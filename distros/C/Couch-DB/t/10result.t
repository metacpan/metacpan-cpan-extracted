#!/usr/bin/env perl
# Test the Couch::DB::Result object

use Test::More;
use HTTP::Status qw(HTTP_CREATED);
use JSON::PP;

use lib 'lib', 't';
use Couch::DB::Util qw(simplified);
use Test;

#$dump_answers = 1;
#$dump_values  = 1;
#$trace = 1;

my $couch = _framework;
ok defined $couch, 'Created the framework';

my $db = $couch->db('test');
$db->remove;  ### cleanup after crash of this script
ok defined $db, 'Create database "test"';

# Any action
my $c  = $db->create;
ok !!$c, '... create successful';
is $c->code, HTTP_CREATED, '... http created';
is $c->message, 'Created', '... http message';
ok defined $c->request, '... http request: '.ref($c->request);
ok defined $c->response, '... http response'.ref($c->response);
$trace && warn $c->response->to_string;

is_deeply $c->answer, { ok => JSON::PP::true }, '... expected answer';
is $c->values, $c->answer, '... no special values to convert';

# Clean-up
_result removed          => $db->remove;

done_testing;
