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

package App::FuguBench::Dist;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Cwd            ();
use Digest::SHA    ();
use File::Basename ();
use File::Spec     ();

use Fugu::CLI qw(EXIT_SUCCESS EXIT_ERROR);
use Fugu::File;
use Fugu::Sandbox;

# App::FuguBench::Dist - the shim verb and the install verb.
#
# A consumer runs the program through a wrapper shim, and that shim
# holds the version that it runs (D-04). `shim` prints the shell of
# DIST-SHIM, and the org pack of FuguBSD/Tooling syncs it into a
# consumer (D-09). `install` copies the running program into the
# install directory of the operator (DIST-INSTALL-2).
#
# Neither verb reads a checkout (CLI-CHECKOUT-5). A fresh clone runs
# the shim before any install, and the install script of
# DIST-INSTALL-1 runs `install` in a home with no .toolingrc.
#
# Each verb opens a file of its own and runs no child, so each row
# unveils the paths that it opens (CLI-SANDBOX-2). shim_paths and
# install_paths hold the two lists.
#
# No verb here downloads. `shim` writes the URL into the shell text,
# and the shell of a consumer fetches it. So no URL of this module
# reaches Fugu::Curl, and none takes the shape check of DEPS-FETCH-4.

use constant {

	# The packed file of one release (DIST-ASSETS-1). The release
	# workflow publishes it under the tag of the version.
	URL => 'https://github.com/FuguBSD/FuguBench'
	    . '/releases/download/v%s/fugubench',

	# The version of a build that no release stamped. scripts/dist
	# writes it into a build of a tree with no tag, and a checkout
	# carries no stamp at all (DIST-VERSION-1).
	NO_STAMP => '0.0.0',

	# The mode of an installed program (DIST-INSTALL-2).
	MODE => 0755,
};

# App::FuguBench::Dist->command($verb):
#	The entry of the Fugu::CLI table of one verb. The module
#	holds two verbs, so it reads the name. An unknown name is a
#	programming error of the verb table.
sub command ( $, $verb )
{
	my %entry = (
		shim => {
			summary => 'print the wrapper shim of a consumer',
			run     => sub ( $app, @argv ) {
				return _shim( $app, @argv );
			},
		},
		install => {
			summary => 'copy the program into ~/.local/bin',
			run     => sub ( $app, @argv ) {
				return _install( $app, @argv );
			},
		},
	);

	my $entry = $entry{$verb} or die "no such verb: $verb";

	return $entry;
}

# App::FuguBench::Dist->shim_paths:
#	The unveil list of the `shim` row (CLI-SANDBOX-2). The verb
#	reads the running file and writes the shell text to standard
#	output, so the row names the directory of that file and
#	nothing else.
sub shim_paths ( $, $ )
{
	return _common_paths();
}

# App::FuguBench::Dist->install_paths:
#	The unveil list of the `install` row (CLI-SANDBOX-2). The
#	verb reads the running file and writes the copy, so the row
#	adds the install directory.
#
#	The install directory holds the running file after an
#	install, and then one entry names both. unveil(2) returns
#	EPERM on a second entry that widens a path, so the wider
#	entry replaces the other one.
#
#	The row makes that directory. unveil(2) hides every path that
#	the list leaves out, and the list can name the install
#	directory alone, so a mkdir under the parent would fail after
#	the entry. The verb makes the directory as well, and it
#	reports the failure, so the verb holds without this row.
sub install_paths ( $, $ )
{
	my @paths = _common_paths();

	my $dir = _install_dir();
	return @paths unless defined $dir && Fugu::File->ensure_dir($dir);

	# The comparison resolves each path, because HOME can hold a
	# symlink and the entry of the running file holds the resolved
	# form. 'rwc' reads as well, so the wider entry loses nothing.
	my $same = Cwd::abs_path($dir) // $dir;
	@paths =
	    grep { ( Cwd::abs_path( $_->[0] ) // $_->[0] ) ne $same } @paths;

	push @paths, [ $dir, 'rwc' ];

	return @paths;
}

# _common_paths():
#	The entries that both rows hold: the library directories of
#	the interpreter, and the directory of the running file.
#
#	perl loads a module on an error path, so the list holds the
#	library directories. Each one is optional, because the build
#	of a perl records a directory that the host can omit.
sub _common_paths ()
{
	my @paths =
	    map { [ $_, 'r', { optional => 1 } ] } Fugu::Sandbox->perl_lib_dirs;
	push @paths, [ File::Basename::dirname( _running_file() ), 'r' ];

	return @paths;
}

# _running_file():
#	The path of the running program. The absolute form names the
#	same file after a chdir, and the row of the verb unveils its
#	directory.
sub _running_file ()
{
	return Cwd::abs_path($0) // $0;
}

# _install_dir():
#	The install directory of DEPS-INSTALL-6, or undef when HOME
#	is unset. A bin entry of `deps` installs there too, so one
#	directory holds the tools of the operator.
sub _install_dir ()
{
	my $home = $ENV{HOME};
	return unless defined $home && $home ne q{};

	return File::Spec->catdir( $home, '.local', 'bin' );
}

# _digest($app, $file):
#	The sha256 digest of one file, in lower-case hex. The shim
#	holds its download to this value (DIST-SHIM-1). The function
#	returns undef, and reports, when the file does not open.
sub _digest ( $app, $file )
{
	open my $fh, '<', $file or do {
		$app->cli->log->error( 'cannot read %s: %s', $file, $! );
		return;
	};
	binmode $fh;
	my $digest = Digest::SHA->new(256)->addfile($fh)->hexdigest;
	close $fh;

	return $digest;
}

# _shim($app, @argv):
#	The body of the `shim` verb. It takes no argument, and an
#	argument is a usage error.
#
#	The shim pins one release, so it needs the version of that
#	release and the digest of its packed file. A checkout carries
#	no stamp, and a build of a tree with no tag carries 0.0.0. No
#	release holds either one, so the verb reports and returns 1.
#
#	The text below is the shim of DIST-SHIM. It holds three
#	values, and each one enters through its token. sprintf takes
#	no part here, because the text holds a per-cent sign of its
#	own, in the parameter expansion that cuts the digest.
#
#	A release asset answers a redirect, so each download follows
#	one. curl needs -L for that, and without it curl writes the
#	empty body of the redirect answer. wget and ftp follow a
#	redirect with no option: scripts/ftp of the org pack fetches
#	a release asset with each one.
#
#	The gate tests FUGUBENCH for a set variable, and not for a
#	non-empty value. `FUGUBENCH=$(command -v fugubench)` writes
#	an empty value on a failed lookup, and a download would then
#	run a program that the developer did not name (DIST-SHIM-2).
sub _shim ( $app, @argv )
{
	my $cli = $app->cli;
	return $cli->command_usage_error('shim') if @argv;

	# The stamp itself, and not the VERSION method. That method
	# parses the value: it truncates a value with a space, and it
	# dies on a value with a letter. The check below is the gate,
	# and it reports every value that it refuses.
	my $version = $App::FuguBench::VERSION;
	if ( !defined $version || $version eq NO_STAMP ) {
		$cli->log->error( 'no release stamped this file: run shim'
			    . ' on the packed file of a release' );
		return EXIT_ERROR;
	}

	# The verb writes the version into shell text, so the value
	# takes a shape check here. scripts/dist holds a build to the
	# same shape, and a value with a space or a semicolon would
	# write broken or injected shell.
	if ( $version !~ /\A[0-9]+(?:\.[0-9]+)+\z/a ) {
		$cli->log->error( 'the version %s is no dotted-decimal number',
			$version );
		return EXIT_ERROR;
	}

	my $digest = _digest( $app, _running_file() );
	return EXIT_ERROR unless defined $digest;

	my $url  = sprintf URL, $version;
	my $text = <<'SHIM';
#!/bin/sh
# The wrapper shim of fugubench @VERSION@. `fugubench shim` wrote it,
# and the org pack of FuguBSD/Tooling syncs it into a consumer. To
# take another release, sync the pack again.
set -eu

version=@VERSION@
url=@URL@
want=@SUM@

if [ -n "${FUGUBENCH+x}" ]; then
	if [ -x "$FUGUBENCH" ]; then exec "$FUGUBENCH" "$@"; fi
	echo "fugubench: FUGUBENCH=$FUGUBENCH is no executable" >&2
	exit 1
fi

dir=$HOME/.cache/fugubench/$version
file=$dir/fugubench
if [ ! -x "$file" ]; then
	# A value of the environment must never pass for a tool.
	get= sum= got=
	for c in curl wget ftp; do
		if command -v "$c" >/dev/null 2>&1; then get=$c; break; fi
	done
	for c in sha256 shasum sha256sum; do
		if command -v "$c" >/dev/null 2>&1; then sum=$c; break; fi
	done
	if [ -z "$get" ]; then
		echo "fugubench: install curl, wget or ftp" >&2
		exit 1
	fi
	if [ -z "$sum" ]; then
		echo "fugubench: install sha256, shasum or sha256sum" >&2
		exit 1
	fi
	mkdir -p "$dir"
	tmp=$dir/.download.$$
	trap 'rm -f "$tmp"' EXIT HUP INT TERM
	case $get in
	curl)	curl -fsSL -o "$tmp" "$url" ;;
	wget)	wget -q -O "$tmp" "$url" ;;
	ftp)	ftp -o "$tmp" "$url" ;;
	esac
	case $sum in
	sha256)		got=$(sha256 -q "$tmp") ;;
	shasum)		got=$(shasum -a 256 "$tmp") ;;
	sha256sum)	got=$(sha256sum "$tmp") ;;
	esac
	if [ "${got%% *}" != "$want" ]; then
		echo "fugubench: $url" >&2
		echo "fugubench: want $want" >&2
		echo "fugubench: got ${got%% *}" >&2
		exit 1
	fi
	chmod 755 "$tmp"
	mv "$tmp" "$file"
fi

exec "$file" "$@"
SHIM

	$text =~ s/\@VERSION\@/$version/g;
	$text =~ s/\@URL\@/$url/g;
	$text =~ s/\@SUM\@/$digest/g;

	print $text;

	return EXIT_SUCCESS;
}

# _install($app, @argv):
#	The body of the `install` verb. It takes no argument, and an
#	argument is a usage error.
#
#	The verb copies the running file, so the operator installs
#	the file that the shim fetched, or the file that the install
#	script downloaded. The copy is atomic, and the mode comes
#	from a chmod, because the open of the write takes the umask
#	of the operator (DIST-INSTALL-2).
sub _install ( $app, @argv )
{
	my $cli = $app->cli;
	my $log = $cli->log;
	return $cli->command_usage_error('install') if @argv;

	my $dir = _install_dir();
	unless ( defined $dir ) {
		$log->error('HOME is not set, and the install writes under it');
		return EXIT_ERROR;
	}
	return EXIT_ERROR unless Fugu::File->ensure_dir($dir);

	my $file = _running_file();
	my $text = Fugu::File->read($file);
	unless ( defined $text ) {
		$log->error( 'cannot read %s: %s', $file, $! );
		return EXIT_ERROR;
	}

	my $target = File::Spec->catfile( $dir, 'fugubench' );
	return EXIT_ERROR
	    unless Fugu::File->write_atomic( $target, $text, mode => MODE );
	unless ( chmod MODE, $target ) {
		$log->error( 'cannot set the mode of %s: %s', $target, $! );
		return EXIT_ERROR;
	}

	say $target;

	unless ( grep { $_ eq $dir } split /:/, ( $ENV{PATH} // q{} ), -1 ) {
		$log->warning(
			'no PATH entry names %s: add it to the'
			    . ' profile of your shell',
			$dir
		);
	}

	return EXIT_SUCCESS;
}

1;
