package Class::Monadic;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.04';

use Exporter qw(import);
our @EXPORT_OK   = qw(monadic);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use Carp ();
use Data::Util ();
use Scalar::Util ();
use Hash::FieldHash ();

#use Class::Method::Modifiers::Fast ();

Hash::FieldHash::fieldhash my %Meta;

sub _cannot_initialize{
	Carp::croak 'Cannot initialize a monadic object without object references';
}

sub monadic{
	my($object) = @_;
	ref($object) or _cannot_initialize();

	return $Meta{$object} ||= __PACKAGE__->_new($object);
}

sub initialize{
	my($class, $object) = @_;
	ref($object) or _cannot_initialize();

	return $Meta{$object} ||= $class->_new($object);
}


sub _new{
	my($metaclass, $object) = @_;

	if(Data::Util::is_glob_ref($object)){
		$object = *{$object}{IO};
	}

	my $class = Scalar::Util::blessed($object) or _cannot_initialize();

	$class =~ s/ ::0x[a-f0-9]+ \z//xms; # remove its monadic identity (in cloning)

	my $meta = bless {
		class     => $class,
		id        => sprintf('0x%x', Scalar::Util::refaddr($object)),

		object    => $object,
		isa       => undef,
		sclass    => undef,
		methods   => undef,
		modifiers => undef,
		fields    => undef,
		field_map => undef,
	}, $metaclass;
	Scalar::Util::weaken( $meta->{object} );

	&Internals::SvREADONLY($meta, 1); # lock_keys(%{$meta})

	my $sclass      = $class . '::' . $meta->{id};
	my $sclass_isa  = do{ no strict 'refs'; \@{$sclass . '::ISA'} };

	$meta->{sclass} = $sclass;
	$meta->{isa}    = $sclass_isa;

	my $base = $metaclass . '::Object';
	if($class->can('clone')){
		$base .= '::Clonable';
	}
	@{$sclass_isa} = ($base, $class);

	bless $object, $sclass; # re-bless
	return $meta;
}


sub name{
	my($meta) = @_;

	return $meta->{class};
}

sub id{
	my($meta) = @_;

	return $meta->{id};
}

*add_methods = \&add_method; # alias
sub add_method{
	my $meta = shift;

	Data::Util::install_subroutine($meta->{sclass}, @_); # dies on fail

	push @{$meta->{methods} ||= []}, @_;
	return;
}

*add_fields = \&add_field; # alias
sub add_field{
	my $meta = shift;

	my $fields_ref = Data::Util::mkopt_hash(\@_, 'add_field', [qw(Regexp ARRAY CODE)]);

	my $field_map_ref = $meta->{field_map} ||= {};

	my $fields = $meta->{fields} ||= [];

	while(my($name, $validator) = each %{$fields_ref}){
		my $slot;

		my $validate_sub;

		if($validator){
			if(Data::Util::is_regex_ref $validator){
				$validate_sub = sub{ $_[0] =~ /$validator/ };
			}
			elsif(Data::Util::is_array_ref $validator){
				my %words;
				@words{@{$validator}} = ();
				$validate_sub = sub{ exists $words{ $_[0] } };
			}
			else{ # CODE reference
				$validate_sub = $validator;
			}
		}

		Data::Util::install_subroutine($meta->{sclass},
			"get_$name" => sub{
				if(@_ > 1){
					Carp::croak "Too many arguments for get_$name";
				}
				return $slot;
			},
			"set_$name" => 	sub{
				if(@_ > 2){
					Carp::croak "Cannot set multiple values for set_$name";
				}
				if(defined $validate_sub){
					my $value = $_[1];
					$validate_sub->($value)
						or Carp::croak 'Invalid value ', Data::Util::neat($value), " for set_$name";
					$slot = $value;
				}
				else{
					$slot = $_[1];
				}
				return $_[0];
			},
		);

		$field_map_ref->{$name} = \$slot;
		push @{$fields}, $name => $validate_sub;
	}
	return;
}

sub add_modifier{
	my $meta = shift;

	require Class::Method::Modifiers::Fast;

	Class::Method::Modifiers::Fast::_install_modifier($meta->{sclass}, @_);
	push @{$meta->{modifiers} ||= []}, @_;
	return;
}

sub inject_base{
	my($meta, @components) = @_;

	# NOTE: In 5.10.0, do{unshift @ISA, @classes} may cause 'uninitialized' warnings.
	
	@{$meta->{isa}} = (
		(grep{ not $meta->{object}->isa($_) } @components),
		@{$meta->{isa}},
	);
	return;
}

sub bless{
	my($meta, $object) = @_;

	my $newmeta = ref($meta)->initialize($object);

	$newmeta->add_methods( @{ $meta->{methods} } )
		if exists $meta->{methods};

	if(exists $meta->{fields}){
		$newmeta->add_fields(@{$meta->{fields}});

		my $src_map_ref = $meta->{field_map};
		my $new_map_ref = $newmeta->{field_map};
		while(my($key, $val_ref) = each %{$src_map_ref}){
			${$new_map_ref->{$key}} = ${$val_ref};
		}
	}

	$newmeta->inject_base(@{$meta->{isa}}[0 .. $#{$meta->{isa}}-2])
		if @{$meta->{isa}} > 2; # other than Monadic::Object and its original class

	return $object;
}

sub DESTROY{
	my($meta) = @_;
	my $original_stash = Data::Util::get_stash($meta->{class});

	my $sclass_stashgv = delete $original_stash->{$meta->{id} . '::'};

	@{$meta->{isa}}    = ();
	%{$sclass_stashgv} = ();

	return;
}

package Class::Monadic::Object;

sub STORABLE_freeze{
	my($object, $cloning) = @_;

	return if $cloning;
	Carp::croak sprintf 'Cannot serialize monadic object (%s)', Data::Util::neat($object);
}

package Class::Monadic::Object::Clonable;
our @ISA = qw(Class::Monadic::Object);

sub clone{
	my($object) = @_;
	my $meta = $Meta{$object};

	my $clone = $meta->{class}->can('clone') or Carp::croak(qq{Cannot find "clone" method for $meta->{class}});
	return $meta->bless( $clone->($object) );
}


1;
__END__

=for stopwords gfx

=head1 NAME

Class::Monadic - Provides monadic methods (a.k.a. singleton methods)

=head1 VERSION

This document describes Class::Monadic version 0.04.

=head1 SYNOPSIS

	use Class::Monadic;

	my $ua1 = LWP::UserAgent->new();

	Class::Monadic->initialize($ua1)->add_methods(
		hello => sub{ print "Hello, world!\n" },
	);

	$ua1->hello(); # => Hello, world!

	my $ua2 = LWP::UserAgent->new();

	$ua2->foo(); # throws "Can't locate object method ..."
	             # because foo() is $ua1 specific.

	# import a syntax sugar to make an object monadic
	use Class::Monadic qw(monadic);

	monadic($ua1)->inject_base(qw(SomeComponent OtherComponent));
	# now $ua1 is-a both SomeComponent and OtherComponent

	# per-object fields
	monadic($ua1)->add_fields(qw(x y z));
	$ua1->set_x(42);
	print $ua1->get_x(); # => 42

	# per-object fields with validation
	monadic($ua1)->add_fields(
		foo => qr/^\d+$/,
		bar => [qw(apple banana)],
		qux => \&is_something,
	);

=head1 DESCRIPTION

C<Class::Monadic> provides per-object classes, B<monadic classes>. It is also
known as B<singleton classes> in other languages, e.g. C<Ruby>.

Monadic classes is used in order to define B<monadic methods>, i.e. per-object
methods (a.k.a. B<singleton methods>), which are available only at the
object they are defined into.

All the meta data that C<Class::Monadic> deals with are outside the object
associated with monadic classes, so this module does not depend on the
implementation of the object.

=head1 INTERFACE

=head2 Exportable functions

=head3 monadic($object)

Specializes I<$object> to have a monadic class,
and returns C<Class::Monadic> instance, I<$meta>.

This is a syntax sugar to C<< Class::Monadic->initialize($object) >>.

=head2 Class methods

=head3 C<< Class::Monadic->initialize($object) >>

Specializes I<$object> to have a monadic class,
and returns C<Class::Monadic> instance, I<$meta>.

=head2 Instance methods

=head3 C<< $meta->name >>

Returns the name of the monadic class.

=head3 C<< $meta->id >>

Returns the ID of the monadic class.

Its real class name is C<< $meta->name . '::' . $meta->id >>;

=head3 C<< $meta->add_method(%name_code_pairs) >>

=head3 C<< $meta->add_methods(%name_code_pairs) >>

Adds methods into the monadic class.

=head3 C<< $meta->add_field(@field_names) >>

=head3 C<< $meta->add_fields(@field_names) >>

Adds field accessors named I<get_$name>/I<set_$name> into the monadic class.
Setters are chainable like C<< $obj->set_foo(42)->set_bar(3.14) >>.

These fields are not stored in the object. Rather, stored in its class.

This feature is like what C<Object::Accessor> provides, but C<Class::Monadic>
is available for all the classes existing, whereas C<Object::Accessor>
is only available in classes that is-a C<Object::Accessor>.

=head3 C<< $meta->add_modifier($type, @method_names, $code) >>

Adds method modifiers to specific methods, using C<Class::Method::Modifiers::Fast>.

I<$type> is must be C<before>, C<around> or C<after>.

Example:

	monadic($obj)->add_modifier(before => foo => sub{ ... });
	monadic($obj)->add_modifier(around => qw(foo bar baz),
		sub{
			my $next = shift;
			my(@args) = @_;
			# ...
			return &{$next};
		}
	);
	monadic($obj)->add_modifier(after => xyzzy => sub{ ... });

See also L<Class::Method::Modifiers::Fast>.

=head3 C<< $meta->inject_base(@component_classes) >>

Adds I<@component_classes> into the is-a hierarchy of the monadic class.

=head3 C<< $meta->bless($another_object) >>

Copies all the features of I<$meta> into I<$another_object>.

=head1 CAVEATS

Although you can clone objects with monadic class, you cannot serialize
these objects because its monadic features usually includes
code references.

Patches are welcome.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

C<Data::Util>.

C<Hash::FieldHash>.

C<Class::Method::Modifiers::Fast>.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<Object::Accessor>.

L<Class::Component>.

L<Class::MOP>.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
