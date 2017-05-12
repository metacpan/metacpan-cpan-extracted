use strict;
use warnings;

use Test::More tests => 3;

use Data::Remember 'Memory';

remember [ x => 'y' ] => [ 1, 2, 3 ];
remember [ x => y => 'z' ] => [ 4, 5, 6 ];

is_deeply(recall [ x => y => 'z' ], [ 4, 5, 6 ]);
is(recall [ x => y => z => 'a'  ], undef);
is_deeply(recall [ x => y => 'z' ], [ 4, 5, 6 ]);
