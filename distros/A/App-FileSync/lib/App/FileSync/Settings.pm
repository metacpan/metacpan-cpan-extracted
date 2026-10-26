package App::FileSync::Settings;

# Process-wide settings (logging and SSH defaults) read through
# Object::Configure, and the logger built from them.  The repos themselves stay
# in ~/.filesync/config.json, which "filesync init" writes and the admin tool
# edits; this module never touches that store.

# First, so the Windows end-of-scope hook is chosen before Log::Abstraction
# (through namespace::clean) or Sub::Private loads B::Hooks::EndOfScope.
use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

# 0.41 for explain_sources(), which the settings report uses; an older copy
# autoloads that name as a config key and dies with "No such config key".
use Config::Abstraction 0.41;
use File::Basename qw(dirname);
use File::Spec;
use List::Util qw(any first);
# 0.36 for the structured fields the client passes as a trailing hashref;
# an older copy appends it to the message as "HASH(0x...)" in a log file and
# records an empty entry in an array logger.
use Log::Abstraction 0.36;
use Object::Configure;
use Readonly;
use Sub::Private { mode => 'enforce' };

use App::FileSync::Args qw(named);
use App::FileSync::I18N qw(throw);
use App::FileSync::IO qw(ensure_dir);

use version; our $VERSION = version->declare('0.001.5');

# The hook predicates moved to App::FileSync::Platform, which must load before
# this module's dependencies; these names are kept for existing callers.
{
	no warnings 'once';
	*wants_plain_end_of_scope_hook = \&App::FileSync::Platform::wants_plain_end_of_scope_hook;
	*use_plain_end_of_scope_hook   = \&App::FileSync::Platform::use_plain_end_of_scope_hook;
}

# Package variables, not Readonly: they are documented and tests may localise them.
our $DEFAULT_FORMAT  = '%level%: %message%';
our $DEFAULT_LEVEL   = 'warning';
our $CONFIG_BASENAME = 'app-filesync.json';

# Defaults for every SSH repo.  A repo's own config still wins, so one machine
# can point at another identity without repeating the common settings.
our $DEFAULT_SERVER_COMMAND = 'filesync-server';

our @VALID_LEVELS = qw(
	trace debug info informational notice warn warning error err
	crit critical fatal alert emerg emergency panic
);

# The process-wide settings, in the order "filesync settings" prints them.
our @SETTING_KEYS = qw(
	log_level log_format log_file
	ssh_identity ssh_known_hosts server_command
);

# How each repo-level SSH key corresponds to the process setting it falls back
# to.  The names differ only because the repo config uses shorter keys.
our %REPO_SSH_KEYS = (
	ssh_identity    => 'identity',
	ssh_known_hosts => 'known_hosts',
	server_command  => 'server_command',
);
our @REPO_SSH_SETTINGS = qw(ssh_identity ssh_known_hosts server_command);

# Section names Object::Configure and Config::Abstraction use.
Readonly my $CLASS_SECTION     => 'App__FileSync';
Readonly my $UNIVERSAL_SECTION => 'UNIVERSAL';
Readonly my $CONF_DIR          => '.conf';

# Settings that only a repo records: there is no process-wide layer, and ssh's
# own default applies when the repo leaves them out.
Readonly my @REPO_ONLY => ([ port => '22' ], [ host_key_checking => 'yes' ]);

# Provenance labels for "filesync settings".
Readonly my $LABEL_DEFAULT     => 'built-in default';
Readonly my $LABEL_SSH_DEFAULT => 'ssh default';
Readonly my $LABEL_UNKNOWN     => 'unknown source';

# Object::Configure's search order for a universal file beside the settings file.
Readonly my @UNIVERSAL_EXTENSIONS => qw(.conf .yml .yaml .json);

# The arguments load, explain and logger share.
my %FILE_ARGS = (
	config_file => { type => 'string', optional => 1 },
	config_dirs => { type => 'arrayref', optional => 1 },
);

=encoding utf8

=head1 NAME

App::FileSync::Settings - process-wide settings and logging for App::FileSync

=head1 SYNOPSIS

	use App::FileSync::Settings;

	my $logger = App::FileSync::Settings::logger(verbose => 1);
	$logger->error('...');

	my $settings = App::FileSync::Settings::load();
	my $level = $settings->{log_level};

	my $report = App::FileSync::Settings::explain();
	printf "%s = %s (%s)\n", $_->{key}, $_->{value}, $_->{label}
		for @{ $report->{settings} };

=head1 DESCRIPTION

Settings that apply to the process rather than to one repo - the log level,
format and destination, plus the SSH identity, known-hosts file and remote
server command - are read through L<Object::Configure>.  The repos themselves
remain in F<~/.filesync/config.json>, which C<filesync init> writes; this
module does not replace that store.

The settings file is F<~/.conf/app-filesync.json> when it exists, or the path in
C<FILESYNC_SETTINGS>.  The section key is C<App__FileSync>, and a C<UNIVERSAL>
section in the same directory applies to every class that uses
Object::Configure.  Environment variables named C<App__FileSync__I<key>>
override the file:

	# ~/.conf/app-filesync.json
	{ "App__FileSync": { "log_level": "debug", "log_format": "%level%: %message%" } }

	# or
	export App__FileSync__log_level=debug

C<log_file> sends the log to a file instead of standard error; leading
directories are created.  C<log_format> is a L<Log::Abstraction> format string.

C<ssh_identity>, C<ssh_known_hosts> and C<server_command> are the defaults for
every SSH repo, so a per-repo C<identity>, C<known_hosts> or C<server_command>
(written by C<filesync init --identity> and friends) only has to be set when it
differs.  C<server_command> defaults to C<filesync-server>:

	{ "App__FileSync": {
		"ssh_identity"    : "~/.ssh/filesync_ed25519",
		"ssh_known_hosts" : "~/.ssh/filesync_known_hosts",
		"server_command"  : "/usr/local/bin/filesync-server"
	} }

Command output (sync summaries, plans, C<--json>) is written to standard output
by the commands themselves; the logger carries diagnostics on standard error,
so a cron job can separate the two.  C<--verbose> raises the level to C<debug>
and C<--quiet> lowers it to C<error> for that run, overriding the file.

C<wants_plain_end_of_scope_hook> and C<use_plain_end_of_scope_hook> are aliases
of the functions in L<App::FileSync::Platform>, kept for existing callers.

=head1 FUNCTIONS

=head2 config_file

Purpose: the settings file that would be used.

Args: an optional explicit path.

Returns: the explicit path when one is given; otherwise C<FILESYNC_SETTINGS> or
F<~/.conf/app-filesync.json> if that file exists; otherwise C<undef>.

Side Effects: none.

Usage:

	my $file = App::FileSync::Settings::config_file();

=head3 EXAMPLE

	my $file = App::FileSync::Settings::config_file() // 'none';
	print "settings: $file\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'given', type => 'string', optional => 1 } ]

=head4 OUTPUT

	{ type => 'string', optional => 1 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	config_file(g) = g                     if g ≠ ""
	config_file(g) = d                     if d = default_path ∧ d ∈ dom FS
	config_file(g) = ⊥                     otherwise

=cut

sub config_file {
	my ($given) = @_;

	return $given if defined $given && length $given;

	# A stale FILESYNC_SETTINGS must not fail every command: it is only a default.
	my $path = _default_config_path();
	return (defined $path && -e $path) ? $path : undef;
}

=head2 load

Purpose: the merged process settings.

Args: optional C<config_file> and C<config_dirs> (as for
L<Object::Configure/configure>).

Returns: a hashref with every key in C<@SETTING_KEYS>, built-in defaults
overlaid by the settings file, the C<UNIVERSAL> section and C<App__FileSync__*>
environment variables.

Side Effects: reads the settings file.  Dies (through Object::Configure) when
an explicit file does not exist.

Usage:

	my $settings = App::FileSync::Settings::load(config_file => $path);

=head3 EXAMPLE

	print App::FileSync::Settings::load()->{log_level}, "\n";	# warning

=head3 API SPECIFICATION

=head4 INPUT

	{
		config_file => { type => 'string', optional => 1 },
		config_dirs => { type => 'arrayref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key            Meaning                         Resolution
	args.invalid   an argument has the wrong type  fix the call

Object::Configure's own error for a missing explicit file is passed through.

=head3 FORMAL SPECIFICATION

	load(a) = defaults ⊕ file(config_file(a)) ⊕ universal ⊕ env

=cut

sub load {
	my $args = named(\@_, {%FILE_ARGS}, 'Settings::load');

	my $config_file = config_file($args->{config_file});

	my %params = (
		%{ _defaults() },
		# We build the logger ourselves; this keeps Object::Configure from
		# constructing its default Log::Log4perl backend as a side effect.
		logger => [],
	);
	$params{config_file} = $config_file if defined $config_file;
	$params{config_dirs} = $args->{config_dirs} if $args->{config_dirs};

	my $settings = Object::Configure::configure('App::FileSync', \%params);
	delete $settings->{logger};

	return $settings;
}

=head2 explain

Purpose: where each effective setting came from, for C<filesync settings>.

Args: as L</load>.

Returns: C<{ settings_file =E<gt> $path_or_undef, settings =E<gt> \@rows }>, one
row per key in C<@SETTING_KEYS>.  Each row has the effective C<value>, a
C<source> of C<default>, C<file>, C<env> or C<merged>, and a human-readable
C<label> naming the file section, environment variable or built-in default
that supplied it.

The values are whatever L</load> returns; the provenance is reconstructed from
the same layers Object::Configure merges.  A value no modelled layer accounts
for (a C<global> section, say) is reported as C<merged> rather than claimed as
a default.

Side Effects: reads the settings file and any universal file beside it.

Usage:

	my $report = App::FileSync::Settings::explain();

=head3 EXAMPLE

	for my $row (@{ App::FileSync::Settings::explain()->{settings} }) {
		printf "%-16s %-20s %s\n", $row->{key}, $row->{value}, $row->{label};
	}

=head3 API SPECIFICATION

=head4 INPUT

	{
		config_file => { type => 'string', optional => 1 },
		config_dirs => { type => 'arrayref', optional => 1 },
	}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			settings_file => { type => 'string', optional => 1 },
			settings      => { type => 'arrayref' },
		},
	}

=head3 MESSAGES

As L</load>.

=head3 FORMAL SPECIFICATION

	∀ k : SETTING_KEYS •
		row(k).value = load()(k)
		row(k).source = last layer ∈ ⟨default, universal, class⟩ that sets k,
		                or merged if that layer's value ≠ row(k).value

=head3 PSEUDOCODE

	load the settings
	explain the class and universal sections of the settings file, if any
	for each key:
		start from the built-in default
		let the universal section, then the class section, override it
		without a file, let UNIVERSAL__key then App__FileSync__key override it
		if the loaded value differs from the winner, call it merged

=cut

sub explain {
	my $args = named(\@_, {%FILE_ARGS}, 'Settings::explain');

	my $config_file = config_file($args->{config_file});
	my $settings = load(%{$args});
	my $defaults = _defaults();

	# Each layer is [ section explanation, label for a file entry ], lowest first.
	my @layers;
	if (defined $config_file) {
		my $universal = _universal_file($config_file);
		push @layers, [ _explanation($universal, $UNIVERSAL_SECTION), $UNIVERSAL_SECTION, "$universal [$UNIVERSAL_SECTION]" ]
			if defined $universal;
		push @layers, [ _explanation($config_file, $CLASS_SECTION), $CLASS_SECTION, "$config_file [$CLASS_SECTION]" ];
	}

	my @rows;
	for my $key (@SETTING_KEYS) {
		my %row = (key => $key, value => $settings->{$key}, source => 'default', label => $LABEL_DEFAULT);
		my $winner = $defaults->{$key};

		if (defined $config_file) {
			for my $layer (@layers) {
				my ($explanation, $section, $file_label) = @{$layer};
				my $entry = _pick($explanation, $section, $key) or next;
				$row{source} = $entry->{type};
				$row{label}  = $entry->{type} eq 'env' ? $entry->{label} : $file_label;
				$winner      = $entry->{value};
			}
		} else {
			# No settings file: Object::Configure falls back to environment
			# variables only, universal ones first and class ones last.
			for my $section ($UNIVERSAL_SECTION, $CLASS_SECTION) {
				my $name = _env_key("${section}__$key") // next;
				@row{qw(source label)} = ('env', $name);
				$winner = $ENV{$name};
			}
		}

		if (_differs($settings->{$key}, $winner)) {
			$row{source} = 'merged';
			$row{label}  = join(' + ', @{ _labels_for($key, map { $_->[0] } @layers) }) || $LABEL_UNKNOWN;
		}

		push @rows, \%row;
	}

	return { settings_file => $config_file, settings => \@rows };
}

=head2 explain_repos

Purpose: how the SSH settings resolve for every repo in a client config.

Args: C<config> (the hashref from C<App::FileSync::Config::load_client>),
C<report> (the result of L</explain>), C<config_file> (the client config path,
used in labels).

Returns: an arrayref, one entry per repo in name order, with C<repo>,
C<transport>, C<server> (when the repo records one) and C<ssh>: one
C<{key, value, source, label}> row per setting, where C<source> is C<repo>
(the repo's own entry), C<process> (the settings reported by C<explain>) or
C<default> (ssh's own default).  C<port> and C<host_key_checking> rows carry
C<repo_only =E<gt> 1>.  C<ssh> is C<undef> for the local transport, which never
runs ssh.

Side Effects: none.

Usage:

	my $repos = App::FileSync::Settings::explain_repos(
		config => $config, report => App::FileSync::Settings::explain(), config_file => $path,
	);

=head3 EXAMPLE

	for my $repo (@{ $repos }) {
		next unless $repo->{ssh};
		print "$repo->{repo}: $_->{key} = $_->{value} ($_->{label})\n" for @{ $repo->{ssh} };
	}

=head3 API SPECIFICATION

=head4 INPUT

	{
		config      => { type => 'hashref', optional => 1 },
		report      => { type => 'hashref', optional => 1 },
		config_file => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

	Key            Meaning                         Resolution
	args.invalid   an argument has the wrong type  fix the call

=head3 FORMAL SPECIFICATION

	∀ r : dom config.repos • ∀ k : REPO_SSH_SETTINGS •
		value(r, k) = repo(r)(k)       if repo(r)(k) ≠ ""
		            = process(k)       else if process(k) ≠ ""
		            = ""               otherwise

=head3 PSEUDOCODE

	for each repo, by name:
		record its transport and server
		if it uses ssh:
			for each SSH setting take the repo's value, else the process
			setting, else ssh's default
			add the repo-only port and host-key-checking rows

=cut

sub explain_repos {
	my $args = named(\@_, {
		config      => { type => 'hashref', optional => 1 },
		report      => { type => 'hashref', optional => 1 },
		config_file => { type => 'string', optional => 1 },
	}, 'Settings::explain_repos');

	my $config = $args->{config} || {};
	my %process = map { $_->{key} => $_ } @{ ($args->{report} || {})->{settings} || [] };

	my @repos;
	for my $name (sort keys %{ $config->{repos} || {} }) {
		my $repo = $config->{repos}{$name};
		$repo = {} unless ref($repo) eq 'HASH';

		my $entry = { repo => $name, transport => $repo->{transport} || 'ssh', ssh => undef };
		$entry->{server} = $repo->{server} if _set($repo->{server});

		# The local transport never runs ssh, so there is nothing to resolve.
		if ($entry->{transport} eq 'ssh') {
			my $repo_label = _repo_label($args->{config_file}, $name);
			my @rows;
			for my $key (@REPO_SSH_SETTINGS) {
				my $value   = $repo->{ $REPO_SSH_KEYS{$key} };
				my $setting = $process{$key};

				if (_set($value)) {
					push @rows, { key => $key, value => $value, source => 'repo', label => $repo_label };
				} elsif ($setting && _set($setting->{value})) {
					push @rows, { key => $key, value => $setting->{value}, source => 'process', label => $setting->{label} };
				} else {
					push @rows, { key => $key, value => '', source => 'default', label => $LABEL_SSH_DEFAULT };
				}
			}

			# The transport omits -p and StrictHostKeyChecking defaults to yes.
			for my $only (@REPO_ONLY) {
				my ($key, $default) = @{$only};
				my $set = _set($repo->{$key});
				push @rows, {
					key       => $key,
					repo_only => 1,
					value     => $set ? $repo->{$key} : $default,
					source    => $set ? 'repo' : 'default',
					label     => $set ? $repo_label : $LABEL_SSH_DEFAULT,
				};
			}
			$entry->{ssh} = \@rows;
		}

		push @repos, $entry;
	}

	return \@repos;
}

=head2 logger

Purpose: the diagnostics logger for this run.

Args: as L</load>, plus C<level> (overrides the settings), C<verbose> (debug)
and C<quiet> (errors only).  A command-line flag describes this run, so it
beats the settings file.

Returns: a L<Log::Abstraction> writing to standard error, or to C<log_file>.

Side Effects: reads the settings; creates C<log_file>'s directory.

Usage:

	my $logger = App::FileSync::Settings::logger(verbose => $opts{verbose});

=head3 EXAMPLE

	my $logger = App::FileSync::Settings::logger(level => 'info');
	$logger->info('starting');

=head3 API SPECIFICATION

=head4 INPUT

	{
		config_file => { type => 'string', optional => 1 },
		config_dirs => { type => 'arrayref', optional => 1 },
		level       => { type => 'string', optional => 1 },
		verbose     => { type => 'boolean', optional => 1 },
		quiet       => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'Log::Abstraction' }

=head3 MESSAGES

	Key                   Meaning                         Resolution
	settings.bad_level    log_level is not a known level  use one of @VALID_LEVELS
	io.mkdir              log_file's directory cannot be made  fix log_file

=head3 FORMAL SPECIFICATION

	level = debug                      if verbose
	      = error                      else if quiet
	      = args.level                 else if set
	      = settings.log_level         else if set
	      = warning                    otherwise
	pre lc level ∈ lc VALID_LEVELS

=head3 PSEUDOCODE

	load the settings
	choose the level: argument, then settings, then the default
	reject an unknown level
	send output to log_file (creating its directory) or standard error
	build the logger; apply --verbose or --quiet over it

=cut

sub logger {
	my $args = named(\@_, {
		%FILE_ARGS,
		level   => { type => 'string', optional => 1 },
		verbose => { type => 'scalar', optional => 1 },
		quiet   => { type => 'scalar', optional => 1 },
	}, 'Settings::logger');

	my $settings = load(map { $_ => $args->{$_} } grep { exists $args->{$_} } keys %FILE_ARGS);

	my $level = first { _set($_) } $args->{level}, $settings->{log_level}, $DEFAULT_LEVEL;
	throw('settings.bad_level', { level => $level, valid => join(', ', @VALID_LEVELS) })
		unless any { lc($_) eq lc($level) } @VALID_LEVELS;

	my $format = _set($settings->{log_format}) ? $settings->{log_format} : $DEFAULT_FORMAT;

	my $destination = { fd => \*STDERR };
	if (_set($settings->{log_file})) {
		ensure_dir(dirname($settings->{log_file}));
		$destination = { file => $settings->{log_file} };
	}

	my $logger = Log::Abstraction->new(
		level          => $level,
		format         => $format,
		# Logging must never turn a handled error into a second, uncaught one.
		croak_on_error => 0,
		logger         => $destination,
	);

	$logger = $logger->new(level => 'debug') if $args->{verbose};
	$logger = $logger->new(level => 'error') if $args->{quiet};

	return $logger;
}

# _set
# Purpose:     true for a value that is defined and not empty.
# Entry:       any scalar.
# Exit:        returns 1 or 0.
# Side effects: none.
sub _set :Private {
	my ($value) = @_;

	return (defined $value && length $value) ? 1 : 0;
}

# _default_config_path
# Purpose:     where the settings file would be when none is given.
# Entry:       none.
# Exit:        returns FILESYNC_SETTINGS, else HOME (or USERPROFILE on
#              Windows) /.conf/app-filesync.json, else undef.
# Side effects: none; existence is the caller's question.
sub _default_config_path :Private {
	my $home = first { _set($_) } @ENV{qw(HOME USERPROFILE)};

	my $path = _set($ENV{FILESYNC_SETTINGS}) ? $ENV{FILESYNC_SETTINGS}
		: defined $home ? File::Spec->catfile($home, $CONF_DIR, $CONFIG_BASENAME)
		: undef;
	return $path;
}

# _defaults
# Purpose:     the built-in value of every setting.
# Entry:       none.
# Exit:        returns a fresh hashref (callers may change it).
# Side effects: none.
sub _defaults :Private {
	return {
		log_level       => $DEFAULT_LEVEL,
		log_format      => $DEFAULT_FORMAT,
		log_file        => '',
		ssh_identity    => '',
		ssh_known_hosts => '',
		server_command  => $DEFAULT_SERVER_COMMAND,
	};
}

# _repo_label
# Purpose:     the provenance label for a value a repo's own entry supplied.
# Entry:       $config_file may be undef.
# Exit:        returns "FILE [name]" or "[name]".
# Side effects: none.
sub _repo_label :Private {
	my ($config_file, $name) = @_;

	return _set($config_file) ? "$config_file [$name]" : "[$name]";
}

# _differs
# Purpose:     compare two setting values as strings, undef only equal to undef.
# Entry:       two scalars.
# Exit:        returns 1 if they differ, else 0.
# Side effects: none.
sub _differs :Private {
	my ($left, $right) = @_;

	return (defined $left xor defined $right) ? 1
		: !defined $left ? 0
		: ("$left" ne "$right") ? 1 : 0;
}

# _explanation
# Purpose:     ask Config::Abstraction which sources set each key of a section.
# Entry:       $file exists; $section is the env prefix's stem.
# Exit:        returns a hashref (empty when the reader cannot be built).
# Side effects: reads $file.
sub _explanation :Private {
	my ($file, $section) = @_;

	my $reader = Config::Abstraction->new(config_file => $file, env_prefix => "${section}__");
	my $explanation = $reader ? $reader->explain_sources() : undef;
	return ref($explanation) eq 'HASH' ? $explanation : {};
}

# _env_key
# Purpose:     the name the environment actually uses for a variable.
# Entry:       $name is "prefix__key".
# Exit:        returns the matching %ENV key, or undef.
# Side effects: none.
# Config::Abstraction matches an env_prefix case-insensitively, and Windows
# reports environment names upper-cased, so the report must name the variable
# in the spelling that actually supplied the value.
sub _env_key :Private {
	my ($name) = @_;

	return exists $ENV{$name} ? $name : first { lc $_ eq lc $name } sort keys %ENV;
}

# _pick
# Purpose:     the source that set a key in one section.
# Entry:       $explanation is from _explanation.
# Exit:        returns { type, label, value } or undef.
# Side effects: none.
# The last source wins, which is how Config::Abstraction layers a file under
# its environment variables.
sub _pick :Private {
	my ($explanation, $section, $key) = @_;

	for my $full ("$section.$key", "global.$key", $key) {
		my $entry = $explanation->{$full};
		next unless ref($entry) eq 'HASH' && ref($entry->{sources}) eq 'ARRAY' && @{ $entry->{sources} };

		my $winner = $entry->{sources}[-1];
		return { map { $_ => $winner->{$_} } qw(type label value) };
	}

	return undef;	## no critic (Subroutines::ProhibitExplicitReturnUndef) -- callers test it in scalar context
}

# _labels_for
# Purpose:     every source label that mentions a key, for a merged value.
# Entry:       explanations from _explanation.
# Exit:        returns an arrayref of distinct labels, in order found.
# Side effects: none.
sub _labels_for :Private {
	my ($key, @explanations) = @_;

	my (%seen, @labels);
	for my $explanation (@explanations) {
		for my $full (grep { $_ eq $key || /\.\Q$key\E\z/ } sort keys %{$explanation}) {
			push @labels, grep { _set($_) && !$seen{$_}++ }
				map { $_->{label} } @{ $explanation->{$full}{sources} || [] };
		}
	}

	return \@labels;
}

# _universal_file
# Purpose:     the universal settings file Object::Configure would read.
# Entry:       $config_file is the settings file.
# Exit:        returns the first readable candidate, or undef.
# Side effects: none.
# Mirrors Object::Configure's search: universal<ext> beside the settings
# file, then the other config-file extensions, so the report matches.
sub _universal_file :Private {
	my ($config_file) = @_;

	my ($volume, $directory) = File::Spec->splitpath($config_file);
	my $base = File::Spec->catpath($volume, $directory, '');
	my $ext = $config_file =~ /(\.[^.\/\\]+)\z/ ? $1 : '';

	my %seen;
	return first { -f $_ && -r $_ }
		map { File::Spec->catfile($base, "universal$_") }
		grep { !$seen{$_}++ } ($ext, @UNIVERSAL_EXTENSIONS);
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * C<explain> reconstructs provenance by re-reading the layers
Object::Configure merges.  If a later Object::Configure adds a layer, the
report says C<merged> for values from it rather than naming it.

=item * The settings are re-read on every C<load>, C<explain> and C<logger>
call; nothing is cached, so a long-running process sees edits but pays a file
read per call.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
