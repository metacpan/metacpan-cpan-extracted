#!perl
use strict;
use warnings;
use CLI::Helpers qw(:output);

output({color=>'green'}, "[normal] Hello, World!");
verbose({indent=>1,color=>'yellow'}, "[verbose=1] Shiny, happy people!");
verbose({level=>2,kv=>1,color=>'red'}, verbose => 2, a => 1, b => 2);
debug_var({ c => 3, d => 4, debug => 1});
