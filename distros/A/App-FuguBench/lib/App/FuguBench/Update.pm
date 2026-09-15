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

package App::FuguBench::Update;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Cwd        ();
use File::Spec ();
use File::Temp ();

use Fugu::CLI qw(EXIT_SUCCESS EXIT_ERROR);
use Fugu::Curl;
use Fugu::File;
use Fugu::Signify;

use App::FuguBench::Fetch;
use App::FuguBench::Keys;

# App::FuguBench::Update - the update verb.
#
# The verb replaces the running program with a release of the
# organization (DIST-UPDATE-1). The first fetch of the shim trusts
# HTTPS to GitHub, and every later download verifies against the
# release key, in this process (D-05).
#
# The keys come from App::FuguBench::Keys alone. The keys of a
# consumer never enter here, because a release of the organization
# carries the keys that verify the next one (DIST-KEY-2).
#
# The verb reads no checkout (CLI-CHECKOUT-5), so an operator runs it
# from ~/.local/bin in any directory.
#
# Three files reach the downloader: SHA256, SHA256.sig, and fugubench.
# Every one of them goes through _fetch, and _fetch calls check_url of
# App::FuguBench::Fetch first (DEPS-FETCH-4). One funnel holds the
# three, because Fugu::Curl places the URL last and builds no '--'
# separator. FUGUBENCH_RELEASE_URL comes from the environment, and the
# check covers the address that it builds.
#
# The row of the verb unveils nothing, because Fugu::Curl runs a
# downloader as a child (CLI-SANDBOX-2). The verb replaces the running
# file where it sits, so no path list bounds that write.

use constant {

	# The release directory of the organization (DIST-ASSETS-1).
	# FUGUBENCH_RELEASE_URL replaces this part, and a test points
	# the verb at a loopback server with it (DIST-UPDATE-1).
	URL => 'https://github.com/FuguBSD/FuguBench',

	# The three names of a release that the verb downloads.
	MANIFEST  => 'SHA256',
	SIGNATURE => 'SHA256.sig',
	PROGRAM   => 'fugubench',

	# The version of a build that no release stamped. A checkout
	# carries no stamp at all, so every release is above it
	# (DIST-VERSION-1).
	NO_STAMP => '0.0.0',

	# The mode of the replaced program (DIST-INSTALL-2).
	MODE => 0755,
};

# App::FuguBench::Update->command($verb):
#	The entry of the Fugu::CLI table. The module holds one verb,
#	so it ignores the name.
sub command ( $, $ )
{
	return {
		summary => 'replace the program with a verified release',
		usage   => '[--version <tag>] [--allow-downgrade]',
		options => {
			'version=s' => 'the release tag, in place of the'
			    . ' latest release',
			'allow-downgrade' => 'take a release below the'
			    . ' running version',
		},
		run => sub ( $app, @argv ) { return _run( $app, @argv ) },
	};
}

# _run($app, @argv):
#	The body of the verb. It takes no argument, and an argument is
#	a usage error.
#
#	The steps run in the order of DIST-UPDATE-1, and the first
#	failure stops the verb. The signature check comes in front of
#	the download of the packed file, so a release that no embedded
#	key signed costs the manifest and its signature, and no more.
#
#	Every failure returns 1 with the reason on standard error. A
#	tag of another shape is a usage error, and it returns 2.
sub _run ( $app, @argv )
{
	my $cli = $app->cli;
	my $log = $cli->log;

	return $cli->command_usage_error('update') if @argv;

	# The tag reaches a URL, and a release tag of this
	# organization is v<MAJOR>.<MINOR>.<PATCH> (DIST-ASSETS-1). The
	# shape check also holds the value to one path segment.
	my $tag = $cli->option('version');
	if ( defined $tag && $tag !~ /\Av[0-9]+[.][0-9]+[.][0-9]+\z/a ) {
		$log->error( 'the tag %s is no v<MAJOR>.<MINOR>.<PATCH>',
			$tag );
		return $cli->command_usage_error('update');
	}

	my $file = _running_file();
	return EXIT_ERROR unless _outside_cache( $app, $file );

	my $temp = File::Temp->newdir(
		TEMPLATE => 'fugubench-XXXXXXXX',
		TMPDIR   => 1
	);
	my $dir  = "$temp";
	my $base = _release_url($tag);
	my $curl = Fugu::Curl->new;

	my $manifest  = File::Spec->catfile( $dir, MANIFEST );
	my $signature = File::Spec->catfile( $dir, SIGNATURE );
	return EXIT_ERROR
	    unless _fetch( $app, $curl, $base, MANIFEST, $manifest, $tag )
	    && _fetch( $app, $curl, $base, SIGNATURE, $signature, $tag );

	my @keys = _key_files( $app, $dir );
	return EXIT_ERROR unless @keys;

	# The perl engine parses the signify(1) formats itself and
	# checks the signature with Fugu::Ed25519, so no host needs
	# signify(1).
	my $signify = Fugu::Signify->new( engine => 'perl' );
	unless (
		defined $signify->verify(
			keys      => \@keys,
			file      => $manifest,
			signature => $signature
		) )
	{
		$log->error( 'no embedded key verifies the signature of %s/%s',
			$base, MANIFEST );
		$log->error( '  %s', $signify->error );
		return EXIT_ERROR;
	}

	my $version = _manifest_version( $app, $signify, $manifest, $base );
	return EXIT_ERROR unless defined $version;

	my $running = _running_version();
	if ( !$cli->option('allow-downgrade') && _below( $version, $running ) )
	{
		$log->error(
			'the release %s is below the running %s, and a replay'
			    . ' of an earlier release is an attack',
			$version, $running
		);
		$log->error('  pass --allow-downgrade to take it anyway');
		return EXIT_ERROR;
	}

	my $packed = File::Spec->catfile( $dir, PROGRAM );
	return EXIT_ERROR
	    unless _fetch( $app, $curl, $base, PROGRAM, $packed, $tag );

	# The digest check comes from the module that verified the
	# signature, so one library holds both checks. The call reads
	# the signature again, and it digests no file before the
	# manifest verifies.
	my $name = PROGRAM;
	unless (
		defined $signify->verify_manifest(
			keys      => \@keys,
			manifest  => $manifest,
			signature => $signature,
			files     => { $name => $packed } ) )
	{
		$log->error( 'the packed file of %s failed its check', $base );
		$log->error( '  %s', $signify->error );
		return EXIT_ERROR;
	}

	return EXIT_ERROR unless _replace( $app, $file, $packed );

	# The result line of the verb (DIST-UPDATE-4).
	say "fugubench $version";

	return EXIT_SUCCESS;
}

# _running_file():
#	The path of the running program, with every symlink resolved.
#	The verb replaces that file where it sits, so a program under
#	~/.local/bin and a program of another directory each take the
#	same path.
sub _running_file ()
{
	return Cwd::realpath($0) // $0;
}

# _running_version():
#	The version of the running program. The dist build stamps it
#	into the package, and a checkout carries no stamp.
#
#	A value of another shape reads as no stamp. The comparison of
#	_below reads each field as a number, and a field that is no
#	number would compare as zero without a word.
sub _running_version ()
{
	my $version = $App::FuguBench::VERSION;
	return NO_STAMP unless defined $version;
	return NO_STAMP unless $version =~ /\A[0-9]+(?:[.][0-9]+)*\z/a;

	return $version;
}

# _release_url($tag):
#	The release directory of the download, without a final
#	solidus. The latest release and a named tag sit at two
#	addresses of GitHub.
#
#	FUGUBENCH_RELEASE_URL replaces the host and the repository
#	(DIST-UPDATE-1). A developer and a test point the verb at
#	another server with it, as the shim takes its own override
#	from the environment (DIST-SHIM-2). The value can end with a
#	solidus, and this method removes it, so no address holds two.
sub _release_url ($tag)
{
	my $base = $ENV{FUGUBENCH_RELEASE_URL};
	$base = URL unless defined $base && length $base;
	$base =~ s{/+\z}{};

	return defined $tag
	    ? "$base/releases/download/$tag"
	    : "$base/releases/latest/download";
}

# _outside_cache($app, $file):
#	Hold the running file out of the shim cache (DIST-UPDATE-3).
#	The method returns 1 for a file that the verb can replace, and
#	0 for one under the cache, which it reports. An unset or an
#	empty HOME is a refusal as well, because the cache path starts
#	with that value and the method cannot find the cache without
#	it.
#
#	The cache path carries the version, and the shim holds the
#	cached file to the digest of that version. A replaced file
#	fails that digest, so the shim stops and the operator has no
#	program. A new version reaches a consumer through a sync of
#	the org pack.
#
#	The comparison resolves the cache directory, because HOME can
#	hold a symlink and the running file carries the resolved form.
#	An absent directory resolves to nothing, and the literal path
#	stands then.
sub _outside_cache ( $app, $file )
{
	my $home = $ENV{HOME};
	unless ( defined $home && length $home ) {
		$app->cli->log->error( 'HOME is unset or empty, and the'
			    . ' shim cache sits under it' );
		return 0;
	}

	my $cache = File::Spec->catdir( $home, '.cache', 'fugubench' );
	$cache = Cwd::realpath($cache) // $cache;

	# The separator is a solidus, as it is in File::Spec on every
	# platform that pledge(2) and unveil(2) reach.
	return 1
	    unless $file eq $cache || index( $file, "$cache/" ) == 0;

	$app->cli->log->error( '%s sits under the shim cache %s',
		$file, $cache );
	$app->cli->log->error(
		      '  the shim holds that file to a digest, so a new version'
		    . ' comes from a sync of the org pack of FuguBSD/Tooling' );

	return 0;
}

# _fetch($app, $curl, $base, $name, $path, $tag):
#	Download one file of the release directory. The method returns
#	1 on success, and 0 after a failure, which it reports.
#
#	Every download of the verb passes here, and the shape check of
#	the URL runs first (DEPS-FETCH-4). Fugu::Curl places the URL
#	last and writes no '--' separator, so a URL that starts with a
#	dash would reach the downloader as an option.
#
#	A 404 names the tag. An absent tag and an absent asset give
#	that one answer, and no caller tells the two apart, so the
#	message names both.
sub _fetch ( $app, $curl, $base, $name, $path, $tag )
{
	my $log = $app->cli->log;
	my $url = "$base/$name";

	return 0
	    unless App::FuguBench::Fetch::check_url( $app, $url,
		'the release address' );

	return 1 if $curl->fetch( $url, $path );

	if ( ( $curl->status // q{} ) eq 'http' && ( $curl->code // 0 ) == 404 )
	{
		$log->error(
			'the release %s answers no %s: the tag names no'
			    . ' release, or that release holds no such asset',
			$tag // 'latest',
			$name
		);
		return 0;
	}

	$log->error( '%s', $curl->error );

	return 0;
}

# _key_files($app, $dir):
#	One signify public key file for each embedded release key, in
#	the trust order of App::FuguBench::Keys (DIST-KEY-1).
#	Fugu::Signify reads a key from a path, so the verb writes the
#	list that it holds.
#
#	The method returns the paths, and the empty list after a
#	failure, which it reports. A program that embeds no key
#	verifies nothing, and that build is broken.
sub _key_files ( $app, $dir )
{
	my $log = $app->cli->log;
	my @paths;

	for my $pair ( App::FuguBench::Keys->keys ) {
		my ( $name, $body ) = @$pair;

		my $path = File::Spec->catfile( $dir, "$name.pub" );
		my $text = "untrusted comment: $name public key\n$body\n";
		unless ( Fugu::File->write( $path, $text ) ) {
			$log->error( 'cannot write the key file %s', $path );
			return ();
		}
		push @paths, $path;
	}

	$log->error('this build embeds no release key') unless @paths;

	return @paths;
}

# _manifest_version($app, $signify, $manifest, $base):
#	The version of the release, from the versioned tarball name of
#	the manifest (DIST-ASSETS-1). The method returns undef after a
#	failure, which it reports.
#
#	The manifest is the version, because the release workflow
#	writes the tag into that name. The manifest also names the
#	tarball of the stable name, and that one carries no version.
#
#	The caller verifies the signature before this call, so the
#	name that the method reads carries the signature of a release
#	key.
sub _manifest_version ( $app, $signify, $manifest, $base )
{
	my $log  = $app->cli->log;
	my $text = Fugu::File->read($manifest);
	unless ( defined $text ) {
		$log->error( 'cannot read %s', $manifest );
		return;
	}

	my $digests = $signify->parse_manifest($text);
	unless ($digests) {
		$log->error( 'the manifest of %s does not parse: %s',
			$base, $signify->error );
		return;
	}

	my @found = sort map {
		/\AApp-FuguBench-([0-9]+(?:[.][0-9]+)+)[.]tar[.]gz\z/a ? $1 : ()
	} keys %$digests;

	unless ( @found == 1 ) {
		$log->error(
			'the manifest of %s names %d versioned tarballs, and a'
			    . ' release holds one',
			$base,
			scalar @found
		);
		return;
	}

	return $found[0];
}

# _below($release, $running):
#	Report if the release version sits below the running one
#	(DIST-UPDATE-2). Each value is a dotted-decimal number, and
#	the comparison reads field by field, so 1.10.0 sits above
#	1.9.0.
sub _below ( $release, $running )
{
	my @new = split /[.]/, $release;
	my @old = split /[.]/, $running;

	for my $i ( 0 .. 2 ) {
		my $a = $new[$i] // 0;
		my $b = $old[$i] // 0;
		return 1 if $a < $b;
		return 0 if $a > $b;
	}

	return 0;
}

# _replace($app, $file, $packed):
#	Put the verified bytes in the place of the running file. The
#	method returns 1, and 0 after a failure, which it reports.
#
#	The write is atomic, so a reader of the path sees the old
#	program or the new one, and never a half-written file. The
#	mode comes from a chmod, because the open of the write takes
#	the umask of the operator.
sub _replace ( $app, $file, $packed )
{
	my $log  = $app->cli->log;
	my $text = Fugu::File->read($packed);
	unless ( defined $text ) {
		$log->error( 'cannot read %s', $packed );
		return 0;
	}

	return 0 unless Fugu::File->write_atomic( $file, $text, mode => MODE );

	unless ( chmod MODE, $file ) {
		$log->error( 'cannot set the mode of %s: %s', $file, $! );
		return 0;
	}

	return 1;
}

1;
