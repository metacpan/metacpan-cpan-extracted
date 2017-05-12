# ABSTRACT: Common Methods for Operating on Numbers
package Bubblegum::Object::Number;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Class 'with';
use Bubblegum::Constraints -isas, -types;

with 'Bubblegum::Object::Role::Coercive';
with 'Bubblegum::Object::Role::Value';

our @ISA = (); # non-object

our $VERSION = '0.45'; # VERSION

sub abs {
    my $self = CORE::shift;
    return CORE::abs $self;
}

sub atan2 {
    my $self = CORE::shift;
    my $x    = type_number CORE::shift;
    return CORE::atan2 $self, $x;
}

sub cos {
    my $self = CORE::shift;
    return CORE::cos $self;
}

sub decr {
    my $self = CORE::shift;
    my $n    = type_number CORE::shift if $_[0];
    return $self - ($n || 1);
}

sub exp {
    my $self = CORE::shift;
    return CORE::exp $self;
}

sub hex {
    my $self = CORE::shift;
    return CORE::sprintf '%#x', $self;
}

sub incr {
    my $self = CORE::shift;
    my $n    = type_number CORE::shift if $_[0];
    return $self + ($n || 1);
}

sub int {
    my $self = CORE::shift;
    return CORE::int $self;
}

sub log {
    my $self = CORE::shift;
    return CORE::log $self;
}

sub mod {
    my $self    = CORE::shift;
    my $divisor = type_number CORE::shift;
    return $self % $divisor;
}

sub neg {
    my $self = CORE::shift;
    return -$self;
}

sub pow {
    my $self = CORE::shift;
    my $n    = type_number CORE::shift;
    return $self ** $n;
}

sub sin {
    my $self = CORE::shift;
    return CORE::sin $self;
}

sub sqrt {
    my $self = CORE::shift;
    return CORE::sqrt $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum::Object::Number - Common Methods for Operating on Numbers

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    use Bubblegum;

    my $number = 123456789;
    say $number->incr; # 123456790

=head1 DESCRIPTION

Number methods work on data that meets the criteria for being a number. A number
holds and manipulates an arbitrary sequence of bytes, typically representing
numberic characters (0-9). It is not necessary to use this module as it is
loaded automatically by the L<Bubblegum> class.

=head1 METHODS

=head2 abs

    my $number = 12;
    $number->abs; # 12

    $number = -12;
    $number->abs; # 12

The abs method returns the absolute value of the subject.

=head2 atan2

    my $number = 1;
    $number->atan2(1); # 0.785398163397448

The atan2 method returns the arctangent of Y/X in the range -PI to PI

=head2 cos

    my $number = 12;
    $number->cos; # 0.843853958732492

The cos method computes the cosine of the subject (expressed in radians).

=head2 decr

    my $number = 123456789;
    $number->decr; # 123456788

The decr method returns the numeric subject decremented by 1.

=head2 exp

    my $number = 0;
    $number->exp; # 1

    $number = 1;
    $number->exp; # 2.71828182845905

    $number = 1.5;
    $number->exp; # 4.48168907033806

The exp method returns e (the natural logarithm base) to the power of the
subject.

=head2 hex

    my $number = 175;
    $number->hex; # 0xaf

The hex method returns a hex string representing the value of the subject.

=head2 incr

    my $number = 123456789;
    $number->incr; # 123456790

The incr method returns the numeric subject incremented by 1.

=head2 int

    my $number = 12.5;
    $number->int; # 12

The int method returns the integer portion of the subject. Do not use this
method for rounding.

=head2 log

    my $number = 12345;
    $number->log; # 9.42100640177928

The log method returns the natural logarithm (base e) of the subject.

=head2 mod

    my $number = 12;
    $number->mod(1); # 0
    $number->mod(2); # 0
    $number->mod(3); # 0
    $number->mod(4); # 0
    $number->mod(5); # 2

The mod method returns the division remainder of the subject divided by the
argment.

=head2 neg

    my $number = 12345;
    $number->neg; # -12345

The neg method returns a negative version of the subject.

=head2 pow

    my $number = 12345;
    $number->pow(3); # 1881365963625

The pow method returns a number, the result of a math operation, which is the
subject to the power of the argument.

=head2 sin

    my $number = 12345;
    $number->sin; # -0.993771636455681

The sin method returns the sine of the subject (expressed in radians).

=head2 sqrt

    my $number = 12345;
    $number->sqrt; # 111.108055513541

The sqrt method returns the positive square root of the subject.

=head2 to_array

    my $int = 1;
    $int->to_array; # [1]

The to_array method is used for coercion and simply returns an array reference
where the first element contains the subject.

=head2 to_code

    my $int = 1;
    $int->to_code; # sub { 1 }

The to_code method is used for coercion and simply returns a code reference
which always returns the subject when called.

=head2 to_hash

    my $int = 1;
    $int->to_hash; # { 1 => 1 }

The to_hash method is used for coercion and simply returns a hash reference
with a single key and value, having the key and value both contain the subject.

=head2 to_integer

    my $int = 1;
    $int->to_integer; # 1

The to_integer method is used for coercion and simply returns the subject.

=head2 to_string

    my $int = 1;
    $int->to_string; # '1'

The to_string method is used for coercion and simply returns the stringified
version of the subject.

=head1 COERCIONS

=head2 to_array

    my $number = 5;
    my $result = $number->to_array; # [5]

The to_array method coerces a number to an array value. This method returns an
array reference using the subject as the first element.

=head2 to_a

    my $number = 5;
    my $result = $number->to_a; # [5]

The to_a method coerces a number to an array value. This method returns an array
reference using the subject as the first element.

=head2 to_code

    my $number = 5;
    my $result = $number->to_code; # sub { $number }

The to_code method coerces a number to a code value. The code reference, when
executed, will return the subject.

=head2 to_c

    my $number = 5;
    my $result = $number->to_c; # sub { $number }

The to_c method coerces a number to a code value. The code reference, when
executed, will return the subject.

=head2 to_hash

    my $number = 5;
    my $result = $number->to_hash; # {5=>1}

The to_hash method coerces a number to a hash value. This method returns a hash
reference with a single element using the subject as the key, and the number 1
as the value.

=head2 to_h

    my $number = 5;
    my $result = $number->to_h; # {5=>1}

The to_h method coerces a number to a hash value. This method returns a hash
reference with a single element using the subject as the key, and the number 1
as the value.

=head2 to_number

    my $number = 5;
    my $result = $number->to_number; # 5

The to_number method coerces a number to a number value. This method merely
returns the subject.

=head2 to_n

    my $number = 5;
    my $result = $number->to_n; # 5

The to_n method coerces a number to a number value. This method merely returns
the subject.

=head2 to_string

    my $number = 5;
    my $result = $number->to_string; # '5'

The to_string method coerces a number to a string value. This method returns a
string representation of the subject.

=head2 to_s

    my $number = 5;
    my $result = $number->to_s; # '5'

The to_s method coerces a number to a string value. This method returns a string
representation of the subject.

=head2 to_undef

    my $number = 5;
    my $result = $number->to_undef; # undef

The to_undef method coerces a number to an undef value. This method merely
returns an undef value.

=head2 to_u

    my $number = 5;
    my $result = $number->to_u; # undef

The to_u method coerces a number to an undef value. This method merely returns
an undef value.

=head1 SEE ALSO

=over 4

=item *

L<Bubblegum::Object::Array>

=item *

L<Bubblegum::Object::Code>

=item *

L<Bubblegum::Object::Hash>

=item *

L<Bubblegum::Object::Instance>

=item *

L<Bubblegum::Object::Integer>

=item *

L<Bubblegum::Object::Number>

=item *

L<Bubblegum::Object::Scalar>

=item *

L<Bubblegum::Object::String>

=item *

L<Bubblegum::Object::Undef>

=item *

L<Bubblegum::Object::Universal>

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
