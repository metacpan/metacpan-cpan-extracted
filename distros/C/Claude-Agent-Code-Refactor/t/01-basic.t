#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Claude::Agent::Code::Refactor');
use_ok('Claude::Agent::Code::Refactor::Options');
use_ok('Claude::Agent::Code::Refactor::Result');

# Test exports
can_ok('Claude::Agent::Code::Refactor', qw(refactor refactor_issues refactor_until_clean));

# Test Options
subtest 'Options defaults' => sub {
    my $opts = Claude::Agent::Code::Refactor::Options->new();

    is($opts->max_iterations, 5, 'default max_iterations');
    is($opts->max_turns_per_fix, 20, 'default max_turns_per_fix');
    is($opts->stop_on_critical, 1, 'default stop_on_critical');
    is($opts->min_severity, 'low', 'default min_severity');
    is_deeply($opts->categories,
        ['bugs', 'security', 'style', 'performance', 'maintainability'],
        'default categories');
    is($opts->fix_one_at_a_time, 0, 'default fix_one_at_a_time');
    is($opts->dry_run, 0, 'default dry_run');
    is($opts->create_backup, 0, 'default create_backup');
    is($opts->perlcritic, 0, 'default perlcritic');
    is($opts->perlcritic_severity, 4, 'default perlcritic_severity');
    is($opts->filter_false_positives, 1, 'default filter_false_positives');
    is($opts->permission_mode, 'acceptEdits', 'default permission_mode');
};

subtest 'Options custom values' => sub {
    my $opts = Claude::Agent::Code::Refactor::Options->new(
        max_iterations     => 10,
        max_turns_per_fix  => 30,
        min_severity       => 'medium',
        categories         => ['bugs', 'security'],
        dry_run            => 1,
        perlcritic         => 1,
        perlcritic_severity => 2,
        model              => 'claude-sonnet-4-5',
    );

    is($opts->max_iterations, 10, 'custom max_iterations');
    is($opts->max_turns_per_fix, 30, 'custom max_turns_per_fix');
    is($opts->min_severity, 'medium', 'custom min_severity');
    is_deeply($opts->categories, ['bugs', 'security'], 'custom categories');
    is($opts->dry_run, 1, 'custom dry_run');
    is($opts->perlcritic, 1, 'custom perlcritic');
    is($opts->perlcritic_severity, 2, 'custom perlcritic_severity');
    is($opts->model, 'claude-sonnet-4-5', 'custom model');
};

subtest 'Options validation' => sub {
    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(min_severity => 'invalid');
    } qr/Invalid min_severity/, 'rejects invalid min_severity';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(categories => ['invalid']);
    } qr/Invalid category/, 'rejects invalid category';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(categories => []);
    } qr/cannot be empty/, 'rejects empty categories';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(max_iterations => 0);
    } qr/must be >= 1/, 'rejects zero max_iterations';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(max_turns_per_fix => 0);
    } qr/must be >= 1/, 'rejects zero max_turns_per_fix';

    throws_ok {
        Claude::Agent::Code::Refactor::Options->new(perlcritic_severity => 6);
    } qr/Invalid perlcritic_severity/, 'rejects invalid perlcritic_severity';
};

# Test Result
subtest 'Result defaults' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new();

    is($result->success, 0, 'default success');
    is($result->iterations, 0, 'default iterations');
    is($result->initial_issues, 0, 'default initial_issues');
    is($result->final_issues, 0, 'default final_issues');
    is($result->fixes_applied, 0, 'default fixes_applied');
    is_deeply($result->files_modified, [], 'default files_modified');
    is_deeply($result->history, [], 'default history');
    is($result->duration_ms, 0, 'default duration_ms');
    ok(!$result->has_error, 'no error by default');
};

subtest 'Result is_clean' => sub {
    my $clean = Claude::Agent::Code::Refactor::Result->new(
        success      => 1,
        final_issues => 0,
    );
    ok($clean->is_clean, 'is_clean when success and no final issues');

    my $not_clean = Claude::Agent::Code::Refactor::Result->new(
        success      => 1,
        final_issues => 5,
    );
    ok(!$not_clean->is_clean, 'not clean when final issues remain');

    my $failed = Claude::Agent::Code::Refactor::Result->new(
        success      => 0,
        final_issues => 0,
    );
    ok(!$failed->is_clean, 'not clean when not success');
};

subtest 'Result issues_fixed and fix_rate' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 10,
        final_issues   => 3,
    );

    is($result->issues_fixed, 7, 'issues_fixed calculation');
    is($result->fix_rate, 70, 'fix_rate calculation');

    my $all_fixed = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 5,
        final_issues   => 0,
    );
    is($all_fixed->fix_rate, 100, 'fix_rate 100% when all fixed');

    my $no_issues = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 0,
        final_issues   => 0,
    );
    is($no_issues->fix_rate, 100, 'fix_rate 100% when no initial issues');
};

subtest 'Result add_iteration' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new();

    $result->add_iteration(
        issues_found   => 10,
        issues_fixed   => 5,
        files_modified => ['lib/Foo.pm'],
    );

    is($result->iterations, 1, 'iteration count');
    is($result->fixes_applied, 5, 'fixes_applied updated');
    is_deeply($result->files_modified, ['lib/Foo.pm'], 'files_modified');
    is(scalar @{$result->history}, 1, 'history has one entry');
    is($result->history->[0]{iteration}, 1, 'history iteration number');
    is($result->history->[0]{issues_found}, 10, 'history issues_found');
    is($result->history->[0]{issues_fixed}, 5, 'history issues_fixed');

    $result->add_iteration(
        issues_found   => 5,
        issues_fixed   => 3,
        files_modified => ['lib/Foo.pm', 'lib/Bar.pm'],
    );

    is($result->iterations, 2, 'iteration count after second');
    is($result->fixes_applied, 8, 'fixes_applied cumulative');
    is(scalar @{$result->files_modified}, 2, 'files_modified deduplicated');
    is(scalar @{$result->history}, 2, 'history has two entries');
};

subtest 'Result has_error' => sub {
    my $no_error = Claude::Agent::Code::Refactor::Result->new();
    ok(!$no_error->has_error, 'no error');

    my $with_error = Claude::Agent::Code::Refactor::Result->new(
        error => 'Something went wrong',
    );
    ok($with_error->has_error, 'has error');
};

subtest 'Result as_text' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new(
        success         => 1,
        iterations      => 2,
        initial_issues  => 10,
        final_issues    => 0,
        fixes_applied   => 10,
        files_modified  => ['lib/Foo.pm'],
        duration_ms     => 5000,
    );

    my $text = $result->as_text;
    like($text, qr/REFACTOR RESULT/, 'has header');
    like($text, qr/SUCCESS/, 'shows success');
    like($text, qr/Iterations: 2/, 'shows iterations');
    like($text, qr/Initial issues: 10/, 'shows initial issues');
    like($text, qr/Fix rate: 100%/, 'shows fix rate');
    like($text, qr/lib\/Foo\.pm/, 'shows modified files');
};

subtest 'Result to_hash' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new(
        success         => 1,
        iterations      => 3,
        initial_issues  => 15,
        final_issues    => 0,
        fixes_applied   => 15,
    );

    my $hash = $result->to_hash;
    is($hash->{success}, 1, 'hash success');
    is($hash->{iterations}, 3, 'hash iterations');
    is($hash->{initial_issues}, 15, 'hash initial_issues');
    is($hash->{final_issues}, 0, 'hash final_issues');
    is($hash->{fix_rate}, 100, 'hash fix_rate');
    ok(!exists $hash->{error}, 'hash omits error when not set');
};

done_testing();
