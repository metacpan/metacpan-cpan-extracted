use Test::More tests => 4;

BEGIN {
      use_ok( "Astro::NED::Query::ByName" );
}

# check for backwards compatibility

my ( $req, $res );

my $object = 'Abell 2166';

eval {
      $req = Astro::NED::Query::ByName->new;
};
ok( ! $@, "new" )
    or diag $@;

eval {
     $req->reset;
};
ok( !$@, "reset" )
     or diag( $@ );

eval {
     $req->set_default;
};
ok( !$@, "set_default" )
     or diag( $@ );
