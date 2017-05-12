use Test::More;

BEGIN{ plan( tests => 12 ) };
BEGIN{ use_ok( 'Astro::STSDAS::Table::HeaderPar' ) };

use Astro::STSDAS::Table::Constants;

my $col;

eval {
  $hdrp = Astro::STSDAS::Table::HeaderPar->new(
					   1,
					   'Snack',
					   'm&ms',
					   'good for you',
					   TY_REAL
					    );
};

ok( !$@, 'new' );

is( $hdrp->idx,    1,       'r: idx' );
is( $hdrp->name,   'SNACK',  'r: name' );
is( $hdrp->value,  'm&ms',   'r: value' );
is( $hdrp->comment, 'good for you',    'r: comment' );
is( $hdrp->type,   TY_REAL, 'r: type' );

# now, try writing some attributes

is( $hdrp->name('col2'),  'COL2', 'w: name' );
is( $hdrp->comment('c2'),   'c2',   'w: comment' );
is( $hdrp->type(TY_INT),  TY_INT,   'w: format' );


# we shouldn't be able to change these:
for my $attr ( qw( idx ) )
{
  eval "\$hdrp->$attr(3);";
  ok( $@ && $@ =~ /attempt to write/, "w: $attr" );
}

# we cheat in testing copy as we know it's just a hash under there
ok( eq_hash( $hdrp, $hdrp->copy), "copy" );
