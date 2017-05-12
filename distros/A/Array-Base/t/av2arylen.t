use warnings;
use strict;

use Test::More tests => 4;

our @t = qw(a b c d e f);
our $r = \@t;

use Array::Base +3;

is_deeply [ scalar $#t ], [ 8 ];
is_deeply [ $#t ], [ 8 ];
is_deeply [ scalar $#$r ], [ 8 ];
is_deeply [ $#$r ], [ 8 ];

1;
