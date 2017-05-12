#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;
use Carp;
use autodie;
use utf8;

use Test::More;

use Plack::Test;
use HTTP::Request::Common;
use JSON qw/from_json/;

use lib 't/lib';
use TestApp;

my $test = Plack::Test->create(TestApp->to_app);

my $is_client_ok = $test->request(GET '/client_status');

unless ($is_client_ok->decoded_content eq 'available') {
    # couldn't call "elastic", assume no local ES cluster
    plan 'skip_all', 'ElasticSearch client not instantiable: ' . $is_client_ok->decoded_content;
}

my $count_response = $test->request(GET '/count');

ok($count_response->is_success, '... and we can talk to the ES instance');

my $count = from_json($count_response->decoded_content);
ok(exists $count->{hits},
   q{... and the response looks like an ES response});

my $ref1 = $test->request(GET '/client_refname')->decoded_content;
my $ref2 = $test->request(GET '/client_refname')->decoded_content;
is($ref1, $ref2,
   qq{... and both calls to elastic() return the same object ($ref1)});

done_testing;
