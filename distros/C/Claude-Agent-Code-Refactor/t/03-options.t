#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Claude::Agent::Code::Refactor::Options');

subtest 'default values' => sub {
    my $opts = Claude::Agent::Code::Refactor::Options->new();

    is($opts->max_iterations, 5, 'default max_iterations is 5');
    is($opts->max_turns_per_fix, 20, 'default max_turns_per_fix is 20');
    is($opts->min_severity, 'low', 'default min_severity is low');
    is($opts->permission_mode, 'acceptEdits', 'default permission_mode is acceptEdits');
    is($opts->dry_run, 0, 'default dry_run is 0');
    is($opts->perlcritic, 0, 'default perlcritic is 0');
    is($opts->perlcritic_severity, 4, 'default perlcritic_severity is 4');
    is($opts->filter_false_positives, 1, 'default filter_false_positives is 1');
    is($opts->model, undef, 'default model is undef');
    is_deeply(
        $opts->categories,
        ['bugs', 'security', 'style', 'performance', 'maintainability'],
        'default categories is all categories'
    );
};

subtest 'custom values' => sub {
    my $opts = Claude::Agent::Code::Refactor::Options->new(
        max_iterations         => 10,
        max_turns_per_fix      => 30,
        min_severity           => 'high',
        permission_mode        => 'bypassPermissions',
        dry_run                => 1,
        perlcritic             => 1,
        perlcritic_severity    => 2,
        filter_false_positives => 0,
        model                  => 'claude-sonnet-4',
        categories             => ['bugs', 'security'],
    );

    is($opts->max_iterations, 10, 'custom max_iterations');
    is($opts->max_turns_per_fix, 30, 'custom max_turns_per_fix');
    is($opts->min_severity, 'high', 'custom min_severity');
    is($opts->permission_mode, 'bypassPermissions', 'custom permission_mode');
    is($opts->dry_run, 1, 'custom dry_run');
    is($opts->perlcritic, 1, 'custom perlcritic');
    is($opts->perlcritic_severity, 2, 'custom perlcritic_severity');
    is($opts->filter_false_positives, 0, 'custom filter_false_positives');
    is($opts->model, 'claude-sonnet-4', 'custom model');
    is_deeply($opts->categories, ['bugs', 'security'], 'custom categories');
};

subtest 'min_severity validation' => sub {
    for my $valid (qw(critical high medium low info)) {
        lives_ok {
            Claude::Agent::Code::Refactor::Options->new(min_severity => $valid);
        } "accepts valid severity: $valid";
    }

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(min_severity => 'invalid');
    } qr/Invalid min_severity/, 'rejects invalid severity';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(min_severity => 'CRITICAL');
    } qr/Invalid min_severity/, 'severity is case-sensitive';
};

subtest 'categories validation' => sub {
    for my $valid (qw(bugs security style performance maintainability)) {
        lives_ok {
            Claude::Agent::Code::Refactor::Options->new(categories => [$valid]);
        } "accepts valid category: $valid";
    }

    lives_ok {
        Claude::Agent::Code::Refactor::Options->new(
            categories => ['bugs', 'security', 'style']
        );
    } 'accepts multiple valid categories';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(categories => ['invalid']);
    } qr/Invalid category/, 'rejects invalid category';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(categories => []);
    } qr/cannot be empty/, 'rejects empty categories';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(categories => 'bugs');
    } qr/must be an array/, 'rejects non-array categories';
};

subtest 'max_iterations validation' => sub {
    lives_ok {
        Claude::Agent::Code::Refactor::Options->new(max_iterations => 1);
    } 'accepts max_iterations = 1';

    lives_ok {
        Claude::Agent::Code::Refactor::Options->new(max_iterations => 100);
    } 'accepts max_iterations = 100';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(max_iterations => 0);
    } qr/must be >= 1/, 'rejects max_iterations < 1';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(max_iterations => 101);
    } qr/must be <= 100/, 'rejects max_iterations > 100';
};

subtest 'max_turns_per_fix validation' => sub {
    lives_ok {
        Claude::Agent::Code::Refactor::Options->new(max_turns_per_fix => 1);
    } 'accepts max_turns_per_fix = 1';

    lives_ok {
        Claude::Agent::Code::Refactor::Options->new(max_turns_per_fix => 100);
    } 'accepts max_turns_per_fix = 100';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(max_turns_per_fix => 0);
    } qr/must be >= 1/, 'rejects max_turns_per_fix < 1';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(max_turns_per_fix => 101);
    } qr/must be <= 100/, 'rejects max_turns_per_fix > 100';
};

subtest 'perlcritic_severity validation' => sub {
    for my $valid (1..5) {
        lives_ok {
            Claude::Agent::Code::Refactor::Options->new(perlcritic_severity => $valid);
        } "accepts perlcritic_severity = $valid";
    }

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(perlcritic_severity => 0);
    } qr/Must be 1-5/, 'rejects perlcritic_severity = 0';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(perlcritic_severity => 6);
    } qr/Must be 1-5/, 'rejects perlcritic_severity = 6';
};

done_testing();
