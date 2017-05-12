#!/usr/bin/env perl

use strict;
use warnings;
use Test::More qw/no_plan/;;
use ok 'Catalyst::Helper::AuthDBIC';
use FindBin qw/$Bin/;
my $app_dir = "$Bin/lib/";
my $cwd = $ENV{PWD};
chdir("$app_dir");
my $app_name = Catalyst::Helper::AuthDBIC->app_name();
ok($app_name eq 'TestApp', 'got app name');

# Catalyst::Helper stuff is a pain to test :(
# ok(Catalyst::Helper::AuthDBIC->make_model(), "model made ok");
# ok(-e ("$app_dir/db/auth.db"), "db file made ok");

# clean up

unlink "$app_dir/db/auth.db";
rmdir "$app_dir/db";
