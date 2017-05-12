% my $name = lc shift;
use strict;
use warnings;
use Test::More tests => 1;
use Test::Script;

script_compiles 'bin/<%= $name %>';
