use Test::More tests => 4;

BEGIN {
      use_ok( "Astro::NED::Query::NearPosition" );
}

my ( $req, $res );

eval {
    $req = Astro::NED::Query::NearPosition->new( 
                                                RA => '16h28m37.0s',
                                                Dec => '+39d31m28s' );
};
ok( ! $@, "new" )
    or diag $@;

$req->Radius( 5 );
$req->ObjTypeInclude( 'ANY' );
$req->IncObjType( 'GClusters' => 1 );

eval {
     $res = $req->query;
};
ok( !$@, "query" )
    or diag $@;

#$_->dump foreach $res->objects;

ok( $res->nobjects > 0 && ($res->objects)[0]->Name eq 'ABELL 2199',
"query result" );

