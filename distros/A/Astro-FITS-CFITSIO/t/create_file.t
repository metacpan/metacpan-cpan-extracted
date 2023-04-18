#! perl

use strict;
use Test2::V0;

use Astro::FITS::CFITSIO qw( :shortnames :constants  );

subtest 'ffopen' => sub {

    # try to open non-existant file
    ffopen( my $fptr, 'tq123x.kjl', READWRITE, my $status = 0 );
    is( $status, 104, 'status' );

};

subtest 'create file' => sub {

    my $fptr;

    subtest 'ffinit' => sub {
        ffinit( $fptr, '!testprog.fit', my $status = 0 );
        is( $status, 0, 'status' );
    };

    subtest 'create_file' => sub {
        my $fptr = Astro::FITS::CFITSIO::create_file( '!testprog.fit', my $status = 0 );
        is( $status, 0, 'status' );
        $fptr->delete_file( $status );
        is( $status, 252 );    # file is incomplete, so CFITSIO is unhappy
    };

    subtest 'ffflnm' => sub {
        ffflnm( $fptr, my $filename, my $status = 0 );
        is( $status,   0,              'status' );
        is( $filename, 'testprog.fit', 'result' );
    };

    subtest '->file_name' => sub {
        $fptr->file_name( my $filename, my $status = 0 );
        is( $status,   0,              'status' );
        is( $filename, 'testprog.fit', 'result' );
    };

    subtest 'ffflmd' => sub {
        ffflmd( $fptr, my $filemode, my $status = 0 );
        is( $status,   0, 'status' );
        is( $filemode, 1, 'result' );
    };

    subtest '->file_mode' => sub {
        $fptr->file_mode( my $filemode, my $status = 0 );
        is( $status,   0, 'status' );
        is( $filemode, 1, 'result' );
    };

    subtest '->delete_file' => sub {
        $fptr->delete_file( my $status = 0 );
        is( $status, 252 );    # file is incomplete, so CFITSIO is unhappy
    };
};

# fits_get_keyname
subtest 'ffgknm' => sub {
    ffgknm( "TESTING  'This is a test'", my $name, undef, my $status = 0 );
    is( $name, 'TESTING', 'value' );
};


done_testing;
