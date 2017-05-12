use Test::More;

BEGIN{ plan( tests => 30 ) };
BEGIN{ use_ok( 'Astro::STSDAS::Table::Columns' ) };

use Astro::STSDAS::Table::Constants;

my $cols;

eval {
  $cols = Astro::STSDAS::Table::Columns->new;
};

ok( !$@ && defined $cols, 'new' );

is( $cols->ncols, 0, 'ncols' );

my $col1;
my $col2;

eval {
  $col1 = $cols->add( 'col1', 'mm', '%f', 1, 22, TY_REAL, 4 );
};
ok( !$@, 'add' );

is( $cols->ncols, 1, 'ncols' );
is( $cols->byname( 'col1' ), $col1, 'byname' );
is( $cols->byidx( 1 ), $col1, 'byidx' );
is( $col1->idx, 1, 'column index' );

# attempt to add duplicate index
eval {
  $col2 = $cols->add( 'col1', 'mm', '%f', 1, 22, TY_REAL, 4 );
};
ok( $@ && $@ =~ /duplicate .* index/, 'duplicate index' );

# attempt to add duplicate name
eval {
  $col2 = $cols->add( 'col1', 'mm', '%f', 2, 22, TY_REAL, 4 );
};
ok( $@ && $@ =~ /duplicate .* name/, 'duplicate index' );

# add a legal second column
eval {
  $col2 = $cols->add( 'col2', 'mm', '%f', 2, 22, TY_REAL, 4 );
};
ok( !$@, 'col2' );


is( $cols->ncols, 2, 'ncols' );
is( $cols->byname( 'col2' ), $col2, 'byname' );
is( $cols->byidx( 2 ), $col2, 'byidx' );
is( $col2->idx, 2, 'column index' );


$copy = $cols->copy;
is( $copy->ncols, 2, 'copy ncols' );
isnt( $copy->byname( 'col2' ), undef, 'copy byname' );
isnt( $copy->byidx( 2 ), undef, 'copy byidx' );


ok( $cols->del( $col1 ), 'del' );

is( $cols->ncols, 1, 'ncols' );
is( $cols->byname( 'col2' ), $col2, 'byname' );
is( $cols->byidx( 2 ), $col2, 'byidx' );
is( $col2->idx, 2, 'column index' );

ok( defined $cols->rename( 'col2', 'col3' ), 'rename' );
is( $cols->byname( 'col3' ), $col2, 'byname' );


ok( $cols->delbyname( $col2->name ), 'delbyname' );
ok( ! $cols->delbyname( $col2->name ), 'delbyname twice' );
is( $cols->ncols, 0, 'ncols' );
is( $cols->byname( 'col3' ), undef, 'byname' );
is( $cols->byidx( 2 ), undef, 'byidx' );

