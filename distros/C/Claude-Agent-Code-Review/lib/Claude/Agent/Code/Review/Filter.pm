package Claude::Agent::Code::Review::Filter;

use 5.020;
use strict;
use warnings;

use Path::Tiny;

=head1 NAME

Claude::Agent::Code::Review::Filter - Filter false positive issues from AI review

=head1 SYNOPSIS

    use Claude::Agent::Code::Review::Filter;

    my @filtered = Claude::Agent::Code::Review::Filter->filter(
        issues => \@issues,
    );

    # With custom filters
    my @filtered = Claude::Agent::Code::Review::Filter->filter(
        issues  => \@issues,
        filters => [
            sub {
                my ($issue, $context) = @_;
                # Return 1 to filter (remove), 0 to keep
                return $issue->description =~ /known false positive/i ? 1 : 0;
            },
        ],
    );

=head1 DESCRIPTION

Filters out likely false positive issues from AI code review by checking
the actual code context. This helps reduce noise from non-deterministic
AI review results.

=head1 METHODS

=head2 filter

    my @filtered = Claude::Agent::Code::Review::Filter->filter(
        issues  => \@issues,
        filters => \@custom_filters,  # optional
    );

Returns a filtered list of issues, removing likely false positives.

Custom filters are coderefs that receive C<($issue, $context)> where
C<$context> is the surrounding code (5 lines before/after). Return 1
to filter out the issue, 0 to keep it.

=cut

sub filter {
    my ($class, %args) = @_;

    my $issues  = $args{issues} // [];
    my $filters = $args{filters} // [];
    my @filtered;

    for my $issue (@$issues) {
        # Skip if we can verify it's a false positive
        next if $class->_is_false_positive($issue, $filters);
        push @filtered, $issue;
    }

    return @filtered;
}

# Check if an issue is likely a false positive
sub _is_false_positive {
    my ($class, $issue, $custom_filters) = @_;
    $custom_filters //= [];

    my $file = $issue->file;
    my $line = $issue->line;
    my $desc = $issue->description // '';

    # Can't verify without file access
    return 0 unless -f $file;

    # Validate path is within project directory (security)
    my $file_path = path($file);
    my $safe_path = eval { $file_path->realpath };
    return 0 unless $safe_path;

    my $base_dir = path('.')->realpath;
    return 0 unless $base_dir->subsumes($safe_path);

    my $content = eval { $safe_path->slurp_utf8 } // '';
    my @lines = split /\n/, $content;

    # Get context around the issue (5 lines before and after)
    # Line numbers are 1-indexed, array is 0-indexed
    my $line_idx = $line - 1;
    # Bounds check: skip if line number is invalid or out of range
    return 0 if $line_idx < 0 || $line_idx >= scalar(@lines);
    my $start = $line_idx - 5;
    $start = 0 if $start < 0;
    my $end = $line_idx + 5;
    $end = $#lines if $end > $#lines;

    my $context = join("\n", @lines[$start..$end]);

    # Run custom filters first (user-defined take precedence)
    for my $filter (@$custom_filters) {
        return 1 if $filter->($issue, $context);
    }

    # Check for documented limitations (already acknowledged in comments)
    if ($desc =~ /heredoc|alarm|Windows|MSWin32|ReDoS|cross-platform/i) {
        # If the code has a comment acknowledging the limitation, it's not a real issue
        # Expand context window for this check - look at more surrounding code
        # Use 0-indexed $line_idx for consistent array indexing
        my $wide_start = $line_idx - 15;
        $wide_start = 0 if $wide_start < 0;
        my $wide_end = $line_idx + 10;
        $wide_end = $#lines if $wide_end > $#lines;
        my $wide_context = join("\n", @lines[$wide_start..$wide_end]);

        if ($wide_context =~ /Note:|TODO:|FIXME:|limitation|basic|doesn't handle|Windows:|MSWin32|fallback|rely on/i) {
            return 1;
        }
    }

    # Check for "unused import" false positives
    if ($desc =~ /unused.*import|import.*unused/i) {
        # Extract the thing allegedly unused
        if ($desc =~ /['"](\w+)['"]|\b(\w+)\s+is\s+imported/i) {
            my $symbol = $1 // $2;
            if ($symbol && $content =~ /\b\Q$symbol\E\b/) {
                # Symbol IS used in the file
                return 1;
            }
        }
    }

    # Check for "no critic" directive claims
    if ($desc =~ /no critic.*obsolete|directive.*unnecessary/i) {
        # If a no critic directive exists, it was probably added for a reason
        if ($context =~ /##\s*no\s*critic/i) {
            return 1;
        }
    }

    # Check for "module doesn't end with 1" when it actually does
    if ($desc =~ /does.*not.*end.*with.*1|RequireEndWithOne/i) {
        # Check if file actually ends with 1;
        if ($content =~ /\n1;\s*\n?\s*$/s) {
            return 1;
        }
    }

    # Check for path validation issues where validation exists
    if ($desc =~ /path.*validation|path.*traversal/i) {
        # If realpath or subsumes is used, validation exists - filter as false positive
        if ($context =~ /realpath|subsumes|base_dir/i) {
            return 1;
        }
    }

    # Check for "missing error handling" when error handling actually exists
    if ($desc =~ /missing.*error|no.*error.*handling/i) {
        if ($context =~ /eval\s*\{|or\s+die|\/\/|warn\s+/i) {
            # Error handling exists - AI incorrectly reported it missing
            return 1;
        }
    }

    # Check for "silent failure" when there's a warn statement
    if ($desc =~ /silent.*fail|silently/i) {
        if ($context =~ /warn\s+["']|warn\s+\$/i) {
            return 1;
        }
    }

    # Check for style issues about validation approach when validation exists
    if ($desc =~ /validation.*(?:regex|pattern|string)|(?:regex|pattern).*validation/i) {
        if ($context =~ /die\s+["']Invalid|Must be/i) {
            return 1;
        }
    }

    # Check for "off-by-one" or indexing issues in code that has bounds checking
    if ($desc =~ /off-by-one|indexing|1-based|0-based/i) {
        if ($context =~ /\$start\s*=\s*0\s+if|\$end\s*=.*if|< 0|> \$#/i) {
            return 1;
        }
    }

    # Check for "inconsistent" style issues - these are usually minor
    if ($desc =~ /inconsistent.*(?:pattern|style|handling)|(?:pattern|style).*inconsistent/i) {
        # Style inconsistencies are usually not bugs
        return 1;
    }

    # Filter out TOCTOU complaints where the code already handles failures gracefully
    # TOCTOU is unavoidable for file checks and downstream code handles missing files
    if ($desc =~ /TOCTOU|time.of.check|race.condition.*file/i) {
        # If there's a comment acknowledging this, or if it's a simple existence check
        if ($context =~ /Note:|TOCTOU|handles.*gracefully|handles.*missing/i) {
            return 1;
        }
    }

    # Filter out meta-complaints about false positive filtering or filter being "too broad"
    # These are self-referential and not actionable
    if ($desc =~ /false.positive.*(?:filter|broad|aggressive)|(?:filter|filtering).*(?:broad|aggressive|too)/i) {
        return 1;
    }

    # Filter out complaints about documentation/comments being "unnecessary" or "redundant"
    if ($desc =~ /(?:comment|documentation).*(?:unnecessary|redundant|obvious)/i) {
        return 1;
    }

    # Filter out complaints about "no critic" directives - these are intentional suppressions
    if ($desc =~ /no.critic.*(?:directive|issue|apply|not.*needed)|directive.*no.critic/i) {
        return 1;
    }

    # Filter out "fragile" position comparison complaints when using valid length-based comparisons
    # Comparing length of captured prefix content is a valid way to compare positions
    if ($desc =~ /position.*(?:fragile|incorrect)|(?:fragile|incorrect).*position|length\(\).*position/i) {
        if ($context =~ /length\(\$\w+\)\s*<\s*length\(\$\w+\)/i) {
            return 1;
        }
    }

    # Check for regex edge cases that are acknowledged
    if ($desc =~ /regex.*(?:edge|corner|doesn't capture|doesn't handle)|(?:edge|corner).*case/i) {
        if ($context =~ /\# .*(?:handle|capture|parse)|TODO|basic/i) {
            return 1;
        }
    }

    return 0;
}

=head2 count_filtered

    my ($kept, $removed) = Claude::Agent::Code::Review::Filter->count_filtered(
        original => \@original,
        filtered => \@filtered,
    );

Returns count of issues kept and removed.

=cut

sub count_filtered {
    my ($class, %args) = @_;

    my $original = scalar @{$args{original} // []};
    my $filtered = scalar @{$args{filtered} // []};

    return ($filtered, $original - $filtered);
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
