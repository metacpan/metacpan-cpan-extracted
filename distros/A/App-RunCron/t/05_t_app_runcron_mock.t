use strict;
use warnings;
use utf8;
use Test::More;
use Test::App::RunCron;

subtest mock => sub {
    my $mock = mock_runcron;

    isa_ok $mock, 'App::RunCron';
    eval { $mock->run };
    ok $@;

    is $mock->report, 'mock report';
    ok $mock->is_success;
};

subtest mock_with_args => sub {
    my $mock = mock_runcron(
        report    => 'hoge',
        exit_code => 66666,
    );

    isa_ok $mock, 'App::RunCron';

    is $mock->report, 'hoge';
    ok !$mock->is_success;
};

done_testing;
