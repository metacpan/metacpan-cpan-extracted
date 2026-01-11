package Claude::Agent::Code::Review::Options;

use 5.020;
use strict;
use warnings;

use Types::Common -types;

# Valid values for validation (do not modify)
my @VALID_SEVERITIES = qw(critical high medium low info);
my @VALID_CATEGORIES = qw(bugs security style performance maintainability);

# Marlin is a lightweight OO module that creates accessors from the declarations below.
# Each key becomes an accessor method, with the sub providing the default value.
use Marlin
    'categories'      => sub { ['bugs', 'security', 'style', 'performance', 'maintainability'] },
    'severity'        => sub { 'low' },
    'max_issues'      => sub { 0 },
    'output_format'   => sub { 'structured' },
    'include_suggestions' => sub { 1 },
    'include_code_context' => sub { 1 },
    'language'        => sub { undef },
    'ignore_patterns' => sub { [] },
    'focus_areas'     => sub { [] },
    'model'           => sub { undef },
    # Default to 'default' for safe operation with permission prompts.
    # Set to 'bypassPermissions' for automated/CI usage without prompts.
    'permission_mode' => sub { 'default' },
    # Perl::Critic integration for deterministic static analysis
    # Set to 1 to enable with default settings (severity 4, no profile)
    # Set to hashref for custom config: { severity => 1-5, profile => '/path/to/.perlcriticrc' }
    # Set to 0/undef to disable (default)
    'perlcritic'      => sub { undef },
    # Perlcritic severity level (1=brutal, 2=cruel, 3=harsh, 4=stern, 5=gentle)
    'perlcritic_severity' => sub { 4 },
    # Path to custom .perlcriticrc profile
    'perlcritic_profile'  => sub { undef },
    # Filter false positives from AI review (default: enabled)
    # Checks actual code context to remove likely false positives
    'filter_false_positives' => sub { 1 },
    # Custom filter functions for extending false positive detection
    # ArrayRef of coderefs: sub { my ($issue, $context) = @_; return 1 to filter, 0 to keep }
    'custom_filters' => sub { [] };

# Marlin calls BUILD after object construction for validation
sub BUILD {
    my ($self) = @_;

    # Validate severity
    if (defined $self->severity) {
        my $sev = $self->severity;
        unless (grep { $_ eq $sev } @VALID_SEVERITIES) {
            die "Invalid severity '$sev'. Must be one of: " . join(', ', @VALID_SEVERITIES);
        }
    }

    # Validate categories
    if (defined $self->categories) {
        unless (ref $self->categories eq 'ARRAY') {
            die "Categories must be an array reference";
        }
        # Reject empty categories array - at least one category must be specified
        unless (@{$self->categories}) {
            die "Categories cannot be empty. Must specify at least one of: " . join(', ', @VALID_CATEGORIES);
        }
        my %seen;
        for my $cat (@{$self->categories}) {
            unless (grep { $_ eq $cat } @VALID_CATEGORIES) {
                die "Invalid category '$cat'. Must be one of: " . join(', ', @VALID_CATEGORIES);
            }
            die "Duplicate category '$cat'" if $seen{$cat}++;
        }
    }

    # Validate max_issues
    if (defined $self->max_issues && $self->max_issues < 0) {
        die "max_issues must be >= 0";
    }

    # Validate output_format
    if (defined $self->output_format) {
        unless ($self->output_format =~ /^(structured|text)$/) {
            die "Invalid output_format. Must be 'structured' or 'text'";
        }
    }

    # Validate perlcritic_severity (1-5)
    if (defined $self->perlcritic_severity) {
        my $sev = $self->perlcritic_severity;
        unless ($sev =~ /^[1-5]$/) {
            die "Invalid perlcritic_severity '$sev'. Must be 1-5 (1=brutal, 5=gentle)";
        }
    }
}

=head1 NAME

Claude::Agent::Code::Review::Options - Configuration options for code review

=head1 SYNOPSIS

    use Claude::Agent::Code::Review::Options;

    my $options = Claude::Agent::Code::Review::Options->new(
        categories => ['bugs', 'security'],
        severity   => 'medium',
        max_issues => 50,
    );

=head1 DESCRIPTION

Configuration object for Claude::Agent::Code::Review.

=head2 ATTRIBUTES

=over 4

=item * categories - ArrayRef of categories to check (default: all)

Valid categories: bugs, security, style, performance, maintainability

=item * severity - Minimum severity to report (default: 'low')

Valid values from highest to lowest: critical, high, medium, low, info.
With default 'low', only 'info' level issues are excluded.

=item * max_issues - Maximum number of issues to return (default: 0 = unlimited)

=item * output_format - Output format: 'structured' or 'text' (default: 'structured')

=item * include_suggestions - Include fix suggestions (default: 1)

=item * include_code_context - Include surrounding code context (default: 1)

=item * language - Language hint for analysis (default: auto-detect)

=item * ignore_patterns - ArrayRef of file patterns to ignore

=item * focus_areas - ArrayRef of specific areas to focus on

=item * model - Claude model to use (default: inherited from Claude::Agent)

=item * permission_mode - Permission mode (default: 'default')

Set to 'bypassPermissions' for automated/CI usage without interactive prompts.

=item * perlcritic - Enable Perl::Critic static analysis (default: undef/disabled)

Set to 1 to enable with default settings, or undef/0 to disable.

=item * perlcritic_severity - Perl::Critic severity level (default: 4)

Values: 1=brutal, 2=cruel, 3=harsh, 4=stern, 5=gentle

=item * perlcritic_profile - Path to custom .perlcriticrc file (default: undef)

=item * filter_false_positives - Filter likely false positives from AI review (default: 1)

When enabled, checks actual code context to remove AI-reported issues that
are likely false positives (e.g., "unused import" when import is used,
"limitation" that's already documented in comments).

=item * custom_filters - ArrayRef of custom filter coderefs (default: [])

Add your own filter functions to extend false positive detection:

    custom_filters => [
        sub {
            my ($issue, $context) = @_;
            # $issue - Claude::Agent::Code::Review::Issue object
            # $context - surrounding code (5 lines before/after)
            # Return 1 to filter (remove), 0 to keep
            return $issue->description =~ /my known false positive/i ? 1 : 0;
        },
    ],

=back

=head1 METHODS

=head2 has_focus_areas

Returns true if focus_areas is set and non-empty.

=cut

sub has_focus_areas {
    my ($self) = @_;
    return $self->focus_areas && @{$self->focus_areas} > 0;
}

=head2 has_max_issues

Returns true if max_issues is set to a positive value.

=cut

sub has_max_issues {
    my ($self) = @_;
    return defined $self->max_issues && $self->max_issues > 0;
}

=head2 has_ignore_patterns

Returns true if ignore_patterns is set and non-empty.

=cut

sub has_ignore_patterns {
    my ($self) = @_;
    return $self->ignore_patterns && @{$self->ignore_patterns} > 0;
}

=head2 has_perlcritic

Returns true if perlcritic is enabled.

=cut

sub has_perlcritic {
    my ($self) = @_;
    return defined $self->perlcritic && $self->perlcritic;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
