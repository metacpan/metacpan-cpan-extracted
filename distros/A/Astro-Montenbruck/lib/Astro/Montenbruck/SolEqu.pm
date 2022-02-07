package Astro::Montenbruck::SolEqu;

use strict;
use warnings;

use Exporter qw/import/;
use Readonly;
use Math::Trig qw/deg2rad/;
use Astro::Montenbruck::MathUtils qw/angle_c/;
use Astro::Montenbruck::Time::DeltaT qw/delta_t/;
use Astro::Montenbruck::Time qw/jd_cent $SEC_PER_DAY/;
use Astro::Montenbruck::Ephemeris::Planet::Sun;
use Astro::Montenbruck::NutEqu qw/mean2true/;


Readonly our $MARCH_EQUINOX     => 0;
Readonly our $JUNE_SOLSTICE     => 1;
Readonly our $SEPTEMBER_EQUINOX => 2;
Readonly our $DECEMBER_SOLSTICE => 3;

Readonly my $DELTA => 1e-4; 

Readonly::Array our @SOLEQU_EVENTS => ($MARCH_EQUINOX, $JUNE_SOLSTICE, $SEPTEMBER_EQUINOX, $DECEMBER_SOLSTICE);
our @CONSTS = qw/$MARCH_EQUINOX $JUNE_SOLSTICE $SEPTEMBER_EQUINOX $DECEMBER_SOLSTICE @SOLEQU_EVENTS/;

our %EXPORT_TAGS = (
    events => \@CONSTS,
    all    => [ @CONSTS, 'solequ' ]
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

our $VERSION   = 0.02;

sub solequ {
    my ($year, $k) = @_;

    # find approximate time in Julian Days
    # k = 0 for March equinox,
    #     1 for the Julne solstice
    #     2 for the September equinox
    #     3 for the December solstice 
    # print("k = $k, year = $year\n");
    my $j = ($year + $k / 4) * 365.2422 + 1721141.3;
    # print("j = $j\n");
	my $k90 = $k * 90;
    my $sun = Astro::Montenbruck::Ephemeris::Planet::Sun->new();
    my $nut_func = mean2true(jd_cent($j)); 
    my $x = -1000;
    my $last_x;
    do {
        $last_x = $x;
        my $t = jd_cent($j);
        my @lbr = $sun->sunpos($t);
        my $nut_func = mean2true($t);
        ($x) =  $sun->apparent($t, \@lbr, $nut_func); # apparent geocentric ecliptical coordinates
        $j += 58 * sin(deg2rad($k90 - $x));
        # print("j = $j, x = $x, last_x = $last_x\n")
    } until(angle_c($k90, $x) < $DELTA || $x == $last_x);

    my $dt = delta_t($j);
	$j -= $dt / $SEC_PER_DAY;
    wantarray ? ($j, $x) : $j
}

1;
__END__


=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::SolEqu - Solstices and Equinoxes.

=head1 SYNOPSIS

  use Astro::Montenbruck::SolEqu qw/:all/;

  # find solstices and equinoxes for year 2020
  for my $event (@SOLEQU_EVENTS) 
  {
      my $jd = solequ(2020, $event);
      # ...
  }


=head1 DESCRIPTION

The times of he equinoxes and solstices are the instants when the apparent longiude
of the Sun is a multiple of B<90 degrees>.

Searches solstices and eqinoxes. Algorithms are based on
I<"Astronomical Formulae for Calculators"> by I<Jean Meeus>, I<Forth Edition>, I<Willmann-Bell, Inc., 1988>.


=head1 EXPORT

=head2 CONSTANTS

=head3 EVENTS

=over

=item * C<$MARCH_EQUINOX>

=item * C<$JUNE_SOLSTICE>

=item * C<$SEPTEMBER_EQUINOX>

=item * C<$DECEMBER_SOLSTICE>

=back

=head3 ARRAY OF THE EVENTS 

=over

=item * C<@SOLEQU_EVENTS> 

=back

Array of L<EVENTS> in proper order.


=head1 SUBROUTINES


=head2 solequ

Find Julian Day of solstice or equinox for a given year.

    use Astro::Montenbruck::SolEqu qw/:all/;

	my $jd = Astro::Montenbruck::Ephemeris::Sun->solequ($year, $k);

The result is accurate within I<5 minutes> of Universal Time.

=head3 Arguments

=over

=item 1.

number of a year (negative for B.C., astronomical)

=item 2.

type of event, defined by the constants (see L<Events>).

=back

=head3 Result

In scalar context retuns I<Standard Julian Day>. 
In list context: array of:

=over

=item 1. 

I<Standard Julian Day> and Sun's longitude, in arc-dgrees.

=item 2. 

Sun's longitude, arc-dgrees.

=back


=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2022 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
