#!perl
use strict;
use warnings;
use CLI::Helpers qw(:all);

output({color=>'yellow',sticky=>1}, "This is duct tape.");
output({color=>'green'}, "Hello, World!");
debug_var({ c => 3, d => 4});
