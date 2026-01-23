package Acme::ExtUtils::XSOne::Test::Calculator::Scientific;

use strict;
use warnings;
use Acme::ExtUtils::XSOne::Test::Calculator;

1;

__END__

=head1 NAME

Acme::ExtUtils::XSOne::Test::Calculator::Scientific - Scientific and advanced mathematical operations

=head1 SYNOPSIS

    # Import specific functions
    use Acme::ExtUtils::XSOne::Test::Calculator::Scientific qw(power sqrt_val factorial);

    my $pow  = power(2, 10);    # 1024
    my $sqrt = sqrt_val(16);    # 4
    my $fact = factorial(5);    # 120

    # Or use fully qualified names
    use Acme::ExtUtils::XSOne::Test::Calculator;

    my $log = Acme::ExtUtils::XSOne::Test::Calculator::Scientific::log_natural(10); # ~2.303

=head1 EXPORTABLE FUNCTIONS

All functions can be imported by name:

    power sqrt_val cbrt_val nth_root log_natural log10_val log_base exp_val
    factorial ipow safe_sqrt safe_log combination permutation

=head1 DESCRIPTION

This module provides scientific and advanced mathematical operations as part of the
L<Acme::ExtUtils::XSOne::Test::Calculator> distribution. All operations
record their results in the shared calculation history.

=head1 FUNCTIONS

=head2 power

    my $result = power($base, $exp);

Returns C<$base> raised to the power of C<$exp>.

=head2 sqrt_val

    my $result = sqrt_val($a);

Returns the square root of C<$a>. Croaks if C<$a> is negative.

=head2 cbrt_val

    my $result = cbrt_val($a);

Returns the cube root of C<$a>.

=head2 nth_root

    my $result = nth_root($a, $n);

Returns the C<$n>th root of C<$a>. Croaks if C<$n> is zero or if
taking an even root of a negative number.

=head2 log_natural

    my $result = log_natural($a);

Returns the natural logarithm (base e) of C<$a>.
Croaks if C<$a> is not positive.

=head2 log10_val

    my $result = log10_val($a);

Returns the base-10 logarithm of C<$a>.
Croaks if C<$a> is not positive.

=head2 log_base

    my $result = log_base($a, $base);

Returns the logarithm of C<$a> with the specified C<$base>.
Croaks if arguments are invalid.

=head2 exp_val

    my $result = exp_val($a);

Returns e raised to the power of C<$a>.

=head2 factorial

    my $result = factorial($n);

Returns the factorial of C<$n> (i.e., C<n!>).
Croaks if C<$n> is negative or greater than 170.

=head2 ipow

    my $result = ipow($base, $exp);

Returns C<$base> raised to the integer power C<$exp>.
This is faster than C<power()> for integer exponents.

=head2 safe_sqrt

    my $result = safe_sqrt($a);

Returns the square root of C<$a>, or C<0> if C<$a> is negative
(instead of croaking).

=head2 safe_log

    my $result = safe_log($a);

Returns the natural logarithm of C<$a>, or C<0> if C<$a> is not positive
(instead of croaking).

=head2 combination

    my $result = combination($n, $r);

Returns the number of combinations (binomial coefficient) C<C(n,r)>.

=head2 permutation

    my $result = permutation($n, $r);

Returns the number of permutations C<P(n,r)>.

=head1 SEE ALSO

L<Acme::ExtUtils::XSOne::Test::Calculator>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Basic>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Trig>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Memory>

=cut
