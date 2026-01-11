package Claude::Agent::Code::Refactor;

use 5.020;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(refactor refactor_issues refactor_until_clean);

use Claude::Agent qw(query);
use Claude::Agent::Options;
use Claude::Agent::Code::Review qw(review_files);
use Claude::Agent::Code::Refactor::Options;
use Claude::Agent::Code::Refactor::Result;
use IO::Async::Loop;
use Future::AsyncAwait;
use Time::HiRes qw(time);

our $VERSION = '0.01';

=head1 NAME

Claude::Agent::Code::Refactor - Automated code refactoring with review-fix loops

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Claude::Agent::Code::Refactor qw(refactor refactor_until_clean);
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;

    # Automatic review -> fix -> re-review loop
    my $result = refactor_until_clean(
        paths   => ['lib/'],
        options => Claude::Agent::Code::Refactor::Options->new(
            max_iterations  => 5,
            min_severity    => 'medium',
            categories      => ['bugs', 'security'],
            permission_mode => 'acceptEdits',
        ),
        loop    => $loop,
    )->get;

    if ($result->is_clean) {
        print "All issues resolved!\n";
    } else {
        print "Remaining issues: ", $result->final_issues, "\n";
    }

=head1 DESCRIPTION

Claude::Agent::Code::Refactor provides automated code refactoring using the
Claude Agent SDK. It integrates with Claude::Agent::Code::Review to create
a review-fix-re-review loop that automatically fixes issues until the code
is clean (or max iterations reached).

=head1 EXPORTED FUNCTIONS

=head2 refactor

    my $future = refactor(
        target  => $target,      # file, dir, or 'staged'
        options => $options,     # Claude::Agent::Code::Refactor::Options
        loop    => $loop,        # IO::Async::Loop
    );
    my $result = $future->get;

High-level refactor function that auto-detects the target type.

=cut

async sub refactor {
    my (%args) = @_;

    my $target  = $args{target} // die "refactor() requires 'target' argument";
    my $options = $args{options} // Claude::Agent::Code::Refactor::Options->new();
    my $loop    = $args{loop} // IO::Async::Loop->new;

    my @paths;
    if (-d $target || -f $target) {
        @paths = ($target);
    }
    else {
        die "Unknown target type: $target (must be file or directory)";
    }

    return await refactor_until_clean(
        paths   => \@paths,
        options => $options,
        loop    => $loop,
    );
}

=head2 refactor_until_clean

    my $future = refactor_until_clean(
        paths   => \@paths,      # files and/or directories
        options => $options,
        loop    => $loop,
    );
    my $result = $future->get;

Main refactoring loop: review -> fix -> re-review until clean or max iterations.

=cut

async sub refactor_until_clean {
    my (%args) = @_;

    my $paths   = $args{paths} // die "refactor_until_clean() requires 'paths' argument";
    my $options = $args{options} // Claude::Agent::Code::Refactor::Options->new();
    my $loop    = $args{loop} // IO::Async::Loop->new;

    my $start_time = time();

    my $result = Claude::Agent::Code::Refactor::Result->new();

    my $review_options = $options->to_review_options;

    for my $iteration (1 .. $options->max_iterations) {
        # Step 1: Review the code
        my $report = await review_files(
            paths   => $paths,
            options => $review_options,
            loop    => $loop,
        );

        if (!defined $report) {
            $result->{error} = 'Review failed to return a report';
            last;
        }
        my @issues = @{$report->issues // []};
        my $issues_found = scalar @issues;

        # Record initial issues on first iteration
        if ($iteration == 1) {
            $result->{initial_issues} = $issues_found;
        }

        # Step 2: Check if we're done
        if ($issues_found == 0) {
            $result->{success} = 1;
            $result->{final_issues} = 0;
            $result->{final_report} = $report;
            $result->add_iteration(
                issues_found   => 0,
                issues_fixed   => 0,
                files_modified => [],
            );
            last;
        }

        # Step 3: Fix the issues
        my $fix_result;
        if ($options->dry_run) {
            # Dry run - just report what would be fixed
            $fix_result = {
                issues_fixed   => 0,
                files_modified => [],
            };
        }
        else {
            $fix_result = await _fix_issues(\@issues, $options, $loop);
        }

        # Step 4: Record this iteration
        $result->add_iteration(
            issues_found   => $issues_found,
            issues_fixed   => $fix_result->{issues_fixed} // 0,
            files_modified => $fix_result->{files_modified} // [],
        );

        # Simplified: stop if no fixes were applied (stall detection)
        if ($iteration > 1 && $fix_result->{issues_fixed} == 0) {
            # No progress or not improving - stop to avoid infinite loop
            # Note: This check may not catch all stall conditions
            $result->{final_issues} = $issues_found;
            $result->{final_report} = $report;

            if ($fix_result->{error}) {
                $result->{error} = $fix_result->{error};
            }
            last;
        }

        # Update final state (will be overwritten if we continue)
        # Note: final_issues will be accurately calculated by final review
        $result->{final_report} = $report;

        # Track issue count for next iteration's progress check
        $result->{previous_issue_count} = $issues_found;
    }

    # Final review to get accurate issue count
    if (!$result->is_clean && !$result->has_error) {
        my $final_report = await review_files(
            paths   => $paths,
            options => $review_options,
            loop    => $loop,
        );
        if (!defined $final_report) {
            $result->{error} = 'Final review failed to return a report';
        } else {
            $result->{final_issues} = scalar @{$final_report->issues // []};
            $result->{final_report} = $final_report;
            $result->{success} = ($result->{final_issues} == 0);
        }
    }

    $result->{duration_ms} = int((time() - $start_time) * 1000);

    return $result;
}

=head2 refactor_issues

    my $future = refactor_issues(
        issues  => \@issues,     # Claude::Agent::Code::Review::Issue objects
        options => $options,
        loop    => $loop,
    );
    my $result = $future->get;

Fix a specific set of issues (single pass, no re-review).

=cut

async sub refactor_issues {
    my (%args) = @_;

    my $issues  = $args{issues} // die "refactor_issues() requires 'issues' argument";
    my $options = $args{options} // Claude::Agent::Code::Refactor::Options->new();
    my $loop    = $args{loop} // IO::Async::Loop->new;

    my $start_time = time();

    my $result = Claude::Agent::Code::Refactor::Result->new(
        initial_issues => scalar(@$issues),
    );

    if (@$issues == 0) {
        $result->{success} = 1;
        $result->{final_issues} = 0;
        $result->{duration_ms} = int((time() - $start_time) * 1000);
        return $result;
    }

    my $fix_result = await _fix_issues($issues, $options, $loop);

    $result->add_iteration(
        issues_found   => scalar(@$issues),
        issues_fixed   => $fix_result->{issues_fixed} // 0,
        files_modified => $fix_result->{files_modified} // [],
    );

    my $remaining = scalar(@$issues) - ($fix_result->{issues_fixed} // 0);
    $result->{final_issues} = $remaining > 0 ? $remaining : 0;
    $result->{success} = ($result->{final_issues} == 0);
    $result->{duration_ms} = int((time() - $start_time) * 1000);

    if ($fix_result->{error}) {
        $result->{error} = $fix_result->{error};
    }

    return $result;
}

# Internal: Fix a set of issues using Claude
async sub _fix_issues {
    my ($issues, $options, $loop) = @_;

    return { issues_fixed => 0, files_modified => [] } unless @$issues;

    # Sort by severity (critical first)
    my %severity_rank = (critical => 5, high => 4, medium => 3, low => 2, info => 1);
    my @sorted = sort {
        ($severity_rank{$b->severity} // 0) <=> ($severity_rank{$a->severity} // 0)
    } @$issues;

    # Build the fix prompt
    my $prompt = _build_fix_prompt(\@sorted);

    # Build Claude options for fixing
    my %claude_args = (
        allowed_tools   => ['Read', 'Edit', 'Glob', 'Grep'],
        permission_mode => $options->permission_mode,
        system_prompt   => _get_fix_system_prompt(),
        max_turns       => $options->max_turns_per_fix,
    );
    $claude_args{model} = $options->model if defined $options->model;

    my $claude_options = Claude::Agent::Options->new(%claude_args);

    # Run the fix query
    my $iter = query(
        prompt  => $prompt,
        options => $claude_options,
        loop    => $loop,
    );

    # Track what gets fixed
    my %files_modified;
    my $edit_count = 0;  # Track actual Edit operations attempted

    my $max_iterations = 1000;
    my $iteration_count = 0;
    my $start_time = time();
    my $timeout_seconds = 300;  # 5 minute timeout

    my $timeout_result;
    eval {
        while (my $msg = await $iter->next_async) {
            # Check timeout at start of loop iteration
            if ((time() - $start_time) > $timeout_seconds) {
                $iter->cancel if $iter->can('cancel');
                $timeout_result = { issues_fixed => $edit_count, files_modified => [keys %files_modified], error => 'Fix operation timed out after 5 minutes' };
                last;
            }
            $iteration_count++;
            last if $iteration_count >= $max_iterations;

            if ($msg->isa('Claude::Agent::Message::Assistant')) {
                for my $block (@{$msg->content_blocks}) {
                    if ($block->isa('Claude::Agent::Content::ToolUse')) {
                        if ($block->name eq 'Edit') {
                            $edit_count++;  # Count each Edit operation
                            my $input = $block->input;
                            if ($input && ref($input) eq 'HASH') {
                                my $file = $input->{file_path};
                                $files_modified{$file} = 1 if defined $file && length $file;
                            }
                        }
                    }
                }
            }
            elsif ($msg->isa('Claude::Agent::Message::Result')) {
                last;
            }
        }
    };
    return $timeout_result if $timeout_result;
    my $error = $@;  # Capture $@ immediately to prevent clobbering
    if ($error) {
        warn "Fix error: $error";  # Log for debugging
        my $safe_error = "An error occurred during fix operation";
        return { issues_fixed => 0, files_modified => [], error => $safe_error };
    }

    return {
        issues_fixed   => $edit_count,  # Count of Edit operations attempted
        files_modified => [keys %files_modified],
    };
}

# Internal: Build prompt for fixing issues
# SECURITY NOTE: Issue data (file, description, suggestion, code_before, code_after)
# is concatenated directly into the prompt. This function assumes issue data comes
# from trusted sources (e.g., Claude::Agent::Code::Review). If issue data originates
# from untrusted external sources, sanitization should be performed by the caller.
sub _build_fix_prompt {
    my ($issues) = @_;

    my $prompt = "Fix the following issues found in code review:\n\n";

    for my $issue (@$issues) {
        $prompt .= sprintf("## Issue in %s (line %d)\n", $issue->file, $issue->line);
        $prompt .= "Severity: " . $issue->severity . "\n";
        $prompt .= "Category: " . $issue->category . "\n";
        $prompt .= "Description: " . $issue->description . "\n";

        if ($issue->has_explanation) {
            $prompt .= "Explanation: " . $issue->explanation . "\n";
        }

        if ($issue->has_suggestion) {
            $prompt .= "Suggestion: " . $issue->suggestion . "\n";
        }

        if ($issue->has_code_before && $issue->has_code_after) {
            $prompt .= "Change from:\n```\n" . $issue->code_before . "\n```\n";
            $prompt .= "To:\n```\n" . $issue->code_after . "\n```\n";
        }

        $prompt .= "\n";
    }

    $prompt .= "Please fix each issue by reading the file and using the Edit tool.\n";

    return $prompt;
}

# Internal: System prompt for fixing
sub _get_fix_system_prompt {
    return <<'END';
You are an expert code fixer. You will be given code issues found by a code review.

Your task:
1. Read each issue carefully (file, line, description, suggestion)
2. Use the Read tool to examine the actual code context
3. Use the Edit tool to fix each issue
4. Make minimal, focused changes - only fix the reported issue
5. Do NOT introduce new issues or change unrelated code

For each fix:
- Read the file first to understand context
- Apply the smallest change that resolves the issue
- If code_after is provided, use it as a guide
- If you cannot fix an issue safely, skip it and explain why

Fix issues in order of severity (critical first, then high, medium, low).
END
}

=head1 SEE ALSO

=over 4

=item * L<Claude::Agent> - Main SDK module

=item * L<Claude::Agent::Code::Review> - Code review module

=item * L<Claude::Agent::Code::Refactor::Options> - Refactor configuration

=item * L<Claude::Agent::Code::Refactor::Result> - Refactor result object

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
