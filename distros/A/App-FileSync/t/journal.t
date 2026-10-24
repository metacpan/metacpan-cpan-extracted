use strict;
use warnings;
use Test::Most;

use File::Spec;
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;

use App::FileSync::Admin;
use App::FileSync::Config;
use App::FileSync::Lock;
use App::FileSync::Store;

my $env = TestSync->new_env();
my $admin = App::FileSync::Admin->new(root => $env->{server});

sub events {
    my (%args) = @_;
    return $admin->journal_read(repo => 'docs', %args);
}

sub actions {
    return [ map { $_->{action} } @{ events(@_) } ];
}

# A quiet repo journals nothing beyond what happened.
is_deeply(actions(), [], 'a fresh repo has no journal entries');

# --- push, then delete ----------------------------------------------------

$env->write_file('client', 'a.txt', "alpha\n", 1_700_000_000);
$env->write_file('client', 'dir/b.txt', "beta\n", 1_700_000_000);
my $result = $env->sync();
is($result->{summary}{pushed}, 2, 'two files were pushed');

my $pushed = events();
ok(@{$pushed}, 'the sync was journalled');

my @push_events = grep { $_->{action} eq 'push' } @{$pushed};
is(scalar @push_events, 2, 'both pushes are journalled');

for my $event (@push_events) {
    ok(defined $event->{ts} && $event->{ts} =~ /\A\d+\z/, "$event->{path} has a timestamp");
    is($event->{client}, 'test-1', "$event->{path} names the client");
    like($event->{sha256}, qr/\A[0-9a-f]{64}\z/, "$event->{path} records the hash");
    ok($event->{size} > 0, "$event->{path} records the size");
}

my ($session) = grep { $_->{action} eq 'session' } @{$pushed};
ok($session, 'the session is journalled');
is($session->{pushed}, 2, 'the session summary counts the pushes');
ok(!$session->{dry_run}, 'a real run is not marked as a dry run');

is_deeply(
    [ sort map { $_->{path} } @push_events ],
    [ 'a.txt', 'dir/b.txt' ],
    'the journalled paths are the ones that were pushed',
);

unlink $env->client_path('dir/b.txt');
$result = $env->sync();
is($result->{summary}{deleted}, 1, 'the deletion was propagated');

my ($deleted) = grep { $_->{action} eq 'delete' } @{ events() };
ok($deleted, 'the deletion is journalled');
is($deleted->{path}, 'dir/b.txt', 'the deleted path is recorded');
like($deleted->{trash}, qr{dir[/\\]b\.txt\z},
    'the journal records where it was trashed');

# --- a conflict is journalled with both sides -----------------------------

$env->write_file('server', 'a.txt', "server version\n", 1_700_000_200);
$env->write_file('client', 'a.txt', "client version\n", 1_700_000_900);

$result = $env->sync();
is($result->{summary}{conflicts}, 1, 'the two edits conflicted');
is($result->{exit}, 3, 'a conflict exits 3');

my ($conflict) = grep { $_->{action} eq 'conflict' } @{ events() };
ok($conflict, 'the conflict is journalled');
is($conflict->{path}, 'a.txt', 'the conflicted path is named');
is($conflict->{winner}, 'client', 'the newer client version won');
like($conflict->{loser_name}, qr{a\.conflict-test-1-\d{8}T\d{6}Z\.txt\z},
    'the conflict copy is named in the journal');
like($conflict->{winner_sha256}, qr/\A[0-9a-f]{64}\z/, 'the winner hash is recorded');
like($conflict->{loser_sha256}, qr/\A[0-9a-f]{64}\z/, 'the loser hash is recorded');
ok($conflict->{winner_mtime} > $conflict->{loser_mtime},
    'both mtimes are recorded and the winner is the newer one');

my ($copy) = grep { $_->{action} eq 'conflict_copy' } @{ events() };
ok($copy, 'the preserved copy is journalled');
is($copy->{from}, 'a.txt', 'the copy names the original path');

# --- filtering ------------------------------------------------------------

is_deeply(events(client => 'someone-else'), [], 'another client has no events');
is_deeply(events(since => time + 86_400), [], 'nothing happened in the future');
ok(scalar @{ events(since => 1) } > 0, 'a past --since matches everything');
is(scalar @{ events(limit => 2) }, 2, 'the limit is applied');
is((events(limit => 2))->[1]{action}, (events())->[-1]{action},
    'the limit keeps the newest events');
is_deeply(events(since => '2999-01-01'), [], 'a date --since is accepted');

throws_ok { events(since => 'last tuesday') } qr/Bad --since/,
    'a nonsensical --since is refused';

# --- a dry run neither changes anything nor writes to the journal -------

$env->write_file('client', 'dry.txt', "dry\n", 1_700_001_000);
my $before = scalar @{ events() };

$result = $env->sync(dry_run => 1);
is($result->{exit}, 0, 'the dry run succeeded');
ok(!$env->exists_in('server', 'dry.txt'), 'the dry run pushed nothing');

is(scalar(@{ events() }), $before, 'the dry run wrote no journal entries');
my ($planned) = grep { $_->{p} eq 'dry.txt' } @{ $result->{actions} };
ok($planned && $planned->{a} eq 'push', 'the dry run planned the push it did not do');

# --- failed sessions are journalled with an exit code --------------------

my $store = App::FileSync::Store->new(root => $env->{server}, repo => 'docs');
my $repo_lock = App::FileSync::Lock::acquire(
    path     => $store->lock_path(),
    nonblock => 1,
);
ok($repo_lock, 'the test holds the server repo lock');

my $blocked = $env->sync();
is($blocked->{exit}, 2, 'a server-held lock refuses the session');
close $repo_lock;

my ($refusal) = grep { ($_->{exit} || 0) == 2 } @{ events() };
ok($refusal, 'the lock refusal is journalled');
is($refusal->{action}, 'session', 'as a session outcome');
is($refusal->{result}, 'error', 'marked as an error');
ok($refusal->{locked}, 'marked as a lock refusal');
like($refusal->{error}, qr/holds the lock/, 'with the reason');

# A client that is not allowed fails before the session starts, after the
# store exists, so that attempt is journalled too.
my $client_config = App::FileSync::Config::load_client($env->{config_path});
$client_config->{client_id} = 'stranger';
App::FileSync::Config::save_client($client_config, $env->{config_path});

throws_ok { $env->sync() } qr/not allowed on repo/, 'an unknown client is refused';

$client_config->{client_id} = 'test-1';
App::FileSync::Config::save_client($client_config, $env->{config_path});

my ($fatal) = grep { ($_->{exit} || 0) == 1 } @{ events() };
ok($fatal, 'the failed session is journalled');
is($fatal->{client}, 'stranger', 'with the client that tried');
is($fatal->{action}, 'session', 'as a session outcome');
is($fatal->{result}, 'error', 'marked as an error');
like($fatal->{error}, qr/not allowed on repo/, 'with the reason');
ok(!$fatal->{locked}, 'and is not a lock refusal');

# A completed session records exit 0, so --exit 0 is the success case.
my $successes = events(exits => [0]);
ok(scalar @{$successes} > 0, '--exit 0 selects completed sessions');
is(scalar(grep { $_->{action} ne 'session' } @{$successes}), 0,
    'only session outcomes carry an exit code');
is(scalar(grep { ($_->{exit} || 0) != 0 } @{$successes}), 0,
    'and all of them succeeded');

is_deeply([ map { $_->{action} } @{ events(exits => [2]) } ], ['session'],
    '--exit 2 selects only the lock refusal');
is_deeply([ map { $_->{client} } @{ events(exits => [1]) } ], ['stranger'],
    '--exit 1 selects only the failed session');

# A session that kept a conflict copy reports the client's warning exit code.
my ($conflicted) = grep { ($_->{exit} || 0) == 3 } @{ events() };
ok($conflicted, 'a session that applied a conflict is journalled with exit 3');
is($conflicted->{conflicts}, 1, 'and carries the conflict count');
is_deeply([ map { $_->{action} } @{ events(exits => [3]) } ], ['session'],
    '--exit 3 selects the conflict session');

is(scalar @{ events(exits => [1, 2]) }, 2, '--exit can be repeated');
is_deeply(events(exits => [9]), [], 'an exit code with no events selects nothing');

# The plan event counts planned conflicts too, but only the session outcome
# shows a run that kept the copies, which is what --warnings selects.
my $warning_events = events(warnings => 1);
is_deeply([ map { $_->{action} } @{$warning_events} ], ['session'],
    '--warnings selects only the conflict session');
is($warning_events->[0]{conflicts}, 1, 'which recorded a conflict');
is($warning_events->[0]{exit}, 3, 'with the warning exit code');
is(scalar @{ events(warnings => 1, exits => [0]) }, 0,
    '--warnings composes with --exit');

# --- filesync-admin log ---------------------------------------------------

my $perl = $^X;
my $admin_bin = File::Spec->catfile($Bin, '..', 'bin', 'filesync-admin');
my $output = qx{$perl $admin_bin --root $env->{server} log docs 2>&1};
is($?, 0, 'filesync-admin log exits 0');
like($output, qr/\d{8}T\d{6}Z\s+test-1\s+conflict\s+a\.txt/, 'log shows the conflict');
like($output, qr/\d{8}T\d{6}Z\s+test-1\s+push\s+a\.txt/, 'log shows the push');
like($output, qr/winner=client/, 'log shows who won');
like($output, qr/loser=a\.conflict-test-1-/, 'log shows the conflict copy');

$output = qx{$perl $admin_bin --root $env->{server} log docs -n 1 2>&1};
is(scalar(grep { /\d{8}T\d{6}Z/ } split /\n/, $output), 1, '-n 1 prints one entry');

$output = qx{$perl $admin_bin --root $env->{server} log docs --client nobody 2>&1};
like($output, qr/No journal entries/, 'a filter that matches nothing says so');

# --- filesync-admin log --until and --exit --------------------------------

$output = qx{$perl $admin_bin --root $env->{server} log docs --exit 2 2>&1};
is($?, 0, '--exit exits 0');
like($output, qr/test-1\s+session\s+exit=2 locked .*holds the lock/,
    '--exit 2 shows the lock refusal and its reason');
unlike($output, qr/\s+push\s+/, '--exit 2 hides the pushes');

$output = qx{$perl $admin_bin --root $env->{server} log docs --exit 1 2>&1};
like($output, qr/stranger\s+session\s+exit=1 .*not allowed on repo/,
    '--exit 1 shows the failed session');

$output = qx{$perl $admin_bin --root $env->{server} log docs --exit 3 2>&1};
like($output, qr/session\s+exit=3 .*conflicts=1/, '--exit 3 shows the conflict session');

$output = qx{$perl $admin_bin --root $env->{server} log docs --exit 9 2>&1};
like($output, qr/No journal entries/, 'an unmatched --exit says so');

$output = qx{$perl $admin_bin --root $env->{server} log docs --until 2999-01-01 2>&1};
like($output, qr/\s+conflict\s+a\.txt/, '--until in the future keeps every entry');
like($output, qr/exit=0/, '--until in the future keeps the sessions too');

$output = qx{$perl $admin_bin --root $env->{server} log docs --until 1970-01-01 2>&1};
like($output, qr/No journal entries/, '--until in the past keeps nothing');

$output = qx{$perl $admin_bin --root $env->{server} log docs --until yesterday 2>&1};
isnt($?, 0, 'a bad --until is an error');
like($output, qr/Bad --until 'yesterday'/, 'the error explains the cutoff');

$output = qx{$perl $admin_bin --root $env->{server} log docs --exit 300 2>&1};
isnt($?, 0, 'an impossible exit code is an error');
like($output, qr/--exit must be between 0 and 255/, 'the error explains the range');

$output = qx{$perl $admin_bin --root $env->{server} log docs --exit 1 --exit 2 2>&1};
is(scalar(grep { /session/ } split /\n/, $output), 2, '--exit 1 --exit 2 shows both');

$output = qx{$perl $admin_bin --root $env->{server} log docs --warnings 2>&1};
is($?, 0, '--warnings exits 0');
like($output, qr/session\s+exit=3 .*conflicts=1/, '--warnings shows the conflict session');
unlike($output, qr/\s+push\s+/, '--warnings hides the pushes');
unlike($output, qr/\s+plan\s+/, '--warnings hides the plan event');

$output = qx{$perl $admin_bin --root $env->{server} log docs --warnings --exit 0 2>&1};
is($?, 0, '--warnings --exit 0 exits 0');
like($output, qr/No journal entries/, '--warnings composes with --exit');

# --- several repo names in one query --------------------------------------
$admin->repo_create(name => 'notes');
my $notes_store = App::FileSync::Store->new(root => $env->{server}, repo => 'notes');
$notes_store->journal({
    client  => 'test-1',
    action  => 'session',
    result  => 'ok',
    exit    => 0,
    pulled  => 0,
    pushed  => 0,
    deleted => 0,
    conflicts => 0,
});

$output = qx{$perl $admin_bin --root $env->{server} log docs 2>&1};
unlike($output, qr/^docs:$/m, 'a single repo needs no heading');
like($output, qr/^\d{8}T\d{6}Z/m, 'and its lines are not indented');

$output = qx{$perl $admin_bin --root $env->{server} log docs notes 2>&1};
is($?, 0, 'several names exit 0');
like($output, qr/^docs:$/m, 'the first repo is headed');
like($output, qr/^notes:$/m, 'the second repo is headed');
like($output, qr/^docs:\n(?:  [^\n]*\n)*?  [^\n]*\sconflict\s+a\.txt/ms,
    'the first repo lists its own events');
like($output, qr/^notes:\n  \d{8}T\d{6}Z\s+test-1\s+session\s+exit=0/ms,
    'the second repo follows under its own heading');

$output = qx{$perl $admin_bin --root $env->{server} log docs notes --warnings 2>&1};
is($?, 0, 'several names with --warnings exit 0');
like($output, qr/^notes:\nNo journal entries for notes$/m,
    'an empty repo says so under its heading');
like($output, qr/session\s+exit=3 .*conflicts=1/,
    'the repo with a conflict keeps its match');
unlike($output, qr/^  .*\splan\s/m, 'the plan event is still excluded');

$output = qx{$perl $admin_bin --root $env->{server} log docs nosuch 2>&1};
isnt($?, 0, 'an unknown repo among several is an error');
like($output, qr/No such repo 'nosuch'/, 'and names it');
unlike($output, qr/^docs:$/m, 'and nothing was printed before the failure');

# --- filesync-admin log --json -------------------------------------------
{
    my $output = qx{$perl $admin_bin --root $env->{server} log docs --json 2>&1};
    is($?, 0, 'log --json exits 0');

    my $data = App::FileSync::json_decode($output);
    ok(ref($data) eq 'HASH', 'the JSON parses');
    is(scalar @{ $data->{results} }, 1, 'one result for the named repo');

    my $result = $data->{results}[0];
    is($result->{repo}, 'docs', 'the result names the repo');
    like($result->{path}, qr{\.filesync[/\\]repos[/\\]docs[/\\]journal\z},
        'and the journal directory');
    is(scalar @{ $result->{events} }, scalar @{ events() }, 'every event is included');
    is($result->{events}[-1]{action}, 'session', 'events are in journal order');
    ok((grep { defined $_->{exit} } @{ $result->{events} }),
        'session outcomes carry their exit codes');

    $output = qx{$perl $admin_bin --root $env->{server} log docs --json --exit 2 2>&1};
    $data = App::FileSync::json_decode($output);
    is(scalar @{ $data->{results}[0]{events} }, 1, '--exit filters the JSON events');
    is_deeply($data->{results}[0]{exits}, [2], 'and is echoed');
    like($output, qr/"locked":1/, 'the refusal keeps its marker');

    $output = qx{$perl $admin_bin --root $env->{server} log docs --json --warnings 2>&1};
    $data = App::FileSync::json_decode($output);
    is($data->{results}[0]{warnings}, 1, '--warnings is echoed');
    is(scalar @{ $data->{results}[0]{events} }, 1,
        '--warnings filters the JSON events');
    is($data->{results}[0]{events}[0]{action}, 'session',
        'to the conflict session');
    is($data->{results}[0]{events}[0]{conflicts}, 1, 'which recorded the conflict');

    $output = qx{$perl $admin_bin --root $env->{server} log docs --json --client stranger 2>&1};
    $data = App::FileSync::json_decode($output);
    is(scalar @{ $data->{results}[0]{events} }, 1, '--client filters the JSON events');
    is($data->{results}[0]{events}[0]{client}, 'stranger', 'to the named client');
    is($data->{results}[0]{client}, 'stranger', 'the client filter is echoed');

    $output = qx{$perl $admin_bin --root $env->{server} log docs --json --until 1970-01-01 2>&1};
    $data = App::FileSync::json_decode($output);
    is(scalar @{ $data->{results}[0]{events} }, 0,
        'a window with no events gives an empty list, not a message');
    is($data->{results}[0]{until}, 86_399, 'the cutoff is echoed as an epoch');

    $output = qx{$perl $admin_bin --root $env->{server} log docs --json -n 1 2>&1};
    $data = App::FileSync::json_decode($output);
    is(scalar @{ $data->{results}[0]{events} }, 1, '-n applies to the JSON events');
    is($data->{results}[0]{events}[0]{action}, 'session', 'and keeps the newest');

    $output = qx{$perl $admin_bin --root $env->{server} log docs notes --json 2>&1};
    is($?, 0, 'several names with --json exit 0');
    $data = App::FileSync::json_decode($output);
    is_deeply([ map { $_->{repo} } @{ $data->{results} } ], [ 'docs', 'notes' ],
        'one result per repo, in the order given');
    is(scalar @{ $data->{results}[0]{events} }, scalar @{ events() },
        'the first repo keeps every event');
    is(scalar @{ $data->{results}[1]{events} }, 1, 'the second repo is queried too');
    like($data->{results}[1]{path}, qr{repos[/\\]notes[/\\]journal\z},
        'each result names its own journal directory');

    $output = qx{$perl $admin_bin --root $env->{server} log docs notes --json --warnings 2>&1};
    $data = App::FileSync::json_decode($output);
    is_deeply([ map { scalar @{ $_->{events} } } @{ $data->{results} } ], [ 1, 0 ],
        '--warnings filters each repo');
    is_deeply([ map { $_->{warnings} } @{ $data->{results} } ], [ 1, 1 ],
        'and is echoed on every result');
}

done_testing();
