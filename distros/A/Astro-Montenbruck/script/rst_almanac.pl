#!/usr/bin/env perl
use 5.22.0;
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib ("$Bin/../lib");

use POSIX qw/strftime/;
use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;
use Astro::Montenbruck::Ephemeris::Planet qw/:ids @PLANETS/;
use Astro::Montenbruck::Time qw/jdnow jd2cal cal2jd jd2unix/;
use Astro::Montenbruck::RiseSet::Constants qw/:events :states/;
use Astro::Montenbruck::RiseSet qw/rst/;
use Astro::Montenbruck::Utils::Helpers qw/parse_geocoords format_geo @DEFAULT_PLACE/;

our $VERSION = 0.01;
binmode(STDOUT, ":encoding(UTF-8)");

my $man    = 0;
my $help   = 0;
my $start  = strftime('%Y-%m-%d', localtime());
my $days   = 30;
my @place;

# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'     => \$help,
    'man'        => \$man,
    'start:s'    => \$start,
    'days:i'     => \$days,
    'place:s{2}' => \@place,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

@place = @DEFAULT_PLACE unless @place;
my ($lat, $lon);

# first, check if geo-coordinates are given in decimal format
if  (grep(/^[\+\-]?(\d+(\.?\d+)?|(\.\d+))$/, @place) == 2) {
    ($lat, $lon) = @place;
} else {
    ($lat, $lon) = parse_geocoords(@place);
}
say format_geo($lat, $lon);

my $jd_start = cal2jd($start =~ /(\d+)-(\d+)-(\d+)/);
my $jd_end = $jd_start + $days;

for (my $jd = $jd_start; $jd < $jd_end; $jd++) { 
    my @date = jd2cal($jd);
    say strftime('%Y-%m-%d', localtime(jd2unix($jd)));
    
    my $rst_func = rst(
        date     => \@date,
        phi      => $lat,
        lambda   => $lon
    );

    for my $pla (@PLANETS) {
        my %report;
        $rst_func->(
            $pla,
            on_event   => sub {
                my ($evt, $jd_evt) = @_;
                $report{$evt} = strftime("%H:%M", localtime(jd2unix($jd_evt)));
            },
            on_noevent => sub {
                my ($evt, $state) = @_;
                $report{$evt} = $state;
            }
        );            
        say sprintf(
            '%-12s rise: %s, transit: %s, set: %s',
            $pla, 
            map {$report{$_}} @RS_EVENTS)
    } 
    say('');     
}


__END__

=pod

=encoding UTF-8

=head1 NAME

rst_almanac — calculate rise, set and transit times of Sun, Moon and the planets.


=head1 SYNOPSIS

  rst_almanac [options]

=head1 OPTIONS

=over 4

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--start>

Start date, in B<YYYY-DD-MM> format, current date by default.

=item B<--days>

Number of days to process, B<30> by default

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


=head1 DESCRIPTION

Calculate rise, set and transit times of Sun, Moon and the planets for given range of days


=head2 EXAMPLES

    perl ./script/rst_almanac.pl --place=56N26 37E09 --days=7
    perl ./script/rst_almanac.pl --place=56N26 37E09 --start=2021-01-01 --days=365
    

=cut
