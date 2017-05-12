#!perl

# strict
use strict;

# Astro::Catalog test harness
use Test::More tests => 29;

#load test
use File::Spec;
use Data::Dumper;

# load modules
BEGIN {
  use_ok("Astro::Catalog::Star");
  use_ok("Astro::Catalog::Query::Sesame");
}
use Astro::Coords;

# Load the generic test code
my $p = ( -d "t" ?  "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";


# T E S T -----------------------------------------------------------------

my $sesame = new Astro::Catalog::Query::Sesame( Target => 'EX Hya' );

SKIP: {
    my $catalog = eval {
        $sesame->querydb();
    };

    unless (defined $catalog) {
        diag('Cannot connect to Sesame: ' . $@);
        skip 'Cannot connect', 14;
    }

    isa_ok( $catalog, "Astro::Catalog" );

    unless ($catalog->sizeof() > 0) {
        diag('No items retrieved from Sesame');
        skip 'Not items retrieved', 13;
    }

    # reference star
    my $star = new Astro::Catalog::Star(id => 'EX Hya',
                                        coords => new Astro::Coords(
                                            ra =>'12 52 24.40', dec =>'-29 14 56',
                                            type=> 'j2000'));

    compare_star( $catalog->starbyindex(0), $star);
}

my $sesame2 = new Astro::Catalog::Query::Sesame( Target => 'V* HT Cas' );

SKIP: {
    my $catalog2 = eval {
        $sesame2->querydb();
    };

    unless (defined $catalog2) {
        diag('Cannot connect to Sesame: ' . $@);
        skip 'Cannot connect', 13;
    }

    unless ($catalog2->sizeof() > 0) {
        diag('No items retrieved from Sesame');
        skip 'Not items retrieved', 13;
    }

    my $star2 = new Astro::Catalog::Star( id => 'V* HT Cas',
                                          coords => new Astro::Coords( ra => '01 10 13.13',
                                                                       dec => '+60 04 35',
                                                                       type => 'J2000' ),
                                        );

    compare_star( $catalog2->starbyindex( 0 ), $star2 );
}
