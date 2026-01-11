package Claude::Agent::Code::Refactor::Options;

use 5.020;
use strict;
use warnings;

use Types::Common -types;

# Valid values for validation
my @VALID_SEVERITIES = qw(critical high medium low info);
my @VALID_CATEGORIES = qw(bugs security style performance maintainability);

use Marlin
    # Loop control
    'max_iterations'     => sub { 5 },
    'max_turns_per_fix'  => sub { 20 },
    'stop_on_critical'   => sub { 1 },

    # Issue filtering (passed to Code::Review)
    'min_severity'       => sub { 'low' },
    'categories'         => sub { ['bugs', 'security', 'style', 'performance', 'maintainability'] },

    # Fix behavior
    'fix_one_at_a_time'  => sub { 0 },
    'dry_run'            => sub { 0 },
    'create_backup'      => sub { 0 },

    # Review options (passed through to Code::Review)
    'perlcritic'              => sub { 0 },
    'perlcritic_severity'     => sub { 4 },
    'filter_false_positives'  => sub { 1 },

    # Claude options
    'model'              => sub { undef },
    'permission_mode'    => sub { 'acceptEdits' };

sub BUILD {
    my ($self) = @_;

    # Validate min_severity
    if (defined $self->min_severity) {
        my $sev = $self->min_severity;
        unless (grep { $_ eq $sev } @VALID_SEVERITIES) {
            my $safe_sev = $sev =~ s/[^a-zA-Z0-9_-]//gr;
            die "Invalid min_severity '$safe_sev'. Must be one of: " . join(', ', @VALID_SEVERITIES);
        }
    }

    # Validate categories
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

    # Validate max_iterations
    if (defined $self->max_iterations) {
        if ($self->max_iterations < 1) {
            die "max_iterations must be >= 1";
        }
        if ($self->max_iterations > 100) {
            die "max_iterations must be <= 100 to prevent resource exhaustion";
        }
    }

    # Validate max_turns_per_fix
    if (defined $self->max_turns_per_fix) {
        if ($self->max_turns_per_fix < 1) {
            die "max_turns_per_fix must be >= 1";
        }
        if ($self->max_turns_per_fix > 100) {
            die "max_turns_per_fix must be <= 100 to prevent resource exhaustion";
        }
    }

    # Validate perlcritic_severity (1-5)
    if (defined $self->perlcritic_severity) {
        my $sev = $self->perlcritic_severity;
        unless ($sev =~ /^[1-5]$/) {
            die "Invalid perlcritic_severity '$sev'. Must be 1-5";
        }
    }
}

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

=item * permission_mode - Permission mode (default: 'acceptEdits')

=back

=head1 METHODS

=head2 to_review_options

Returns a Claude::Agent::Code::Review::Options object configured with
the review-related settings from this object.

=cut

sub to_review_options {
    my ($self) = @_;

    require Claude::Agent::Code::Review::Options;

    # Use 'default' permission mode for review operations - review only reads files
    # and doesn't need edit permissions.
    my $review_perm_mode = 'default';

    return Claude::Agent::Code::Review::Options->new(
        severity               => $self->min_severity,
        categories             => $self->categories,
        perlcritic             => $self->perlcritic,
        perlcritic_severity    => $self->perlcritic_severity,
        filter_false_positives => $self->filter_false_positives,
        permission_mode        => $review_perm_mode,
        ($self->model ? (model => $self->model) : ()),
    );
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
