use Test::More;

BEGIN{ plan( tests => 25 ) };
BEGIN{ use_ok( 'Astro::STSDAS::Table::Column' ) };

use Astro::STSDAS::Table::Constants;

my $col;

eval {
  $col = Astro::STSDAS::Table::Column->new(
					   'col1',
					   'mm',
					   '%f',
					   1,
					   22,
					   TY_REAL,
					   4 );
};

ok( !$@, 'new' );

is( $col->name,   'col1',  'r: name' );
is( $col->units,  'mm',    'r: units' );
is( $col->format, '%f',    'r: format' );
is( $col->idx,    1,       'r: idx' );
is( $col->offset, 22,      'r: offset' );
is( $col->type,   TY_REAL, 'r: type' );
is( $col->nelem,  4,       'r: nelem' );
is( $col->ifmt,   'f',     'r: ifmt' );
is( $col->fmt,    'f4',    'r: fmt' );

# now, try writing some attributes

is( $col->name('col2'),  'col2', 'w: name' );
is( $col->units('in'),   'in',   'w: units' );
is( $col->format('%d'),  '%d',   'w: format' );


# we shouldn't be able to change these:
for my $attr ( qw(idx offset type nelem ifmt fmt ) )
{
  eval "\$col->$attr(3);";
  ok( $@ && $@ =~ /attempt to write/, "w: $attr" );
}

is( $col->is_string, 0, 'non-string: is_string' );
isnt( $col->is_indef( 33 ),  1, 'non-indef: is_indef' );
is( $col->is_indef( $TypeIndef{TY_REAL()} ),  1, 'indef: is_indef' );

# we cheat in testing copy as we know it's just a hash under there
ok( eq_hash( $col, $col->copy), "copy" );

# make a string
$col = Astro::STSDAS::Table::Column->new(
					 'col1',
					 'mm',
					 '%s',
					 1,
					 22,
					 TY_STRING,
					 4 );
is( $col->is_string, 1, 'string: is_string' );
