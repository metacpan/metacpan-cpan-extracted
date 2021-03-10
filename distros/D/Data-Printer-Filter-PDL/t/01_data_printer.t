use strict;
use warnings;

use Test::More;

use PDL;

if ( eval { use Data::Printer {
		colored => 0,
		filters => [ 'PDL' ]
	}; 1 } ) {
  plan tests => 8;
} else {
  plan skip_all => 'Test requires Data::Printer';
}
use_ok('Data::Printer::Filter::PDL');

my $pdl = sequence(10,10);
my $ddp = p $pdl, return_value => 'dump';

like( $ddp, qr/PDL/,                 "contains the class name PDL" );
like( $ddp, qr/Type\s+: double/,     "displays type"               );
like( $ddp, qr/Shape\s+: \[10 10\]/, "displays shape"              );
like( $ddp, qr/Min\s+: 0/,           "displays minimum"            );
like( $ddp, qr/Max\s+: 99/,          "displays maximum"            );
like( $ddp, qr/Badflag\s+: No/,          "displays badflag status"     );

{
  local $PDL::toolongtoprint = $pdl->nelem - 1;
  my $long_ddp = p $pdl, return_value => 'dump';
  ok( length $ddp > length $long_ddp, 'does not print PDL after setting $PDL::toolongtoprint');
}
