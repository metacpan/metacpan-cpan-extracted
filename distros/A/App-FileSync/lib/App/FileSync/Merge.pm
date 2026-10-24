package App::FileSync::Merge;

use strict;
use warnings;

use App::FileSync qw(conflict_name);

# plan(base => ..., client => ..., master => ..., client_id => ..., role => ..., now => ...)
#
# Returns { actions => [...], warnings => [...], deletions => N, conflicts => N }.
# Each side is a hash of relative path => manifest entry (see App::FileSync::Scan).
sub plan {
    my (%args) = @_;

    my $base   = $args{base}   || {};
    my $client = $args{client} || {};
    my $master = $args{master} || {};

    my $client_id = defined $args{client_id} ? $args{client_id} : 'unknown';
    my $now       = defined $args{now} ? $args{now} : time;
    my $role      = $args{role} || 'client';

    return _replica_plan(
        base      => $base,
        client    => $client,
        master    => $master,
        client_id => $client_id,
    ) if $role eq 'replica';

    my @actions;
    my @warnings;

    my %paths = (%{$base}, %{$client}, %{$master});

    for my $path (sort keys %paths) {
        my $b = $base->{$path};
        my $a = $client->{$path};
        my $m = $master->{$path};

        # Gone on both sides: nothing to do, the base entry is dropped at commit.
        next unless $a || $m;

        if (!$a) {
            if ($b && _same($m, $b)) {
                push @actions, { a => 'delete_remote', p => $path };
            } else {
                push @actions, {
                    a => 'pull',
                    p => $path,
                    t => _type($m),
                    (defined $m->{h} ? (h => $m->{h}) : ()),
                };
                push @warnings,
                    "$path: deleted on $client_id but changed on the master; restored from the master"
                    if $b;
            }
            next;
        }

        if (!$m) {
            if ($b && _same($a, $b)) {
                push @actions, { a => 'delete_local', p => $path, t => _type($a) };
            } else {
                push @actions, {
                    a => 'push',
                    p => $path,
                    t => _type($a),
                    (defined $a->{h} ? (h => $a->{h}) : ()),
                };
                push @warnings,
                    "$path: changed on $client_id but deleted on the master; restored to the master"
                    if $b;
            }
            next;
        }

        # Both sides have it.
        next if _same($a, $m);                             # already converged

        if ($b && _same($a, $b)) {
            push @actions, {
                a => 'pull',
                p => $path,
                t => _type($m),
                (defined $m->{h} ? (h => $m->{h}) : ()),
            };
            next;
        }

        if ($b && _same($m, $b)) {
            push @actions, {
                a => 'push',
                p => $path,
                t => _type($a),
                (defined $a->{h} ? (h => $a->{h}) : ()),
            };
            next;
        }

        my $resolution = _conflict($path, $a, $m, $client_id, $now);
        push @actions, $resolution;
        push @warnings, _conflict_warning($path, $resolution, $client_id);
    }

    # Deletions run first so a type change never tries to write over a directory.
    my @deletions = grep { $_->{a} =~ /\Adelete_/ } @actions;
    my @transfers = grep { $_->{a} !~ /\Adelete_/ } @actions;
    my @ordered = (@deletions, @transfers);

    return {
        actions   => \@ordered,
        warnings  => \@warnings,
        deletions => scalar(grep { $_->{a} =~ /\Adelete_/ } @ordered),
        conflicts => scalar(grep { $_->{a} eq 'conflict' } @ordered),
    };
}

# A replica mirrors the master: pull what differs, remove what the master no longer has,
# and never push.  Local edits are reported and then overwritten.
sub _replica_plan {
    my (%args) = @_;
    my ($base, $client, $master) = @args{qw(base client master)};

    my @actions;
    my @warnings;

    for my $path (sort keys %{$master}) {
        my $a = $client->{$path};
        my $m = $master->{$path};
        next if $a && _same($a, $m);
        push @actions, {
            a => 'pull',
            p => $path,
            t => _type($m),
            (defined $m->{h} ? (h => $m->{h}) : ()),
        };
        if ($a && $base->{$path} && !_same($a, $base->{$path})) {
            push @warnings, "$path: changed on the replica; overwritten from the master";
        }
    }

    for my $path (sort keys %{$client}) {
        next if $master->{$path};
        push @actions, { a => 'delete_local', p => $path, t => _type($client->{$path}) };
        push @warnings, "$path: removed on the replica; not in the master";
    }

    return {
        actions   => \@actions,
        warnings  => \@warnings,
        deletions => scalar(grep { $_->{a} =~ /\Adelete_/ } @actions),
        conflicts => 0,
    };
}

sub _conflict {
    my ($path, $client_entry, $master_entry, $client_id, $now) = @_;

    my $winner;
    if (_type($client_entry) eq 'f' && _type($master_entry) eq 'f') {
        my $client_mtime = defined $client_entry->{m} ? $client_entry->{m} : 0;
        my $master_mtime = defined $master_entry->{m} ? $master_entry->{m} : 0;
        # Within two seconds, or exactly equal, the master wins deterministically.
        $winner = $client_mtime > $master_mtime + 2 ? 'client' : 'remote';
    } elsif (_type($client_entry) eq 'f') {
        $winner = 'client';
    } else {
        $winner = 'remote';
    }

    my $winner_entry = $winner eq 'client' ? $client_entry : $master_entry;
    my $loser = $winner eq 'client' ? $master_entry : $client_entry;
    my $loser_type = _type($loser);
    my $loser_name = $loser_type eq 'f' ? conflict_name($path, $client_id, $now) : undef;

    return {
        a            => 'conflict',
        p            => $path,
        winner       => $winner,
        winner_type  => _type($winner_entry),
        (defined $winner_entry->{h} ? (h => $winner_entry->{h}) : ()),
        (defined $loser_name ? (loser_name => $loser_name) : ()),
        loser_type   => $loser_type,
    };
}

sub _conflict_warning {
    my ($path, $resolution, $client_id) = @_;

    my $kept = $resolution->{winner} eq 'client' ? $client_id : 'master';
    my $other = $resolution->{winner} eq 'client' ? 'master' : $client_id;

    return "$path: changed on both $client_id and the master; $kept version kept"
        . ($resolution->{loser_name}
            ? ", $other version saved as $resolution->{loser_name}"
            : ', the empty directory on the other side was discarded');
}

sub _same {
    my ($left, $right) = @_;

    return 1 unless $left || $right;
    return 0 unless $left && $right;

    my $left_type = _type($left);
    return 0 unless $left_type eq _type($right);
    return 1 if $left_type eq 'd';

    return 0 unless defined $left->{h} && defined $right->{h};
    return $left->{h} eq $right->{h} ? 1 : 0;
}

sub _type {
    my ($entry) = @_;
    return 'f' unless $entry && defined $entry->{t} && length $entry->{t};
    return $entry->{t};
}

# Guard against a misconfigured client (or an empty mount) wiping the master.
# Returns undef when the plan is acceptable, or a message when it must be refused.
sub check_delete_limit {
    my (%args) = @_;

    my $deletions = $args{deletions} || 0;
    my $base_size = $args{base_size} || 0;
    my $max       = defined $args{max_deletes} ? $args{max_deletes} : 200;
    my $percent   = defined $args{max_delete_percent} ? $args{max_delete_percent} : 10;

    return undef if $deletions == 0;
    return undef if $args{force};

    if ($max && $deletions > $max) {
        return "refusing to delete $deletions files (limit is $max); rerun with --force if this is intended";
    }

    if ($percent && $base_size > 0) {
        # Never block a single deletion just because the repo is small:
        # 10% of five files is zero, which would make the tool unusable.
        my $allowed = int($base_size * $percent / 100);
        $allowed = 1 if $allowed < 1;
        if ($deletions > $allowed) {
            return "refusing to delete $deletions of $base_size known files (limit is $percent%); rerun with --force if this is intended";
        }
    }

    return undef;
}

1;
