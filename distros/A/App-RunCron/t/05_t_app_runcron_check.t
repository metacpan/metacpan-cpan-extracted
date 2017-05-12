use strict;
use warnings;
use utf8;
use Test::Tester;
use Test::More;
use Test::App::RunCron;

check_test(
    sub {
        runcron_yml_ok 't/yml/file.yml';
    }, {
        ok => 1,
    }
);

check_test(
    sub {
        runcron_yml_ok 't/yml/file-ng.yml';
    }, {
        ok => 0,
    }
);

check_test(
    sub {
        runcron_yml_ok 't/yml/broken.yml';
    }, {
        ok => 0,
    }
);

done_testing;
