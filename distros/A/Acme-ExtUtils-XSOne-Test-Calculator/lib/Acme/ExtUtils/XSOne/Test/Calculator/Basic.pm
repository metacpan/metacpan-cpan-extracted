package Acme::ExtUtils::XSOne::Test::Calculator::Basic;

use strict;
use warnings;
use Acme::ExtUtils::XSOne::Test::Calculator;

1;

__END__

=head1 NAME

Acme::ExtUtils::XSOne::Test::Calculator::Basic - Basic arithmetic operations

=head1 SYNOPSIS

    # Import specific functions
    use Acme::ExtUtils::XSOne::Test::Calculator::Basic qw(add subtract multiply);

    my $sum  = add(2, 3);       # 5
    my $diff = subtract(10, 4); # 6
    my $prod = multiply(3, 4);  # 12

    # Or use fully qualified names
    use Acme::ExtUtils::XSOne::Test::Calculator;

    my $quot = Acme::ExtUtils::XSOne::Test::Calculator::Basic::divide(15, 3);   # 5
    my $mod  = Acme::ExtUtils::XSOne::Test::Calculator::Basic::modulo(17, 5);   # 2

=head1 EXPORTABLE FUNCTIONS

All functions can be imported by name:

    add subtract multiply divide modulo negate absolute safe_divide clamp percent

=head1 DESCRIPTION

This module provides basic arithmetic operations as part of the
L<Acme::ExtUtils::XSOne::Test::Calculator> distribution. All operations
record their results in the shared calculation history.

=head1 FUNCTIONS

=head2 add

    my $result = add($a, $b);

Returns the sum of C<$a> and C<$b>.

=head2 subtract

    my $result = subtract($a, $b);

Returns C<$a> minus C<$b>.

=head2 multiply

    my $result = multiply($a, $b);

Returns the product of C<$a> and C<$b>.

=head2 divide

    my $result = divide($a, $b);

Returns C<$a> divided by C<$b>. Croaks if C<$b> is zero.

=head2 modulo

    my $result = modulo($a, $b);

Returns the floating-point remainder of C<$a> divided by C<$b>.
Croaks if C<$b> is zero.

=head2 negate

    my $result = negate($a);

Returns the negation of C<$a> (i.e., C<-$a>).

=head2 absolute

    my $result = absolute($a);

Returns the absolute value of C<$a>.

=head2 safe_divide

    my $result = safe_divide($a, $b);

Returns C<$a> divided by C<$b>, or C<0> if C<$b> is zero
(instead of croaking).

=head2 clamp

    my $result = clamp($value, $min, $max);

Returns C<$value> constrained to the range C<[$min, $max]>.

=head2 percent

    my $result = percent($value, $pct);

Returns C<$pct> percent of C<$value> (i.e., C<$value * $pct / 100>).

=head1 SEE ALSO

L<Acme::ExtUtils::XSOne::Test::Calculator>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Scientific>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Trig>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Memory>

=cut
