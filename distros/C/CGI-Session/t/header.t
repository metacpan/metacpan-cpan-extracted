# $Id$

use strict;


use Test::More qw/no_plan/;

# Some driver independent tests for header();

use CGI::Session;

my $s = CGI::Session->new();
eval { $s->header() };
is($@, '','has header() method');

eval { $s->http_header() };
is($@, '','has http_header() method');

$s->delete();
