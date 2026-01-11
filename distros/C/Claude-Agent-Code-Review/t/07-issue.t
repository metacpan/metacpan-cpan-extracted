#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Claude::Agent::Code::Review::Issue');

# Test all severity levels
subtest 'Severity levels' => sub {
    for my $sev (qw(critical high medium low info)) {
        my $issue = Claude::Agent::Code::Review::Issue->new(
            severity    => $sev,
            category    => 'bugs',
            file        => 'test.pm',
            line        => 1,
            description => "Test $sev issue",
        );
        is($issue->severity, $sev, "severity $sev accepted");
    }

    throws_ok {
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'invalid',
            category    => 'bugs',
            file        => 'test.pm',
            line        => 1,
            description => 'test',
        );
    } qr/failed type constraint/, 'rejects invalid severity';
};

# Test all category levels
subtest 'Category levels' => sub {
    for my $cat (qw(bugs security style performance maintainability)) {
        my $issue = Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => $cat,
            file        => 'test.pm',
            line        => 1,
            description => "Test $cat issue",
        );
        is($issue->category, $cat, "category $cat accepted");
    }

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

# Test severity check methods
subtest 'is_critical method' => sub {
    my $critical = Claude::Agent::Code::Review::Issue->new(
        severity    => 'critical',
        category    => 'security',
        file        => 'test.pm',
        line        => 1,
        description => 'Critical issue',
    );

    my $high = Claude::Agent::Code::Review::Issue->new(
        severity    => 'high',
        category    => 'bugs',
        file        => 'test.pm',
        line        => 1,
        description => 'High issue',
    );

    ok($critical->is_critical, 'critical issue returns true');
    ok(!$high->is_critical, 'high issue returns false');
};

subtest 'is_high method' => sub {
    my $high = Claude::Agent::Code::Review::Issue->new(
        severity    => 'high',
        category    => 'bugs',
        file        => 'test.pm',
        line        => 1,
        description => 'High issue',
    );

    my $medium = Claude::Agent::Code::Review::Issue->new(
        severity    => 'medium',
        category    => 'bugs',
        file        => 'test.pm',
        line        => 1,
        description => 'Medium issue',
    );

    ok($high->is_high, 'high issue returns true');
    ok(!$medium->is_high, 'medium issue returns false');
};

subtest 'is_security method' => sub {
    my $security = Claude::Agent::Code::Review::Issue->new(
        severity    => 'high',
        category    => 'security',
        file        => 'test.pm',
        line        => 1,
        description => 'Security issue',
    );

    my $bugs = Claude::Agent::Code::Review::Issue->new(
        severity    => 'high',
        category    => 'bugs',
        file        => 'test.pm',
        line        => 1,
        description => 'Bug issue',
    );

    ok($security->is_security, 'security category returns true');
    ok(!$bugs->is_security, 'bugs category returns false');
};

# Test location formatting
subtest 'location method' => sub {
    my $single = Claude::Agent::Code::Review::Issue->new(
        severity    => 'low',
        category    => 'style',
        file        => 'lib/Foo/Bar.pm',
        line        => 42,
        description => 'Single line issue',
    );

    is($single->location, 'lib/Foo/Bar.pm:42', 'single line location');

    my $multi = Claude::Agent::Code::Review::Issue->new(
        severity    => 'low',
        category    => 'style',
        file        => 'lib/Foo.pm',
        line        => 10,
        end_line    => 25,
        description => 'Multi line issue',
    );

    is($multi->location, 'lib/Foo.pm:10-25', 'multi line location');

    my $same_line = Claude::Agent::Code::Review::Issue->new(
        severity    => 'low',
        category    => 'style',
        file        => 'test.pm',
        line        => 5,
        end_line    => 5,  # Same as start
        description => 'Same line',
    );

    is($same_line->location, 'test.pm:5', 'same start/end line shows single');
};

# Test has_* methods
subtest 'has_* optional field methods' => sub {
    my $minimal = Claude::Agent::Code::Review::Issue->new(
        severity    => 'info',
        category    => 'style',
        file        => 'test.pm',
        line        => 1,
        description => 'Minimal issue',
    );

    ok(!$minimal->has_end_line, 'no end_line');
    ok(!$minimal->has_column, 'no column');
    ok(!$minimal->has_explanation, 'no explanation');
    ok(!$minimal->has_suggestion, 'no suggestion');
    ok(!$minimal->has_code_before, 'no code_before');
    ok(!$minimal->has_code_after, 'no code_after');

    my $full = Claude::Agent::Code::Review::Issue->new(
        severity    => 'high',
        category    => 'security',
        file        => 'app.pm',
        line        => 10,
        end_line    => 15,
        column      => 5,
        description => 'Full issue',
        explanation => 'Detailed explanation',
        suggestion  => 'Fix suggestion',
        code_before => 'bad code',
        code_after  => 'good code',
    );

    ok($full->has_end_line, 'has end_line');
    ok($full->has_column, 'has column');
    ok($full->has_explanation, 'has explanation');
    ok($full->has_suggestion, 'has suggestion');
    ok($full->has_code_before, 'has code_before');
    ok($full->has_code_after, 'has code_after');
};

# Test empty string vs undefined for optional fields
subtest 'Empty string vs undefined' => sub {
    my $with_empty = Claude::Agent::Code::Review::Issue->new(
        severity    => 'low',
        category    => 'style',
        file        => 'test.pm',
        line        => 1,
        description => 'Test',
        explanation => '',  # Empty string
        suggestion  => '',  # Empty string
    );

    # Empty strings should return false for has_* methods
    ok(!$with_empty->has_explanation, 'empty explanation returns false');
    ok(!$with_empty->has_suggestion, 'empty suggestion returns false');
};

# Test to_hash
subtest 'to_hash method' => sub {
    my $issue = Claude::Agent::Code::Review::Issue->new(
        severity    => 'high',
        category    => 'bugs',
        file        => 'lib/App.pm',
        line        => 100,
        end_line    => 105,
        column      => 8,
        description => 'Bug description',
        explanation => 'Why this is bad',
        suggestion  => 'How to fix it',
        code_before => 'bad();',
        code_after  => 'good();',
    );

    my $hash = $issue->to_hash;

    is($hash->{severity}, 'high', 'hash severity');
    is($hash->{category}, 'bugs', 'hash category');
    is($hash->{file}, 'lib/App.pm', 'hash file');
    is($hash->{line}, 100, 'hash line');
    is($hash->{end_line}, 105, 'hash end_line');
    is($hash->{column}, 8, 'hash column');
    is($hash->{description}, 'Bug description', 'hash description');
    is($hash->{explanation}, 'Why this is bad', 'hash explanation');
    is($hash->{suggestion}, 'How to fix it', 'hash suggestion');
    is($hash->{code_before}, 'bad();', 'hash code_before');
    is($hash->{code_after}, 'good();', 'hash code_after');
};

subtest 'to_hash omits undefined optionals' => sub {
    my $minimal = Claude::Agent::Code::Review::Issue->new(
        severity    => 'low',
        category    => 'style',
        file        => 'test.pm',
        line        => 1,
        description => 'Minimal',
    );

    my $hash = $minimal->to_hash;

    ok(!exists $hash->{end_line}, 'omits undefined end_line');
    ok(!exists $hash->{column}, 'omits undefined column');
    ok(!exists $hash->{explanation}, 'omits undefined explanation');
    ok(!exists $hash->{suggestion}, 'omits undefined suggestion');
    ok(!exists $hash->{code_before}, 'omits undefined code_before');
    ok(!exists $hash->{code_after}, 'omits undefined code_after');
};

# Test as_text
subtest 'as_text method' => sub {
    my $issue = Claude::Agent::Code::Review::Issue->new(
        severity    => 'critical',
        category    => 'security',
        file        => 'lib/Auth.pm',
        line        => 50,
        description => 'SQL injection vulnerability',
        explanation => 'User input is not sanitized',
        suggestion  => 'Use prepared statements',
        code_before => '$dbh->do("SELECT * WHERE id=$id")',
        code_after  => '$dbh->do("SELECT * WHERE id=?", undef, $id)',
    );

    my $text = $issue->as_text;

    like($text, qr/\[CRITICAL\]/, 'uppercase severity');
    like($text, qr/security/, 'category');
    like($text, qr/lib\/Auth\.pm:50/, 'location');
    like($text, qr/SQL injection/, 'description');
    like($text, qr/Explanation:.*sanitized/s, 'explanation');
    like($text, qr/Suggestion:.*prepared/s, 'suggestion');
    like($text, qr/Before:.*SELECT/s, 'code_before');
    like($text, qr/After:.*\?/s, 'code_after');
};

subtest 'as_text minimal issue' => sub {
    my $minimal = Claude::Agent::Code::Review::Issue->new(
        severity    => 'info',
        category    => 'style',
        file        => 'test.pm',
        line        => 1,
        description => 'Just a note',
    );

    my $text = $minimal->as_text;

    like($text, qr/\[INFO\]/, 'has severity');
    like($text, qr/Just a note/, 'has description');
    unlike($text, qr/Explanation:/, 'no explanation line');
    unlike($text, qr/Suggestion:/, 'no suggestion line');
    unlike($text, qr/Before:/, 'no before line');
    unlike($text, qr/After:/, 'no after line');
};

# Test required fields validation
subtest 'Required fields' => sub {
    throws_ok {
        Claude::Agent::Code::Review::Issue->new(
            category    => 'bugs',
            file        => 'test.pm',
            line        => 1,
            description => 'test',
        );
    } qr/severity/, 'requires severity';

    throws_ok {
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            file        => 'test.pm',
            line        => 1,
            description => 'test',
        );
    } qr/category/, 'requires category';

    throws_ok {
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'bugs',
            line        => 1,
            description => 'test',
        );
    } qr/file/, 'requires file';

    throws_ok {
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'bugs',
            file        => 'test.pm',
            description => 'test',
        );
    } qr/line/, 'requires line';

    throws_ok {
        Claude::Agent::Code::Review::Issue->new(
            severity => 'high',
            category => 'bugs',
            file     => 'test.pm',
            line     => 1,
        );
    } qr/description/, 'requires description';
};

# Test various file paths
subtest 'File path handling' => sub {
    my @paths = (
        'simple.pm',
        'lib/Module.pm',
        'lib/Deep/Nested/Module.pm',
        './relative/path.pm',
        '../parent/path.pm',
        '/absolute/path.pm',
        'path with spaces/file.pm',
    );

    for my $path (@paths) {
        my $issue = Claude::Agent::Code::Review::Issue->new(
            severity    => 'low',
            category    => 'style',
            file        => $path,
            line        => 1,
            description => 'test',
        );
        is($issue->file, $path, "accepts path: $path");
    }
};

# Test line number edge cases
subtest 'Line number edge cases' => sub {
    my $line1 = Claude::Agent::Code::Review::Issue->new(
        severity    => 'low',
        category    => 'style',
        file        => 'test.pm',
        line        => 1,
        description => 'First line',
    );
    is($line1->line, 1, 'line 1 accepted');

    my $large = Claude::Agent::Code::Review::Issue->new(
        severity    => 'low',
        category    => 'style',
        file        => 'test.pm',
        line        => 999999,
        description => 'Large line number',
    );
    is($large->line, 999999, 'large line number accepted');

    # Test with zero (edge case - may be invalid in practice)
    my $zero = Claude::Agent::Code::Review::Issue->new(
        severity    => 'low',
        category    => 'style',
        file        => 'test.pm',
        line        => 0,
        description => 'Zero line',
    );
    is($zero->line, 0, 'line 0 accepted (may indicate header/overall issue)');
};

done_testing();
