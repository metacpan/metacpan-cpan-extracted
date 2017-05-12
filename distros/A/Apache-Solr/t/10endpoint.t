#!/usr/bin/perl
# Test endpoint construction

use warnings;
use strict;

use lib 'lib';
use Apache::Solr;

use Test::More tests => 4;

# the server will not be called in this script.
my $server = 'http://localhost:8080/solr';
my $core   = 'my-core';

my $solr = Apache::Solr->new(server => $server, core => $core);
ok(defined $solr, 'instantiated client');
isa_ok($solr, 'Apache::Solr');

my $uri1 = $solr->endpoint('update', params => [tic => 1, tac => '&']);
isa_ok($uri1, 'URI');
is($uri1->as_string, "$server/$core/update?tic=1&tac=%26");

