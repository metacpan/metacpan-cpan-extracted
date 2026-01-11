package Claude::Agent::Code::Review::Report;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Cpanel::JSON::XS qw(encode_json);

# Marlin creates accessors; Types::Common provides type constraints
# The '!' suffix marks required attributes; others get default values via subs
use Marlin
    'summary!' => Str,
    'issues'   => sub { [] },
    'metrics'  => Maybe[HashRef],
    # Track perlcritic separately for clear reporting
    'perlcritic_issues' => sub { [] },
    'perlcritic_enabled' => sub { 0 },
    # Track how many false positives were filtered
    'filtered_count' => sub { 0 };

=head1 NAME

Claude::Agent::Code::Review::Report - Structured code review report

=head1 SYNOPSIS

    my $report = Claude::Agent::Code::Review::Report->new(
        summary => 'Found 5 issues',
        issues  => \@issues,
        metrics => { files_reviewed => 10 },
    );

    if ($report->has_issues) {
        print $report->summary, "\n";
        for my $issue (@{$report->issues}) {
            print $issue->description, "\n";
        }
    }

    # Group by category or severity
    my $by_cat = $report->issues_by_category;
    my $by_sev = $report->issues_by_severity;

    # Output formats
    print $report->as_text;
    print $report->as_json;

=head1 DESCRIPTION

Represents a complete code review report with issues and metrics.

=head2 ATTRIBUTES

=over 4

=item * summary - Brief overview of findings

=item * issues - ArrayRef of L<Claude::Agent::Code::Review::Issue> objects

=item * metrics - HashRef of review metrics (optional)

=back

=head1 METHODS

=head2 has_issues

Returns true if there are any issues.

=cut

sub has_issues {
    my ($self) = @_;
    return @{$self->issues} > 0;
}

=head2 has_critical_issues

Returns true if there are any critical severity issues.

=cut

sub has_critical_issues {
    my ($self) = @_;
    return scalar(grep { $_->severity eq 'critical' } @{$self->issues}) > 0;
}

=head2 has_high_issues

Returns true if there are any high severity issues.

=cut

sub has_high_issues {
    my ($self) = @_;
    return scalar(grep { $_->severity eq 'high' } @{$self->issues}) > 0;
}

=head2 issue_count

Returns the total number of issues.

=cut

sub issue_count {
    my ($self) = @_;
    return scalar @{$self->issues};
}

=head2 generate_summary

Generates a clean, deterministic summary from issues.
This is preferred over AI-generated summaries which can be inconsistent.

Can be called as instance method or class method:

    my $summary = $report->generate_summary;
    my $summary = Claude::Agent::Code::Review::Report->generate_summary(\@issues);

=cut

sub generate_summary {
    my ($self_or_class, $issues_ref) = @_;

    # Handle both instance and class method calls
    my @issues;
    if (ref($self_or_class) && $self_or_class->isa(__PACKAGE__)) {
        # Instance method
        @issues = @{$self_or_class->issues};
    } else {
        # Class method with issues arrayref
        @issues = @{$issues_ref // []};
    }

    my $total = scalar @issues;
    return "No issues found." unless $total > 0;

    # Group by severity
    my %by_sev;
    for my $issue (@issues) {
        push @{$by_sev{$issue->severity} //= []}, $issue;
    }

    # Group by category
    my %by_cat;
    for my $issue (@issues) {
        push @{$by_cat{$issue->category} //= []}, $issue;
    }

    # Build severity breakdown
    my @sev_parts;
    for my $sev (qw(critical high medium low info)) {
        my $count = scalar(@{$by_sev{$sev} // []});
        push @sev_parts, "$count $sev" if $count > 0;
    }

    # Build category breakdown
    my @cat_parts;
    for my $cat (qw(security bugs performance maintainability style)) {
        my $count = scalar(@{$by_cat{$cat} // []});
        push @cat_parts, "$count $cat" if $count > 0;
    }

    my $summary = "Found $total issue" . ($total == 1 ? '' : 's');
    $summary .= ": " . join(", ", @sev_parts) if @sev_parts;
    $summary .= " (" . join(", ", @cat_parts) . ")" if @cat_parts;
    $summary .= ".";

    return $summary;
}

=head2 issues_by_category

Returns a hashref grouping issues by category.

    my $by_cat = $report->issues_by_category;
    # { bugs => [...], security => [...], ... }

=cut

sub issues_by_category {
    my ($self) = @_;

    my %by_cat;
    for my $issue (@{$self->issues}) {
        push @{$by_cat{$issue->category} //= []}, $issue;
    }

    return \%by_cat;
}

=head2 issues_by_severity

Returns a hashref grouping issues by severity.

    my $by_sev = $report->issues_by_severity;
    # { critical => [...], high => [...], ... }

=cut

sub issues_by_severity {
    my ($self) = @_;

    my %by_sev;
    for my $issue (@{$self->issues}) {
        push @{$by_sev{$issue->severity} //= []}, $issue;
    }

    return \%by_sev;
}

=head2 issues_by_file

Returns a hashref grouping issues by file.

    my $by_file = $report->issues_by_file;
    # { 'lib/Foo.pm' => [...], 'lib/Bar.pm' => [...] }

=cut

sub issues_by_file {
    my ($self) = @_;

    my %by_file;
    for my $issue (@{$self->issues}) {
        push @{$by_file{$issue->file} //= []}, $issue;
    }

    return \%by_file;
}

=head2 as_text

Returns a human-readable text representation of the report.

=cut

sub as_text {
    my ($self) = @_;

    my @lines;
    push @lines, "=" x 60;
    push @lines, "CODE REVIEW REPORT";
    push @lines, "=" x 60;
    push @lines, "";

    # Show Perl::Critic status prominently if enabled
    if ($self->perlcritic_enabled) {
        my $pc_count = scalar @{$self->perlcritic_issues};
        if ($pc_count == 0) {
            push @lines, "Perl::Critic: *** NO PERLCRITIC ERRORS ***";
        }
        else {
            push @lines, "Perl::Critic: $pc_count issue(s) found";
        }
        push @lines, "";
    }

    push @lines, "Summary: " . $self->summary;
    push @lines, "Total issues: " . $self->issue_count;
    if ($self->filtered_count > 0) {
        push @lines, "Filtered: " . $self->filtered_count . " likely false positive(s) removed";
    }
    push @lines, "";

    if ($self->has_issues) {
        # Group by severity for display
        my $by_sev = $self->issues_by_severity;

        for my $severity (qw(critical high medium low info)) {
            my $issues = $by_sev->{$severity} // [];
            next unless @$issues;

            push @lines, "-" x 40;
            push @lines, uc($severity) . " (" . scalar(@$issues) . ")";
            push @lines, "-" x 40;

            for my $issue (@$issues) {
                push @lines, "";
                push @lines, sprintf("[%s] %s:%d", $issue->category, $issue->file, $issue->line);
                push @lines, "  " . $issue->description;

                if ($issue->has_explanation) {
                    push @lines, "  Explanation: " . $issue->explanation;
                }

                if ($issue->has_suggestion) {
                    push @lines, "  Suggestion: " . $issue->suggestion;
                }

                if ($issue->has_code_before && $issue->has_code_after) {
                    push @lines, "  Before: " . $issue->code_before;
                    push @lines, "  After:  " . $issue->code_after;
                }
            }
        }
    }
    else {
        push @lines, "No issues found.";
    }

    push @lines, "";

    # Add disclaimer about AI review
    if ($self->has_issues && !$self->perlcritic_enabled) {
        push @lines, "-" x 60;
        push @lines, "Note: AI review is non-deterministic. Results may vary.";
    }
    elsif ($self->has_issues && $self->perlcritic_enabled) {
        push @lines, "-" x 60;
        push @lines, "Note: AI issues above may vary between runs.";
        push @lines, "Perl::Critic issues are deterministic and reproducible.";
    }

    push @lines, "";
    push @lines, "=" x 60;

    return join("\n", @lines) . "\n";
}

=head2 as_json

Returns a JSON representation of the report.

=cut

sub as_json {
    my ($self) = @_;

    my $data = {
        summary => $self->summary,
        issues  => [
            map {
                my $issue = $_;
                {
                    severity    => $issue->severity,
                    category    => $issue->category,
                    file        => $issue->file,
                    line        => $issue->line,
                    ($issue->has_end_line    ? (end_line    => $issue->end_line)    : ()),
                    description => $issue->description,
                    ($issue->has_explanation ? (explanation => $issue->explanation) : ()),
                    ($issue->has_suggestion  ? (suggestion  => $issue->suggestion)  : ()),
                    ($issue->has_code_before ? (code_before => $issue->code_before) : ()),
                    ($issue->has_code_after  ? (code_after  => $issue->code_after)  : ()),
                }
            } @{$self->issues}
        ],
        ($self->metrics ? (metrics => $self->metrics) : ()),
    };

    return encode_json($data);
}

=head2 to_hash

Returns a hashref representation of the report.

=cut

sub to_hash {
    my ($self) = @_;

    return {
        summary => $self->summary,
        issues  => [ map { $_->to_hash } @{$self->issues} ],
        ($self->metrics ? (metrics => $self->metrics) : ()),
    };
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
