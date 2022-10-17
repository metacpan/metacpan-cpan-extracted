use strict;
use warnings;

use Chemistry::File::OPTIMADE;
use Test::More tests => 4;

my @mols;

@mols = Chemistry::File::OPTIMADE->parse_string( <<'END' );
{
  "data": {
    "id": "test1",
    "attributes": {
      "cartesian_site_positions": [ [0.5,0.5,0.5] ],
      "species": [ { "name": "Fe", "chemical_symbols": ["Fe"] } ],
      "species_at_sites": [ "Fe" ]
    }
  },
  "meta": {
    "query": {
      "representation": "test?response_fields=cartesian_site_positions,species_at_sites,species"
    }
  }
}
END

is( scalar @mols, 1 );
is( $mols[0]->name, 'test1' );
is( scalar $mols[0]->atoms, 1 );
is( $mols[0]->by_id( 'a1' )->x3, 0.5 );
