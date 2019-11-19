package Class::Tiny::Antlers;

sub _getstash { \%{"$_[0]::"} }

use 5.006;
use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.024';

use Class::Tiny 0.006 ();
our @ISA = 'Class::Tiny';

my %EXPORT_TAGS = (
	default => [qw/ has extends with strict /],
	all     => [qw/ has extends with before after around strict warnings confess /],
	cmm     => [qw/ before after around /],
);

my %CLASS_ATTRIBUTES;

sub import
{
	my $me = shift;
	my %want =
		map +($_ => 1),
		map +(@{ $EXPORT_TAGS{substr($_, 1)} or [$_] }),
		(@_ ? @_ : '-default');
	
	strict->import   if delete $want{strict};
	warnings->import if delete $want{warnings};
	
	my $caller = caller;
	$me->_install_tracked($caller, has     => sub { unshift @_, $me, $caller; goto \&has })     if delete $want{has};
	$me->_install_tracked($caller, extends => sub { unshift @_, $me, $caller; goto \&extends }) if delete $want{extends};
	$me->_install_tracked($caller, with    => sub { unshift @_, $me, $caller; goto \&with })    if delete $want{with};
	$me->_install_tracked($caller, confess => \&confess)                                        if delete $want{confess};
	
	for my $modifier (qw/ before after around /)
	{
		next unless delete $want{$modifier};
		$me->_install_tracked($caller, $modifier, sub
		{
			require Class::Method::Modifiers;
			Class::Method::Modifiers::install_modifier($caller, $modifier, @_);
		});
	}
	
	croak("Unknown import symbols (%s)", join ", ", sort keys %want) if keys %want;
	
	@_ = ($me);
	goto \&Class::Tiny::import;
}

my %INSTALLED;
sub _install_tracked
{
	no strict 'refs';
	my ($me, $pkg, $name, $code) = @_;
	*{"$pkg\::$name"} = $code;
	$INSTALLED{$pkg}{$name} = "$code";
}

sub unimport
{
	my $me = shift;
	my $caller = caller;
	$me->_clean($caller, $INSTALLED{$caller});
}

sub _clean
{
	my ($me, $target, $exports) = @_;
	my %rev = reverse %$exports or return;
	my $stash = _getstash($target);
	
	for my $name (keys %$exports)
	{
		if ($stash->{$name} and defined(&{$stash->{$name}}))
		{
			if ($rev{$target->can($name)})
			{
				my $old = delete $stash->{$name};
				my $full_name = join('::',$target,$name);
				# Copy everything except the code slot back into place (e.g. $has)
				foreach my $type (qw(SCALAR HASH ARRAY IO))
				{
					next unless defined(*{$old}{$type});
					no strict 'refs';
					*$full_name = *{$old}{$type};
				}
			}
		}
	}
}

sub croak
{
	require Carp;
	my ($fmt, @values) = @_;
	Carp::croak(sprintf($fmt, @values));
}

sub confess
{
	require Carp;
	my ($fmt, @values) = @_;
	Carp::confess(sprintf($fmt, @values));
}

my %BUILD_WRAPPED;

sub has
{
	my ($me, $caller) = (shift, shift);
	my ($attr, %spec) = @_;
	
	if (defined($attr) and ref($attr) eq q(ARRAY))
	{
		has($caller, $_, %spec) for @$attr;
		return;
	}

	$CLASS_ATTRIBUTES{$caller}{$attr} = +{ %spec };
	$CLASS_ATTRIBUTES{$caller}{$attr}{is}   ||= 'ro';
	$CLASS_ATTRIBUTES{$caller}{$attr}{lazy} ||= 1 if exists($spec{default});
	
	if (!defined($attr) or ref($attr) or $attr !~ /^[^\W\d]\w*$/s)
	{
		croak("Invalid accessor name '%s'", $attr);
	}
	
	my $init_arg  = exists($spec{init_arg}) ? delete($spec{init_arg}) : \undef;
	my $is        = delete($spec{is}) || 'rw';
	my $required  = delete($spec{required});
	my $default   = delete($spec{default});
	my $lazy      = delete($spec{lazy});
	my $clearer   = delete($spec{clearer});
	my $predicate = delete($spec{predicate});
	my $setter_wrap;

	if ($spec{isa} or $spec{coerce})
	{
		ref($spec{isa}) or croak("Type names are strings are not supported");
		$spec{isa}->can('check')       or croak("Type doesn't have a `check` method");
		$spec{isa}->can('get_message') or croak("Type doesn't have a `get_message` method");
		$spec{isa}->can('coerce')      or !$spec{coerce} or croak("Type doesn't have a `coerce` method");
		$setter_wrap = 1;
		delete $spec{$_} for qw/ isa coerce /;
		__PACKAGE__->_wrap_build($caller) unless $BUILD_WRAPPED{$caller}++;
	}
	
	if ($is eq 'lazy')
	{
		$lazy = 1;
		$is   = 'ro';
	}
	
	if (defined $lazy and not $lazy)
	{
		croak("Class::Tiny does not support eager defaults");
	}
	elsif (keys %spec)
	{
		croak("Unknown options in attribute specification (%s)", join ", ", sort keys %spec);
	}
	
	if ($required and 'Class::Tiny::Object'->can('new') == $caller->can('new'))
	{
		croak("Class::Tiny::Object::new does not support required attributes; please manually override the constructor to enforce required attributes");
	}
	
	if ($init_arg and ref($init_arg) eq 'SCALAR' and not defined $$init_arg)
	{
		# ok
	}
	elsif (!$init_arg or $init_arg ne $attr)
	{
		croak("Class::Tiny does not support init_arg");
	}
	
	my $getter = "\$_[0]{'$attr'}";
	if (defined $default and ref($default) eq 'CODE')
	{
		$getter = "\$_[0]{'$attr'} = \$default->(\$_[0]) unless exists \$_[0]{'$attr'}; $getter";
	}
	elsif (defined $default)
	{
		$getter = "\$_[0]{'$attr'} = \$default unless exists \$_[0]{'$attr'}; $getter";
	}
	
	my $setter_name;
	my @methods;
	my $needs_clean = 0;
	if ($is eq 'rw')
	{
		$setter_name = $attr;
		push @methods, "sub $attr :method { \$_[0]{'$attr'} = \$_[1] if \@_ > 1; $getter };";
	}
	elsif ($is eq 'ro' or $is eq 'rwp')
	{
		$setter_name = "_set_$attr";
		push @methods, "sub $attr :method { $getter };";
		push @methods, "sub _set_$attr :method { \$_[0]{'$attr'} = \$_[1] };"
			if $is eq 'rwp';
	}
	elsif ($is eq 'bare')
	{
		no strict 'refs';
		$needs_clean = not exists &{"$caller\::$attr"};
	}
	else
	{
		croak("Class::Tiny::Antlers does not support '$is' accessors");
	}
	
	if ($clearer)
	{
		$clearer = ($attr =~ /^_/) ? "_clear$attr" : "clear_$attr" if $clearer eq '1';
		push @methods, "sub $clearer :method { delete(\$_[0]{'$attr'}) }";
	}
	
	if ($predicate)
	{
		$predicate = ($attr =~ /^_/) ? "_has$attr" : "has_$attr" if $predicate eq '1';
		push @methods, "sub $predicate :method { exists(\$_[0]{'$attr'}) }";
	}
	
	eval "package $caller; @methods";
	$me->create_attributes($caller, $attr);
	
	$me->_wrap_setter($caller, $attr, $setter_name) if $setter_wrap;
	
	$me->_clean($caller, { $attr => do { no strict 'refs'; ''.\&{"$caller\::$attr"} } })
		if $needs_clean;
}

sub _wrap_build {
	my ($me, $caller) = @_;
	no strict 'refs';
	if (exists &{"$caller\::BUILD"}) {
		my $next = \&{"$caller\::BUILD"};
		$me->_clean($caller, { BUILD => $next });
		eval sprintf(q{
			package %s;
			sub BUILD {
				my $self = shift;
				%s->_check_args('%s', @_);
				$self->$next(@_);
			}
		}, $caller, $me, $caller);
	}
	else {
		eval sprintf(q{
			package %s;
			sub BUILD {
				my $self = shift;
				%s->_check_args('%s', $self, @_);
			}
		}, $caller, $me, $caller);
	}
}

sub _check_args {
	my ($me, $caller, $object, $args) = @_;
	my $spec = $CLASS_ATTRIBUTES{$caller};
	for my $attr (sort keys %$spec) {
		my $type = $spec->{$attr}{isa} or next;
		exists $args->{$attr} or next;
		$type->check($args->{$attr}) and next;
		if ($spec->{$attr}{coerce}) {
			my $coerced = $type->coerce($args->{$attr});
			if ($type->check($coerced)) {
				$object->{$attr} = $args->{$attr} = $coerced;
				next;
			}
		}
		croak('Type constraint check failed for attribute "%s": %s', $attr, $type->get_message($args->{$attr}));
	}
}

sub _wrap_setter {
	my ($me, $caller, $attr, $setter_name) = @_;
	no strict 'refs';
	my $next = \&{"$caller\::$setter_name"};
	my $spec = $CLASS_ATTRIBUTES{$caller};
	my $type = $spec->{$attr}{isa};
	my $coerce = $spec->{$attr}{coerce};
	$me->_clean($caller, { $setter_name => $next });
	if ($coerce) {
		eval sprintf(q{
			package %s;
			sub %s {
				my $self = shift;
				if (@_) {
					$type->check(@_)
					or do {
						my $coerced = $type->coerce(@_);
						$type->check($coerced) and do { @_ = ($coerced); 1 };
					}
					or %s::croak('Type constraint check failed for attribute "%s": %%s', $type->get_message(@_));
				}
				$self->$next(@_);
			}
		}, $caller, $setter_name, $me, $attr);
	}
	elsif ($type->can('can_be_inlined') && $type->can_be_inlined) {
		my $ic = $type->can('inline_check') || $type->can('_inline_check');
		eval sprintf(q{
			package %s;
			sub %s {
				my $self = shift;
				if (@_) {
					my $val = $_[0];
					%s or %s::croak('Type constraint check failed for attribute "%s": %%s', $type->get_message(@_));
				}
				$self->$next(@_);
			}
		}, $caller, $setter_name, $type->$ic('$val'), $me, $attr);
	}
	else {
		eval sprintf(q{
			package %s;
			sub %s {
				my $self = shift;
				if (@_) {
					$type->check(@_) or %s::croak('Type constraint check failed for attribute "%s": %%s', $type->get_message(@_));
				}
				$self->$next(@_);
			}
		}, $caller, $setter_name, $me, $attr);
	}
}

sub extends
{
	my ($me, $caller) = (shift, shift);
	my (@parents) = @_;
	
	for my $parent (@parents)
	{
		eval "require $parent";
	}
	
	no strict 'refs';
	@{"$caller\::ISA"} = @parents;
}

sub with
{
	my ($me, $caller) = (shift, shift);
	require Role::Tiny::With;
	goto \&Role::Tiny::With::with;
}

sub get_all_attribute_specs_for
{
	my $me = shift;
	my $class = $_[0];
	
	my %specs = %{ $me->get_all_attribute_defaults_for };
	$specs{$_} =
		defined($specs{$_})
			? +{ is => 'rw', lazy => 1, default => $specs{$_} }
			: +{ is => 'rw' }
		for keys %specs;
	
	for my $p ( reverse @{ $class->mro::get_linear_isa } )
	{
		while ( my ($k, $v) = each %{$CLASS_ATTRIBUTES{$p}||{}} )
		{
			$specs{$k} = $v;
		}
	}
	
	\%specs;
}

1;


__END__

=pod

=encoding utf-8

=for stopwords unimport

=head1 NAME

Class::Tiny::Antlers - Moose-like sugar for Class::Tiny

=head1 SYNOPSIS

   {
      package Point;
      use Class::Tiny::Antlers;
      has x => (is => 'ro');
      has y => (is => 'ro');
   }
   
   {
      package Point3D;
      use Class::Tiny::Antlers;
      extends 'Point';
      has z => (is => 'ro');
   }

=head1 DESCRIPTION

Class::Tiny::Antlers provides L<Moose>-like C<has>, C<extends>, C<with>,
C<before>, C<after> and C<around> keywords for L<Class::Tiny>.
(The C<with> keyword requires L<Role::Tiny>; method modifiers require
L<Class::Method::Modifiers>.)

Class::Tiny doesn't support all Moose's attribute options; C<has> should
throw you an error if you try to do something it doesn't support (like
triggers).

Class::Tiny::Antlers does however hack in support for C<< is => 'ro' >>
and Moo-style C<< is => 'rwp' >>, clearers and predicates.

From version 0.24, Class::Tiny::Antlers also adds support for `isa` and
`coerce` using L<Type::Tiny>. (I mean, this is a TOBYINK module, so what
do you expect?!) Technically L<MooseX::Types>, L<MouseX::Types>,
L<Specio>, and L<Type::Nano> should work, but these are less tested.

=head2 Export

By default, Class::Tiny::Antlers exports C<has>, C<with> and C<extends>,
and also imports L<strict> into its caller. You can optionally also import
C<confess> and L<warnings>:

   use Class::Tiny::Antlers qw( -default confess warnings );

And Class::Method::Modifiers keywords:

   use Class::Tiny::Antlers qw( -default before after around );
   use Class::Tiny::Antlers qw( -default -cmm );  # same thing

If you just want everything:

   use Class::Tiny::Antlers qw( -all );

Class::Tiny::Antlers also ensures that Class::Tiny's import method is called
for your class.

You can put a C<< no Class::Tiny::Antlers >> statement at the end of your
class definition to wipe the imported functions out of your namespace. (This
does not unimport strict/warnings though.) To clean up your namespace more
thoroughly, use something like L<namespace::sweep>.

=head2 Functions

=over

=item C<< has $attr, %spec >>

Create an attribute. The specification hash roughly supports C<is>,
C<default>, C<clearer> and C<predicate> as per L<Moose> and L<Moo>.

=item C<< extends @classes >>

Set the base class(es) for your class.

=item C<< with @roles >>

Compose L<Role::Tiny> roles with your class.

=item C<< before $name, \&code >>

Install a C<before> modifier using L<Class::Method::Modifiers>.

=item C<< after $name, \&code >>

Install a C<after> modifier using L<Class::Method::Modifiers>.

=item C<< around $name, \&code >>

Install a C<around> modifier using L<Class::Method::Modifiers>.

=item C<< confess $format, @list >>

C<sprintf>-fueled version of L<Carp>'s C<confess>.

=back

=head2 Methods

Class::Tiny::Antlers inherits the C<get_all_attributes_for> and
C<get_all_attribute_defaults_for> methods from Class::Tiny, and also
provides:

=over

=item C<< Class::Tiny::Antlers->get_all_attribute_specs_for($class) >>

Gets Moose-style attribute specification hashes for all the class'
attributes as a big hashref. (Includes inherited attributes.)

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Class-Tiny-Antlers>.

=head1 SEE ALSO

L<Class::Tiny>, L<Role::Tiny>, L<Class::Method::Modifiers>,
L<Type::Tiny::Manual>.

L<Moose>, L<Mouse>, L<Moo>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013, 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
