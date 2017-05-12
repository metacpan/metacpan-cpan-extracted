package DateTime::Event::Jewish::Sunrise;
use strict;
use warnings;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
use DateTime;
use DateTime::Duration;
use Math::Trig;
use DateTime::Event::Jewish::Declination qw(declination %Declination);
use DateTime::Event::Jewish::ZoneLocation;
use DateTime::Event::Jewish::Eqt qw(eqt );
our $VERSION = '0.01';

our @months=("Jan", "Feb", "Mar", "Apr", "May", "Jun", 
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec");

@EXPORT_OK = qw(@months);

=head1 NAME

DateTime::Event::Jewish::Sunrise - Calculate halachically
interesting times

=head1 SYNOPSIS

use DateTime::Event::Jewish::Sunrise ;

my $jerusalem	= DateTime::Event::Jewish::Sunrise->new([31,34,57], [35,13,0]), 'Asia/Jerusalem';
my $date	= DateTime->new(year=>2010, month=>3, day=>30);

my $shkia	= $jerusalem->shkia($date);
my $shabbat	= $jerusalem->kabbalatShabbat($date);
my $netz	= $jerusalem->netzHachama($date);
my $night	= $jerusalem->motzeiShabbat($date);

=head1 DESCRIPTION

This module assumes that the earth is a smooth sphere. No
allowance is made for atmospheric refraction or diffraction of
light passing close to the earth's surface. To allow for
refraction one uses a depression of 0.833 degrees (50' arc). As,
by default, we use 1 degree of depression this is more than adequate.

The methods that return times actually return a DateTime
object in the correct timezone as specified in the constructor. 
If an evaluation fails, e.g. no sunrise inside the Arctic cirle,
undef is returned.

All times are corrected for the equation of time: the variation
between sundial time and clock time.

If you call this module for a high latitude in the height of
summer or the depth of winter it will return nonsense. Ask a silly
question and you will get a very silly answer.

Calculations are done using the spherical cosine rule.

=head3 new($latitude, $longitude, $timeZone)

Constructs a new object.

=over

=item $latitude

An arrayref of three numbers representing degrees, minutes and
seconds of latitude. North latitudes are positive, south
latitudes are negative.

=item $Longitude

An arrayref of three numbers representing degrees, minutes and
seconds of longitude. East longitudes are positive, west
longitudes are negative.

=item $timeZone

A time-zone name as stored in the time-zone database, e.g.
"Europe/London".

=back

=cut

sub new {
	my $class	= shift;
	my ($lat, $long, $zone)	= @_;
	my $self	= {lat=>$lat, long=>$long, zone=>$zone};
	bless $self, $class;
}


=head3 halachicHalfDay($date, [$extra])

Calculates the length of the halachic half day in minutes. This
is half the time between sunrise and sunset.

If you call this method for a high latitude in the height of
summer or the depth of winter it will return 0. Ask a silly
question and you will get a very silly answer.

=over 


=item $date

A DateTime object, either a Gregorian or a Hebrew date.
Only the day and month are relevant.

=item $extra

The number of degrees below the tangent plane that the sun
should be at halachic sunrise/set. Default 1.

=item returns

The length of the half-day in minutes. Returns 0 if there is no
sensible answer, e.g. inside the Arctic circle in summer.

=back

=cut

sub halachicHalfDay {
    my ($self, $hdate)	= @_;
    shift;shift;
    # Ensure that we have a Gregorian date
    my $date	= DateTime->from_object(object=>$hdate);
    my $extra= shift || 1;
    my $delta	= cos(deg2rad(90.0+$extra));
    # Convert the location to radians.
    my $phi	= recalculate_coordinate($self->{lat},"rad");

    my ($day, $month)	= ($date->day, $date->month);

    my $decl	= declination($date); # Radians

    #Protect against stupidity - works for both summer and winter.
    return 0 if abs($phi)+ abs($decl) +abs(deg2rad($extra)) > pi/2.0;

    # Find the longitude difference between the base point and the sun
    my $dlong	= acos(($delta - sin($phi)*sin($decl))/(cos($phi)*cos($decl)));
    # Each degree of longitude represents 4 minutes of time
    my $minutes_offset= rad2deg($dlong)*4.0;
    return $minutes_offset;
}

=head3 localnoon($date)

Returns a DateTime object of the local time of local noon. 

=over

=item $date

A DateTime object, either a Gregorian or a Hebrew date.
Only the day and month are relevant.

=back

=cut

sub localnoon {
    my $self	= shift;
    my $hdate	= shift;
    my $date = DateTime->from_object(object=>$hdate);
    # Extract the longitude so that we can do the correct shift
    my $longref	= $self->{long};
    my $long	= $longref->[0] + $longref->[1]/60.0 + $longref->[2]/3600.0;
    $date->set_time_zone("UTC");
    $date->set_hour(12);
    $date->set_minute(0);
    $date->set_second(0);
    my $res	=  $date - DateTime::Duration->new(minutes=>eqt($date)+4*$long);
    # We now have the correct time, but expressed in UTC
    # So change the time-zone to what the user expects.
    $res->set_time_zone($self->{zone});
    return $res;
}

=head3 halfday($date, [$as])

Calculates the offset in minutes from local noon of sunrise/sunset at
the given location on the specified day of the year.
i.e. the time when the sun is 90 degrees from the zenith.

=over 

=item $date

A DateTime object. Only the day and month are relevant.
N.B. This is a Gregorian date.

=item Returns

The length of the ahlf day in minutes. Returns 0 if there is no
sensible answer, e.g. inside the ARctic circle in summer.

=back

=cut

sub halfday {
    my ($self, $date) = @_;
    shift;shift;
    my $_as= shift;
    # Convert the location to radians.
    my $phi	= recalculate_coordinate($self->{lat},"rad");

    my ($day, $month)	= ($date->day, $date->month);

    my $decl	= declination($date);
    #Protect against stupidity
    return 0 if abs($phi)+ abs($decl) > pi/2.0;

    # Find the longitude difference between the base point and the sun
    my $dlong	= rad2deg(acos(-tan($phi)*tan($decl)));
    # Each degree of longitude represents 4 minutes of time
    my $minutes_offset= $dlong*4.0;
    return $minutes_offset;
}


=head3 sunset($date)

Calculates the time of sunset, i.e. when the mid-line of the
sun is 90degs from the zenith.	The result returned has to be
corrected for your distance from the standard meridian.

=over 

=item $date

A DateTime object. Only the day and month are relevant.

=item Returns

A DateTime object.

=back

=cut

sub  sunset {
    my ($self, $date) = @_;
    my $res	= $self->localnoon($date) +
	    DateTime::Duration->new(minutes=>$self->halfday($date));
    $res->set_time_zone($self->{zone});
}

=head3 sunrise($date)

Calculates the time of sunrise, i.e. when the mid-line of the
sun is 90degs from the zenith.	The result returned has to be
corrected for your distance from the standard meridian.

=over 

=item $date

A DateTime object. Only the day and month are relevant.

=back


=cut

sub sunrise {
    my ($self, $date) = @_;
    my $res	= $self->localnoon($date) -
	    DateTime::Duration->new(minutes=>$self->halfday($date));
    $res->set_time_zone($self->{zone});
}

=head3 shkia($date, [$extra])

Kabbalat Shabbat is 15 minutes before shkia, though some people
use 18 minutes;
Motzei Shabbat is 72 minutes after shkia (R Tam)

Other values for 'extra' give the times of Motzei Shabbat.
 Pre 1977	7.5 degs
 Post 1977	8 degs or 8.5
 Fast end	6 degs

=over 

=item $date

A DateTime object specifying the Gregorian date that we are interested in.

=item $extra

The number of degrees below the tangent plane that the sun
should be at halachic sunrise/set. Default 1.

=back

=cut

sub shkia {
    my($self, $date)	= @_;
    shift;shift;
    my $extra=shift ||1;

    # $offset is a number of minutes
    my $res	= $self->localnoon($date)
        +DateTime::Duration->new(minutes=>$self->halachicHalfDay( $date, $extra));
    $res->set_time_zone($self->{zone});
}

=head3 netzHachama($date, [$extra])

Calculates the time of halachic sunrise. This is usually when the sun
is 1 degree below the tangent plane, though some people use other values.

=over 

=item $date

A DateTime object specifying the Gregorian date that we are interested in.

=item $extra

The number of degrees below the tangent plane that the sun
should be at halachic sunrise/set. Default 1.

=back

=cut

sub netzHachama {
    my ($self, $date) = @_;
    my $res	= $self->localnoon($date)
	- DateTime::Duration->new(minutes=>$self->halachicHalfDay( $date));
    $res->set_time_zone($self->{zone});
}


=head3 kabbalatShabbat($date, [$extra])

Calculates the time of kabbalat Shabbat. This is usually 15 minutes
before shkia, though some people use 18 minutes.

=over 

=item $date

A DateTime object specifying the Gregorian date that we are interested in.

=item $extra

The number of minutes before shkia that one should use for kabbalat
Shabbat. Default 15.

=back

=cut

sub kabbalatShabbat {
    my ($self, $date)	= @_;
    shift; shift;
    my $extra	= shift|| 15;
    my $res	= $self->shkia($date) 
    			- DateTime::Duration->new(minutes=>$extra);
    return $res;
}

=head3 motzeiShabbat($date, [$extra])

Motzei Shabbat according to R Tam is 72 mins after shkia.
More conventionally we use the time when the sun is
either  7degs or 8 degs or 8.5 degs below the horizon.
Some people even use 11 or 14 degrees, but this quickly becomes
ridiculous in even moderate latitudes.

For fast ends we use 6 degs (R Schneur Zalman).

=over 

=item $date

A DateTime object. Only the day and month are relevant.

=item $extra

The number of degrees below the tangent plane that the sun
should be at motzei Shabbat. Default 8.

=back

=cut

sub motzeiShabbat {
    my ($self, $date)	= @_;
    shift; shift;
    my $extra= shift||8.0;
    
    return $self->shkia($date, $extra) ;
}

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

1; # End of DateTime::Event::Sunrise
