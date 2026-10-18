package Claude::Agent::Code::Review::Options;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Code::Review::Types;

my @VALID_SEVERITIES = @Claude::Agent::Code::Review::Types::SEVERITIES;
my @VALID_CATEGORIES = @Claude::Agent::Code::Review::Types::CATEGORIES;

BEGIN {
    Object::Proto::define('Claude::Agent::Code::Review::Options',
        'categories:ArrayRef:builder(_build_categories)',
        'severity:Str:default(low)',
        'max_issues:Int:default(0)',
        'output_format:Str:default(structured)',
        'include_suggestions:Bool:default(1)',
        'include_code_context:Bool:default(1)',
        'language',
        'ignore_patterns:ArrayRef:default([])',
        'focus_areas:ArrayRef:default([])',
        'model',
        'effort:Str:predicate',
        'permission_mode:Str:default(default)',
        'perlcritic',
        'perlcritic_severity:Int:default(4)',
        'perlcritic_profile',
        'filter_false_positives:Bool:default(1)',
        'custom_filters:ArrayRef:default([])',
    );
}

sub _build_categories {
    return [@Claude::Agent::Code::Review::Types::CATEGORIES];
}

sub BUILD {
    my ($self) = @_;

    if (defined $self->severity) {
        my $sev = $self->severity;
        unless (grep { $_ eq $sev } @VALID_SEVERITIES) {
            die "Invalid severity '$sev'. Must be one of: " . join(', ', @VALID_SEVERITIES);
        }
    }

    if (defined $self->categories) {
        unless (ref $self->categories eq 'ARRAY') {
            die "Categories must be an array reference";
        }
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

    if (defined $self->max_issues && $self->max_issues < 0) {
        die "max_issues must be >= 0";
    }

    if (defined $self->output_format) {
        unless ($self->output_format =~ /^(structured|text)$/) {
            die "Invalid output_format. Must be 'structured' or 'text'";
        }
    }

    if (defined $self->perlcritic_severity) {
        my $sev = $self->perlcritic_severity;
        unless ($sev =~ /^[1-5]$/) {
            die "Invalid perlcritic_severity '$sev'. Must be 1-5 (1=brutal, 5=gentle)";
        }
    }
}

sub has_focus_areas {
    my ($self) = @_;
    return $self->focus_areas && @{$self->focus_areas} > 0;
}

sub has_max_issues {
    my ($self) = @_;
    return defined $self->max_issues && $self->max_issues > 0;
}

sub has_ignore_patterns {
    my ($self) = @_;
    return $self->ignore_patterns && @{$self->ignore_patterns} > 0;
}

sub has_perlcritic {
    my ($self) = @_;
    return defined $self->perlcritic && $self->perlcritic;
}


1;

__END__

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

=item * effort - Effort level passed to Claude::Agent: low, medium, high, xhigh or max (optional; C<has_effort> reports whether it was given)

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

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored. Dies on
an invalid severity, category, max_issues, output_format or
perlcritic_severity.

=head2 has_focus_areas

Returns true if focus_areas is set and non-empty.

=cut

=head2 has_max_issues

Returns true if max_issues is set to a positive value.

=cut

=head2 has_ignore_patterns

Returns true if ignore_patterns is set and non-empty.

=cut

=head2 has_perlcritic

Returns true if perlcritic is enabled.

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
