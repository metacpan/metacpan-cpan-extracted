#!perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More tests => 1;

use Catalyst::Test 'TestCGIBinChainRoot';
use HTTP::Request::Common;

# Test configurable path root and dir, and Chained root

my $response = request POST '/cgi/path/test.pl', [
    foo => 'bar',
    bar => 'baz',
];

is($response->content, 'foo:bar bar:baz from_chain:from_chain', 'POST to Perl CGI File');
