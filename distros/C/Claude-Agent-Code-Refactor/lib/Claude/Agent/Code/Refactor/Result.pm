package Claude::Agent::Code::Refactor::Result;

use 5.020;
use strict;
use warnings;

use Types::Common -types;

use Marlin
    'success'         => sub { 0 },
    'iterations'      => sub { 0 },
    'initial_issues'  => sub { 0 },
    'final_issues'    => sub { 0 },
    'fixes_applied'   => sub { 0 },
    'files_modified'  => sub { [] },
    'history'         => sub { [] },
    'final_report'    => sub { undef },
    'duration_ms'     => sub { 0 },
    'error'           => sub { undef };

=head1 NAME

Claude::Agent::Code::Refactor::Result - Result of a refactoring operation

=head1 SYNOPSIS

    my $result = Claude::Agent::Code::Refactor::Result->new(
        success         => 1,
        iterations      => 3,
        initial_issues  => 15,
        final_issues    => 0,
        fixes_applied   => 15,
        files_modified  => ['lib/Foo.pm', 'lib/Bar.pm'],
        history         => [...],
        duration_ms     => 45000,
    );

    if ($result->is_clean) {
        print "All issues resolved!\n";
    }

=head1 DESCRIPTION

Represents the result of a refactoring operation, including success status,
iteration history, and statistics.

=head2 ATTRIBUTES

=over 4

=item * success - True if all issues were resolved

=item * iterations - Number of review-fix cycles completed

=item * initial_issues - Number of issues found in first review

=item * final_issues - Number of issues remaining after refactoring

=item * fixes_applied - Total number of fixes applied

=item * files_modified - ArrayRef of files that were modified

=item * history - ArrayRef of per-iteration details

=item * final_report - The last Code::Review report object

=item * duration_ms - Total duration in milliseconds

=item * error - Error message if refactoring failed

=back

=head1 METHODS

=head2 is_clean

Returns true if no issues remain after refactoring.

=cut

sub is_clean {
    my ($self) = @_;
    return $self->success && $self->final_issues == 0;
}

=head2 has_error

Returns true if an error occurred during refactoring.

=cut

sub has_error {
    my ($self) = @_;
    return defined $self->error && length $self->error;
}

=head2 issues_fixed

Returns the number of issues that were fixed.

=cut

sub issues_fixed {
    my ($self) = @_;
    my $fixed = $self->initial_issues - $self->final_issues;
    return $fixed > 0 ? $fixed : 0;
}

=head2 fix_rate

Returns the percentage of issues that were fixed (0-100).

=cut

sub fix_rate {
    my ($self) = @_;
    return 100 if $self->initial_issues == 0;
    return int(($self->issues_fixed / $self->initial_issues) * 100);
}

=head2 add_iteration

Adds an iteration record to the history.

    $result->add_iteration(
        issues_found => 5,
        issues_fixed => 3,
        files_modified => ['lib/Foo.pm'],
    );

=cut

sub add_iteration {
    my ($self, %args) = @_;

    my $iteration = scalar(@{$self->history}) + 1;

    push @{$self->history}, {
        iteration      => $iteration,
        issues_found   => $args{issues_found} // 0,
        issues_fixed   => $args{issues_fixed} // 0,
        files_modified => $args{files_modified} // [],
    };

    # Update totals
    $self->{fixes_applied} += $args{issues_fixed} // 0;
    $self->{iterations} = $iteration;

    # Track unique files modified
    my %seen = map { $_ => 1 } @{$self->files_modified};
    for my $file (@{$args{files_modified} // []}) {
        push @{$self->files_modified}, $file unless $seen{$file}++;
    }

    return;
}

=head2 as_text

Returns a human-readable summary of the result.

=cut

sub as_text {
    my ($self) = @_;

    my @lines;

    push @lines, "=" x 60;
    push @lines, "REFACTOR RESULT";
    push @lines, "=" x 60;
    push @lines, "";

    if ($self->has_error) {
        push @lines, "Status: FAILED";
        push @lines, "Error: " . $self->error;
    }
    elsif ($self->is_clean) {
        push @lines, "Status: SUCCESS - All issues resolved";
    }
    else {
        push @lines, "Status: INCOMPLETE - Some issues remain";
    }

    push @lines, "";
    push @lines, "Iterations: " . $self->iterations;
    push @lines, "Initial issues: " . $self->initial_issues;
    push @lines, "Final issues: " . $self->final_issues;
    push @lines, "Fixes applied: " . $self->fixes_applied;
    push @lines, "Fix rate: " . $self->fix_rate . "%";
    push @lines, "Duration: " . sprintf("%.1f", $self->duration_ms / 1000) . "s";
    push @lines, "";

    if (@{$self->files_modified}) {
        push @lines, "Files modified:";
        for my $file (@{$self->files_modified}) {
            push @lines, "  - $file";
        }
        push @lines, "";
    }

    if (@{$self->history}) {
        push @lines, "History:";
        for my $iter (@{$self->history}) {
            push @lines, sprintf("  Iteration %d: found %d, fixed %d",
                $iter->{iteration},
                $iter->{issues_found},
                $iter->{issues_fixed},
            );
        }
    }

    push @lines, "";
    push @lines, "=" x 60;

    return join("\n", @lines) . "\n";
}

=head2 to_hash

Returns a hashref representation of the result.

=cut

sub to_hash {
    my ($self) = @_;

    return {
        success        => $self->success ? 1 : 0,
        iterations     => $self->iterations,
        initial_issues => $self->initial_issues,
        final_issues   => $self->final_issues,
        fixes_applied  => $self->fixes_applied,
        fix_rate       => $self->fix_rate,
        files_modified => $self->files_modified,
        history        => $self->history,
        duration_ms    => $self->duration_ms,
        ($self->has_error ? (error => $self->error) : ()),
    };
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
