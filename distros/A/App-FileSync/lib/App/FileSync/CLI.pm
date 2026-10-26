package App::FileSync::CLI;

# The three command-line programs: filesync (client), filesync-admin and
# filesync-server.  Each run_* parses arguments, calls the library and prints;
# all text comes from the message catalogue, so this module holds no prose.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Cwd qw(abs_path);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use List::Util qw(any first);
use Readonly;
use Sub::Private { mode => 'enforce' };
use Sys::Hostname ();

use App::FileSync qw(json_encode format_utc validate_repo_name validate_client_id parse_since parse_until write_atomic);
use App::FileSync::Admin;
use App::FileSync::Client;
use App::FileSync::Config;
use App::FileSync::Constants qw(
	$EXIT_OK $EXIT_FATAL $EXIT_LOCKED $EXIT_WARNINGS $EXIT_DRIFT $EXIT_MAX
	$DEFAULT_SERVER_ROOT $PROTOCOL_VERSION $ROLE_CLIENT @ROLES $ROOT_MARKER $MAX_ID_LENGTH $TYPE_FILE
);
use App::FileSync::I18N qw(message throw strip_location);
use App::FileSync::IO qw(ensure_dir);
use App::FileSync::Protocol;
use App::FileSync::Server;
use App::FileSync::Settings;
use App::FileSync::Transport::SSH;

use version; our $VERSION = version->declare('0.001.5');

# What the marker file says to anyone who finds it.  File content, not a
# message: it must not change with the reader's language.
Readonly my $MARKER_TEXT => "This directory is a filesync root; do not delete this file.\n";

# The client's default local-trash retention, written by init.
Readonly my $LOCAL_TRASH_DAYS => 30;

# How many journal events "filesync-admin log" shows by default.
Readonly my $ADMIN_LOG_LIMIT => 20;

# Size units for human-readable byte counts.
Readonly my $KIB => 1024;
Readonly my @SIZE_UNITS => ([ $KIB ** 3, 'GB' ], [ $KIB ** 2, 'MB' ], [ $KIB, 'kB' ]);

# The client commands and their handlers.
Readonly my %CLIENT_COMMANDS => (
	help     => '_client_help',
	'--help' => '_client_help',
	version  => '_client_version',
	init     => '_client_init',
	sync     => '_client_sync',
	status   => '_client_status',
	log      => '_client_log',
	settings => '_client_settings',
	verify   => '_client_verify',
	restore  => '_client_restore',
	snapshot => '_client_snapshot',
);

# The admin commands; a hashref value is a group of sub-commands.
Readonly my %ADMIN_COMMANDS => (
	repo    => { create => '_admin_repo_create', list => '_admin_repo_list', show => '_admin_repo_show' },
	client  => { allow => '_admin_client_allow', list => '_admin_client_list', forget => '_admin_client_forget' },
	log     => '_admin_log',
	verify  => '_admin_verify',
	reindex => '_admin_reindex',
	restore => '_admin_restore',
);

# Settings whose empty value means "the transport's default", and what to
# show instead of a blank column.
Readonly my %BLANK_SETTING => (
	log_file        => 'cli.settings.stderr',
	ssh_identity    => 'cli.settings.ssh_default',
	ssh_known_hosts => 'cli.settings.ssh_default',
	server_command  => 'cli.settings.server_default',
);

# Journal fields "filesync-admin log" prints as key=value, in this order.
Readonly my @EVENT_FIELDS   => qw(from winner loser_name exit trash sha256);
Readonly my @EVENT_COUNTERS => qw(actions deletions conflicts pulled pushed deleted);
Readonly my %EVENT_LABEL    => (loser_name => 'loser');

=encoding utf8

=head1 NAME

App::FileSync::CLI - the filesync, filesync-admin and filesync-server commands

=head1 SYNOPSIS

	# bin/filesync
	use App::FileSync::CLI;
	exit App::FileSync::CLI::run_client(@ARGV);

=head1 DESCRIPTION

Each C<run_*> function runs one command line and returns the exit code; it
never dies.  Errors are reported through the logger (or standard error if the
settings that configure the logger are themselves broken), without Perl file
and line numbers.  Text output goes to standard output; C<--json> prints one
JSON document instead.

Client exit codes: 0 ok, 1 fatal, 2 another run holds the lock, 3 completed
with warnings, 4 verification found drift.  Admin: 0, 1 and 4.

=head1 FUNCTIONS

=head2 run_client

Documented with L</run_server> below.

=head2 run_admin

Documented with L</run_server> below.

=head2 run_server

Purpose: run C<filesync>, C<filesync-admin> or C<filesync-server>.

Args: the command line, without the program name.

Returns: the exit code.

Side Effects: whatever the command does; prints to standard output and logs
to standard error.  C<run_server> speaks the protocol on standard input and
output and refuses to run on a terminal unless C<FILESYNC_ALLOW_TTY> is set.

Usage:

	exit App::FileSync::CLI::run_client(@ARGV);

=head3 EXAMPLE

	my $code = App::FileSync::CLI::run_client('sync', '--repo', 'docs', '--json');
	my $code = App::FileSync::CLI::run_admin('--root', '/srv/filesync', 'repo', 'list');

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'args', type => 'arrayref' } ]	# passed as a list

=head4 OUTPUT

	{ type => 'integer', min => 0, max => 255 }

=head3 MESSAGES

	Key                 Meaning                                   Resolution
	cli.unknown_command the command is not known                  run "filesync help"
	cli.usage.*         the options could not be parsed           see the usage line
	cli.unexpected      extra arguments were given                remove them
	cli.required        a required argument is missing            supply it
	cli.no_repos        no repos are configured                   filesync init
	cli.no_repo         the named repo is not configured          check --repo
	cli.need_repo       several repos and no --repo               pass --repo
	cli.init.*          init was given an unusable value          see the message
	cli.server.*        the server was started wrongly            fix authorized_keys

=head3 FORMAL SPECIFICATION

	run(args) = dispatch(args)                  if dispatch succeeds
	run(args) = 1 ∧ log(strip_location(error))  if it raises

=cut

sub run_client {
	my (@args) = @_;

	return _run(sub {
		my ($command, @rest) = @_;
		return _dispatch(\%CLIENT_COMMANDS, 'filesync', $command // 'help', @rest);
	}, @args);
}

sub run_admin {
	my (@args) = @_;

	return _run(\&_admin_dispatch, @args);
}

sub run_server {
	my (@args) = @_;

	return _run(\&_server_main, @args);
}

# _run
# Purpose:     run a dispatcher, turning any error into exit code 1.
# Entry:       $code takes the arguments and returns an exit code.
# Exit:        returns the exit code.
# Side effects: reports the error without its Perl location.
sub _run :Private {
	my ($code, @args) = @_;

	my $exit = eval { $code->(@args) };
	return $exit if defined $exit;

	_report_error(strip_location($@));
	return $EXIT_FATAL;
}

# _report_error
# Purpose:     show an error to the user.
# Entry:       $error is the text.
# Exit:        returns 1 if logged, 0 if printed directly.
# Side effects: logs it; if the logger cannot be built (an unusable settings
#              file), prints to standard error, so the error that says so is
#              never hidden.
sub _report_error :Private {
	my ($error) = @_;

	my $logger = eval { App::FileSync::Settings::logger() };
	if ($logger) {
		$logger->error($error);
		return 1;
	}

	print STDERR "$error\n";
	return 0;
}

# _dispatch
# Purpose:     run one command from a table.
# Entry:       $table maps command names to handler names.
# Exit:        returns the handler's exit code.
# Side effects: raises cli.unknown_command.
sub _dispatch :Private {
	my ($table, $program, $command, @args) = @_;

	my $handler = $table->{$command} or throw('cli.unknown_command', { command => $command, program => $program });
	my $code = __PACKAGE__->can($handler);
	return $code->(@args);
}

# _say
# Purpose:     print one catalogued line.
# Entry:       $key and its arguments.
# Exit:        returns 1.
# Side effects: prints to standard output.
sub _say :Private {
	my ($key, $args) = @_;

	print message($key, $args), "\n";
	return 1;
}

# _options
# Purpose:     parse options for a command, with its usage line on failure.
# Entry:       $args is the argument list (consumed); $spec is the
#              Getopt::Long specification; $command names the usage key.
# Exit:        returns 1.
# Side effects: removes the options from @$args; raises cli.usage.
sub _options :Private {
	my ($args, $spec, $command) = @_;

	GetOptionsFromArray($args, %{$spec}) or throw('cli.usage', { usage => message("cli.usage.$command") });
	return 1;
}

# _no_more
# Purpose:     refuse arguments a command does not take.
# Entry:       $args holds what is left after parsing.
# Exit:        returns 1.
# Side effects: raises cli.unexpected.
sub _no_more :Private {
	my ($args, $command) = @_;

	throw('cli.unexpected', { command => $command, args => "@{$args}" }) if @{$args};
	return 1;
}

# _require
# Purpose:     insist on a non-empty value.
# Entry:       $what names it in the message.
# Exit:        returns the value.
# Side effects: raises cli.required.
sub _require :Private {
	my ($value, $command, $what) = @_;

	throw('cli.required', { command => $command, what => $what }) unless defined $value && length $value;
	return $value;
}

# _repos
# Purpose:     the repos a multi-repo command works on.
# Entry:       $given are --repo values (maybe none); $require_any says
#              whether an empty configuration is an error.
# Exit:        returns an arrayref of names: the given ones, or all, sorted.
# Side effects: raises cli.no_repos or cli.no_repo.
sub _repos :Private {
	my ($config, $given, $require_any) = @_;

	throw('cli.no_repos') if $require_any && !%{ $config->{repos} };
	my @names = @{$given} ? @{$given} : sort keys %{ $config->{repos} };
	$config->{repos}{$_} or throw('cli.no_repo', { repo => $_ }) for @names;

	return \@names;
}

# _one_repo
# Purpose:     the repo a single-repo command works on.
# Entry:       $name is --repo, maybe undef.
# Exit:        returns the name; the only repo when there is just one.
# Side effects: raises cli.no_repos, cli.need_repo or cli.no_repo.
sub _one_repo :Private {
	my ($config, $name, $command) = @_;

	my @names = sort keys %{ $config->{repos} };
	throw('cli.no_repos') unless @names;
	$name //= $names[0] if @names == 1;
	throw('cli.need_repo', { command => $command }) unless defined $name;
	throw('cli.no_repo', { repo => $name }) unless $config->{repos}{$name};

	return $name;
}

# _client
# Purpose:     a Client for one configured repo.
# Entry:       %extra is passed to Client->new.
# Exit:        returns the client.
# Side effects: none.
sub _client :Private {
	my ($config, $name, %extra) = @_;

	return App::FileSync::Client->new(config => $config, name => $name, %extra);
}

# ------------------------------------------------------------------ server

# _server_main
# Purpose:     filesync-server: serve one session on stdin/stdout.
# Entry:       @args is the forced command's arguments.
# Exit:        returns 0 when the session finished, 1 when it failed.
# Side effects: runs the session.  Under sshd the root comes from the
#              forced command (or FILESYNC_ROOT), never from the client,
#              and SSH_ORIGINAL_COMMAND must agree with the pinned values.
sub _server_main :Private {
	my (@args) = @_;

	# --forced is accepted (older authorized_keys lines carry it) but implies
	# nothing: SSH_ORIGINAL_COMMAND is checked whenever sshd sets it.
	my %opt;
	_options(\@args, {
		'root=s'   => \$opt{root},
		'repo=s'   => \$opt{repo},
		'client=s' => \$opt{client},
		'role=s'   => \$opt{role},
		'proto=i'  => \$opt{proto},
		'forced'   => \$opt{forced},
	}, 'server');
	_no_more(\@args, 'filesync-server');

	my $root = first { defined && length } $opt{root}, $ENV{FILESYNC_ROOT}, $DEFAULT_SERVER_ROOT;
	_require($opt{$_}, 'filesync-server', "--$_") for qw(repo client role);
	throw('cli.server.bad_role', { role => $opt{role} }) unless any { $_ eq $opt{role} } @ROLES;
	throw('cli.server.proto', { proto => $opt{proto} }) if defined $opt{proto} && $opt{proto} != $PROTOCOL_VERSION;

	my $original = $ENV{SSH_ORIGINAL_COMMAND};
	if (defined $original && length $original) {
		my ($ok, $reason) = App::FileSync::Server::validate_forced_command(
			$original, { map({ $_ => $opt{$_} } qw(repo client role)), root => $root },
		);
		throw('cli.server.forced', { reason => $reason }) unless $ok;
	}

	throw('cli.server.tty') if -t STDIN && !$ENV{FILESYNC_ALLOW_TTY};

	my $server = App::FileSync::Server->new(
		root       => $root,
		(map { $_ => $opt{$_} } qw(repo client role)),
		connection => App::FileSync::Protocol->new(in => \*STDIN, out => \*STDOUT),
		logger     => App::FileSync::Settings::logger(),
	);

	return $server->run() ? $EXIT_OK : $EXIT_FATAL;
}

# ------------------------------------------------------------------ client

# _client_help / _client_version
# Purpose:     print the usage summary, or the version.
# Entry:       none.
# Exit:        returns 0.
# Side effects: prints.
sub _client_help :Private {
	print message('cli.help.client');
	return $EXIT_OK;
}

sub _client_version :Private {
	_say('cli.version', { version => $App::FileSync::VERSION, proto => $PROTOCOL_VERSION });
	return $EXIT_OK;
}

# _client_init
# Purpose:     filesync init: register a repo in the client configuration.
# Entry:       @args are init's options.
# Exit:        returns 0.
# Side effects: creates the sync root and its marker (and a local server
#              root); writes the client configuration.  Every id that will
#              reach the server is checked here, so a bad one is reported
#              at init rather than as a refusal at the first sync.
sub _client_init :Private {
	my (@args) = @_;

	# init has defaults that are not obvious, the client id above all, so
	# --help prints them instead of failing as an unknown option.
	if (grep { $_ eq '--help' || $_ eq '-h' } @args) {
		print message('cli.help.init');
		return $EXIT_OK;
	}

	my %opt;
	_options(\@args, {
		(map { ("$_=s" => \$opt{$_}) } qw(repo root server remote-repo id identity role transport server-root config known-hosts server-command snapshot-mode)),
		'port=i'          => \$opt{port},
		'accept-host-key' => \$opt{accept},
	}, 'init');

	my $repo = _require($opt{repo}, 'init', '--repo');
	my $root = _require($opt{root}, 'init', '--root');
	_check_id(\&validate_repo_name, $repo);
	_check_id(\&validate_repo_name, $opt{'remote-repo'}) if defined $opt{'remote-repo'} && length $opt{'remote-repo'};
	_check_id(\&validate_client_id, $opt{id}) if defined $opt{id} && length $opt{id};

	my $role = $opt{role} // $ROLE_CLIENT;
	throw('cli.init.bad_role', { role => $role }) unless any { $_ eq $role } @ROLES;

	my $mode = $opt{'snapshot-mode'};
	throw('cli.init.bad_mode', { mode => $mode })
		if defined $mode && length $mode && $mode ne 'hardlink' && $mode ne 'copy';

	my ($server, $server_root, $known) = @opt{qw(server server-root known-hosts)};
	my $use = $opt{transport} || ($server_root ? 'local' : 'ssh');
	throw('cli.init.bad_transport', { transport => $use }) unless $use eq 'local' || $use eq 'ssh';
	throw('cli.init.need_server_root') if $use eq 'local' && !(defined $server_root && length $server_root);
	throw('cli.init.need_server') if $use eq 'ssh' && !(defined $server && length $server);
	throw('cli.init.bad_server', { server => $server }) if $use eq 'ssh' && !App::FileSync::Transport::SSH::valid_server($server);
	throw('cli.init.no_known_hosts', { path => $known }) if defined $known && length $known && !-f $known;
	throw('cli.init.accept_ssh_only') if $opt{accept} && $use ne 'ssh';

	ensure_dir($root);
	throw('cli.init.bad_root', { root => $root }) unless -d $root;
	$root = abs_path($root);

	my $marker = File::Spec->catfile($root, $ROOT_MARKER);
	write_atomic($marker, $MARKER_TEXT) unless -e $marker;

	if (defined $server_root) {
		ensure_dir($server_root);
		$server_root = abs_path($server_root);
	}

	my $config = App::FileSync::Config::load_client($opt{config});
	$config->{client_id} = _default_client_id() unless defined $config->{client_id} && length $config->{client_id};
	$config->{client_id} = $opt{id} if defined $opt{id} && length $opt{id};

	my %optional = (
		server_root       => $server_root,
		server            => $server,
		port              => $opt{port},
		identity          => $opt{identity},
		known_hosts       => $known,
		host_key_checking => $opt{accept} ? 'accept-new' : undef,
		server_command    => $opt{'server-command'},
		snapshot_mode     => $mode,
	);
	$config->{repos}{$repo} = {
		root             => $root,
		remote_repo      => (defined $opt{'remote-repo'} && length $opt{'remote-repo'}) ? $opt{'remote-repo'} : $repo,
		role             => $role,
		transport        => $use,
		local_trash_days => $LOCAL_TRASH_DAYS,
		map { $_ => $optional{$_} } grep { defined $optional{$_} && length $optional{$_} } keys %optional,
	};

	my $path = App::FileSync::Config::save_client($config, $opt{config});

	_say('cli.init.done', { repo => $repo });
	_say('cli.init.client_id', { id => $config->{client_id} });
	_say('cli.init.root', { root => $root });
	_say('cli.init.transport', { transport => $use });
	if ($use eq 'ssh') {
		_say('cli.init.server', { server => $server });
		_say($opt{accept} ? 'cli.init.host_key_tofu' : 'cli.init.host_key_strict');
	}
	_say('cli.init.config', { path => $path });

	return $EXIT_OK;
}

# _check_id
# Purpose:     validate an id given to init.
# Entry:       $validate is validate_repo_name or validate_client_id.
# Exit:        returns 1.
# Side effects: raises cli.init.bad_id with the validator's reason.
sub _check_id :Private {
	my ($validate, $value) = @_;

	my ($ok, $reason) = $validate->($value);
	throw('cli.init.bad_id', { reason => $reason }) unless $ok;
	return 1;
}

# _client_sync
# Purpose:     filesync sync: sync each selected repo.
# Entry:       @args are sync's options.
# Exit:        returns 1 if any repo failed, else 3 if any warned, else 2 if
#              any was locked, else 0.
# Side effects: syncs; prints a summary per repo (or JSON); logs errors.
#              One repo failing does not stop the others.
sub _client_sync :Private {
	my (@args) = @_;

	my (%opt, @given);
	_options(\@args, {
		'repo=s@' => \@given,
		(map { ($_ => \$opt{$_}) } qw(dry-run force verbose quiet json no-prune no-delta)),
		'config=s' => \$opt{config},
	}, 'sync');

	my $config = App::FileSync::Config::load_client($opt{config});
	my $names = _repos($config, \@given, 1);
	my $logger = App::FileSync::Settings::logger(verbose => $opt{verbose}, quiet => $opt{quiet});
	my $client_opts = { map { (my $key = $_) =~ tr/-/_/; $key => $opt{$_} } qw(dry-run force no-prune no-delta verbose) };

	my (@results, @errors, %seen);
	for my $name (@{$names}) {
		my $result = eval { _client($config, $name, opts => $client_opts, logger => $logger)->sync() };
		unless ($result) {
			my $error = strip_location($@);
			push @errors, { repo => $name, error => $error };
			$logger->error(message('cli.repo_error', { repo => $name, error => $error })) unless $opt{json};
			$seen{$EXIT_FATAL} = 1;
			next;
		}

		push @results, $result;
		my $exit = $result->{exit} || $EXIT_OK;
		$seen{$exit} = 1;
		if ($exit == $EXIT_LOCKED) {
			$logger->warn(message('cli.repo_error', { repo => $name, error => $result->{error} })) unless $opt{json} || $opt{quiet};
			next;
		}

		_print_sync($name, $result, \%opt) unless $opt{json};
	}

	print json_encode({ results => \@results, errors => \@errors }), "\n" if $opt{json};

	# Severity order, not numeric order: a failure outranks warnings, which
	# outrank a lock refusal (nothing went wrong; it just did not run).
	return (first { $seen{$_} } $EXIT_FATAL, $EXIT_WARNINGS, $EXIT_LOCKED) // $EXIT_OK;
}

# _print_sync
# Purpose:     the text report of one repo's sync.
# Entry:       $result is a sync result; $opt the parsed options.
# Exit:        returns 1.
# Side effects: prints the planned actions (dry run), the counts, the
#              transfer accounting (a dry run sends no payloads, so it has
#              none) and, unless --quiet, the warnings.
sub _print_sync :Private {
	my ($name, $result, $opt) = @_;

	if ($opt->{'dry-run'}) {
		for my $action (@{ $result->{actions} || [] }) {
			(my $verb = $action->{a}) =~ tr/_/ /;
			_say('cli.sync.would', { verb => $verb, path => $action->{p} });
		}
	}

	my $summary = $result->{summary} || {};
	_say('cli.sync.summary', {
		repo => $name,
		dry  => $opt->{'dry-run'} ? message('cli.sync.dry_tag') : '',
		map { $_ => $summary->{$_} || 0 } qw(pulled pushed deleted conflicts),
	});
	_say('cli.sync.transfer', { report => _transfer_report($summary) }) unless $opt->{'dry-run'};

	_print_warnings($result->{warnings}) unless $opt->{quiet};
	return 1;
}

# _print_warnings
# Purpose:     print warnings, one per line.
# Entry:       $warnings is an arrayref or undef.
# Exit:        returns 1.
# Side effects: prints.
sub _print_warnings :Private {
	my ($warnings) = @_;

	_say('cli.warning', { warning => $_ }) for @{ $warnings || [] };
	return 1;
}

# _client_status
# Purpose:     filesync status: when each repo last synced, and how big it is.
# Entry:       @args are status's options.
# Exit:        returns 0.
# Side effects: reads each repo's cache; prints.
sub _client_status :Private {
	my (@args) = @_;

	my (@given, %opt);
	_options(\@args, { 'repo=s@' => \@given, json => \$opt{json}, 'config=s' => \$opt{config} }, 'status');

	my $config = App::FileSync::Config::load_client($opt{config});
	my @status;
	for my $name (@{ _repos($config, \@given, 0) }) {
		my $repo = $config->{repos}{$name};
		my $cache = _client($config, $name)->cache();
		my $last = ref($cache->{last_run}) eq 'HASH' ? $cache->{last_run} : undef;

		push @status, {
			repo         => $name,
			root         => $repo->{root},
			transport    => $repo->{transport} || 'ssh',
			last_run     => $last ? scalar(gmtime($last->{ts})) . ' UTC' : 'never',
			last_summary => $last ? $last->{summary} : undef,
			files        => scalar(grep { ($_->{t} || $TYPE_FILE) eq $TYPE_FILE } values %{ $cache->{entries} }),
		};
	}

	if ($opt{json}) {
		print json_encode({ repos => \@status }), "\n";
		return $EXIT_OK;
	}

	for my $entry (@status) {
		_say('cli.status.repo', $entry);
		_say('cli.status.transport', $entry);
		# JSON keeps the literal 'never' (it is data); the text is translated.
		_say('cli.status.last_run', { last_run => $entry->{last_run} eq 'never' ? message('cli.never') : $entry->{last_run} });

		# Caches written before the byte counters existed have no transfer
		# figures; skip the line rather than invent zeros.
		my $summary = $entry->{last_summary};
		_say('cli.status.transfer', { report => _transfer_report($summary) })
			if ref($summary) eq 'HASH' && defined $summary->{bytes_sent};
		_say('cli.status.files', $entry);
	}

	return $EXIT_OK;
}

# _client_log
# Purpose:     filesync log: recent run attempts per repo.
# Entry:       @args are log's options.
# Exit:        returns 0.
# Side effects: reads the run logs; prints (or JSON).  Bad dates are
#              reported before any repo is touched.
sub _client_log :Private {
	my (@args) = @_;

	my (@given, @exits, %opt);
	_options(\@args, {
		'repo=s@' => \@given,
		'n=i'     => \$opt{limit},
		'exit=i@' => \@exits,
		(map { ("$_=s" => \$opt{$_}) } qw(since until config)),
		(map { ($_ => \$opt{$_}) } qw(warnings json)),
	}, 'log');
	_no_more(\@args, 'log');
	throw('cli.positive', { command => 'log', option => '-n' }) if defined $opt{limit} && $opt{limit} < 1;
	_check_exits(\@exits);
	_check_window(@opt{qw(since until)});

	my $config = App::FileSync::Config::load_client($opt{config});
	my @results;
	for my $name (@{ _repos($config, \@given, 1) }) {
		my $result = _client($config, $name)->log(
			limit => $opt{limit}, since => $opt{since}, until => $opt{until}, exits => \@exits, warnings => $opt{warnings},
		);
		push @results, $result;
		_print_runs($name, $result->{runs}) unless $opt{json};
	}

	print json_encode({ results => \@results }), "\n" if $opt{json};
	return $EXIT_OK;
}

# _print_runs
# Purpose:     the text form of one repo's run log.
# Entry:       $runs is from Client->log.
# Exit:        returns 1.
# Side effects: prints one line per run (and its warnings).  A failed or
#              lock-refused attempt has no counts worth printing: its
#              message explains it.  Entries older than the byte counters
#              keep the shorter line.
sub _print_runs :Private {
	my ($name, $runs) = @_;

	return _say('cli.log.none', { repo => $name }) unless @{$runs};

	for my $run (@{$runs}) {
		my %line = (repo => $name, ts => format_utc($run->{ts}), exit => $run->{exit} || 0);

		if (defined $run->{error} && length $run->{error}) {
			(my $text = $run->{error}) =~ s/\s+/ /g;
			_say('cli.log.error', { %line, message => $text });
			next;
		}

		my $summary = $run->{summary} || {};
		_say('cli.log.run', {
			%line,
			(map { $_ => $summary->{$_} || 0 } qw(pulled pushed deleted conflicts)),
			skipped  => $summary->{skipped} ? message('cli.log.skipped', { count => $summary->{skipped} }) : '',
			transfer => (!$run->{dry_run} && defined $summary->{bytes_sent}) ? ', ' . _transfer_report($summary) : '',
			dry      => $run->{dry_run} ? message('cli.log.dry_tag') : '',
		});
		_print_warnings($run->{warnings});
	}

	return 1;
}

# _client_settings
# Purpose:     filesync settings: effective settings and where each came from.
# Entry:       @args are settings's options.
# Exit:        returns 0.
# Side effects: reads the settings and the client configuration; prints.
sub _client_settings :Private {
	my (@args) = @_;

	my %opt;
	_options(\@args, { json => \$opt{json}, 'config=s' => \$opt{config} }, 'settings');
	_no_more(\@args, 'settings');

	my $report = App::FileSync::Settings::explain();
	my $client_file = (defined $opt{config} && length $opt{config}) ? $opt{config} : App::FileSync::Config::client_config_path();
	$report->{config_file} = $client_file;
	$report->{repos} = App::FileSync::Settings::explain_repos(
		config      => App::FileSync::Config::load_client($opt{config}),
		report      => $report,
		config_file => $client_file,
	);

	if ($opt{json}) {
		print json_encode($report), "\n";
		return $EXIT_OK;
	}

	my $file = $report->{settings_file};
	_say('cli.settings.file', { file => (defined $file && length $file) ? $file : message('cli.settings.no_file') });
	print "\n";
	_say('cli.settings.row', { key => $_->{key}, value => _display_setting($_), source => _describe_source($_) })
		for @{ $report->{settings} };
	print "\n";
	_say('cli.settings.note');

	my @repos = @{ $report->{repos} || [] };
	return $EXIT_OK unless @repos;

	print "\n";
	_say('cli.settings.repos');
	for my $repo (@repos) {
		_say('cli.settings.repo', { %{$repo}, server => defined $repo->{server} ? ", $repo->{server}" : '' });
		unless (defined $repo->{ssh}) {
			_say('cli.settings.local');
			next;
		}
		_say('cli.settings.repo_row', { key => $_->{key}, value => _display_setting($_), source => _describe_repo_source($_) })
			for @{ $repo->{ssh} };
	}

	return $EXIT_OK;
}

# _describe_repo_source / _describe_source / _display_setting
# Purpose:     the text columns of "filesync settings".
# Entry:       $row is a row from Settings::explain or explain_repos.
# Exit:        returns the text.
# Side effects: none.  Port and host-key checking have no process-wide
#              fallback, so their rows say [repo only]; a blank value that
#              means "the transport's default" is named rather than shown
#              as an empty column.
sub _describe_repo_source :Private {
	my ($row) = @_;

	my $description = message("cli.repo_source.$row->{source}", $row);
	return $row->{repo_only} ? message('cli.source.repo_only', { description => $description }) : $description;
}

sub _describe_source :Private {
	my ($row) = @_;

	# Config::Abstraction reports file-like sources under several names.
	my $source = $row->{source} =~ /\A(?:default|merged|env)\z/ ? $row->{source} : 'file';
	return message("cli.source.$source", $row);
}

sub _display_setting :Private {
	my ($row) = @_;

	my $value = $row->{value};
	my $blank = $BLANK_SETTING{ $row->{key} };
	return (!(defined $value && length $value) && $blank) ? message($blank) : $value // '';
}

# _client_verify
# Purpose:     filesync verify: compare each repo's tree with its base.
# Entry:       @args are verify's options.
# Exit:        returns 4 if any repo drifted, else 0.
# Side effects: reads the trees; prints (or JSON).
sub _client_verify :Private {
	my (@args) = @_;

	my (@given, %opt);
	_options(\@args, { 'repo=s@' => \@given, (map { ($_ => \$opt{$_}) } qw(deep json)), 'config=s' => \$opt{config} }, 'verify');
	_no_more(\@args, 'verify');

	my $config = App::FileSync::Config::load_client($opt{config});
	my @reports = map { _client($config, $_)->verify(deep => $opt{deep}) } @{ _repos($config, \@given, 1) };

	if ($opt{json}) {
		print json_encode({ results => \@reports }), "\n";
	} else {
		_print_verify($_, 1) for @reports;
	}

	return (any { !$_->{ok} } @reports) ? $EXIT_DRIFT : $EXIT_OK;
}

# _print_verify
# Purpose:     the text form of a verify report (client or admin).
# Entry:       $report is from Verify; $base_note says whether to mention a
#              missing base (client only: the admin always has an index).
# Exit:        returns 1.
# Side effects: prints.
sub _print_verify :Private {
	my ($report, $base_note) = @_;

	_say('cli.verify.summary', {
		repo     => $report->{repo},
		state    => message($report->{ok} ? 'cli.verify.clean' : 'cli.verify.drift'),
		files    => message('word.file', { count => $report->{files} || 0 }),
		rehashed => $report->{rehashed},
		trusted  => $report->{trusted},
	});
	_say('cli.verify.no_base') if $base_note && !$report->{known};

	for my $entry (@{ $report->{modified} }) {
		_say('cli.verify.modified', { path => $entry->{p}, reason => defined $entry->{reason} ? " ($entry->{reason})" : '' });
	}
	_say('cli.verify.missing', { path => $_->{p} }) for @{ $report->{missing} };
	_say('cli.verify.extra', { path => $_->{p} }) for @{ $report->{extra} };

	return 1;
}

# _client_restore
# Purpose:     filesync restore: put a path back from the local trash.
# Entry:       @args are PATH and options.
# Exit:        returns 0.
# Side effects: copies the version out, or lists versions.
sub _client_restore :Private {
	my (@args) = @_;

	my %opt;
	_options(\@args, { (map { ("$_=s" => \$opt{$_}) } qw(repo to config)), list => \$opt{list} }, 'restore');
	my $path = _require(shift @args, 'restore', 'PATH');
	_no_more(\@args, 'restore');

	my $config = App::FileSync::Config::load_client($opt{config});
	my $name = _one_repo($config, $opt{repo}, 'restore');
	my $result = _client($config, $name)->restore(path => $path, to => $opt{to}, list => $opt{list});

	return _print_versions($result->{versions}, 'cli.restore.no_versions', { path => $path }) if $opt{list};

	_say('cli.restore.done', { path => $path, to => $result->{to} });
	return $EXIT_OK;
}

# _print_versions
# Purpose:     list trashed versions (client or admin).
# Entry:       $versions are Trash::version_info rows; $empty_key and
#              $empty_args say what to print when there are none.
# Exit:        returns 0.
# Side effects: prints.
sub _print_versions :Private {
	my ($versions, $empty_key, $empty_args) = @_;

	return _say($empty_key, $empty_args) && $EXIT_OK unless @{$versions};

	for my $version (@{$versions}) {
		_say('cli.restore.version', {
			date  => $version->{date} // '-',
			size  => defined $version->{size} ? _format_bytes($version->{size}) : '-',
			mtime => defined $version->{mtime} ? scalar(gmtime($version->{mtime})) . ' UTC' : '-',
			path  => $version->{path},
		});
	}

	return $EXIT_OK;
}

# _client_snapshot
# Purpose:     filesync snapshot [create|take|list|restore].
# Entry:       @args start with the verb, or an option (meaning create).
# Exit:        returns the sub-command's exit code.
# Side effects: raises cli.unknown_snapshot.
sub _client_snapshot :Private {
	my (@args) = @_;

	my $verb = (@args && $args[0] !~ /\A-/) ? shift @args : 'create';
	my %verbs = (create => '_client_snapshot_create', take => '_client_snapshot_create',
		list => '_client_snapshot_list', restore => '_client_snapshot_restore');
	my $handler = $verbs{$verb} or throw('cli.unknown_snapshot', { verb => $verb });

	return __PACKAGE__->can($handler)->(@args);
}

# _client_snapshot_create
# Purpose:     take today's snapshot of a replica, pruning old ones.
# Entry:       @args are the options.
# Exit:        returns 0, or 2 when another run holds the lock.
# Side effects: creates and prunes snapshots; prints.
sub _client_snapshot_create :Private {
	my (@args) = @_;

	my %opt;
	_options(\@args, { 'repo=s' => \$opt{repo}, 'keep=i' => \$opt{keep}, 'config=s' => \$opt{config} }, 'snapshot');
	_no_more(\@args, 'snapshot');
	throw('cli.positive', { command => 'snapshot', option => '--keep' }) if defined $opt{keep} && $opt{keep} < 1;

	my $config = App::FileSync::Config::load_client($opt{config});
	my $name = _one_repo($config, $opt{repo}, 'snapshot');
	my $result = _client($config, $name)->snapshot_create(keep => $opt{keep});
	return _warn_locked($name, $result) if ($result->{exit} || 0) == $EXIT_LOCKED;

	return _say('cli.snapshot.exists', { repo => $name, date => $result->{date} }) && $EXIT_OK unless $result->{created};

	_say('cli.snapshot.taken', {
		repo  => $name,
		date  => $result->{date},
		files => message('word.file', { count => $result->{files} }),
		size  => _format_bytes($result->{bytes}),
		path  => $result->{path},
	});

	my @pruned = @{ $result->{pruned} || [] };
	_say('cli.snapshot.pruned', { repo => $name, count => scalar @pruned, kept => scalar @{ $result->{older} || [] }, dates => "@pruned" })
		if @pruned;

	return $EXIT_OK;
}

# _client_snapshot_list
# Purpose:     list a replica's snapshots.
# Entry:       @args are the options.
# Exit:        returns 0.
# Side effects: prints.
sub _client_snapshot_list :Private {
	my (@args) = @_;

	my %opt;
	_options(\@args, { 'repo=s' => \$opt{repo}, 'config=s' => \$opt{config} }, 'snapshot_list');
	_no_more(\@args, 'snapshot list');

	my $config = App::FileSync::Config::load_client($opt{config});
	my $name = _one_repo($config, $opt{repo}, 'snapshot list');
	my $snapshots = _client($config, $name)->snapshot_list()->{snapshots};

	return _say('cli.snapshot.none', { repo => $name }) && $EXIT_OK unless @{$snapshots};

	_say('cli.snapshot.header', { map { $_ => message("cli.snapshot.column.$_") } qw(date files size path) });
	_say('cli.snapshot.row', { %{$_}, size => _format_bytes($_->{bytes}) }) for @{$snapshots};
	return $EXIT_OK;
}

# _client_snapshot_restore
# Purpose:     copy a snapshot (or one path) back.
# Entry:       @args are DATE [PATH] and options.
# Exit:        returns 0, or 2 when another run holds the lock.
# Side effects: replaces files; prints, with a reminder that a replica is
#              mirrored again on its next sync.
sub _client_snapshot_restore :Private {
	my (@args) = @_;

	my %opt;
	_options(\@args, { map { ("$_=s" => \$opt{$_}) } qw(repo to config) }, 'snapshot_restore');
	my $date = _require(shift @args, 'snapshot restore', 'DATE');
	my $path = shift @args;
	_no_more(\@args, 'snapshot restore');

	my $config = App::FileSync::Config::load_client($opt{config});
	my $name = _one_repo($config, $opt{repo}, 'snapshot restore');
	my $result = _client($config, $name)->snapshot_restore(date => $date, path => $path, to => $opt{to});
	return _warn_locked($name, $result) if ($result->{exit} || 0) == $EXIT_LOCKED;

	_say('cli.snapshot.restored', {
		repo  => $name,
		what  => @{ $result->{paths} } ? "@{ $result->{paths} }" : message('cli.snapshot.whole_tree'),
		date  => $result->{date},
		files => message('word.file', { count => $result->{files} }),
		size  => _format_bytes($result->{bytes}),
		to    => $result->{to},
	});
	_say('cli.snapshot.into_root') if $result->{into_root};

	return $EXIT_OK;
}

# _warn_locked
# Purpose:     report a lock refusal from a snapshot command.
# Entry:       $result has error.
# Exit:        returns 2.
# Side effects: logs a warning.
sub _warn_locked :Private {
	my ($name, $result) = @_;

	App::FileSync::Settings::logger()->warn(message('cli.repo_error', { repo => $name, error => $result->{error} }));
	return $EXIT_LOCKED;
}

# ------------------------------------------------------------ formatting

# _format_bytes
# Purpose:     a byte count for people: B, kB, MB or GB with one decimal.
# Entry:       $bytes may be undef (shown as 0).
# Exit:        returns the text.
# Side effects: none.
sub _format_bytes :Private {
	my ($bytes) = @_;

	$bytes //= 0;
	my $unit = first { $bytes >= $_->[0] } @SIZE_UNITS;
	return $unit
		? message('cli.size.scaled', { value => $bytes / $unit->[0], unit => $unit->[1] })
		: message('cli.size.bytes', { value => $bytes });
}

# _bytes_exact
# Purpose:     an exact byte count with thousands separators.
# Entry:       $bytes may be undef or junk (shown as 0).
# Exit:        returns the text.
# Side effects: none.  Transfer accounting is exact: these bytes are what
#              the peer actually read, so rounding them would defeat it.
sub _bytes_exact :Private {
	my ($bytes) = @_;

	$bytes = 0 unless defined $bytes && $bytes =~ /\A\d+\z/;
	1 while $bytes =~ s/(\d)(\d{3})(?!\d)/$1,$2/;
	return message('cli.size.exact', { value => $bytes });
}

# _transfer_report
# Purpose:     one line of per-run accounting.
# Entry:       $summary has bytes_sent, bytes_received, delta_pulled,
#              delta_pushed.
# Exit:        returns the text: bytes each way, then how many files moved
#              as a delta rather than whole.
# Side effects: none.
sub _transfer_report :Private {
	my ($summary) = @_;

	my %delta = map { $_ => $summary->{"delta_$_"} || 0 } qw(pulled pushed);
	my @parts = map { message("cli.transfer.$_", { count => $delta{$_} }) } grep { $delta{$_} } qw(pulled pushed);

	return message('cli.transfer.report', {
		sent     => _bytes_exact($summary->{bytes_sent}),
		received => _bytes_exact($summary->{bytes_received}),
		files    => message('word.file', { count => $delta{pulled} + $delta{pushed} }),
		detail   => @parts ? ' (' . join(', ', @parts) . ')' : '',
	});
}

# _check_exits / _check_window
# Purpose:     validate log filters before anything is read.
# Entry:       exit codes; since and until (maybe undef).
# Exit:        returns 1.
# Side effects: raises cli.exit_range or when.bad.
sub _check_exits :Private {
	my ($exits) = @_;

	throw('cli.exit_range', { max => $EXIT_MAX }) if any { $_ < 0 || $_ > $EXIT_MAX } @{$exits};
	return 1;
}

sub _check_window :Private {
	my ($since, $until) = @_;

	parse_since($since) if defined $since;
	parse_until($until) if defined $until;
	return 1;
}

# _default_client_id
# Purpose:     a client id derived from the host name.
# Entry:       none.
# Exit:        returns a valid client id: the short host name, lower-cased,
#              with anything else replaced by '-', starting with a letter
#              or digit and at most 64 characters; "client" if nothing is
#              left.
# Side effects: none.
sub _default_client_id :Private {
	my $name = lc Sys::Hostname::hostname();
	$name =~ s/\..*//s;
	$name =~ s/[^a-z0-9._-]+/-/g;
	$name =~ s/\A[^a-z0-9]+//;
	$name = substr($name, 0, $MAX_ID_LENGTH);
	$name =~ s/-+\z//;

	return length $name ? $name : $ROLE_CLIENT;
}

# ------------------------------------------------------------------- admin

# _admin_dispatch
# Purpose:     filesync-admin: parse --root, then run the command.
# Entry:       @args is the command line.
# Exit:        returns the command's exit code.
# Side effects: raises cli.admin.* for an unknown command or verb.
sub _admin_dispatch :Private {
	my (@args) = @_;

	my $root = $ENV{FILESYNC_ROOT};
	while (@args && $args[0] =~ /\A--root(?:=(.*))?\z/s) {
		shift @args;
		$root = defined $1 ? $1 : shift @args;
		throw('cli.admin.root_value') unless defined $root;
	}

	my $group = shift(@args) // 'help';
	if ($group eq 'help' || $group eq '--help') {
		print message('cli.help.admin');
		return $EXIT_OK;
	}

	my $admin = App::FileSync::Admin->new(root => $root);
	my $entry = $ADMIN_COMMANDS{$group} or throw('cli.unknown_command', { command => $group, program => 'filesync-admin' });

	unless (ref $entry) {
		return __PACKAGE__->can($entry)->($admin, @args);
	}

	my $verb = shift(@args) // '';
	my $handler = $entry->{$verb} or throw('cli.admin.unknown_verb', { group => $group, verb => $verb });
	return __PACKAGE__->can($handler)->($admin, @args);
}

# _admin_repo_create / _admin_repo_list / _admin_repo_show
# Purpose:     filesync-admin repo create|list|show.
# Entry:       $admin, then the command's arguments.
# Exit:        returns 0.
# Side effects: create makes the repo; all print.
sub _admin_repo_create :Private {
	my ($admin, @args) = @_;

	my (%opt, @ignore);
	_options(\@args, {
		(map { ("$_=i" => \$opt{$_}) } qw(trash-days max-deletes max-delete-percent)),
		'ignore=s' => \@ignore,
	}, 'repo_create');
	my $name = _require(shift @args, 'repo create', 'NAME');
	_no_more(\@args, 'repo create');

	my $result = $admin->repo_create(
		name               => $name,
		trash_days         => $opt{'trash-days'},
		max_deletes        => $opt{'max-deletes'},
		max_delete_percent => $opt{'max-delete-percent'},
		ignore             => \@ignore,
	);

	_say("cli.repo.created.$_", { %{$result}, repo => $result->{name} }) for qw(name master config);
	return $EXIT_OK;
}

sub _admin_repo_list :Private {
	my ($admin) = @_;

	my $repos = $admin->repo_list();
	return _say('cli.repo.none', { root => $admin->root }) && $EXIT_OK unless @{$repos};

	print "$_\n" for @{$repos};
	return $EXIT_OK;
}

sub _admin_repo_show :Private {
	my ($admin, @args) = @_;

	my $info = $admin->repo_show(_require(shift @args, 'repo show', 'NAME'));
	my $config = $info->{config};
	_say('cli.repo.show', {
		%{$config},
		master  => $info->{master},
		meta    => $info->{meta},
		clients => @{ $info->{clients} } ? join(', ', @{ $info->{clients} }) : message('cli.repo.no_clients'),
	});

	return $EXIT_OK;
}

# _admin_log
# Purpose:     filesync-admin log: journal events for one or more repos.
# Entry:       $admin, then NAME... and options.
# Exit:        returns 0.
# Side effects: reads journals; prints (or JSON).  Every name is checked
#              before anything is printed, so text mode never shows a
#              partial answer before failing on a later repo.
sub _admin_log :Private {
	my ($admin, @args) = @_;

	my (@exits, %opt);
	_options(\@args, {
		'n=i'     => \$opt{limit},
		'exit=i@' => \@exits,
		(map { ("$_=s" => \$opt{$_}) } qw(client since until)),
		(map { ($_ => \$opt{$_}) } qw(warnings json)),
	}, 'admin_log');
	_check_exits(\@exits);
	_check_window(@opt{qw(since until)});

	my @names = @args;
	throw('cli.required', { command => 'log', what => 'NAME' }) unless @names;
	throw('cli.admin.empty_name') if any { !defined $_ || !length $_ } @names;
	App::FileSync::Config::load_repo($admin->root, $_) for @names;

	my $multiple = @names > 1;
	my @results;
	for my $name (@names) {
		my %filters = (
			(defined $opt{client} && length $opt{client} ? (client => $opt{client}) : ()),
			(defined $opt{since} ? (since => parse_since($opt{since})) : ()),
			(defined $opt{until} ? (until => parse_until($opt{until})) : ()),
			(@exits ? (exits => [ map { $_ + 0 } @exits ]) : ()),
			($opt{warnings} ? (warnings => 1) : ()),
		);
		my $events = $admin->journal_read(
			repo => $name, limit => $opt{limit} // $ADMIN_LOG_LIMIT, client => $opt{client},
			since => $opt{since}, until => $opt{until}, exits => \@exits, warnings => $opt{warnings},
		);
		push @results, { repo => $name, path => $admin->journal_dir($name), events => $events, %filters };
		next if $opt{json};

		# With one repo the lines stand alone; with several, head each group.
		_say('cli.log.heading', { repo => $name }) if $multiple;
		_say('cli.log.no_events', { repo => $name }) unless @{$events};
		_say('cli.log.event', {
			indent => $multiple ? '  ' : '',
			ts     => format_utc($_->{ts}),
			client => $_->{client} // '-',
			action => $_->{action} // '?',
			detail => _event_detail($_),
		}) for @{$events};
	}

	print json_encode({ results => \@results }), "\n" if $opt{json};
	return $EXIT_OK;
}

# _event_detail
# Purpose:     the free-form tail of a journal line.
# Entry:       $event is a journal event.
# Exit:        returns the text: path, key=value fields, counters, flags,
#              then the error with its white space flattened.
# Side effects: none.
sub _event_detail :Private {
	my ($event) = @_;

	my @detail = grep { defined } $event->{path};
	push @detail, map { ($EVENT_LABEL{$_} // $_) . "=$event->{$_}" } grep { defined $event->{$_} } @EVENT_FIELDS, @EVENT_COUNTERS;
	push @detail, 'dry-run' if $event->{dry_run};
	push @detail, 'locked' if $event->{locked};

	if (defined $event->{error} && length $event->{error}) {
		(my $text = $event->{error}) =~ s/\s+/ /g;
		push @detail, $text;
	}

	return join(' ', @detail);
}

# _admin_reindex
# Purpose:     filesync-admin reindex: rebuild the master index.
# Entry:       $admin, then NAME and options.
# Exit:        returns 0.
# Side effects: rewrites the index (unless --dry-run); prints (or JSON).
sub _admin_reindex :Private {
	my ($admin, @args) = @_;

	my %opt;
	_options(\@args, { (map { ($_ => \$opt{$_}) } qw(dry-run json)) }, 'reindex');
	my $name = _require(shift @args, 'reindex', 'NAME');
	_no_more(\@args, 'reindex');

	my $result = $admin->reindex(repo => $name, dry_run => $opt{'dry-run'});
	if ($opt{json}) {
		print json_encode($result), "\n";
		return $EXIT_OK;
	}

	_say($opt{'dry-run'} ? 'cli.reindex.would' : 'cli.reindex.done', {
		repo  => $name,
		files => message('word.file', { count => $result->{files} }),
		dirs  => message('word.empty_dir', { count => $result->{dirs} }),
		size  => _format_bytes($result->{bytes}),
	});
	_say('cli.reindex.skipped', { path => $_, reason => $result->{skipped}{$_} }) for sort keys %{ $result->{skipped} || {} };

	return $EXIT_OK;
}

# _admin_verify
# Purpose:     filesync-admin verify: rehash the master against its index.
# Entry:       $admin, then NAME and options.
# Exit:        returns 4 on drift, else 0.
# Side effects: reads the master; prints (or JSON).
sub _admin_verify :Private {
	my ($admin, @args) = @_;

	my %opt;
	_options(\@args, { deep => \$opt{deep}, 'sample=i' => \$opt{sample}, json => \$opt{json} }, 'admin_verify');
	my $name = _require(shift @args, 'verify', 'NAME');
	_no_more(\@args, 'verify');
	throw('cli.positive', { command => 'verify', option => '--sample' }) if defined $opt{sample} && $opt{sample} < 1;

	my $report = $admin->verify(repo => $name, deep => $opt{deep}, sample => $opt{sample});
	$opt{json} ? print(json_encode($report), "\n") : _print_verify($report, 0);

	return $report->{ok} ? $EXIT_OK : $EXIT_DRIFT;
}

# _admin_restore
# Purpose:     filesync-admin restore: put a path back from the server trash.
# Entry:       $admin, then NAME PATH and options.
# Exit:        returns 0.
# Side effects: restores into the master or --to; or lists versions.
sub _admin_restore :Private {
	my ($admin, @args) = @_;

	my %opt;
	_options(\@args, { 'to=s' => \$opt{to}, list => \$opt{list}, 'date=s' => \$opt{date} }, 'admin_restore');
	my ($name, $path) = splice(@args, 0, 2);
	throw('cli.required', { command => 'restore', what => 'NAME and PATH' })
		unless defined $name && length $name && defined $path && length $path;
	_no_more(\@args, 'restore');

	my $result = $admin->restore(repo => $name, path => $path, %opt);
	return _print_versions($result->{versions}, 'cli.restore.no_versions_in', { path => $path, repo => $name }) if $opt{list};

	_say('cli.restore.admin_done', {
		repo => $name,
		path => $path,
		from => $result->{date} // message('cli.restore.the_trash'),
		to   => $result->{to},
	});
	return $EXIT_OK;
}

# _admin_client_allow / _admin_client_list / _admin_client_forget
# Purpose:     filesync-admin client allow|list|forget.
# Entry:       $admin, then the command's arguments.
# Exit:        returns 0.
# Side effects: allow and forget change the repo; all print.
sub _admin_client_allow :Private {
	my ($admin, @args) = @_;

	my %opt;
	_options(\@args, { 'repo=s' => \$opt{repo}, 'role=s' => \$opt{role} }, 'client_allow');
	my $client = _require(shift @args, 'client allow', 'ID');
	my $repo = _require($opt{repo}, 'client allow', '--repo');

	my $result = $admin->client_allow(repo => $repo, client => $client, role => $opt{role});
	_say('cli.client.allowed', { %{$result}, repo => $repo });
	return $EXIT_OK;
}

sub _admin_client_list :Private {
	my ($admin, @args) = @_;

	my %opt;
	_options(\@args, { 'repo=s' => \$opt{repo} }, 'client_list');
	my $repo = _require($opt{repo}, 'client list', '--repo');

	my $clients = $admin->client_list($repo);
	return _say('cli.client.none', { repo => $repo }) && $EXIT_OK unless @{$clients};

	_say('cli.client.row', { %{$_}, state => message($_->{base} ? 'cli.client.synced' : 'cli.client.never') }) for @{$clients};
	return $EXIT_OK;
}

sub _admin_client_forget :Private {
	my ($admin, @args) = @_;

	my %opt;
	_options(\@args, { 'repo=s' => \$opt{repo} }, 'client_forget');
	my $repo = _require($opt{repo}, 'client forget', '--repo');
	my $client = _require(shift @args, 'client forget', 'ID');

	my $result = $admin->client_forget(repo => $repo, client => $client);
	_say($result->{removed} ? 'cli.client.forgot' : 'cli.client.nothing', { client => $client, path => $result->{path} });
	return $EXIT_OK;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * Option parsing is Getopt::Long's: its own diagnostics for an unknown
option are printed in English before the catalogued usage line.

=item * C<--json> output is not localised (field names and values such as
C<never> are data), while the text output is.

=item * C<filesync-admin> reads C<--root> only before the command name.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
