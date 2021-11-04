use strict;
use warnings;
use lib 't/lib';
use Test2::V0;

use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;
use TestAppSecondWith;

plan tests => 1;

my $test = Plack::Test->create( TestAppSecondWith->to_app );
my $res;

subtest 'Check ResultSetNames' => sub {
   plan tests => 6;

   $res = $test->request( GET '/test_humans' );
   is(
      decode_json( $res->content ),
      [qw(id name birthdate)], 'Plural on humans returns second resultset'
   );

   $res = $test->request( GET '/test_human' );
   is(
      decode_json( $res->content ),
      {
         id        => 1, name => 'Wolfgang Amadaeus Mozart',
         birthdate => '1756-01-27'
      },
      'Singular on human does a find() on second db'
   );

   $res = $test->request( GET '/test_mugs' );
   like(
      decode_json( $res->content ),
      [qw(id color size_in_oz beverage)],
      'Plural on second DB returns resultset'
   );

   $res = $test->request( GET '/test_mug' );
   like(
      decode_json( $res->content ),
      { id => 1, color => 'purple', size_in_oz => 30, beverage => 1 },
      'Singular on second DB does a find()'
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
