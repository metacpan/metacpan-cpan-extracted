use strict;
use warnings FATAL => 'all';

use Test::More;

sub main_in_test {

    require 'bin/stopwatch';

    pass('Loaded ok');

    is_deeply(
        parse_argv(),
        {
            error => 0,
            actions => [],
        },
        '',
    );

    is_deeply(
        parse_argv('--help'),
        {
            error => 0,
            actions => ['help'],
        },
        '--help',
    );

    is_deeply(
        parse_argv('-h'),
        {
            error => 0,
            actions => ['help'],
        },
        '-h',
    );

    is_deeply(
        parse_argv('--help', '-h'),
        {
            error => 1,
            error_actions => ['help_cant_be_used_with_other_options'],
        },
        '--help -h',
    );

    is_deeply(
        parse_argv('--help', '--help'),
        {
            error => 1,
            error_actions => ['help_cant_be_used_with_other_options'],
        },
        '--help --help',
    );

    is_deeply(
        parse_argv('--version'),
        {
            error => 1,
            error_actions => ['unknown_option'],
            error_options => [ '--version' ],
        },
        '--version',
    );

    is_deeply(
        parse_argv('--help', '--version'),
        {
            error => 1,
            error_actions => ['help_cant_be_used_with_other_options'],
        },
        '--help --version',
    );

    is_deeply(
        parse_argv('--version', '--help'),
        {
            error => 1,
            error_actions => ['help_cant_be_used_with_other_options'],
        },
        '--version --help',
    );

    is_deeply(
        parse_argv('asdf', '--help'),
        {
            error => 1,
            error_actions => ['help_cant_be_used_with_other_options'],
        },
        'asdf --help',
    );

    is_deeply(
        parse_argv('asdf', '--version'),
        {
            error => 1,
            error_actions => ['unknown_option'],
            error_options => [ 'asdf', '--version' ],
        },
        'asdf --version',
    );

    is_deeply(
        parse_argv('asdf'),
        {
            error => 1,
            error_actions => ['unknown_option'],
            error_options => [ 'asdf' ],
        },
        'asdf',
    );

    is_deeply(
        parse_argv('foo', 'bar'),
        {
            error => 1,
            error_actions => ['unknown_option'],
            error_options => [ 'foo', 'bar' ],
        },
        'foo bar',
    );


    is_deeply(
        parse_argv('--run', '20m', 'touch /tmp/20m'),
        {
            error => 0,
            actions => ['run'],
            run_options => [
                {
                    time => '20m',
                    cmd => 'touch /tmp/20m',
                },
            ],
        },
        '--run 20m "touch /tmp/20m"',
    );

    is_deeply(
        parse_argv('--run', '20m', 'touch /tmp/20m', '--run', '5s', 'touch /tmp/5s'),
        {
            error => 0,
            actions => ['run'],
            run_options => [
                {
                    time => '20m',
                    cmd => 'touch /tmp/20m',
                },
                {
                    time => '5s',
                    cmd => 'touch /tmp/5s',
                },
            ],
        },
        '--run 20m "touch /tmp/20m" --run 5s "touch /tmp/5s"',
    );

    is_deeply(
        parse_argv('--run', '20m'),
        {
            error => 1,
            error_actions => ['incorrect_run_usage'],
        },
        '--run 20m',
    );

    is_deeply(
        parse_argv('--run', '20m', 'touch /tmp/20m', 'asdf'),
        {
            error => 1,
            error_actions => ['unknown_option'],
            error_options => [ 'asdf' ],
        },
        '--run 20m "touch /tmp/aaa" asdf',
    );

    done_testing();

}
main_in_test();
