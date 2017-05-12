# $Id: /local/datetime/modules/DateTime-Util-Calc/trunk/lib/DateTime/Util/Calc.pm 11779 2007-05-29T22:12:48.788920Z daisuke  $
#
# Copyright (c) 2004-2015 Daisuke Maki <daisuke@endeworks.jp>

package DateTime::Util::Calc;
use strict;
use warnings;
use Carp qw(carp);
use Exporter;
use DateTime;
use Math::BigInt   ('lib' => 'GMP,Pari,FastCalc');
use Math::BigFloat ('lib' => 'GMP,Pari,FastCalc');
use Math::Trig ();
use POSIX();

use constant RATA_DIE => DateTime->new(year => 1, time_zone => 'UTC');

use vars qw($VERSION @EXPORT_OK);
use vars qw($DOWNGRADE_ACCURACY);
BEGIN
{
    *import = \&Exporter::import;
    $VERSION = '0.13003';
    @EXPORT_OK = qw(
        bf_downgrade
        bi_downgrade
        binary_search
        search_next
        angle
        polynomial
        sin_deg
        cos_deg
        tan_deg
        asin_deg acos_deg mod amod min
        max bigfloat bigint moment dt_from_moment rata_die
        truncate_to_midday
        revolution
        rev180
    );

    $DOWNGRADE_ACCURACY = 32;
}

sub rata_die { RATA_DIE->clone }

sub bigfloat
{
    return
        UNIVERSAL::isa($_[0], 'Math::BigFloat') ? $_[0] :
            Math::BigFloat->new($_[0]);
}

sub bigint
{
    return UNIVERSAL::isa($_[0], 'Math::BigInt') ? $_[0] : Math::BigInt->new($_[0]);
}

my $warn_bf_downgrade = 0;
my $warn_bi_downgrade = 0;
sub bf_downgrade
{
    $warn_bf_downgrade++ or carp "DateTime::Util::Calc::bf_downgrade has been deprecated, and will be removed in future versions.";
    return $_[0];
}

sub bi_downgrade
{
    $warn_bi_downgrade++ or carp "DateTime::Util::Calc::bi_downgrade has been deprecated, and will be removed in future versions.";
    return $_[0];
}   

sub angle
{
    Math::BigFloat->new($_[0]) + (Math::BigFloat->new($_[1]) + (Math::BigFloat->new($_[2]) / 60)) / 60;
}

# polynomial($x, $a(0) ... $a(n))
sub polynomial
{
    if (@_ == 1) {
        require Carp;
        Carp::croak('polynomial requires at least two arguments: polynomial($x, @coeffients)');
    }

    # XXX - There seems to be a bug in adding BigInt and BigFloat
    # Math::BigFloat->bzero must be used
    my $x   = Math::BigFloat->new(shift @_);
    my $v   = Math::BigFloat->bzero();
    my $ret = Math::BigFloat->new(shift @_);

    # reuse $v for sake of efficiency. we just want to check if $x
    # is zero or not
    if ($x == $v) {
        return $ret;
    }

    while (@_) {
        $v = $x * ($v + pop @_);
    }
    return $ret + $v;
}

sub deg2rad
{
    my $deg = ref($_[0]) ? $_[0]->bstr() : $_[0];
    return Math::Trig::deg2rad($deg > 360 ? $deg % 360 : $deg);
}

sub sin_deg  { CORE::sin(deg2rad($_[0])) }
sub cos_deg  { CORE::cos(deg2rad($_[0])) }
sub tan_deg  { Math::Trig::tan(deg2rad($_[0])) }
sub asin_deg
{
    my $v = ref($_[0]) ? $_[0]->bstr() : $_[0];
    return Math::Trig::rad2deg(Math::Trig::asin($v));
}

sub acos_deg
{
    my $v = ref($_[0]) ? $_[0]->bstr() : $_[0];
    Math::Trig::rad2deg(Math::Trig::acos($v));
}

sub mod
{
    my ($x, $y) = @_;

    # x mod y = x - y * (floor(x/y));

    if (ref($x) || ref($y)) {
        # Make sure both are M::BF
        $x = Math::BigFloat->new($x) if ! ref ($x);
        $y = Math::BigFloat->new($y) if ! ref ($y);

        return $x - $y * ( ($x / $y)->bfloor );
    } else {
        return $x - $y * ( POSIX::floor($x / $y) );
    }
}

sub amod { mod($_[0], $_[1]) || $_[1]; }
sub min  { $_[0] > $_[1] ? $_[1] : $_[0] }
sub max  { $_[0] < $_[1] ? $_[1] : $_[0] }

sub moment
{
    my $dt = shift;
    my($rd, $seconds) = $dt->utc_rd_values;
    return $rd + $seconds / (24 * 3600);
}

sub dt_from_moment
{
    my $moment  = Math::BigFloat->new('' . shift);

    # Truncate the moment down to an int
    my $rd_days = $moment->as_int();

    # Upgrade here to BigFloat to maintain accuracy to the second
    my $time    = ($moment - $rd_days) * 24 * 3600;
    my $dt      = rata_die();

    if ($rd_days || $time) {
        $dt->add(
            days    => ($rd_days - 1)->bstr(),
            seconds => $time->as_int()->bstr(),
        );
        $dt->truncate(to => 'second');
    }
    return $dt;
}

    
sub binary_search
{
    my ($lo, $hi, $mu, $phi) = @_;

    $lo = Math::BigFloat->new($lo);
    $hi = Math::BigFloat->new($hi);

    while (1) {
        my $x = ($lo + $hi) / 2;
        if ($mu->($lo, $hi)) {
            return $x;
        } elsif ($phi->($x)) {
            $hi = $x;
        } else {
            $lo = $x;
        }
    }
}

sub __increment_one { $_[0] + 1 }
sub search_next
{
    my %args = @_;
    my $x     = $args{base};
    my $check = $args{check};
    my $next  = $args{next} || \&__increment_one;
    while (! $check->($x) ) {
        $x = $next->($x);
    }
    return $x;
}

sub truncate_to_midday
{
    $_[0]->truncate(to => 'hour');
    $_[0]->set( hour => 12 );
    $_[0];
}

sub revolution
{
    #
    #
    # FUNCTIONAL SEQUENCE for revolution
    #
    # _GIVEN
    # any angle
    #
    # _THEN
    #
    # reduces any angle to within the first revolution 
    # by subtracting or adding even multiples of 360.0
    # 
    #
    # _RETURN
    #
    # the value of the input is >= 0.0 and < 360.0
    #

    my $x = $_[0];
    return ( $x - 360.0 * POSIX::floor( $x * ( 1.0 / 360.0 ) ) );
}

sub rev180
{
    #
    #
    # FUNCTIONAL SEQUENCE for rev180
    #
    # _GIVEN
    # 
    # any angle
    #
    # _THEN
    #
    # Reduce input to within +180..+180 degrees
    # 
    #
    # _RETURN
    #
    # angle that was reduced
    #
    my ($x) = @_;
    return ( $x - 360.0 * POSIX::floor( $x * ( 1.0 / 360.0 ) + 0.5 ) );
}


1;

__END__

=head1 NAME

DateTime::Util::Calc - DateTime Calculation Utilities

=head1 SYNOPSIS

  use DateTime::Util::Calc qw(polynomial);

  my @coeffs = qw(2 3 -2);
  my $x      = 5;
  my $rv     = polynomial($x, @coeffs);

=head1 DEPRECATION WARNING

You really should not be using this module. Math::BigInt nad friends are fine,
but they are not realistic for anything more complicated... like calendars.
If you need an astronomical calendar, use C (and/or provide a very thing
Perl wrapper over it)

Because the author has reached the above conclusion, this module should really
be considered deprecated. It will NOT be maintained regularly.

=head1 DESCRIPTION

This module contains some common calculation utilities that are required
to perform datetime calculations, specifically from "Calendrical Calculations"
-- they are NOT meant to be general purpose.

Nothing is exported by default. You must either explicitly export them,
or use as fully qualified function names.

=head1 FUNCTIONS

=head2 max($a, $b)

=head2 min($a, $b)

max() returns the bigger of $a and $b. min() returns the smaller of $a and $b.

=head2 polynomial($x, @coefs)

Calculates the value of a polynomial equation, based on Horner's Rule.

   c + b * x + a * (x ** 2)     x = 5

is expressed as:

   polynomial(5, c, b, a);

=head2 moment($dt)

=head2 dt_from_moment($moment)

moment() converts a DateTime object to moment, which is RD days + the time 
of day as fraction of the total seconds in a day.

dt_from_moment() converts a moment to DateTime object.

=head2 rata_die()

Returns a new DateTime object that is set to Rata Die, 0001-01-01 00:00:00 UTC

=head2 bigfloat($v)

=head2 bigint($v)

If the value $v is not a Math::BigFloat object, returns the value converted
to Math::BigFloat. Otherwise returns the value itself.

bigint() does the same for Math::BigInt.

=head2 bf_downgrade($v)

=head2 bi_downgrade($v)

These have been deprecated.

=head2 truncate_to_midday($dt)

Truncates the DateTime object to 12:00 noon.

=head2 sin_deg($degrees)

=head2 cos_deg($degrees)

=head2 tan_deg($degrees)

=head2 asin_deg($degrees)

=head2 acos_deg($degrees)

Each of these functions calculates their respective values based on degrees,
not radians (as Perl's version of sin() and cos() would do).

=head2 mod($v,$mod)

Calculates the modulus of $v over $mod. Perl's built-in modulus operator (%)
for some reason rounds numbers UP when a fractional number's modulus is
taken. Many of the calculations also needed the fractional part of the
calculation, so this function takes care of both.

Example:

  mod(12.234, 5) = 2.234

=head2 amod($v,$mod)

This function is almost identical to mod(), but when the regular modulus value
is 0, returns $mod instead of 0.

Example:

  amod(11, 5) = 1
  amod(10, 5) = 5
  amod(9, 5)  = 4
  amod(8, 5)  = 3

=head2 binary_search($hi, $lo, $mu, $phi)

This is a special version of binary search, where the terminating condition
is determined by the result of coderefs $mu and $phi.

$mu is passed the value of $hi and $lo. If it returns true upon execution,
then the search terminates. 

$phi is passed the next median value. If it returns true upon execution,
then the search terminates.

If the above two fails, then $hi and $lo are re-computed for the next
iteration.

=head2 search_next(%opts)

Performs a "linear" search until some condition is met. This is a generalized
version of the formula defined in [1] p.22. The basic idea is :

  x = base
  while (! check(x) ) {
     x = next(x);
  }
  return x

%opts can contain the following parameters:

=over 4

=item base

The initial value to use to start the search process. The value can be
anything, but you must provide C<check> and C<next> parameters that are
capable of handling the type of thing you specified.

=item check (coderef)

Code to be executed to determine the end of the search. The function receives
the current value of "x", and should return a true value if the condition
to end the loop has been reached

=item next (coderef, optional)

Code to be executed to determine the next value of "x". The function receives
the current value of "x", and should return the value to be used for the
next iteration.

If unspecified, it will use a function that blindly adds 1 to whatever x is.
(so if you specified a number for C<base>, it should work -- but if you
passed an object like DateTime, it will probably be an error)

=back

So for example, to iterate through 1 through 9, you could do something
like this

  my $x = search_next(
    base => 1,
    check => sub { $_[0] == 9 }
  );

And $x will be set to 9. For a more interesting example, we could look
for a DateTime object $dt matching a certain condition C<foo()>:

  my $dt = search_next(
    base  => $base_date,
    check => \&foo,
    next  => sub { $_[0] + DateTime::Duration->new(days => 1) }
  );

=head2 deg2rad

Converts degrees to radians using Math::Trig, but works for Math::BigInt
objects as well.

=head2 revolution($angle_in_degrees)

Reduces any angle to within the first revolution by sbtracting or adding
even multiples of 360.0.

=head2 rev180($angle_in_degrees)

Reduces input to within +180..+180 degrees

=head2 angle($h, $m, $s)

=head1 AUTHOR

Copyright (c) 2004-2015 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=cut

