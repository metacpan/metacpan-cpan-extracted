use Test::More;

BEGIN{ plan( tests => 22 ) };
BEGIN{ use_ok( 'Astro::STSDAS::Table::HeaderPars' ) };

my $pars;

eval {
  $pars = Astro::STSDAS::Table::HeaderPars->new;
};
ok( !$@ && defined $pars, 'new' );

is( $pars->npars, 0, 'npars' );

my $p1;
my $p2;

eval {
  $p1 = $pars->add( 'p1', 'p1v' );
};
ok( !$@, 'add' );

is( $pars->npars, 1, 'npars' );
is( $pars->byname( 'p1' ), $p1, 'byname' );
is( $p1->idx, 1, 'parameter index' );

# attempt to add duplicate parameter name
eval {
  $p2 = $pars->add( 'p1', 'p1v' );
};
ok( $@ && $@ =~ /duplicate.*name/, 'duplicate name' );

# add a legal second parameter
eval {
  $p2 = $pars->add( 'p2', 'p2v' );
};
ok( !$@, 'add');

is( $pars->npars, 2, 'npars' );
is( $pars->byname( 'p2' ), $p2, 'byname' );
is( $p2->idx, 2, 'parameter index' );

ok( eq_array( [ $p1, $p2 ], [ $pars->pars ] ), 'pars' );

ok( defined $pars->rename( 'p2', 'p3' ), 'rename' );
is( $pars->byname( 'p3' ), $p2, 'byname' );

ok( $pars->delbyname( 'p1' ), 'delbyname' );
ok( ! $pars->delbyname( 'p1' ), 'delbyname twice' );
is( $pars->npars, 1, 'npars' );
is( $pars->byname( 'p1' ), undef, 'byname' );

ok( $pars->delbyname( 'p3' ), 'delbyname' );
is( $pars->npars, 0, 'npars' );
is( $pars->byname( 'p3' ), undef, 'byname' );
