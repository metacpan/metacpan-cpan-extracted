#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Carp;
use JSON;
use Try::Tiny;
use Circle::Common qw(load_config build_url_template http_json_get http_json_post);

my $config = load_config();
ok($config, "load config ok");
ok($config->{user}, "user config ok");
carp $config->{user}->{sessionPath};
is( $config->{user}->{sessionPath}, ".ccl/circle.properties" );

my $http = $config->{http};
my $block = $config->{block};
my $protocol = $http->{protocol};
my $host = $http->{host};
my $blockPath = $block->{path}->{blockchainHashListPath};
my $url = "$protocol://${host}${blockPath}?baseHeight=0";
carp "url: $url";
my $data = http_json_get($url);
# carp encode_json($data);
ok($data, "$url get ok");

my $invalid_url = 'https://circle-node.net/v2/block/getBlockHashList?baseHeight=0';
my $result = http_json_get($invalid_url);
print encode_json($result) . "\n";
ok( $result->{status} != 200, "not success here" );
my $url1 = build_url_template(
    "block", "blockchainHashListPath",
    {
        baseHeight => 100
    }
);
carp "url1: $url1";
ok($url1, "build url ok");


done_testing();


