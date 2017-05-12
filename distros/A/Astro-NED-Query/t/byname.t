use Test::More tests => 5;

BEGIN {
      use_ok( "Astro::NED::Query::ByName" );
}


my ( $req, $res );

my $object = 'Abell 2166';

eval {
      $req = Astro::NED::Query::ByName->new( ObjName => $object );
};
ok( ! $@, "new" )
    or diag $@;

ok( $req->ObjName eq $object, "ObjName" );

eval {
     $res = $req->query;
};
ok( !$@, "query" )
     or diag( $@ );

ok(    1 == $res->nobjects 
    && ($res->objects)[0]->Name eq 'ABELL 2166',
    "query result" );

#$_->dump foreach $res->objects;
