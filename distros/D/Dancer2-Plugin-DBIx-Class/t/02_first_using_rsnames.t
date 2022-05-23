use strict;
use warnings;
use lib 't/lib';
use Test2::V0;

use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;
use TestAppFirstWith;

plan tests => 1;

my $test = Plack::Test->create( TestAppFirstWith->to_app );
my $res;

subtest 'Check ResultSetNames' => sub {
   plan tests => 4;

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
   like(
      decode_json( $res->content ),
      { status => 500,  exception => qr/Can't locate object method/ },
      'Plural on second DB dies'
   );

   $res = $test->request( GET '/test_mug' );
   like(
      decode_json( $res->content ),
      { status => 500, exception => qr/Undefined subroutine/ },
      'Singular on second DB dies'
   );
};
