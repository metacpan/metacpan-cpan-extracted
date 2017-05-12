use Test::More tests => 20;
use strict; use warnings;

use Try::Tiny;

use_ok( 'Bot::Cobalt::Error' );

my $obj = new_ok( 'Bot::Cobalt::Error' => [
    "SOME_ERROR"
  ],
);

cmp_ok( $obj, 'eq', 'SOME_ERROR', 'Stringification seems to work' );

$obj = new_ok( 'Bot::Cobalt::Error' => [
    "There are some", "errors here"
  ],
);

cmp_ok( $obj, 'eq', 'There are someerrors here' );

isa_ok( $obj->join, 'Bot::Cobalt::Error' );
cmp_ok( $obj->join, 'eq', 'There are some errors here' );

isa_ok( $obj->trace, 'Devel::StackTrace' );

$obj = new_ok( 'Bot::Cobalt::Error' );

cmp_ok( $obj->push("Some error"), 'eq', 'Some error' );
cmp_ok( $obj, 'eq', 'Some error' );
cmp_ok( $obj->unshift("Some header"), 'eq', 'Some headerSome error' );
cmp_ok( $obj, 'eq', 'Some headerSome error' );
cmp_ok( $obj->join(', '), 'eq', 'Some header, Some error' );

try {
  $obj->throw;
} catch {
  isa_ok( $_, 'Bot::Cobalt::Error' );
  isa_ok( $_->trace, 'Devel::StackTrace' );
  is( $_->trace->frame(0)->package, 'main' );
};

$obj = new_ok( 'Bot::Cobalt::Error' => [
    "An error"
  ],
);

cmp_ok( $obj = 
  $obj->new( 
    "An error",
    "Second"
  )->unshift("Unshifted")->push("Third")->join(', '),
  'eq',
  "Unshifted, An error, Second, Third"
);

cmp_ok( $obj =
  $obj->new(
    "One",
    "Two"
  )->push("Three", "Four")->slice(0 .. 2),
  'eq',
  'OneTwoThree'
);
