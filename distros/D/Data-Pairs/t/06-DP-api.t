use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Pairs') };

my( $pairs, $invalid_pairs );

for $invalid_pairs (
    "scalar",          # not aref
    {hash=>1},         # not aref
    ['scalar'],        # not href (inside array)
    [{a=>1},'scalar'], # not href
    [{a=>1},[]],       # not href
    [{a=>1,b=>2}],     # multi-key hash
    ) {

    eval { $pairs = Data::Pairs->new( $invalid_pairs ); };
    my $msg = $@;
    chomp $msg;
    like( $msg, qr/Invalid pairs:/,
        "expected croak, [$msg]: " . Dumper( $invalid_pairs ) );
}

$pairs = Data::Pairs->new( [{a=>1},{a=>2}] );
is( $pairs->get_values('a'), 2,
    "new() with valid pairs" );

