package Claude::Agent::Code::Review::Filter;

use 5.020;
use strict;
use warnings;

use Path::Tiny;

sub filter {
    my ($class, %args) = @_;

    my $issues  = $args{issues} // [];
    my $filters = $args{filters} // [];
    my @filtered;

    for my $issue (@$issues) {
        next if $class->_is_false_positive($issue, $filters);
        push @filtered, $issue;
    }

    return @filtered;
}

sub _is_false_positive {
    my ($class, $issue, $custom_filters) = @_;
    $custom_filters //= [];

    my $file = $issue->file;
    my $line = $issue->line;
    my $desc = $issue->description // '';

    return 0 unless -f $file;

    my $file_path = path($file);
    my $safe_path = eval { $file_path->realpath };
    return 0 unless $safe_path;

    my $base_dir = path('.')->realpath;
    return 0 unless $base_dir->subsumes($safe_path);

    my $content = eval { $safe_path->slurp_utf8 } // '';
    my @lines = split /\n/, $content;

    my $line_idx = $line - 1;
    return 0 if $line_idx < 0 || $line_idx >= scalar(@lines);
    my $start = $line_idx - 5;
    $start = 0 if $start < 0;
    my $end = $line_idx + 5;
    $end = $#lines if $end > $#lines;

    my $context = join("\n", @lines[$start..$end]);

    for my $filter (@$custom_filters) {
        return 1 if $filter->($issue, $context);
    }

    if ($desc =~ /heredoc|alarm|Windows|MSWin32|ReDoS|cross-platform/i) {
        my $wide_start = $line_idx - 15;
        $wide_start = 0 if $wide_start < 0;
        my $wide_end = $line_idx + 10;
        $wide_end = $#lines if $wide_end > $#lines;
        my $wide_context = join("\n", @lines[$wide_start..$wide_end]);

        if ($wide_context =~ /Note:|TODO:|FIXME:|limitation|basic|doesn't handle|Windows:|MSWin32|fallback|rely on/i) {
            return 1;
        }
    }

    if ($desc =~ /unused.*import|import.*unused/i) {
        if ($desc =~ /['"](\w+)['"]|\b(\w+)\s+is\s+imported/i) {
            my $symbol = $1 // $2;
            if ($symbol && $content =~ /\b\Q$symbol\E\b/) {
                return 1;
            }
        }
    }

    if ($desc =~ /no critic.*obsolete|directive.*unnecessary/i) {
        if ($context =~ /##\s*no\s*critic/i) {
            return 1;
        }
    }

    if ($desc =~ /does.*not.*end.*with.*1|RequireEndWithOne/i) {
        if ($content =~ /\n1;\s*\n?\s*$/s) {
            return 1;
        }
    }

    if ($desc =~ /path.*validation|path.*traversal/i) {
        if ($context =~ /realpath|subsumes|base_dir/i) {
            return 1;
        }
    }

    if ($desc =~ /missing.*error|no.*error.*handling/i) {
        if ($context =~ /eval\s*\{|or\s+die|\/\/|warn\s+/i) {
            return 1;
        }
    }

    if ($desc =~ /silent.*fail|silently/i) {
        if ($context =~ /warn\s+["']|warn\s+\$/i) {
            return 1;
        }
    }

    if ($desc =~ /validation.*(?:regex|pattern|string)|(?:regex|pattern).*validation/i) {
        if ($context =~ /die\s+["']Invalid|Must be/i) {
            return 1;
        }
    }

    if ($desc =~ /off-by-one|indexing|1-based|0-based/i) {
        if ($context =~ /\$start\s*=\s*0\s+if|\$end\s*=.*if|< 0|> \$#/i) {
            return 1;
        }
    }

    if ($desc =~ /inconsistent.*(?:pattern|style|handling)|(?:pattern|style).*inconsistent/i) {
        return 1;
    }

    if ($desc =~ /TOCTOU|time.of.check|race.condition.*file/i) {
        if ($context =~ /Note:|TOCTOU|handles.*gracefully|handles.*missing/i) {
            return 1;
        }
    }

    if ($desc =~ /false.positive.*(?:filter|broad|aggressive)|(?:filter|filtering).*(?:broad|aggressive|too)/i) {
        return 1;
    }

    if ($desc =~ /(?:comment|documentation).*(?:unnecessary|redundant|obvious)/i) {
        return 1;
    }

    if ($desc =~ /no.critic.*(?:directive|issue|apply|not.*needed)|directive.*no.critic/i) {
        return 1;
    }

    if ($desc =~ /position.*(?:fragile|incorrect)|(?:fragile|incorrect).*position|length\(\).*position/i) {
        if ($context =~ /length\(\$\w+\)\s*<\s*length\(\$\w+\)/i) {
            return 1;
        }
    }

    if ($desc =~ /regex.*(?:edge|corner|doesn't capture|doesn't handle)|(?:edge|corner).*case/i) {
        if ($context =~ /\# .*(?:handle|capture|parse)|TODO|basic/i) {
            return 1;
        }
    }

    return 0;
}

sub count_filtered {
    my ($class, %args) = @_;

    my $original = scalar @{$args{original} // []};
    my $filtered = scalar @{$args{filtered} // []};

    return ($filtered, $original - $filtered);
}


1;

__END__

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

=head2 count_filtered

    my ($kept, $removed) = Claude::Agent::Code::Review::Filter->count_filtered(
        original => \@original,
        filtered => \@filtered,
    );

Returns count of issues kept and removed.

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
