use strict;
use warnings;

use Test2::V0;
use Test::Script;

script_compiles('script/diceware.pl');
script_runs(['script/diceware.pl', '--pretty']);

done_testing;
