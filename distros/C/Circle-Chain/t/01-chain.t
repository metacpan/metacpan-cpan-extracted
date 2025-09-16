#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use JSON;
use Carp;
use Circle::Chain qw(:block :node);

my $response = get_block_hashlist(0);
is( $response->{status}, 200 );
my $data = $response->{data};
ok( scalar(@$data) > 0 );


$response = subscribe();
print encode_json($response) . "\n";
is( $response->{status}, 200 );
carp(encode_json($response));

done_testing();


