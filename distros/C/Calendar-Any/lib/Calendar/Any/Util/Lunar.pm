package Calendar::Any::Util::Lunar;
{
  $Calendar::Any::Util::Lunar::VERSION = '0.5';
}
use Calendar::Any::Util::Solar;
use Calendar::Any::Gregorian;
use Math::Trig qw(deg2rad);
use POSIX qw/floor/;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
new_moon_date
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#==========================================================
# Input  : Calendar Object or absolute_date, timezone
# Output : *absolute date* that first new moon on or after
#          input date
# Desc   :
#==========================================================
sub new_moon_date {
    my $d = shift;
    my $tz = shift;
    my $date;
    if ( ref $d && ref $d eq 'Calendar::Any::Gregorian' ) {
        $date = $d;
    } else {
        $date = Calendar::Any::Gregorian->new(ref $d ? $d->absolute_date : $d);
    }
    $d = $date->astro_date();
    my $year = $date->year + $date->day_of_year / 365.25;
    my $k = floor(($year-2000)*12.3685);
    $date = _new_moon_time($k, $tz);
    while ( $date <$d ) {
        $k++;
        $date = _new_moon_time($k, $tz);
    }
    # TODO: daylight time offset
    return Calendar::Any->new_from_Astro($date)->absolute_date;
}

sub _new_moon_time {
    my $k = shift;
    my $tz = shift;
    defined($tz) || ($tz = $Calendar::Any::Util::Solar::timezone);
    my $T = $k / 1236.85;
    my $T2 = $T * $T;
    my $T3 = $T2 * $T;
    my $T4 = $T2 * $T2;
    my $JDE =  2451550.09765 + 29.530588853*$k
        + 0.0001337*$T2 - 0.000000150*$T3 + 0.00000000073*$T4;
    my $E = 1 - 0.002516*$T - 0.0000074*$T2;
	 my $sun_anomaly =  deg2rad(2.5534 +  29.10535669*$k - 0.0000218*$T2
         - 0.00000011*$T3);
    my $moon_anomaly = deg2rad(201.5643 +385.81693528*$k + 0.0107438*$T2
        + 0.00001239*$T3 - 0.000000058*$T4);
    my $moon_argument = deg2rad(160.7108 + 390.67050274*$k - 0.0016341*$T2
        - 0.00000227*$T3 + 0.000000011*$T4);
    my $omega = deg2rad(124.7746 - 1.56375580*$k + 0.0020691*$T2 + 0.00000215*$T3);
    my $A1  = deg2rad(299.77 +  0.107408 * $k - 0.009173 * $T2);
    my $A2  = deg2rad(251.88 +  0.016321 * $k);
    my $A3  = deg2rad(251.83 + 26.641886 * $k);
    my $A4  = deg2rad(349.42 + 36.412478 * $k);
    my $A5  = deg2rad( 84.66 + 18.206239 * $k);
    my $A6  = deg2rad(141.74 + 53.303771 * $k);
    my $A7  = deg2rad(207.14 +  2.453732 * $k);
    my $A8  = deg2rad(154.84 +  7.306860 * $k);
    my $A9  = deg2rad( 34.52 + 27.261239 * $k);
    my $A10 = deg2rad(207.19 +  0.121824 * $k);
    my $A11 = deg2rad(291.34 +  1.844379 * $k);
    my $A12 = deg2rad(161.72 + 24.198154 * $k);
    my $A13 = deg2rad(239.56 + 25.513099 * $k);
    my $A14 = deg2rad(331.55 +  3.592518 * $k);

    my $correction = -0.40720*sin($moon_anomaly)
 + 0.17241 * $E *sin($sun_anomaly)
 + 0.01608 * sin(2 * $moon_anomaly)
 + 0.01039 * sin(2*$moon_argument)
 + 0.00739 * $E * sin( $moon_anomaly - $sun_anomaly)
 - 0.00514 * $E * sin($moon_anomaly + $sun_anomaly)
 + 0.00208 * $E * $E * sin(2*$sun_anomaly)
 - 0.00111 * sin($moon_anomaly - 2*$moon_argument)
 - 0.00057 * sin($moon_anomaly + 2*$moon_argument)
 + 0.00056 * $E * sin(2*$moon_anomaly+ $sun_anomaly)
 - 0.00042 * sin(3*$moon_anomaly)
 + 0.00042 * $E * sin($sun_anomaly+ 2* $moon_argument)
 + 0.00038 * $E * sin($sun_anomaly - 2* $moon_argument)
 - 0.00024 * $E * sin(2*$moon_anomaly - $sun_anomaly)
 - 0.00017 * sin($omega)
 - 0.00007 * sin($moon_anomaly + 2*$sun_anomaly)
 + 0.00004 * sin(2*$moon_anomaly -  2*$moon_argument)
 + 0.00004 * sin(3*$sun_anomaly)
 + 0.00003 * sin($moon_anomaly+ $sun_anomaly -2 *$moon_argument)
 + 0.00003 * sin(2*$moon_anomaly +  2* $moon_argument)
 - 0.00003 * sin($moon_anomaly + $sun_anomaly + 2* $moon_argument)
 + 0.00003 * sin($moon_anomaly - $sun_anomaly + 2*$moon_argument)
 - 0.00002 * sin($moon_anomaly - $sun_anomaly - 2* $moon_argument)
 - 0.00002 * sin(3*$moon_anomaly + $sun_anomaly)
 + 0.00002 * sin(4*$moon_anomaly);

    my $additional = 0
 + 0.000325 * sin($A1)
 + 0.000165 * sin($A2)
 + 0.000164 * sin($A3)
 + 0.000126 * sin($A4)
 + 0.000110 * sin($A5)
 + 0.000062 * sin($A6)
 + 0.000060 * sin($A7)
 + 0.000056 * sin($A8)
 + 0.000047 * sin($A9)
 + 0.000042 * sin($A10)
 + 0.000040 * sin($A11)
 + 0.000037 * sin($A12)
 + 0.000035 * sin($A13)
 + 0.000023 * sin($A14);
    my $newJDE = $JDE +$correction+$additional;
    my $ec = Calendar::Any::Util::Solar::_ephemeris_correction(
        Calendar::Any->new_from_Astro($newJDE)->to_Gregorian->year
    );
    return $newJDE - Calendar::Any::Util::Solar::_ephemeris_correction(
        Calendar::Any->new_from_Astro($newJDE)->to_Gregorian->year
    ) + $tz/60/24;
}

1;

__END__

=head1 NAME

Calendar::Any::Lunar - Lunar event functions

=head1 VERSION

version 0.5

=head1 SYNOPSIS

      use Calendar::Any::Lunar qw(new_moon_date);
      use Calendar::Any::Gregorian;
      my $date = Calendar::Any::Gregorian->new(12, 15, 2006);
      my $next_newmoon = Calendar::Any::Gregorian->new(new_moon_date($date, 30));
      print "The new next moon date is in $next_newmoon.\n";

=head1 DESCRIPTION

This library implement one function in emacs library lunar.el.
new_moon_date is used to calculte the next new moon date.

=head1 AUTHOR

Ye Wenbin <wenbinye@gmail.com>

=cut
