use warnings;
use strict;
use Test::More;

my $app = eval <<"HERE" or die $@;
package main;
use Applify app => 'run', option => 'arg';
arg bool => foo => 'whatever', 42;
run { 0 };
HERE

is $app->foo, 42, 'can override default names' or diag $@;

done_testing;
