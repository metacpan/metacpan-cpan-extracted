package Astro::Montenbruck::Time::Sidereal;
use strict;
use warnings;

use Readonly;
use Exporter qw/import/;
use Astro::Montenbruck::MathUtils qw/reduce_deg frac/;
use Astro::Montenbruck::Time qw/jd_cent/;
use Astro::Montenbruck::NutEqu qw/deltas obliquity/;

our @EXPORT = qw/ramc lmst/;

our $VERSION = 0.01;

Readonly::Scalar our $SOLAR_TO_SIDEREAL => 1.002737909350795;
# Difference in between Sidereal and Solar hour (the former is shorter)

sub ramc {
    my ( $jd, $lambda ) = @_;
    my $t = jd_cent($jd);

    my ($dpsi) = deltas($t);

    # Correction for apparent S.T.
    my $corr = $dpsi * cos( obliquity($t) ) / 3600;

    # Mean Local S.T.
    my $result =
      280.46061837 + 360.98564736629 * ( $jd - 2451545 ) + 0.000387933 * $t * $t
      - $t**3 / 38710000 + $corr;

    $result -= $lambda;
    reduce_deg($result);
}

sub lmst {
    my ($mjd, $lambda) = @_;

    my $mj0 = int($mjd);
    my $ut = ($mjd - $mj0) * 24; 
    my $t = ($mj0 - 51544.5) / 36525.0;
    my $gmst = 6.697374558 + 1.0027379093 * $ut + (8640184.812866 + (0.093104 - 6.2E-6 * $t) * $t) * $t / 3600.0;
    24.0 * frac( ($gmst - $lambda / 15.0) / 24.0 );   
}


1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Time::Sidereal - Sidereal time related calculations.

=head1 VERSION

Version 0.01


=head1 DESCRIPTION

Sidereal time related calculations.

=head1 EXPORT

=over

=item * L</ramc($jd, $lambda)>

=back

=head1 SUBROUTINES/METHODS

=head2 ramc($jd, $lambda)

Right Ascension of the Meridian

=head3 Arguments

=over

=item * B<$jd> — Standard Julian Date.

=item * B<$lambda> — geographic longitude in degrees, negative for East

=back

=head2 lmst($mjd, $lambda)

Local Mean Sidereal Time

=head3 Arguments

=over

=item * B<$jd> — Modified Julian Date.

=item * B<$lambda> — geographic longitude in degrees, negative for East

=back


=head3 Returns

Right Ascension of Meridian, arc-degrees

=cut
