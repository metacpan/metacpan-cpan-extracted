use strict;
use warnings;

use Chemistry::File::CML;
use Test::More tests => 9;

my @mols;

@mols = Chemistry::File::CML->parse_string( <<'END' );
<?xml version="1.0"?>
<cml xmlns="http://www.xml-cml.org/schema">
  <molecule id="name">
    <atomArray>
      <atom id="a1" elementType="C" x3="0.5" y3="0.5" z3="0.5"/>
    </atomArray>
  </molecule>
</cml>
END

is( scalar @mols, 1 );
is( $mols[0]->name, 'name' );
is( scalar $mols[0]->atoms, 1 );
is( $mols[0]->by_id( 'a1' )->x3, 0.5 );
is( $mols[0]->by_id( 'a1' )->attr('cml/has_coords'), 1 );

@mols = Chemistry::File::CML->parse_string( <<'END' );
<?xml version="1.0"?>
<cml xmlns="http://www.xml-cml.org/schema">
  <molecule id="container" convention="convention:molecular">
    <molecule id="name">
      <atomArray>
        <atom id="a1" elementType="C" x3="0.5" y3="0.5" z3="0.5"/>
      </atomArray>
    </molecule>
  </molecule>
</cml>
END

is( scalar @mols, 1 );
is( $mols[0]->name, 'name' );
is( scalar $mols[0]->atoms, 1 );
is( $mols[0]->by_id( 'a2' )->x3, 0.5 );
