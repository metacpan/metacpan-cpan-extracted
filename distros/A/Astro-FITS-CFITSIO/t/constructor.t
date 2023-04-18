#! perl

use strict;
use warnings;

use Test2::V0;

use Astro::FITS::CFITSIO ':constants';

use constant FILE => 'examples/m51.fits.gz';

subtest 'open_file' => sub {
    my $status = 0;
    ok(
        lives {
            Astro::FITS::CFITSIO::open_file( FILE, READONLY, $status )
        },
        'open existing file'
    ) or note $@;
    is( $status, 0, "status" );
};

subtest 'open_image' => sub {
    my $status = 0;
    ok(
        lives {
            Astro::FITS::CFITSIO::open_image( FILE, READONLY, $status )
        },
        'open existing file'
    ) or note $@;
    is( $status, 0, "status" );
};

subtest 'open_table' => sub {
    my $status = 0;
    ok(
        lives {
            Astro::FITS::CFITSIO::open_table( FILE, READONLY, $status )
        },
        'open existing file'
    ) or note $@;
    is( $status, 235, "status" );
};

subtest 'open_data' => sub {
    my $status = 0;
    ok(
        lives {
            Astro::FITS::CFITSIO::open_data( FILE, READONLY, $status )
        },
        'open existing file'
    ) or note $@;
    is( $status, 0, "status" );
};

subtest 'open_disfile' => sub {
    my $status = 0;
    ok(
        lives {
            Astro::FITS::CFITSIO::open_diskfile( FILE, READONLY, $status )
        },
        'open existing file'
    ) or note $@;
    is( $status, 0, "status" );
};

done_testing;
