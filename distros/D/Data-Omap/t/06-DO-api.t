use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Omap') };

my( $omap, $invalid_omap );

for $invalid_omap (
    "scalar",          # not aref
    {hash=>1},         # not aref
    ['scalar'],        # not href (inside array)
    [{a=>1},'scalar'], # not href
    [{a=>1},[]],       # not href
    [{a=>1,b=>2}],     # multi-key hash
    [{a=>1},{a=>2}],   # duplicate keys
    ) {

    eval { $omap = Data::Omap->new( $invalid_omap ); };
    my $msg = $@;
    chomp $msg;
    like( $msg, qr/Invalid omap:/,
        "expected croak, [$msg]: " . Dumper( $invalid_omap ) );
}

$omap = Data::Omap->new( [{a=>1}] );
is( $omap->get_values('a'), 1,
    "new() with valid omap" );

