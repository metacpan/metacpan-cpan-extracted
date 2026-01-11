package Claude::Agent::Code::Review;

use 5.020;
use strict;
use warnings;

## no critic (Modules::RequireEndWithOne)
# Note: This directive suppresses a false positive from Perl::Critic.
# The module correctly ends with '1;' but perlcritic sometimes misdetects
# this in modules with complex async/await code or large POD sections.

use Exporter 'import';
our @EXPORT_OK = qw(review review_files review_diff);

use Claude::Agent qw(query tool create_sdk_mcp_server);
use Claude::Agent::Options;
use Claude::Agent::Code::Review::Options;
use Claude::Agent::Code::Review::Report;
use Claude::Agent::Code::Review::Issue;
use Claude::Agent::Code::Review::Tools;
use Claude::Agent::Code::Review::Perlcritic;
use Claude::Agent::Code::Review::Filter;
use IO::Async::Loop;
use IO::Async::Process;
use Future::AsyncAwait;
use Path::Tiny;
use Cpanel::JSON::XS qw(decode_json);

our $VERSION = '0.01';

=head1 NAME

Claude::Agent::Code::Review - AI-powered code review using Claude

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Claude::Agent::Code::Review qw(review review_files review_diff);
    use Claude::Agent::Code::Review::Options;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;

    # Combined AI + Perl::Critic review (recommended for CI/CD)
    my $options = Claude::Agent::Code::Review::Options->new(
        categories          => ['bugs', 'security', 'style'],
        severity            => 'medium',
        permission_mode     => 'bypassPermissions',
        # Enable deterministic perlcritic alongside AI review
        perlcritic          => 1,
        perlcritic_severity => 4,  # 1=brutal, 5=gentle
    );

    my $report = review_files(
        paths   => ['lib/'],
        options => $options,
        loop    => $loop,
    )->get;

    # Process results
    if ($report->has_issues) {
        print $report->summary, "\n";
        for my $issue (@{$report->issues}) {
            printf "%s [%s] %s:%d - %s\n",
                $issue->severity,
                $issue->category,
                $issue->file,
                $issue->line,
                $issue->description;
        }
    }

    # Review staged git changes
    my $staged_report = review_diff(
        staged  => 1,
        options => $options,
        loop    => $loop,
    )->get;

    # Simple high-level review (auto-detects file/dir/staged)
    my $report = review(
        target  => 'lib/MyModule.pm',
        options => $options,
        loop    => $loop,
    )->get;

=head1 DESCRIPTION

Claude::Agent::Code::Review provides AI-powered code review using the Claude Agent SDK.
It analyzes code for bugs, security vulnerabilities, style issues, performance
problems, and maintainability concerns.

All functions return Futures for async operation.

B<Note:> By default, permission_mode is set to 'default' which prompts for
permissions. For automated/CI usage, set C<< permission_mode => 'bypassPermissions' >>
in your Options.

=head1 EXPORTED FUNCTIONS

=head2 review

    my $future = review(
        target  => $target,      # file, dir, or 'staged'
        options => $options,     # Claude::Agent::Code::Review::Options
        loop    => $loop,        # IO::Async::Loop
    );
    my $report = $future->get;

High-level review function that auto-detects the review mode.

=cut

async sub review {
    my (%args) = @_;

    my $target  = $args{target} // die "review() requires 'target' argument";
    my $options = $args{options} // Claude::Agent::Code::Review::Options->new();
    my $loop    = $args{loop} // IO::Async::Loop->new;

    if ($target eq 'staged') {
        return await review_diff(
            staged  => 1,
            options => $options,
            loop    => $loop,
        );
    }
    elsif (-d $target || -f $target) {
        # Note: TOCTOU race possible here, but review_files() handles missing
        # files gracefully and will report appropriate errors if target changes
        return await review_files(
            paths   => [$target],
            options => $options,
            loop    => $loop,
        );
    }
    elsif (_is_diff_content($target)) {
        # Detected as diff content (git diff, unified diff, or svn diff)
        return await review_diff(
            diff    => $target,
            options => $options,
            loop    => $loop,
        );
    }
    else {
        die "Unknown target type: $target";
    }
}

=head2 review_files

    my $future = review_files(
        paths   => \@paths,      # files and/or directories
        options => $options,
        loop    => $loop,
    );
    my $report = $future->get;

Review specific files or directories.

=cut

async sub review_files {
    my (%args) = @_;

    my $paths   = $args{paths} // die "review_files() requires 'paths' argument";
    my $options = $args{options} // Claude::Agent::Code::Review::Options->new();
    my $loop    = $args{loop} // IO::Async::Loop->new;

    my $prompt = _build_files_prompt($paths, $options);
    my $report = await _run_review($prompt, $options, $loop);

    # Filter false positives from AI review if enabled
    my $filtered_count = 0;
    if ($options->filter_false_positives) {
        my @original = @{$report->issues};
        my @filtered = Claude::Agent::Code::Review::Filter->filter(
            issues  => \@original,
            filters => $options->custom_filters,
        );
        $filtered_count = scalar(@original) - scalar(@filtered);
        if ($filtered_count > 0) {
            # Regenerate summary with filtered issues
            my $new_summary = Claude::Agent::Code::Review::Report->generate_summary(\@filtered);
            $report = Claude::Agent::Code::Review::Report->new(
                summary => $new_summary,
                issues  => \@filtered,
                metrics => $report->metrics,
            );
        }
    }

    # Add perlcritic issues if enabled
    if ($options->has_perlcritic) {
        my @pc_issues = Claude::Agent::Code::Review::Perlcritic->analyze(
            paths   => $paths,
            options => $options,
        );
        # Merge perlcritic issues with AI review issues
        my @all_issues = (@{$report->issues}, @pc_issues);
        $report = Claude::Agent::Code::Review::Report->new(
            summary            => $report->summary,
            issues             => \@all_issues,
            metrics            => $report->metrics,
            perlcritic_enabled => 1,
            perlcritic_issues  => \@pc_issues,
            filtered_count     => $filtered_count,
        );
    }
    elsif ($filtered_count > 0) {
        # Update report with filtered count even without perlcritic
        $report = Claude::Agent::Code::Review::Report->new(
            summary        => $report->summary,
            issues         => $report->issues,
            metrics        => $report->metrics,
            filtered_count => $filtered_count,
        );
    }

    return $report;
}

=head2 review_diff

    my $future = review_diff(
        diff    => $diff_text,   # diff content
        # OR
        staged  => 1,            # review staged changes
        options => $options,
        loop    => $loop,
    );
    my $report = $future->get;

Review a diff or staged changes.

=cut

async sub review_diff {
    my (%args) = @_;

    my $options = $args{options} // Claude::Agent::Code::Review::Options->new();
    my $loop    = $args{loop} // IO::Async::Loop->new;

    my $diff;
    if ($args{staged}) {
        my $result = await _run_git_diff_cached_async($loop);
        if ($result->{error}) {
            return Claude::Agent::Code::Review::Report->new(
                summary => $result->{error},
                issues  => [],
            );
        }
        $diff = $result->{diff};
        if (!$diff || $diff =~ /^\s*$/) {
            return Claude::Agent::Code::Review::Report->new(
                summary => 'No staged changes to review',
                issues  => [],
            );
        }
    }
    elsif ($args{diff}) {
        $diff = $args{diff};
    }
    else {
        die "review_diff() requires 'diff' or 'staged' argument";
    }

    my $prompt = _build_diff_prompt($diff, $options);
    return await _run_review($prompt, $options, $loop);
}

# Internal: Build prompt for file review
sub _build_files_prompt {
    my ($paths, $options) = @_;

    my @path_list = ref $paths eq 'ARRAY' ? @$paths : ($paths);
    my $paths_str = join(', ', @path_list);

    my $categories = join(', ', @{$options->categories});
    my $severity = $options->severity;

    my $focus = '';
    if ($options->has_focus_areas && @{$options->focus_areas}) {
        $focus = "\n\nPay special attention to: " . join(', ', @{$options->focus_areas});
    }

    return <<"END_PROMPT";
Review the following code paths for issues: $paths_str

Categories to check: $categories
Minimum severity to report: $severity
$focus

Use the provided tools to read files and gather context. For each issue found, provide:
- File path and line number
- Severity (critical, high, medium, low, info)
- Category (bugs, security, style, performance, maintainability)
- Clear description of the problem
- Suggested fix when possible

Return your findings as a structured JSON response.
END_PROMPT
}

# Internal: Build prompt for diff review
sub _build_diff_prompt {
    my ($diff, $options) = @_;

    my $categories = join(', ', @{$options->categories});
    my $severity = $options->severity;

    my $focus = '';
    if ($options->has_focus_areas && @{$options->focus_areas}) {
        $focus = "\n\nPay special attention to: " . join(', ', @{$options->focus_areas});
    }

    return <<"END_PROMPT";
Review the following diff for issues:

```diff
$diff
```

Categories to check: $categories
Minimum severity to report: $severity
$focus

For each issue found in the changed code, provide:
- File path and line number
- Severity (critical, high, medium, low, info)
- Category (bugs, security, style, performance, maintainability)
- Clear description of the problem
- Suggested fix when possible

Return your findings as a structured JSON response.
END_PROMPT
}

# Internal: Run the review query
async sub _run_review {
    my ($prompt, $options, $loop) = @_;

    # Create MCP server with review tools
    my $tools_server = Claude::Agent::Code::Review::Tools->create_server();

    # Build the JSON schema for structured output
    my $review_schema = _get_review_schema();

    # Build Claude options
    my %claude_args = (
        allowed_tools => [
            'Read', 'Glob', 'Grep',
            @{$tools_server->tool_names},
        ],
        mcp_servers     => { review => $tools_server },
        permission_mode => $options->permission_mode,  # Uses Options default ('default')
        system_prompt   => _get_system_prompt($options),
        output_format   => {
            type   => 'json_schema',
            schema => $review_schema,
        },
    );
    $claude_args{model} = $options->model if defined $options->model;

    my $claude_options = Claude::Agent::Options->new(%claude_args);

    # Run query
    my $iter = query(
        prompt  => $prompt,
        options => $claude_options,
        loop    => $loop,
    );

    # Collect result asynchronously with iteration limit
    my $result;
    my $max_iterations = 1000;  # Prevent infinite loops
    my $iterations = 0;

    while (my $msg = await $iter->next_async) {
        $iterations++;
        if ($msg->isa('Claude::Agent::Message::Result')) {
            $result = $msg;
            last;
        }
        if ($iterations >= $max_iterations) {
            return Claude::Agent::Code::Review::Report->new(
                summary => 'Review timed out: exceeded maximum iterations',
                issues  => [],
            );
        }
    }

    # Handle case where loop exits without finding a Result message
    unless (defined $result) {
        return Claude::Agent::Code::Review::Report->new(
            summary => 'Review failed - no result received from Claude',
            issues  => [],
        );
    }

    return _build_report($result, $options);
}

# Internal: Get system prompt for review
sub _get_system_prompt {
    my ($options) = @_;

    my $categories = join(', ', @{$options->categories});
    my $focus = '';
    if ($options->has_focus_areas && @{$options->focus_areas}) {
        $focus = "\n\nPay special attention to: " . join(', ', @{$options->focus_areas});
    }

    return <<"END_PROMPT";
You are an expert code reviewer. Your task is to systematically analyze code for issues.

IMPORTANT: Follow this SYSTEMATIC methodology for consistent, reproducible results:

1. ENUMERATE: First, list ALL files to be reviewed using Glob
2. FOR EACH FILE: Read the entire file, then check for issues in this EXACT order:
   a. Security issues (injection, XSS, auth, data exposure)
   b. Bugs (logic errors, null handling, race conditions, off-by-one)
   c. Performance (inefficient algorithms, unnecessary operations)
   d. Style (naming, organization) - only report if clearly problematic
   e. Maintainability (complexity, duplication)
3. VERIFY: Before reporting an issue, check the surrounding code context to avoid false positives
4. SKIP: Do not report issues about documented limitations (comments with "Note:", "TODO:", etc.)

Categories to check: $categories

Severity guidelines:
- critical: Security vulnerabilities, data loss, crashes
- high: Bugs that will cause incorrect behavior
- medium: Potential bugs, minor security issues
- low: Code quality issues
- info: Suggestions for improvement

For each issue:
- Provide exact file path and line number
- Explain the actual problem (not theoretical)
- Suggest a concrete fix
- Only report issues you are confident about$focus
END_PROMPT
}

# Internal: JSON schema for structured output
sub _get_review_schema {
    return {
        type       => 'object',
        properties => {
            summary => {
                type        => 'string',
                description => 'Brief overview of findings',
            },
            issues => {
                type  => 'array',
                items => {
                    type       => 'object',
                    properties => {
                        severity => {
                            type => 'string',
                            enum => ['critical', 'high', 'medium', 'low', 'info'],
                        },
                        category => {
                            type => 'string',
                            enum => ['bugs', 'security', 'style', 'performance', 'maintainability'],
                        },
                        file        => { type => 'string' },
                        line        => { type => 'integer' },
                        end_line    => { type => 'integer' },
                        description => { type => 'string' },
                        explanation => { type => 'string' },
                        suggestion  => { type => 'string' },
                        code_before => { type => 'string' },
                        code_after  => { type => 'string' },
                    },
                    required => ['severity', 'category', 'file', 'line', 'description'],
                },
            },
            metrics => {
                type       => 'object',
                properties => {
                    files_reviewed     => { type => 'integer' },
                    lines_reviewed     => { type => 'integer' },
                    issues_by_severity => { type => 'object' },
                    issues_by_category => { type => 'object' },
                },
            },
        },
        required => ['summary', 'issues'],
    };
}

# Internal: Build report from result
sub _build_report {
    my ($result, $options) = @_;

    unless ($result) {
        return Claude::Agent::Code::Review::Report->new(
            summary => 'Review failed - no result returned',
            issues  => [],
        );
    }

    my $data;
    if ($result->has_structured_output) {
        $data = $result->structured_output;
    }
    else {
        # Try to parse from text result
        my $text = $result->result // '';
        if ($text eq '') {
            return Claude::Agent::Code::Review::Report->new(
                summary => 'Review returned empty response',
                issues  => [],
            );
        }
        my $parse_error;
        eval { $data = decode_json($text); 1 } or $parse_error = $@;
        if ($parse_error) {
            # Include truncated response snippet to help debugging
            my $snippet = length($text) > 100 ? substr($text, 0, 100) . '...' : $text;
            # Sanitize: remove potential sensitive data patterns
            $snippet =~ s/api[_-]?key[^\s]*/[REDACTED]/gi;
            $snippet =~ s/password[^\s]*/[REDACTED]/gi;
            $snippet =~ s/token[^\s]*/[REDACTED]/gi;
            return Claude::Agent::Code::Review::Report->new(
                summary => "Failed to parse review output as JSON. Response started with: $snippet",
                issues  => [],
            );
        }
    }

    # Build Issue objects, tracking any failures separately for debugging
    my @issues;
    my $missing_fields_count = 0;  # Issues missing required fields
    my $invalid_values_count = 0;  # Issues with invalid field values
    my $issues_data = $data->{issues};

    # Validate issues is an arrayref
    if (defined $issues_data && ref($issues_data) ne 'ARRAY') {
        return Claude::Agent::Code::Review::Report->new(
            summary => 'Invalid review output: issues must be an array',
            issues  => [],
        );
    }

    for my $issue_data (@{$issues_data // []}) {
        # Skip non-hashref entries
        next unless ref($issue_data) eq 'HASH';
        # Validate required fields exist
        my @missing = grep { !defined $issue_data->{$_} } qw(severity category file line description);
        if (@missing) {
            $missing_fields_count++;
            next;
        }

        # Filter by severity if needed
        next if $options->severity && !_meets_severity($issue_data->{severity}, $options->severity);

        my $issue = eval {
            Claude::Agent::Code::Review::Issue->new(
                severity    => $issue_data->{severity},
                category    => $issue_data->{category},
                file        => $issue_data->{file},
                line        => $issue_data->{line},
                end_line    => $issue_data->{end_line},
                description => $issue_data->{description},
                explanation => $issue_data->{explanation},
                suggestion  => $issue_data->{suggestion},
                code_before => $issue_data->{code_before},
                code_after  => $issue_data->{code_after},
            );
        };
        # Track failures from exception or constructor returning undef (invalid values)
        if (!$issue) {
            $invalid_values_count++;
        } else {
            push @issues, $issue;
        }
    }

    # Apply max_issues limit
    if ($options->has_max_issues && $options->max_issues > 0 && @issues > $options->max_issues) {
        splice(@issues, $options->max_issues);
    }

    # Include failure counts in metrics for debugging
    my $metrics = $data->{metrics} // {};
    if ($missing_fields_count > 0) {
        $metrics->{issues_missing_fields} = $missing_fields_count;
    }
    if ($invalid_values_count > 0) {
        $metrics->{issues_invalid_values} = $invalid_values_count;
    }

    # Generate clean, deterministic summary from actual issues
    # This replaces the AI-generated summary which can be inconsistent
    my $summary = Claude::Agent::Code::Review::Report->generate_summary(\@issues);

    return Claude::Agent::Code::Review::Report->new(
        summary => $summary,
        issues  => \@issues,
        metrics => $metrics,
    );
}

# Internal: Run git diff --cached asynchronously using IO::Async::Process
# Returns Future that resolves to hashref with 'diff' on success, 'error' on failure
async sub _run_git_diff_cached_async {
    my ($loop) = @_;

    my $stdout = '';
    my $stderr = '';
    my $finish_future = $loop->new_future;

    my $process = IO::Async::Process->new(
        command => ['git', 'diff', '--cached'],
        stdout  => { into => \$stdout },
        stderr  => { into => \$stderr },
        on_finish => sub {
            my ($proc, $exitcode) = @_;
            $finish_future->done($exitcode);
        },
        on_exception => sub {
            my ($proc, $exception, $errno) = @_;
            $finish_future->fail("Process exception: $exception");
        },
    );

    $loop->add($process);

    # Wait for process to complete
    my $exitcode;
    eval {
        $exitcode = await $finish_future;
    };
    if ($@) {
        return { error => "Failed to run git diff: $@" };
    }

    # Check exit status (raw waitpid status from IO::Async, needs >> 8 for exit code)
    if ($exitcode != 0) {
        my $exit_code = $exitcode >> 8;
        return { error => "Git command failed (exit code $exit_code): $stderr" };
    }

    return { diff => $stdout };
}

# Internal: Detect if content is a diff (git, unified, or svn format)
# Returns true only for content that is clearly diff-formatted
sub _is_diff_content {
    my ($content) = @_;
    return 0 unless defined $content && length($content) > 10;

    # Git diff: starts with "diff --git a/path b/path"
    return 1 if $content =~ /\Adiff --git\s+\S+\s+\S+/;

    # Standard diff command: starts with "diff -" followed by options
    return 1 if $content =~ /\Adiff\s+-[a-zA-Z]/;

    # SVN diff: starts with "Index: path"
    return 1 if $content =~ /\AIndex:\s+\S+/;

    # Unified diff format: requires all three markers in proper sequence
    # Must have --- line, +++ line, and @@ hunk header
    # The --- and +++ must use a/ b/ prefix (git style) or have timestamps
    if ($content =~ /^---\s+(?:[ab]\/\S+|\S+\t)/m &&
        $content =~ /^\+\+\+\s+(?:[ab]\/\S+|\S+\t)/m &&
        $content =~ /^@@\s+-\d+(?:,\d+)?\s+\+\d+(?:,\d+)?\s+@@/m) {
        # Additional validation: --- must appear before +++ in the content
        my ($dash_pos) = $content =~ /^(.*?)^---\s+/ms;
        my ($plus_pos) = $content =~ /^(.*?)^\+\+\+\s+/ms;
        return 1 if defined $dash_pos && defined $plus_pos &&
                    length($dash_pos) < length($plus_pos);
    }

    return 0;
}

# Internal: Check if severity meets minimum threshold
sub _meets_severity {
    my ($severity, $min_severity) = @_;

    my %severity_rank = (
        critical => 5,
        high     => 4,
        medium   => 3,
        low      => 2,
        info     => 1,
    );

    # Handle unknown severities gracefully - skip unknown issues, default unknown minimums
    # Note: We silently handle these cases rather than warn() because:
    # 1. This is a library used in CI/CD where STDERR noise is undesirable
    # 2. Unknown severities from AI responses are expected edge cases
    # 3. Callers can validate severity values upstream if needed
    my $sev_rank = $severity_rank{$severity};
    unless (defined $sev_rank) {
        # Unknown severity from AI - skip this issue
        return 0;
    }

    my $min_rank = $severity_rank{$min_severity};
    unless (defined $min_rank) {
        # Unknown minimum severity - default to 'info' (show everything)
        $min_rank = 1;
    }

    return $sev_rank >= $min_rank;
}

=head1 SEE ALSO

=over 4

=item * L<Claude::Agent> - Main SDK module

=item * L<Claude::Agent::Code::Review::Options> - Review configuration

=item * L<Claude::Agent::Code::Review::Report> - Review report object

=item * L<Claude::Agent::Code::Review::Issue> - Individual issue object

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
