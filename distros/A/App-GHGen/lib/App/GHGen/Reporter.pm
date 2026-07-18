package App::GHGen::Reporter;

use v5.36;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
	generate_markdown_report
	generate_github_comment
	estimate_savings
);

our $VERSION = '0.06';

=head1 NAME

App::GHGen::Reporter - Generate reports for GitHub integration

=head1 SYNOPSIS

    use App::GHGen::Reporter qw(generate_github_comment);

    my $comment = generate_github_comment(\@issues, \@fixes);

=head1 FUNCTIONS

=head2 generate_markdown_report($issues, $fixes)

Produce a Markdown-formatted report of workflow issues and applied fixes.

=head3 Purpose

Render a structured Markdown document that summarises detected issues grouped
by category, includes suggested fixes, and appends an estimated savings
section when applicable.

=head3 Arguments

=over 4

=item C<$issues> (ArrayRef[HashRef], required)

Issues to report.  Each must have C<type>, C<severity>, C<message>; an
optional C<fix> key renders a collapsible C<E<lt>detailsE<gt>> block.

=item C<$fixes> (ArrayRef, optional, default C<[]>)

List of fixes already applied (used only for the summary count).

=back

=head3 Returns

A non-empty Markdown string beginning with C<# GHGen Workflow Analysis>.

=head3 Side Effects

None.  Pure function.

=head3 Usage Example

    my $md = generate_markdown_report(\@issues, \@fixes);
    path('report.md')->spew_utf8($md);

=head3 API SPECIFICATION

=head4 Input

    {
        issues => { type => 'arrayref', required => 1 },
        fixes  => { type => 'arrayref', default  => [] },
    }

=head4 Output

    { type => 'scalar' }   # Markdown string

=head3 FORMAL SPECIFICATION

    generate_markdown_report : seq Issue × seq Fix → ℤ*

    result begins with "# GHGen Workflow Analysis"
    |issues| > 0 ⇒ result contains "## Issues by Category"
    |issues| = 0 ⇒ result does not contain "## Issues by Category"
    |fixes|  > 0 ⇒ result contains "Fixes applied"
    savings.minutes > 0 ⇒ result contains "## 💰 Estimated Savings"

=cut

sub generate_markdown_report($issues, $fixes = []) {
	my $report = "# GHGen Workflow Analysis\n\n";

	my $total_issues = scalar @$issues;
	my $total_fixes = scalar @$fixes;

	$report .= "## Summary\n\n";
	$report .= "- 📊 **Issues found:** $total_issues\n";
	$report .= "- ✅ **Fixes applied:** $total_fixes\n\n";

    if (@$issues) {
        # Group by type
        my %by_type;
        push @{$by_type{$_->{type}}}, $_ for @$issues;

        $report .= "## Issues by Category\n\n";

        for my $type (sort keys %by_type) {
            my $count = scalar @{$by_type{$type}};
            my $emoji = get_type_emoji($type);
            $report .= "### $emoji " . ucfirst($type) . " ($count)\n\n";

            for my $issue (@{$by_type{$type}}) {
                my $severity_badge = get_severity_badge($issue->{severity});
                $report .= "**$severity_badge $issue->{message}**\n\n";

                if ($issue->{fix}) {
                    $report .= "<details>\n";
                    $report .= "<summary>💡 Suggested Fix</summary>\n\n";
                    $report .= "```yaml\n";
                    $report .= "$issue->{fix}\n";
                    $report .= "```\n\n";
                    $report .= "</details>\n\n";
                }
            }
        }
    }

    # Add savings estimate if available
    my $savings = estimate_savings($issues);
    if ($savings->{minutes} > 0) {
        $report .= "## 💰 Estimated Savings\n\n";
        $report .= "By fixing these issues, you could save:\n\n";
        $report .= "- ⏱️ **~$savings->{minutes} CI minutes/month**\n";

        if ($savings->{cost} > 0) {
            $report .= "- 💵 **~\$$savings->{cost}/month** (for private repos)\n";
        }

        $report .= "\n";
    }

    return $report;
}

=head2 generate_github_comment($issues, $fixes, $options)

Generate a GitHub Pull-Request comment summarising workflow issues.

=head3 Purpose

Produce a compact Markdown comment suitable for posting as a PR review
comment.  Includes a summary table, a collapsible detail block, a how-to-fix
section when no fixes were applied, and a potential savings estimate.

=head3 Arguments

=over 4

=item C<$issues> (ArrayRef[HashRef], required)

Issues to display.  Each must have C<type>, C<severity>, C<message>; an
optional C<file> key adds a file reference line.

=item C<$fixes> (ArrayRef, optional, default C<[]>)

Fixes already applied (used only for the applied-fix count in the header).

=item C<$options> (HashRef, optional, default C<{}>)

Reserved for future use; currently unused.

=back

=head3 Returns

A non-empty Markdown string starting with C<## 🔍 GHGen Workflow Analysis>.

When C<$issues> is empty, the comment contains the phrase
C<No issues found!> and is returned early without a table or details block.

=head3 Side Effects

None.  Pure function.

=head3 Usage Example

    my $comment = generate_github_comment(\@issues, \@fixes);
    # Post $comment via GitHub API

=head3 API SPECIFICATION

=head4 Input

    {
        issues  => { type => 'arrayref', required => 1 },
        fixes   => { type => 'arrayref', default  => [] },
        options => { type => 'hashref',  default  => {} },
    }

=head4 Output

    { type => 'scalar' }   # Markdown string

=head3 FORMAL SPECIFICATION

    generate_github_comment : seq Issue × seq Fix × Options → ℤ*

    result begins with "## 🔍 GHGen Workflow Analysis"
    |issues| = 0 ⇒ result contains "No issues found!" ∧ early return
    |fixes|  > 0 ⇒ result contains "Applied" ∧ fix count
    |issues| > 0 ∧ |fixes| = 0 ⇒ result contains "How to Fix"
    ∃ i ∈ issues: i.file defined ⇒ result contains i.file

=cut

sub generate_github_comment($issues, $fixes = [], $options = {}) {
	my $comment = "## 🔍 GHGen Workflow Analysis\n\n";

    my $total_issues = scalar @$issues;
    my $total_fixes = scalar @$fixes;

    if ($total_fixes > 0) {
        $comment .= "✅ **Applied $total_fixes automatic fix(es)**\n\n";
    }

    if ($total_issues == 0) {
        $comment .= "🎉 **No issues found!** Your workflows look great.\n\n";
        return $comment;
    }

    # Summary table
    $comment .= "| Category | Count | Auto-fixable |\n";
    $comment .= "|----------|-------|-------------|\n";

    my %by_type;
    push @{$by_type{$_->{type}}}, $_ for @$issues;

    for my $type (sort keys %by_type) {
        my $count = scalar @{$by_type{$type}};
        my $fixable = grep { $_->{auto_fixable} // 1 } @{$by_type{$type}};
        my $emoji = get_type_emoji($type);
        $comment .= "| $emoji " . ucfirst($type) . " | $count | $fixable |\n";
    }

    $comment .= "\n";

    # Detailed issues
    $comment .= "<details>\n";
    $comment .= "<summary>📋 View Details</summary>\n\n";

    for my $type (sort keys %by_type) {
        $comment .= "### " . get_type_emoji($type) . " " . ucfirst($type) . "\n\n";

        for my $issue (@{$by_type{$type}}) {
            my $badge = get_severity_badge($issue->{severity});
            $comment .= "- $badge **$issue->{message}**\n";

            if ($issue->{file}) {
                $comment .= "  - File: `$issue->{file}`\n";
            }
        }

        $comment .= "\n";
    }

    $comment .= "</details>\n\n";

    # Add recommendations
    if ($total_fixes == 0 && $total_issues > 0) {
        $comment .= "### 💡 How to Fix\n\n";
        $comment .= "Run these commands locally:\n\n";
        $comment .= "```bash\n";
        $comment .= "# Install ghgen\n";
        $comment .= "cpanm App::GHGen\n\n";
        $comment .= "# Analyze and fix\n";
        $comment .= "ghgen analyze --fix\n";
        $comment .= "```\n\n";

        $comment .= "Or enable auto-fix in this action:\n\n";
        $comment .= "```yaml\n";
        $comment .= "- uses: nigelhorne/ghgen-action\@v1\n";
        $comment .= "  with:\n";
        $comment .= "    auto-fix: true\n";
        $comment .= "    create-pr: true\n";
        $comment .= "```\n\n";
    }

    # Add savings estimate
    my $savings = estimate_savings($issues);
    if ($savings->{minutes} > 0) {
        $comment .= "### 💰 Potential Savings\n\n";
        $comment .= "By fixing these issues:\n";
        $comment .= "- ⏱️ Save **~$savings->{minutes} CI minutes/month**\n";

        if ($savings->{cost} > 0) {
            $comment .= "- 💵 Save **~\$$savings->{cost}/month** (private repos)\n";
        }

        $comment .= "\n";
    }

    $comment .= "---\n";
    $comment .= "*Analysis by [GHGen](https://github.com/your-org/ghgen)*\n";

    return $comment;
}

=head2 estimate_savings($issues)

Estimate CI-minute savings and associated cost reduction from fixing a set of issues.

=head3 Purpose

For each C<performance> (caching) or C<cost> (concurrency, triggers) issue,
add a fixed minute estimate to the running total and compute the equivalent
USD saving at the GitHub private-repo rate of $0.008/minute.

=head3 Arguments

=over 4

=item C<$issues> (ArrayRef[HashRef], required)

Issue hashes with at least C<type> and C<message>.

=back

=head3 Returns

A hash reference:

    {
        minutes => Int,   # total estimated minutes saved per month; 0 when no savings
        cost    => Int,   # floor(minutes * 0.008); 0 when no savings
    }

=head3 Side Effects

None.  Pure function.

=head3 Usage Example

    my $s = estimate_savings(\@issues);
    say "Save $s->{minutes} min/month";

=head3 API SPECIFICATION

=head4 Input

    { issues => { type => 'arrayref', required => 1 } }

=head4 Output

    {
        type => 'hashref',
        keys => {
            minutes => { type => 'scalar' },
            cost    => { type => 'scalar' },
        },
    }

=head3 FORMAL SPECIFICATION

    estimate_savings : seq Issue → { minutes: ℕ, cost: ℕ }

    RATE ≔ 0.008
    savings(i) ≔
        i.type = performance ∧ i.message =~ /caching/     → 500
        i.type = cost        ∧ i.message =~ /concurrency/ → 50
        i.type = cost        ∧ i.message =~ /triggers/    → 100
        otherwise                                          → 0

    total  ≔ ∑ { savings(i) ∣ i ∈ issues }
    result ≔ { minutes ↦ total, cost ↦ floor(total × RATE) }

=cut

sub estimate_savings($issues) {
	my %savings = (
		minutes => 0,
		cost => 0,
	);

	for my $issue (@$issues) {
	# Estimate savings by issue type
		if ($issue->{type} eq 'performance') {
			# Caching saves ~5 minutes per workflow run
			# Assume 100 runs/month
			$savings{minutes} += 500 if $issue->{message} =~ /caching/;
		} elsif ($issue->{type} eq 'cost') {
			if ($issue->{message} =~ /concurrency/) {
				# Concurrency saves ~50 minutes/month by canceling old runs
				$savings{minutes} += 50;
			}
			if ($issue->{message} =~ /triggers/) {
				# Trigger filters save ~100 minutes/month
				$savings{minutes} += 100;
			}
		}
	}

	# Private repo pricing: ~$0.008 per minute
	$savings{cost} = int($savings{minutes} * 0.008);

	return \%savings;
}

sub get_type_emoji($type) {
	my %emojis = (
		performance => '⚡',
		security => '🔒',
		cost => '💰',
		maintenance => '🔧',
	);

	return $emojis{$type} // '📌';
}

sub get_severity_badge($severity) {
	my %badges = (
		high   => '🔴',
		medium => '🟡',
		low => '🟢',
	);

	return $badges{$severity} // '⚪';
}

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

L<https://github.com/nigelhorne>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
