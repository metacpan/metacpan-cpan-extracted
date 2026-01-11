#!/usr/bin/env perl

=head1 NAME

06-perlcritic.pl - Combined AI + Perl::Critic review

=head1 SYNOPSIS

    # Combined review with default perlcritic severity (4=stern)
    perl examples/06-perlcritic.pl lib/

    # Enable debug mode
    CLAUDE_AGENT_DEBUG=1 perl examples/06-perlcritic.pl lib/

=head1 DESCRIPTION

This example combines AI-powered review with Perl::Critic static analysis
for comprehensive coverage. This gives you:

=over 4

=item * B<Deterministic results> from Perl::Critic (same every run)

=item * B<Deep analysis> from AI review (finds semantic issues)

=item * B<False positive filtering> to reduce noise

=back

The report clearly shows "NO PERLCRITIC ERRORS" when perlcritic passes,
and notes that AI issues may vary between runs.

=head1 PERLCRITIC SEVERITY LEVELS

=over 4

=item * 1 = brutal (strictest, catches everything)

=item * 2 = cruel

=item * 3 = harsh

=item * 4 = stern (default, good balance)

=item * 5 = gentle (most permissive)

=back

=head1 DEBUG MODE

Set C<CLAUDE_AGENT_DEBUG=1> to see detailed output including:

=over 4

=item * Perlcritic violations as they're found

=item * AI review tool calls and reasoning

=item * False positive filtering decisions

=back

=head1 REQUIREMENTS

Requires Perl::Critic to be installed:

    cpanm Perl::Critic

=head1 EXIT CODES

=over 4

=item * 0 - No high/critical issues

=item * 1 - High severity issues

=item * 2 - Critical issues

=back

=cut

use strict;
use warnings;
use lib 'lib', '../lib';

use Claude::Agent::Code::Review qw(review_files);
use Claude::Agent::Code::Review::Options;
use Claude::Agent::Code::Review::Perlcritic;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

# Check if perlcritic is available
unless (Claude::Agent::Code::Review::Perlcritic->is_available) {
    die "Perl::Critic is not installed. Install with: cpanm Perl::Critic\n";
}

# Perlcritic-enabled review for deterministic static analysis
# Combined with AI review for comprehensive coverage
my $options = Claude::Agent::Code::Review::Options->new(
    categories          => ['bugs', 'security', 'style'],
    severity            => 'medium',
    permission_mode     => 'bypassPermissions',
    # Enable perlcritic integration
    perlcritic          => 1,
    perlcritic_severity => 4,  # 1=brutal, 2=cruel, 3=harsh, 4=stern, 5=gentle
    # perlcritic_profile => '.perlcriticrc',  # Optional custom profile
);

my $target = $ARGV[0] // 'lib/';

print "=" x 60, "\n";
print "COMBINED REVIEW (AI + Perl::Critic)\n";
print "=" x 60, "\n";
print "Target: $target\n";
print "Perlcritic severity: ", $options->perlcritic_severity, "\n";
print "=" x 60, "\n\n";

my $report = review_files(
    paths   => [$target],
    options => $options,
    loop    => $loop,
)->get;

print $report->as_text;

# Show source breakdown if there are issues
if ($report->has_issues) {
    my $by_cat = $report->issues_by_category;
    print "\n";
    print "Issues by category:\n";
    for my $cat (sort keys %$by_cat) {
        my $count = scalar @{$by_cat->{$cat}};
        print "  $cat: $count\n";
    }
}

exit($report->has_critical_issues ? 2 : $report->has_high_issues ? 1 : 0);
