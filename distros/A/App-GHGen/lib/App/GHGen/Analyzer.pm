package App::GHGen::Analyzer;

use v5.36;
use warnings;
use strict;

use YAML::XS qw(LoadFile);
use Path::Tiny;

use Exporter 'import';
our @EXPORT_OK = qw(
	analyze_workflow
	find_workflows
	get_cache_suggestion
);

our $VERSION = '0.01';

=head1 NAME

App::GHGen::Analyzer - Analyze GitHub Actions workflows

=head1 SYNOPSIS

    use App::GHGen::Analyzer qw(analyze_workflow);
    
    my @issues = analyze_workflow($workflow_hashref, 'ci.yml');

=head1 FUNCTIONS

=head2 find_workflows()

Find all workflow files in .github/workflows directory.
Returns a list of Path::Tiny objects.

=cut

sub find_workflows() {
    my $workflows_dir = path('.github/workflows');
    return () unless $workflows_dir->exists && $workflows_dir->is_dir;
    return sort $workflows_dir->children(qr/\.ya?ml$/i);
}

=head2 analyze_workflow($workflow, $filename)

Analyze a workflow hash for issues. Returns array of issue hashes.

Each issue has: type, severity, message, fix (optional)

=cut

sub analyze_workflow($workflow, $filename) {
    my @issues;
    
    # Check 1: Missing dependency caching
    unless (has_caching($workflow)) {
        my $cache_suggestion = get_cache_suggestion($workflow);
        push @issues, {
            type => 'performance',
            severity => 'medium',
            message => 'No dependency caching found - increases build times and costs',
            fix => $cache_suggestion
        };
    }
    
    # Check 2: Using unpinned action versions
    my @unpinned = find_unpinned_actions($workflow);
    if (@unpinned) {
        push @issues, {
            type => 'security',
            severity => 'high',
            message => "Found " . scalar(@unpinned) . " action(s) using \@master or \@main",
            fix => "Replace \@master/\@main with specific version tags:\n" .
                   join("\n", map { "       $_" } map { s/\@(master|main)$/\@v5/r } @unpinned[0..min(2, $#unpinned)])
        };
    }
    
    # Check for outdated action versions
    my @outdated = find_outdated_actions($workflow);
    if (@outdated) {
        push @issues, {
            type => 'maintenance',
            severity => 'medium',
            message => "Found " . scalar(@outdated) . " outdated action(s)",
            fix => "Update to latest versions:\n" .
                   join("\n", map { "       $_" } @outdated[0..min(2, $#outdated)])
        };
    }
    
    # Check 3: Overly broad triggers
    if (has_broad_triggers($workflow)) {
        push @issues, {
            type => 'cost',
            severity => 'medium',
            message => 'Workflow triggers on all pushes - consider path/branch filters',
            fix => "Add trigger filters:\n" .
                   "     on:\n" .
                   "       push:\n" .
                   "         branches: [main, develop]\n" .
                   "         paths:\n" .
                   "           - 'src/**'\n" .
                   "           - 'package.json'"
        };
    }
    
    # Check 4: Missing concurrency controls
    unless ($workflow->{concurrency}) {
        push @issues, {
            type => 'cost',
            severity => 'low',
            message => 'No concurrency group - old runs continue when superseded',
            fix => "Add concurrency control:\n" .
                   "     concurrency:\n" .
                   "       group: \${{ github.workflow }}-\${{ github.ref }}\n" .
                   "       cancel-in-progress: true"
        };
    }
    
    # Check 5: Outdated runner versions
    if (has_outdated_runners($workflow)) {
        push @issues, {
            type => 'maintenance',
            severity => 'low',
            message => 'Using older runner versions - consider updating',
            fix => 'Update to ubuntu-latest, macos-latest, or windows-latest'
        };
    }
    
    return @issues;
}

=head2 get_cache_suggestion($workflow)

Generate a caching suggestion based on detected project type.

=cut

sub get_cache_suggestion($workflow) {
    my $detected_type = detect_project_type($workflow);
    
    my %cache_configs = (
        npm => "- uses: actions/cache\@v5\n" .
               "       with:\n" .
               "         path: ~/.npm\n" .
               "         key: \${{ runner.os }}-node-\${{ hashFiles('**/package-lock.json') }}\n" .
               "         restore-keys: |\n" .
               "           \${{ runner.os }}-node-",
        
        pip => "- uses: actions/cache\@v5\n" .
               "       with:\n" .
               "         path: ~/.cache/pip\n" .
               "         key: \${{ runner.os }}-pip-\${{ hashFiles('**/requirements.txt') }}\n" .
               "         restore-keys: |\n" .
               "           \${{ runner.os }}-pip-",
        
        cargo => "- uses: actions/cache\@v5\n" .
                 "       with:\n" .
                 "         path: |\n" .
                 "           ~/.cargo/bin/\n" .
                 "           ~/.cargo/registry/index/\n" .
                 "           ~/.cargo/registry/cache/\n" .
                 "           target/\n" .
                 "         key: \${{ runner.os }}-cargo-\${{ hashFiles('**/Cargo.lock') }}",
        
        bundler => "- uses: actions/cache\@v5\n" .
                   "       with:\n" .
                   "         path: vendor/bundle\n" .
                   "         key: \${{ runner.os }}-gems-\${{ hashFiles('**/Gemfile.lock') }}\n" .
                   "         restore-keys: |\n" .
                   "           \${{ runner.os }}-gems-",
    );
    
    return $cache_configs{$detected_type} // 
           "Add caching based on your dependency manager:\n" .
           "       See: https://docs.github.com/en/actions/using-workflows/caching-dependencies";
}

# Helper functions

sub has_caching($workflow) {
    my $jobs = $workflow->{jobs} or return 0;
    
    for my $job (values %$jobs) {
        my $steps = $job->{steps} or next;
        for my $step (@$steps) {
            return 1 if $step->{uses} && $step->{uses} =~ /actions\/cache/;
        }
    }
    return 0;
}

sub find_unpinned_actions($workflow) {
    my @unpinned;
    my $jobs = $workflow->{jobs} or return @unpinned;
    
    for my $job (values %$jobs) {
        my $steps = $job->{steps} or next;
        for my $step (@$steps) {
            next unless $step->{uses};
            if ($step->{uses} =~ /\@(master|main)$/) {
                push @unpinned, $step->{uses};
            }
        }
    }
    return @unpinned;
}

sub has_broad_triggers($workflow) {
    my $on = $workflow->{on};
    return 0 unless $on;
    
    # Check if push trigger has no path or branch filters
    if (ref $on eq 'HASH' && $on->{push}) {
        my $push = $on->{push};
        return 1 if ref $push eq '' || (!$push->{paths} && !$push->{branches});
    }
    
    # Simple array of triggers including 'push'
    if (ref $on eq 'ARRAY' && grep { $_ eq 'push' } @$on) {
        return 1;
    }
    
    return 0;
}

sub has_outdated_runners($workflow) {
    my $jobs = $workflow->{jobs} or return 0;
    
    for my $job (values %$jobs) {
        my $runs_on = $job->{'runs-on'} or next;
        return 1 if $runs_on =~ /ubuntu-18\.04|ubuntu-16\.04|macos-10\.15/;
    }
    return 0;
}

sub detect_project_type($workflow) {
    my $jobs = $workflow->{jobs} or return 'unknown';
    
    for my $job (values %$jobs) {
        my $steps = $job->{steps} or next;
        for my $step (@$steps) {
            my $run = $step->{run} // '';
            return 'npm' if $run =~ /npm (install|ci)/;
            return 'pip' if $run =~ /pip install/;
            return 'cargo' if $run =~ /cargo (build|test)/;
            return 'bundler' if $run =~ /bundle install/;
        }
    }
    return 'unknown';
}

sub min($a, $b) {
    return $a < $b ? $a : $b;
}

sub find_outdated_actions($workflow) {
    my @outdated;
    my $jobs = $workflow->{jobs} or return @outdated;
    
    # Known outdated versions
    my %updates = (
        'actions/cache@v4' => 'actions/cache@v5',
        'actions/cache@v3' => 'actions/cache@v5',
        'actions/checkout@v5' => 'actions/checkout@v6',
        'actions/checkout@v4' => 'actions/checkout@v6',
        'actions/checkout@v3' => 'actions/checkout@v6',
        'actions/setup-node@v3' => 'actions/setup-node@v4',
        'actions/setup-python@v4' => 'actions/setup-python@v5',
        'actions/setup-go@v4' => 'actions/setup-go@v5',
    );
    
    for my $job (values %$jobs) {
        my $steps = $job->{steps} or next;
        for my $step (@$steps) {
            next unless $step->{uses};
            my $uses = $step->{uses};
            
            for my $old (keys %updates) {
                if ($uses =~ /^\Q$old\E/) {
                    push @outdated, "$old → $updates{$old}";
                }
            }
        }
    }
    
    return @outdated;
}

sub has_deployment_steps($workflow) {
    my $jobs = $workflow->{jobs} or return 0;
    
    for my $job (values %$jobs) {
        my $steps = $job->{steps} or next;
        for my $step (@$steps) {
            # Check for deployment-related actions
            return 1 if $step->{uses} && $step->{uses} =~ /deploy|publish|release/i;
            return 1 if $step->{run} && $step->{run} =~ /git push|npm publish/;
        }
    }
    
	return 0;
}

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

L<https://github.com/nigelhorne>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
