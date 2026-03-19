package Data::Hash::Diff::Smart::Engine;

use strict;
use warnings;

use Scalar::Util qw(reftype blessed refaddr);
use Data::Hash::Diff::Smart::Path ();

=pod

=head1 NAME

Data::Hash::Diff::Smart::Engine - Internal diff engine for Data::Hash::Diff::Smart

=head1 DESCRIPTION

This module implements the recursive diff algorithm used by
L<Data::Hash::Diff::Smart>. It is not intended to be used directly.

Features include:

=over 4

=item * recursive comparison of scalars, hashes, arrays, and objects

=item * cycle detection to avoid infinite recursion

=item * ignore rules (exact, regex, wildcard)

=item * custom comparators per path

=item * array diff modes: index, LCS, unordered

=back

=head1 INTERNAL METHODS

=head2 diff($old, $new, %opts)

Entry point for computing a diff.

=head2 _diff($old, $new, $path, $changes, $ctx)

Recursive comparison routine.

=head2 _diff_scalar, _diff_hash, _diff_array

Type-specific comparison helpers.

=head2 _diff_array_index, _diff_array_lcs, _diff_array_unordered

Array diffing strategies.

=head2 _normalize_ignore, _is_ignored

Ignore rule processing.

=head2 _reftype, _eq

Utility helpers.

=cut

# -------------------------------------------------------------------------
# Public entry point
# -------------------------------------------------------------------------

sub diff {
    my ($old, $new, %opts) = @_;

    my $changes = [];

    my $ctx = {
        ignore      => _normalize_ignore($opts{ignore}),
        compare     => $opts{compare} || {},
        array_mode  => $opts{array_mode} || 'index',
    };

    _diff($old, $new, '', $changes, $ctx);

    return $changes;
}

# -------------------------------------------------------------------------
# Core recursive diff
# -------------------------------------------------------------------------

sub _diff {
    my ($old, $new, $path, $changes, $ctx) = @_;

    # Ignore rules
    return if _is_ignored($path, $ctx->{ignore});

    # ------------------------------------------------------------------
    # Cycle detection
    # ------------------------------------------------------------------
    if (ref($old) && ref($new)) {
        my $ro = refaddr($old);
        my $rn = refaddr($new);

        # If we've seen this pair before, stop recursion
        if ($ctx->{seen}{$ro}{$rn}++) {
            return;
        }
    }

    my $rt_old = _reftype($old);
    my $rt_new = _reftype($new);

    # ------------------------------------------------------------------
    # Both scalars
    # ------------------------------------------------------------------
    if (!$rt_old && !$rt_new) {
        return _diff_scalar($old, $new, $path, $changes, $ctx);
    }

    # ------------------------------------------------------------------
    # Type mismatch
    # ------------------------------------------------------------------
    if ($rt_old && $rt_new && $rt_old ne $rt_new) {
        push @$changes, {
            op   => 'change',
            path => $path,
            from => $old,
            to   => $new,
        };
        return;
    }

    # ------------------------------------------------------------------
    # One ref, one scalar
    # ------------------------------------------------------------------
    if ($rt_old && !$rt_new) {
        push @$changes, {
            op   => 'change',
            path => $path,
            from => $old,
            to   => $new,
        };
        return;
    }

    if (!$rt_old && $rt_new) {
        push @$changes, {
            op   => 'change',
            path => $path,
            from => $old,
            to   => $new,
        };
        return;
    }

    # ------------------------------------------------------------------
    # Both refs, same type
    # ------------------------------------------------------------------
    if ($rt_old eq 'HASH') {
        return _diff_hash($old, $new, $path, $changes, $ctx);
    }

    if ($rt_old eq 'ARRAY') {
        return _diff_array($old, $new, $path, $changes, $ctx);
    }

    # ------------------------------------------------------------------
    # Fallback: stringify
    # ------------------------------------------------------------------
    return _diff_scalar("$old", "$new", $path, $changes, $ctx);
}

# -------------------------------------------------------------------------
# Scalar comparison
# -------------------------------------------------------------------------

sub _diff_scalar {
    my ($old, $new, $path, $changes, $ctx) = @_;

    # Custom comparator?
    if (my $cmp = $ctx->{compare}{$path}) {
        my $same = eval { $cmp->($old, $new) };
        if ($@) {
            push @$changes, {
                op    => 'change',
                path  => $path,
                from  => $old,
                to    => $new,
                error => "$@",
            };
            return;
        }
        return if $same;
    }
    else {
        return if _eq($old, $new);
    }

    push @$changes, {
        op   => 'change',
        path => $path,
        from => $old,
        to   => $new,
    };
}

# -------------------------------------------------------------------------
# Hash comparison
# -------------------------------------------------------------------------

sub _diff_hash {
    my ($old, $new, $path, $changes, $ctx) = @_;

    my %keys;
    $keys{$_}++ for keys %$old;
    $keys{$_}++ for keys %$new;

    for my $k (sort keys %keys) {
        my $subpath = Data::Hash::Diff::Smart::Path::join($path, $k);

        if (exists $old->{$k} && exists $new->{$k}) {
            _diff($old->{$k}, $new->{$k}, $subpath, $changes, $ctx);
        }
        elsif (exists $old->{$k}) {
            push @$changes, {
                op   => 'remove',
                path => $subpath,
                from => $old->{$k},
            };
        }
        else {
            push @$changes, {
                op    => 'add',
                path  => $subpath,
                value => $new->{$k},
            };
        }
    }
}

# -------------------------------------------------------------------------
# Array comparison dispatcher
# -------------------------------------------------------------------------

sub _diff_array {
    my ($old, $new, $path, $changes, $ctx) = @_;

    my $mode = $ctx->{array_mode} || 'index';

    if ($mode eq 'index') {
        return _diff_array_index($old, $new, $path, $changes, $ctx);
    }
    elsif ($mode eq 'lcs') {
        return _diff_array_lcs($old, $new, $path, $changes, $ctx);
    }
    elsif ($mode eq 'unordered') {
        return _diff_array_unordered($old, $new, $path, $changes, $ctx);
    }

    die "Unsupported array_mode: $mode";
}

# -------------------------------------------------------------------------
# Array mode: index
# -------------------------------------------------------------------------

sub _diff_array_index {
    my ($old, $new, $path, $changes, $ctx) = @_;

    my $max = @$old > @$new ? @$old : @$new;

    for my $i (0 .. $max - 1) {
        my $subpath = Data::Hash::Diff::Smart::Path::join($path, $i);

        if ($i <= $#$old && $i <= $#$new) {
            _diff($old->[$i], $new->[$i], $subpath, $changes, $ctx);
        }
        elsif ($i <= $#$old) {
            push @$changes, {
                op   => 'remove',
                path => $subpath,
                from => $old->[$i],
            };
        }
        else {
            push @$changes, {
                op    => 'add',
                path  => $subpath,
                value => $new->[$i],
            };
        }
    }
}

# -------------------------------------------------------------------------
# Array mode: LCS (Longest Common Subsequence)
# -------------------------------------------------------------------------

sub _diff_array_lcs {
    my ($old, $new, $path, $changes, $ctx) = @_;

    my @a = @$old;
    my @b = @$new;

    my $m = @a;
    my $n = @b;

    # DP table
    my @dp;
    for my $i (0 .. $m) {
        for my $j (0 .. $n) {
            $dp[$i][$j] = 0;
        }
    }

    for my $i (1 .. $m) {
        for my $j (1 .. $n) {
            if (_eq($a[$i-1], $b[$j-1])) {
                $dp[$i][$j] = $dp[$i-1][$j-1] + 1;
            } else {
                $dp[$i][$j] = $dp[$i-1][$j] > $dp[$i][$j-1]
                    ? $dp[$i-1][$j]
                    : $dp[$i][$j-1];
            }
        }
    }

    # Extract LCS
    my @lcs;
    my ($i, $j) = ($m, $n);

    while ($i > 0 && $j > 0) {
        if (_eq($a[$i-1], $b[$j-1])) {
            unshift @lcs, $a[$i-1];
            $i--; $j--;
        }
        elsif ($dp[$i-1][$j] >= $dp[$i][$j-1]) {
            $i--;
        }
        else {
            $j--;
        }
    }

    # Walk arrays and LCS
    my ($ai, $bi, $li) = (0, 0, 0);

    while ($ai < @a || $bi < @b) {
        my $l = $li < @lcs ? $lcs[$li] : undef;

        if ($ai < @a && $bi < @b && _eq($a[$ai], $b[$bi])) {
            my $subpath = Data::Hash::Diff::Smart::Path::join($path, $bi);
            _diff($a[$ai], $b[$bi], $subpath, $changes, $ctx);
            $ai++; $bi++;
        }
        elsif ($ai < @a && defined $l && _eq($a[$ai], $l)) {
            my $subpath = Data::Hash::Diff::Smart::Path::join($path, $bi);
            push @$changes, {
                op    => 'add',
                path  => $subpath,
                value => $b[$bi],
            };
            $bi++;
        }
        elsif ($bi < @b && defined $l && _eq($b[$bi], $l)) {
            my $subpath = Data::Hash::Diff::Smart::Path::join($path, $ai);
            push @$changes, {
                op   => 'remove',
                path => $subpath,
                from => $a[$ai],
            };
            $ai++;
        }
        else {
            my $subpath = Data::Hash::Diff::Smart::Path::join($path, $bi);
            _diff($a[$ai], $b[$bi], $subpath, $changes, $ctx);
            $ai++; $bi++;
        }

        if ($li < @lcs && $ai > 0 && $bi > 0 && _eq($a[$ai-1], $lcs[$li])) {
            $li++;
        }
    }
}

# -------------------------------------------------------------------------
# Array mode: unordered (multiset)
# -------------------------------------------------------------------------

sub _diff_array_unordered {
    my ($old, $new, $path, $changes, $ctx) = @_;

    my %count_old;
    my %count_new;

    $count_old{_key($_)}++ for @$old;
    $count_new{_key($_)}++ for @$new;

    my %keys;
    $keys{$_}++ for keys %count_old;
    $keys{$_}++ for keys %count_new;

    for my $k (sort keys %keys) {
        my $o = $count_old{$k} || 0;
        my $n = $count_new{$k} || 0;

        if ($n > $o) {
            for (1 .. $n - $o) {
                push @$changes, {
                    op    => 'add',
                    path  => "$path/*",
                    value => $k,
                };
            }
        }
        elsif ($o > $n) {
            for (1 .. $o - $n) {
                push @$changes, {
                    op   => 'remove',
                    path => "$path/*",
                    from => $k,
                };
            }
        }
    }
}

sub _key {
    my ($v) = @_;
    return ref($v) ? "$v" : $v;
}

# -------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------

sub _reftype {
    my ($v) = @_;
    return unless ref $v;
    return reftype($v) || 'SCALAR';
}

sub _eq {
    my ($a, $b) = @_;
    return 1 if !defined($a) && !defined($b);
    return 0 if defined($a) xor defined($b);
    return $a eq $b;
}

sub _normalize_ignore {
    my ($ignore) = @_;
    return [] unless $ignore;

    my @rules;

    for my $r (@$ignore) {

        # Regex rule
        if (ref($r) eq 'Regexp') {
            push @rules, { type => 'regex', re => $r };
            next;
        }

        # String rule: check for wildcard
        if ($r =~ /\*/) {
            my @parts = grep { length $_ } split m{/}, $r;
            push @rules, { type => 'wildcard', parts => \@parts };
        }
        else {
            push @rules, { type => 'exact', path => $r };
        }
    }

    return \@rules;
}

sub _is_ignored {
    my ($path, $rules) = @_;
    return 0 unless $rules && @$rules;

    # Split current path into parts
    my @path_parts = grep { length $_ } split m{/}, $path;

    RULE:
    for my $rule (@$rules) {

        if ($rule->{type} eq 'exact') {
            return 1 if $path eq $rule->{path};
        }

        elsif ($rule->{type} eq 'regex') {
            return 1 if $path =~ $rule->{re};
        }

        elsif ($rule->{type} eq 'wildcard') {
            my @r = @{ $rule->{parts} };

            next RULE unless @r == @path_parts;

            for my $i (0 .. $#r) {
                next if $r[$i] eq '*';
                next RULE if $r[$i] ne $path_parts[$i];
            }

            return 1;
        }
    }

    return 0;
}

1;

=head1 AUTHOR

Nigel Horne

=cut
