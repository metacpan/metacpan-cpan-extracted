#!/usr/bin/perl

package Data::Thunk;
BEGIN {
  $Data::Thunk::AUTHORITY = 'cpan:NUFFIN';
}
BEGIN {
  $Data::Thunk::VERSION = '0.07';
}
# ABSTRACT: A sneakier Scalar::Defer ;-)

use strict;
use warnings;

use Data::Thunk::Code;
use Data::Thunk::ScalarValue;
use Data::Thunk::Object;

use Scalar::Util qw(blessed);

use namespace::clean;

use Sub::Exporter -setup => {
	exports => [qw(lazy lazy_new lazy_object force)],
	groups => {
		default => [':all'],
	},
};

sub lazy (&) {
	my $thunk = shift;
	bless \$thunk, "Data::Thunk::Code";
}

sub lazy_new ($;@) {
	my ( $class, %args ) = @_;
	my $constructor = delete $args{constructor} || 'new';
	my $args        = delete $args{args} || [];
	&lazy_object(sub { $class->$constructor(@$args) }, %args, class => $class);
}

sub lazy_object (&;@) {
	my ( $thunk, @args ) = @_;
	bless { @args, code => $thunk }, "Data::Thunk::Object";
}

my ( $vivify_code, $vivify_scalar ) = ( $Data::Thunk::Code::vivify_code, $Data::Thunk::ScalarValue::vivify_scalar );

sub force ($) {
	my $val = shift;

	if ( blessed($val) ) {
		no warnings; # UNIVERSAL::isa
		if ( $val->UNIVERSAL::isa('Data::Thunk::Code') ) { # we wanna know what it's *real* class is
			return $val->$vivify_code;
		} elsif ( $val->UNIVERSAL::isa('Data::Thunk::ScalarValue') ) {
			return $val->$vivify_scalar;
		}
	}

	return $val;
}

{
	package Data::Thunk::NoOverload;
BEGIN {
  $Data::Thunk::NoOverload::AUTHORITY = 'cpan:NUFFIN';
}
BEGIN {
  $Data::Thunk::NoOverload::VERSION = '0.07';
}
	# we temporarily bless into this to avoid overloading
}

1;



__END__
=pod

=encoding utf-8

=head1 NAME

Data::Thunk - A sneakier Scalar::Defer ;-)

=head1 SYNOPSIS

	use Data::Thunk qw(lazy);

	my %hash = (
		foo => lazy { $expensive },
	);

	$hash{bar}{gorch} = $hash{foo};

	$hash{bar}{gorch}->foo; # vivifies the object

	warn overload::StrVal($hash{foo}); # replaced with the value

=head1 DESCRIPTION

This is an implementation of thunks a la L<Scalar::Defer>, but uses
L<Data::Swap> and assignment to C<$_[0]> in order to leave a minimal trace of the thunk.

In the case that a reference is returned from C<lazy { }> L<Data::Swap> can
replace the thunk ref with the result ref, so all the references that pointed
to the thunk are now pointing to the result (at the same address).

If a simple value is returned then the thunk is swapped with a simple scalar
container, which will assign the value to C<$_[0]> on each overloaded use.

In this particular example:

	my $x = {
		foo => lazy { "blah" },
		bar => lazy { [ "boink" ] },
	};

	$x->{quxx} = $x->{foo};
	$x->{gorch} = $x->{bar};

	warn $x->{bar};
	warn $x->{foo};
	warn $x->{quxx};

	use Data::Dumper;
	warn Dumper($x);

The resulting structure is:

	$VAR1 = {
		'bar' => [ 'boink' ],
		'foo' => 'blah',
		'gorch' => $VAR1->{'bar'},
		'quxx' => 'blah'
	};

Whereas with L<Scalar::Defer> the trampoline objects remain:

	$VAR1 = {
		'bar' => bless( do{\(my $o = 25206320)}, '0' ),
		'foo' => bless( do{\(my $o = 25387232)}, '0' ),
		'gorch' => $VAR1->{'bar'},
		'quxx' => $VAR1->{'foo'}
	};

This is potentially problematic because L<Scalar::Util/reftype> and
L<Scalar::Util/blessed> can't be fooled. With L<Data::Thunk> the problem still
exists before values are vivified, but not after.

Furthermore this module uses L<UNIVERSAL::ref> instead of blessing to C<0>.
Blessing to C<0> pretends that everything is a non ref (C<ref($thunk)> returns
the name of the package, which evaluates as false), so deferred values that
become objects don't appear to be as such.

=head1 EXPORTS

=over 4

=item lazy { ... }

Create a new thunk.

=item lazy_object { }, %attrs;

Creates a thunk that is expected to be an object.

If the C<class> attribute is provided then C<isa> and C<can> will work as class
methods without vivifying the object.

Any other attributes in %attrs will be used to shadow method calls. If the keys
are code references they will be invoked, otherwise they will be simply
returned as values. This can be useful if some of your object's properties are
known in advance.

=item lazy_new $class, %args;

A specialization on C<lazy_object> that can call a constructor method based on
a class for you. The C<constructor> and C<args> arguments (method name or code
ref, and array reference) will be removed from %args to create the thunk. They
default to C<new> and an empty array ref by default. Then this function
delegates to C<lazy_object>.

=item force

Vivify the value and return the result.

=back

=head1 SEE ALSO

L<Scalar::Defer>, L<Data::Lazy>, L<Data::Swap>, L<UNIVERSAL::ref>.

=head1 AUTHOR

Yuval Kogman

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Yuval Kogman.

This is free software, licensed under:

  The MIT (X11) License

=cut

