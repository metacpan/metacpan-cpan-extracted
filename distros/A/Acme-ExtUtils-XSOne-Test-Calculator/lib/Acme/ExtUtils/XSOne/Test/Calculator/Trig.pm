package Acme::ExtUtils::XSOne::Test::Calculator::Trig;

use strict;
use warnings;
use Acme::ExtUtils::XSOne::Test::Calculator;

1;

__END__

=head1 NAME

Acme::ExtUtils::XSOne::Test::Calculator::Trig - Trigonometric functions

=head1 SYNOPSIS

    # Import specific functions
    use Acme::ExtUtils::XSOne::Test::Calculator::Trig qw(sin_val cos_val deg_to_rad);

    my $sin = sin_val(3.14159/2);  # ~1.0
    my $cos = cos_val(0);          # 1.0
    my $rad = deg_to_rad(180);     # ~3.14159

    # Or use fully qualified names
    use Acme::ExtUtils::XSOne::Test::Calculator;

    my $tan = Acme::ExtUtils::XSOne::Test::Calculator::Trig::tan_val(0.785398);   # ~1.0
    my $deg = Acme::ExtUtils::XSOne::Test::Calculator::Trig::rad_to_deg(3.14159); # ~180

=head1 EXPORTABLE FUNCTIONS

All functions can be imported by name:

    sin_val cos_val tan_val asin_val acos_val atan_val atan2_val
    deg_to_rad rad_to_deg hypot_val normalize_angle
    sec_val csc_val cot_val is_valid_asin_arg

=head1 DESCRIPTION

This module provides trigonometric functions as part of the
L<Acme::ExtUtils::XSOne::Test::Calculator> distribution. All angles are
in radians unless otherwise noted. Operations record their results
in the shared calculation history.

=head1 FUNCTIONS

=head2 sin_val

    my $result = sin_val($radians);

Returns the sine of C<$radians>.

=head2 cos_val

    my $result = cos_val($radians);

Returns the cosine of C<$radians>.

=head2 tan_val

    my $result = tan_val($radians);

Returns the tangent of C<$radians>.

=head2 asin_val

    my $result = asin_val($x);

Returns the arc sine (inverse sine) of C<$x> in radians.
Croaks if C<$x> is not in the range C<[-1, 1]>.

=head2 acos_val

    my $result = acos_val($x);

Returns the arc cosine (inverse cosine) of C<$x> in radians.
Croaks if C<$x> is not in the range C<[-1, 1]>.

=head2 atan_val

    my $result = atan_val($x);

Returns the arc tangent (inverse tangent) of C<$x> in radians.

=head2 atan2_val

    my $result = atan2_val($y, $x);

Returns the arc tangent of C<$y/$x> in radians, using the signs of
both arguments to determine the quadrant of the result.

=head2 deg_to_rad

    my $radians = deg_to_rad($degrees);

Converts degrees to radians.

=head2 rad_to_deg

    my $degrees = rad_to_deg($radians);

Converts radians to degrees.

=head2 hypot_val

    my $result = hypot_val($a, $b);

Returns the hypotenuse of a right triangle with sides C<$a> and C<$b>
(i.e., C<sqrt($a*$a + $b*$b)>).

=head2 normalize_angle

    my $result = normalize_angle($radians);

Normalizes an angle to the range C<[-PI, PI]>.

=head2 sec_val

    my $result = sec_val($radians);

Returns the secant of C<$radians> (i.e., C<1/cos($radians)>).

=head2 csc_val

    my $result = csc_val($radians);

Returns the cosecant of C<$radians> (i.e., C<1/sin($radians)>).

=head2 cot_val

    my $result = cot_val($radians);

Returns the cotangent of C<$radians> (i.e., C<cos($radians)/sin($radians)>).

=head2 is_valid_asin_arg

    my $bool = is_valid_asin_arg($x);

Returns true if C<$x> is a valid argument for C<asin_val()> or C<acos_val()>
(i.e., in the range C<[-1, 1]>).

=head1 SEE ALSO

L<Acme::ExtUtils::XSOne::Test::Calculator>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Basic>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Scientific>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Memory>

=cut
