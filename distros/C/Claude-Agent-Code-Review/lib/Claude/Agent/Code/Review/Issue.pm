package Claude::Agent::Code::Review::Issue;

use 5.020;
use strict;
use warnings;

use Types::Common -types;

# Marlin attribute declarations:
#   Required attributes (marked with '!'):
#     severity, category, file, line, description
#   Optional attributes (use Maybe[Type]):
#     end_line, column, explanation, suggestion, code_before, code_after
use Marlin
    'severity!'    => Enum['critical', 'high', 'medium', 'low', 'info'],
    'category!'    => Enum['bugs', 'security', 'style', 'performance', 'maintainability'],
    'file!'        => Str,
    'line!'        => Int,
    'description!' => Str,
    'end_line'     => Maybe[Int],
    'column'       => Maybe[Int],
    'explanation'  => Maybe[Str],
    'suggestion'   => Maybe[Str],
    'code_before'  => Maybe[Str],
    'code_after'   => Maybe[Str];

=head1 NAME

Claude::Agent::Code::Review::Issue - Individual code review issue

=head1 SYNOPSIS

    my $issue = Claude::Agent::Code::Review::Issue->new(
        severity    => 'high',
        category    => 'security',
        file        => 'lib/App.pm',
        line        => 42,
        description => 'SQL injection vulnerability',
        suggestion  => 'Use parameterized queries',
    );

    printf "%s [%s] %s:%d - %s\n",
        $issue->severity,
        $issue->category,
        $issue->file,
        $issue->line,
        $issue->description;

=head1 DESCRIPTION

Represents a single issue found during code review.

=head2 ATTRIBUTES

=over 4

=item * severity (required) - Issue severity: critical, high, medium, low, info

=item * category (required) - Issue category: bugs, security, style, performance, maintainability

=item * file (required) - File path where issue was found

=item * line (required) - Line number of the issue

=item * end_line - End line for multi-line issues (optional)

=item * column - Column number (optional)

=item * description (required) - Brief description of the issue

=item * explanation - Detailed explanation of the problem (optional)

=item * suggestion - Suggested fix (optional)

=item * code_before - Original code snippet (optional)

=item * code_after - Fixed code snippet (optional)

=back

=head1 METHODS

=head2 has_end_line

Returns true if end_line is set.

=cut

sub has_end_line {
    my ($self) = @_;
    return defined $self->end_line;
}

=head2 has_column

Returns true if column is set.

=cut

sub has_column {
    my ($self) = @_;
    return defined $self->column;
}

=head2 has_explanation

Returns true if explanation is set.

=cut

sub has_explanation {
    my ($self) = @_;
    return defined $self->explanation && length $self->explanation;
}

=head2 has_suggestion

Returns true if suggestion is set.

=cut

sub has_suggestion {
    my ($self) = @_;
    return defined $self->suggestion && length $self->suggestion;
}

=head2 has_code_before

Returns true if code_before is set.

=cut

sub has_code_before {
    my ($self) = @_;
    return defined $self->code_before && length $self->code_before;
}

=head2 has_code_after

Returns true if code_after is set.

=cut

sub has_code_after {
    my ($self) = @_;
    return defined $self->code_after && length $self->code_after;
}

=head2 is_critical

Returns true if severity is critical.

=cut

sub is_critical {
    my ($self) = @_;
    return $self->severity eq 'critical';
}

=head2 is_high

Returns true if severity is high.

=cut

sub is_high {
    my ($self) = @_;
    return $self->severity eq 'high';
}

=head2 is_security

Returns true if category is security.

=cut

sub is_security {
    my ($self) = @_;
    return $self->category eq 'security';
}

=head2 location

Returns a formatted location string "file:line" or "file:line-end_line".

=cut

sub location {
    my ($self) = @_;

    if ($self->has_end_line && $self->end_line != $self->line) {
        return sprintf "%s:%d-%d", $self->file, $self->line, $self->end_line;
    }

    return sprintf "%s:%d", $self->file, $self->line;
}

=head2 to_hash

Returns a hashref representation of the issue.

=cut

sub to_hash {
    my ($self) = @_;

    return {
        severity    => $self->severity,
        category    => $self->category,
        file        => $self->file,
        line        => $self->line,
        ($self->has_end_line    ? (end_line    => $self->end_line)    : ()),
        ($self->has_column      ? (column      => $self->column)      : ()),
        description => $self->description,
        ($self->has_explanation ? (explanation => $self->explanation) : ()),
        ($self->has_suggestion  ? (suggestion  => $self->suggestion)  : ()),
        ($self->has_code_before ? (code_before => $self->code_before) : ()),
        ($self->has_code_after  ? (code_after  => $self->code_after)  : ()),
    };
}

=head2 as_text

Returns a human-readable text representation.

=cut

sub as_text {
    my ($self) = @_;

    my @lines;
    push @lines, sprintf "[%s] %s - %s", uc($self->severity), $self->category, $self->location;
    push @lines, "  " . $self->description;

    if ($self->has_explanation) {
        push @lines, "  Explanation: " . $self->explanation;
    }

    if ($self->has_suggestion) {
        push @lines, "  Suggestion: " . $self->suggestion;
    }

    if ($self->has_code_before) {
        push @lines, "  Before: " . $self->code_before;
    }

    if ($self->has_code_after) {
        push @lines, "  After:  " . $self->code_after;
    }

    return join("\n", @lines);
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
