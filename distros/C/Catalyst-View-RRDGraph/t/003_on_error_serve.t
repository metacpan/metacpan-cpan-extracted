use strict;
use warnings;

use Test::More;

plan tests => 6;

use lib 't/lib';

use Catalyst::Test qw/RRDGraphTest003/;

# --------------------------------------------------------------------------------
# test with RRDGraph configured with on_error_serve pointing to a file that has
# ERRORIMAGEPNG as it's content

my $content = get("/zero_byte_error");
chomp($content);
cmp_ok($content, 'eq', 'ERRORIMAGEPNG', "Served static file in zero byte result");


$content = get("/image_error");
chomp($content);
cmp_ok($content, 'eq', 'ERRORIMAGEPNG', "Served a defined static file on an error");

# --------------------------------------------------------------------------------
# test with RRDGraph configured with default on_error_serve behaviour 
# (throw exception)

$content = get("/zero_byte_error_normal");
chomp($content);
like($content, qr/RRDgraph is 0 bytes/, "Served static file in zero byte result");


$content = get("/image_error_normal");
chomp($content);
like($content, qr/Unknown option/, "Served a defined static file on an error");



$content = get("/zero_byte_error_function");
chomp($content);
like($content, qr/CUSTOM BODY: RRDgraph is 0 bytes/, "Served error via a sub");


$content = get("/image_error_function");
chomp($content);
like($content, qr/CUSTOM BODY: Unknown option/, "Served error via a sub");

