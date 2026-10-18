package Claude::Agent::Code::Refactor::Options;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

my @VALID_SEVERITIES = qw(critical high medium low info);
my @VALID_CATEGORIES = qw(bugs security style performance maintainability);

BEGIN {
    Object::Proto::define('Claude::Agent::Code::Refactor::Options',
        'max_iterations:Int:default(5)',
        'max_turns_per_fix:Int:default(20)',
        'stop_on_critical:Bool:default(1)',
        'min_severity:Str:default(low)',
        'categories:builder(_build_categories)',
        'fix_one_at_a_time:Bool:default(0)',
        'dry_run:Bool:default(0)',
        'create_backup:Bool:default(0)',
        'perlcritic:default(0)',
        'perlcritic_severity:Int:default(4)',
        'filter_false_positives:Bool:default(1)',
        'model',
        'effort:Str:predicate',
        'permission_mode:Str:default(acceptEdits)',
    );
}

sub _build_categories {
    return [@VALID_CATEGORIES];
}

sub BUILD {
    my ($self) = @_;

    if (defined $self->min_severity) {
        my $sev = $self->min_severity;
        unless (grep { $_ eq $sev } @VALID_SEVERITIES) {
            my $safe_sev = $sev =~ s/[^a-zA-Z0-9_-]//gr;
            die "Invalid min_severity '$safe_sev'. Must be one of: " . join(', ', @VALID_SEVERITIES);
        }
    }

    if (defined $self->categories) {
        unless (ref $self->categories eq 'ARRAY') {
            die "Categories must be an array reference";
        }
        unless (@{$self->categories}) {
            die "Categories cannot be empty";
        }
        for my $cat (@{$self->categories}) {
            unless (grep { $_ eq $cat } @VALID_CATEGORIES) {
                my $safe_cat = $cat =~ s/[^a-zA-Z0-9_-]//gr;
            die "Invalid category '$safe_cat'. Must be one of: " . join(', ', @VALID_CATEGORIES);
            }
        }
    }

    if (defined $self->max_iterations) {
        if ($self->max_iterations < 1) {
            die "max_iterations must be >= 1";
        }
        if ($self->max_iterations > 100) {
            die "max_iterations must be <= 100 to prevent resource exhaustion";
        }
    }

    if (defined $self->max_turns_per_fix) {
        if ($self->max_turns_per_fix < 1) {
            die "max_turns_per_fix must be >= 1";
        }
        if ($self->max_turns_per_fix > 100) {
            die "max_turns_per_fix must be <= 100 to prevent resource exhaustion";
        }
    }

    if (defined $self->perlcritic_severity) {
        my $sev = $self->perlcritic_severity;
        unless ($sev =~ /^[1-5]$/) {
            die "Invalid perlcritic_severity '$sev'. Must be 1-5";
        }
    }
}

sub to_review_options {
    my ($self) = @_;

    require Claude::Agent::Code::Review::Options;

    my $review_perm_mode = 'default';

    return Claude::Agent::Code::Review::Options->new(
        severity               => $self->min_severity,
        categories             => $self->categories,
        perlcritic             => $self->perlcritic,
        perlcritic_severity    => $self->perlcritic_severity,
        filter_false_positives => $self->filter_false_positives,
        permission_mode        => $review_perm_mode,
        ($self->model ? (model => $self->model) : ()),
        ($self->has_effort ? (effort => $self->effort) : ()),
    );
}


1;

__END__

=head1 NAME

Claude::Agent::Code::Refactor::Options - Configuration options for code refactoring

=head1 SYNOPSIS

    use Claude::Agent::Code::Refactor::Options;

    my $options = Claude::Agent::Code::Refactor::Options->new(
        max_iterations  => 5,
        min_severity    => 'medium',
        categories      => ['bugs', 'security'],
        permission_mode => 'acceptEdits',
    );

=head1 DESCRIPTION

Configuration object for Claude::Agent::Code::Refactor.

=head2 ATTRIBUTES

=over 4

=item * max_iterations - Maximum review-fix-review cycles (default: 5)

=item * max_turns_per_fix - Maximum Claude turns per fix attempt (default: 20)

=item * stop_on_critical - Halt if critical issue can't be fixed (default: 1)

=item * min_severity - Minimum severity to fix (default: 'low')

=item * categories - ArrayRef of categories to fix (default: all)

=item * fix_one_at_a_time - Fix issues one at a time vs all at once (default: 0)

=item * dry_run - Preview fixes without applying (default: 0)

=item * create_backup - Backup files before editing (default: 0)

=item * perlcritic - Include perlcritic in review (default: 0)

=item * perlcritic_severity - Perlcritic severity 1-5 (default: 4)

=item * filter_false_positives - Filter AI false positives (default: 1)

=item * model - Claude model to use (default: inherited)

=item * effort - Effort level passed to both the review and the fix: low, medium, high, xhigh or max (optional; C<has_effort> reports whether it was given)

=item * permission_mode - Permission mode (default: 'acceptEdits')

=back

=head1 METHODS

=head2 to_review_options

Returns a Claude::Agent::Code::Review::Options object configured with
the review-related settings from this object.

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
