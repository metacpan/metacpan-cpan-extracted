package DateTime::Event::Jewish::Haversine;
use strict;
use warnings;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(recalculate_coordinate azimuth elevation point2distance);
use Math::Trig;
our $VERSION = '0.01';


#  Python implementation of Haversine formula
#  Copyright (C) <2009>  Bartek Garny <bartek at gorny.edu.pl>
#  Converted to Perl by Raphael Mankin <rapmankin at cpan.org> Feb 2010
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#
#  Apparent angular diameters
#  Sun: 31.6' - 32.7'
#  Moon: 29.3' - 34.1'

=head1 NAME

Haversine.pm - Calculations using haversine formula

=head1 SYNOPSIS

  use Haversine;
  my $degrees	= recalculate_coordinate([51, 12, 0], 'deg');
  my $radians	= recalculate_coordinate([51, 12, 0], 'rad');
  my $km  = points2distance($start, $end);
  my $degrees  = azimuth($start, $end, 'deg');

=cut


=head3 recalculate_coordinate($location, $as)

Convert a tupe of (degrees, minutes, seconds) to a normal form.

=over

=item $location

An arrayref of three components: degrees, minutes, seconds.

=item $as

Return value type. Can be specified as 'deg', 'min', 'sec' or 'rad'; default
return value is a proper coordinate tuple.

=back

=cut

sub recalculate_coordinate {
    my $val = shift;
    my $_as = shift;
  
#    Accepts a coordinate as a tuple (degree, minutes, seconds)
#    You can give only one of them (e.g. only minutes as a floating point number) and it will be duly
#    recalculated into degrees, minutes and seconds.


  my ($deg,  $min,  $sec) = @$val;
  # pass outstanding values from right to left
  $min = ($min or 0) + int($sec) / 60;
  $sec = $sec % 60;
  $deg = ($deg or 0) + int($min) / 60;
  $min = $min % 60;
  # pass decimal part from left to right
  my $dint	= int($deg);
  my $dfrac	= $deg - $dint;
  $min = $min + $dfrac * 60;
  $deg = $dint;
  my $mint	= int($min);
  my $mfrac	= $min - $mint;
  $sec = $sec + $mfrac * 60;
  $min = $mint;
  if ($_as) {
    $sec = $sec + $min * 60 + $deg * 3600;
    if ($_as eq 'sec') { return $sec;}
    if ($_as eq 'min') { return $sec / 60;}
    if ($_as eq 'deg') { return $sec / 3600;}
    if ($_as eq 'rad') { return deg2rad($sec / 3600);}
  }
  return [$deg,  $min,  $sec];
}
      

=head3 points2distance($start, $end)

Calculate distance (in kilometers) between two points
given as (lat, long) pairs based on Haversine formula
(http://en.wikipedia.org/wiki/Haversine_formula).
Implementation inspired by JavaScript implementation from http://www.movable-type.co.uk/scripts/latlong.html

Accepts coordinates as tuples (deg, min, sec), but coordinates can be given in any form - e.g.
can specify only minutes:
(0, 3133.9333, 0) 
is interpreted as 
(52.0, 13.0, 55.998000000008687)
which, not accidentally, is the latitude of Warsaw, Poland.

=cut

sub points2distance {
    my ($start,  $end)	= @_;
    shift; shift;
    my $_as	=shift;
  
  
  my $start_lat	= recalculate_coordinate($start->[0], 'rad');
  my $start_long= recalculate_coordinate($start->[1], 'rad');
  my $end_long	= recalculate_coordinate($end->[1], 'rad');
  my $end_lat	= recalculate_coordinate($end->[0], 'rad');
  my $d_lat	= $end_lat - $start_lat;
  my $d_long	= $end_long - $start_long;
  my $a	= sin($d_lat/2)**2 + cos($start_lat) * cos($end_lat) * sin($d_long/2)**2;
  my $c	= 2 * atan2(sqrt($a),  sqrt(1-$a));
  if ($_as) {
     if ($_as eq 'rad'){ return $c;}
     if ($_as eq 'deg'){ return rad2deg($c);}
  }
  return 6371 * $c;
}

=head3 azimuth($start, $end)

Calculate azimuth (bearing) of one point from another
given as (lat, long) pairs based on Haversine formula

=cut

sub azimuth {
    my ($start, $end)	= @_;
    shift; shift;
    my $_as= shift||'deg';
    
#	Calculate the azimuth (initial bearing) to travel by a 
#	great circle path from 'start' to 'end'
    
    my $phi1	= recalculate_coordinate($start->[0], 'rad');
    my $phi2	= recalculate_coordinate($end->[0], 'rad');
    my $lambda1	= recalculate_coordinate($start->[1], 'rad');
    my $lambda2	= recalculate_coordinate($end->[1], 'rad');
    my $y	= sin($lambda2-$lambda1)*cos($phi2);
    my $x	= cos($phi1)*sin($phi2) - sin($phi1)*cos($phi2)*cos($lambda2-$lambda1);
    my $az	= atan2($y,$x);
    if ($az < 0) { $az += 2*pi; }
    if ($_as) {
        if($_as eq 'deg'){ return rad2deg($az);}
    }
    return $az;
}

=head3 elevation($ground, $star)

Calculate the elevation of a star as seen from a point on the ground.
'star' is the declination and hour angle (lat, long) of the star,
'ground' is the (lat,long) of the ground point.

The elevation is just the complement of the angular distance between
the two ground points. We assume that the star is at infinity. Not quite
true for the sun or moon.

=cut

sub  elevation {
    my ($ground, $star)	= @_;
    shift; shift;
    my $_as= shift||'deg';
    
    
    my $el	= 90-points2distance($ground, $star, 'deg');
    if ($_as eq 'rad') { return deg2rad($el);}
    return $el;
}

1;

__END__

    my $warsaw = [[52, 13, 56], [21,  0,  30]];
    my $cracow = [[50, 3, 41], [19, 56, 18]];
    my $london = [[51, 29, 0], [0,0,0]];
    my $jerusalem = [[31, 47, 00], [35, 13,0]];
    print points2distance($warsaw,  $cracow);
    print points2distance($warsaw,  $cracow, 'deg');
    print points2distance($london,  $jerusalem);
    print points2distance($london,  $jerusalem, 'deg');
    print azimuth($london,  $jerusalem, 'deg');
    print azimuth($jerusalem, $london);

1;

=head1 AUTHOR

Raphael Mankin, C<< <rapmankin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datetime-event-jewish at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Event-Jewish>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Event::Jewish


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Event-Jewish>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-Event-Jewish>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Event-Jewish>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Event-Jewish/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Raphael Mankin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of DateTime::Event::Haversine
