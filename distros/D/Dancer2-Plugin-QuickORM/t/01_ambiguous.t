use strict;
use warnings;
use lib 't/lib';
use Test2::V0;

use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;
use TestAppAmbiguous;

my $test = Plack::Test->create( TestAppAmbiguous->to_app );
my $res;

subtest 'bare keywords shared by two ORMs become ambiguous' => sub {
   plan tests => 3;

   $res = $test->request( GET '/widget_ambiguous' );
   like(
      decode_json( $res->content )->{error},
      qr/widget is ambiguous/,
      'widget(...) refuses to guess which ORM you meant'
   );

   $res = $test->request( GET '/widgets_ambiguous' );
   like(
      decode_json( $res->content )->{error},
      qr/widgets is ambiguous/,
      'widgets(...) refuses to guess which ORM you meant'
   );

   $res = $test->request( GET '/moose_ambiguous' );
   like(
      decode_json( $res->content )->{error},
      qr/moose is ambiguous/,
      'moose(...) (identical singular/plural) is also ambiguous across ORMs'
   );
};

subtest 'schema-prefixed keywords still work for each ORM independently' =>
   sub {
   plan tests => 5;

   $res = $test->request( GET '/default_widget/2' );
   is(
      decode_json( $res->content ),
      { id => 2, name => 'right widget', color => 'red' },
      'default_widget(2) works despite the bare keyword being ambiguous'
   );

   $res = $test->request( GET '/second_widget/2' );
   is(
      decode_json( $res->content ),
      { id => 2, name => 'right widget', color => 'red' },
      'second_widget(2) works independently of the default ORM'
   );

   $res = $test->request( GET '/default_widgets/blue' );
   is(
      [ sort { $a->{id} <=> $b->{id} } @{ decode_json( $res->content ) } ],
      [
         { id => 1, name => 'left widget', color => 'blue' },
         { id => 3, name => 'top widget',  color => 'blue' },
      ],
      'default_widgets({...}) still searches correctly'
   );

   $res = $test->request( GET '/default_moose/1' );
   is(
      decode_json( $res->content ),
      { id => 1, name => 'Bullwinkle', herd => 'north' },
      'default_moose(1) works for the identical-singular-plural table too'
   );

   $res = $test->request( GET '/second_moose/1' );
   is(
      decode_json( $res->content ),
      { id => 1, name => 'Bullwinkle', herd => 'north' },
      'second_moose(1) works independently'
   );
   };

done_testing;
