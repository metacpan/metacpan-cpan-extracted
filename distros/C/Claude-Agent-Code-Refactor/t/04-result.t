#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Claude::Agent::Code::Refactor::Result');

subtest 'default values' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new();

    is($result->success, 0, 'default success is 0');
    is($result->iterations, 0, 'default iterations is 0');
    is($result->initial_issues, 0, 'default initial_issues is 0');
    is($result->final_issues, 0, 'default final_issues is 0');
    is($result->fixes_applied, 0, 'default fixes_applied is 0');
    is_deeply($result->files_modified, [], 'default files_modified is empty');
    is_deeply($result->history, [], 'default history is empty');
    is($result->duration_ms, 0, 'default duration_ms is 0');
    is($result->error, undef, 'default error is undef');
};

subtest 'is_clean' => sub {
    my $clean = Claude::Agent::Code::Refactor::Result->new(
        success      => 1,
        final_issues => 0,
    );
    ok($clean->is_clean, 'is_clean when success=1 and final_issues=0');

    my $not_clean1 = Claude::Agent::Code::Refactor::Result->new(
        success      => 0,
        final_issues => 0,
    );
    ok(!$not_clean1->is_clean, 'not clean when success=0');

    my $not_clean2 = Claude::Agent::Code::Refactor::Result->new(
        success      => 1,
        final_issues => 5,
    );
    ok(!$not_clean2->is_clean, 'not clean when final_issues > 0');
};

subtest 'has_error' => sub {
    my $no_error = Claude::Agent::Code::Refactor::Result->new();
    ok(!$no_error->has_error, 'no error when error is undef');

    my $empty_error = Claude::Agent::Code::Refactor::Result->new(error => '');
    ok(!$empty_error->has_error, 'no error when error is empty string');

    my $with_error = Claude::Agent::Code::Refactor::Result->new(
        error => 'Something went wrong'
    );
    ok($with_error->has_error, 'has_error when error is set');
};

subtest 'issues_fixed' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 10,
        final_issues   => 3,
    );
    is($result->issues_fixed, 7, 'issues_fixed = initial - final');

    my $all_fixed = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 5,
        final_issues   => 0,
    );
    is($all_fixed->issues_fixed, 5, 'all issues fixed');

    my $none_fixed = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 5,
        final_issues   => 5,
    );
    is($none_fixed->issues_fixed, 0, 'no issues fixed');

    my $negative = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 5,
        final_issues   => 10,
    );
    is($negative->issues_fixed, 0, 'returns 0 when final > initial');
};

subtest 'fix_rate' => sub {
    my $full = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 10,
        final_issues   => 0,
    );
    is($full->fix_rate, 100, '100% fix rate when all fixed');

    my $half = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 10,
        final_issues   => 5,
    );
    is($half->fix_rate, 50, '50% fix rate');

    my $none = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 10,
        final_issues   => 10,
    );
    is($none->fix_rate, 0, '0% fix rate when none fixed');

    my $no_issues = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 0,
        final_issues   => 0,
    );
    is($no_issues->fix_rate, 100, '100% when no initial issues');
};

subtest 'add_iteration' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new();

    $result->add_iteration(
        issues_found   => 10,
        issues_fixed   => 5,
        files_modified => ['lib/Foo.pm', 'lib/Bar.pm'],
    );

    is($result->iterations, 1, 'iterations incremented');
    is($result->fixes_applied, 5, 'fixes_applied updated');
    is_deeply($result->files_modified, ['lib/Foo.pm', 'lib/Bar.pm'], 'files tracked');
    is(scalar(@{$result->history}), 1, 'history has one entry');
    is($result->history->[0]{iteration}, 1, 'iteration number recorded');
    is($result->history->[0]{issues_found}, 10, 'issues_found recorded');
    is($result->history->[0]{issues_fixed}, 5, 'issues_fixed recorded');

    $result->add_iteration(
        issues_found   => 5,
        issues_fixed   => 3,
        files_modified => ['lib/Bar.pm', 'lib/Baz.pm'],
    );

    is($result->iterations, 2, 'iterations incremented again');
    is($result->fixes_applied, 8, 'fixes_applied accumulated');
    is_deeply(
        [sort @{$result->files_modified}],
        ['lib/Bar.pm', 'lib/Baz.pm', 'lib/Foo.pm'],
        'files deduplicated'
    );
    is(scalar(@{$result->history}), 2, 'history has two entries');
};

subtest 'as_text' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new(
        success        => 1,
        initial_issues => 10,
        final_issues   => 0,
        duration_ms    => 5000,
    );
    $result->add_iteration(
        issues_found   => 10,
        issues_fixed   => 10,
        files_modified => ['lib/Foo.pm'],
    );

    my $text = $result->as_text;

    like($text, qr/REFACTOR RESULT/, 'contains header');
    like($text, qr/SUCCESS/, 'contains success status');
    like($text, qr/Initial issues: 10/, 'contains initial issues');
    like($text, qr/Final issues: 0/, 'contains final issues');
    like($text, qr/Fix rate: 100%/, 'contains fix rate');
    like($text, qr/lib\/Foo\.pm/, 'contains modified file');
    like($text, qr/Iteration 1/, 'contains iteration info');
};

subtest 'as_text with error' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new(
        error => 'Something went wrong',
    );

    my $text = $result->as_text;

    like($text, qr/FAILED/, 'contains failed status');
    like($text, qr/Something went wrong/, 'contains error message');
};

subtest 'as_text incomplete' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new(
        success        => 0,
        initial_issues => 10,
        final_issues   => 3,
    );

    my $text = $result->as_text;

    like($text, qr/INCOMPLETE/, 'contains incomplete status');
};

subtest 'to_hash' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new(
        success        => 1,
        initial_issues => 10,
        final_issues   => 2,
        duration_ms    => 3000,
    );
    $result->add_iteration(
        issues_found   => 10,
        issues_fixed   => 8,
        files_modified => ['lib/Foo.pm'],
    );

    my $hash = $result->to_hash;

    is($hash->{success}, 1, 'success in hash');
    is($hash->{iterations}, 1, 'iterations in hash');
    is($hash->{initial_issues}, 10, 'initial_issues in hash');
    is($hash->{final_issues}, 2, 'final_issues in hash');
    is($hash->{fixes_applied}, 8, 'fixes_applied in hash');
    is($hash->{fix_rate}, 80, 'fix_rate in hash');
    is_deeply($hash->{files_modified}, ['lib/Foo.pm'], 'files_modified in hash');
    is($hash->{duration_ms}, 3000, 'duration_ms in hash');
    ok(!exists $hash->{error}, 'no error key when no error');
};

subtest 'to_hash with error' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new(
        error => 'Failed to fix',
    );

    my $hash = $result->to_hash;

    is($hash->{error}, 'Failed to fix', 'error included in hash');
};

done_testing();
