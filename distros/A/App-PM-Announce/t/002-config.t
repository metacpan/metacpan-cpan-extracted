#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use App::PM::Announce;
use Directory::Scratch;

$ENV{APP_PM_ANNOUNCE_HOME} = 't/assets/home';

my $app = App::PM::Announce->new;

ok($app);
ok($app->config);
is($app->config->{xyzzy}, 1);

