use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;

use Test::Catalyst::Action::REST;

my $controller = Test::Catalyst::Action::REST->controller('Root');
ok $controller;

my $action = $controller->action_for('test');
ok $action;

isa_ok($action, 'Catalyst::Action::REST');
ok(!$action->isa('Catalyst'));
ok(!$action->isa('Catalyst::Controller'));

done_testing;
