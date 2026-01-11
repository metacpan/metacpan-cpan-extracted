#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Claude::Agent::Code::Refactor');
use_ok('Claude::Agent::Code::Refactor::Options');
use_ok('Claude::Agent::Code::Refactor::Result');

subtest 'refactor requires target' => sub {
    throws_ok {
        Claude::Agent::Code::Refactor::refactor()->get;
    } qr/requires 'target'/, 'refactor dies without target';
};

subtest 'refactor_until_clean requires paths' => sub {
    throws_ok {
        Claude::Agent::Code::Refactor::refactor_until_clean()->get;
    } qr/requires 'paths'/, 'refactor_until_clean dies without paths';
};

subtest 'refactor_issues requires issues' => sub {
    throws_ok {
        Claude::Agent::Code::Refactor::refactor_issues()->get;
    } qr/requires 'issues'/, 'refactor_issues dies without issues';
};

subtest 'refactor rejects unknown target type' => sub {
    throws_ok {
        Claude::Agent::Code::Refactor::refactor(
            target => 'nonexistent_path_12345',
        )->get;
    } qr/Unknown target type/, 'rejects non-existent path';
};

subtest 'Result iteration with missing values' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new();

    lives_ok {
        $result->add_iteration();
    } 'add_iteration works with no arguments';

    is($result->iterations, 1, 'iteration counted');
    is($result->fixes_applied, 0, 'fixes_applied defaults to 0');
    is_deeply($result->files_modified, [], 'files_modified defaults to empty');
    is($result->history->[0]{issues_found}, 0, 'issues_found defaults to 0');
    is($result->history->[0]{issues_fixed}, 0, 'issues_fixed defaults to 0');
};

subtest 'Result multiple iterations tracking' => sub {
    my $result = Claude::Agent::Code::Refactor::Result->new();

    for my $i (1..5) {
        $result->add_iteration(
            issues_found   => 10 - $i,
            issues_fixed   => 2,
            files_modified => ["file$i.pm"],
        );
    }

    is($result->iterations, 5, '5 iterations recorded');
    is($result->fixes_applied, 10, 'total fixes accumulated');
    is(scalar(@{$result->files_modified}), 5, 'all files tracked');
    is(scalar(@{$result->history}), 5, 'history has 5 entries');

    for my $i (0..4) {
        is($result->history->[$i]{iteration}, $i + 1, "iteration " . ($i+1) . " numbered correctly");
    }
};

subtest 'Options all severities' => sub {
    for my $sev (qw(critical high medium low info)) {
        my $opts = Claude::Agent::Code::Refactor::Options->new(
            min_severity => $sev,
        );
        is($opts->min_severity, $sev, "accepts severity: $sev");
    }
};

subtest 'Options all categories' => sub {
    my @cats = qw(bugs security style performance maintainability);
    my $opts = Claude::Agent::Code::Refactor::Options->new(
        categories => \@cats,
    );
    is_deeply($opts->categories, \@cats, 'accepts all categories together');
};

subtest 'fix_rate edge cases' => sub {
    my $zero_initial = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 0,
        final_issues   => 0,
    );
    is($zero_initial->fix_rate, 100, 'fix_rate is 100% when no initial issues');

    my $partial = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 3,
        final_issues   => 1,
    );
    is($partial->fix_rate, 66, 'fix_rate rounds down (66.67% -> 66%)');
};

subtest 'issues_fixed never negative' => sub {
    my $more_final = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => 5,
        final_issues   => 10,
    );
    is($more_final->issues_fixed, 0, 'issues_fixed returns 0 when final > initial');
};

done_testing();
