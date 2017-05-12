use strict;
use Test::More tests => 14;
use Test::Exception;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
}


my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test;

lives_ok {
  $dbh->do(q!SELECT ok(true, 'true')!);
} 'ok must pass';
dies_ok {
  $dbh->do(q!SELECT ok(false, 'false')!);
} 'ok must fail';
lives_ok {
  $dbh->do(q!SELECT dies_ok($$SELECT 1/0$$, 'pass')!);
} 'dies_ok must pass';
dies_ok {
  $dbh->do(q!SELECT dies_ok($$SELECT 1$$, 'fail')!);
} 'dies_ok must fail';

lives_ok {
  $dbh->do(q!SELECT dies_ok($$ok(false, 'ok must fail')$$, 'fail')!);
} 'dies_ok + ok(false) must pass';

lives_ok {
  $dbh->do(q!SELECT is(1, 1, '1=1')!);
} 'is 1=1 must pass';
lives_ok {
  $dbh->do(q!SELECT is('a'::text, 'a'::text, '1=1')!);
} 'is a=a must pass';
dies_ok {
  $dbh->do(q!SELECT is(1, 2, '1=2')!);
} 'is 1=2 must fail';
dies_ok {
  $dbh->do(q!SELECT is('a'::text, 'b'::text, 'a=b')!);
} 'is a=b must fail';
dies_ok {
  $dbh->do(q!SELECT is(1, NULL, '1=NULL')!);
} 'is 1=null must fail';
dies_ok {
  $dbh->do(q!SELECT is('a'::text, NULL, 'a=NULL')!);
} 'is a=null must fail';
lives_ok {
  $dbh->do(q!SELECT is(NULL::int, NULL::int, 'NULL=NULL')!);
} 'is null=null (int context) must pass';
lives_ok {
  $dbh->do(q!SELECT is(NULL::text, NULL::text, 'NULL=NULL')!);
} 'is null=null (text context) must pass';
