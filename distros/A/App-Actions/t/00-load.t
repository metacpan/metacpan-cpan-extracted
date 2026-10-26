use strict;
use warnings;
use Test::Most;

use_ok('App::Actions');
use_ok('App::Actions::Action');
use_ok('App::Actions::Check');
use_ok('App::Actions::Docker');
use_ok('App::Actions::Expression');
use_ok('App::Actions::Logs');
use_ok('App::Actions::Process');
use_ok('App::Actions::Runner');
use_ok('App::Actions::Schema');
use_ok('App::Actions::Workflow');

is($App::Actions::VERSION, '0.002.1', 'version is set');

done_testing;
