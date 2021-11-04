use strict;
use warnings;
use lib 't/lib';
use Test2::V0;

use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;
use TestAppBothWith;

plan tests => 1;

my $test = Plack::Test->create( TestAppBothWith->to_app );
my $res;

subtest 'Check core keywords' => sub {
   plan tests => 7;

   $res = $test->request( GET '/test_rs' );
   is( decode_json( $res->content ), [qw(id name)],
      'rs (uses default schema)' );

   $res = $test->request( GET '/test_rset' );
   is( decode_json( $res->content ), [qw(id name)],
      'rset (uses default schema)' );

   $res = $test->request( GET '/test_resultset' );
   is( decode_json( $res->content ), [qw(id name)],
      'resultset (uses default schema)' );

   $res = $test->request( GET '/test_schema' );
   is( decode_json( $res->content ), [qw(id name)],
      'schema without parameters' );

   $res = $test->request( GET '/test_defschema' );
   is( decode_json( $res->content ), [qw(id name)],
      'schema specifying default' );

   $res = $test->request( GET '/test_otherschema' );
   is(
      decode_json( $res->content ),
      [qw(id name birthdate)],
      'schema specifying second'
   );

   $res = $test->request( GET '/test_alias' );
   is(
      decode_json( $res->content ),
      [qw(id name birthdate)],
      'schema specifying alias'
   );
};
