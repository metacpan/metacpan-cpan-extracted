package App::FileSync::Client;

# The client end of a sync, plus the client-side commands that work on one
# repo: log, verify, restore from the local trash, and replica snapshots.
# Everything the client keeps for a repo lives under ~/.filesync: its cache
# (the base of the last sync), its run log, its lock and its trash.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Digest::SHA ();
use File::Basename qw(dirname);
use File::Spec;
use File::Temp ();
use List::Util qw(any);
use Readonly;
use Sub::Private { mode => 'enforce' };
use Sys::Hostname ();
use Time::HiRes ();

use parent 'App::FileSync::Base';

use App::FileSync qw(json_encode json_decode validate_relpath validate_repo_name parse_since parse_until);
use App::FileSync::Args qw(named);
use App::FileSync::Config;
use App::FileSync::Constants qw(
	$PROTOCOL_VERSION $ROLE_CLIENT $ROLE_REPLICA $TYPE_FILE $TYPE_DIR $MODE_MASK
	$EXIT_OK $EXIT_FATAL $EXIT_LOCKED $EXIT_WARNINGS
	$ROOT_MARKER $SNAPSHOT_DIR $TEMP_PREFIX $TRASH_DAYS $SNAPSHOT_KEEP
);
use App::FileSync::Delta;
use App::FileSync::I18N qw(os_error strip_location);
use App::FileSync::IO qw(append_line ensure_dir install_file open_file read_text temp_file write_atomic);
use App::FileSync::Ignore;
use App::FileSync::Lock;
use App::FileSync::Protocol;
use App::FileSync::Scan;
use App::FileSync::Settings;
use App::FileSync::Snapshot;
use App::FileSync::Transport::Local;
use App::FileSync::Transport::SSH;
use App::FileSync::Trash;
use App::FileSync::Verify;

use version; our $VERSION = version->declare('0.001.2');

# Tunables, kept as package variables so tests can localise them.
our $CHUNK          = 262_144;
our $MANIFEST_CHUNK = 2_000;

# How many run summaries the local log keeps before trimming the oldest.
our $LOG_LIMIT = 500;

# How many runs "filesync log" shows when no limit is given.
Readonly my $LOG_DEFAULT_LIMIT => 20;

# Wire cost of one delta record (see the server's identical estimate).
Readonly my $DELTA_OP_BYTES => 12;
Readonly my $DELTA_OVERHEAD => 64;

# Per-repo trash lives under trash/repos/NAME; "repos" can never be mistaken
# for a year directory of the trash layout used before 0.001.1, which put
# every repo's trash straight under trash/.
Readonly my $TRASH_REPOS => 'repos';

# Names probed to discover whether the sync root's filesystem folds case.
Readonly my $CASE_PROBE => "${TEMP_PREFIX}caseprobe";

# Summary counters, in the order the run log records them.
Readonly my @SUMMARY_KEYS => qw(pulled pushed deleted conflicts skipped delta_pulled delta_pushed bytes_sent bytes_received);

=encoding utf8

=head1 NAME

App::FileSync::Client - sync one repo, and the client-side repo commands

=head1 SYNOPSIS

	my $config = App::FileSync::Config::load_client();
	my $client = App::FileSync::Client->new(config => $config, name => 'docs', opts => { verbose => 1 });

	my $result = $client->sync;
	exit $result->{exit};

=head1 DESCRIPTION

A sync is one session with the server: hello, manifest, plan, then the
transfers the plan lists, then done.  The client keeps under
F<~/.filesync> (or C<FILESYNC_HOME>):

	cache/NAME.json          the base: what the last successful sync left
	logs/NAME.jsonl          one line per attempt, for "filesync log"
	locks/NAME.lock          held for the whole run
	trash/repos/NAME/Y/M/D/  files the sync deleted or replaced locally

Exit codes: 0 ok, 1 error, 2 another run holds the lock, 3 finished with
warnings (conflicts or skipped paths).

=head1 METHODS

=head2 new

Purpose: a client for one repo of a client configuration.

Args: C<config> (from L<App::FileSync::Config/load_client>), C<name> (the
repo's key in it), optional C<opts> (C<dry_run>, C<force>, C<no_prune>,
C<no_delta>, C<verbose>, C<quiet>), C<logger>, C<settings> (process settings,
read lazily otherwise), C<language>.

Returns: the client.

Side Effects: builds a logger from the settings when none is given.

Usage:

	my $client = App::FileSync::Client->new(config => $config, name => 'docs');

=head3 EXAMPLE

	my $client = App::FileSync::Client->new(
		config => $config, name => 'docs', opts => { dry_run => 1 },
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		config   => { type => 'hashref' },
		name     => { type => 'string', min => 1, max => 64 },
		opts     => { type => 'hashref', optional => 1 },
		logger   => { type => 'object', optional => 1 },
		settings => { type => 'hashref', optional => 1 },
		language => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::FileSync::Client' }

=head3 MESSAGES

	Key              Meaning                              Resolution
	client.no_config no configuration was given           pass config
	client.bad_name  the repo name is not a plain id      rename the repo in config.json

=head3 FORMAL SPECIFICATION

	pre config ≠ ⊥ ∧ name ∈ Id
	post self.name = name ∧ self.opts = opts ∨ ∅

=cut

sub new {
	my $class = shift;
	my $args = named(\@_, {
		config   => { type => 'hashref', optional => 1 },
		name     => { type => 'string', optional => 1 },
		opts     => { type => 'hashref', optional => 1 },
		logger   => { type => 'object', optional => 1 },
		settings => { type => 'hashref', optional => 1 },
		language => { type => 'string', optional => 1 },
	}, 'Client->new');

	App::FileSync::I18N::throw('client.no_config') unless $args->{config};

	# The name becomes part of the cache, log, lock and trash paths, so it
	# must be a plain id, not something like "../x".
	my ($ok, $reason) = validate_repo_name($args->{name});
	App::FileSync::I18N::throw('client.bad_name', { reason => $reason }) unless $ok;

	my $opts = $args->{opts} || {};
	my $self = bless {
		config   => $args->{config},
		name     => $args->{name},
		opts     => $opts,
		language => $args->{language},
		logger   => $args->{logger} || App::FileSync::Settings::logger(verbose => $opts->{verbose}, quiet => $opts->{quiet}),
	}, $class;

	# Read lazily unless the caller (a test, or a command that already loaded
	# them) supplies the process settings.
	$self->{settings} = $args->{settings} if exists $args->{settings};
	return $self;
}

=head2 sync

Purpose: run one sync session for the repo.

Args: none (see C<opts> in L</new>).

Returns: C<{ repo, ok, exit, summary, warnings, stats }>; with C<dry_run>,
also C<dry_run =E<gt> 1> and the planned C<actions>.  A lock refusal (here or
on the server) returns C<ok =E<gt> 0, exit =E<gt> 2, locked =E<gt> 1> rather than
raising: cron starting a run while the last one is finishing is normal.

Side Effects: changes the local tree and the master; updates the cache;
prunes this repo's local trash (unless C<no_prune>); appends to the run log,
whatever the outcome.

Usage:

	my $result = App::FileSync::Client->new(%args)->sync;

=head3 EXAMPLE

	my $result = $client->sync;
	printf "pulled %d, pushed %d\n", @{ $result->{summary} }{qw(pulled pushed)};
	print "warning: $_\n" for @{ $result->{warnings} };

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			repo     => { type => 'string' },
			ok       => { type => 'integer', memberof => [ 0, 1 ] },
			exit     => { type => 'integer', memberof => [ 0, 2, 3 ] },
			summary  => { type => 'hashref', optional => 1 },
			warnings => { type => 'arrayref', optional => 1 },
		},
	}

=head3 MESSAGES

	Key                  Meaning                                    Resolution
	client.no_repo       the repo is not in the configuration       filesync init
	client.bad_root      the sync root is not a directory           fix root in config.json
	client.no_marker     the root has no .filesync-root marker      mount the drive, or create the marker
	client.no_client_id  the configuration has no client_id         filesync init
	client.refused       the server refused the session             read the reason
	client.req.*         the server rejected a step                 read the reason
	client.hash_mismatch a transfer arrived corrupted               rerun the sync

=head3 FORMAL SPECIFICATION

	ΔFS
	sync = ⟨exit ↦ 2⟩                              if lock held elsewhere
	sync = ⟨exit ↦ 0 | 3⟩ ∧ local' ≡ master'       if the session completes
	sync raises ∧ base' = base                     otherwise

=head3 PSEUDOCODE

	look up the repo
	run the session (lock, transport, protocol)
	record the attempt in the run log, success or failure
	log a summary; return the result, or re-raise the error

=cut

sub sync {
	my ($self) = @_;

	my $repo = $self->_repo_config();
	my $result = eval { $self->_run_session($repo) };

	unless ($result) {
		# A run that started and then failed is still something cron attempted,
		# so the audit trail records it before the error escapes.
		my $error = $@;
		$self->_record_run({ exit => $EXIT_FATAL, error => strip_location($error) });
		die $error;	## no critic (ErrorHandling::RequireCarping) -- rethrow unchanged
	}

	$self->_record_run($result);

	if ($result->{ok}) {
		$self->{logger}->info('sync finished', {
			repo    => $self->{name},
			(map { $_ => ($result->{summary}{$_} || 0) } qw(pulled pushed deleted conflicts skipped bytes_sent bytes_received)),
			exit    => $result->{exit} || $EXIT_OK,
			dry_run => $result->{dry_run} ? 1 : 0,
		});
	}

	return $result;
}

=head2 log

Purpose: recent run attempts from the local run log.

Args: optional C<limit> (default 20), C<since> and C<until> (C<YYYY-MM-DD>
or epoch, inclusive), C<exits> (an exit code or arrayref of them),
C<warnings> (only runs that recorded a warning, conflict or skipped path).
All filters apply before the limit.

Returns: C<{ repo, path, runs }> (runs oldest first), plus the filters used.

Side Effects: reads the log.  A torn final line from a killed run is skipped.

Usage:

	my $log = $client->log(limit => 5, exits => [ 1, 2 ]);

=head3 EXAMPLE

	for my $run (@{ $client->log(since => '2026-10-01')->{runs} }) {
		print "$run->{ts} exit $run->{exit}\n";
	}

=head3 API SPECIFICATION

=head4 INPUT

	{
		limit    => { type => 'integer', optional => 1 },
		since    => { type => 'string', optional => 1 },
		until    => { type => 'string', optional => 1 },
		exits    => { type => 'arrayref', optional => 1 },	# a lone code is wrapped
		warnings => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref', schema => { repo => { type => 'string' }, path => { type => 'string' }, runs => { type => 'arrayref' } } }

=head3 MESSAGES

	Key        Meaning                     Resolution
	when.bad   since/until is malformed    use YYYY-MM-DD or an epoch
	io.read    the log cannot be read      check permissions

=head3 FORMAL SPECIFICATION

	log = last limit ⟨ r ∈ runs | since ≤ r.ts ≤ until ∧ (exits = ∅ ∨ r.exit ∈ exits) ∧ (¬warnings ∨ has_warnings(r)) ⟩

=head3 PSEUDOCODE

	parse the filters
	read each JSON line of the log, skipping torn ones
	keep the runs that pass every filter
	keep the newest limit; report the filters used

=cut

sub log {	## no critic (Subroutines::ProhibitBuiltinHomonyms) -- public API name
	my ($self, %raw) = @_;

	# One exit code is accepted as shorthand for a list of one.
	$raw{exits} = [ $raw{exits} ] if defined $raw{exits} && !ref $raw{exits};
	my $args = named([ %raw ], {
		limit    => { type => 'integer', optional => 1 },
		since    => { type => 'string', optional => 1 },
		until    => { type => 'string', optional => 1 },
		exits    => { type => 'arrayref', optional => 1 },
		warnings => { type => 'scalar', optional => 1 },
	}, 'Client::log');

	my $limit = ($args->{limit} && $args->{limit} > 0) ? $args->{limit} : $LOG_DEFAULT_LIMIT;
	my $since = defined $args->{since} ? parse_since($args->{since}) : undef;
	my $until = defined $args->{until} ? parse_until($args->{until}) : undef;
	my $warnings = $args->{warnings} ? 1 : 0;

	my @exits = map { $_ + 0 } @{ $args->{exits} || [] };

	my $path = $self->log_path();
	my @runs = grep {
		my $ts = $_->{ts} || 0;
		(!defined $since || $ts >= $since)
			&& (!defined $until || $ts <= $until)
			&& (!$warnings || _has_warnings($_));
	} @{ _read_jsonl($path) };

	# any's block sees its own $_, so the exit test reads the run explicitly.
	@runs = grep { my $run = $_; !@exits || any { ($run->{exit} || 0) == $_ } @exits } @runs;
	splice(@runs, 0, @runs - $limit) if @runs > $limit;

	return {
		repo => $self->{name},
		path => $path,
		runs => \@runs,
		(defined $since ? (since => $since) : ()),
		(defined $until ? (until => $until) : ()),
		(@exits ? (exits => \@exits) : ()),
		($warnings ? (warnings => 1) : ()),
	};
}

=head2 verify

Purpose: compare the local tree with the base the last successful sync
recorded.  Drift means the tree changed without being synced.

Args: optional C<deep> (hash every file rather than trusting size and mtime).

Returns: the L<App::FileSync::Verify> report, plus C<repo>.

Side Effects: reads the tree; logs a summary.  Works offline: the ignore list
is the one cached by the last sync.

Usage:

	my $report = $client->verify(deep => 1);

=head3 EXAMPLE

	my $report = $client->verify;
	print $report->{ok} ? "clean\n" : scalar(@{ $report->{modified} }) . " modified\n";

=head3 API SPECIFICATION

=head4 INPUT

	{ deep => { type => 'boolean', optional => 1 } }

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key               Meaning                                Resolution
	client.bad_root   the sync root is not a directory       fix root in config.json
	client.no_marker  the root has no .filesync-root marker  mount the drive

=head3 FORMAL SPECIFICATION

	verify = Verify(root, cache.entries, Ignore(cache.ignore ∪ {snapshots}))

=cut

sub verify {
	my $self = shift;
	my $args = named(\@_, { deep => { type => 'scalar', optional => 1 } }, 'Client::verify');

	my $root = $self->_checked_root($self->_repo_config());
	my $cache = $self->cache();
	my $patterns = ref($cache->{ignore}) eq 'ARRAY' ? $cache->{ignore} : \@App::FileSync::Config::DEFAULT_IGNORE;

	my $report = App::FileSync::Verify::verify(
		root    => $root,
		entries => $cache->{entries},
		ignore  => App::FileSync::Ignore->new(patterns => _with_reserved($patterns)),
		deep    => $args->{deep},
	);
	$report->{repo} = $self->{name};

	$self->{logger}->info('verify finished', {
		repo  => $self->{name},
		files => $report->{files},
		(map { $_ => scalar @{ $report->{$_} } } qw(modified missing extra)),
		ok    => $report->{ok} ? 1 : 0,
	});

	return $report;
}

=head2 restore

Purpose: put a path back from this repo's local trash.  The newest stored
version wins; C<list> shows them all instead.

Args: C<path>, optional C<to> (a directory; default the sync root), C<list>.

Versions are searched in this repo's trash first, then in the shared trash
that releases before 0.001.1 used, so files trashed before an upgrade can
still be restored.

Returns: with C<list>, C<{ repo, path, versions }>; otherwise
C<{ repo, path, from, to }>.

Side Effects: copies the version out; the trash entry is kept.

Usage:

	$client->restore(path => 'notes/a.txt', to => '/tmp/out');

=head3 EXAMPLE

	my $versions = $client->restore(path => 'a.txt', list => 1)->{versions};
	print "$_->{date} $_->{size}\n" for @{$versions};

=head3 API SPECIFICATION

=head4 INPUT

	{
		path => { type => 'string', min => 1 },
		to   => { type => 'string', optional => 1 },
		list => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key                 Meaning                                 Resolution
	client.unsafe       the path fails validate_relpath         fix the path
	client.no_versions  nothing of that path is in the trash    check --list
	client.not_dir      the target is not a directory           choose another
	client.exists       the destination exists                  move it aside or use --to

=head3 FORMAL SPECIFICATION

	ΔFS
	pre path ∈ SafePath ∧ versions(path) ≠ ⟨⟩ ∧ dest ∉ dom FS
	post tree'(dest) = tree(head versions(path))

=head3 PSEUDOCODE

	validate the path; list versions from the repo trash then the legacy trash
	if listing, return them
	destination := to (created) or the sync root, plus the path
	refuse to overwrite; copy the newest version out

=cut

sub restore {
	my $self = shift;
	my $args = named(\@_, {
		path => { type => 'string', optional => 1 },
		to   => { type => 'string', optional => 1 },
		list => { type => 'scalar', optional => 1 },
	}, 'Client::restore');

	my $repo = $self->_repo_config();
	my $path = $args->{path};
	my ($safe, $reason) = validate_relpath($path);
	$self->_throw('client.unsafe', { path => $path // '', reason => $reason }) unless $safe;

	my @versions = map { @{ App::FileSync::Trash::versions(root => $_, rel => $path) } }
		$self->_trash_root(), $self->_legacy_trash_root();

	if ($args->{list}) {
		return { repo => $self->{name}, path => $path, versions => [ map { App::FileSync::Trash::version_info($_) } @versions ] };
	}

	$self->_throw('client.no_versions', { path => $path, repo => $self->{name}, trash => $self->_trash_root() })
		unless @versions;

	my $to_root = (defined $args->{to} && length $args->{to}) ? $args->{to} : $repo->{root};
	ensure_dir($to_root);
	$self->_throw('client.not_dir', { path => $to_root }) unless -d $to_root;

	my $destination = File::Spec->catfile($to_root, split m{/}, $path);
	$self->_throw('client.exists', { path => $destination }) if -e $destination || -l $destination;

	App::FileSync::Trash::restore(src => $versions[0], to => $destination);

	my %done = (path => $path, from => $versions[0], to => $destination);
	$self->{logger}->info('restored path', { repo => $self->{name}, %done });
	return { repo => $self->{name}, %done };
}

=head2 snapshot_create

Purpose: take today's snapshot of a replica.

Args: optional C<keep> (how many snapshots to keep; default the repo's
C<snapshot_keep>, else 14; 0 keeps all).

Returns: C<{ repo, ok, exit, keep, pruned, older, ... }> with the
L<App::FileSync::Snapshot/create> result merged in; C<exit =E<gt> 2> when
another run holds the lock.

Side Effects: holds the repo lock; creates a snapshot; prunes old ones when a
new one was made.

Usage:

	my $made = $client->snapshot_create(keep => 7);

=head3 EXAMPLE

	my $made = $client->snapshot_create;
	print $made->{created} ? "snapshot $made->{date}\n" : "already have $made->{date}\n";

=head3 API SPECIFICATION

=head4 INPUT

	{ keep => { type => 'integer', min => 0, optional => 1 } }

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key                 Meaning                           Resolution
	client.not_replica  the repo is a client              snapshots are for replicas
	snapshot.*          see App::FileSync::Snapshot

=head3 FORMAL SPECIFICATION

	pre role = replica
	created ∧ keep > 0 ⇒ #snapshots' ≤ keep

=head3 PSEUDOCODE

	refuse unless the repo is a replica
	take the lock, or report that another run holds it
	choose the mode and the number to keep
	create today's snapshot; prune if one was made

=cut

sub snapshot_create {
	my $self = shift;
	my $args = named(\@_, { keep => { type => 'integer', min => 0, optional => 1 } }, 'Client::snapshot_create');

	my $repo = $self->_repo_config();
	$self->_throw('client.not_replica', { repo => $self->{name} })
		unless ($repo->{role} || $ROLE_CLIENT) eq $ROLE_REPLICA;

	my $lock = $self->_lock() or return $self->_locked_result();

	my $mode = (defined $repo->{snapshot_mode} && length $repo->{snapshot_mode})
		? $repo->{snapshot_mode}
		: App::FileSync::Snapshot::default_mode();
	my $keep = $args->{keep} // $repo->{snapshot_keep} // $SNAPSHOT_KEEP;

	my $created = App::FileSync::Snapshot::create(root => $repo->{root}, mode => $mode);
	my $pruned = ($created->{created} && $keep > 0)
		? App::FileSync::Snapshot::prune(root => $repo->{root}, keep => $keep)
		: { removed => [], kept => [] };

	return {
		repo   => $self->{name},
		ok     => 1,
		exit   => $EXIT_OK,
		%{$created},
		keep   => $keep,
		pruned => $pruned->{removed},
		older  => $pruned->{kept},
	};
}

=head2 snapshot_list

Purpose: a replica's snapshots, newest first.

Args: none.

Returns: C<{ repo, snapshots }>.

Side Effects: walks every snapshot to count it.

Usage:

	my $list = $client->snapshot_list;

=head3 EXAMPLE

	print "$_->{date}\n" for @{ $client->snapshot_list->{snapshots} };

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'hashref', schema => { repo => { type => 'string' }, snapshots => { type => 'arrayref' } } }

=head3 MESSAGES

	Key              Meaning                            Resolution
	client.no_repo   the repo is not in the config      filesync init

=head3 FORMAL SPECIFICATION

	snapshot_list = ⟨repo ↦ name, snapshots ↦ Snapshot::list(root)⟩

=cut

sub snapshot_list {
	my ($self) = @_;

	return { repo => $self->{name}, snapshots => App::FileSync::Snapshot::list(root => $self->_repo_config()->{root}) };
}

=head2 snapshot_restore

Purpose: copy a snapshot (or one path of it) back.

Args: C<date>, optional C<path> (one relative path; default everything) and
C<to> (default the sync root, which rolls the replica back).

Returns: the L<App::FileSync::Snapshot/restore> result plus C<repo>, C<ok>,
C<exit> and C<into_root>; C<exit =E<gt> 2> when another run holds the lock.

Side Effects: holds the repo lock; replaces files under C<to>.

Usage:

	$client->snapshot_restore(date => '2026-10-20', path => 'notes');

=head3 EXAMPLE

	my $done = $client->snapshot_restore(date => '2026-10-20', to => '/tmp/export');
	print "$done->{files} files\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		date => { type => 'string', optional => 1 },
		path => { type => 'string', optional => 1 },
		to   => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

See L<App::FileSync::Snapshot/restore>.

=head3 FORMAL SPECIFICATION

	ΔFS
	into_root ⇔ to = root
	tree'(to / p) = tree(snapshot(date) / p) for each restored p

=cut

sub snapshot_restore {
	my $self = shift;
	my $args = named(\@_, {
		date => { type => 'string', optional => 1 },
		path => { type => 'string', optional => 1 },
		to   => { type => 'string', optional => 1 },
	}, 'Client::snapshot_restore');

	my $repo = $self->_repo_config();
	my $lock = $self->_lock() or return $self->_locked_result();

	my $to = (defined $args->{to} && length $args->{to}) ? $args->{to} : $repo->{root};
	my $result = App::FileSync::Snapshot::restore(
		root  => $repo->{root},
		date  => $args->{date},
		paths => (defined $args->{path} && length $args->{path}) ? [ $args->{path} ] : [],
		to    => $to,
	);

	return { repo => $self->{name}, ok => 1, exit => $EXIT_OK, into_root => ($to eq $repo->{root} ? 1 : 0), %{$result} };
}

=head2 cache_path

Documented with L</log_path> below.

=head2 log_path

Purpose: where this repo's cache and run log live.

Args: none.

Returns: F<HOME/cache/NAME.json>, F<HOME/logs/NAME.jsonl>.

Side Effects: none.

Usage:

	my $path = $client->cache_path;

=head3 EXAMPLE

	print $client->log_path, "\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key              Meaning                        Resolution
	config.no_home   no home directory is known     set HOME or FILESYNC_HOME

=head3 FORMAL SPECIFICATION

	cache_path = home / "cache" / name ⁀ ".json"
	log_path   = home / "logs" / name ⁀ ".jsonl"

=cut

sub cache_path {
	my ($self) = @_;

	return $self->_home_file('cache', "$self->{name}.json");
}

sub log_path {
	my ($self) = @_;

	return $self->_home_file('logs', "$self->{name}.jsonl");
}

=head2 cache

Purpose: the cached base and last-run summary.

Args: none.

Returns: the cache hashref, always with an C<entries> hashref; an empty cache
when there is none or it is unreadable (the next sync rebuilds it).

Side Effects: reads the cache file.

Usage:

	my $last = $client->cache->{last_run};

=head3 EXAMPLE

	my $cache = $client->cache;
	printf "%d files at the last sync\n", scalar keys %{ $cache->{entries} };

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'hashref', schema => { entries => { type => 'hashref' } } }

=head3 MESSAGES

None; a damaged cache is treated as empty.

=head3 FORMAL SPECIFICATION

	cache = json(FS(cache_path)) if that parses to an object, else ⟨entries ↦ ∅⟩

=cut

sub cache {
	my ($self) = @_;

	my $path = $self->cache_path();
	my $cache = -e $path ? eval { json_decode(read_text($path)) } : undef;
	$cache = {} unless ref($cache) eq 'HASH';
	$cache->{entries} = {} unless ref($cache->{entries}) eq 'HASH';

	return $cache;
}

# _run_session
# Purpose:     one attempt: check the root, lock, connect, run the session.
# Entry:       $repo is this repo's client config.
# Exit:        returns a result hashref; a lock refusal is a result, not an
#              exception.
# Side effects: holds the lock for the session; starts and closes the
#              transport.  When the transport failed, its own error text
#              ("Permission denied (publickey)", a host key mismatch) is
#              raised instead of the protocol error it caused.
sub _run_session :Private {
	my ($self, $repo) = @_;

	my $root = $self->_checked_root($repo);
	my $lock = $self->_lock() or return $self->_locked_result();

	my $transport = $self->_transport($repo);
	my $connection = App::FileSync::Protocol->new(in => $transport->reader(), out => $transport->writer());

	my $result = eval { $self->_session($connection, $repo, $root) };
	my $error = $@;
	$transport->close();
	return $result if $result;

	if ($connection->transport_failed) {
		my $text = eval { $transport->error_text() };
		$error = "$text\n" if defined $text && length $text;
	}
	die $error;	## no critic (ErrorHandling::RequireCarping) -- rethrow unchanged
}

# _session
# Purpose:     the protocol conversation, from hello to done.
# Entry:       $connection is open; $root has been checked.
# Exit:        returns the result hashref.
# Side effects: scans the tree; applies the plan; saves the cache and prunes
#              the trash after a real (not dry) run.
sub _session :Private {
	my ($self, $connection, $repo, $root) = @_;

	my $opts = $self->{opts};
	my $client_id = $self->{config}{client_id};
	$self->_throw('client.no_client_id') unless defined $client_id && length $client_id;

	$connection->send({
		cmd              => 'hello',
		proto            => $PROTOCOL_VERSION,
		client           => $client_id,
		host             => Sys::Hostname::hostname(),
		os               => $^O,
		role             => $repo->{role} || $ROLE_CLIENT,
		repo             => $repo->{remote_repo} || $self->{name},
		case_insensitive => _case_insensitive($root),
		now              => time,
		dry_run          => $opts->{dry_run} ? 1 : 0,
		force            => $opts->{force} ? 1 : 0,
	});

	my $hello = $connection->recv();
	unless ($hello->{ok}) {
		my $reason = $hello->{error} || $self->i18n('client.unknown_reason');
		# Lock contention on the server is as normal as it is here.
		return { %{ $self->_locked_result($reason) }, summary => { map { $_ => 0 } qw(pulled pushed deleted conflicts) } }
			if ($hello->{code} // '') eq 'locked';
		$self->_throw('client.refused', { reason => $reason });
	}

	my $policy = $hello->{policy} || {};
	my $patterns = _with_reserved($policy->{ignore} || []);
	my $ignore = App::FileSync::Ignore->new(patterns => $patterns, case_insensitive => $hello->{case_insensitive} ? 1 : 0);

	App::FileSync::Scan::clean_stale_temps(root => $root);
	my ($manifest, $stats, $skipped) = @{ App::FileSync::Scan::scan(
		root   => $root,
		ignore => $ignore,
		cache  => $self->cache()->{entries},
	) }{qw(manifest stats skipped)};

	$self->_send_manifest($connection, $manifest);

	my $plan = $self->_request($connection, { cmd => 'plan' }, 'client.req.plan', {});
	my @actions = @{ $plan->{actions} || [] };
	my @warnings = (@{ $plan->{warnings} || [] },
		map { $self->i18n('client.skipped', { path => $_, reason => $skipped->{$_} }) } sort keys %{$skipped});

	my %planned = (
		pulled    => scalar(grep { $_->{a} eq 'pull' } @actions),
		pushed    => scalar(grep { $_->{a} eq 'push' } @actions),
		deleted   => scalar(grep { $_->{a} =~ /\Adelete_/ } @actions),
		conflicts => scalar(grep { $_->{a} eq 'conflict' } @actions),
	);
	$self->{logger}->debug('plan received', {
		repo => $self->{name}, actions => scalar @actions, deletions => $planned{deleted},
		conflicts => $planned{conflicts}, dry_run => $opts->{dry_run} ? 1 : 0,
	});

	my $summary = { (map { $_ => 0 } qw(pulled pushed deleted conflicts delta_pulled delta_pushed)), skipped => scalar(keys %{$skipped}) };
	my %result = (repo => $self->{name}, ok => 1, summary => $summary, warnings => \@warnings, stats => $stats);

	if ($opts->{dry_run}) {
		$self->_request($connection, { cmd => 'done' }, 'client.req.end', {});
		# Nothing but headers and control messages has crossed the connection.
		%{$summary} = (%{$summary}, %planned, bytes_sent => $connection->bytes_sent, bytes_received => $connection->bytes_received);
		return { %result, exit => @warnings ? $EXIT_WARNINGS : $EXIT_OK, dry_run => 1, actions => \@actions };
	}

	if ($opts->{verbose}) {
		for my $action (@actions) {
			(my $verb = $action->{a}) =~ tr/_/ /;
			print $self->i18n('client.verbose_action', { verb => $verb, path => $action->{p} }), "\n";
		}
	}

	my %after = %{$manifest};
	$self->_apply($connection, $_, \%after, $summary) for @actions;

	$self->_request($connection, { cmd => 'done' }, 'client.req.end', {});
	@{$summary}{qw(delta_pulled delta_pushed)} = map { $self->{$_} || 0 } qw(delta_pulled delta_pushed);
	@{$summary}{qw(bytes_sent bytes_received)} = ($connection->bytes_sent, $connection->bytes_received);

	$self->_save_cache(\%after, $summary, $patterns);
	$self->_prune_local_trash($repo) unless $opts->{no_prune};

	return { %result, exit => @warnings ? $EXIT_WARNINGS : $EXIT_OK };
}

# _apply
# Purpose:     carry out one planned action.
# Entry:       $after is the manifest being turned into the new base.
# Exit:        returns 1.
# Side effects: transfers, deletes or resolves; counts it in $summary.
sub _apply :Private {
	my ($self, $connection, $action, $after, $summary) = @_;

	my ($type, $path) = @{$action}{qw(a p)};
	if ($type eq 'pull') {
		$self->_pull($connection, $action, $after);
		$summary->{pulled}++;
	} elsif ($type eq 'push') {
		$self->_push($connection, $action);
		$summary->{pushed}++;
	} elsif ($type eq 'delete_remote') {
		$self->_request($connection, { cmd => 'del', p => $path }, 'client.req.delete', { path => $path });
		delete $after->{$path};
		$summary->{deleted}++;
	} elsif ($type eq 'delete_local') {
		$self->_delete_local($path);
		$self->_request($connection, { cmd => 'ack', p => $path, deleted => 1 }, 'client.req.ack_delete', { path => $path });
		delete $after->{$path};
		$summary->{deleted}++;
	} elsif ($type eq 'conflict') {
		$self->_resolve_conflict($connection, $action, $after);
		$summary->{conflicts}++;
	} else {
		$self->_throw('client.unknown_action', { action => $type, path => $path });
	}

	return 1;
}

# _send_manifest
# Purpose:     send the scanned manifest in parts.
# Entry:       $manifest maps paths to entries.
# Exit:        returns 1.
# Side effects: one request per $MANIFEST_CHUNK entries (at least one, so an
#              empty tree still sends an empty manifest).
sub _send_manifest :Private {
	my ($self, $connection, $manifest) = @_;

	my @entries = map { { p => $_, %{ $manifest->{$_} } } } sort keys %{$manifest};
	my $parts = @entries ? int((@entries - 1) / $MANIFEST_CHUNK) + 1 : 1;

	for my $part (0 .. $parts - 1) {
		my @slice = splice(@entries, 0, $MANIFEST_CHUNK);
		$self->_request($connection, { cmd => 'manifest', part => $part, of => $parts, entries => \@slice },
			'client.req.manifest', {});
	}

	return 1;
}

# _pull
# Purpose:     fetch a master file (or directory) the plan says to pull.
# Entry:       $action has p, t and maybe h (the expected hash).
# Exit:        returns 1.
# Side effects: replaces the local path; acknowledges it; records it in
#              $after.  Tries a delta first when there is a local version.
sub _pull :Private {
	my ($self, $connection, $action, $after) = @_;

	my $path = $action->{p};
	my $abs  = $self->_abs($path);

	if (($action->{t} || $TYPE_FILE) eq $TYPE_DIR) {
		ensure_dir($abs);
		$self->_request($connection, { cmd => 'ack', p => $path, t => $TYPE_DIR }, 'client.req.ack_dir', { path => $path });
		$after->{$path} = { t => $TYPE_DIR };
		return 1;
	}

	return 1 if $self->_pull_delta($connection, $action, $after, $abs);

	my $receipt = $self->_receive($abs, sub {
		my ($write) = @_;
		my ($offset, %server) = (0);
		while (1) {
			my $header = $self->_request($connection, { cmd => 'get', p => $path, off => $offset, max => $CHUNK },
				'client.req.get', { path => $path });
			my $bytes = $connection->read_data($header);
			$write->($bytes);
			$offset += length $bytes;
			$server{$_} = $header->{$_} for grep { defined $header->{$_} } qw(s m mode h);
			last if $header->{eof};
		}
		return \%server;
	});

	return $self->_finish_pull($connection, $action, $after, $abs, $receipt);
}

# _pull_delta
# Purpose:     receive only the blocks that differ from the local copy.
# Entry:       $abs is the local path.
# Exit:        returns 1 if the file was pulled as a delta, 0 (without
#              touching the connection beyond the signature) when a
#              whole-file pull is the right answer.
# Side effects: as _pull.
sub _pull_delta :Private {
	my ($self, $connection, $action, $after, $abs) = @_;

	return 0 if $self->{opts}{no_delta} || !-f $abs || -l $abs;
	my $local_size = -s $abs;
	return 0 if $local_size < $App::FileSync::Delta::MIN_SIZE;

	my $path = $action->{p};
	my $block = App::FileSync::Delta::block_size($local_size);
	my $signature = App::FileSync::Delta::signature($abs, $block) or return 0;

	my $reply = $self->_request($connection, {
		cmd => 'dsig',
		p   => $path,
		s   => $local_size,
		b   => $block,
		n   => scalar @{ $signature->{blocks} },
		(defined $action->{h} ? (h => $action->{h}) : ()),
	}, 'client.req.signature', { path => $path }, App::FileSync::Delta::encode_signature($signature));
	return 0 unless $reply->{delta};

	my $old = open_file($abs, '<:raw');
	my $receipt = $self->_receive($abs, sub {
		my ($write) = @_;
		while (1) {
			my $op = $self->_request($connection, { cmd => 'dop', p => $path }, 'client.req.get', { path => $path });
			last if $op->{done};
			$write->($self->_delta_bytes($connection, $op, $old, $abs, $path, $local_size));
		}
		return { map { $_ => $reply->{$_} } grep { defined $reply->{$_} } qw(s m mode h) };
	}, $old);

	$self->_finish_pull($connection, $action, $after, $abs, $receipt);
	$self->{delta_pulled}++;
	return 1;
}

# _delta_bytes
# Purpose:     the bytes one pull-delta record stands for.
# Entry:       $op is a reply with op copy (off, len) or lit (data follows).
# Exit:        returns the bytes.
# Side effects: reads the local old version or the connection; raises
#              client.bad_copy or client.bad_op for anything malformed.
sub _delta_bytes :Private {
	my ($self, $connection, $op, $old, $abs, $path, $local_size) = @_;

	my $kind = $op->{op} // '';
	return $connection->read_data($op) if $kind eq 'lit';
	$self->_throw('client.bad_op', { path => $path }) unless $kind eq 'copy';

	my ($offset, $length) = @{$op}{qw(off len)};
	$self->_throw('client.bad_copy', { path => $path })
		unless defined $offset && $offset =~ /\A\d+\z/ && defined $length && $length =~ /\A\d+\z/
			&& $offset + $length <= $local_size;

	return '' unless $length;
	seek($old, $offset, 0);
	return App::FileSync::Delta::read_exact($old, $length, $abs);
}

# _receive
# Purpose:     the shared body of every pull: a temporary file beside the
#              target, a running hash, and cleanup on failure.
# Entry:       $fill->($write) reads from the server, calling $write->($bytes)
#              for each piece, and returns what the server said about the
#              file ({ s, m, mode, h }); @close are extra handles to close.
# Exit:        returns { temp, hash, written, server }.
# Side effects: creates the temporary file; on any error removes it, closes
#              @close and re-raises.
sub _receive :Private {
	my ($self, $abs, $fill, @close) = @_;

	my ($out, $temp) = @{ temp_file(dirname($abs)) };
	my $sha = Digest::SHA->new(256);
	my $written = 0;

	my $server = eval {
		my $info = $fill->(sub {
			my ($bytes) = @_;
			print {$out} $bytes or $self->_throw('io.write', { path => $temp, error => os_error() });
			$sha->add($bytes);
			$written += length $bytes;
		});
		close $out;
		$info;
	};
	my $error = $@;
	eval { close $_ } for grep { defined } @close;

	unless ($server) {
		eval { close $out };
		eval { unlink $temp };
		die $error;	## no critic (ErrorHandling::RequireCarping) -- rethrow unchanged
	}

	return { temp => $temp, hash => $sha->hexdigest(), written => $written, server => $server };
}

# _finish_pull
# Purpose:     verify a received file, install it, and acknowledge it.
# Entry:       $receipt is from _receive.
# Exit:        returns 1.
# Side effects: replaces the local path (whatever was there: a file, a
#              symlink or an empty directory); records the new entry in
#              $after.  A mismatch removes the temporary file and raises.
sub _finish_pull :Private {
	my ($self, $connection, $action, $after, $abs, $receipt) = @_;

	my ($path, $server, $got) = ($action->{p}, $receipt->{server}, $receipt->{hash});
	my $expected = $action->{h} // $server->{h};

	my ($key, %args) =
		  (defined $expected && $got ne $expected) ? ('client.hash_mismatch', expected => $expected, got => $got)
		: (defined $server->{s} && $receipt->{written} != $server->{s}) ? ('client.size_mismatch', expected => $server->{s}, got => $receipt->{written})
		: ();
	if ($key) {
		eval { unlink $receipt->{temp} };
		$self->_throw($key, { path => $path, %args });
	}

	install_file($receipt->{temp}, $abs, $server->{m}, $server->{mode});

	my %entry = (h => $got, s => $receipt->{written}, m => $server->{m}, mode => $server->{mode});
	$self->_request($connection, { cmd => 'ack', p => $path, %entry }, 'client.req.ack', { path => $path });
	$after->{$path} = { t => $TYPE_FILE, %entry };
	return 1;
}

# _push
# Purpose:     send a local file (or directory) the plan says to push.
# Entry:       $action has p, t, h and, for a conflict this side won,
#              loser_name.
# Exit:        returns 1.
# Side effects: transfers the file, as a delta when that is cheaper (never
#              for a conflict, where the server must first move its version
#              aside).
sub _push :Private {
	my ($self, $connection, $action) = @_;

	my $path = $action->{p};
	my $abs  = $self->_abs($path);

	if (($action->{t} || $TYPE_FILE) eq $TYPE_DIR) {
		$self->_request($connection, { cmd => 'mkdir', p => $path }, 'client.req.mkdir', { path => $path });
		return 1;
	}

	my @stat = Time::HiRes::stat($abs);
	$self->_throw('client.cannot_stat', { path => $abs, error => os_error() }) unless @stat;
	my %file = (s => $stat[7], m => $stat[9], mode => $stat[2] & $MODE_MASK);

	return 1 if !$action->{loser_name} && $self->_push_delta($connection, $path, $abs, \%file, $action->{h});

	my $in = open_file($abs, '<:raw');

	# The server acknowledges the header before any chunk is sent; reading it
	# here keeps the lock-step protocol aligned.
	$self->_request($connection, {
		cmd => 'put', p => $path, t => $TYPE_FILE, %file, h => $action->{h},
		($action->{loser_name} ? (conflict_name => $action->{loser_name}) : ()),
	}, 'client.req.put', { path => $path });

	while (read($in, my $buffer, $CHUNK)) {
		$self->_request($connection, { cmd => 'chunk', p => $path }, 'client.req.chunk', { path => $path }, $buffer);
	}
	close $in;

	$self->_request($connection, { cmd => 'chunk_end', p => $path }, 'client.req.store', { path => $path });
	return 1;
}

# _push_delta
# Purpose:     send only the blocks that changed since the master's version.
# Entry:       %{$file} has s, m, mode; $hash is the planned hash.
# Exit:        returns 1 if pushed as a delta, 0 when a whole-file put is
#              cheaper or there is nothing to reuse.
# Side effects: spools the delta to a temporary file beside $abs.
sub _push_delta :Private {
	my ($self, $connection, $path, $abs, $file, $hash) = @_;

	return 0 if $self->{opts}{no_delta} || !defined $hash || $file->{s} < $App::FileSync::Delta::MIN_SIZE;

	my $reply = $self->_request($connection, { cmd => 'sig', p => $path }, 'client.req.signature', { path => $path });
	return 0 unless $reply->{delta};

	my $blocks = App::FileSync::Delta::decode_signature($connection->read_data($reply), $reply->{n});

	my $spool = File::Temp->new(TEMPLATE => "${TEMP_PREFIX}delta-XXXXXXXX", DIR => dirname($abs), UNLINK => 1);
	binmode $spool;
	my $stats = App::FileSync::Delta::diff($abs, { size => $reply->{s}, blocklen => $reply->{b}, blocks => $blocks }, $spool);

	my $estimated = $stats->{literal} + $DELTA_OP_BYTES * $stats->{ops} + $DELTA_OVERHEAD;
	return 0 if $estimated >= $file->{s};

	$self->_request($connection, { cmd => 'delta', p => $path, %{$file}, h => $hash }, 'client.req.delta', { path => $path });

	seek($spool, 0, 0);
	while (my ($type, @rest) = App::FileSync::Delta::read_op($spool)) {
		my ($message, $bytes) = $type eq 'copy'
			? ({ cmd => 'dcopy', p => $path, off => $rest[0], len => $rest[1] })
			: ({ cmd => 'dlit', p => $path }, $rest[0]);
		$self->_request($connection, $message, 'client.req.delta_data', { path => $path }, $bytes);
	}

	$self->_request($connection, { cmd => 'delta_end', p => $path }, 'client.req.store', { path => $path });
	$self->{delta_pushed}++;
	return 1;
}

# _resolve_conflict
# Purpose:     carry out a conflict resolution.
# Entry:       $action has p, winner (client or remote), winner_type, h,
#              loser_name (when the losing side is a file).
# Exit:        returns 1.
# Side effects: when the master won, moves the local version aside under
#              loser_name and pulls; when this side won, pushes (the server
#              moves its version aside).
sub _resolve_conflict :Private {
	my ($self, $connection, $action, $after) = @_;

	my ($path, $loser) = @{$action}{qw(p loser_name)};
	my %winner = (p => $path, t => $action->{winner_type} || $TYPE_FILE, (defined $action->{h} ? (h => $action->{h}) : ()));

	return $self->_push($connection, { %winner, loser_name => $loser }) if $action->{winner} ne 'remote';

	my $abs = $self->_abs($path);
	if ((-e $abs || -l $abs) && defined $loser) {
		my $conflict = $self->_abs($loser);
		$self->_throw('client.conflict_exists', { path => $conflict }) if -e $conflict || -l $conflict;
		ensure_dir(dirname($conflict));
		eval { rename $abs, $conflict; 1 }
			or $self->_throw('client.conflict_move', { path => $path, to => $loser, error => os_error($@) });
		$after->{$loser} = delete $after->{$path};
	}

	return $self->_pull($connection, \%winner, $after);
}

# _delete_local
# Purpose:     remove a local path the master deleted.
# Entry:       $path is relative.
# Exit:        returns 1.
# Side effects: moves the path into this repo's local trash.
sub _delete_local :Private {
	my ($self, $path) = @_;

	my $abs = $self->_abs($path);
	return 1 unless -e $abs || -l $abs;

	App::FileSync::Trash::move_to_trash(src => $abs, rel => $path, root => $self->_trash_root(), epoch => time);
	return 1;
}

# _request
# Purpose:     one lock-step exchange: send, receive, insist on ok.
# Entry:       $key is the catalogue key for a refusal, $args its arguments;
#              $bytes, when defined, is sent as a data payload.
# Exit:        returns the reply.
# Side effects: raises $key with the server's reason.
sub _request :Private {
	my ($self, $connection, $message, $key, $args, $bytes) = @_;

	defined $bytes ? $connection->send_data($message, $bytes) : $connection->send($message);
	my $reply = $connection->recv();
	$self->_throw($key, { %{$args}, reason => $reply->{error} || $self->i18n('client.unknown_reason') })
		unless $reply->{ok};

	return $reply;
}

# _abs
# Purpose:     the local path for a relative path from the server.
# Entry:       $path came over the wire.
# Exit:        returns ROOT/path.
# Side effects: raises client.unsafe for a path that could escape the root.
sub _abs :Private {
	my ($self, $path) = @_;

	my ($ok, $reason) = validate_relpath($path);
	$self->_throw('client.unsafe', { path => $path // '', reason => $reason }) unless $ok;
	return File::Spec->catfile($self->_repo_config()->{root}, split m{/}, $path);
}

# _transport
# Purpose:     build the transport the repo's config asks for.
# Entry:       $repo is this repo's client config.
# Exit:        returns a started transport.
# Side effects: starts the server (locally or over ssh).  Per-repo SSH
#              settings fall back to the process settings.
sub _transport :Private {
	my ($self, $repo) = @_;

	my $type = $repo->{transport} || ($repo->{server_root} ? 'local' : 'ssh');
	my %common = (
		repo   => $repo->{remote_repo} || $self->{name},
		client => $self->{config}{client_id},
		role   => $repo->{role} || $ROLE_CLIENT,
	);

	if ($type eq 'local') {
		$self->_throw('client.need_server_root', { repo => $self->{name} })
			unless defined $repo->{server_root} && length $repo->{server_root};
		return App::FileSync::Transport::Local->new(%common, root => $repo->{server_root}, server_bin => $repo->{server_bin});
	}

	$self->_throw('client.bad_transport', { transport => $type, repo => $self->{name} }) unless $type eq 'ssh';
	$self->_throw('client.need_server', { repo => $self->{name} }) unless defined $repo->{server} && length $repo->{server};

	my $ssh = ref($self->{config}{ssh}) eq 'HASH' ? $self->{config}{ssh} : {};
	my $settings = $self->_settings();
	my $either = sub { my ($own, $fallback) = @_; (defined $own && length $own) ? $own : (defined $fallback && length $fallback) ? $fallback : undef };

	return App::FileSync::Transport::SSH->new(
		%common,
		server            => $repo->{server},
		port              => $repo->{port},
		identity          => $either->($repo->{identity},       $settings->{ssh_identity}),
		known_hosts       => $either->($repo->{known_hosts},    $settings->{ssh_known_hosts}),
		server_command    => $either->($repo->{server_command}, $settings->{server_command}),
		host_key_checking => $repo->{host_key_checking},
		command           => $ssh->{command},
		extra_args        => $ssh->{extra_args},
	);
}

# _settings
# Purpose:     the process settings, read once per client.
# Entry:       none.
# Exit:        returns a hashref.
# Side effects: reads the settings file the first time.  A bad settings
#              file is reported here rather than ignored: it decides which
#              key and program a sync uses.
sub _settings :Private {
	my ($self) = @_;

	$self->{settings} = App::FileSync::Settings::load() unless exists $self->{settings};
	return $self->{settings} || {};
}

# _record_run
# Purpose:     append one line per attempt to the run log, so "filesync log"
#              can audit what cron tried even when it failed or never got
#              the lock.
# Entry:       $result is a sync result or { exit, error }.
# Exit:        returns 1 if recorded, 0 if not.
# Side effects: appends (on a fresh line, if a killed run left a torn one)
#              and trims the log.  A failure is logged as a warning: losing
#              the audit line must not fail the sync.
sub _record_run :Private {
	my ($self, $result) = @_;

	my $summary = ref($result->{summary}) eq 'HASH' ? $result->{summary} : {};
	my $entry = {
		ts       => time,
		exit     => ($result->{exit} // $EXIT_OK) + 0,
		dry_run  => $result->{dry_run} ? 1 : 0,
		summary  => { map { $_ => ($summary->{$_} || 0) } @SUMMARY_KEYS },
		warnings => [ map { strip_location($_) } @{ $result->{warnings} || [] } ],
		($result->{locked} ? (locked => 1) : ()),
	};
	my $error = strip_location($result->{error});
	$entry->{error} = $error if length $error;

	my $path = $self->log_path();
	my $ok = eval { append_line($path, json_encode($entry)); $self->_trim_log($path); 1 };
	$self->{logger}->warn($self->i18n('client.record_failed', { path => $path, error => strip_location($@) })) unless $ok;

	return $ok ? 1 : 0;
}

# _trim_log
# Purpose:     keep only the newest $LOG_LIMIT lines.
# Entry:       $path exists.
# Exit:        returns 1 if trimmed, else 0.
# Side effects: rewrites the log atomically when it is too long.
sub _trim_log :Private {
	my ($self, $path) = @_;

	my @lines = split /^/m, read_text($path);
	return 0 if @lines <= $LOG_LIMIT;

	write_atomic($path, join('', @lines[ -$LOG_LIMIT .. -1 ]));
	return 1;
}

# _save_cache
# Purpose:     record the new base after a successful sync.
# Entry:       $entries is the post-sync manifest; $patterns the ignore list
#              used.
# Exit:        returns 1.
# Side effects: rewrites the cache atomically.  The ignore list is kept so
#              verify can scan with the same exclusions when it runs offline.
sub _save_cache :Private {
	my ($self, $entries, $summary, $patterns) = @_;

	write_atomic($self->cache_path(), json_encode({
		version  => 1,
		entries  => $entries,
		ignore   => $patterns,
		last_run => { ts => time, summary => $summary },
	}) . "\n");

	return 1;
}

# _prune_local_trash
# Purpose:     drop this repo's trashed files older than local_trash_days.
# Entry:       $repo is this repo's client config.
# Exit:        returns 1.
# Side effects: removes old day buckets from this repo's trash, and from
#              the legacy shared trash with the default retention (it can
#              no longer be attributed to one repo's setting).
sub _prune_local_trash :Private {
	my ($self, $repo) = @_;

	App::FileSync::Trash::prune(root => $self->_trash_root(), days => $repo->{local_trash_days} // $TRASH_DAYS, now => time);
	App::FileSync::Trash::prune(root => $self->_legacy_trash_root(), days => $TRASH_DAYS, now => time);
	return 1;
}

# _repo_config
# Purpose:     this repo's entry in the client config.
# Entry:       none.
# Exit:        returns the hashref.
# Side effects: raises client.no_repo.
sub _repo_config :Private {
	my ($self) = @_;

	my $repo = $self->{config}{repos}{ $self->{name} };
	$self->_throw('client.no_repo', { repo => $self->{name}, path => App::FileSync::Config::client_config_path() })
		unless ref($repo) eq 'HASH';
	return $repo;
}

# _checked_root
# Purpose:     the sync root, after checking it is safe to sync.
# Entry:       $repo is this repo's client config.
# Exit:        returns the root.
# Side effects: raises client.bad_root or client.no_marker.  The marker
#              guards against syncing an unmounted drive's empty mount
#              point, which would look like every file was deleted.
sub _checked_root :Private {
	my ($self, $repo) = @_;

	my $root = $repo->{root};
	$self->_throw('client.bad_root', { repo => $self->{name}, root => $root // '(unset)' })
		unless defined $root && length $root && -d $root;
	$self->_throw('client.no_marker', { root => $root }) unless -e File::Spec->catfile($root, $ROOT_MARKER);
	return $root;
}

# _lock / _locked_result
# Purpose:     take this repo's run lock; describe a refusal.
# Entry:       $reason optionally overrides the refusal text.
# Exit:        _lock returns the held handle or undef; _locked_result a
#              result with exit 2.
# Side effects: _lock creates the lock file.
sub _lock :Private {
	my ($self) = @_;

	return App::FileSync::Lock::acquire(path => $self->_home_file('locks', "$self->{name}.lock"), nonblock => 1);
}

sub _locked_result :Private {
	my ($self, $reason) = @_;

	return {
		repo   => $self->{name},
		ok     => 0,
		exit   => $EXIT_LOCKED,
		locked => 1,
		error  => $reason // $self->i18n('client.locked', { repo => $self->{name} }),
	};
}

# _home_file
# Purpose:     a file under the client's home directory.
# Entry:       directory and file names.
# Exit:        returns the path.
# Side effects: raises config.no_home when there is no home.
sub _home_file :Private {
	my ($self, @parts) = @_;

	return File::Spec->catfile(App::FileSync::Config::home_dir(), @parts);
}

# _trash_root / _legacy_trash_root
# Purpose:     this repo's local trash, and the shared one older releases used.
# Entry:       none.
# Exit:        returns the directory.
# Side effects: none.
sub _trash_root :Private {
	my ($self) = @_;

	return File::Spec->catdir(App::FileSync::Config::home_dir(), 'trash', $TRASH_REPOS, $self->{name});
}

sub _legacy_trash_root :Private {
	return File::Spec->catdir(App::FileSync::Config::home_dir(), 'trash');
}

# _with_reserved
# Purpose:     an ignore list that always covers the snapshot directory.
# Entry:       $patterns is an arrayref (not changed).
# Exit:        returns a new arrayref.
# Side effects: none.  A replica's snapshots live inside its root; the
#              pattern is reserved so it applies even to a repo created
#              before snapshots existed, whose stored list lacks it.
sub _with_reserved :Private {
	my ($patterns) = @_;

	return [ @{$patterns}, (any { $_ eq $SNAPSHOT_DIR } @{$patterns}) ? () : $SNAPSHOT_DIR ];
}

# _has_warnings
# Purpose:     whether a logged run carried a warning.
# Entry:       $entry is a run-log entry.
# Exit:        returns 1 or 0.
# Side effects: none.  Older entries may predate one of the fields, so a
#              warning, a conflict or a skipped path each count.
sub _has_warnings :Private {
	my ($entry) = @_;

	my $summary = $entry->{summary} || {};
	return ((ref($entry->{warnings}) eq 'ARRAY' && @{ $entry->{warnings} })
		|| ($summary->{conflicts} || 0) > 0
		|| ($summary->{skipped} || 0) > 0) ? 1 : 0;
}

# _read_jsonl
# Purpose:     the JSON objects in a line-per-record file.
# Entry:       $path may not exist.
# Exit:        returns an arrayref of hashrefs.
# Side effects: reads the file; lines that are not objects (a torn last
#              line) are skipped.
sub _read_jsonl :Private {
	my ($path) = @_;

	return [] unless -e $path;
	return [ grep { ref($_) eq 'HASH' } map { length ? eval { json_decode($_) } : () } split /\n/, read_text($path) ];
}

# _case_insensitive
# Purpose:     whether the sync root's filesystem folds case.
# Entry:       $root is a directory.
# Exit:        returns 1 or 0; when the probe cannot be written, guesses
#              from the OS (Windows folds case).
# Side effects: creates and removes a probe file.
sub _case_insensitive :Private {
	my ($root) = @_;

	my $probe = File::Spec->catfile($root, $CASE_PROBE);
	my $created = eval { close(open_file($probe, '>')); 1 };
	return $^O eq 'MSWin32' ? 1 : 0 unless $created;

	my $insensitive = -e File::Spec->catfile($root, uc $CASE_PROBE) ? 1 : 0;
	eval { unlink $probe };
	return $insensitive;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * The base is a JSON file rewritten whole after every sync; a tree of
millions of paths makes that write, and the manifest it is built from, large.

=item * C<log> reads the whole run log; it is trimmed to 500 lines, so this
stays small.

=item * Local trash written by releases before 0.001.1 sits in one shared
directory.  It is still searched by C<restore> and pruned with the default 30
days, but a C<restore> can then offer another repo's file of the same
relative path.

=item * A pull is verified against the hash in the plan, which the server
computed when it planned.  If the master changes during the session (only
possible if something other than filesync writes to it), the pull fails with
a hash mismatch and the next sync retries.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
