# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package App::FuguBench::Deps;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Digest::SHA ();
use File::Spec  ();
use File::Temp  ();
use POSIX       qw(uname);

use App::FuguBench::Fetch;

use Fugu::CLI qw(EXIT_SUCCESS EXIT_ERROR);
use Fugu::Curl;
use Fugu::File;
use Fugu::Process;
use Fugu::Signify;

# App::FuguBench::Deps - the deps verb.
#
# The verb reads the external tools, the Perl distributions, the CPAN
# modules, and the prebuilt binaries that deps/<OS>.txt names, and it
# installs each one. --dry-run prints the command of each install,
# and it runs none of them. The design comes from the synced
# scripts/deps, and the trace of --dry-run is the oracle of
# CLI-CONFORMANCE-2.
#
# The verb reads deps/<OS>.txt relative to the start directory, and
# it walks up to no checkout (CLI-CHECKOUT-5). A guest runs
# `make deps` out of an extracted tarball, and that tree holds no
# .toolingrc.
#
# The verb validates every line of the manifest before the first
# install, and not the lines of the wanted environment alone
# (DEPS-MANIFEST-3). A bad line of another environment would
# otherwise stay invisible until someone installs that environment.
#
# Every download goes through Fugu::Curl (DEPS-FETCH-1). Each
# download that a manifest names takes its check before anything
# reads it (DEPS-TIER-1), and the standalone cpanm script is the one
# download that no manifest names (DEPS-INSTALL-4). A recorded digest
# of deps/SHA256.txt comes first. Without one, the verb fetches the
# signed SHA256 manifest that sits beside the download, and
# Fugu::Signify verifies it in-process against the declared keys
# (DEPS-TIER-8).
#
# --dry-run prints each command and asks no network, so it reads the
# manifest, the digest file and the key set alone (DEPS-MANIFEST-6).
#
# Every other run installs. The trace names each command, and
# $app->command then runs it as a child: a package manager, cpanm,
# and the mkdir, tar, unzip, cp and chmod of a bin entry. No line of
# a child reaches standard output (CLI-PROGRAM-4), and a child that
# exits non-zero stops the run.

# The environments of a manifest line (DEPS-MANIFEST-2).
use constant ENVIRONMENTS => qw(tool runtime test develop);

# The types of a manifest line, in the install order of
# DEPS-MANIFEST-4. A package can give the toolchain that a dist build
# needs, and a dist can give a module that the cpan list builds on. A
# binary depends on nothing here.
use constant TYPES => qw(pkg dist cpan bin);

# The standalone cpanm script. It is the one download that no
# manifest names, so it carries no check (DEPS-INSTALL-4).
use constant CPANM_URL => 'https://cpanmin.us';

# The asset spellings of one system name and one machine name, in
# preference order (DEPS-ALIAS-2). GitHub answers an asset path in
# any letter case, so macOS also covers macos. Two spellings of one
# name would name one download twice, and raise a false ambiguity.
my %OS_ALIAS = (
	Darwin  => [qw(darwin macOS osx)],
	Linux   => [qw(linux)],
	OpenBSD => [qw(openbsd)],
);

my %ARCH_ALIAS = (
	x86_64  => [qw(amd64 x64 x86_64)],
	amd64   => [qw(amd64 x64 x86_64)],
	aarch64 => [qw(arm64 aarch64)],
	arm64   => [qw(arm64 aarch64)],
);

# The shape of a word that becomes a file name (DEPS-INSTALL-8): the
# command name of a bin entry, and the value of --os and --arch. The
# first character is a letter or a digit, so the word is neither an
# option of tar and unzip, nor a parent segment of a path.
my $FILE_NAME = qr{\A[A-Za-z0-9][A-Za-z0-9._-]*\z};

# App::FuguBench::Deps->command($verb):
#	The entry of the Fugu::CLI table. The module holds one verb,
#	so it ignores the name.
sub command ( $, $ )
{
	return {
		summary => 'install one dependency environment, or record'
		    . ' the digests',
		usage => '[--dry-run] [--os <name>] [--arch <name>]'
		    . ' <tool|runtime|test|develop>'
		    . ' | --update-sums [--force] [--os <name>]'
		    . ' [--arch <name>]',
		options => {
			'dry-run' => 'print each command, and run none of them',
			'update-sums' => 'record the digest of each download',
			'force'       => 'rewrite a recorded digest, and pin a'
			    . ' stable name',
			'os=s'   => 'the system name, in place of uname',
			'arch=s' => 'the machine name, in place of uname',
		},
		run => sub ( $app, @argv ) { return _run( $app, @argv ) },
	};
}

# _run($app, @argv):
#	The body of the verb. The argument of an install is one
#	environment word, and a refresh takes none. Every other
#	command line is a usage error.
sub _run ( $app, @argv )
{
	my $cli    = $app->cli;
	my $log    = $cli->log;
	my $update = $cli->option('update-sums') ? 1 : 0;

	# A refresh reads every environment of one manifest, so it
	# keeps no environment word. The install path keeps one.
	my $env;
	if ($update) {
		return $cli->command_usage_error('deps')
		    unless _refresh_usage( $app, @argv );
	}
	else {
		$env = _install_usage( $app, @argv );
		return $cli->command_usage_error('deps') unless defined $env;
	}

	my $os   = $cli->option('os')   // ( uname() )[0];
	my $arch = $cli->option('arch') // ( uname() )[4];

	# Both words reach a file name: the system name names the
	# manifest, and each one names a download of the alias
	# expansion.
	for my $word ( [ os => $os ], [ arch => $arch ] ) {
		next if $word->[1] =~ $FILE_NAME;
		$log->error(
			q{the %s word '%s' holds letters, digits, a dot, a}
			    . ' dash, and an underscore',
			@$word
		);
		return $cli->command_usage_error('deps');
	}

	my $dir      = File::Spec->catdir( $app->start, 'deps' );
	my $manifest = File::Spec->catfile( $dir, "$os.txt" );
	unless ( -f $manifest ) {
		$log->notice( 'no dependencies for %s', $os );
		return EXIT_SUCCESS;
	}

	my $by_type = _manifest( $app, $manifest, $env );
	return Fugu::CLI::EXIT_CONFIG_ERROR() unless $by_type;

	# A file-name key stops an install (DEPS-TIER-5), and a
	# refresh drops the one that a recorded URL replaces
	# (DEPS-SUMS-11).
	my $file = File::Spec->catfile( $dir, 'SHA256.txt' );
	my $digests =
	    $update ? _recorded( $app, $file ) : _digests( $app, $file );
	return Fugu::CLI::EXIT_CONFIG_ERROR() unless $digests;

	my $keys = _keys( $app, $dir );
	return Fugu::CLI::EXIT_CONFIG_ERROR() unless $keys;

	my $ctx = {
		app     => $app,
		os      => $os,
		arch    => $arch,
		digests => $digests,
		keys    => $keys,
		dry     => $cli->option('dry-run') ? 1 : 0,
		force   => $cli->option('force')   ? 1 : 0,
		hold    => [],
	};

	# The dry-run trace is standard output, and each line of a
	# diagnostic is standard error, which Fugu::Log holds
	# unbuffered. In a pipe that joins the two, a buffered trace
	# line would land after the diagnostic that follows it.
	STDOUT->autoflush(1);

	return _update_sums( $ctx, $file, $by_type ) if $update;

	my $code = _install( $ctx, $by_type );
	return $code unless $code == EXIT_SUCCESS;

	# The one result line of the verb (DEPS-INSTALL-10). A dry run
	# installs nothing, so its trace is the whole standard output.
	say "installed the dependencies of $env" unless $ctx->{dry};

	return EXIT_SUCCESS;
}

# _refresh_usage($app, @argv):
#	1 for a command line that a refresh takes, and 0 for every
#	other one, which the method reports (DEPS-SUMS-13).
#
#	A refresh reads every environment of one manifest, so it takes
#	no environment word. It writes the digest file, so it takes no
#	--dry-run.
sub _refresh_usage ( $app, @argv )
{
	my $cli = $app->cli;
	my $log = $cli->log;

	if (@argv) {
		$log->error(  '--update-sums reads every environment of the'
			    . ' manifest, so it takes no environment word' );
		return 0;
	}
	if ( $cli->option('dry-run') ) {
		$log->error(  '--update-sums writes the digest file, so it'
			    . ' takes no --dry-run' );
		return 0;
	}

	return 1;
}

# _install_usage($app, @argv):
#	The environment word of an install, or undef for a command
#	line that no install takes, which the method reports.
#
#	--force belongs to --update-sums (DEPS-SUMS-13). An install
#	that took it would write nothing, and the operator would read
#	no word about the option that they gave.
sub _install_usage ( $app, @argv )
{
	my $cli = $app->cli;
	my $log = $cli->log;

	if ( $cli->option('force') ) {
		$log->error(q{--force belongs to '--update-sums'});
		return;
	}
	return unless @argv == 1;

	my ($env) = @argv;
	return $env if grep { $_ eq $env } ENVIRONMENTS;

	$log->error( q{unknown environment '%s': the environments are %s},
		$env, join ', ', ENVIRONMENTS );

	return;
}

# _install($ctx, $by_type):
#	Take each type of one environment, in the order of
#	DEPS-MANIFEST-4. The method returns the exit code of the run.
sub _install ( $ctx, $by_type )
{
	my %handler = (
		pkg  => \&_packages,
		dist => \&_dists,
		cpan => \&_modules,
		bin  => \&_bins,
	);

	for my $type (TYPES) {
		my $entries = $by_type->{$type};
		next unless @$entries;

		my $code = $handler{$type}->( $ctx, @$entries );
		return $code if $code != EXIT_SUCCESS;
	}

	return EXIT_SUCCESS;
}

# _manifest($app, $file, $want):
#	The entries of one manifest, as a hash of type to array
#	(DEPS-MANIFEST-2). Whitespace separates the three fields of a
#	line, and a # at the start of the first word starts a comment.
#
#	The method validates every line, and it keeps the lines of the
#	wanted environment (DEPS-MANIFEST-3). It reports the first bad
#	line and returns undef.
sub _manifest ( $app, $file, $want )
{
	my $log  = $app->cli->log;
	my $text = Fugu::File->read($file);
	unless ( defined $text ) {
		$log->error( 'cannot read %s', $file );
		return;
	}

	my %by_type = map { $_ => [] } TYPES;
	my $n       = 0;
	for my $line ( split /\n/, $text ) {
		$n++;
		my $where = "$file:$n";
		my ( $env, $type, $name ) = split ' ', $line, 3;

		next unless defined $env;
		next if index( $env, '#' ) == 0;

		# The split with a limit keeps the tail of the line
		# intact, so the trailing whitespace goes here.
		$name =~ s/\s+\z// if defined $name;

		if ( !defined $type || !defined $name || $name eq '' ) {
			$log->error(
				'%s: a line holds an environment, a type, and'
				    . ' a name: %s',
				$where, $line
			);
			return;
		}

		# An unknown environment word makes a line invisible: it
		# matches no wanted environment, and the run then claims
		# success for an install that never ran.
		unless ( grep { $_ eq $env } ENVIRONMENTS ) {
			$log->error(
				q{%s: unknown environment '%s': the}
				    . ' environments are %s',
				$where, $env, join ', ', ENVIRONMENTS
			);
			return;
		}
		unless ( exists $by_type{$type} ) {
			$log->error( q{%s: unknown type '%s': the types are %s},
				$where, $type, join ', ', TYPES );
			return;
		}

		return unless _check_entry( $app, $type, $name, $where, $line );

		next if defined $want && $env ne $want;
		push @{ $by_type{$type} }, $name;
	}

	return \%by_type;
}

# _check_entry($app, $type, $name, $where, $line):
#	Hold the name of one manifest line to the shape of its type. A
#	dist name is one URL, and a bin name holds the command name,
#	the URL, and, for an archive, the path of the file in the
#	archive (DEPS-MANIFEST-8). A pkg name and a cpan name reach a
#	package manager, so neither reads as an option, and neither
#	names a download that no tier covers (DEPS-MANIFEST-7).
sub _check_entry ( $app, $type, $name, $where, $line )
{
	my $log = $app->cli->log;

	return _check_url( $app, $name, $where ) if $type eq 'dist';

	if ( $type eq 'cpan' || $type eq 'pkg' ) {
		if ( $name =~ /\A-/ ) {
			$log->error( q{%s: a %s name must not start with a}
				    . ' dash: %s',
				$where, $type, $name );
			return 0;
		}
		if ( $name =~ m{\A[a-z][a-z0-9+.-]*://}i ) {
			$log->error( '%s: a %s name must not be a URL: %s',
				$where, $type, $name );
			return 0;
		}

		return 1;
	}

	my ( $command, $url, $member ) = split ' ', $name, 3;
	if ( !defined $url || $url eq '' ) {
		$log->error(
			'%s: a bin line holds the command name, the URL, and'
			    . ' the path in an archive: %s',
			$where, $line
		);
		return 0;
	}
	if ( _archive_type($url) && !defined $member ) {
		$log->error(
			'%s: an archive URL needs the path of the file'
			    . ' in the archive: %s',
			$where, $url
		);
		return 0;
	}
	if ( !_archive_type($url) && defined $member ) {
		$log->error(
			'%s: a path in the archive needs an archive URL:'
			    . ' %s',
			$where, $url
		);
		return 0;
	}

	return 0 unless _check_url( $app, $url, $where );

	return _check_bin_names( $app, $command, $member, $where );
}

# _check_url($app, $url, $where):
#	Hold one download URL to the shapes that the downloader and
#	the digest file allow.
#
#	The scheme check is the shared one of the fetch verb
#	(DEPS-FETCH-4), because both reach one downloader.
#
#	The URL becomes a key of deps/SHA256.txt, whose line format
#	reserves the parenthesis and the space (DEPS-TIER-12). It must
#	also name a file, which becomes the name of the download in a
#	temporary directory.
sub _check_url ( $app, $url, $where )
{
	my $log = $app->cli->log;
	return 0
	    unless App::FuguBench::Fetch::check_url( $app, $url, $where );

	my ($file) = $url =~ m{([^/]+)\z};
	if ( !defined $file || $file eq '' ) {
		$log->error( '%s: the URL names no file: %s', $where, $url );
		return 0;
	}
	if ( $url =~ /[()\s]/ ) {
		$log->error(
			'%s: the URL holds a parenthesis or a space, which the'
			    . ' line format of deps/SHA256.txt reserves: %s',
			$where, $url
		);
		return 0;
	}

	return 1;
}

# _check_bin_names($app, $name, $member, $where):
#	Hold the command name and the archive path of one bin entry to
#	the shapes that a file name allows (DEPS-INSTALL-8). The
#	command name becomes a file name in the install directory, and
#	the archive path becomes one in a temporary directory. tar and
#	unzip read a leading dash as an option, and one of those
#	options runs a command.
sub _check_bin_names ( $app, $name, $member, $where )
{
	my $log = $app->cli->log;
	unless ( $name =~ $FILE_NAME ) {
		$log->error(
			q{%s: the command name '%s' holds letters, digits, a}
			    . ' dot, a dash, and an underscore',
			$where, $name
		);
		return 0;
	}

	return 1 unless defined $member;

	my @part = split m{/}, $member;
	if ( grep { $_ eq q{..} || $_ eq q{} } @part ) {
		$log->error(
			q{%s: the archive path '%s' must hold no empty and no}
			    . ' parent segment',
			$where, $member
		);
		return 0;
	}
	if ( $member =~ /\A-/ ) {
		$log->error(
			q{%s: the archive path '%s' must not start with}
			    . ' a dash',
			$where, $member
		);
		return 0;
	}

	return 1;
}

# _signify():
#	The one Fugu::Signify of the run. The perl engine parses the
#	signify(1) formats itself and checks a signature with
#	Fugu::Ed25519, so no host needs signify(1) (DEPS-TIER-8).
#
#	The object holds no key set, and each verification names its
#	own keys. It also parses the SHA256 manifest form, which both
#	tiers read, and the public key file of a key line.
sub _signify ()
{
	state $signify = Fugu::Signify->new( engine => 'perl' );

	return $signify;
}

# _parse_digests($app, $file):
#	The digest of each line of one SHA256 manifest, as a hash of
#	key to digest, through the manifest reader of Fugu::Signify
#	(DEPS-TIER-3). The reader rejects a bad line, a digest that is
#	not 64 hexadecimal characters, a blank line, and a duplicate
#	key (DEPS-TIER-4). A silent skip would drop a check.
#
#	A file with no line gives the empty set. The method reports a
#	file that it cannot read or parse, and returns undef.
sub _parse_digests ( $app, $file )
{
	my $log  = $app->cli->log;
	my $text = Fugu::File->read($file);
	unless ( defined $text ) {
		$log->error( 'cannot read %s', $file );
		return;
	}
	return {} if $text =~ /\A\s*\z/;

	my $digests = _signify()->parse_manifest($text);
	unless ($digests) {
		$log->error( '%s: %s', $file, _signify()->error );
		return;
	}

	return $digests;
}

# _digests($app, $file):
#	The digest of each download that deps/SHA256.txt records, as a
#	hash of URL to digest (DEPS-TIER-3). An absent file, and a
#	file with no line, each give the empty set.
#
#	Each key of this file holds a scheme, because the file gathers
#	many upstreams and keys on the whole download URL. A key that
#	is a file name comes from an older file (DEPS-TIER-5). It
#	matches no download of this verb, so the entry would lose its
#	pin without a word.
sub _digests ( $app, $file )
{
	my $digests = _recorded( $app, $file );
	return unless $digests;

	my @legacy = _legacy($digests);
	return $digests unless @legacy;

	my $log = $app->cli->log;
	$log->error(
		'%s keys on the file name, and the verb keys on the whole'
		    . ' download URL',
		$file
	);
	$log->error( '  %s', $_ ) for @legacy;
	$log->error(  q{  run 'deps --update-sums' for each operating system}
		    . ' that deps/ holds a manifest for' );

	return;
}

# _recorded($app, $file):
#	The digest set of deps/SHA256.txt, with every key that the
#	file holds. An absent file, and a file with no line, each give
#	the empty set.
#
#	A refresh reads the file through this method, because it drops
#	a file-name key that it can replace, and keeps every other one
#	(DEPS-SUMS-11). An install reads it through _digests, which
#	stops on such a key.
sub _recorded ( $app, $file )
{
	return {} unless -f $file;

	return _parse_digests( $app, $file );
}

# _legacy($digests):
#	Each key of a digest set that is a file name, in sorted order.
#	Such a key comes from an older file, and the verb keys on the
#	whole download URL (DEPS-TIER-5).
sub _legacy ($digests)
{
	return grep { !m{\A[a-z][a-z0-9+.-]*://}i } sort keys %$digests;
}

# _keys($app, $dir):
#	The declared signify keys, in the order that deps/KEYS.txt and
#	then deps/KEYS.local.txt name them (DEPS-KEYS-1). The order is
#	the trust order, and the current key comes first
#	(DEPS-KEYS-3). An absent file carries no key, and an empty set
#	is valid (DEPS-KEYS-5).
#
#	A # at the start of a line starts a comment. The method
#	reports the first bad line and returns undef.
sub _keys ( $app, $dir )
{
	my $log = $app->cli->log;

	my ( @keys, %seen );
	for my $name (qw(KEYS.txt KEYS.local.txt)) {
		my $file = File::Spec->catfile( $dir, $name );
		next unless -f $file;

		my $text = Fugu::File->read($file);
		unless ( defined $text ) {
			$log->error( 'cannot read %s', $file );
			return;
		}

		my $n = 0;
		for my $line ( split /\n/, $text ) {
			$n++;
			next if $line =~ /\A\s*(?:#|\z)/;

			my $where = "$file:$n";
			my $key   = _key( $app, [ split q{ }, $line ], $where );
			return unless $key;

			if ( $seen{ $key->{name} }++ ) {
				$log->error( '%s: duplicate key name: %s',
					$where, $key->{name} );
				return;
			}
			push @keys, $key;
		}
	}

	return \@keys;
}

# _key($app, $field, $where):
#	One key of a key line, as a hash with the name and either the
#	key body or the URL and the digest (DEPS-KEYS-2). Two fields
#	give the body form, and three give the URL form, whose digest
#	is the trust anchor.
#
#	The URL of the URL form reaches the downloader, so it takes
#	the shape check of the fetch verb (DEPS-FETCH-4).
#
#	The method reports a bad line and returns undef (DEPS-KEYS-4).
sub _key ( $app, $field, $where )
{
	my $log = $app->cli->log;

	# The name becomes a file name in a temporary directory, so it
	# holds no path.
	unless ( defined $field->[0] && $field->[0] =~ $FILE_NAME ) {
		$log->error(
			'%s: a key name holds letters, digits, a dot, a dash,'
			    . ' and an underscore',
			$where
		);
		return;
	}

	if ( @$field == 2 ) {
		my $key = { name => $field->[0], body => $field->[1] };

		# The body is the second line of a signify public key
		# file, so the parser of Fugu::Signify holds it to the
		# 42 bytes and the prefix of that form.
		return $key if _signify()->parse_public_key( _key_text($key) );

		$log->error( '%s: not a signify key body: %s',
			$where, _signify()->error );
		return;
	}

	if ( @$field == 3 ) {
		unless ( $field->[2] =~ /\A[0-9a-f]{64}\z/ ) {
			$log->error( '%s: not a sha256 digest: %s',
				$where, $field->[2] );
			return;
		}

		return
		    unless App::FuguBench::Fetch::check_url( $app, $field->[1],
			$where );

		return {
			name   => $field->[0],
			url    => $field->[1],
			digest => $field->[2],
		};
	}

	$log->error( '%s: a key line holds two or three fields', $where );

	return;
}

# _key_text($key):
#	The two lines of a signify public key file. signify(1) reads
#	the comment line and carries no trust in it, so one word of a
#	key line holds the whole key.
sub _key_text ($key)
{
	return "untrusted comment: $key->{name} public key\n$key->{body}\n";
}

# _packages($ctx, @pkgs):
#	Give the package list to the package manager of the platform
#	(DEPS-INSTALL-1). The verb gives every package of the
#	environment in one command.
sub _packages ( $ctx, @pkgs )
{
	my $os = $ctx->{os};
	_note( $ctx, 'the OS packages: %s', join q{ }, @pkgs );

	if ( $os eq 'OpenBSD' ) {
		return EXIT_ERROR
		    unless _command( $ctx, 'pkg_add', @pkgs );
	}
	elsif ( $os eq 'Linux' ) {
		return EXIT_ERROR
		    unless _command( $ctx, 'sudo', 'apt-get', 'update' );
		return EXIT_ERROR
		    unless _command( $ctx, 'sudo', 'apt-get', 'install', '-y',
			@pkgs );
	}
	elsif ( $os eq 'Darwin' ) {
		return EXIT_ERROR
		    unless _command( $ctx, 'brew', 'install', @pkgs );
	}
	else {
		$ctx->{app}
		    ->cli->log->error( 'no package manager for %s', $os );
		return EXIT_ERROR;
	}

	return EXIT_SUCCESS;
}

# _dists($ctx, @urls):
#	Fetch each distribution tarball and give it to cpanm
#	(DEPS-INSTALL-5). Every entry resolves, and takes its tier
#	check, before the first fetch, so a set with one entry that no
#	tier covers installs nothing (DEPS-INSTALL-9).
#
#	The digest of an entry takes its check in the install loop, at
#	the download of that entry. A mismatch there leaves an earlier
#	entry of the set installed (DEPS-TIER-2). The two loops come
#	from the synced scripts/deps, which CLI-CONFORMANCE-2 pins.
sub _dists ( $ctx, @urls )
{
	_note( $ctx, 'the distributions: %s', join q{ }, @urls );

	my @resolved;
	for my $url (@urls) {
		my ($value) = _resolve( $ctx, $url, undef );
		return Fugu::CLI::EXIT_CONFIG_ERROR() unless defined $value;

		# An entry that no tier covers stops the run before the
		# first download (DEPS-INSTALL-9).
		return EXIT_ERROR unless _check_tier( $ctx, $value );
		push @resolved, $value;
	}

	my @cpanm = _cpanm($ctx);
	return EXIT_ERROR unless @cpanm;

	for my $url (@resolved) {
		my ($asset) = _asset( $ctx, $url );
		return EXIT_ERROR unless defined $asset;

		return EXIT_ERROR
		    unless _command( $ctx, @cpanm, _options($ctx), $asset );
	}

	return EXIT_SUCCESS;
}

# _modules($ctx, @modules):
#	Install the CPAN modules of one environment with cpanm
#	(DEPS-INSTALL-2).
sub _modules ( $ctx, @modules )
{
	_note( $ctx, 'the CPAN modules: %s', join q{ }, @modules );

	my @cpanm = _cpanm($ctx);
	return EXIT_ERROR unless @cpanm;

	return EXIT_ERROR
	    unless _command( $ctx, @cpanm, _options($ctx), @modules );

	return EXIT_SUCCESS;
}

# _bins($ctx, @bins):
#	Install the prebuilt binaries of one environment into
#	~/.local/bin (DEPS-INSTALL-6). A bin entry holds the command
#	name, the download URL and, for an archive, the path of the
#	file in the archive.
#
#	Every entry resolves, and takes its shape check again, before
#	the first fetch. The resolution asks no network
#	(DEPS-ALIAS-4), so an entry that no tier covers stops the run
#	ahead of the mkdir, and a host with no install directory keeps
#	none (DEPS-INSTALL-9).
#
#	The digest of an entry takes its check in the install loop, at
#	the download of that entry. A mismatch there leaves an earlier
#	entry of the set installed, and a mismatch on the first entry
#	leaves the new install directory behind (DEPS-TIER-2). The two
#	loops come from the synced scripts/deps, which
#	CLI-CONFORMANCE-2 pins.
sub _bins ( $ctx, @bins )
{
	my $app = $ctx->{app};
	my $log = $app->cli->log;
	_note( $ctx, 'the binaries: %s',
		join q{ }, map { ( split q{ }, $_, 2 )[0] } @bins );

	my $home = $ENV{HOME};
	unless ( defined $home && $home ne q{} ) {
		$log->error(  'HOME is not set, and a bin entry installs'
			    . ' under it' );
		return EXIT_ERROR;
	}

	my $bindir = File::Spec->catdir( $home, '.local', 'bin' );

	my @entry;
	for my $bin (@bins) {
		my ( $name, $url, $member ) = split q{ }, $bin, 3;
		return Fugu::CLI::EXIT_CONFIG_ERROR()
		    unless _check_bin_names( $app, $name, $member,
			"the entry $name" );

		( $url, $member ) = _resolve( $ctx, $url, $member );
		return Fugu::CLI::EXIT_CONFIG_ERROR() unless defined $url;

		# The alias words expand into the archive path, so the
		# shape takes its check again after the expansion
		# (DEPS-INSTALL-8).
		return Fugu::CLI::EXIT_CONFIG_ERROR()
		    unless _check_bin_names( $app, $name, $member,
			"the resolved entry $name" );

		# An entry that no tier covers stops the run here, ahead
		# of the mkdir of the install directory
		# (DEPS-INSTALL-9).
		return EXIT_ERROR unless _check_tier( $ctx, $url );

		push @entry, [ $name, $url, $member ];
	}

	return EXIT_ERROR unless _command( $ctx, 'mkdir', '-p', $bindir );

	for my $bin (@entry) {
		my ( $name, $url, $member ) = @$bin;
		my $file = File::Spec->catfile( $bindir, $name );

		my ( $asset, $dir ) = _asset( $ctx, $url );
		return EXIT_ERROR unless defined $asset;

		if ( defined $member ) {
			return EXIT_ERROR
			    unless _extract( $ctx, $dir, $file, $asset,
				$member );
		}
		else {
			return EXIT_ERROR
			    unless _command( $ctx, 'cp', $asset, $file );
		}
		return EXIT_ERROR
		    unless _command( $ctx, 'chmod', '755', $file );
	}

	return EXIT_SUCCESS;
}

# _extract($ctx, $dir, $file, $archive, $member):
#	Install the one file $member of a checked archive as $file
#	(DEPS-INSTALL-7). tar unpacks a tar archive, and unzip unpacks
#	a zip archive. Both unpack $member alone, into the temporary
#	directory that holds the archive.
#
#	The method returns 1 after both commands, and 0 after a
#	failure, which _command reports.
sub _extract ( $ctx, $dir, $file, $archive, $member )
{
	if ( _archive_type($archive) eq 'tar' ) {
		return 0
		    unless _command( $ctx, 'tar', '-xzf', $archive, '-C',
			$dir, $member );
	}
	else {
		return 0
		    unless _command( $ctx, 'unzip', '-q', $archive, $member,
			'-d', $dir );
	}

	return _command( $ctx, 'cp',
		File::Spec->catfile( $dir, split m{/}, $member ), $file );
}

# _asset($ctx, $url):
#	The path of one checked download, and the temporary directory
#	that holds it, in that order (DEPS-TIER-1). The method writes
#	the trace line of the fetch, which names the fetch verb
#	(DEPS-FETCH-2).
#
#	The signed manifest of a release lands beside the download, so
#	a download named SHA256 would share one path with it. The
#	download therefore takes a directory of its own.
#
#	A dry run names the file and asks no network
#	(DEPS-MANIFEST-6). Every other run downloads the file and
#	checks it, and it returns the empty list on a failure.
sub _asset ( $ctx, $url )
{
	my $dir = _tempdir($ctx);
	my ($name) = $url =~ m{([^/]+)\z};

	my $asset = File::Spec->catdir( $dir, 'asset' );
	unless ( mkdir $asset ) {
		$ctx->{app}
		    ->cli->log->error( 'cannot make %s: %s', $asset, $! );
		return;
	}

	my $file = File::Spec->catfile( $asset, $name );
	_trace( $ctx, $ctx->{app}->cli->name, 'fetch', $file, $url );

	return ( $file, $dir ) if $ctx->{dry};
	return unless _verified( $ctx, $url, $file, $dir );

	return ( $file, $dir );
}

# _check_tier($ctx, $url):
#	Report an entry that no tier can check (DEPS-TIER-9). The
#	check reads the digest file and the key set alone, so a caller
#	runs it over every entry before the first download.
#
#	A tool entry takes the signify tier as every other entry does,
#	because the check runs in-process and needs no signify(1) on
#	the host (DEPS-TIER-8).
sub _check_tier ( $ctx, $url )
{
	return 1 if exists $ctx->{digests}{$url};
	return 1 if @{ $ctx->{keys} };

	my $log = $ctx->{app}->cli->log;
	$log->error(
		'%s has no recorded digest, and no key is declared, so nothing'
		    . ' verifies it',
		$url
	);
	$log->error(  q{  a versioned URL takes a digest from}
		    . q{ 'deps --update-sums'} );
	$log->error(  '  a stable URL needs a signed SHA256 beside it, and a'
		    . ' key in deps/KEYS.local.txt' );

	return 0;
}

# _verified($ctx, $url, $file, $dir):
#	Download one file and hold it to its digest. The method
#	returns 1 after a check that passes, and 0 after every
#	failure, which it reports.
#
#	The recorded digest of deps/SHA256.txt comes first
#	(DEPS-TIER-6). Without one, the method derives SHA256 and
#	SHA256.sig from the directory of the URL, verifies the
#	signature, and holds the file to the signed manifest
#	(DEPS-TIER-7). The signature covers the manifest, and the
#	manifest covers the file, so the signature verifies before the
#	file downloads.
sub _verified ( $ctx, $url, $file, $dir )
{
	my $log = $ctx->{app}->cli->log;

	my $want = $ctx->{digests}{$url};
	if ( defined $want ) {
		return 0 unless _fetch_file( $ctx, $url, $file );

		return _check_digest( $ctx, $file, $want, $url, 'recorded' );
	}

	my $base = _base($url);
	unless ( defined $base ) {
		$log->error( 'the URL names no directory: %s', $url );
		return 0;
	}

	my $sums = File::Spec->catfile( $dir, 'SHA256' );
	my $sig  = File::Spec->catfile( $dir, 'SHA256.sig' );
	for my $part ( [ $sums, 'SHA256' ], [ $sig, 'SHA256.sig' ] ) {
		my $answer = _probe( $ctx, "$base/$part->[1]", $part->[0] );
		return 0 unless defined $answer;
		next if $answer;

		$log->error(
			'the signify tier needs %s/%s, and the server does not'
			    . ' answer it',
			$base, $part->[1] );
		$log->error(  '  a release that publishes no signature needs a'
			    . ' recorded digest' );
		$log->error(
			q{  'deps --update-sums' records a versioned URL, and}
			    . q{ '--update-sums --force' records any URL} );
		return 0;
	}

	return 0 unless _verify( $ctx, $sums, $sig );

	# The signed manifest of a release covers one directory with
	# unique file names, so it keys on the file name.
	my $signed = _parse_digests( $ctx->{app}, $sums );
	return 0 unless $signed;

	my ($name) = $url =~ m{([^/]+)\z};
	my $signed_want = $signed->{$name};
	unless ( defined $signed_want ) {
		$log->error( 'the signed manifest of %s does not name %s',
			$base, $name );
		return 0;
	}

	return 0 unless _fetch_file( $ctx, $url, $file );

	return _check_digest( $ctx, $file, $signed_want, $name, 'signed' );
}

# _verify($ctx, $sums, $sig, $level):
#	Verify the signature over one SHA256 manifest with the
#	declared keys, in trust order. The method returns the path of
#	the key file that verified it, and undef after a failure,
#	which it reports.
#
#	Fugu::Signify reads each key file under the perl engine, so no
#	host needs signify(1) (DEPS-TIER-8). An empty key set stops
#	the signify tier (DEPS-KEYS-5).
#
#	$level names the level of a failure. The install path takes
#	the default, because a failure there stops the run. The
#	signed-manifest probe of a refresh passes 'warning', because a
#	manifest that no key verifies keeps the entry off the digest
#	tier, and the run goes on (DEPS-SUMS-6).
sub _verify ( $ctx, $sums, $sig, $level = 'error' )
{
	my $log  = $ctx->{app}->cli->log;
	my $keys = $ctx->{keys};
	my $report =
	    $level eq 'warning'
	    ? sub (@line) { return $log->warning(@line) }
	    : sub (@line) { return $log->error(@line) };

	unless (@$keys) {
		$report->(
			'no key is declared, so no signature verifies %s',
			$sums
		);
		return;
	}

	# Each verification builds the key set again, in a directory
	# of its own (DEPS-KEYS-6). A cached copy would carry the
	# check of an earlier entry.
	my $dir = _tempdir($ctx);
	my ( @paths, %name, @failed );
	for my $key (@$keys) {
		my ( $path, $why ) = _key_file( $ctx, $dir, $key );
		unless ( defined $path ) {

			# A key that fails its digest, and a key that no
			# server answers, must not stop the trust order
			# (DEPS-KEYS-7). The operator must still see it.
			$log->warning( 'the key %s did not load: %s',
				$key->{name}, $why );
			push @failed, "$key->{name}: $why";
			next;
		}
		$name{$path} = $key->{name};
		push @paths, $path;
	}

	unless (@paths) {
		$report->(
			'no declared key loaded, so no signature verifies'
			    . ' %s',
			$sums
		);
		$report->( '  %s', $_ ) for @failed;
		return;
	}

	my $public = _signify()->verify(
		keys      => \@paths,
		file      => $sums,
		signature => $sig
	);
	unless ( defined $public ) {
		$report->(
			'no declared key verifies the signature of %s', $sums
		);
		$report->( '  %s', $_ )
		    for _reasons( _signify()->error ), @failed;
		return;
	}

	_note( $ctx, 'verified the manifest with the key %s', $name{$public} );

	return $public;
}

# _key_file($ctx, $dir, $key):
#	The path of one public key file in a temporary directory, or
#	undef and the reason of the failure, in that order.
#
#	The body form writes the two lines of a signify public key
#	file. The URL form downloads the published file and holds it
#	to the recorded digest, which is the trust anchor
#	(DEPS-KEYS-2). A failed check leaves no file behind for a
#	later use.
sub _key_file ( $ctx, $dir, $key )
{
	my $path = File::Spec->catfile( $dir, "$key->{name}.pub" );

	if ( defined $key->{body} ) {
		return ( undef, "cannot write $path" )
		    unless Fugu::File->write( $path, _key_text($key) );

		return $path;
	}

	return ( undef, $ctx->{curl}->error )
	    unless _fetch( $ctx, $key->{url}, $path );

	my $got = _sha256($path);
	unless ( defined $got ) {
		my $why = "cannot read $path: $!";
		unlink $path;
		return ( undef, $why );
	}
	unless ( $got eq $key->{digest} ) {
		unlink $path;
		return ( undef,
			      "the file holds $got, and the key line records"
			    . " $key->{digest}" );
	}

	return $path;
}

# _check_digest($ctx, $path, $want, $key, $source):
#	Hold one downloaded file to the wanted digest. The method
#	returns 1 for a digest that matches, and 0 for every other
#	answer, which it reports.
#
#	A mismatch names the repair of its tier (DEPS-TIER-10). The
#	source is 'recorded' or 'signed', and the key names the line
#	to repair: the URL for a recorded digest, and the file name
#	for a signed manifest.
sub _check_digest ( $ctx, $path, $want, $key, $source )
{
	my $log = $ctx->{app}->cli->log;

	my $got = _sha256($path);
	unless ( defined $got ) {
		$log->error( 'cannot read %s: %s', $path, $! );
		return 0;
	}
	return 1 if $got eq $want;

	$log->error( '%s does not match its %s digest', $key, $source );
	$log->error( '  expected %s', $want );
	$log->error( '  got      %s', $got );
	if ( $source eq 'signed' ) {
		$log->error(  '  the signature verifies, so the served file'
			    . ' disagrees with the release' );
		$log->error(  '  report it upstream, and install nothing until'
			    . ' it agrees' );
	}
	else {
		$log->error(  '  compare the upstream checksum file, then'
			    . q{ 'deps --update-sums --force' rewrites the line}
		);
	}

	return 0;
}

# _sha256($path):
#	The sha256 digest of one file, in lower-case hexadecimal, or
#	undef for a file that does not open. The digest streams from
#	the handle, so a large file never enters memory whole.
sub _sha256 ($path)
{
	open my $fh, '<', $path or return;
	binmode $fh;
	my $sha = Digest::SHA->new(256);
	$sha->addfile($fh);
	close $fh;

	return $sha->hexdigest;
}

# _fetch($ctx, $url, $path):
#	Download one URL to one path through Fugu::Curl
#	(DEPS-FETCH-1). The method returns 1 on success, and undef
#	with the reason in the error of the downloader.
#
#	One Fugu::Curl serves the whole run, because it resolves the
#	command of the host one time. A failed download leaves no file
#	at the path.
sub _fetch ( $ctx, $url, $path )
{
	$ctx->{curl} //= Fugu::Curl->new;

	return $ctx->{curl}->fetch( $url, $path );
}

# _fetch_file($ctx, $url, $path):
#	One download that the run needs. The method reports a failure
#	and returns 0, and it returns 1 after a download that lands.
sub _fetch_file ( $ctx, $url, $path )
{
	return 1 if _fetch( $ctx, $url, $path );
	$ctx->{app}->cli->log->error( '%s', $ctx->{curl}->error );

	return 0;
}

# _probe($ctx, $url, $path):
#	One download whose absence is a normal answer: 1 for a file
#	that lands, 0 for a 404, and undef for every other failure,
#	which the method reports (DEPS-FETCH-3).
#
#	curl reports the HTTP status through --write-out, and a 404
#	behind a redirect exits 56 and not 22. Fugu::Curl owns that
#	classification, and the verb reads the status alone.
sub _probe ( $ctx, $url, $path )
{
	return 1 if _fetch( $ctx, $url, $path );

	my $curl = $ctx->{curl};
	return 0
	    if ( $curl->status // q{} ) eq 'http'
	    && ( $curl->code // 0 ) == 404;

	$ctx->{app}->cli->log->error( '%s', $curl->error );

	return;
}

# _base($url):
#	The directory part of one URL, or undef.
sub _base ($url)
{
	my ($base) = $url =~ m{\A(.*)/[^/]+\z};

	return defined $base && $base ne q{} ? $base : undef;
}

# _reasons($text):
#	Each line of a multi-line reason, without its lead and its
#	trailing whitespace. One line of the log carries one reason.
sub _reasons ($text)
{
	my @out;
	for my $line ( split /\n/, $text // q{} ) {
		$line =~ s/\A\s+//;
		$line =~ s/\s+\z//;
		push @out, $line if length $line;
	}

	return @out;
}

# _cpanm($ctx):
#	The command that runs cpanm, as a list (DEPS-INSTALL-3). The
#	cpanm on PATH is the first choice, and the bare name keeps the
#	trace line readable.
#
#	Without one, the method names the standalone cpanm script in a
#	temporary directory, and this perl runs it. An install of
#	App::cpanminus does not answer here: it lands in the local
#	library of the user, and PATH does not hold it.
#
#	The method resolves the command one time, because the trace
#	holds the download of the script one time. It returns the
#	empty list after a failed download, which it reports.
sub _cpanm ($ctx)
{
	return @{ $ctx->{cpanm} } if $ctx->{cpanm};

	my @cmd = ('cpanm');
	unless ( defined Fugu::Process->find_command('cpanm') ) {
		_note( $ctx,
			      'cpanm is absent, and the bootstrap'
			    . ' downloads the standalone script' );

		my $script = File::Spec->catfile( _tempdir($ctx), 'cpanm' );
		_trace( $ctx, $ctx->{app}->cli->name,
			'fetch', $script, CPANM_URL );

		# This is the one download with no check, because no
		# manifest names it (DEPS-INSTALL-4).
		return
		    unless $ctx->{dry}
		    || _fetch_file( $ctx, CPANM_URL, $script );

		@cmd = ( $^X, $script );
	}
	$ctx->{cpanm} = \@cmd;

	return @cmd;
}

# _options($ctx):
#	The options that every cpanm run shares (DEPS-INSTALL-2). With
#	PERL_LOCAL_LIB_ROOT in the environment, the install lands in
#	that directory. local::lib and the setup-perl action of CI
#	each set the variable.
sub _options ($ctx)
{
	return @{ $ctx->{options} } if $ctx->{options};

	my @opts  = ('--notest');
	my $local = $ENV{PERL_LOCAL_LIB_ROOT};
	if ( defined $local && length $local ) {
		_note( $ctx, 'the local library: %s', $local );
		push @opts, "--local-lib=$local";
	}
	$ctx->{options} = \@opts;

	return @opts;
}

# _tempdir($ctx):
#	The path of one new temporary directory. The context holds
#	each directory object, so every directory of the run stays
#	until the run ends.
sub _tempdir ($ctx)
{
	my $dir = File::Temp->newdir(
		TEMPLATE => 'fugubench-XXXXXXXX',
		TMPDIR   => 1
	);
	push @{ $ctx->{hold} }, $dir;

	return "$dir";
}

# _resolve($ctx, $url, $member):
#	The URL and the archive path with the platform words in place,
#	in that order (DEPS-ALIAS-1). The digest file selects the
#	spelling: the method forms one candidate for each alias pair,
#	and it takes the candidate that the file records
#	(DEPS-ALIAS-3). No match and more than one match are each an
#	error, and neither one asks the network (DEPS-ALIAS-4).
#
#	The method reports the failure and returns the empty list.
sub _resolve ( $ctx, $url, $member )
{
	my $log = $ctx->{app}->cli->log;

	# Each placeholder of the archive path must also sit in the
	# URL (DEPS-ALIAS-6). The archive path names a path inside the
	# archive, and only the URL selects the platform.
	for my $word (qw(os arch)) {
		next unless defined $member && $member =~ /\{$word\}/;
		next if $url =~ /\{$word\}/;
		$log->error(
			'the archive path holds {%s}, and the URL does not:'
			    . ' %s',
			$word, $url
		);
		return;
	}

	return ( $url, $member ) if $url !~ /\{(?:os|arch)\}/;

	# The digest file keys on the URL, so a candidate matches when
	# the file records that whole URL. Two candidates never share a
	# key, so more than one match is a real ambiguity.
	my @hit = grep { exists $ctx->{digests}{ $_->[0] } }
	    _candidates( $url, $ctx->{os}, $ctx->{arch} );

	unless (@hit) {
		$log->error( 'deps/SHA256.txt records no digest for %s', $url );
		$log->error(  'the file keys on the whole download URL; run'
			    . q{ 'deps --update-sums' and check each new line}
		);
		return;
	}
	if ( @hit > 1 ) {
		$log->error(
			'deps/SHA256.txt records more than one candidate'
			    . ' of %s',
			$url
		);
		$log->error( '  %s', $_->[0] ) for @hit;
		$log->error(  q{'deps --update-sums --force' keeps one}
			    . ' candidate and drops the others' );
		return;
	}

	my ( $value, $os_word, $arch_word ) = @{ $hit[0] };

	return ( $value,
		defined $member
		? _expand( $member, $os_word, $arch_word )
		: undef );
}

# _candidates($text, $os, $arch):
#	Every distinct expansion of one text, in preference order,
#	with the word pair that made each one.
sub _candidates ( $text, $os, $arch )
{
	my ( @out, %seen );
	for my $os_word ( _os_words($os) ) {
		for my $arch_word ( _arch_words($arch) ) {
			my $value = _expand( $text, $os_word, $arch_word );
			next if $seen{$value}++;
			push @out, [ $value, $os_word, $arch_word ];
		}
	}

	return @out;
}

# _os_words($os):
#	Every asset spelling of one system name, in preference order.
#	An unknown name gives its own lower case (DEPS-ALIAS-2).
sub _os_words ($os)
{
	return @{ $OS_ALIAS{$os} // [ lc $os ] };
}

# _arch_words($arch):
#	Every asset spelling of one machine name, in preference order.
#	An unknown name gives itself (DEPS-ALIAS-2).
sub _arch_words ($arch)
{
	return @{ $ARCH_ALIAS{$arch} // [$arch] };
}

# _expand($text, $os_word, $arch_word):
#	One text with both placeholders replaced.
sub _expand ( $text, $os_word, $arch_word )
{
	my $out = $text;
	$out =~ s/\{os\}/$os_word/g;
	$out =~ s/\{arch\}/$arch_word/g;

	return $out;
}

# _archive_type($url):
#	The archive type that the suffix of the URL names: tar for
#	.tar.gz and .tgz, zip for .zip, and undef for a plain file.
sub _archive_type ($url)
{
	return 'tar' if $url =~ /\.(?:tar\.gz|tgz)\z/;
	return 'zip' if $url =~ /\.zip\z/;

	return;
}

# _update_sums($ctx, $file, $by_type):
#	Record the digest of each download that the manifest names,
#	and write deps/SHA256.txt (DEPS-SUMS-1). The operator runs
#	this command, and the install path never does.
#
#	The entries hold every environment of one manifest, because
#	one digest file records every download of one operating
#	system. The method returns the exit code of the run.
sub _update_sums ( $ctx, $file, $by_type )
{
	my $sums = {
		digests  => $ctx->{digests},
		legacy   => [ _legacy( $ctx->{digests} ) ],
		report   => [],
		recorded => 0,
		missed   => 0,
	};

	# The dist entries and the bin entries name every download of
	# the manifest. A pkg name and a cpan name reach a package
	# manager, which owns its own check.
	my @urls = @{ $by_type->{dist} };
	push @urls, ( split q{ }, $_, 3 )[1] for @{ $by_type->{bin} };

	for my $url (@urls) {
		my $code = _record( $ctx, $sums, $url );
		return $code if $code != EXIT_SUCCESS;
	}

	return _write_sums( $ctx, $sums, $file );
}

# _write_sums($ctx, $sums, $file):
#	End one refresh: report each line of the run, and write the
#	digest file when the run recorded something (DEPS-SUMS-12).
#	The method returns the exit code of the run.
#
#	A run with an entry that reached no candidate writes nothing,
#	because a half state must not reach the recorded file. An
#	operator must also read no success line for a state that makes
#	the next install fail.
sub _write_sums ( $ctx, $sums, $file )
{
	my $log = $ctx->{app}->cli->log;

	if ( $sums->{missed} ) {
		$log->error(
			'%d entry of the manifest reached no candidate, and %s'
			    . ' stays as it was',
			$sums->{missed}, $file
		);
		$log->error(  '  check the URL of each entry, and check that'
			    . ' --os and --arch name a platform of the release'
		);
		$log->error(  '  a signed manifest that names no candidate'
			    . ' needs a release with a per-platform file name'
		);
		return EXIT_ERROR;
	}

	say for @{ $sums->{report} };

	unless ( $sums->{recorded} ) {
		say "recorded nothing, and $file stays as it was";
		return EXIT_SUCCESS;
	}

	# The writer sorts the keys, so a second refresh makes a stable
	# diff (DEPS-TIER-3).
	my $text = _signify()->write_manifest( $sums->{digests} );
	unless ( defined $text ) {
		$log->error( '%s: %s', $file, _signify()->error );
		return EXIT_ERROR;
	}
	unless ( Fugu::File->write( $file, $text ) ) {
		$log->error( 'cannot write %s: %s', $file, $! );
		return EXIT_ERROR;
	}
	say "wrote $file";

	return EXIT_SUCCESS;
}

# _record($ctx, $sums, $url):
#	Take one download of the manifest through the rules of the
#	refresh. The method returns the exit code of the run:
#	EXIT_SUCCESS for an entry that records, keeps, skips or
#	misses, and another code for a fault that stops the refresh.
#
#	A candidate URL that the file records already stays, so a
#	version bump needs no hand edit. This branch leaves a file
#	that holds two candidates of one entry as it is, and --force
#	repairs that. --force also repairs a digest that no longer
#	matches the release.
sub _record ( $ctx, $sums, $url )
{
	my $app = $ctx->{app};

	# The alias words expand into the URL, and a candidate becomes
	# a key of the digest file. The shape takes its check again
	# after the expansion, so no run writes a line that a later run
	# cannot read (DEPS-TIER-12).
	my @candidate = _candidates( $url, $ctx->{os}, $ctx->{arch} );
	for my $one (@candidate) {
		return Fugu::CLI::EXIT_CONFIG_ERROR()
		    unless _check_url( $app, $one->[0], 'the resolved URL' );
	}

	my @known =
	    grep { exists $sums->{digests}{$_} } map { $_->[0] } @candidate;
	if ( @known && !$ctx->{force} ) {

		# The file holds the URL of this entry, so the file-name
		# key that it replaces goes (DEPS-SUMS-11).
		$sums->{recorded} += _drop_legacy( $sums, $known[0] );
		push @{ $sums->{report} }, "kept $known[0]";
		return EXIT_SUCCESS;
	}

	# A digest covers a versioned name, so a stable name stays on
	# the signify tier (DEPS-SUMS-3). The test reads the manifest,
	# and never the network.
	if ( !$ctx->{force} && _stable($url) ) {
		push @{ $sums->{report} }, "skipped the stable name: $url";
		return EXIT_SUCCESS;
	}

	my $signed = _signed( $ctx, @candidate );
	return EXIT_ERROR unless $signed;

	my $code = _signed_entry( $ctx, $sums, $url, $signed, \@known );
	return $code if defined $code;

	return _download_sums( $ctx, $sums, $url, \@candidate, \@known );
}

# _stable($url):
#	1 for a URL that names a stable download, and 0 for a
#	versioned one (DEPS-SUMS-2). A versioned name carries a digit
#	in the path of its URL. A stable name carries none, or it
#	holds /releases/latest/.
#
#	An entry with a placeholder is never stable, because the
#	resolution reads the digest file, and that entry then needs a
#	recorded digest (DEPS-ALIAS-5).
sub _stable ($url)
{
	return 0 if $url =~ /\{(?:os|arch)\}/;
	return 1 if index( $url, '/releases/latest/' ) >= 0;

	my ($path) = $url =~ m{\A[a-z][a-z0-9+.-]*://[^/]+(/.*)\z}i;

	return !defined $path || $path !~ /[0-9]/ ? 1 : 0;
}

# _signed($ctx, @candidate):
#	The answer of the signed-manifest probe over the candidates of
#	one entry, as a hash with 'found', 'verified' and 'taken'. The
#	method returns undef after a failure of the run, which it
#	reports.
#
#	The probe asks each distinct resolved directory of the
#	candidates, and never the directory of the template, which
#	names no server (DEPS-SUMS-6). A manifest that answers keeps
#	the entry off the digest tier, whether or not a key verifies
#	it. A server that withholds the signature alone must not make
#	the refresh pin the bytes that it serves (DEPS-SUMS-3).
#
#	'taken' holds the first candidate of the answering directory
#	that the manifest names, with its digest, and the probe stops
#	there. A verified manifest that names no candidate must not
#	hide a later directory that holds the release (DEPS-SUMS-7).
sub _signed ( $ctx, @candidate )
{
	my $answer = { found => 0, verified => 0 };

	my %seen;
	for my $one (@candidate) {
		my $base = _base( $one->[0] );
		next unless defined $base;
		next if $seen{$base}++;

		# Each probe takes a directory of its own. One shared
		# path would let a later probe that finds nothing keep
		# the manifest of an earlier answer.
		my $dir  = _tempdir($ctx);
		my $sums = File::Spec->catfile( $dir, 'SHA256' );
		my $sig  = File::Spec->catfile( $dir, 'SHA256.sig' );

		my $got = _probe( $ctx, "$base/SHA256", $sums );
		return unless defined $got;
		next   unless $got;

		$answer->{found} = 1;
		$got = _probe( $ctx, "$base/SHA256.sig", $sig );
		return unless defined $got;
		next   unless $got;

		# A manifest that no key verifies is a normal outcome
		# of the probe, so each line of it is a warning
		# (DEPS-SUMS-6).
		next unless _verify( $ctx, $sums, $sig, 'warning' );
		$answer->{verified} = 1;

		my $digests = _parse_digests( $ctx->{app}, $sums );
		return unless $digests;

		$answer->{taken} = _taken( $base, $digests, @candidate );
		last if defined $answer->{taken};
	}

	return $answer;
}

# _taken($base, $digests, @candidate):
#	The first candidate of one directory that the signed manifest
#	of that directory names, with its digest, or undef.
#
#	The signed manifest keys on the file name, and the digest file
#	keys on the URL. The candidate carries both, so it joins the
#	two. A candidate of another directory names another release.
sub _taken ( $base, $digests, @candidate )
{
	for my $one (@candidate) {
		my $where = _base( $one->[0] );
		next unless defined $where && $where eq $base;

		my ($name) = $one->[0] =~ m{([^/]+)\z};
		next unless defined $name && exists $digests->{$name};

		return [ $one->[0], $digests->{$name} ];
	}

	return;
}

# _signed_entry($ctx, $sums, $url, $signed, $known):
#	Take one entry whose directory holds a signed manifest. The
#	method returns the exit code of the entry, or undef when the
#	refresh must download the candidates itself.
#
#	A URL without a placeholder installs through the signify tier,
#	so it needs no digest, and a recorded one would outrank the
#	signature (DEPS-SUMS-5). A URL with a placeholder needs a
#	digest, and the signed manifest is where it comes from
#	(DEPS-SUMS-4).
#
#	--force overrides both, with a warning first (DEPS-SUMS-10).
#	An upstream that publishes a manifest which the operator
#	cannot verify would otherwise leave the entry unpinnable.
sub _signed_entry ( $ctx, $sums, $url, $signed, $known )
{
	my $log = $ctx->{app}->cli->log;

	return unless $signed->{found};

	if ( $url !~ /\{(?:os|arch)\}/ ) {
		unless ( $ctx->{force} ) {
			push @{ $sums->{report} },
			    "skipped the signed entry: $url";
			return EXIT_SUCCESS;
		}
		_warn_force( $log, $url );

		return;
	}

	my $taken = $signed->{taken};
	if ( defined $taken ) {

		# --force replaces the line of this entry, so every
		# other recorded candidate of it goes (DEPS-SUMS-10).
		_drop_siblings( $sums, $known, $taken->[0] ) if $ctx->{force};
		_drop_legacy( $sums, $taken->[0] );
		$sums->{digests}{ $taken->[0] } = $taken->[1];
		$sums->{recorded}++;
		push @{ $sums->{report} },
		    "recorded $taken->[0] from the signed manifest";

		return EXIT_SUCCESS;
	}

	unless ( $ctx->{force} ) {

		# Without a digest this entry can never install, so the
		# run must not report success (DEPS-SUMS-7).
		$log->warning(
			$signed->{verified}
			? 'the signed manifest beside %s names no candidate'
			: 'nothing verifies the signed manifest beside %s',
			$url
		);
		$log->warning(q{  '--update-sums --force' pins the bytes}
			    . ' that the server serves' );
		$sums->{missed}++;

		return EXIT_SUCCESS;
	}
	_warn_force( $log, $url );

	return;
}

# _warn_force($log, $url):
#	The warning of a --force that pins a URL of the signify tier
#	(DEPS-SUMS-10).
sub _warn_force ( $log, $url )
{
	$log->warning(
		'--force pins a URL that a signed manifest covers, and the'
		    . ' recorded digest then outranks the signature: %s',
		$url
	);

	return;
}

# _download_sums($ctx, $sums, $url, $candidate, $known):
#	Download each candidate of one entry, and record the digest of
#	the first one that answers (DEPS-SUMS-9). The method returns
#	the exit code of the entry.
#
#	Each candidate takes a directory of its own, because two
#	candidates can share a file name (DEPS-SUMS-8). A 404 is the
#	absent answer of a candidate, and every other failed download
#	stops the refresh. An entry that no candidate answers fails
#	the run (DEPS-SUMS-7).
sub _download_sums ( $ctx, $sums, $url, $candidate, $known )
{
	my $log = $ctx->{app}->cli->log;

	my @found;
	for my $one (@$candidate) {
		my ($name) = $one->[0] =~ m{([^/]+)\z};
		next unless defined $name && $name ne q{};

		my $path   = File::Spec->catfile( _tempdir($ctx), $name );
		my $answer = _probe( $ctx, $one->[0], $path );
		return EXIT_ERROR unless defined $answer;
		next              unless $answer;

		push @found, [ $one->[0], $path ];
	}

	unless (@found) {
		$log->warning( 'no candidate answers for %s', $url );
		$sums->{missed}++;

		return EXIT_SUCCESS;
	}

	my ( $taken, $path ) = @{ $found[0] };
	my $digest = _sha256($path);
	unless ( defined $digest ) {
		$log->error( 'cannot read %s: %s', $path, $! );
		return EXIT_ERROR;
	}

	# --force replaces the line of this entry, so every other
	# recorded candidate of it goes (DEPS-SUMS-10).
	_drop_siblings( $sums, $known, $taken ) if $ctx->{force};
	_drop_legacy( $sums, $taken );
	$sums->{digests}{$taken} = $digest;
	$sums->{recorded}++;
	push @{ $sums->{report} }, "recorded $taken";

	return EXIT_SUCCESS if @found == 1;

	# The install rejects a URL that more than one recorded
	# candidate covers, so the operator must see each other
	# answer. The line of each one names it, and the recorded
	# candidate stays out of that list.
	$log->warning(
		'more than one candidate answers for %s: the refresh records'
		    . ' %s, and each candidate below stays out of the file',
		$url, $taken
	);
	$log->warning( '  %s', $_->[0] ) for @found[ 1 .. $#found ];

	return EXIT_SUCCESS;
}

# _drop_siblings($sums, $known, $taken):
#	Remove every other recorded candidate of one entry, and report
#	each one. Two recorded candidates make the install ambiguous
#	(DEPS-ALIAS-3).
sub _drop_siblings ( $sums, $known, $taken )
{
	for my $other (@$known) {
		next if $other eq $taken;
		delete $sums->{digests}{$other};
		push @{ $sums->{report} }, "removed $other";
	}

	return;
}

# _drop_legacy($sums, $taken):
#	Remove the file-name key that one recorded URL replaces, and
#	report each one. The method returns the number of keys that it
#	removed (DEPS-SUMS-11).
#
#	One run reads the manifest of one operating system, so a key
#	that this run cannot replace stays. A blanket drop would take
#	the pin of every other platform with it.
sub _drop_legacy ( $sums, $taken )
{
	my ($name) = $taken =~ m{([^/]+)\z};
	return 0 unless defined $name;

	my $dropped = 0;
	for my $key ( @{ $sums->{legacy} } ) {
		next unless $key eq $name;
		next unless exists $sums->{digests}{$key};
		delete $sums->{digests}{$key};
		push @{ $sums->{report} }, "dropped the file-name key $key";
		$dropped++;
	}

	return $dropped;
}

# _command($ctx, @cmd):
#	Run one command of an install as a child. A dry run prints the
#	trace line and runs nothing (DEPS-MANIFEST-6). A real run
#	prints no line here, because $app->command traces each child
#	on standard error under --verbose (CLI-PROGRAM-7).
#
#	The child takes the environment of the run, because a package
#	manager and cpanm read it. No line of a child reaches standard
#	output, because a child writes no part of the result
#	(CLI-PROGRAM-4). $app->command writes the standard error of
#	every child to standard error, and this method writes the
#	standard output of a child that exits 0 there.
#
#	The method returns 1 for a child that exits 0, and 0 for every
#	other answer, which it reports. A failed command stops the run,
#	so no later command of the environment runs.
sub _command ( $ctx, @cmd )
{
	if ( $ctx->{dry} ) {
		_trace( $ctx, @cmd );
		return 1;
	}

	my $app = $ctx->{app};
	my $out = $app->command( \@cmd );
	unless ( defined $out ) {
		$app->cli->log->error( '%s', $app->error );
		return 0;
	}
	print STDERR $out if length $out;

	return 1;
}

# _note($ctx, $fmt, @args):
#	Report one step of the run on standard error. The line goes
#	out under --verbose alone, because the program is silent on
#	success except for the result line (CLI-PROGRAM-7).
#	DEPS-MANIFEST-9 names the progress lines of this verb.
#
#	A message that reports a fault takes the logger directly, at
#	the warning level or the error level, and no run hides it.
sub _note ( $ctx, $fmt, @args )
{
	my $cli = $ctx->{app}->cli;
	$cli->log->info( $fmt, @args ) if $cli->option('verbose');

	return;
}

# _trace($ctx, @cmd):
#	Trace one command of the run. A dry run prints it to standard
#	output, as the line that starts with '+ ' and holds each
#	argument shell-quoted (DEPS-MANIFEST-6). That trace is the
#	oracle of CLI-CONFORMANCE-2, so the form of the line comes
#	from the synced scripts/deps.
#
#	A real run prints no line to standard output, because standard
#	output carries the result of the verb alone (CLI-PROGRAM-4).
#	With --verbose the line goes to standard error, and this method
#	writes it (CLI-PROGRAM-7).
#
#	A download of the verb runs in-process, so $app->command never
#	sees it and traces nothing for it. The verbose branch here
#	covers that download alone: _command hands every child to
#	$app->command, which writes its own 'run: ' line.
#
#	That branch joins the words raw, as $app->command does, so one
#	run writes one form. The quoted form belongs to the dry-run
#	trace, whose reader is the oracle.
#
#	A download of the verb names the fetch verb in its line
#	(DEPS-FETCH-2).
sub _trace ( $ctx, @cmd )
{
	if ( $ctx->{dry} ) {
		say '+ ', join q{ }, map { _quote($_) } @cmd;
		return;
	}

	$ctx->{app}->cli->log->info( 'run: %s', join q{ }, @cmd )
	    if $ctx->{app}->cli->option('verbose');

	return;
}

# _quote($word):
#	Shell-quote one word of the dry-run trace line. The program
#	gives no word to a shell (CLI-PROGRAM-6). The quoting lets a
#	reader of the trace, and the oracle test, see that an argument
#	with a space is one argument.
sub _quote ($word)
{
	return $word unless $word eq q{} || $word =~ /[^\w.\/:=-]/;

	my $quoted = $word;
	$quoted =~ s/'/'\\''/g;

	return "'$quoted'";
}

1;
