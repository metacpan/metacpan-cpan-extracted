use warnings;
use strict;
use Test::More;

plan skip_all => 'Skipped on 5.10.1' unless eval 'require 5.12.0;1';

my $app = eval <<"HERE" or die $@;
package main;
sub not_app_method { 1 }
use Applify;
sub bar { 1 }
sub AUTOLOAD { 'Autoloaded' }
app { 0 };
HERE

is eval { $app->i_am_autoloaded }, 'Autoloaded', 'AUTOLOAD works' or diag $@;

done_testing;
