package App::GHGen::CostEstimator;

use v5.36;
use strict;
use warnings;
use YAML::XS qw(LoadFile);
use Path::Tiny;

use Exporter 'import';
our @EXPORT_OK = qw(
	estimate_current_usage
	estimate_savings
	estimate_workflow_cost
);

our $VERSION = '0.01';

=head1 NAME

App::GHGen::CostEstimator - Estimate CI costs and savings

=head1 SYNOPSIS

    use App::GHGen::CostEstimator qw(estimate_current_usage);
    
    my $estimate = estimate_current_usage(\@workflows);

=head1 FUNCTIONS

=head2 estimate_current_usage($workflows)

Estimate current monthly CI usage based on workflow configurations.

=cut

sub estimate_current_usage($workflows) {
    my $total_minutes = 0;
    my @workflow_costs;
    
    for my $wf_file (@$workflows) {
        my $workflow = LoadFile($wf_file);
        my $cost = estimate_workflow_cost($workflow, $wf_file->basename);
        
        $total_minutes += $cost->{minutes_per_month};
        push @workflow_costs, $cost;
    }
    
    # GitHub pricing (approximate)
    # Free tier: 2,000 minutes/month for private repos
    # Additional: $0.008 per minute
    my $cost_per_minute = 0.008;
    my $free_tier = 2000;
    
    my $billable_minutes = $total_minutes > $free_tier ? 
                          ($total_minutes - $free_tier) : 0;
    
    my $monthly_cost = $billable_minutes * $cost_per_minute;
    
    return {
        total_minutes => $total_minutes,
        billable_minutes => $billable_minutes,
        monthly_cost => $monthly_cost,
        workflows => \@workflow_costs,
    };
}

=head2 estimate_workflow_cost($workflow, $filename)

Estimate the cost of a single workflow.

=cut

sub estimate_workflow_cost($workflow, $filename) {
    my $name = $workflow->{name} // $filename;
    
    # Estimate triggers per month
    my $runs_per_month = estimate_runs_per_month($workflow);
    
    # Estimate duration per run
    my $minutes_per_run = estimate_duration($workflow);
    
    # Calculate total
    my $minutes_per_month = $runs_per_month * $minutes_per_run;
    
    return {
        name => $name,
        file => $filename,
        runs_per_month => $runs_per_month,
        minutes_per_run => $minutes_per_run,
        minutes_per_month => $minutes_per_month,
    };
}

=head2 estimate_savings($issues, $workflows)

Estimate potential savings from fixing issues.

=cut

sub estimate_savings($issues, $workflows = []) {
    my %savings = (
        minutes => 0,
        percentage => 0,
        cost => 0,
        details => [],
    );
    
    # Get current usage if workflows provided
    my $current_usage = @$workflows ? estimate_current_usage($workflows) : undef;
    
    for my $issue (@$issues) {
        my $saving = 0;
        my $description = '';
        
        if ($issue->{type} eq 'performance') {
            if ($issue->{message} =~ /caching/) {
                # Caching typically saves 30-60 seconds per run
                # Estimate 100 runs/month affected
                $saving = 100 * 0.75;  # 75 minutes
                $description = 'Adding dependency caching';
            }
        }
        elsif ($issue->{type} eq 'cost') {
            if ($issue->{message} =~ /concurrency/) {
                # Concurrency saves by canceling superseded runs
                # Estimate 10-20% of runs are canceled
                if ($current_usage) {
                    $saving = $current_usage->{total_minutes} * 0.15;
                } else {
                    $saving = 50;  # Conservative estimate
                }
                $description = 'Adding concurrency controls';
            }
            elsif ($issue->{message} =~ /triggers/) {
                # Trigger filters reduce unnecessary runs
                # Estimate 20-30% of runs avoided
                if ($current_usage) {
                    $saving = $current_usage->{total_minutes} * 0.25;
                } else {
                    $saving = 100;  # Conservative estimate
                }
                $description = 'Optimizing workflow triggers';
            }
        }
        
        if ($saving > 0) {
            $savings{minutes} += $saving;
            push @{$savings{details}}, {
                description => $description,
                minutes => int($saving),
                issue_type => $issue->{type},
            };
        }
    }
    
    # Calculate percentage and cost
    if ($current_usage && $current_usage->{total_minutes} > 0) {
        $savings{percentage} = int(($savings{minutes} / $current_usage->{total_minutes}) * 100);
    } elsif ($savings{minutes} > 0) {
        $savings{percentage} = 30;  # Estimate 30% savings
    }
    
    $savings{cost} = sprintf("%.2f", $savings{minutes} * 0.008);
    $savings{minutes} = int($savings{minutes});
    
    return \%savings;
}

sub estimate_runs_per_month($workflow) {
    my $on = $workflow->{on} or return 50;  # Default estimate
    
    my $runs = 0;
    
    # Parse different trigger formats
    if (ref $on eq 'ARRAY') {
        for my $trigger (@$on) {
            $runs += estimate_trigger_frequency($trigger);
        }
    }
    elsif (ref $on eq 'HASH') {
        for my $trigger (keys %$on) {
            $runs += estimate_trigger_frequency($trigger, $on->{$trigger});
        }
    }
    else {
        $runs += estimate_trigger_frequency($on);
    }
    
    return $runs || 50;  # Minimum estimate
}

sub estimate_trigger_frequency($trigger, $config = undef) {
    # Estimates based on typical project activity
    my %frequencies = (
        push => 100,           # ~5 pushes/day for active projects
        pull_request => 60,    # ~2-3 PRs/day
        schedule => 30,        # Depends on cron, assume daily
        workflow_dispatch => 10,  # Manual runs
        release => 4,          # ~1 per week
        issues => 20,          # Issue activity
    );
    
    my $base = $frequencies{$trigger} // 20;
    
    # Adjust based on configuration
    if ($config && ref $config eq 'HASH') {
        # If it has branches filter, likely fewer runs
        if ($config->{branches}) {
            $base *= 0.6;  # 40% reduction
        }
        
        # If it has paths filter, significantly fewer runs
        if ($config->{paths}) {
            $base *= 0.3;  # 70% reduction
        }
    }
    
    return int($base);
}

sub estimate_duration($workflow) {
    my $jobs = $workflow->{jobs} or return 5;  # Default 5 minutes
    
    my $total_duration = 0;
    my $max_parallel_duration = 0;
    
    # Check if jobs run in parallel or sequence
    my $has_dependencies = 0;
    for my $job (values %$jobs) {
        $has_dependencies = 1 if $job->{needs};
    }
    
    for my $job (values %$jobs) {
        my $duration = estimate_job_duration($job);
        
        if ($has_dependencies) {
            # Sequential - add durations
            $total_duration += $duration;
        } else {
            # Parallel - track maximum
            $max_parallel_duration = $duration if $duration > $max_parallel_duration;
        }
    }
    
    my $estimated = $has_dependencies ? $total_duration : $max_parallel_duration;
    
    # Factor in matrix multiplier
    my $matrix_factor = estimate_matrix_factor($workflow);
    
    return int($estimated * $matrix_factor) || 5;
}

sub estimate_job_duration($job) {
    my $steps = $job->{steps} or return 3;
    
    my $duration = 0;
    
    for my $step (@$steps) {
        # Estimate based on step type
        if ($step->{uses}) {
            my $uses = $step->{uses};
            
            # Common actions and their typical durations
            if ($uses =~ /checkout/) {
                $duration += 0.5;
            }
            elsif ($uses =~ /setup-(node|python|go|ruby)/) {
                $duration += 1;
            }
            elsif ($uses =~ /cache/) {
                # Cache hit: ~10s, miss: ~30s
                $duration += 0.3;
            }
        }
        elsif ($step->{run}) {
            my $run = $step->{run};
            
            # Estimate based on command
            if ($run =~ /npm (install|ci)/) {
                $duration += 2;  # npm install takes time
            }
            elsif ($run =~ /pip install/) {
                $duration += 1.5;
            }
            elsif ($run =~ /cargo build/) {
                $duration += 5;  # Rust builds are slow
            }
            elsif ($run =~ /(npm|pytest|cargo|go) test/) {
                $duration += 2;  # Test suites
            }
            else {
                $duration += 0.5;  # Generic command
            }
        }
    }
    
    return $duration || 3;
}

sub estimate_matrix_factor($workflow) {
    my $jobs = $workflow->{jobs} or return 1;
    
    my $max_matrix_size = 1;
    
    for my $job (values %$jobs) {
        next unless $job->{strategy};
        next unless $job->{strategy}->{matrix};
        
        my $matrix = $job->{strategy}->{matrix};
        my $size = 1;
        
        # Calculate matrix size
        for my $key (keys %$matrix) {
            next if $key eq 'include' || $key eq 'exclude';
            my $values = $matrix->{$key};
            if (ref $values eq 'ARRAY') {
                $size *= scalar @$values;
            }
        }
        
        $max_matrix_size = $size if $size > $max_matrix_size;
    }
    
	return $max_matrix_size;
}

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

L<https://github.com/nigelhorne>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
