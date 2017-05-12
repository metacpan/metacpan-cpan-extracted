#!perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::More;
use Catalyst::Test 'FetchApp';

my $content;

$content  = get('index');
is( $content, 'index', 'correct body' );

$content  = get('/open');
is( $content, 'open', 'correct body' );

# This will fail
$content  = get('/close');
is( $content, 'close', 'correct body' );

done_testing;
