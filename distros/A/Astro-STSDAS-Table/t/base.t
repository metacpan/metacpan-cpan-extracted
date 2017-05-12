use Test::More;

BEGIN{ plan( tests => 3 ) };
BEGIN{ use_ok( 'Astro::STSDAS::Table::Base' ) };

my $tbl;

eval {
  $tbl = Astro::STSDAS::Table::Base->new();
};
ok( !$@, 'new' );
is( $tbl->{cols}->ncols, 0, 'ncols' );

