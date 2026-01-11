#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Claude::Agent::Code::Review::Report');
use_ok('Claude::Agent::Code::Review::Issue');

# Test generate_summary
subtest 'generate_summary - no issues' => sub {
    my $summary = Claude::Agent::Code::Review::Report->generate_summary([]);
    is($summary, 'No issues found.', 'empty issues returns no issues message');
};

subtest 'generate_summary - single issue' => sub {
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'security',
            file        => 'a.pm',
            line        => 1,
            description => 'Test',
        ),
    );

    my $summary = Claude::Agent::Code::Review::Report->generate_summary(\@issues);
    is($summary, 'Found 1 issue: 1 high (1 security).', 'single issue summary');
};

subtest 'generate_summary - multiple issues same severity' => sub {
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => 'bugs',
            file        => 'a.pm',
            line        => 1,
            description => 'Bug 1',
        ),
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => 'bugs',
            file        => 'b.pm',
            line        => 2,
            description => 'Bug 2',
        ),
    );

    my $summary = Claude::Agent::Code::Review::Report->generate_summary(\@issues);
    is($summary, 'Found 2 issues: 2 medium (2 bugs).', 'multiple same severity');
};

subtest 'generate_summary - mixed severities and categories' => sub {
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'critical',
            category    => 'security',
            file        => 'a.pm',
            line        => 1,
            description => 'Critical security',
        ),
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'bugs',
            file        => 'b.pm',
            line        => 2,
            description => 'High bug',
        ),
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => 'performance',
            file        => 'c.pm',
            line        => 3,
            description => 'Medium performance',
        ),
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'low',
            category    => 'style',
            file        => 'd.pm',
            line        => 4,
            description => 'Low style',
        ),
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'info',
            category    => 'maintainability',
            file        => 'e.pm',
            line        => 5,
            description => 'Info maintainability',
        ),
    );

    my $summary = Claude::Agent::Code::Review::Report->generate_summary(\@issues);
    is($summary,
       'Found 5 issues: 1 critical, 1 high, 1 medium, 1 low, 1 info (1 security, 1 bugs, 1 performance, 1 maintainability, 1 style).',
       'mixed severities and categories');
};

subtest 'generate_summary - instance method' => sub {
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'bugs',
            file        => 'test.pm',
            line        => 1,
            description => 'Test issue',
        ),
    );

    my $report = Claude::Agent::Code::Review::Report->new(
        summary => 'Old summary',
        issues  => \@issues,
    );

    my $summary = $report->generate_summary;
    is($summary, 'Found 1 issue: 1 high (1 bugs).', 'instance method generates correct summary');
};

subtest 'generate_summary - severity ordering' => sub {
    # Ensure severities are listed from most to least severe
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'info',
            category    => 'style',
            file        => 'a.pm',
            line        => 1,
            description => 'Info',
        ),
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'critical',
            category    => 'security',
            file        => 'b.pm',
            line        => 2,
            description => 'Critical',
        ),
    );

    my $summary = Claude::Agent::Code::Review::Report->generate_summary(\@issues);
    like($summary, qr/1 critical.*1 info/, 'critical listed before info');
};

subtest 'generate_summary - category ordering' => sub {
    # Ensure categories are listed in defined order
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => 'style',
            file        => 'a.pm',
            line        => 1,
            description => 'Style',
        ),
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => 'security',
            file        => 'b.pm',
            line        => 2,
            description => 'Security',
        ),
    );

    my $summary = Claude::Agent::Code::Review::Report->generate_summary(\@issues);
    like($summary, qr/1 security.*1 style/, 'security listed before style');
};

# Test perlcritic tracking
subtest 'Perlcritic tracking' => sub {
    my @perlcritic_issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => 'style',
            file        => 'test.pm',
            line        => 1,
            description => 'Perl::Critic policy violation',
        ),
    );

    my $report = Claude::Agent::Code::Review::Report->new(
        summary           => 'Test',
        issues            => [],
        perlcritic_issues => \@perlcritic_issues,
        perlcritic_enabled => 1,
    );

    ok($report->perlcritic_enabled, 'perlcritic enabled');
    is(scalar @{$report->perlcritic_issues}, 1, 'has perlcritic issues');

    my $text = $report->as_text;
    like($text, qr/Perl::Critic:.*1 issue/, 'text output mentions perlcritic');
};

subtest 'Perlcritic no errors' => sub {
    my $report = Claude::Agent::Code::Review::Report->new(
        summary           => 'Test',
        issues            => [],
        perlcritic_issues => [],
        perlcritic_enabled => 1,
    );

    my $text = $report->as_text;
    like($text, qr/NO PERLCRITIC ERRORS/, 'shows no perlcritic errors message');
};

# Test filtered_count
subtest 'Filtered count tracking' => sub {
    my $report = Claude::Agent::Code::Review::Report->new(
        summary        => 'Test',
        issues         => [],
        filtered_count => 5,
    );

    is($report->filtered_count, 5, 'filtered count stored');

    my $text = $report->as_text;
    like($text, qr/Filtered: 5 likely false positive/, 'text shows filtered count');
};

# Test as_text with various configurations
subtest 'as_text full report' => sub {
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'security',
            file        => 'app.pm',
            line        => 10,
            description => 'SQL injection risk',
            explanation => 'User input interpolated into query',
            suggestion  => 'Use prepared statements',
            code_before => '$dbh->do("SELECT * FROM t WHERE id=$id")',
            code_after  => '$dbh->do("SELECT * FROM t WHERE id=?", undef, $id)',
        ),
    );

    my $report = Claude::Agent::Code::Review::Report->new(
        summary => 'Found 1 issue',
        issues  => \@issues,
    );

    my $text = $report->as_text;
    like($text, qr/CODE REVIEW REPORT/, 'has header');
    like($text, qr/HIGH/, 'has severity');
    like($text, qr/security/, 'has category');
    like($text, qr/app\.pm:10/, 'has file:line');
    like($text, qr/SQL injection risk/, 'has description');
    like($text, qr/Explanation:.*User input/, 'has explanation');
    like($text, qr/Suggestion:.*prepared statements/, 'has suggestion');
    like($text, qr/Before:/, 'has code before');
    like($text, qr/After:/, 'has code after');
    like($text, qr/AI review is non-deterministic/, 'has disclaimer');
};

subtest 'as_text with perlcritic disclaimer' => sub {
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'low',
            category    => 'style',
            file        => 'test.pm',
            line        => 1,
            description => 'Test',
        ),
    );

    my $report = Claude::Agent::Code::Review::Report->new(
        summary            => 'Test',
        issues             => \@issues,
        perlcritic_enabled => 1,
    );

    my $text = $report->as_text;
    like($text, qr/AI issues above may vary/, 'has combined disclaimer');
    like($text, qr/Perl::Critic issues are deterministic/, 'mentions perlcritic determinism');
};

# Test as_json
subtest 'as_json structure' => sub {
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'bugs',
            file        => 'test.pm',
            line        => 5,
            end_line    => 10,
            description => 'Test issue',
            explanation => 'Explanation here',
            suggestion  => 'Fix suggestion',
        ),
    );

    my $report = Claude::Agent::Code::Review::Report->new(
        summary => 'Test summary',
        issues  => \@issues,
        metrics => { files_reviewed => 3 },
    );

    my $json = $report->as_json;
    like($json, qr/"summary":"Test summary"/, 'JSON has summary');
    like($json, qr/"issues":\[/, 'JSON has issues array');
    like($json, qr/"severity":"high"/, 'JSON has severity');
    like($json, qr/"end_line":10/, 'JSON has end_line when present');
    like($json, qr/"explanation":"Explanation here"/, 'JSON has explanation');
    like($json, qr/"metrics":\{/, 'JSON has metrics');
    like($json, qr/"files_reviewed":3/, 'JSON has files_reviewed metric');
};

subtest 'as_json optional fields omitted' => sub {
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'low',
            category    => 'style',
            file        => 'test.pm',
            line        => 1,
            description => 'Minimal issue',
        ),
    );

    my $report = Claude::Agent::Code::Review::Report->new(
        summary => 'Test',
        issues  => \@issues,
    );

    my $json = $report->as_json;
    unlike($json, qr/"end_line"/, 'JSON omits end_line when not set');
    unlike($json, qr/"explanation"/, 'JSON omits explanation when not set');
    unlike($json, qr/"suggestion"/, 'JSON omits suggestion when not set');
    unlike($json, qr/"metrics"/, 'JSON omits metrics when not set');
};

# Test to_hash
subtest 'to_hash structure' => sub {
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => 'performance',
            file        => 'slow.pm',
            line        => 20,
            description => 'Inefficient algorithm',
        ),
    );

    my $report = Claude::Agent::Code::Review::Report->new(
        summary => 'Performance review',
        issues  => \@issues,
        metrics => { total_time => 5 },
    );

    my $hash = $report->to_hash;
    is($hash->{summary}, 'Performance review', 'hash has summary');
    is(ref($hash->{issues}), 'ARRAY', 'hash has issues array');
    is(scalar @{$hash->{issues}}, 1, 'hash has one issue');
    is($hash->{issues}[0]{severity}, 'medium', 'issue has severity');
    is($hash->{metrics}{total_time}, 5, 'hash has metrics');
};

done_testing();
