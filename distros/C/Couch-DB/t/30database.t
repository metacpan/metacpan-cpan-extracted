#!/usr/bin/env perl

use Test::More;
use HTTP::Status    qw(HTTP_OK);

use lib 'lib', 't';
use Couch::DB::Util qw(simplified);
use Test;

#$dump_answers = 1;
#$dump_values  = 1;
#$trace = 1;

my $couch = _framework;
ok defined $couch, 'Created the framework';

##### $couch->db('test');

my $db = $couch->db('test');
ok defined $db, 'Create database "test"';
isa_ok $db, 'Couch::DB::Database', '...';
is $db->name, 'test', '... name';
is $db->couch, $couch, '... link back to couch';

my $r = _result ping => $db->ping;
ok ! defined $r->answer, '... no answer';
ok ! defined $r->values, '... no values';
is  $r->code, 404, '... http not found';
ok ! $db->exists, '... exists, not yet';

_result create           => $db->create;
_result details          => $db->details;
_result compact          => $db->compact;
_result userRoles        => $db->userRoles;
_result ensureFullCommit => $db->ensureFullCommit;

_result removed          => $db->remove;

done_testing;
