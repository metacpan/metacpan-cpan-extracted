package App::FileSync::Merge;

# The three-way merge: given what the client had at the last sync (the base),
# what it has now, and what the master has now, decide what moves where.
# Pure functions of their arguments; nothing here touches the disk.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Sub::Private { mode => 'enforce' };

use App::FileSync qw(conflict_name);
use App::FileSync::Args qw(named);
use App::FileSync::Constants qw(
	$ROLE_CLIENT $ROLE_REPLICA @ROLES $TYPE_FILE $TYPE_DIR
	$MAX_DELETES $MAX_DELETE_PERCENT $MTIME_TOLERANCE
);
use App::FileSync::I18N qw(message);

use version; our $VERSION = version->declare('0.001.5');

# The comparisons below run several times per path in the tree, so they are
# lexical code references rather than wrapped private subs; see
# App::FileSync/LIMITATIONS.

# Entry type, treating a missing "t" as a file.
my $type = sub {
	my ($entry) = @_;
	return ($entry && defined $entry->{t} && length $entry->{t}) ? $entry->{t} : $TYPE_FILE;
};

# Two entries describe the same content: both absent, both directories, or
# both files with the same hash.
my $same = sub {
	my ($left, $right) = @_;

	return 1 unless $left || $right;
	return 0 unless $left && $right;

	my $left_type = $type->($left);
	return 0 unless $left_type eq $type->($right);
	return 1 if $left_type eq $TYPE_DIR;

	return (defined $left->{h} && defined $right->{h} && $left->{h} eq $right->{h}) ? 1 : 0;
};

# A pull or push action for one path, carrying the hash the receiver must
# verify against.
my $transfer = sub {
	my ($verb, $path, $entry) = @_;
	return {
		a => $verb,
		p => $path,
		t => $type->($entry),
		(defined $entry->{h} ? (h => $entry->{h}) : ()),
	};
};

=encoding utf8

=head1 NAME

App::FileSync::Merge - three-way merge of base, client and master manifests

=head1 SYNOPSIS

	my $plan = App::FileSync::Merge::plan(
		base => $base, client => $client, master => $master,
		client_id => 'laptop-1', role => 'client', now => time,
	);
	my $refusal = App::FileSync::Merge::check_delete_limit(
		deletions => $plan->{deletions}, base_size => scalar(keys %$base),
	);

=head1 FUNCTIONS

=head2 plan

Purpose: decide, path by path, what a session must do.

Args: C<base>, C<client>, C<master> (manifests: path =E<gt> entry, see
L<App::FileSync::Scan>), C<client_id>, C<role> (C<client> or C<replica>),
C<now> (the epoch used in conflict-copy names).

Returns: a hashref C<{ actions, warnings, deletions, conflicts }>.  Actions are
hashes with C<a> (pull, push, delete_local, delete_remote or conflict) and
C<p> (the path); deletions come first, so a type change never writes over a
directory.  Warnings are translated sentences.

Side Effects: none.

Usage:

	my $plan = App::FileSync::Merge::plan(%manifests, client_id => $id);

=head3 EXAMPLE

	my $plan = App::FileSync::Merge::plan(
		base   => {},
		client => { 'a.txt' => { t => 'f', h => 'aa' } },
		master => {},
	);
	print $plan->{actions}[0]{a}, "\n";	# push

=head3 API SPECIFICATION

=head4 INPUT

	{
		base      => { type => 'hashref', optional => 1 },
		client    => { type => 'hashref', optional => 1 },
		master    => { type => 'hashref', optional => 1 },
		client_id => { type => 'string', optional => 1 },
		role      => { type => 'string', memberof => [ 'client', 'replica' ], optional => 1 },
		now       => { type => 'number', optional => 1 },
	}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			actions   => { type => 'arrayref' },
			warnings  => { type => 'arrayref' },
			deletions => { type => 'integer', min => 0 },
			conflicts => { type => 'integer', min => 0 },
		},
	}

=head3 MESSAGES

Warnings (returned, not raised):

	Key                            Meaning
	merge.deleted_changed          deleted on the client, changed on the master; master copy restored
	merge.changed_deleted          changed on the client, deleted on the master; client copy restored
	merge.conflict_copy            changed on both; loser kept as a conflict copy
	merge.conflict_dir             changed on both; an empty directory lost
	merge.replica_overwritten      a replica's local edit was overwritten
	merge.replica_removed          a replica's extra file was removed

=head3 FORMAL SPECIFICATION

	B, A, M : PATH ⇸ ENTRY      (base, client, master)
	∀ p ∈ dom B ∪ dom A ∪ dom M •
		p ∉ dom A ∧ p ∉ dom M                     ⇒ no action
		p ∉ dom A ∧ same(M p, B p)                ⇒ delete_remote p
		p ∉ dom A ∧ ¬same(M p, B p)               ⇒ pull p
		p ∉ dom M ∧ same(A p, B p)                ⇒ delete_local p
		p ∉ dom M ∧ ¬same(A p, B p)               ⇒ push p
		same(A p, M p)                            ⇒ no action
		same(A p, B p)                            ⇒ pull p
		same(M p, B p)                            ⇒ push p
		otherwise                                 ⇒ conflict p
	role = replica ⇒ actions ⊆ {pull, delete_local}

=head3 PSEUDOCODE

	if replica: mirror the master and return
	for each path in base, client or master, sorted:
		apply the table above, adding a warning where one side's change
		is undone or a conflict copy is made
	put deletions before transfers
	count deletions and conflicts

=cut

sub plan {
	my $args = named(\@_, {
		base      => { type => 'hashref', optional => 1 },
		client    => { type => 'hashref', optional => 1 },
		master    => { type => 'hashref', optional => 1 },
		client_id => { type => 'string', optional => 1 },
		role      => { type => 'string', memberof => [@ROLES], optional => 1 },
		now       => { type => 'number', optional => 1 },
	}, 'Merge::plan');

	my $base   = $args->{base}   || {};
	my $client = $args->{client} || {};
	my $master = $args->{master} || {};
	my $client_id = defined $args->{client_id} ? $args->{client_id} : 'unknown';
	my $now = defined $args->{now} ? $args->{now} : time;

	return _replica_plan($base, $client, $master)
		if ($args->{role} || $ROLE_CLIENT) eq $ROLE_REPLICA;

	my (@actions, @warnings);
	my %paths = (%{$base}, %{$client}, %{$master});

	for my $path (sort keys %paths) {
		my ($b, $a, $m) = ($base->{$path}, $client->{$path}, $master->{$path});
		my %who = (path => $path, client => $client_id);

		# Gone on both sides: nothing to do, the base entry is dropped at commit.
		next unless $a || $m;

		if (!$a || !$m) {
			# One side lacks it: an unchanged survivor follows the deletion;
			# a changed one wins, and the deletion is undone with a warning.
			my ($have, $verb, $delete, $undo) = $a
				? ($a, 'push', { a => 'delete_local', p => $path, t => $type->($a) }, 'merge.changed_deleted')
				: ($m, 'pull', { a => 'delete_remote', p => $path }, 'merge.deleted_changed');

			if ($b && $same->($have, $b)) {
				push @actions, $delete;
			} else {
				push @actions, $transfer->($verb, $path, $have);
				push @warnings, message($undo, \%who) if $b;
			}
		} elsif ($same->($a, $m)) {
			next;	# already converged
		} elsif ($b && $same->($a, $b)) {
			push @actions, $transfer->('pull', $path, $m);
		} elsif ($b && $same->($m, $b)) {
			push @actions, $transfer->('push', $path, $a);
		} else {
			my $resolution = _conflict($path, $a, $m, $client_id, $now);
			push @actions, $resolution;
			push @warnings, _conflict_warning($resolution, \%who);
		}
	}

	return _ordered(\@actions, \@warnings);
}

=head2 check_delete_limit

Purpose: guard against a misconfigured client (or an empty mount) wiping the
master.

Args: C<deletions> (planned), C<base_size> (files known at the last sync),
C<max_deletes> (default 200; 0 disables), C<max_delete_percent> (default 10;
0 disables), C<force>.

Returns: C<undef> when the plan is acceptable, or a translated sentence
explaining the refusal.  At least one deletion is always allowed, so a small
repo stays usable.

Side Effects: none.

Usage:

	my $refusal = App::FileSync::Merge::check_delete_limit(%counts, force => $force);

=head3 EXAMPLE

	my $why = App::FileSync::Merge::check_delete_limit(deletions => 300, base_size => 1000);
	print "$why\n" if defined $why;	# refusing to delete 300 files (limit is 200); ...

=head3 API SPECIFICATION

=head4 INPUT

	{
		deletions          => { type => 'integer', min => 0, optional => 1 },
		base_size          => { type => 'integer', min => 0, optional => 1 },
		max_deletes        => { type => 'integer', min => 0, optional => 1 },
		max_delete_percent => { type => 'number', min => 0, optional => 1 },
		force              => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string', optional => 1 }

=head3 MESSAGES

	Key                       Meaning                                Resolution
	merge.too_many            over the absolute limit                --force if intended
	merge.too_many_percent    over the percentage of known files     --force if intended

=head3 FORMAL SPECIFICATION

	allowed(n, k) ⇔ n = 0 ∨ force ∨ ((max = 0 ∨ n ≤ max) ∧ (pct = 0 ∨ k = 0 ∨ n ≤ max(1, ⌊k × pct / 100⌋)))
	check(n, k) = ⊥ if allowed(n, k), reason otherwise

=cut

sub check_delete_limit {
	my $args = named(\@_, {
		deletions          => { type => 'integer', min => 0, optional => 1 },
		base_size          => { type => 'integer', min => 0, optional => 1 },
		max_deletes        => { type => 'integer', min => 0, optional => 1 },
		max_delete_percent => { type => 'number', min => 0, optional => 1 },
		force              => { type => 'boolean', optional => 1 },
	}, 'Merge::check_delete_limit');

	my $deletions = $args->{deletions} || 0;
	my $known     = $args->{base_size} || 0;
	my $max       = defined $args->{max_deletes} ? $args->{max_deletes} : $MAX_DELETES;
	my $percent   = defined $args->{max_delete_percent} ? $args->{max_delete_percent} : $MAX_DELETE_PERCENT;

	# Never block a single deletion just because the repo is small: 10% of
	# five files is zero, which would make the tool unusable.
	my $allowed = int($known * $percent / 100);
	$allowed = 1 if $allowed < 1;

	my %args = (count => $deletions, known => $known, max => $max, percent => $percent);
	my $refusal =
		  ($deletions == 0 || $args->{force})       ? undef
		: ($max && $deletions > $max)               ? message('merge.too_many', \%args)
		: ($percent && $known > 0 && $deletions > $allowed) ? message('merge.too_many_percent', \%args)
		: undef;

	return $refusal;
}

# _replica_plan
# Purpose:     plan for a replica: mirror the master, never push.
# Entry:       manifests for base, replica and master.
# Exit:        returns the same shape as plan(); local edits are reported and
#              then overwritten, local extras removed.
# Side effects: none.
sub _replica_plan :Private {
	my ($base, $client, $master) = @_;

	my (@actions, @warnings);

	for my $path (sort keys %{$master}) {
		my $have = $client->{$path};
		next if $have && $same->($have, $master->{$path});

		push @actions, $transfer->('pull', $path, $master->{$path});
		push @warnings, message('merge.replica_overwritten', { path => $path })
			if $have && $base->{$path} && !$same->($have, $base->{$path});
	}

	for my $path (sort grep { !$master->{$_} } keys %{$client}) {
		push @actions, { a => 'delete_local', p => $path, t => $type->($client->{$path}) };
		push @warnings, message('merge.replica_removed', { path => $path });
	}

	return _ordered(\@actions, \@warnings);
}

# _ordered
# Purpose:     the plan result: deletions first, with counts.
# Entry:       $actions and $warnings are arrayrefs.
# Exit:        returns { actions, warnings, deletions, conflicts }.
# Side effects: none.
sub _ordered :Private {
	my ($actions, $warnings) = @_;

	# Deletions run first so a type change never tries to write over a directory.
	my @deletions = grep { $_->{a} =~ /\Adelete_/ } @{$actions};
	my @transfers = grep { $_->{a} !~ /\Adelete_/ } @{$actions};

	return {
		actions   => [ @deletions, @transfers ],
		warnings  => $warnings,
		deletions => scalar(@deletions),
		conflicts => scalar(grep { $_->{a} eq 'conflict' } @transfers),
	};
}

# _conflict
# Purpose:     resolve a path both sides changed.
# Entry:       both entries exist and differ from each other and the base.
# Exit:        returns a conflict action naming the winner and, for a losing
#              file, the name to keep it under.
# Side effects: none.
sub _conflict :Private {
	my ($path, $client_entry, $master_entry, $client_id, $now) = @_;

	my ($client_type, $master_type) = ($type->($client_entry), $type->($master_entry));

	# A file beats an empty directory; between two files the newer wins, and
	# within the clock tolerance the master wins deterministically.
	my $winner = $client_type ne $TYPE_FILE ? 'remote'
		: $master_type ne $TYPE_FILE ? 'client'
		: ($client_entry->{m} || 0) > ($master_entry->{m} || 0) + $MTIME_TOLERANCE ? 'client'
		: 'remote';

	my ($winner_entry, $loser) = $winner eq 'client'
		? ($client_entry, $master_entry)
		: ($master_entry, $client_entry);
	my $loser_type = $type->($loser);

	return {
		a           => 'conflict',
		p           => $path,
		winner      => $winner,
		winner_type => $type->($winner_entry),
		(defined $winner_entry->{h} ? (h => $winner_entry->{h}) : ()),
		($loser_type eq $TYPE_FILE ? (loser_name => conflict_name($path, $client_id, $now)) : ()),
		loser_type  => $loser_type,
	};
}

# _conflict_warning
# Purpose:     the sentence that reports a conflict.
# Entry:       $resolution is a conflict action; $who holds path and client.
# Exit:        returns the translated warning.
# Side effects: none.
sub _conflict_warning :Private {
	my ($resolution, $who) = @_;

	my $master = message('merge.master');
	my ($kept, $other) = $resolution->{winner} eq 'client'
		? ($who->{client}, $master)
		: ($master, $who->{client});

	return message($resolution->{loser_name} ? 'merge.conflict_copy' : 'merge.conflict_dir', {
		%{$who},
		kept  => $kept,
		other => $other,
		copy  => $resolution->{loser_name},
	});
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * Conflicts are resolved by mtime; see L<App::FileSync/LIMITATIONS>.

=item * The plan holds every path in memory three times over (the union of
the three manifests).  That is the price of a stateless server.

=item * A rename is seen as a deletion plus a creation, so a renamed large
file is transferred again rather than moved.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
