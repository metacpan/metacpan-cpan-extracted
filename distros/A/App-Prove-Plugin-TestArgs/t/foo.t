#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( explain note pass ) ], tests => 1;

note explain \@ARGV;

pass( __FILE__ );
