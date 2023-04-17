#! perl

use Test2::V0;

use Astro::FITS::CFITSIO::FileName;

# this is from new.t. should stick it somewhere common

subtest 'is_compressed' => sub {

    ok(
        Astro::FITS::CFITSIO::FileName->new( 'file://foo.fits.gz[2; image() ][pixr1 expr(ffo)]' )
          ->is_compressed,
        'compressed',
    );

    ok(
        !Astro::FITS::CFITSIO::FileName->new( 'file://foo.fits[2; image() ][pixr1 expr(ffo)]' )
          ->is_compressed,
        'not compressed ',
    );

};

done_testing;
