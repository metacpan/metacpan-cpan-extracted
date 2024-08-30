use 5.006;
use strict;
use warnings;
use Test::More;
use JSON;
use Carp;
use Circle::Block;

my $response = get_block_hashlist(0);
is( $response->{status}, 200 );
my $data = $response->{data};
ok( scalar(@$data) > 0 );

my $hash = $data->[0];
$response = get_block($hash);
is( $response->{status}, 200 );
$data = $response->{data};
carp 'block data:' . encode_json($data);
ok($data);

$response = get_block_data($hash);
is( $response->{status}, 200 );
$data = $response->{data};
carp 'block inner data:' . encode_json($data);
ok($data);

$response = get_block_header_list(0);
is( $response->{status}, 200 );
$data = $response->{data};
ok( scalar(@$data) > 0 );

$response = get_blocktails_hashlist(0);
is( $response->{status}, 200 );
$data = $response->{data};
ok( scalar(@$data) > 0 );

$hash = $data->[0];
$response = get_blocktails_po($hash);
is( $response->{status}, 200 );
$data = $response->{data};
carp 'block tails po:' . encode_json($data);
ok($data);

my $address = '1CqAt456oYZKur4Cf36teZgCsva3GBnSLQ';
$response = search_tx_by_address($address, '', 1);
is( $response->{status}, 200 );
$data = $response->{data};
ok($data);
carp 'tx list data: ' . encode_json($data);

my $txDetailList = $data->{txDetailList};
ok($txDetailList);
ok(@$txDetailList > 0);
my $txDetail = $txDetailList->[0];
my $txIdHexStr = $txDetail->{txIdHexStr};
ok($txIdHexStr);

$response = get_tx_by_txid($txIdHexStr);
is( $response->{status}, 200 );
$data = $response->{data};
carp 'tx info data:' . encode_json($data);
ok($data);

$response = search_tx_by_txid($txIdHexStr);
is( $response->{status}, 200 );
$data = $response->{data};
carp 'tx info data:' . encode_json($data);
ok($data);

$response = search_utxos($address, '', 1);
is( $response->{status}, 200 );
$data = $response->{data};
carp 'utxos data:' . encode_json($data);
ok($data);

done_testing();
