use strict;
use warnings;

use Test::More tests => 5;

use Data::Remember Hybrid => 
    []              => 'Memory', 
    [ 'load_test' ] => [ YAML => file => 't/load-test.yml' ]
    ;
 
is_deeply(recall [ load_test => 'something' ], 
    { foo => 1, bar => 2, baz => 3, qux => 4 });
is(recall [ load_test => something => 'foo' ], 1);
is(recall [ load_test => something => 'bar' ], 2);
is(recall [ load_test => something => 'baz' ], 3);
is(recall [ load_test => something => 'qux' ], 4);
