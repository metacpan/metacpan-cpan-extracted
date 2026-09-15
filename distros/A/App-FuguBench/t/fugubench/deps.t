#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The manifest, the alias expansion, the type order, and the dry-run
# trace of the deps verb (DEPS-MANIFEST, DEPS-ALIAS, DEPS-INSTALL-6,
# DEPS-INSTALL-8, DEPS-TIER-12).
#
# Each case runs bin/fugubench as a child with -Ilib, against a
# temporary checkout that holds one deps/ directory. The child takes
# HOME, TMPDIR and PATH inside the temporary tree, so no case reads
# the operator home, and no case writes outside the tree. PATH holds
# one stub cpanm, so the trace names the bare command. The case of
# the bootstrap runs with a PATH that holds no command.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";

use Fugu::File;
use Fugu::Process;

my $root    = "$RealBin/../..";
my $program = "$root/bin/fugubench";

# Fugu::Process gives a child the named environment alone, and CI
# reaches the installed Fugu through PERL5LIB. Every child of this
# test therefore carries it.
my %LIB = defined $ENV{PERL5LIB} ? ( PERL5LIB => $ENV{PERL5LIB} ) : ();

# The digest of one gitleaks asset. The value is a fixture of the
# alias resolution, and no case downloads the file.
my $SUM = 'b40ab0ae55c505963e365f271a8d3846efbc170aa17f2607f13df610a9aeb6a5';

my $tree = tempdir( CLEANUP => 1 );
my $home = "$tree/home";
my $tmp  = "$tree/tmp";
my $path = "$tree/bin";
make_path( $home, $tmp, $path );

# The stub cpanm keeps the trace of a dist and a cpan entry at the
# bare command name. Without one, the verb traces the bootstrap
# download and this perl.
Fugu::File->write( "$path/cpanm", "#!/bin/sh\nexit 0\n" ) or die 'write';
chmod 0755, "$path/cpanm" or die 'chmod';

my $case = 0;

# _checkout(%file):
#	A checkout that holds one deps/ directory. Each key names a
#	file of that directory, and each value holds its text.
sub _checkout (%file)
{
	my $dir = "$tree/case" . ++$case;
	make_path("$dir/deps");
	for my $name ( sort keys %file ) {
		Fugu::File->write( "$dir/deps/$name", $file{$name} )
		    or die "write $name";
	}

	return $dir;
}

# _deps($dir, @argv):
#	Run the verb against one checkout, and return the result of
#	Fugu::Process->run. The child holds HOME, and _no_home runs it
#	without.
sub _deps ( $dir, @argv )
{
	return _child( $dir, { HOME => $home }, @argv );
}

# _no_home($dir, @argv):
#	Run the verb with no HOME in the environment (DEPS-INSTALL-6).
sub _no_home ( $dir, @argv )
{
	return _child( $dir, {}, @argv );
}

# _child($dir, $env, @argv):
#	Run the verb with the named environment beside PATH and
#	TMPDIR.
sub _child ( $dir, $env, @argv )
{
	# --verbose is a global option, so it sits ahead of the verb.
	my @global = grep { $_ eq '--verbose' } @argv;
	my @option = grep { $_ ne '--verbose' } @argv;
	my $result = Fugu::Process->run(
		cmd => [
			$^X,  "-I$root/lib", $program, @global,
			'-C', $dir,          'deps',   @option
		],
		env => { PATH => $path, TMPDIR => $tmp, %LIB, %$env },
	);
	die "cannot run $program: $result->{error}\n"
	    if defined $result->{error};

	return $result;
}

# _trace($result):
#	The trace lines of one run, without the '+ ' lead, and with
#	each temporary directory replaced by one token.
sub _trace ($result)
{
	my @lines = grep { index( $_, '+ ' ) == 0 }
	    split /\n/, $result->{stdout};
	s{\A[+] }{}     for @lines;
	s{\Q$tmp\E/\S+?(?=/|\z|\s)}{TMP}g for @lines;

	return @lines;
}

# A usage error exits 2 and prints the usage (CLI-PROGRAM-3)
{
	my $dir = _checkout( 'Darwin.txt' => "test pkg ok\n" );
	my %usage = (
		'no environment word'    => ['--dry-run'],
		'two environment words'  => [ '--dry-run', 'test', 'develop' ],
		'an unknown environment' => [ '--dry-run', 'nosuch' ],
		'an os word with a path' => [ '--dry-run', '--os', '../etc',
			'test' ],
		'an arch word with a slash' => [ '--dry-run', '--arch', 'a/b',
			'test' ],
	);
	for my $name ( sort keys %usage ) {
		my $r = _deps( $dir, @{ $usage{$name} } );
		is( $r->{exit_code}, 2, "$name exits 2" );
		like(
			$r->{stderr}, qr/^usage: fugubench deps /m,
			"$name prints the usage to standard error"
		);
		is( $r->{stdout}, q{}, "$name writes no trace" );
	}
}

# Without a manifest for the operating system, the verb reports that
# fact and exits zero (DEPS-MANIFEST-5)
{
	my $dir = _checkout( 'Darwin.txt' => "test pkg ok\n" );
	my $r = _deps( $dir, '--dry-run', '--os', 'Plan9', 'test' );
	is( $r->{exit_code}, 0, 'a missing manifest exits 0' );
	is( $r->{stdout},    q{}, 'a missing manifest writes no trace' );
	like(
		$r->{stderr}, qr/no dependencies for Plan9/,
		'a missing manifest names the operating system'
	);
}

# A bad line is a configuration error that names the line, and the
# validation covers every environment (DEPS-MANIFEST-3,
# DEPS-MANIFEST-7, DEPS-MANIFEST-8, DEPS-INSTALL-8, DEPS-TIER-12)
{
	my %bad = (
		'a line of two words' => [ 'tool pkg', qr/environment, a type/ ],
		'an unknown environment' =>
		    [ 'nosuch pkg ok', qr/unknown environment 'nosuch'/ ],
		'an unknown type' =>
		    [ 'tool nosuch ok', qr/unknown type 'nosuch'/ ],
		'a pkg name with a leading dash' =>
		    [ 'tool pkg -rf', qr/must not start with a dash/ ],
		'a cpan name that is a URL' => [
			'tool cpan https://example.com/x',
			qr/must not be a URL/
		],
		'a bin line with no URL' =>
		    [ 'tool bin gitleaks', qr/a bin line holds/ ],
		'an archive URL with no member' => [
			'tool bin g https://example.com/x.tar.gz',
			qr/needs the path of the file/
		],
		'a member with a plain URL' => [
			'tool bin g https://example.com/x member',
			qr/needs an archive URL/
		],
		'a URL with a parenthesis' => [
			'runtime dist https://example.com/x(1).tar.gz',
			qr/parenthesis or a space/
		],
		'a URL that names no file' =>
		    [ 'runtime dist https://example.com/', qr/names no file/ ],
		'a dist URL with a leading dash' =>
		    [ 'runtime dist -rf', qr/must start with a scheme/ ],
		'a bin URL with no scheme' => [
			'tool bin g example.com/x',
			qr/must start with a scheme/
		],
		'a command name with a slash' => [
			'tool bin ../evil https://example.com/x',
			qr/the command name '\.\.\/evil'/
		],
		'an archive path with a parent segment' => [
			'tool bin g https://example.com/x.tar.gz ../etc',
			qr/no empty and no parent segment/
		],
		'an archive path with a leading dash' => [
			'tool bin g https://example.com/x.tar.gz -rf',
			qr/must not start with a dash/
		],
	);
	for my $name ( sort keys %bad ) {
		my ( $line, $re ) = @{ $bad{$name} };

		# Each bad line names the tool environment or the
		# runtime one, and the run asks for the test
		# environment. The verb validates every line
		# (DEPS-MANIFEST-3).
		my $dir = _checkout(
			'Darwin.txt' => "# a comment\ntest pkg ok\n$line\n" );

		my $r = _deps( $dir, '--dry-run', '--os', 'Darwin', 'test' );
		is( $r->{exit_code}, 3, "$name exits 3" );
		is( $r->{stdout},    q{}, "$name writes no trace" );
		like( $r->{stderr}, $re, "$name names the fault" );
		like(
			$r->{stderr}, qr{deps/Darwin\.txt:3\b},
			"$name names the file and the line"
		);
	}
}

# A comment line and a blank line carry no entry (DEPS-MANIFEST-2)
{
	my $dir = _checkout(
		'Darwin.txt' => "#test pkg skipped\n\n   \ntest pkg ok\n" );
	my $r = _deps( $dir, '--dry-run', '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 0, 'a comment and a blank line pass' );
	is_deeply(
		[ _trace($r) ],
		['brew install ok'],
		'a comment line names no package'
	);
}

# A bad line of deps/SHA256.txt is a configuration error
# (DEPS-TIER-3, DEPS-TIER-4)
{
	my %bad = (
		'a line that is no digest line' => 'sha256 x = y',
		'a digest of the wrong length'  => 'SHA256 (https://a/b) = ff',
		'a duplicate key' =>
		    "SHA256 (https://a/b) = $SUM\nSHA256 (https://a/b) = $SUM",
	);
	for my $name ( sort keys %bad ) {
		my $dir = _checkout(
			'Darwin.txt'  => "test pkg ok\n",
			'SHA256.txt'  => "$bad{$name}\n",
		);
		my $r = _deps( $dir, '--dry-run', '--os', 'Darwin', 'test' );
		is( $r->{exit_code}, 3, "$name of the digest file exits 3" );
		like(
			$r->{stderr}, qr{deps/SHA256\.txt},
			"$name of the digest file names the file"
		);
	}
}

# The install order is pkg, dist, cpan, bin (DEPS-MANIFEST-4)
{
	my $url = 'https://example.com/tool_{os}_{arch}.tar.gz';
	my $dir = _checkout(
		'Darwin.txt' => join( "\n",
			'test bin tool ' . $url . ' tool',
			'test cpan Some::Module',
			'test dist https://example.com/Dist.tar.gz',
			'test pkg package', q{} ),
		'SHA256.txt' =>
		    "SHA256 (https://example.com/Dist.tar.gz) = $SUM\n"
		    . "SHA256 (https://example.com/tool_darwin_arm64.tar.gz)"
		    . " = $SUM\n",
	);
	my $r = _deps( $dir, '--dry-run', '--os', 'Darwin', '--arch', 'arm64',
		'test' );
	is( $r->{exit_code}, 0, 'the four types exit 0' );
	is_deeply(
		[ _trace($r) ],
		[
			'brew install package',
			"fugubench fetch TMP/asset/Dist.tar.gz"
			    . ' https://example.com/Dist.tar.gz',
			'cpanm --notest TMP/asset/Dist.tar.gz',
			'cpanm --notest Some::Module',
			"mkdir -p $home/.local/bin",
			'fugubench fetch TMP/asset/tool_darwin_arm64.tar.gz'
			    . ' https://example.com/tool_darwin_arm64.tar.gz',
			'tar -xzf TMP/asset/tool_darwin_arm64.tar.gz -C TMP'
			    . ' tool',
			"cp TMP/tool $home/.local/bin/tool",
			"chmod 755 $home/.local/bin/tool",
		],
		'the trace holds pkg, dist, cpan, and bin in that order'
	);
}

# The trace is the standard output, and a progress line waits for
# --verbose (CLI-PROGRAM-4, CLI-PROGRAM-7, DEPS-MANIFEST-6,
# DEPS-MANIFEST-9)
{
	my $dir = _checkout( 'Darwin.txt' => "test pkg ok\n" );
	my $r = _deps( $dir, '--dry-run', '--os', 'Darwin', 'test' );
	is(
		$r->{stdout}, "+ brew install ok\n",
		'the trace is the whole standard output'
	);
	unlike(
		$r->{stderr}, qr/the OS packages/,
		'a run without --verbose writes no progress line'
	);

	$r = _deps( $dir, '--dry-run', '--verbose', '--os', 'Darwin', 'test' );
	is(
		$r->{stdout}, "+ brew install ok\n",
		'--verbose leaves the standard output as it was'
	);
	like(
		$r->{stderr}, qr/the OS packages: ok/,
		'--verbose adds the progress line to standard error'
	);
}

# A word with a space and a word with a quote each stay one argument
# (DEPS-MANIFEST-6)
{
	my $dir = _checkout(
		'Darwin.txt' => "test pkg two words\ntest pkg it's\n" );
	my $r = _deps( $dir, '--dry-run', '--os', 'Darwin', 'test' );
	is_deeply(
		[ _trace($r) ],
		[ q{brew install 'two words' 'it'\\''s'} ],
		'the trace quotes a word with a space and a word with a quote'
	);
}

# The package manager of each platform, and the update of Linux
# (DEPS-INSTALL-1)
{
	my %manager = (
		Darwin  => ['brew install one two'],
		Linux   => [ 'sudo apt-get update', 'sudo apt-get install -y one two' ],
		OpenBSD => ['pkg_add one two'],
	);
	for my $os ( sort keys %manager ) {
		my $dir =
		    _checkout( "$os.txt" => "test pkg one\ntest pkg two\n" );
		my $r = _deps( $dir, '--dry-run', '--os', $os, 'test' );
		is_deeply( [ _trace($r) ], $manager{$os},
			"the package manager of $os" );
	}
}

# The alias tables resolve the platform words against the digest file
# (DEPS-ALIAS-1, DEPS-ALIAS-2, DEPS-ALIAS-3)
{
	my $url = 'https://example.com/t_{os}_{arch}.zip';
	my %hit = (
		'the second os word'   => [ 'Darwin', 'arm64', 'macOS_arm64' ],
		'the second arch word' => [ 'Darwin', 'x86_64', 'darwin_x64' ],
		'an unknown os name in lower case' =>
		    [ 'Haiku', 'arm64', 'haiku_arm64' ],
		'an unknown arch name' => [ 'Linux', 'riscv64',
			'linux_riscv64' ],
	);
	for my $name ( sort keys %hit ) {
		my ( $os, $arch, $word ) = @{ $hit{$name} };
		my $dir = _checkout(
			"$os.txt" => "test bin t $url t\n",
			'SHA256.txt' =>
			    "SHA256 (https://example.com/t_$word.zip) = $SUM\n",
		);
		my $r =
		    _deps( $dir, '--dry-run', '--os', $os, '--arch', $arch,
			'test' );
		is( $r->{exit_code}, 0, "$name resolves" );
		my @trace = _trace($r);
		like(
			$trace[1], qr/\Qt_$word.zip\E\z/,
			"$name takes the candidate of the digest file"
		);
	}
}

# The alias words expand into the archive path too (DEPS-ALIAS-1)
{
	my $dir = _checkout(
		'Darwin.txt' => 'test bin gh'
		    . ' https://example.com/gh_{os}_{arch}.zip'
		    . " gh_{os}_{arch}/bin/gh\n",
		'SHA256.txt' =>
		    "SHA256 (https://example.com/gh_macOS_arm64.zip) = $SUM\n",
	);
	my $r =
	    _deps( $dir, '--dry-run', '--os', 'Darwin', '--arch', 'arm64',
		'test' );
	my @trace = _trace($r);
	like(
		$trace[2], qr{\Qgh_macOS_arm64/bin/gh\E},
		'the archive path holds the words of the candidate'
	);
}

# No match and more than one match are each an error that names the
# repair (DEPS-ALIAS-3), and the resolution asks no network
# (DEPS-ALIAS-4)
{
	my $url = 'https://example.com/t_{os}_{arch}.zip';
	my %bad = (
		'no candidate' => [ q{}, qr/records no digest/ ],
		'two candidates' => [
			"SHA256 (https://example.com/t_darwin_arm64.zip)"
			    . " = $SUM\n"
			    . "SHA256 (https://example.com/t_macOS_arm64.zip)"
			    . " = $SUM\n",
			qr/more than one candidate/
		],
	);
	for my $name ( sort keys %bad ) {
		my ( $sums, $re ) = @{ $bad{$name} };
		my $dir = _checkout(
			'Darwin.txt' => "test bin t $url t\n",
			'SHA256.txt' => $sums,
		);
		my $r =
		    _deps( $dir, '--dry-run', '--os', 'Darwin', '--arch',
			'arm64', 'test' );
		is( $r->{exit_code}, 3, "$name exits 3" );
		like( $r->{stderr}, $re, "$name names the fault" );
		like(
			$r->{stderr}, qr/deps --update-sums/,
			"$name names the repair"
		);
	}
}

# Each placeholder of the archive path must also sit in the URL
# (DEPS-ALIAS-6)
{
	my $dir = _checkout(
		'Darwin.txt' => 'test bin t https://example.com/t.zip'
		    . " t_{arch}/t\n" );
	my $r =
	    _deps( $dir, '--dry-run', '--os', 'Darwin', '--arch', 'arm64',
		'test' );
	is( $r->{exit_code}, 3, 'a placeholder that the URL lacks exits 3' );
	like(
		$r->{stderr}, qr/the archive path holds \{arch\}/,
		'the message names the placeholder'
	);
}

# A bin entry needs HOME (DEPS-INSTALL-6)
{
	my $dir = _checkout(
		'Darwin.txt' => "test bin t https://example.com/t\n",
		'SHA256.txt' => "SHA256 (https://example.com/t) = $SUM\n",
	);
	my $r = _no_home( $dir, '--dry-run', '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 1, 'a bin entry without HOME exits 1' );
	like( $r->{stderr}, qr/HOME is not set/, 'the message names HOME' );
	is( $r->{stdout}, q{}, 'a bin entry without HOME writes no trace' );
}

# A run without --dry-run runs each command, and a command that PATH
# does not hold stops it. PATH holds the stub cpanm alone, so no
# package manager answers, and the case installs nothing. The run
# writes no trace line, because standard output carries the result of
# the verb alone (CLI-PROGRAM-4).
{
	my $dir = _checkout( 'Darwin.txt' => "test pkg ok\n" );
	my $r = _deps( $dir, '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 1, 'an absent package manager exits 1' );
	is_deeply( [ _trace($r) ],
		[], 'a run without --dry-run writes no trace line' );
	like( $r->{stderr}, qr/brew/, 'the message names the command' );
	unlike(
		$r->{stdout}, qr/installed the dependencies/,
		'a failed run writes no result line'
	);
}

# The bootstrap names the standalone cpanm script when PATH holds no
# cpanm (DEPS-INSTALL-3)
{
	my $bare = "$tree/bare";
	make_path($bare);
	my $dir = _checkout( 'Darwin.txt' => "test cpan Some::Module\n" );
	my $result = Fugu::Process->run(
		cmd => [
			$^X, "-I$root/lib", $program, '-C',
			$dir, 'deps', '--dry-run', '--os', 'Darwin', 'test'
		],
		env => { PATH => $bare, TMPDIR => $tmp, HOME => $home, %LIB },
	);
	die "cannot run $program: $result->{error}\n"
	    if defined $result->{error};
	is_deeply(
		[ _trace($result) ],
		[
			'fugubench fetch TMP/cpanm https://cpanmin.us',
			"$^X TMP/cpanm --notest Some::Module",
		],
		'the bootstrap downloads cpanm and runs it with this perl'
	);
}

# With PERL_LOCAL_LIB_ROOT, every cpanm run takes --local-lib
# (DEPS-INSTALL-2)
{
	my $dir = _checkout( 'Darwin.txt' => "test cpan Some::Module\n" );
	my $r = _child(
		$dir,
		{ HOME => $home, PERL_LOCAL_LIB_ROOT => "$tree/local" },
		'--dry-run', '--os', 'Darwin', 'test'
	);
	is_deeply(
		[ _trace($r) ],
		["cpanm --notest --local-lib=$tree/local Some::Module"],
		'the cpanm run names the local library'
	);
}

done_testing();
