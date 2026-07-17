use strict;
use warnings;
use lib 't/lib';
use Test2::V0;

use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;
use TestAppDispatch;

my $test = Plack::Test->create( TestAppDispatch->to_app );
my $res;

subtest 'singular keyword (widget) is a primary-key lookup' => sub {
   plan tests => 4;

   $res = $test->request( GET '/widget/2' );
   is(
      decode_json( $res->content ),
      { id => 2, name => 'right widget', color => 'red' },
      'widget(2) returns the row with that primary key'
   );

   $res = $test->request( GET '/widget/999' );
   is( $res->content, '',
      'widget(missing id) returns nothing (undef, no matching row)' );

   $res = $test->request( GET '/widget_bad_hash' );
   like(
      decode_json( $res->content )->{error},
      qr/expects a single primary key value, not a hashref/,
      'widget(hashref) refuses to be treated as a search'
   );

   $res = $test->request( GET '/widget_no_args' );
   like(
      decode_json( $res->content )->{error},
      qr/requires a primary key value/,
      'widget() with no argument is a caller error, not "give me everything"'
   );
};

subtest 'plural keyword (widgets) is a search' => sub {
   plan tests => 3;

   $res = $test->request( GET '/widgets' );
   is(
      [ sort { $a->{id} <=> $b->{id} } @{ decode_json( $res->content ) } ],
      [
         { id => 1, name => 'left widget',  color => 'blue' },
         { id => 2, name => 'right widget', color => 'red' },
         { id => 3, name => 'top widget',   color => 'blue' },
      ],
      'widgets() with no arguments returns every row'
   );

   $res = $test->request( GET '/widgets/blue' );
   is(
      [ sort { $a->{id} <=> $b->{id} } @{ decode_json( $res->content ) } ],
      [
         { id => 1, name => 'left widget', color => 'blue' },
         { id => 3, name => 'top widget',  color => 'blue' },
      ],
      'widgets({color => blue}) searches via SQL::Abstract conditions'
   );

   $res = $test->request( GET '/widgets_bad' );
   like(
      decode_json( $res->content )->{error},
      qr/expects a hashref of search conditions/,
      'widgets(scalar) refuses a non-hashref argument'
   );
};

subtest
   'moose: singular and plural forms are identical, so it dispatches on argument shape'
   => sub {
   plan tests => 6;

   $res = $test->request( GET '/moose/1' );
   is(
      decode_json( $res->content ),
      { id => 1, name => 'Bullwinkle', herd => 'north' },
      'moose(1) with a scalar returns the single row by primary key'
   );

   $res = $test->request( GET '/moose_search/north' );
   is(
      [ sort { $a->{id} <=> $b->{id} } @{ decode_json( $res->content ) } ],
      [
         { id => 1, name => 'Bullwinkle', herd => 'north' },
         { id => 2, name => 'Boris',      herd => 'north' },
      ],
      'moose({herd => north}) with a hashref returns a search over all moose'
   );

   $res = $test->request( GET '/moose_search/south' );
   is(
      decode_json( $res->content ),
      [ { id => 3, name => 'Rocky', herd => 'south' } ],
      'moose({herd => south}) returns the other herd'
   );

   $res = $test->request( GET '/moose_no_args' );
   like(
      decode_json( $res->content )->{error},
      qr/requires a primary key value or a hashref of search conditions/,
      'moose() with no argument is ambiguous and refuses to guess'
   );

   $res = $test->request( GET '/moose_bad_ref' );
   like(
      decode_json( $res->content )->{error},
      qr/does not accept a reference of type 'CODE'/,
      'moose(coderef) is rejected outright'
   );

   $res = $test->request( GET '/moose_arrayref' );
   is(
      $res->content, '',
      'moose(arrayref) is treated like a scalar primary key (not rejected the way other refs are)'
   );
   };

subtest 'orm() keyword' => sub {
   plan tests => 3;

   $res = $test->request( GET '/orm_default_name' );
   is( decode_json( $res->content ), { name => 'default' },
      'orm() with no name defaults to "default"' );

   $res = $test->request( GET '/orm_named_name/default' );
   is(
      decode_json( $res->content ), { name => 'default' },
      'orm("default") returns the same connection explicitly'
   );

   $res = $test->request( GET '/orm_unknown' );
   like(
      decode_json( $res->content )->{error},
      qr/ORM 'nope' is not defined in the configuration/,
      'orm("nope") croaks for an unconfigured name'
   );
};

subtest
   q{a table keyword ('orm') that collides with the plugin's own orm() keyword}
   => sub {
   plan tests => 2;

   $res = $test->request( GET '/orm_default_name' );
   is(
      decode_json( $res->content ), { name => 'default' },
      'the bare orm() keyword still returns the connection, not the row_sub for the colliding table'
   );

   $res = $test->request( GET '/default_orm/1' );
   is(
      decode_json( $res->content ),
      { id => 1, note => 'not the orm() keyword' },
      q{the 'orm' table is still reachable via its schema-prefixed keyword}
   );
   };

subtest 'table names that collide with Dancer2 core DSL keywords' => sub {
   plan tests => 4;

   $res = $test->request( GET '/session_builtin_roundtrip' );
   is(
      decode_json( $res->content ),
      { greeting => 'hello' },
      q/the built-in 'session' keyword still works; QuickORM did not clobber it/
   );

   $res = $test->request( GET '/sessions_search/abc123' );
   is(
      decode_json( $res->content ),
      [ { id => 1, token => 'abc123' } ],
      q{'sessions' (plural of the colliding 'session' table) is still a valid search keyword}
   );

   $res = $test->request( GET '/response_header_roundtrip/hello-there' );
   is(
      $res->header('X-QuickORM-Test'), 'hello-there',
      q/the built-in 'response_header' keyword still works"/
   );

   $res = $test->request( GET '/default_header/1' );
   is(
      decode_json( $res->content ),
      { id => 1, label => 'X-Test' },
      q{the 'headers' table is unreachable by bare keyword (both forms collide with DSL), }
         . 'but still reachable via the schema-prefixed keyword'
   );
};

done_testing;
