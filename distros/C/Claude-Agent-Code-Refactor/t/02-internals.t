#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Claude::Agent::Code::Refactor');

# Test internal prompt building function
subtest '_build_fix_prompt' => sub {
    # Create mock issue objects
    package MockIssue;
    sub new {
        my ($class, %args) = @_;
        bless \%args, $class;
    }
    sub file { shift->{file} }
    sub line { shift->{line} }
    sub severity { shift->{severity} }
    sub category { shift->{category} }
    sub description { shift->{description} }
    sub explanation { shift->{explanation} }
    sub suggestion { shift->{suggestion} }
    sub code_before { shift->{code_before} }
    sub code_after { shift->{code_after} }
    sub has_explanation { my $s = shift; defined $s->{explanation} && length $s->{explanation} }
    sub has_suggestion { my $s = shift; defined $s->{suggestion} && length $s->{suggestion} }
    sub has_code_before { my $s = shift; defined $s->{code_before} && length $s->{code_before} }
    sub has_code_after { my $s = shift; defined $s->{code_after} && length $s->{code_after} }

    package main;

    my @issues = (
        MockIssue->new(
            file        => 'lib/Foo.pm',
            line        => 42,
            severity    => 'high',
            category    => 'security',
            description => 'SQL injection vulnerability',
            suggestion  => 'Use prepared statements',
        ),
        MockIssue->new(
            file        => 'lib/Bar.pm',
            line        => 10,
            severity    => 'medium',
            category    => 'bugs',
            description => 'Undefined variable',
            code_before => 'my $x = $undefined;',
            code_after  => 'my $x = $defined // "default";',
        ),
    );

    my $prompt = Claude::Agent::Code::Refactor::_build_fix_prompt(\@issues);

    like($prompt, qr/lib\/Foo\.pm.*line 42/s, 'contains first file and line');
    like($prompt, qr/high/, 'contains severity');
    like($prompt, qr/security/, 'contains category');
    like($prompt, qr/SQL injection/, 'contains description');
    like($prompt, qr/prepared statements/, 'contains suggestion');
    like($prompt, qr/lib\/Bar\.pm/, 'contains second file');
    like($prompt, qr/code_before.*code_after|Change from.*To/s, 'contains code snippets');
    like($prompt, qr/Edit tool/, 'mentions Edit tool');
};

# Test system prompt
subtest '_get_fix_system_prompt' => sub {
    my $prompt = Claude::Agent::Code::Refactor::_get_fix_system_prompt();

    like($prompt, qr/expert code fixer/, 'mentions expert');
    like($prompt, qr/Read tool/, 'mentions Read tool');
    like($prompt, qr/Edit tool/, 'mentions Edit tool');
    like($prompt, qr/minimal.*focused/i, 'emphasizes minimal changes');
    like($prompt, qr/severity/i, 'mentions severity ordering');
};

# Test Options to_review_options conversion
subtest 'Options to_review_options' => sub {
    SKIP: {
        eval { require Claude::Agent::Code::Review::Options; 1 }
            or skip "Claude::Agent::Code::Review not installed", 5;

        my $refactor_opts = Claude::Agent::Code::Refactor::Options->new(
            min_severity           => 'medium',
            categories             => ['bugs', 'security'],
            perlcritic             => 1,
            perlcritic_severity    => 3,
            filter_false_positives => 1,
            model                  => 'claude-opus-4',
        );

        my $review_opts = $refactor_opts->to_review_options;

        isa_ok($review_opts, 'Claude::Agent::Code::Review::Options');
        is($review_opts->severity, 'medium', 'severity passed through');
        is_deeply($review_opts->categories, ['bugs', 'security'], 'categories passed through');
        is($review_opts->perlcritic, 1, 'perlcritic passed through');
        is($review_opts->perlcritic_severity, 3, 'perlcritic_severity passed through');
        is($review_opts->filter_false_positives, 1, 'filter_false_positives passed through');
        is($review_opts->permission_mode, 'default', 'review uses default permission mode');
    }
};

done_testing();
