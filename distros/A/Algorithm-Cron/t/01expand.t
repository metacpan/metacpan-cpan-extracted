#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Algorithm::Cron;

local *expand = \&Algorithm::Cron::_expand_set;

is_deeply( expand( "*", "sec" ), undef, 'expand sec=*' );
is_deeply( expand( "0", "sec" ), [ 0 ], 'expand sec=0' );
is_deeply( expand( "*/10", "sec" ), [ 0, 10, 20, 30, 40, 50 ], 'expand sec=0/10' );
is_deeply( expand( "5-8", "sec" ), [ 5, 6, 7, 8 ], 'expand sec=5-8' );
is_deeply( expand( "3-17/4", "sec" ), [ 3, 7, 11, 15 ], 'expand sec=3-17/4' );

is_deeply( expand( "*/5", "mday" ), [ 1, 6, 11, 16, 21, 26, 31 ], 'expand mday=*/5' );

is_deeply( expand( "jan", "mon" ), [ 0 ], 'expand mon=jan' );
is_deeply( expand( "mar-sep", "mon" ), [ 2 .. 8 ], 'expand mon=mar-sep' );
is_deeply( expand( "5", "mon" ), [ 4 ], 'expand mon=5' );
is_deeply( expand( "*/3", "mon" ), [ 0, 3, 6, 9 ], 'expand mon=*/3' );

is_deeply( expand( "mon", "wday" ), [ 1 ], 'expand wday=mon' );
is_deeply( expand( "mon-fri", "wday" ), [ 1 .. 5 ], 'expand wday=mon-fri' );
is_deeply( expand( "4", "wday" ), [ 4 ], 'expand wday=4' );
is_deeply( expand( "5-7", "wday" ), [ 0, 5, 6 ], 'expand wday=5-7' );
is_deeply( expand( "thu-sun", "wday" ), [ 0, 4, 5, 6 ], 'expand wday=thu-sun' );

done_testing;
