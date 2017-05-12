use Test::More tests => 5;

BEGIN {
      use_ok ("Astro::NED::Query::NearName");
}

my ( $req, $res );
my $object = 'Abell 2166';

eval {
      $req = Astro::NED::Query::NearName->new( ObjName => $object );
};
ok( ! $@, "new" );

ok( $req->ObjName eq $object, "ObjName" );

$req->Radius( 5 );
$req->ObjTypeInclude( 'ANY' );
$req->IncObjType( 'GClusters' => 1 );

eval {
     $res = $req->query;
};
ok( !$@, "query" ) 
    or diag( $@ );

#$_->dump foreach $res->objects;

ok( $res->nobjects > 0 && ($res->objects)[0]->Name eq 'ABELL 2166',
    "query result" );

