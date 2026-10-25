package App::FileSync::Server;

# The server end of one sync session.  It is started by sshd (or the local
# transport) with the repo, client and role pinned on its command line, speaks
# the lock-step protocol on its connection, and only ever does what its own
# plan allows: a client cannot write, read, delete or acknowledge a path the
# server did not plan for it.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Digest::SHA ();
use File::Temp ();
use List::Util qw(any);
use Readonly;
use Sub::Private { mode => 'enforce' };
use Time::HiRes ();

use parent 'App::FileSync::Base';

use App::FileSync qw(validate_relpath validate_client_id validate_repo_name name_with_suffix);
use App::FileSync::Args qw(named);
use App::FileSync::Constants qw(
	$PROTOCOL_VERSION $ROLE_CLIENT @ROLES $TYPE_FILE $TYPE_DIR
	$MODE_MASK $DEFAULT_FILE_MODE $MAX_CHUNK_BYTES $SHA256_HEX
	$EXIT_OK $EXIT_FATAL $EXIT_LOCKED $EXIT_WARNINGS $SERVER_PROGRAM
);
use App::FileSync::Delta;
use App::FileSync::I18N qw(message os_error strip_location);
use App::FileSync::Merge;
use App::FileSync::Protocol;
use App::FileSync::Settings;
use App::FileSync::Store;

use version; our $VERSION = version->declare('0.001.2');

# Package variables for compatibility: the CLI checks $PROTO, and tests may
# localise $CHUNK.
our $CHUNK = 262_144;
our $PROTO = $PROTOCOL_VERSION;

# Bounds on a pull signature the client uploads, so a hostile client cannot
# make the server allocate or hash without limit.
Readonly my $MAX_SIGNATURE_BLOCKS => 16_384;
Readonly my $MIN_SIGNATURE_BLOCK  => 1024;
Readonly my $MAX_SIGNATURE_BLOCK  => 1024 * 1024;

# Wire cost of one delta record, for deciding whether a delta is worth it;
# the constant covers the reply headers.
Readonly my $DELTA_OP_BYTES => 12;
Readonly my $DELTA_OVERHEAD => 64;

# Unsigned decimal integers, and mtimes (which may be fractional or, for a
# file dated before 1970, negative).
Readonly my $UINT  => qr/\A\d+\z/;
Readonly my $MTIME => qr/\A-?\d+(?:\.\d+)?\z/;

# The protocol's commands and the method that serves each.
Readonly my %COMMANDS => (
	manifest  => '_manifest',
	plan      => '_plan',
	get       => '_get',
	put       => '_put',
	chunk     => '_chunk',
	chunk_end => '_chunk_end',
	sig       => '_signature',
	delta     => '_delta_start',
	dcopy     => '_delta_copy',
	dlit      => '_delta_literal',
	delta_end => '_delta_end',
	dsig      => '_pull_signature',
	dop       => '_pull_op',
	mkdir     => '_mkdir',
	del       => '_delete',
	ack       => '_ack',
	done      => '_finish',
);

# Which planned actions each kind of request may serve.  "conflict:client"
# is a conflict the client's version won; "conflict:remote" one the master's won.
Readonly my %MAY => (
	read   => [ 'pull', 'conflict:remote' ],
	write  => [ 'push', 'conflict:client' ],
	delta  => [ 'push' ],
	pull   => [ 'pull' ],
	mkdir  => [ 'push', 'conflict:client' ],
	delete => [ 'delete_remote' ],
	ack    => [ 'pull', 'delete_local', 'conflict:remote' ],
);

# The flags a forced command may carry, and the pinned field each must match.
Readonly my %FORCED_FLAGS => (repo => 'repo', client => 'client', role => 'role', proto => 'proto');

=encoding utf8

=head1 NAME

App::FileSync::Server - serve one sync session against a repo's master

=head1 SYNOPSIS

	my $server = App::FileSync::Server->new(
		root => '/srv/filesync', repo => 'docs', client => 'laptop', role => 'client',
		connection => App::FileSync::Protocol->new(in => \*STDIN, out => \*STDOUT),
	);
	exit($server->run ? 0 : 1);

=head1 DESCRIPTION

A session is: hello, manifest, plan, then the transfers the plan lists, then
C<done>.  The server holds the repo lock throughout, so sessions on one repo
never interleave.  It updates the master index and the client's base only in
C<done>, after every planned action has been applied; a session that dies part
way leaves both as they were, and the next session replans from the tree.

=head1 METHODS

=head2 new

Purpose: prepare a session.

Args: C<root>, C<repo>, C<client>, C<role> (C<client> or C<replica>),
C<connection> (an L<App::FileSync::Protocol>), optional C<logger> and
C<language>.

Returns: the server object.

Side Effects: builds a logger from the settings when none is given.

Usage:

	my $server = App::FileSync::Server->new(%pinned, connection => $connection);

=head3 EXAMPLE

	my $server = App::FileSync::Server->new(
		root => $root, repo => 'docs', client => 'laptop', role => 'client', connection => $conn,
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		root       => { type => 'string', min => 1 },
		repo       => { type => 'string', min => 1, max => 64 },
		client     => { type => 'string', min => 1, max => 64 },
		role       => { type => 'string', memberof => [ 'client', 'replica' ] },
		connection => { type => 'object', can => [ 'send', 'recv' ] },
		logger     => { type => 'object', optional => 1 },
		language   => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::FileSync::Server' }

=head3 MESSAGES

	Key                  Meaning                         Resolution
	server.missing       a required argument is absent   pass it
	server.bad_role      role is not client or replica   fix the forced command
	server.bad_id        repo or client is not an id     fix the forced command
	server.no_connection no connection was given         pass connection

=head3 FORMAL SPECIFICATION

	pre root ≠ "" ∧ repo ∈ Id ∧ client ∈ Id ∧ role ∈ {client, replica} ∧ connection ≠ ⊥
	post finished = 0 ∧ plan = ∅ ∧ uploads = ∅

=cut

sub new {
	my $class = shift;
	my $args = named(\@_, {
		root       => { type => 'string', optional => 1 },
		repo       => { type => 'string', optional => 1 },
		client     => { type => 'string', optional => 1 },
		role       => { type => 'string', optional => 1 },
		connection => { type => 'object', optional => 1 },
		logger     => { type => 'object', optional => 1 },
		language   => { type => 'string', optional => 1 },
	}, 'Server->new');

	# Checked here rather than by the schema so the messages read as a
	# server refusal rather than an argument error.
	for my $required (qw(root repo client role)) {
		App::FileSync::I18N::throw('server.missing', { what => $required })
			unless defined $args->{$required} && length $args->{$required};
	}
	App::FileSync::I18N::throw('server.bad_role', { role => $args->{role} })
		unless any { $_ eq $args->{role} } @ROLES;

	for my $check ([ repo => \&validate_repo_name ], [ client => \&validate_client_id ]) {
		my ($field, $validate) = @{$check};
		my ($ok, $reason) = $validate->($args->{$field});
		App::FileSync::I18N::throw('server.bad_id', { reason => $reason }) unless $ok;
	}
	App::FileSync::I18N::throw('server.no_connection') unless $args->{connection};

	return bless {
		(map { $_ => $args->{$_} } qw(root repo client role language)),
		conn            => $args->{connection},
		logger          => $args->{logger} || App::FileSync::Settings::logger(),
		dry_run         => 0,
		force           => 0,
		finished        => 0,
		uploads         => {},
		pull_deltas     => {},
		client_manifest => {},
		plan            => {},
		index           => {},
		base            => {},
		base_after      => {},
		applied         => {},
	}, $class;
}

=head2 run

Purpose: serve the whole session.

Args: none.

Returns: 1 when the session finished, 0 when it failed (the client has been
sent the error).

Side Effects: takes the repo lock; reads and writes the master, its index, the
client's base, the trash and the journal; prunes the trash and removes stale
temporaries.  A failed session is journalled (exit 2 for a lock refusal,
otherwise 1) unless it never got as far as opening the repo.

Usage:

	exit($server->run ? 0 : 1);

=head3 EXAMPLE

	my $ok = $server->run;
	warn "session failed\n" unless $ok;

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

	Key                    Meaning                             Resolution
	server.locked          another session holds the lock      the client retries later
	server.not_allowed     the client is not registered        filesync-admin client allow
	server.wrong_role      the client is registered otherwise  fix the key's --role
	server.proto           the client speaks another protocol  upgrade one side
	server.pinned          the hello disagrees with the pin    fix the client config
	server.unknown         an unknown command arrived          upgrade one side

Raised once the session is open.  Each ends the session: the open uploads
are discarded, the failure is journalled, and the text (without Perl's
file and line) reaches the client as C<< { ok => 0, fatal => 1, error => ... } >>.
Most mean a client bug or a hostile client; the resolution is to fix the
client, or simply to rerun the sync.

	Key                     Meaning
	server.manifest_list    the manifest is not a list
	server.manifest_entry   a manifest entry is not an object
	server.manifest_path    a manifest path is unsafe
	server.manifest_field   a manifest t, h, s, m or mode field is malformed
	server.refused          the deletion guard stopped the plan (rerun with --force if intended)
	server.unplanned        an operation names a path that is not in the plan
	server.not_planned      the path's planned action does not allow this operation
	server.bad_field        an off, max, len, s, mode or h field is malformed
	server.conflict_name    the conflict copy is named other than the plan says
	server.conflict_unsafe  the planned conflict name is not a safe path
	server.conflict_same    the planned conflict name equals the path
	server.conflict_exists  something already exists at the conflict name
	server.conflict_move    the master's copy could not be moved aside
	server.bad_ack          an ack disagrees with the planned action
	server.busy             a second put for a path already being received
	server.no_put           chunk or chunk_end without a put
	server.too_large        one chunk is larger than the chunk limit
	server.overflow         the upload is larger than its announced size
	server.hash_mismatch    the received content does not have the announced hash
	server.size_mismatch    the received content does not have the announced size
	server.no_delta         delta data without a delta start
	server.bad_copy         a delta copy reaches outside the base file
	server.bad_signature    a pull signature is malformed
	server.no_signature     a pull delta operation without a signature
	server.cannot_stat      a planned file vanished from the master
	server.not_file         a get for a path that is a directory
	server.unfinished       done arrived before every planned action completed

=head3 FORMAL SPECIFICATION

	ΔFS
	run = 1 ⇔ hello ⨾ open ⨾ lock ⨾ loop ⨾ done succeed
	run = 0 ⇒ index' = index ∧ base' = base

=head3 PSEUDOCODE

	read and check the hello against the pinned arguments
	open the repo; check the client is allowed in its role
	take the lock (refuse with code "locked" otherwise)
	load the index and the client's base; tidy temporaries and the trash
	send the policy, then serve commands until done
	on any error: log it, journal the failed session, discard partial
	uploads, and send the error to the client

=cut

sub run {
	my ($self) = @_;

	my $connection = $self->{conn};

	my $ok = eval {
		$self->_validate_hello($connection->recv());

		my $store = $self->{store} = App::FileSync::Store->new(
			root => $self->{root}, repo => $self->{repo}, language => $self->{language},
		);
		$self->_check_client_allowed();

		$self->{lock} = $store->acquire_lock();
		unless ($self->{lock}) {
			$self->{refusal} = 'locked';
			$self->_throw('server.locked', { repo => $self->{repo} });
		}

		$self->{index} = $store->load_index();
		$self->{base}  = $store->load_base($self->{client});
		$store->clean_stale_temps();
		$store->prune_trash() unless $self->{dry_run};

		$self->{logger}->info('session opened', { map { $_ => $self->{$_} } qw(repo client role) });

		my $policy = $store->config();
		$connection->send({
			ok     => 1,
			proto  => $PROTO,
			server => { os => $^O },
			repo   => { name => $self->{repo} },
			policy => { map { $_ => $policy->{$_} } qw(ignore trash_days max_deletes max_delete_percent) },
		});

		$self->_loop();
		1;
	};

	return 1 if $ok;

	# The client shows this text to a person, so no Perl file and line.
	my $error = strip_location($@) || $self->i18n('server.unknown_error');
	$self->{logger}->error($error);
	$self->_discard_uploads();
	$self->_journal_failed_session($error);

	eval {
		$connection->send({ ok => 0, error => $error, fatal => 1, ($self->{refusal} ? (code => $self->{refusal}) : ()) });
	};
	return 0;
}

=head2 validate_forced_command

Purpose: check the command a client asked sshd to run against the arguments
pinned in F<authorized_keys>.

The pinned arguments are the authority for a session.  sshd passes the command
the client asked for in C<SSH_ORIGINAL_COMMAND>; it must agree with the pinned
repo, client, role and protocol and ask for nothing else: in particular it may
not choose its own C<--root>.

Args: C<$original> (the requested command; undef or blank is accepted),
C<\%pinned> (C<repo>, C<client>, C<role>).

Returns: C<(1, undef)> or C<(0, $reason)>.  A list, deliberately: callers
write C<my ($ok, $why) = ...>, matching L<App::FileSync/validate_relpath>.

Side Effects: none.

Usage:

	my ($ok, $reason) = App::FileSync::Server::validate_forced_command($ENV{SSH_ORIGINAL_COMMAND}, \%pinned);

=head3 EXAMPLE

	my ($ok, $why) = App::FileSync::Server::validate_forced_command(
		'filesync-server --repo docs --client laptop --role client --proto 2',
		{ repo => 'docs', client => 'laptop', role => 'client' },
	);	# (1, undef)

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'original', type => 'string', optional => 1 },
		{ name => 'pinned',   type => 'hashref' },
	]

=head4 OUTPUT

	{ type => 'arrayref', min => 2, max => 2 }	# returned as a two-element list

=head3 MESSAGES

	Key                   Meaning
	forced.program        the command runs some other program
	forced.argument       a token is not a --flag
	forced.no_value       a flag has no value
	forced.flag           the flag is not repo, client, role or proto
	forced.proto          the protocol differs from this server's
	forced.pinned         the value differs from the pinned one

=head3 FORMAL SPECIFICATION

	let ts = tokens(original)
	ok ⇔ (ts = ⟨⟩) ∨ ((head ts ∈ FLAG ∨ basename(head ts) = filesync-server) ∧
	      ∀ (f, v) : flags(ts) • f ∈ {repo, client, role, proto} ∧
	      (f = proto ⇒ v = PROTO) ∧ (f ≠ proto ⇒ v = pinned(f)))

=head3 PSEUDOCODE

	accept an empty command
	split on white space; allow a leading filesync-server path
	for each --flag[=value] (value from the next token if not attached):
		reject an unknown flag, a missing value, a wrong protocol
		reject a value that differs from the pinned one

=cut

sub validate_forced_command {
	my ($original, $pinned) = @_;

	my @tokens = defined $original ? split(' ', $original) : ();
	return (1, undef) unless @tokens;

	if ($tokens[0] !~ /\A--/) {
		my $program = shift @tokens;
		return (0, message('forced.program', { program => $program }))
			unless $program =~ m{(?:\A|/)\Q$SERVER_PROGRAM\E\z};
	}

	while (@tokens) {
		my $token = shift @tokens;
		return (0, message('forced.argument', { token => $token }))
			unless $token =~ /\A--([a-z][a-z-]*)(?:=(.*))?\z/s;

		my ($flag, $value) = ($1, $2);
		unless (defined $value) {
			return (0, message('forced.no_value', { flag => $flag })) unless @tokens;
			$value = shift @tokens;
		}

		my $field = $FORCED_FLAGS{$flag} or return (0, message('forced.flag', { flag => $flag }));

		if ($field eq 'proto') {
			return (0, message('forced.proto', { proto => $value })) unless $value eq $PROTO;
			next;
		}

		my $expected = $pinned->{$field};
		return (0, message('forced.pinned', { field => $field, value => $value, expected => $expected // '' }))
			unless defined $expected && $value eq $expected;
	}

	return (1, undef);
}

# _journal_failed_session
# Purpose:     record a session that never reached done, so the admin sees
#              the attempt with the same exit code the client records.
# Entry:       $error is the message sent to the client.
# Exit:        returns 1 if journalled, else 0.
# Side effects: appends to the journal.  Nothing is journalled without a store
#              (a bad hello, say) or on a dry run, and a journal write that
#              fails is logged, never allowed to mask the original error.
sub _journal_failed_session :Private {
	my ($self, $error) = @_;

	return 0 if $self->{finished} || $self->{session_journalled} || $self->{dry_run} || !$self->{store};

	my $locked = ($self->{refusal} || '') eq 'locked';
	my $ok = eval {
		$self->_journal({
			action => 'session',
			result => 'error',
			exit   => $locked ? $EXIT_LOCKED : $EXIT_FATAL,
			error  => $error,
			($locked ? (locked => 1) : ()),
		});
		1;
	};
	$self->{logger}->warn('cannot journal the failed session', { error => strip_location($@) }) unless $ok;

	return $ok ? 1 : 0;
}

# _validate_hello
# Purpose:     check the client's hello against the pinned session.
# Entry:       $hello is the first message.
# Exit:        returns 1.
# Side effects: records dry_run and force; raises server.proto or
#              server.pinned.
sub _validate_hello :Private {
	my ($self, $hello) = @_;

	$self->_throw('server.proto') unless defined $hello->{proto} && $hello->{proto} eq $PROTO;

	for my $field (qw(client repo role)) {
		my $given = $hello->{$field} // '';
		$self->_throw('server.pinned', { field => $field, expected => $self->{$field}, given => $given })
			unless $given eq $self->{$field};
	}

	# case_insensitive is part of the hello but only the client acts on it.
	$self->{dry_run} = $hello->{dry_run} ? 1 : 0;
	$self->{force}   = $hello->{force} ? 1 : 0;
	return 1;
}

# _check_client_allowed
# Purpose:     enforce the repo's client list.
# Entry:       the store is open.
# Exit:        returns 1.
# Side effects: raises server.not_allowed or server.wrong_role.  An empty
#              list allows everyone (a repo nobody has restricted yet).
sub _check_client_allowed :Private {
	my ($self) = @_;

	my $clients = $self->{store}->config()->{clients} || {};
	return 1 unless %{$clients};

	my $entry = $clients->{ $self->{client} }
		or $self->_throw('server.not_allowed', { client => $self->{client}, repo => $self->{repo} });

	my $role = (ref($entry) eq 'HASH' && $entry->{role}) || $ROLE_CLIENT;
	$self->_throw('server.wrong_role', { client => $self->{client}, registered => $role, asked => $self->{role} })
		unless $role eq $self->{role};

	return 1;
}

# _loop
# Purpose:     serve commands until done.
# Entry:       the hello has been answered.
# Exit:        returns 1 once _finish has run.
# Side effects: whatever the commands do; raises server.unknown.
sub _loop :Private {
	my ($self) = @_;

	until ($self->{finished}) {
		my $message = $self->{conn}->recv();
		my $command = $message->{cmd} // '';
		my $method = $COMMANDS{$command} or $self->_throw('server.unknown', { command => $command });
		$self->$method($message);
	}

	return 1;
}

# _manifest
# Purpose:     accept (part of) the client's manifest.
# Entry:       $message->{entries} is an arrayref of { p, t, s, m, h, mode }.
# Exit:        returns 1 after replying ok.
# Side effects: adds normalised entries to client_manifest; raises
#              server.manifest_* for anything malformed, so the plan never
#              sees an unchecked path or field.
sub _manifest :Private {
	my ($self, $message) = @_;

	my $entries = $message->{entries};
	$self->_throw('server.manifest_list') unless ref($entries) eq 'ARRAY';

	for my $entry (@{$entries}) {
		$self->_throw('server.manifest_entry') unless ref($entry) eq 'HASH';

		my $path = $entry->{p};
		my ($safe, $reason) = validate_relpath($path);
		$self->_throw('server.manifest_path', { reason => $reason }) unless $safe;

		my $type = $entry->{t} // $TYPE_FILE;
		$self->_throw('server.manifest_field', { field => 't', path => $path })
			unless $type eq $TYPE_FILE || $type eq $TYPE_DIR;

		if ($type eq $TYPE_DIR) {
			$self->{client_manifest}{$path} = { t => $TYPE_DIR };
			next;
		}

		my %field = (h => $SHA256_HEX, s => $UINT, m => $MTIME, mode => $UINT);
		my %entry = (m => 0, mode => $DEFAULT_FILE_MODE, %{$entry});
		for my $name (sort keys %field) {
			$self->_throw('server.manifest_field', { field => $name, path => $path })
				unless defined $entry{$name} && $entry{$name} =~ $field{$name};
		}

		$self->{client_manifest}{$path} = {
			t    => $TYPE_FILE,
			h    => $entry{h},
			(map { $_ => $entry{$_} + 0 } qw(s m mode)),
		};
	}

	$self->{conn}->send({ ok => 1 });
	return 1;
}

# _plan
# Purpose:     plan the session and send it to the client.
# Entry:       the manifest has arrived.
# Exit:        returns 1 after sending the actions.
# Side effects: rescans the master (reusing the index's hashes); stores the
#              plan; journals it unless dry run; raises the delete guard's
#              refusal when the plan deletes too much.
sub _plan :Private {
	my ($self) = @_;

	my $store = $self->{store};
	my $master = $self->{index} = $store->walk_master($self->{index})->{manifest};
	my $config = $store->config();

	my $plan = App::FileSync::Merge::plan(
		base      => $self->{base},
		client    => $self->{client_manifest},
		master    => $master,
		client_id => $self->{client},
		role      => $self->{role},
		now       => time,
	);

	my $refusal = App::FileSync::Merge::check_delete_limit(
		deletions          => $plan->{deletions},
		base_size          => scalar(keys %{ $self->{base} }),
		max_deletes        => $config->{max_deletes},
		max_delete_percent => $config->{max_delete_percent},
		force              => $self->{force},
	);
	$self->_throw('server.refused', { reason => $refusal }) if defined $refusal;

	$self->_unique_loser_names($plan->{actions});

	$self->{plan} = { map { $_->{p} => $_ } @{ $plan->{actions} } };
	$self->{base_after} = { %{ $self->{client_manifest} } };

	my %counts = (
		actions   => scalar @{ $plan->{actions} },
		deletions => $plan->{deletions},
		conflicts => $plan->{conflicts},
		dry_run   => $self->{dry_run},
	);
	$self->{logger}->debug('plan', { repo => $self->{repo}, client => $self->{client}, %counts });
	$self->_journal({ action => 'plan', %counts }) unless $self->{dry_run};

	$self->{conn}->send({ ok => 1, actions => $plan->{actions}, warnings => $plan->{warnings} });
	return 1;
}

# _unique_loser_names
# Purpose:     make every conflict-copy name unique against the master and
#              the rest of the plan.
# Entry:       $actions from Merge::plan.
# Exit:        returns 1.
# Side effects: rewrites loser_name in place.  Two conflicts resolved in the
#              same second would otherwise pick the same name.
sub _unique_loser_names :Private {
	my ($self, $actions) = @_;

	my %used;
	for my $action (grep { $_->{a} eq 'conflict' && defined $_->{loser_name} } @{$actions}) {
		my ($name, $suffix) = ($action->{loser_name}, 1);
		$name = name_with_suffix($action->{loser_name}, ++$suffix)
			while $used{$name} || exists $self->{index}{$name};
		$used{$name} = 1;
		$action->{loser_name} = $name;
	}

	return 1;
}

# _expect
# Purpose:     the one gate every path-bearing request passes.
# Entry:       $kind is a key of %MAY; $path is from the client.
# Exit:        returns the planned action for $path.
# Side effects: raises server.unplanned when the plan has no such path and
#              server.not_planned when it does not allow this request.
sub _expect :Private {
	my ($self, $kind, $path) = @_;

	my $what = $self->i18n("server.op.$kind");
	my $action = defined $path ? $self->{plan}{$path} : undef;
	$self->_throw('server.unplanned', { what => $what, path => $path // '' }) unless $action;

	my $label = $action->{a} eq 'conflict' ? "conflict:" . ($action->{winner} // '') : $action->{a};
	$self->_throw('server.not_planned', { what => $what, path => $path })
		unless any { $_ eq $label } @{ $MAY{$kind} };

	return $action;
}

# _get
# Purpose:     send one chunk of a master file the client is pulling.
# Entry:       $message has p, optional off and max.
# Exit:        returns 1 after sending the chunk.
# Side effects: reads the master; raises server.bad_field for a malformed
#              offset or size, server.not_file and io.* errors.  max is
#              clamped to MAX_CHUNK_BYTES so a client cannot ask the server to
#              buffer an entire large file.
sub _get :Private {
	my ($self, $message) = @_;

	my $path = $message->{p};
	$self->_expect('read', $path);

	my $offset = $self->_uint($message, 'off', 0);
	my $max    = $self->_uint($message, 'max', $CHUNK);
	$max = $MAX_CHUNK_BYTES if $max > $MAX_CHUNK_BYTES;

	my $abs = $self->{store}->abs_path($path);
	my $file = $self->_file_stat($abs, $path);
	$self->_throw('server.bad_field', { field => 'off', path => $path }) if $offset > $file->{s};

	my $length = $file->{s} - $offset;
	$length = $max if $length > $max;

	my $bytes = '';
	if ($length > 0) {
		my $fh = App::FileSync::IO::open_file($abs, '<:raw');
		seek($fh, $offset, 0);
		$bytes = App::FileSync::Delta::read_exact($fh, $length, $abs);
		close $fh;
	}

	$self->{conn}->send_data({ ok => 1, eof => ($offset + $length >= $file->{s}) ? 1 : 0, %{$file} }, $bytes);
	return 1;
}

# _put
# Purpose:     start receiving a whole file the client is pushing.
# Entry:       $message has p, s, h, m, mode; conflict_name is optional and,
#              when sent, must equal the plan's loser_name.
# Exit:        returns 1 after replying ok with off 0.
# Side effects: for a conflict the client won, moves the master's version
#              aside under the plan's name first - whatever the client
#              sends, so a client that omits the name cannot overwrite the
#              master's losing version.  Opens a temporary file.
sub _put :Private {
	my ($self, $message) = @_;

	my $path = $message->{p};
	my $action = $self->_expect('write', $path);

	if ($action->{a} eq 'conflict' && defined $action->{loser_name}) {
		$self->_throw('server.conflict_name', { path => $path, expected => $action->{loser_name} })
			if defined $message->{conflict_name} && $message->{conflict_name} ne $action->{loser_name};
		$self->_preserve_loser($path, $action->{loser_name}, { sha256 => $message->{h}, mtime => $message->{m} });
	}

	$self->_open_upload($path, $message);
	$self->{conn}->send({ ok => 1, off => 0 });
	return 1;
}

# _chunk
# Purpose:     receive one chunk of a whole-file upload.
# Entry:       a put for $message->{p} is open; len gives the payload size.
# Exit:        returns 1 after replying with the new offset.
# Side effects: appends to the temporary file and the running hash.
sub _chunk :Private {
	my ($self, $message) = @_;

	my $path = $message->{p} // '';
	my $upload = $self->{uploads}{$path} or $self->_throw('server.no_put', { path => $path });

	my $length = $self->_uint($message, 'len', 0);
	$self->_throw('server.too_large', { path => $path }) if $length > $MAX_CHUNK_BYTES;

	$self->_append_upload($path, $upload, $length ? $self->{conn}->read_data($message) : '');
	$self->{conn}->send({ ok => 1, off => $upload->{got} });
	return 1;
}

# _chunk_end
# Purpose:     finish a whole-file upload.
# Entry:       a put for $message->{p} is open.
# Exit:        returns 1 after replying ok.
# Side effects: verifies and installs the file (see _commit_upload).
sub _chunk_end :Private {
	my ($self, $message) = @_;

	my $path = $message->{p} // '';
	my $upload = delete $self->{uploads}{$path} or $self->_throw('server.no_put', { path => $path });

	$self->_commit_upload($path, $upload);
	$self->{conn}->send({ ok => 1 });
	return 1;
}

# _signature
# Purpose:     describe the master's current version so the client can push
#              only the blocks that differ.
# Entry:       $message->{p} is a planned push.
# Exit:        returns 1 after replying; delta 0 when the file is too small
#              or absent.
# Side effects: reads the master file.
sub _signature :Private {
	my ($self, $message) = @_;

	my $path = $message->{p};
	$self->_expect('delta', $path);

	my $abs = $self->{store}->abs_path($path);
	my $signature = (-f $abs && (-s _) >= $App::FileSync::Delta::MIN_SIZE)
		? App::FileSync::Delta::signature($abs)
		: undef;

	return $self->_reply({ ok => 1, delta => 0 }) unless $signature;

	$self->{conn}->send_data({
		ok    => 1,
		delta => 1,
		s     => $signature->{size},
		b     => $signature->{blocklen},
		n     => scalar @{ $signature->{blocks} },
	}, App::FileSync::Delta::encode_signature($signature));
	return 1;
}

# _delta_start
# Purpose:     start receiving a pushed file as a delta against the master.
# Entry:       $message has p, h, s, m, mode.
# Exit:        returns 1 after replying ok.
# Side effects: opens a temporary file and, when the master has the file,
#              a read handle on it for copy records.
sub _delta_start :Private {
	my ($self, $message) = @_;

	my $path = $message->{p};
	$self->_expect('delta', $path);
	$self->_throw('server.bad_field', { field => 'h', path => $path })
		unless defined $message->{h} && $message->{h} =~ $SHA256_HEX;
	$self->_uint($message, 's');

	my $upload = $self->_open_upload($path, $message);
	$upload->{delta} = 1;

	my $old = $self->{store}->abs_path($path);
	if (-f $old) {
		@{$upload}{qw(old old_fh old_size)} = ($old, App::FileSync::IO::open_file($old, '<:raw'), -s _);
	}

	$self->{conn}->send({ ok => 1 });
	return 1;
}

# _delta_copy
# Purpose:     apply a copy record: bytes from the master's old version.
# Entry:       a delta for p is open; off and len are integers, len > 0.
# Exit:        returns 1 after replying with the new offset.
# Side effects: appends to the upload; raises server.bad_copy for a range
#              outside the old file.
sub _delta_copy :Private {
	my ($self, $message) = @_;

	my ($path, $upload) = $self->_open_delta($message);
	my $offset = $self->_uint($message, 'off');
	my $length = $self->_uint($message, 'len');

	$self->_throw('server.bad_copy', { path => $path })
		unless $length > 0 && $upload->{old_fh} && $offset + $length <= $upload->{old_size};

	seek($upload->{old_fh}, $offset, 0);
	$self->_append_upload($path, $upload, App::FileSync::Delta::read_exact($upload->{old_fh}, $length, $upload->{old}));
	$self->{conn}->send({ ok => 1, off => $upload->{got} });
	return 1;
}

# _delta_literal
# Purpose:     apply a literal record: bytes sent by the client.
# Entry:       a delta for p is open.
# Exit:        returns 1 after replying with the new offset.
# Side effects: appends to the upload.
sub _delta_literal :Private {
	my ($self, $message) = @_;

	my ($path, $upload) = $self->_open_delta($message);
	$self->_append_upload($path, $upload, $self->{conn}->read_data($message));
	$self->{conn}->send({ ok => 1, off => $upload->{got} });
	return 1;
}

# _delta_end
# Purpose:     finish a delta upload.
# Entry:       a delta for p is open.
# Exit:        returns 1 after replying ok.
# Side effects: verifies and installs the file; journals it as a delta push.
sub _delta_end :Private {
	my ($self, $message) = @_;

	my ($path, $upload) = $self->_open_delta($message);
	delete $self->{uploads}{$path};

	$self->_commit_upload($path, $upload, delta => 1);
	$self->{conn}->send({ ok => 1, delta => 1 });
	return 1;
}

# _pull_signature
# Purpose:     take the client's description of its old version and spool a
#              delta from the master's current one.
# Entry:       $message->{p} is a planned pull; n and b describe the blocks.
# Exit:        returns 1 after replying; delta 0 when a delta is not worth it.
# Side effects: reads the master file; keeps the spool for _pull_op.
sub _pull_signature :Private {
	my ($self, $message) = @_;

	my $path = $message->{p};
	$self->_expect('pull', $path);

	my $count = $self->_uint($message, 'n');
	my $block = $self->_uint($message, 'b');
	$self->_throw('server.bad_signature', { path => $path })
		unless $count <= $MAX_SIGNATURE_BLOCKS && $block >= $MIN_SIGNATURE_BLOCK && $block <= $MAX_SIGNATURE_BLOCK;

	my $blocks = App::FileSync::Delta::decode_signature($self->{conn}->read_data($message), $count);

	my $abs = $self->{store}->abs_path($path);
	my $file = $self->_file_stat($abs, $path);
	return $self->_reply({ ok => 1, delta => 0 }) if $file->{s} < $App::FileSync::Delta::MIN_SIZE;

	my $spool = File::Temp->new(UNLINK => 1);
	binmode $spool;
	my $stats = App::FileSync::Delta::diff($abs, { blocklen => $block, blocks => $blocks }, $spool);
	$spool->flush();

	# Only the literal bytes and record headers go on the wire; compression can
	# shrink them further, so this is a conservative estimate.
	my $estimated = $stats->{literal} + $DELTA_OP_BYTES * $stats->{ops} + $DELTA_OVERHEAD;
	return $self->_reply({ ok => 1, delta => 0 }) if $estimated >= $file->{s};

	seek($spool, 0, 0);
	$self->{pull_deltas}{$path} = { spool => $spool, %{$file} };
	$self->{conn}->send({ ok => 1, delta => 1, %{$file}, b => $block });
	return 1;
}

# _pull_op
# Purpose:     serve the next record of a spooled pull delta.
# Entry:       _pull_signature spooled a delta for p.
# Exit:        returns 1 after sending a copy, a literal, or done.
# Side effects: advances the spool; forgets it at the end.
sub _pull_op :Private {
	my ($self, $message) = @_;

	my $path = $message->{p} // '';
	my $state = $self->{pull_deltas}{$path} or $self->_throw('server.no_signature', { path => $path });

	my ($type, @rest) = App::FileSync::Delta::read_op($state->{spool});
	unless ($type) {
		delete $self->{pull_deltas}{$path};
		return $self->_reply({ ok => 1, done => 1 });
	}

	return $self->_reply({ ok => 1, op => 'copy', off => $rest[0], len => $rest[1] }) if $type eq 'copy';

	$self->{conn}->send_data({ ok => 1, op => 'lit' }, $rest[0]);
	return 1;
}

# _mkdir
# Purpose:     create a directory the client pushed.
# Entry:       $message->{p} is a planned push of a directory.
# Exit:        returns 1 after replying ok.
# Side effects: creates the directory in the master; records it.
sub _mkdir :Private {
	my ($self, $message) = @_;

	my $path = $message->{p};
	$self->_expect('mkdir', $path);

	App::FileSync::IO::ensure_dir($self->{store}->abs_path($path));
	$self->{index}{$path} = { t => $TYPE_DIR };
	$self->{base_after}{$path} = { t => $TYPE_DIR };
	$self->_journal({ action => 'mkdir', path => $path, result => 'ok' });

	$self->{applied}{$path} = 1;
	return $self->_reply({ ok => 1 });
}

# _delete
# Purpose:     move a master path the client deleted into the trash.
# Entry:       $message->{p} is a planned delete_remote.
# Exit:        returns 1 after replying with the trash path.
# Side effects: moves the path to the trash; records it.
sub _delete :Private {
	my ($self, $message) = @_;

	my $path = $message->{p};
	$self->_expect('delete', $path);

	my $trashed = $self->{store}->move_to_trash($path, time);
	delete $self->{index}{$path};
	delete $self->{base_after}{$path};
	$self->_journal({ action => 'delete', path => $path, trash => $trashed, result => 'ok' });

	$self->{applied}{$path} = 1;
	return $self->_reply({ ok => 1, trash => $trashed });
}

# _ack
# Purpose:     record what the client now holds after a change on its side.
# Entry:       $message->{p} is a planned pull, delete_local or conflict the
#              master won.  deleted is only valid for delete_local, and only
#              a delete_local may omit the file description.
# Exit:        returns 1 after replying ok.
# Side effects: updates base_after; journals a conflict the master won.
#              Restricting acks to these actions stops a client from writing
#              arbitrary entries into its own base, which would make the
#              next plan delete or skip master files.
sub _ack :Private {
	my ($self, $message) = @_;

	my $path = $message->{p};
	my $action = $self->_expect('ack', $path);
	my $deleting = $action->{a} eq 'delete_local';

	$self->_throw('server.bad_ack', { path => $path }) unless !$message->{deleted} == !$deleting;

	if ($deleting) {
		delete $self->{base_after}{$path};
	} elsif (($message->{t} // '') eq $TYPE_DIR) {
		$self->{base_after}{$path} = { t => $TYPE_DIR };
	} else {
		$self->_throw('server.bad_field', { field => 'h', path => $path })
			unless defined $message->{h} && $message->{h} =~ $SHA256_HEX;
		$self->{base_after}{$path} = {
			t    => $TYPE_FILE,
			h    => $message->{h},
			s    => $self->_uint($message, 's', 0),
			m    => ($message->{m} // 0) + 0,
			mode => $self->_uint($message, 'mode', $DEFAULT_FILE_MODE),
		};
	}

	if ($action->{a} eq 'conflict') {
		$self->_journal_conflict($path, 'remote', $action->{loser_name},
			$self->{index}{$path}, $self->{client_manifest}{$path});
	}

	$self->{applied}{$path} = 1;
	delete $self->{pull_deltas}{$path};
	return $self->_reply({ ok => 1 });
}

# _preserve_loser
# Purpose:     move the master's losing version aside before the client's
#              version is written.
# Entry:       $conflict_rel is the plan's loser_name for $path.
# Exit:        returns 1.
# Side effects: renames the master file; moves its index entry; journals the
#              copy and the conflict.  Does nothing if the master no longer
#              has the file.
sub _preserve_loser :Private {
	my ($self, $path, $conflict_rel, $winner) = @_;

	my ($safe, $reason) = validate_relpath($conflict_rel);
	$self->_throw('server.conflict_unsafe', { reason => $reason }) unless $safe;
	$self->_throw('server.conflict_same', { path => $path }) if $conflict_rel eq $path;

	my $store = $self->{store};
	my $abs = $store->abs_path($path);
	return 1 unless -e $abs || -l $abs;

	my $destination = $store->abs_path($conflict_rel);
	$self->_throw('server.conflict_exists', { path => $conflict_rel }) if -e $destination || -l $destination;

	$store->ensure_parent($conflict_rel);
	eval { rename $abs, $destination; 1 }
		or $self->_throw('server.conflict_move', { path => $path, to => $conflict_rel, error => os_error($@) });

	my $old = delete $self->{index}{$path};
	$self->{index}{$conflict_rel} = $old if $old;

	$self->_journal({ action => 'conflict_copy', path => $conflict_rel, from => $path, sha256 => $old ? $old->{h} : undef, result => 'ok' });
	$self->_journal_conflict($path, 'client', $conflict_rel, { h => $winner->{sha256}, m => $winner->{mtime} }, $old);

	return 1;
}

# _journal_conflict
# Purpose:     record how a conflict was resolved.
# Entry:       $side is client or remote; entries may be undef.
# Exit:        returns 1.
# Side effects: appends a conflict event.
sub _journal_conflict :Private {
	my ($self, $path, $side, $loser_name, $winner, $loser) = @_;

	($winner, $loser) = ($winner || {}, $loser || {});
	return $self->_journal({
		action        => 'conflict',
		path          => $path,
		winner        => $side,
		loser_name    => $loser_name,
		winner_sha256 => $winner->{h},
		winner_mtime  => $winner->{m},
		loser_sha256  => $loser->{h},
		loser_mtime   => $loser->{m},
		result        => 'ok',
	});
}

# _finish
# Purpose:     end the session: save the index and the client's base.
# Entry:       every planned action has been applied (unless dry run).
# Exit:        returns 1 after sending the summary.
# Side effects: writes the index, the base and a session event; sets
#              finished.  Raises server.unfinished, naming the missing paths
#              in order, when the client stopped early.
sub _finish :Private {
	my ($self) = @_;

	my @actions = values %{ $self->{plan} };
	unless ($self->{dry_run}) {
		my @unfinished = sort map { $_->{p} } grep { !$self->{applied}{ $_->{p} } } @actions;
		$self->_throw('server.unfinished', { paths => join(', ', @unfinished) }) if @unfinished;

		$self->{store}->save_index($self->{index});
		$self->{store}->save_base($self->{client}, $self->{base_after});
	}

	my %summary = map { my $kind = $_; $kind => scalar(grep { $_->{a} =~ /\A$kind/ } @actions) }
		qw(pull push delete conflict);
	%summary = (
		pulled    => $summary{pull},
		pushed    => $summary{push},
		deleted   => $summary{delete},
		conflicts => $summary{conflict},
	);

	$self->{logger}->info('session finished', { repo => $self->{repo}, client => $self->{client}, %summary, dry_run => $self->{dry_run} });

	# The client exits 3 when it had to keep conflict copies; record that here
	# too, so --exit means the same thing on both sides.
	$self->_journal({
		action  => 'session',
		result  => 'ok',
		exit    => $summary{conflicts} ? $EXIT_WARNINGS : $EXIT_OK,
		dry_run => $self->{dry_run},
		%summary,
	}) unless $self->{dry_run};
	$self->{session_journalled} = 1;

	$self->{conn}->send({ ok => 1, summary => \%summary });
	$self->{finished} = 1;
	return 1;
}

# _open_upload
# Purpose:     start an upload for a planned path.
# Entry:       $message has s, h, m, mode (s and h may be absent for a put).
# Exit:        returns the upload record.
# Side effects: creates the parent directory and a temporary file; raises
#              server.busy if the path is already being received.
sub _open_upload :Private {
	my ($self, $path, $message) = @_;

	$self->_throw('server.busy', { path => $path }) if $self->{uploads}{$path};

	my $size = defined $message->{s} ? $self->_uint($message, 's') : undef;
	$self->{store}->ensure_parent($path);
	my ($fh, $temp) = @{ $self->{store}->temp_file($path) };

	return $self->{uploads}{$path} = {
		fh    => $fh,
		temp  => $temp,
		sha   => Digest::SHA->new(256),
		got   => 0,
		size  => $size,
		hash  => $message->{h},
		mtime => $message->{m},
		mode  => $message->{mode},
	};
}

# _open_delta
# Purpose:     find the delta upload a record belongs to.
# Entry:       $message->{p} names it.
# Exit:        returns ($path, $upload).
# Side effects: raises server.no_delta when there is none, or the open
#              upload for that path is a whole-file put.
sub _open_delta :Private {
	my ($self, $message) = @_;

	my $path = $message->{p} // '';
	my $upload = $self->{uploads}{$path};
	$self->_throw('server.no_delta', { path => $path }) unless $upload && $upload->{delta};
	return ($path, $upload);
}

# _append_upload
# Purpose:     add received bytes to an upload.
# Entry:       $upload is open.
# Exit:        returns 1.
# Side effects: writes to the temporary file and the hash.  Refuses more
#              bytes than were announced, so a client cannot fill the disk
#              behind a small size; on any failure the upload is discarded.
sub _append_upload :Private {
	my ($self, $path, $upload, $bytes) = @_;

	my $length = length $bytes;
	if (defined $upload->{size} && $upload->{got} + $length > $upload->{size}) {
		$self->_discard_upload($path);
		$self->_throw('server.overflow', { path => $path });
	}

	unless (print { $upload->{fh} } $bytes) {
		my $error = os_error();
		$self->_discard_upload($path);
		$self->_throw('io.write', { path => $upload->{temp}, error => $error });
	}

	$upload->{sha}->add($bytes);
	$upload->{got} += $length;
	return 1;
}

# _commit_upload
# Purpose:     close, verify and install an upload, whole or delta.
# Entry:       $upload is no longer in uploads.
# Exit:        returns the new index entry.
# Side effects: installs the file in the master; updates the index and
#              base_after; journals the push.  A hash or size mismatch
#              discards the temporary file and raises.
sub _commit_upload :Private {
	my ($self, $path, $upload, %extra) = @_;

	my $closed = eval { close $upload->{fh}; 1 };
	my $error = $closed ? undef : os_error($@);
	eval { close $upload->{old_fh} } if $upload->{old_fh};

	my $hash = $upload->{sha}->hexdigest();
	my ($key, %args) =
		  !$closed ? ('io.write', path => $upload->{temp}, error => $error)
		: (defined $upload->{hash} && $hash ne $upload->{hash}) ? ('server.hash_mismatch', path => $path, expected => $upload->{hash}, got => $hash)
		: (defined $upload->{size} && $upload->{got} != $upload->{size}) ? ('server.size_mismatch', path => $path, expected => $upload->{size}, got => $upload->{got})
		: ();
	if ($key) {
		eval { unlink $upload->{temp} };
		$self->_throw($key, \%args);
	}

	$self->{store}->commit_temp($path, $upload->{temp}, $upload->{mtime}, $upload->{mode});

	my $entry = {
		t    => $TYPE_FILE,
		s    => $upload->{got},
		m    => $upload->{mtime} // time,
		h    => $hash,
		mode => $upload->{mode} // $DEFAULT_FILE_MODE,
	};
	$self->{index}{$path}      = $entry;
	$self->{base_after}{$path} = { %{$entry} };

	$self->_journal({ action => 'push', path => $path, size => $upload->{got}, sha256 => $hash, result => 'ok', %extra });
	$self->{applied}{$path} = 1;
	return $entry;
}

# _discard_upload / _discard_uploads
# Purpose:     abandon one, or every, partial upload.
# Entry:       none.
# Exit:        returns 1.
# Side effects: closes handles and removes temporary files, so a failed
#              session leaves nothing for clean_stale_temps to find an hour
#              later.
sub _discard_upload :Private {
	my ($self, $path) = @_;

	my $upload = delete $self->{uploads}{$path} or return 1;
	eval { close $_ } for grep { defined } @{$upload}{qw(fh old_fh)};
	eval { unlink $upload->{temp} };
	return 1;
}

sub _discard_uploads :Private {
	my ($self) = @_;

	$self->_discard_upload($_) for keys %{ $self->{uploads} };
	return 1;
}

# _file_stat
# Purpose:     size, mtime and mode of a master file the client is reading.
# Entry:       $abs is inside the master.
# Exit:        returns { s, m, mode }.
# Side effects: raises server.cannot_stat or server.not_file.
sub _file_stat :Private {
	my ($self, $abs, $path) = @_;

	my @stat = Time::HiRes::stat($abs);
	$self->_throw('server.cannot_stat', { path => $path, error => os_error() }) unless @stat;
	$self->_throw('server.not_file', { path => $path }) unless -f _;
	return { s => $stat[7], m => $stat[9], mode => $stat[2] & $MODE_MASK };
}

# _uint
# Purpose:     read an unsigned integer field from a client message.
# Entry:       $default is used when the field is absent; without one the
#              field is required.
# Exit:        returns the number.
# Side effects: raises server.bad_field for anything else (a negative or
#              fractional offset, a string, a missing required field).
sub _uint :Private {
	my ($self, $message, $field, $default) = @_;

	my $value = $message->{$field} // $default;
	$self->_throw('server.bad_field', { field => $field, path => $message->{p} // '' })
		unless defined $value && $value =~ $UINT;
	return $value + 0;
}

# _journal
# Purpose:     append an event for this client.
# Entry:       $event is a hashref without client.
# Exit:        returns 1.
# Side effects: appends to the journal.
sub _journal :Private {
	my ($self, $event) = @_;

	$self->{store}->journal({ client => $self->{client}, %{$event} });
	return 1;
}

# _reply
# Purpose:     send a reply and end the handler.
# Entry:       $reply is a hashref.
# Exit:        returns 1.
# Side effects: writes to the connection.
sub _reply :Private {
	my ($self, $reply) = @_;

	$self->{conn}->send($reply);
	return 1;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * The plan is computed once, from a scan taken while the lock is held.
Something other than filesync writing into the master during a session (an
admin's C<cp>, say) is not seen until the next session, and a file it
replaces may be overwritten.

=item * The whole client manifest is held in memory, as is the plan; a repo
with millions of paths needs memory in proportion.

=item * Uploads are verified by SHA-256 only at the end; a client that sends a
wrong file of the announced size wastes the transfer before it is refused.

=item * C<validate_forced_command> splits on white space, as sshd's
C<SSH_ORIGINAL_COMMAND> carries no quoting; a pinned value containing a space
can therefore never match.  Ids cannot contain spaces, so this only matters if
that rule changes.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
