#!/usr/bin/env perl

use 5.22.0;
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib ("$Bin/../lib");

binmode( STDOUT, ":encoding(UTF-8)" );

our $VERSION = 0.01;

use Getopt::Long qw/GetOptions/;
use POSIX qw/strftime floor/;
use Carp qw/croak/;
use DateTime;
use Astro::Montenbruck::Ephemeris::Planet qw/$MO/;
use Astro::Montenbruck::Time qw/jd2cal cal2jd jd2unix/;
use Astro::Montenbruck::Ephemeris::Planet qw/$SU $MO/;
use Astro::Montenbruck::Ephemeris qw/find_positions/;

# use Astro::Montenbruck::Ephemeris qw/find_positions/;
use Astro::Montenbruck::RiseSet qw/rst/;
use Astro::Montenbruck::RiseSet::Constants qw/:events :states/;
use Astro::Montenbruck::Utils::Helpers
  qw/format_geo current_timezone local_now parse_geocoords @DEFAULT_PLACE/;
use Astro::Montenbruck::Lunation qw/:all/;

sub parse_date {
    my ( $date_str, $tz_name ) = @_;
    my ( $ye, $mo, $da ) = $date_str =~ /(\d+)-(\d+)-(\d+)/;
    DateTime->new(
        year      => $ye,
        month     => $mo,
        day       => $da,
        hour      => 12,
        minute    => 0,
        second    => 0,
        time_zone => $tz_name
    );
}

sub jd2str {
    my $jd  = shift;
    my $tz  = shift;
    my %arg = ( format => '%Y-%m-%d', @_ );

    DateTime->from_epoch(
        epoch     => jd2unix($jd),
        time_zone => $tz
    )->strftime( $arg{format} );
}

sub rise_set_transit {
    my ($ye, $mo, $da, $lat, $lon, $tz) = @_;
    # Convert Julian date to centuries since epoch 2000.0
    # my $t = ( $jd - 2451545 ) / 36525;

    # build top-level function for any event and any celestial object
    # for given time and place
    my $rst_func = rst(
        date   => [ $ye, $mo, $da ],
        phi    => $lat,
        lambda => $lon
    );
    my %report;
    $rst_func->(
        $MO,
        on_event => sub {
            my ( $evt, $jd_evt ) = @_;
            $report{$evt} = jd2str( $jd_evt, $tz, format => '%H:%M %Z' );
        },
        on_noevent => sub {
            my ( $evt, $state ) = @_;
            $report{$evt} = $state;
        }
    );    
    %report;
}

sub sun_moon_positions {
    my $jd = shift;
    my $t  = ($jd - 2451545) / 36525; # Convert Julian date to centuries since epoch 2000.0
    my %lam;
    find_positions($t, [$SU, $MO], sub {
        my ($id, $lambda) = @_;
        $lam{$id} = $lambda;
    });
    $lam{$MO}, $lam{$SU}
}


sub moon_for_date {
    my ($jd, $lat, $lon, $tz) = @_;
    my ($ye, $mo, $da) = cal2jd($jd);
    say sprintf( 'Date : %s', sprintf('%d-%02d-%02d', $ye, $mo, $da) );
    say '';


    # Convert Julian date to centuries since epoch 2000.0
    # my $t = ( $jd - 2451545 ) / 36525;

    # build top-level function for any event and any celestial object
    # for given time and place
    my $rst_func = rst(
        date   => [ $ye, $mo, $da ],
        phi    => $lat,
        lambda => $lon
    );
    my %report;
    $rst_func->(
        $MO,
        on_event => sub {
            my ( $evt, $jd_evt ) = @_;
            $report{$evt} = jd2str( $jd_evt, $tz, format => '%H:%M %Z' );
        },
        on_noevent => sub {
            my ( $evt, $state ) = @_;
            $report{$evt} = $state;
        }
    );
    say sprintf( "Moon Rise: %s\nMoon Transit: %s\nMoon Set: %s",
        map { $report{$_} } @RS_EVENTS );

    say '';

    my $t  = ($jd - 2451545) / 36525; # Convert Julian date to centuries since epoch 2000.0

    my %lam;
    find_positions($t, [$SU, $MO], sub {
        my ($id, $lambda) = @_;
        $lam{$id} = $lambda;
        say sprintf('%s longitude: %6.2f', $id, $lambda);
    });
    my ($phase, $deg, $days) = moon_phase(moon => $lam{$MO}, sun => $lam{$SU});
    say sprintf("Phase: %s\nAge: %5.2f deg. = %d days", $phase, $deg, $days);    
}


my $now = local_now();

my $help  = 0;
my $man   = 0;
my $start  = $now->strftime('%F');
my $days   = 1;
my $step   = 7;
my $tzone = current_timezone();
my @place;

# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'     => \$help,
    'man'        => \$man,
    'start:s'    => \$start,
    'days:i'     => \$days,
    'step:i'     => \$step,
    'timezone:s' => \$tzone,
    'place:s{2}' => \@place,
) or pod2usage(2);

my $tz = DateTime::TimeZone->new( name => $tzone );
my $dt = parse_date( $start, $tzone );
@place = @DEFAULT_PLACE unless @place;
my ( $lat, $lon );

# first, check if geo-coordinates are given in decimal format
if ( grep( /^[\+\-]?(\d+(\.?\d+)?|(\.\d+))$/, @place ) == 2 ) {
    ( $lat, $lon ) = @place;
}
else {
    ( $lat, $lon ) = parse_geocoords(@place);
}

say "Lunar Calendar";
say sprintf( 'Place: %s', format_geo( $lat, $lon ) );
say '';
my $jd_start = $dt->jd;
my $jd_end = $jd_start + $days * $step;

for (my $jd = $jd_start; $jd < $jd_end; $jd+=$step) {
    my @date = jd2cal($jd);
    say sprintf( 'Date : %s', sprintf('%d-%02d-%02d', @date) );
    say '';

    my %rst = rise_set_transit(@date, $lat, $lon, $tz);
    say sprintf( "Rise: %s\nTransit: %s\nSet: %s",
        map { $rst{$_} } @RS_EVENTS );
    say '';
    my ($mo, $su) = sun_moon_positions($jd);
    say sprintf('Sun longitude: %6.2f', $su);  
    say sprintf('Moon longitude: %6.2f', $mo);  
    say '';

    my ($phase, $deg, $days) = moon_phase(moon => $mo, sun => $su);
    say sprintf("Phase: %s\nAge: %5.2f deg. = %d days", $phase, $deg, $days);  
    say "\n---\n" 
}



__END__

=pod

=encoding UTF-8

=head1 NAME

moon_almanac — Computes rise, set of the Moon, its position and lunar phase circumstances for a range of dates

=head1 SYNOPSIS

  $ moon_almanac [OPTIONS]

=head1 OPTIONS

=over 4

=item B<--help>

Prints a brief help message and exits.

=item B<--start>

Start date, in B<YYYY-DD-MM> format, current date by default.

  --start=2019-06-08 # calendar date

=item B<--days>

Number of days to process, B<1> by default  

=item B<--step>

Step between successive cevents, in days, B<7> by default  

=item B<--timezone>

Time zone name, e.g.: C<EST>, C<UTC>, C<Europe/Berlin> etc. 
or I<offset from Greenwich> in format B<+HHMM> / B<-HHMM>, like C<+0300>.

    --timezone=CET # Central European Time
    --timezone=EST # Eastern Standard Time
    --timezone=UTC # Universal Coordinated Time
    --timezone=GMT # Greenwich Mean Time, same as the UTC
    --timezone=+0300 # UTC + 3h (eastward from Greenwich)
    --timezone="Europe/Moscow"

By default, a local timezone.

Please, note: Windows platform may not recognize some time zone names, like C<MSK>.
In such cases use I<offset from Greenwich> format, as described above.


=item B<--place>

The observer's location. Contains 2 elements, space separated. 

=over

=item * 

latitude in C<DD(N|S)MM> format, B<N> for North, B<S> for South.

=item * 

longitude in C<DDD(W|E)MM> format, B<W> for West, B<E> for East.

=back

E.g.: C<--place=51N28 0W0> for I<Greenwich, UK> (the default).

B<Decimal numbers> are also supported. In that case

=over

=item * 

The latitude always goes first

=item * 

Negative numbers represent I<South> latitude and I<East> longitudes. 

=back

C<--place=55.75 -37.58> for I<Moscow, Russian Federation>.
C<--place=40.73 73.935> for I<New-York, NY, USA>.


=back

=head1 DESCRIPTION

B<moon> Computes rise, set of the Moon, its position and lunar phase circumstances for a range of dates
 
krushi astro-montenbruck (master) $ perl script/moon_almanac.pl --start=2021-01-01 --days=2 --step=14
Lunar Calendar
Place: 51N28, 000W00

Date : 2021-01-01

Rise: 21:26 MSK
Transit: 05:36 MSK
Set: 13:02 MSK

Sun longitude: 281.16
Moon longitude: 127.64

Phase: Full Moon
Age: 206.48 deg. = 16 days

---

Date : 2021-01-15

Rise: 12:46 MSK
Transit: 17:16 MSK
Set: 21:57 MSK

Sun longitude: 295.43
Moon longitude: 322.70

Phase: New Moon
Age: 27.27 deg. = 2 days

---


=cut
