use Test::More tests => 7;

BEGIN {
      use_ok( "Astro::NED::Query::CoordExtinct" );
}

my ( $req, $res );
my ( $RA, $Dec, $PA ) = ( 12, 0, 35 );


eval {
      $req = Astro::NED::Query::CoordExtinct->new( 
                                                  RA => $RA,
                                                  Dec => $Dec,
                                                  PA => $PA );
};
ok( ! $@, "new" )
    or diag $@;

ok( $req->RA  eq $RA,  "get RA" );
ok( $req->Dec eq $Dec, "get Dec" );
ok( $req->PA  eq $PA,  "get PA" );

eval {
     $res = $req->query;
};

ok( !$@, "submit query" )
     or diag( $@ );

ok( eq_hash( { $res->data },
         {
          'J' => '0.021',
          'K' => '0.009',
          'Lon' => '-0.27839900',
          'B' => '0.102',
          'V' => '0.078',
          'H' => '0.014',
          'L\'' => '0.004',
          'PA' => '34.998447',
          'I' => '0.046',
          'R' => '0.063',
          'EB-V' => '1',
          'Lat' => '180.64065840',
          'Dec' => '-0.27839900',
          'U' => '0.129',
          'RA' => '180.64065840'
        } ), "check query" );


