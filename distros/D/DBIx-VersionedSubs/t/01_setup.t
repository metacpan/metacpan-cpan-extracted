package My::App::Test;
use lib 'eg/lib';
use base 'My::App';

package main;
use strict;
use Test::More tests => 4;
use DBI;

my $package = 'My::App::Test';
$package->setup;

# Check that the defaults are as documented:
is $package->code_version, 0, "code_version";
is_deeply $package->code_source, {},"code_source";
is $package->code_live, 'code_live',"code_live";
is $package->code_history, 'code_history',"code_history";
