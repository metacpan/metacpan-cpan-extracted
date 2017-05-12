#!perl

use strict;
use warnings;
use Test::More;

use_ok('App::BashComplete') || die "Could not load App::BashComplete, ";

my $app = App::BashComplete->new;
ok($app, 'Have a nice app');
can_ok($app, qw( run ));

is($app->_parse_options('--help', 'setup'), 'setup', "Recognized setup cmd");
ok($app->opts->{help}, '... help option properly set');


## and we are done for today
done_testing();
