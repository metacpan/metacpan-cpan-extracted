#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Claude::Agent::Code::Review');
use_ok('Claude::Agent::Code::Review::Options');
use_ok('Claude::Agent::Code::Review::Report');
use_ok('Claude::Agent::Code::Review::Issue');
use_ok('Claude::Agent::Code::Review::Tools');

# Test exports
can_ok('Claude::Agent::Code::Review', qw(review review_files review_diff));

# Test Options
subtest 'Options' => sub {
    my $opts = Claude::Agent::Code::Review::Options->new();

    is_deeply($opts->categories,
        ['bugs', 'security', 'style', 'performance', 'maintainability'],
        'default categories');
    is($opts->severity, 'low', 'default severity');
    is($opts->max_issues, 0, 'default max_issues');
    is($opts->output_format, 'structured', 'default output_format');
    ok($opts->include_suggestions, 'default include_suggestions');
    is($opts->permission_mode, 'default', 'default permission_mode');

    my $custom = Claude::Agent::Code::Review::Options->new(
        categories => ['security', 'bugs'],
        severity   => 'high',
        max_issues => 10,
        permission_mode => 'bypassPermissions',
    );

    is_deeply($custom->categories, ['security', 'bugs'], 'custom categories');
    is($custom->severity, 'high', 'custom severity');
    is($custom->max_issues, 10, 'custom max_issues');
    ok($custom->has_max_issues, 'has_max_issues true when set');
    is($custom->permission_mode, 'bypassPermissions', 'custom permission_mode');

    # Test validation
    throws_ok {
        Claude::Agent::Code::Review::Options->new(severity => 'invalid');
    } qr/Invalid severity/, 'rejects invalid severity';

    throws_ok {
        Claude::Agent::Code::Review::Options->new(categories => ['invalid']);
    } qr/Invalid category/, 'rejects invalid category';

    throws_ok {
        Claude::Agent::Code::Review::Options->new(max_issues => -1);
    } qr/must be >= 0/, 'rejects negative max_issues';

    throws_ok {
        Claude::Agent::Code::Review::Options->new(output_format => 'invalid');
    } qr/Invalid output_format/, 'rejects invalid output_format';

    throws_ok {
        Claude::Agent::Code::Review::Options->new(categories => []);
    } qr/Categories cannot be empty/, 'rejects empty categories';
};

# Test Issue
subtest 'Issue' => sub {
    my $issue = Claude::Agent::Code::Review::Issue->new(
        severity    => 'high',
        category    => 'security',
        file        => 'lib/App.pm',
        line        => 42,
        description => 'SQL injection vulnerability',
        suggestion  => 'Use parameterized queries',
    );

    is($issue->severity, 'high', 'severity');
    is($issue->category, 'security', 'category');
    is($issue->file, 'lib/App.pm', 'file');
    is($issue->line, 42, 'line');
    is($issue->description, 'SQL injection vulnerability', 'description');
    ok($issue->has_suggestion, 'has_suggestion');
    ok(!$issue->has_end_line, 'no end_line');
    ok($issue->is_high, 'is_high');
    ok($issue->is_security, 'is_security');
    is($issue->location, 'lib/App.pm:42', 'location');

    my $multi = Claude::Agent::Code::Review::Issue->new(
        severity    => 'medium',
        category    => 'style',
        file        => 'lib/Foo.pm',
        line        => 10,
        end_line    => 15,
        description => 'Long function',
    );

    is($multi->location, 'lib/Foo.pm:10-15', 'multi-line location');

    # Test to_hash
    my $hash = $issue->to_hash;
    is($hash->{severity}, 'high', 'to_hash severity');
    is($hash->{file}, 'lib/App.pm', 'to_hash file');
    ok(exists $hash->{suggestion}, 'to_hash has suggestion');

    # Test as_text
    my $text = $issue->as_text;
    like($text, qr/HIGH/, 'as_text has severity');
    like($text, qr/security/, 'as_text has category');
    like($text, qr/SQL injection/, 'as_text has description');

    # Test enum validation
    throws_ok {
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'invalid',
            category    => 'security',
            file        => 'test.pm',
            line        => 1,
            description => 'test',
        );
    } qr/failed type constraint/, 'rejects invalid severity';

    throws_ok {
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'invalid',
            file        => 'test.pm',
            line        => 1,
            description => 'test',
        );
    } qr/failed type constraint/, 'rejects invalid category';
};

# Test Report
subtest 'Report' => sub {
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'critical',
            category    => 'security',
            file        => 'a.pm',
            line        => 1,
            description => 'Critical issue',
        ),
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'bugs',
            file        => 'b.pm',
            line        => 2,
            description => 'High issue',
        ),
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'low',
            category    => 'style',
            file        => 'a.pm',
            line        => 3,
            description => 'Low issue',
        ),
    );

    my $report = Claude::Agent::Code::Review::Report->new(
        summary => 'Found 3 issues',
        issues  => \@issues,
    );

    is($report->summary, 'Found 3 issues', 'summary');
    is($report->issue_count, 3, 'issue_count');
    ok($report->has_issues, 'has_issues');
    ok($report->has_critical_issues, 'has_critical_issues');
    ok($report->has_high_issues, 'has_high_issues');

    my $by_sev = $report->issues_by_severity;
    is(scalar @{$by_sev->{critical}}, 1, 'one critical');
    is(scalar @{$by_sev->{high}}, 1, 'one high');
    is(scalar @{$by_sev->{low}}, 1, 'one low');

    my $by_cat = $report->issues_by_category;
    is(scalar @{$by_cat->{security}}, 1, 'one security');
    is(scalar @{$by_cat->{bugs}}, 1, 'one bugs');
    is(scalar @{$by_cat->{style}}, 1, 'one style');

    my $by_file = $report->issues_by_file;
    is(scalar @{$by_file->{'a.pm'}}, 2, 'two in a.pm');
    is(scalar @{$by_file->{'b.pm'}}, 1, 'one in b.pm');

    # Test text output
    my $text = $report->as_text;
    like($text, qr/CODE REVIEW REPORT/, 'text has header');
    like($text, qr/CRITICAL/, 'text has critical section');
    like($text, qr/Found 3 issues/, 'text has summary');

    # Test JSON output
    my $json = $report->as_json;
    like($json, qr/"summary"/, 'json has summary');
    like($json, qr/"issues"/, 'json has issues');
    like($json, qr/"severity"/, 'json has severity in issues');

    # Test to_hash
    my $hash = $report->to_hash;
    is($hash->{summary}, 'Found 3 issues', 'to_hash summary');
    is(scalar @{$hash->{issues}}, 3, 'to_hash has 3 issues');
};

# Test empty report
subtest 'Empty Report' => sub {
    my $report = Claude::Agent::Code::Review::Report->new(
        summary => 'No issues found',
        issues  => [],
    );

    ok(!$report->has_issues, 'no issues');
    ok(!$report->has_critical_issues, 'no critical issues');
    ok(!$report->has_high_issues, 'no high issues');
    is($report->issue_count, 0, 'zero count');

    my $text = $report->as_text;
    like($text, qr/No issues found/, 'text shows no issues');
};

# Test report with default issues
subtest 'Report default issues' => sub {
    my $report = Claude::Agent::Code::Review::Report->new(
        summary => 'Test',
    );

    is_deeply($report->issues, [], 'default issues is empty array');
    ok(!$report->has_issues, 'has_issues false for default');
};

# Test Options helper methods
subtest 'Options helpers' => sub {
    my $opts = Claude::Agent::Code::Review::Options->new();
    ok(!$opts->has_focus_areas, 'no focus areas by default');
    ok(!$opts->has_max_issues, 'no max_issues by default (0 = unlimited)');
    ok(!$opts->has_ignore_patterns, 'no ignore patterns by default');

    my $with_focus = Claude::Agent::Code::Review::Options->new(
        focus_areas => ['error handling', 'security'],
    );
    ok($with_focus->has_focus_areas, 'has focus areas when set');

    my $with_patterns = Claude::Agent::Code::Review::Options->new(
        ignore_patterns => ['*.bak', 'tmp/*'],
    );
    ok($with_patterns->has_ignore_patterns, 'has ignore patterns when set');

    # Perlcritic options
    my $no_pc = Claude::Agent::Code::Review::Options->new();
    ok(!$no_pc->has_perlcritic, 'perlcritic disabled by default');
    is($no_pc->perlcritic_severity, 4, 'default perlcritic severity is 4 (stern)');

    my $with_pc = Claude::Agent::Code::Review::Options->new(
        perlcritic          => 1,
        perlcritic_severity => 3,
    );
    ok($with_pc->has_perlcritic, 'perlcritic enabled when set');
    is($with_pc->perlcritic_severity, 3, 'custom perlcritic severity');

    throws_ok {
        Claude::Agent::Code::Review::Options->new(perlcritic_severity => 6);
    } qr/Invalid perlcritic_severity/, 'rejects invalid perlcritic_severity';

    throws_ok {
        Claude::Agent::Code::Review::Options->new(perlcritic_severity => 0);
    } qr/Invalid perlcritic_severity/, 'rejects zero perlcritic_severity';
};

# Test Perlcritic module
subtest 'Perlcritic' => sub {
    use_ok('Claude::Agent::Code::Review::Perlcritic');

    # Test is_available (just check it doesn't crash)
    my $available = Claude::Agent::Code::Review::Perlcritic->is_available;
    ok(defined $available, 'is_available returns defined value');
};

done_testing();
