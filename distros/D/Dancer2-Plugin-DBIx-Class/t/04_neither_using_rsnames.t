use strict;
use warnings;
use lib 't/lib';
use Test2::V0;

use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;
use TestAppNeitherWith;

plan tests => 1;

my $test = Plack::Test->create( TestAppNeitherWith->to_app );
my $res;

subtest 'Check ResultSetNames' => sub {
   plan tests => 6;

   $res = $test->request( GET '/test_humans' );
   like(
      decode_json( $res->content ),
      { status => 500, exception => qr/Can't locate object method/ },
      'Plural on humans DB dies'
   );

   $res = $test->request( GET '/test_human' );
   like(
      decode_json( $res->content ),
      { status => 500, exception => qr/Undefined subroutine/ },
      'Singular on human dies'
   );

   $res = $test->request( GET '/test_mugs' );
   like(
      decode_json( $res->content ),
      { status => 500, exception => qr/Can't locate object method/ },
      'Plural on second DB dies'
   );

   $res = $test->request( GET '/test_mug' );
   like(
      decode_json( $res->content ),
      { status => 500, exception => qr/Undefined subroutine/ },
      'Singular on second DB dies'
   );

   $res = $test->request( GET '/test_cars' );
   like(
      decode_json( $res->content ),
      { status => 500, exception => qr/Can't locate object method/ },
      'Plural on first DB dies'
   );

   $res = $test->request( GET '/test_car' );
   like(
      decode_json( $res->content ),
      { status => 500, exception => qr/Undefined subroutine/ },
      'Singular on first DB dies'
   );

};
