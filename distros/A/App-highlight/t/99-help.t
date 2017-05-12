use strict;
use warnings;

use Test::More tests => 8;
use App::Cmd::Tester;

use App::highlight;

## help
{
    my $result = test_app('App::highlight' => [ '--help' ]);

    like($result->stdout, qr/-c --color/ms,           'help message - color flag');
    like($result->stdout, qr/--no-color/ms,           'help message - no-color flag');
    like($result->stdout, qr/-e --escape/ms,          'help message - escape flag');
    like($result->stdout, qr/--no-escape/ms,          'help message - no-escape flag');
    like($result->stdout, qr/-l --full-line/ms,       'help message - full-line flag');
    like($result->stdout, qr/-o --one-color/ms,       'help message - one-color flag');
    like($result->stdout, qr/-b --show-bad-spaces/ms, 'help message - --show-bad-spaces flag');
    like($result->stdout, qr/-h --help/ms,            'help message - help flag');
}
