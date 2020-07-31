package main;

use 5.008;

use strict;
use warnings;

use Config;
use Astro::Coord::ECI::Utils qw{ date2epoch };
use Astro::Coord::ECI::VSOP87D qw{ __model };
use File::Basename qw{ basename };
use File::Glob qw{ bsd_glob };
use Test::More 0.88;	# Because of done_testing();

# I believe the expanded limit when using long doubles is because the
# Fortran program that generated the comparison data only used double.
# This only shows up when testing Mercury.
use constant TEST_LIMIT	=>
    ( defined $Config{uselongdouble} || defined $Config{usequadmath} )
    ? 11e-10 : 5e-10;

my @name = (
    'Longitude, radians',
    'Latitude, radians',
    'Radius, AU',
    'Longitudinal velocity, radians/day',
    'Latitudinal velocity, radians/day',
    'Radius velocity, AU/day',
);

note "Test limit is @{[ TEST_LIMIT ]}";

foreach my $fn ( bsd_glob( 't/data/vsop87*.*' ) ) {
    my $body = basename( $fn );
    my @parts = split qr< [.] >smx, $body, 2;
    $parts[0] = uc $parts[0];
    $parts[1] = ucfirst lc $parts[1];
    my $class = join '::', qw{ Astro Coord ECI }, @parts;

    require_ok $class
	or BAIL_OUT $@;

    open my $fh, '<', $fn
	or BAIL_OUT "Failed to open $fn: $!";

    my $year;
    while ( <$fh> ) {
	my ( $dt, @want ) = unpack 'A16(A14)6', $_;
	$dt =~ s/ \A [+\s] //smx;
	$dt =~ s/ \s /0/smxg;
	s/ \s+ //smxg for @want;
	$dt =~ m/ \A ( [+-]? [0-9]{4} ) ( [0-9]{2} ) ( [0-9]{2} ) .
	( [0-9]{2} ) ( [0-9]{2} ) ( [0-9]{2} ) \z /smx
	    or next;
	not $ENV{AUTHOR_TESTING}
	    and defined $year
	    and $1 eq $year
	    and next;
	$year = $1;
	my $time = date2epoch( $6, $5, $4, $3, $2 - 1, $1 - 1900 );
	my @got = map { sprintf '%.10f', $_ } __model(
	    $class, $time,
	    cutoff	=> 'none',
	);
	foreach my $inx ( 0 .. $#got ) {
	    cmp_ok abs( $got[$inx] - $want[$inx] ), '<', TEST_LIMIT,
	    "$body $dt [$inx] ($name[$inx])";
	}
    }

    close $fh;
}

done_testing;

1;

# ex: set textwidth=72 :
