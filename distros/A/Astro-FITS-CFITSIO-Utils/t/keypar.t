use Test::More;

BEGIN{ plan( tests => 14 ) };

BEGIN{ use_ok( 'Astro::FITS::CFITSIO::Utils', ':all' ) };

my $hdr;
my @hdr;

eval {
  $hdr = keypar( 'data/bintbl.fits', 'SIMPLE' );
};
ok( ! $@ && $hdr->type eq 'LOGICAL' && $hdr->value eq 1 
         && $hdr->hdu_num() == 1, "keypar: hdu 1" );

eval {
  $hdr = keypar( 'data/bintbl.fits', 'TFIELDS' );
};
ok( !$@ && $hdr && $hdr->value == 9
        && $hdr->hdu_num() == 2, "keypar: hdu 2, implicit" );

eval {
  $hdr = keypar( 'data/bintbl.fits[1]', 'TFIELDS' );
};
ok( !$@ && $hdr && $hdr->value == 9 
        && $hdr->hdu_num() == 2, "keypar: hdu 2, explicit" );

ok( !defined keypar( 'data/bintbl.fits', 'NOTEXIST' ),
    "keypar: non-existant keyword" );

eval {
     keypar( "non-existant file", 'SIMPLE' );
};
ok( $@ && $@ =~ /non-existant file/, "non-existant file" );


$hdr = keypar( 'data/bintbl.fits', 'COMMENT' );
ok( $hdr->comment == 1, 'multivalue; 1 HDU; scalar context' );

@hdr = keypar( 'data/bintbl.fits', 'COMMENT' );
ok( $hdr[0]->comment == 1 && $hdr[1]->comment == 2,
    'multivalue; 1 HDU; list context' );

@hdr = keypar( 'data/bintbl.fits', 'NAXIS' );
ok( $hdr[0]->value == 0 && $hdr[1]->value == 2,
    'multivalue; 2 HDU; list context' );

@hdr = keypar( 'data/bintbl.fits', 'NaXiS' );
ok( $hdr[0]->value == 0 && $hdr[1]->value == 2,
    'multivalue; 2 HDU; list context, case check' );

@hdr = keypar( 'data/bintbl.fits', [ 'NAXIS', 'COMMENT' ] );
ok( $hdr[0]->value == 0 && $hdr[1]->comment == 1,
    'multikeyw; single value; list context' );

@hdr = keypar( 'data/bintbl.fits', [ 'NAXIS', 'COMMENT' ],
      { OnePerHDU => 0 });
ok( 1 == @{$hdr[0]} && $hdr[0][0]->value == 0 &&
    2 == @{$hdr[1]} && $hdr[1][0]->comment == 1 && $hdr[1][1]->comment == 2,
    'multikeyw; multi per HDU; list context' );

@hdr = keypar( 'data/bintbl.fits', [ 'NAXIS', 'COMMENT' ],
      { OnePerHDU => 0, Accumulate => 1 });
ok( 2 == @{$hdr[0]} && $hdr[0][0]->value == 0 && $hdr[0][1]->value == 2 &&
    2 == @{$hdr[1]} && $hdr[1][0]->comment == 1 && $hdr[1][1]->comment == 2,
    'multikeyw; multi per HDU, accumulate ; list context' );

$hdr = keypar( 'data/bintbl.fits', 'VALUE', { Value => 1 } );
ok( 2 == $hdr, 'single value, scalar context, return value' );

