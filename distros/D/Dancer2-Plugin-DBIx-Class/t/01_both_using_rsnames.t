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

subtest 'Check ResultSetNames' => sub {
   plan tests => 6;

   $res = $test->request( GET '/test_humans' );
   is( decode_json( $res->content ),
      [qw(id name)], 'Plural on first DB returns resultset' );

   $res = $test->request( GET '/test_human' );
   is(
      decode_json( $res->content ),
      { id => 1, name => 'Ruth Holloway' },
      'Singular on first DB does a find()'
   );

   $res = $test->request( GET '/test_mugs' );
   is(
      decode_json( $res->content ),
      [qw(id color size_in_oz beverage)],
      'Plural on second DB returns resultset'
   );

   $res = $test->request( GET '/test_mug' );
   is(
      decode_json( $res->content ),
      { id => 1, color => 'purple', size_in_oz => 30, beverage => 1 },
      'Singular on second DB does a find()'
   );

   $res = $test->request( GET '/test_session');
   like(
      decode_json( $res->content ),
      { status => 500, exception => qr/Can't call method "get_columns"/ },
      'Singular on sesion dies (DSL keyword collision prevented)'
   );
   $res = $test->request( GET '/test_sessions');
   is(
      decode_json( $res->content ),
      [qw(id created_at session_key)],
      'Plural on sessions returns resultset'
   );

};
