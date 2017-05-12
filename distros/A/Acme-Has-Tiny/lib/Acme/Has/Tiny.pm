package Acme::Has::Tiny;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized once void numeric);

our $AUTHORITY = "cpan:TOBYINK";
our $VERSION   = "0.002";

use B qw(perlstring);
use Scalar::Util qw(blessed);

our %ATTRIBUTES;
our %VALIDATORS;

sub _croak ($;@)
{
	my $msg = shift;
	require Carp;
	$Carp::CarpInternal{+__PACKAGE__} = 1;
	Carp::croak(sprintf($msg, @_));
}

BEGIN { *CAN_HAZ_XS = eval 'use Class::XSAccessor 1.18; 1' ? sub(){!!1} : sub(){!!0} };

sub import
{
	no strict qw(refs);
	
	my $me     = shift;
	my $caller = caller;
	my %want   = map +($_ => 1), @_;
	
	if ($want{has})
	{
		*{"$caller\::has"} = sub { unshift @_, __PACKAGE__; goto \&has };
	}
	
	if ($want{new})
	{
		*{"$caller\::new"} = sub {
			my $new = $me->create_constructor("new", class => $_[0], replace => 1);
			goto $new;
		};
	}
	
	return;
}

sub has
{
	my $me = shift;
	my ($attrs, %options) = @_;
	$attrs = [$attrs] unless ref($attrs) eq q(ARRAY);
	
	my $class = $options{class} || caller;
	delete $VALIDATORS{$class};
	
	my @code = "package $class;";
	for my $a (@$attrs)
	{
		$ATTRIBUTES{$class}{$a} = +{ %options };
		push @code, $me->_build_methods($class, $a, $ATTRIBUTES{$class}{$a});
	}
	my $str = join "\n", @code, "1;";
	
	eval($str) or die("COMPILE ERROR: $@\nCODE:\n$str\n");
	return;
}

sub assert_valid
{
	my $me = shift;
	my ($class, $hash) = @_;
	
	my @validator = map {
		$VALIDATORS{$_} ||= $me->_compile_validator($_, $ATTRIBUTES{$_});
	} $me->_find_parents($class);
	
	$_->($hash) for @validator;
	return $hash;
}

my $default_buildargs = sub
{
	my $class = shift;
	return +{
		(@_ == 1 && ref($_[0]) eq q(HASH)) ? %{$_[0]} : @_
	};
};

sub create_constructor
{
	my $me = shift;
	my ($method, %options) = @_;
	
	my $class     = $options{class} || caller;
	my $build     = $options{build};
	my $buildargs = $options{buildargs} || $default_buildargs;
	
	my $code = sub
	{
		my $class = shift;
		my $self = bless($class->$buildargs(@_), $class);
		$me->assert_valid($class, $self);
		$self->$build if $options{build};
		return $self;
	};
	
	no strict qw(refs);
	if ($options{replace})
	{
		no warnings qw(redefine);
		*{"$class\::$method"} = $code;
	}
	else
	{
		use warnings FATAL => qw(redefine);
		*{"$class\::$method"} = $code;
	}
	return $code;
}

sub _build_methods
{
	my $me = shift;
	my ($class, $attr, $spec) = @_;
	my @code;
	
	if ($spec->{is} eq q(rwp))
	{
		push @code,
			$me->_build_reader($class, $attr, $spec, $attr),
			$me->_build_writer($class, $attr, $spec, "_set_$attr");
	}
	elsif ($spec->{is} eq q(rw))
	{
		push @code, $me->_build_accessor($class, $attr, $spec, $attr);
	}
	else
	{
		push @code, $me->_build_reader($class, $attr, $spec, $attr);
	}
	
	if ($spec->{predicate} eq q(1))
	{
		push @code, $me->_build_predicate($class, $attr, $spec, "has_$attr");
	}
	elsif ($spec->{predicate})
	{
		push @code, $me->_build_predicate($class, $attr, $spec, $spec->{predicate});
	}
	
	return @code;
}

sub _build_reader
{
	my $me = shift;
	my ($class, $attr, $spec, $method) = @_;
	
	my $builder_name;
	if ($spec->{builder} eq q(1))
	{
		$builder_name = "_build_$attr";
	}
	elsif (ref($spec->{builder}) eq q(CODE))
	{
		no strict qw(refs);
		$builder_name = "_build_$attr";
		*{"$class\::$builder_name"} = $spec->{builder};
	}
	elsif ($spec->{builder})
	{
		$builder_name = $spec->{builder};
	}
	
	if (CAN_HAZ_XS and not $builder_name)
	{
		"Class::XSAccessor"->import(class => $class, getters => { $method => $attr });
		return;
	}
	
	return $builder_name
		? sprintf('sub %s { $_[0]{%s} ||= $_[0]->%s }', $method, perlstring($attr), $builder_name)
		: sprintf('sub %s { $_[0]{%s}               }', $method, perlstring($attr));
}

sub _build_predicate
{
	my $me = shift;
	my ($class, $attr, $spec, $method) = @_;
	
	if (CAN_HAZ_XS)
	{
		"Class::XSAccessor"->import(class => $class, exists_predicates => { $method => $attr });
		return;
	}
	
	return sprintf('sub %s { exists $_[0]{%s} }', $method, perlstring($attr));
}

sub _build_writer
{
	my $me = shift;
	my ($class, $attr, $spec, $method) = @_;
	
	my $inlined;
	my $isa = $spec->{isa};
	if (blessed($isa) and $isa->isa('Type::Tiny') and $isa->can_be_inlined)
	{
		$inlined = $isa->inline_assert('$_[1]');
	}
	elsif ($isa)
	{
		$inlined = sprintf('$Acme::Has::Tiny::ATTRIBUTES{%s}{%s}{isa}->($_[1]);', perlstring($class), perlstring($attr));
	}
	
	if (CAN_HAZ_XS and not $inlined)
	{
		"Class::XSAccessor"->import(class => $class, setters => { $method => $attr });
		return;
	}
	
	return defined($inlined)
		? sprintf('sub %s { %s; $_[0]{%s} = $_[1] }', $method, $inlined, perlstring($attr))
		: sprintf('sub %s {     $_[0]{%s} = $_[1] }', $method,           perlstring($attr));
}

sub _build_accessor
{
	my $me = shift;
	my ($class, $attr, $spec, $method) = @_;
	
	my $inlined;
	my $isa = $spec->{isa};
	if (blessed($isa) and $isa->can_be_inlined)
	{
		$inlined = $isa->inline_assert('$_[1]');
	}
	elsif ($isa)
	{
		$inlined = sprintf('$Acme::Has::Tiny::ATTRIBUTES{%s}{%s}{isa}->($_[1]);', perlstring($class), perlstring($attr));
	}
	
	if (CAN_HAZ_XS and not $inlined)
	{
		"Class::XSAccessor"->import(class => $class, accessors => { $method => $attr });
		return;
	}
	
	return defined($inlined)
		? sprintf('sub %s { return $_[0]{%s} unless @_; %s; $_[0]{%s} = $_[1] }', $method, perlstring($attr), $inlined, perlstring($attr))
		: sprintf('sub %s { return $_[0]{%s} unless @_;     $_[0]{%s} = $_[1] }', $method, perlstring($attr),           perlstring($attr));
}

sub _compile_validator
{
	my $me = shift;
	my $code = join "\n" => (
		"#line 1 \"validator(Acme::Has::Tiny)\"",
		"package $_[0];",
		'sub {',
		'my $self = $_[0];',
		$me->_build_validator_parts(@_),
		'return $self;',
		'}',
	);
	eval $code;
}

sub _build_validator_parts
{
	my $me = shift;
	my ($class, $attributes) = @_;
	
	my @code;
	for my $a (sort keys %$attributes)
	{
		my $spec = $attributes->{$a};
		
		if ($spec->{default})
		{
			push @code, sprintf(
				'exists($self->{%s}) or $self->{%s} = $Acme::Has::Tiny::ATTRIBUTES{%s}{%s}{default}->();',
				map perlstring($_), $a, $a, $class, $a,
			);
		}
		elsif ($spec->{required})
		{
			push @code, sprintf(
				'exists($self->{%s}) or Acme::Has::Tiny::_croak("Attribute %%s is required by %%s", %s, %s);',
				map perlstring($_), $a, $a, $class,
			);
		}
		
		my $isa = $spec->{isa};
		if (blessed($isa) and $isa->can_be_inlined)
		{
			push @code, (
				sprintf('if (exists($self->{%s})) {', $a),
				$isa->inline_assert(sprintf '$self->{%s}', perlstring($a)),
				'}',
			);
		}
		elsif ($isa)
		{
			push @code, (
				sprintf('if (exists($self->{%s})) {', $a),
				sprintf('$Acme::Has::Tiny::ATTRIBUTES{%s}{%s}{isa}->($self->{%s});', map perlstring($_), $class, $a, $a),
				'}',
			);
		}
	}
	
	return @code;
}

sub _find_parents
{
	my $me = shift;
	my $class = $_[0];
	
	if (eval { require mro } or eval { require MRO::Compat })
	{
		return @{ mro::get_linear_isa($class) };
	}
	
	require Class::ISA;
	return Class::ISA::self_and_super_path($class);
}

1;

__END__

=pod

=encoding utf-8

=for stopwords ro rw rwp isa

=head1 NAME

Acme::Has::Tiny - tiny implementation of Moose-like "has" keyword

=head1 SYNOPSIS

   package Person;
   
   use Acme::Has::Tiny qw(new has);
   use Types::Standard -types;
   
   has name => (isa => Str);
   has age  => (isa => Num);

=head1 DESCRIPTION

Acme::Has::Tiny provides a Moose-like C<has> function. It is not
particularly full-featured, providing just enough to be useful for
small OO projects.

Generally speaking, I'd recommend using L<Moo> or L<Moose> instead, but
if you want to use this then I'm fairly unlikely to hunt you down with dogs.

This module was originally written for Type::Tiny, but turned out to be
just a smidgen slower than the system it was replacing, so was abandoned.

=head2 Methods

=over

=item C<< has \@attrs, %spec >>

=item C<< has $attr, %spec >>

Create an attribute. This method can also be exported as a usable function.

The specification supports the following options:

=over

=item C<< is => "ro" | "rw" | "rwp" >>

Defaults to "ro".

=item C<< required => 1 >>

=item C<< default => $coderef >>

Defaults are always eager (not lazy).

=item C<< builder => $coderef | $method_name | 1 >>

Builders are always lazy.

=item C<< predicate => $method_name | 1 >>

=item C<< isa => $type >>

Type constraint (use L<Types::Standard> or another L<Type::Library>-based
type constraint library).

=back

=item C<< create_constructor $method_name, %options >>

If you want a constructor, then you could call this B<after> defining
your attributes. (Or you could just import C<new> from this module.)

   package Person;
   
   use Acme::Has::Tiny qw(has);
   use Types::Standard -types;
   
   has name => (isa => Str);
   has age  => (isa => Num);
   
   Acme::Has::Tiny->create_constructor("new");
   Acme::Has::Tiny->create_constructor(
      "new_from_arrayref",
      buildargs => sub {
         my ($class, $aref) = @_;
         return { name => $aref->[0], age => $aref->[1] };
      },
   );

Currently supported options:

=over

=item C<< buildargs => $coderef | $method_name >>

=item C<< build => $coderef | $method_name >>

=item C<< class => $class_name >>

Package to build a constructor for; if omitted, uses the caller.

=item C<< replace => $bool >>

Allow C<create_constructor> to overwrite an existing method.

=back

There's no law that says you have to use C<create_constructor>. You can
write your own constructor if you like. In which case, you might like to
make use of...

=item C<< assert_valid($class, \%params) >>

Check that a hash of parameters is valid according to type constraints and
required attributes of C<< $class >> and any classes it inherits from.

Returns the hashref or dies.

   sub new {
      my ($class, %params) = @_;
      ...; # other stuff here
      my $self = bless(
         Acme::Has::Tiny->assert_valid($class, \%params),
         $class,
      );
      ...; # other stuff here
      return $self;
   }

=back

=head2 Constants

=over

=item C<< CAN_HAZ_XS >>

Whether Class::XSAccessor can be used.

=back

=head1 CAVEATS

Inheriting attributes from parent classes is not super well-tested.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-Type-Tiny>.

=head1 SEE ALSO

L<Moo>, L<Moose>, L<Mouse>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

