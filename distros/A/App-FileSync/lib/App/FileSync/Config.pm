package App::FileSync::Config;

# Where configuration lives and what it holds: the client's repo list in
# ~/.filesync/config.json, and each repo's policy under the server root.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use File::Spec;
use JSON::PP ();
use Sub::Private { mode => 'enforce' };

use App::FileSync qw(json_encode json_decode read_text write_atomic);
use App::FileSync::Args qw(positional);
use App::FileSync::Constants qw(
	$ROOT_MARKER $TEMP_PREFIX $SNAPSHOT_DIR
	$TRASH_DAYS $MAX_DELETES $MAX_DELETE_PERCENT
);
use App::FileSync::I18N qw(throw strip_location);
use App::FileSync::IO qw(ensure_dir);

use version; our $VERSION = version->declare('0.001.2');

# Patterns that must never enter a manifest; they are excluded on both sides.
our @DEFAULT_IGNORE = (
	$ROOT_MARKER,
	"$TEMP_PREFIX*",
	$SNAPSHOT_DIR,
	'*.swp',
	'*~',
	'.#*',
	'#*#',
	'.DS_Store',
	'._*',
	'Thumbs.db',
	'desktop.ini',
	'*.crdownload',
	'*.part',
);

# Schemas for the positional entry points.
my %PATH_RULE = (type => 'string', min => 1);
my %ROOT_REPO = (root => {%PATH_RULE}, repo => {%PATH_RULE});

=encoding utf8

=head1 NAME

App::FileSync::Config - client and repo configuration files

=head1 SYNOPSIS

	my $client = App::FileSync::Config::load_client();
	$client->{repos}{docs}{root} = '/home/foo/Documents';
	App::FileSync::Config::save_client($client);

	my $repo = App::FileSync::Config::load_repo('/srv/filesync', 'docs');

=head1 DESCRIPTION

The client keeps one JSON file, F<~/.filesync/config.json> (or
C<FILESYNC_CONFIG>), listing its repos.  The server keeps one JSON file per
repo, F<ROOT/.filesync/repos/NAME/config.json>, holding its policy (trash
retention, deletion limits, ignore patterns) and the allowed clients.  Both are
written atomically.

=head1 FUNCTIONS

=head2 home_dir

Purpose: the client's state directory.

Args: none.

Returns: C<FILESYNC_HOME>, else F<~/.filesync> (using C<HOME>, then
C<USERPROFILE>).

Side Effects: none.

Usage:

	my $home = App::FileSync::Config::home_dir();

=head3 EXAMPLE

	print App::FileSync::Config::home_dir(), "\n";	# /home/foo/.filesync

=head3 API SPECIFICATION

=head4 INPUT

	[]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key                Meaning                       Resolution
	config.no_home     no home directory is known    set FILESYNC_HOME

=head3 FORMAL SPECIFICATION

	home_dir = ENV(FILESYNC_HOME)                   if non-empty
	         = (ENV(HOME) or ENV(USERPROFILE)) / ".filesync"   if one is non-empty
	         ↑ config.no_home                        otherwise

=cut

sub home_dir {
	my $explicit = _env('FILESYNC_HOME');
	return $explicit if defined $explicit;

	my $home = _env('HOME');
	$home = _env('USERPROFILE') unless defined $home;
	throw('config.no_home') unless defined $home;

	return File::Spec->catdir($home, '.filesync');
}

=head2 client_config_path

Purpose: where the client's repo list is stored.

Args: none.

Returns: C<FILESYNC_CONFIG>, else F<HOME_DIR/config.json>.

Side Effects: none.

Usage:

	my $path = App::FileSync::Config::client_config_path();

=head3 EXAMPLE

	local $ENV{FILESYNC_CONFIG} = '/tmp/test.json';
	print App::FileSync::Config::client_config_path(), "\n";	# /tmp/test.json

=head3 API SPECIFICATION

=head4 INPUT

	[]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key                Meaning                       Resolution
	config.no_home     no home directory is known    set FILESYNC_HOME

=head3 FORMAL SPECIFICATION

	client_config_path = ENV(FILESYNC_CONFIG) if non-empty, else home_dir / "config.json"

=cut

sub client_config_path {
	my $explicit = _env('FILESYNC_CONFIG');

	return defined $explicit ? $explicit : File::Spec->catfile(home_dir(), 'config.json');
}

=head2 default_client_config

Purpose: the configuration of a client that has no repos yet.

Args: none.

Returns: a new hashref C<{ version, ssh =E<gt> { command, extra_args }, repos =E<gt> {} }>.

Side Effects: none.

Usage:

	my $config = App::FileSync::Config::default_client_config();

=head3 EXAMPLE

	my $config = App::FileSync::Config::default_client_config();
	$config->{client_id} = 'laptop-1';

=head3 API SPECIFICATION

=head4 INPUT

	[]

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			version => { type => 'integer' },
			ssh     => { type => 'hashref' },
			repos   => { type => 'hashref' },
		},
	}

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	default_client_config = ⟨version ↦ 1, ssh ↦ default_ssh, repos ↦ ∅⟩

=cut

sub default_client_config {
	return {
		version => 1,
		ssh     => _default_ssh(),
		repos   => {},
	};
}

=head2 load_client

Purpose: read the client's repo list.

Args: optional C<$path> (default L</client_config_path>).

Returns: the configuration hashref; a missing file gives
L</default_client_config>.  C<repos> and C<ssh> are always hashes.

Side Effects: none.

Usage:

	my $config = App::FileSync::Config::load_client($opts{config});

=head3 EXAMPLE

	my $config = App::FileSync::Config::load_client();
	print join(', ', sort keys %{ $config->{repos} }), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'path', type => 'string', optional => 1 } ]

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key                  Meaning                       Resolution
	config.parse         the file is not valid JSON    fix or remove it
	config.not_object    the JSON is not an object     fix or remove it
	io.read              the file cannot be read       check permissions

=head3 FORMAL SPECIFICATION

	load_client(p) = normalise(json(FS(p)))   if p ∈ dom FS
	               = default_client_config    otherwise

=cut

sub load_client {
	my $args = positional(\@_, ['path'], { path => { type => 'string', optional => 1 } }, 'load_client');
	my $path = _or_default($args->{path}, \&client_config_path);

	my $config = -e $path ? _load_object($path) : default_client_config();

	# Older or hand-edited files may lack either section.
	$config->{repos} = {} unless ref($config->{repos}) eq 'HASH';
	$config->{ssh} = _default_ssh() unless ref($config->{ssh}) eq 'HASH';

	return $config;
}

=head2 save_client

Purpose: write the client's repo list.

Args: C<\%config>, optional C<$path>.

Returns: the path written.

Side Effects: replaces the file atomically, creating its directory.

Usage:

	App::FileSync::Config::save_client($config, $path);

=head3 EXAMPLE

	my $written = App::FileSync::Config::save_client(App::FileSync::Config::default_client_config());

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'config', type => 'hashref' },
		{ name => 'path',   type => 'string', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key        Meaning                       Resolution
	io.write   the file cannot be written    check permissions and space

=head3 FORMAL SPECIFICATION

	ΔFS
	FS'(path) = json(config) ⁀ "\n"

=cut

sub save_client {
	my $args = positional(\@_, [qw(config path)], {
		config => { type => 'hashref' },
		path   => { type => 'string', optional => 1 },
	}, 'save_client');

	my $path = _or_default($args->{path}, \&client_config_path);
	write_atomic($path, json_encode($args->{config}) . "\n");

	return $path;
}

=head2 repo_meta_dir

Documented with L</repo_config_path> below.

=head2 repo_config_path

Purpose: where a repo's metadata (and its config file) lives on the server.

Args: C<$root>, C<$repo>.

Returns: F<ROOT/.filesync/repos/REPO> and F<.../config.json>.

Side Effects: none.

Usage:

	my $meta = App::FileSync::Config::repo_meta_dir($root, $repo);

=head3 EXAMPLE

	print App::FileSync::Config::repo_config_path('/srv/filesync', 'docs'), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'root', type => 'string', min => 1 },
		{ name => 'repo', type => 'string', min => 1 },
	]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	repo_meta_dir(r, n) = r / ".filesync" / "repos" / n
	repo_config_path(r, n) = repo_meta_dir(r, n) / "config.json"

=cut

sub repo_meta_dir {
	my ($root, $repo) = @_;

	return File::Spec->catdir($root, '.filesync', 'repos', $repo);
}

sub repo_config_path {
	my ($root, $repo) = @_;

	return File::Spec->catfile(repo_meta_dir($root, $repo), 'config.json');
}

=head2 default_repo_config

Purpose: the policy of a newly created repo.

Args: C<$name>.

Returns: a new hashref: 30 days of trash, at most 200 or 10% of known files
deleted per session, inline conflict copies, modes preserved, symlinks not
followed, no clients, the default ignore list.

Side Effects: none.

Usage:

	my $config = App::FileSync::Config::default_repo_config('docs');

=head3 EXAMPLE

	my $config = App::FileSync::Config::default_repo_config('photos');
	$config->{trash_days} = 90;

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'name', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key            Meaning                 Resolution
	args.invalid   no name was given       pass the repo name

=head3 FORMAL SPECIFICATION

	default_repo_config(n) = ⟨name ↦ n, trash_days ↦ 30, max_deletes ↦ 200,
	                          max_delete_percent ↦ 10, clients ↦ ∅, ignore ↦ DEFAULT_IGNORE, ...⟩

=cut

sub default_repo_config {
	my $args = positional(\@_, ['name'], { name => {%PATH_RULE} }, 'default_repo_config');

	return {
		version            => 1,
		name               => $args->{name},
		created            => scalar(gmtime()) . ' UTC',
		trash_days         => $TRASH_DAYS,
		max_deletes        => $MAX_DELETES,
		max_delete_percent => $MAX_DELETE_PERCENT,
		conflicts          => 'inline',
		preserve_mode      => JSON::PP::true,
		allow_symlinks     => JSON::PP::false,
		clients            => {},
		ignore             => [ @DEFAULT_IGNORE ],
	};
}

=head2 load_repo

Purpose: read a repo's policy from the server root.

Args: C<$root>, C<$repo>.

Returns: the configuration hashref; C<ignore> is always an array and
C<clients> always a hash.

Side Effects: none.

Usage:

	my $config = App::FileSync::Config::load_repo($root, 'docs');

=head3 EXAMPLE

	my $config = App::FileSync::Config::load_repo('/srv/filesync', 'docs');
	print "$config->{trash_days} days of trash\n";

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'root', type => 'string', min => 1 },
		{ name => 'repo', type => 'string', min => 1 },
	]

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key                 Meaning                        Resolution
	config.no_repo      no such repo under the root    filesync-admin repo create
	config.parse        the file is not valid JSON     fix it by hand
	config.not_object   the JSON is not an object      fix it by hand

=head3 FORMAL SPECIFICATION

	load_repo(r, n) = normalise(json(FS(repo_config_path(r, n))))
	pre repo_config_path(r, n) ∈ dom FS

=cut

sub load_repo {
	my $args = positional(\@_, [qw(root repo)], {%ROOT_REPO}, 'load_repo');
	my ($root, $repo) = @{$args}{qw(root repo)};

	my $path = repo_config_path($root, $repo);
	throw('config.no_repo', { repo => $repo, root => $root }) unless -e $path;

	my $config = _load_object($path);
	$config->{ignore} = [ @DEFAULT_IGNORE ] unless ref($config->{ignore}) eq 'ARRAY';
	$config->{clients} = {} unless ref($config->{clients}) eq 'HASH';

	return $config;
}

=head2 save_repo

Purpose: write a repo's policy.

Args: C<$root>, C<$repo>, C<\%config>.

Returns: the path written.

Side Effects: creates the repo's metadata directory; replaces the file
atomically.

Usage:

	App::FileSync::Config::save_repo($root, 'docs', $config);

=head3 EXAMPLE

	my $config = App::FileSync::Config::load_repo($root, 'docs');
	$config->{trash_days} = 60;
	App::FileSync::Config::save_repo($root, 'docs', $config);

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'root',   type => 'string', min => 1 },
		{ name => 'repo',   type => 'string', min => 1 },
		{ name => 'config', type => 'hashref' },
	]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key        Meaning                       Resolution
	io.mkdir   the directory cannot be made  check permissions
	io.write   the file cannot be written    check permissions and space

=head3 FORMAL SPECIFICATION

	ΔFS
	FS'(repo_config_path(r, n)) = json(config) ⁀ "\n"

=cut

sub save_repo {
	my $args = positional(\@_, [qw(root repo config)], {
		%ROOT_REPO,
		config => { type => 'hashref' },
	}, 'save_repo');
	my ($root, $repo) = @{$args}{qw(root repo)};

	ensure_dir(repo_meta_dir($root, $repo));
	my $path = repo_config_path($root, $repo);
	write_atomic($path, json_encode($args->{config}) . "\n");

	return $path;
}

# _load_object
# Purpose:     read a JSON file that must hold an object.
# Entry:       $path exists.
# Exit:        returns the decoded hashref.
# Side effects: raises config.parse or config.not_object.
sub _load_object :Private {
	my ($path) = @_;

	my $text = read_text($path);
	my $data = eval { json_decode($text) };
	throw('config.parse', { path => $path, error => strip_location($@) }) if $@;
	throw('config.not_object', { path => $path }) unless ref($data) eq 'HASH';

	return $data;
}

# _default_ssh
# Purpose:     the ssh section of a client config that has none.
# Entry:       none.
# Exit:        returns a new hashref.
# Side effects: none.
sub _default_ssh :Private {
	return { command => 'ssh', extra_args => [] };
}

# _env
# Purpose:     an environment variable, treating empty as unset.
# Entry:       $name is the variable's name.
# Exit:        returns the value, or undef when unset or empty.
# Side effects: none.
sub _env :Private {
	my ($name) = @_;

	my $value = $ENV{$name};
	return (defined $value && length $value) ? $value : undef;
}

# _or_default
# Purpose:     use a given path, or compute the default one.
# Entry:       $given may be undef or empty; $default is a coderef.
# Exit:        returns the path to use.
# Side effects: whatever $default does (reads %ENV).
sub _or_default :Private {
	my ($given, $default) = @_;

	return (defined $given && length $given) ? $given : $default->();
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * Configuration is JSON only.  The process-wide settings (log level,
SSH defaults) go through L<Object::Configure> instead; see
L<App::FileSync::Settings>.  Two mechanisms is one too many, but the repo
list is written by C<filesync init> and must round-trip exactly, which
Object::Configure's layered merge does not promise.

=item * A config written by a newer release is read as-is: unknown keys are
kept and ignored, and there is no schema version check beyond C<version>.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
