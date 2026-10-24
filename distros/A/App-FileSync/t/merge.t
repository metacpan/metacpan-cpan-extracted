use strict;
use warnings;
use Test::Most;

use App::FileSync::Merge;

my $H1 = 'a' x 64;
my $H2 = 'b' x 64;
my $H3 = 'c' x 64;

sub entry {
    my ($hash, $mtime, %extra) = @_;
    return { t => 'f', s => 10, m => $mtime, h => $hash, mode => oct(644), %extra };
}

sub dir_entry { return { t => 'd' } }

sub actions_of {
    my ($base, $client, $master, %opts) = @_;
    my $plan = App::FileSync::Merge::plan(
        base      => $base,
        client    => $client,
        master    => $master,
        client_id => 'laptop-1',
        now       => 1_792_700_000,
        %opts,
    );
    return ($plan->{actions}, $plan);
}

sub action_for {
    my ($base, $client, $master, $path) = @_;
    my ($actions) = actions_of($base, $client, $master);
    my ($found) = grep { $_->{p} eq $path } @{$actions};
    return $found;
}

# 1. nothing anywhere
is_deeply((actions_of({}, {}, {}))[0], [], 'empty trees produce no actions');

# 2. master changed
is(action_for({ p => entry($H1, 100) }, { p => entry($H1, 100) }, { p => entry($H2, 200) }, 'p')->{a},
    'pull', 'master-only change is pulled');

# 3. client changed
is(action_for({ p => entry($H1, 100) }, { p => entry($H2, 200) }, { p => entry($H1, 100) }, 'p')->{a},
    'push', 'client-only change is pushed');

# 4. both changed to the same thing
is(action_for({ p => entry($H1, 100) }, { p => entry($H2, 200) }, { p => entry($H2, 200) }, 'p'),
    undef, 'identical changes converge with no action');

# 5. client deleted, master untouched
is(action_for({ p => entry($H1, 100) }, {}, { p => entry($H1, 100) }, 'p')->{a},
    'delete_remote', 'client deletion deletes the master copy');

# 6. master deleted, client untouched
is(action_for({ p => entry($H1, 100) }, { p => entry($H1, 100) }, {}, 'p')->{a},
    'delete_local', 'master deletion deletes the client copy');

# 7. deleted on both sides
is(action_for({ p => entry($H1, 100) }, {}, {}, 'p'),
    undef, 'deleted on both sides is already converged');

# 8. client deleted, master modified: the edit wins
my ($delete_modify, $plan8) = actions_of({ p => entry($H1, 100) }, {}, { p => entry($H2, 200) });
is($delete_modify->[0]{a}, 'pull', 'modification beats deletion on the master');
is(scalar @{ $plan8->{warnings} }, 1, 'the resurrection is reported');
like($plan8->{warnings}[0], qr/deleted on laptop-1 but changed on the master/,
    'warning names the client and the master');

# 9. master deleted, client modified: the edit wins
my ($modify_delete, $plan9) = actions_of({ p => entry($H1, 100) }, { p => entry($H2, 200) }, {});
is($modify_delete->[0]{a}, 'push', 'modification beats deletion on the client');
is(scalar @{ $plan9->{warnings} }, 1, 'the resurrection is reported');

# 10. both sides added the same file
is(action_for({}, { p => entry($H1, 100) }, { p => entry($H1, 100) }, 'p'),
    undef, 'identical new files converge');

# 11. new on the client
is(action_for({}, { p => entry($H1, 100) }, {}, 'p')->{a}, 'push', 'new client file is pushed');

# 12. new on the master
is(action_for({}, {}, { p => entry($H1, 100) }, 'p')->{a}, 'pull', 'new master file is pulled');

# 13. new on both sides, different
my $conflict13 = action_for({}, { p => entry($H2, 300) }, { p => entry($H1, 100) }, 'p');
is($conflict13->{a}, 'conflict', 'two different new files conflict');
is($conflict13->{winner}, 'client', 'the newer client file wins');
like($conflict13->{loser_name}, qr{\Ap\.conflict-laptop-1-\d{8}T\d{6}Z\z},
    'the loser gets a conflict copy name');

# 14. both modified: newest wins, ties go to the master
my $client_wins = action_for({ p => entry($H1, 100) }, { p => entry($H2, 300) }, { p => entry($H3, 200) }, 'p');
is($client_wins->{winner}, 'client', 'newer client modification wins');
is($client_wins->{winner_type}, 'f', 'winner type is reported');
is($client_wins->{h}, $H2, 'winner hash is reported');

my $master_wins = action_for({ p => entry($H1, 100) }, { p => entry($H2, 200) }, { p => entry($H3, 300) }, 'p');
is($master_wins->{winner}, 'remote', 'newer master modification wins');

my $tie = action_for({ p => entry($H1, 100) }, { p => entry($H2, 200) }, { p => entry($H3, 201) }, 'p');
is($tie->{winner}, 'remote', 'a tie within two seconds goes to the master');

# Conflict copies keep an extension, and names without one are handled.
my $now = 1_792_700_000;
my $stamp = App::FileSync::format_utc($now);
is(App::FileSync::conflict_name('notes.txt', 'laptop-1', $now),
    "notes.conflict-laptop-1-$stamp.txt", 'conflict name preserves the extension');
is(App::FileSync::conflict_name('noextension', 'laptop-1', $now),
    "noextension.conflict-laptop-1-$stamp", 'name without an extension');
is(App::FileSync::conflict_name('a/b/.hidden', 'laptop-1', $now),
    "a/b/.hidden.conflict-laptop-1-$stamp", 'dotfile keeps its name');
is(App::FileSync::conflict_name('dir/file.txt', 'laptop-1', $now),
    "dir/file.conflict-laptop-1-$stamp.txt", 'subdirectory preserved');

# Directories: an empty directory deleted on the client.
is(action_for({ d => dir_entry() }, {}, { d => dir_entry() }, 'd')->{a},
    'delete_remote', 'empty directory deletion propagates');

# File replaced by an (empty) directory on the master while the client is unchanged:
# that is an ordinary master-side change and is pulled.
my $type_change = action_for({ p => entry($H1, 100) }, { p => entry($H1, 100) }, { p => dir_entry() }, 'p');
is($type_change->{a}, 'pull', 'an unchanged client follows a file/directory change');

# Both sides changed type/content: the file wins over the empty directory.
my $type_conflict = action_for({ p => entry($H1, 100) }, { p => entry($H2, 300) }, { p => dir_entry() }, 'p');
is($type_conflict->{a}, 'conflict', 'a contested type change is a conflict');
is($type_conflict->{winner}, 'client', 'the file wins over an empty directory');
ok(!defined $type_conflict->{loser_name}, 'no conflict copy is invented for an empty directory');

# Deletions run before transfers.
my ($ordered) = actions_of(
    { gone => entry($H1, 100), kept => entry($H1, 100) },
    { kept => entry($H2, 200) },
    { gone => entry($H1, 100), kept => entry($H1, 100) },
);
is($ordered->[0]{a}, 'delete_remote', 'deletions are ordered first');
is($ordered->[1]{a}, 'push', 'transfers follow');

# Replica: mirror only, never push.
my $replica = App::FileSync::Merge::plan(
    base       => { a => entry($H1, 100) },
    client     => { a => entry($H2, 200), extra => entry($H1, 100) },
    master     => { a => entry($H1, 100), b => entry($H3, 100) },
    client_id  => 'backup-1',
    role       => 'replica',
);
my %replica_actions = map { $_->{p} => $_->{a} } @{ $replica->{actions} };
is_deeply(\%replica_actions, { a => 'pull', b => 'pull', extra => 'delete_local' },
    'replica pulls what differs and removes extras, never pushes');
is($replica->{conflicts}, 0, 'a replica cannot conflict');
ok((grep { $_ =~ /changed on the replica/ } @{ $replica->{warnings} }),
    'local replica edits are reported');

# Delete guard.
ok(!defined App::FileSync::Merge::check_delete_limit(
    deletions => 10, base_size => 100, max_deletes => 200, max_delete_percent => 10),
    'ten deletions out of a hundred is allowed');
ok(defined App::FileSync::Merge::check_delete_limit(
    deletions => 201, base_size => 10_000, max_deletes => 200),
    'the absolute limit refuses 201 deletions');
ok(defined App::FileSync::Merge::check_delete_limit(
    deletions => 11, base_size => 100, max_delete_percent => 10),
    'the percentage limit refuses eleven out of a hundred');
ok(!defined App::FileSync::Merge::check_delete_limit(
    deletions => 1, base_size => 2, max_delete_percent => 10),
    'a single deletion is never blocked by the percentage rule');

# Ten percent of a five-file base floors to zero; the guard raises the
# allowance to one so a small repo can still shed a file, but no more.
ok(!defined App::FileSync::Merge::check_delete_limit(
    deletions => 1, base_size => 5, max_deletes => 200, max_delete_percent => 10),
    'one deletion in a five-file base is allowed');

my $small_refusal = App::FileSync::Merge::check_delete_limit(
    deletions => 2, base_size => 5, max_deletes => 200, max_delete_percent => 10);
ok(defined $small_refusal, 'two deletions in a five-file base are refused');
is($small_refusal,
    'refusing to delete 2 of 5 known files (limit is 10%); rerun with --force if this is intended',
    'the small-repo refusal names the count, the base and the percentage');

# Nine files is the largest base whose ten percent still floors to zero (ten
# files first reach an allowance of one), and the raised allowance holds there
# too: one deletion passes, a two-file batch does not.
ok(!defined App::FileSync::Merge::check_delete_limit(
    deletions => 1, base_size => 9, max_deletes => 200, max_delete_percent => 10),
    'one deletion in a nine-file base is allowed');

my $floor_refusal = App::FileSync::Merge::check_delete_limit(
    deletions => 2, base_size => 9, max_deletes => 200, max_delete_percent => 10);
ok(defined $floor_refusal, 'two deletions in a nine-file base are refused');
is($floor_refusal,
    'refusing to delete 2 of 9 known files (limit is 10%); rerun with --force if this is intended',
    'the nine-file refusal names the count, the base and the percentage');
ok(!defined App::FileSync::Merge::check_delete_limit(
    deletions => 201, base_size => 10_000, max_deletes => 200, force => 1),
    '--force overrides the limits');

done_testing();
