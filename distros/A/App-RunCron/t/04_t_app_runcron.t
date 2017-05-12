use strict;
use warnings;
use utf8;
use Test::More;

BEGIN { use_ok 'Test::App::RunCron' }

runcron_yml_ok 'eg/sample-runcron.yml';

done_testing;
