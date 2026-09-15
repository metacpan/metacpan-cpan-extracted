#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The port of the Workspace test t/ci/wiki.t (CLI-CONFORMANCE-1). It
# tests the wiki verb (WIKI-OPEN, WIKI-PAGES, WIKI-CAPTURE,
# WIKI-STATUS, WIKI-CONFINE). The hook subtest of the source sits in
# t/fugubench/hook.t, beside the hook verb.
#
# Each test makes a temp tree with a bare repository as the origin
# and one or two checkouts that clone it. No test reaches the
# network, and no test writes outside its temp tree.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use POSIX      qw(strftime);

my $lib     = "$RealBin/../../lib";
my $program = "$RealBin/../../bin/fugubench";

# _git(@args):
#	Run git, quiet, and die on a failure. Each argument is quoted:
#	a commit subject holds a space.
sub _git (@args)
{
	my $a   = join q{ }, map { "'$_'" } @args;
	my $out = qx(git $a 2>&1);
	die "git $a: $out" if $?;

	return $out;
}

# _wiki($checkout, @args):
#	Run the wiki verb against $checkout. The exit code and the
#	output.
sub _wiki ( $checkout, @args )
{
	my $a = join q{ }, map { "'$_'" } @args;
	my $out = qx("$^X" "-I$lib" "$program" -C "$checkout" wiki $a 2>&1);

	return ( $? >> 8, $out );
}

# _write($path, $text):
#	Write one file, and make its parent directories.
sub _write ( $path, $text )
{
	make_path( $path =~ s{/[^/]+\z}{}r );
	open my $fh, '>', $path or die "write $path: $!";
	print {$fh} $text;
	close $fh;
}

# _origin($dir):
#	A bare repository with one commit on main, as the origin.
sub _origin ($dir)
{
	my $origin = "$dir/origin.git";
	_git( 'init', '--quiet', '--bare', $origin );
	_git( '-C', $origin, 'symbolic-ref', 'HEAD', 'refs/heads/main' );
	_git( 'clone', '--quiet', $origin, "$dir/seed" );
	# The test must not depend on the operator signing agent.
	_git( '-C', "$dir/seed", '-c', 'user.email=a@b', '-c',
		'user.name=a', '-c', 'commit.gpgsign=false',
		'commit', '--quiet', '--allow-empty',
		'-m', 'Initial commit' );
	_git( '-C', "$dir/seed", 'branch', '-M', 'main' );
	_git( '-C', "$dir/seed", 'push', '--quiet', 'origin', 'main' );

	return $origin;
}

# _checkout($dir, $name, $origin):
#	A checkout that holds a .toolingrc and a Wiki clone. The
#	program walks up to the nearest directory that holds a
#	.toolingrc, and the home of wiki.origin anchors the library.
sub _checkout ( $dir, $name, $origin )
{
	my $co = "$dir/$name";
	_write( "$co/.toolingrc", "wiki.origin\tfile://$origin\n" );
	_git( 'clone', '--quiet', $origin, "$co/Wiki" );
	_git( '-C', "$co/Wiki", 'config', 'user.email', 'a@b' );
	_git( '-C', "$co/Wiki", 'config', 'user.name',  'a' );

	# The test must not depend on the operator signing agent.
	_git( '-C', "$co/Wiki", 'config', 'commit.gpgsign', 'false' );

	return $co;
}

my $today = strftime( '%Y-%m-%d', gmtime );

subtest 'open is idempotent and note commits and pushes' => sub {
	my $dir    = tempdir( CLEANUP => 1 );
	my $origin = _origin($dir);
	my $co     = _checkout( $dir, 'c1', $origin );

	my ( $rc, $out ) = _wiki( $co, 'open', 'FuguSTX', 'sess-1' );
	is( $rc, 0, 'open exits zero' );
	like( $out, qr/Session-FuguSTX-\Q$today\E-1/, 'the page name' );

	( $rc, $out ) = _wiki( $co, 'open', 'FuguSTX', 'sess-1' );
	like( $out, qr/already open/, 'a second open changes nothing' );
	my @pages = glob "$co/Wiki/Session-*";
	is( scalar @pages, 1, 'one page for one session (WIKI-OPEN-1)' );

	# An empty page is not an open session (WIKI-STATUS-1).
	( $rc, $out ) = _wiki( $co, 'status' );
	like( $out, qr/open sessions: none/,
		'an empty page is not an open session' );

	_write( "$dir/obs.md", "Claim: the probe returns three zones.\n" );
	( $rc, $out ) =
	    _wiki( $co, 'note', "Session-FuguSTX-$today-1", "$dir/obs.md" );
	is( $rc, 0, 'note exits zero' );

	( $rc, $out ) = _wiki( $co, 'status' );
	like( $out, qr/1 claim\(s\), 0 admitted/, 'status counts the claim' );
	like( $out, qr/unpushed commits: 0/, 'the commit reached the origin' );

	my $log = qx(git -C "$origin" log --oneline);
	like( $log, qr/note: Session-FuguSTX/,
		'the origin holds the note commit (WIKI-CAPTURE-1)' );
};

subtest 'a rejected push rebases and retries, and never forces' => sub {
	my $dir    = tempdir( CLEANUP => 1 );
	my $origin = _origin($dir);
	my $one    = _checkout( $dir, 'c1', $origin );
	my $two    = _checkout( $dir, 'c2', $origin );

	_wiki( $one, 'open', 'FuguSTX', 'sess-1' );

	# The second checkout pushes, so the first is behind. Its next
	# push is a non-fast-forward rejection (WIKI-CAPTURE-5).
	_wiki( $two, 'open', 'FuguCTX', 'sess-2' );

	_write( "$dir/obs.md", "Claim: the lease expires at ninety minutes.\n" );
	my ( $rc, $out ) =
	    _wiki( $one, 'note', "Session-FuguSTX-$today-1", "$dir/obs.md" );
	is( $rc, 0, 'note exits zero after a rejected push' );
	like( $out, qr/rebasing and retrying/, 'the retry ran (WIKI-CAPTURE-5)' );

	# Both sessions survive, so the rebase kept the other commit.
	my $log = qx(git -C "$origin" log --oneline);
	like( $log, qr/Session-FuguCTX/, 'the other checkout keeps its page' );
	like( $log, qr/note: Session-FuguSTX/, 'the retry landed the note' );
};

subtest 'a page name stays inside the clone' => sub {
	my $dir    = tempdir( CLEANUP => 1 );
	my $origin = _origin($dir);
	my $co     = _checkout( $dir, 'c1', $origin );
	_wiki( $co, 'open', 'FuguSTX', 'sess-1' );
	_write( "$dir/obs.md", "Claim: x\n" );

	for my $bad (qw(../../../etc/passwd sub/dir ..)) {
		my ( $rc, $out ) = _wiki( $co, 'note', $bad, "$dir/obs.md" );
		isnt( $rc, 0, "note refuses $bad (WIKI-CONFINE-1)" );
	}

	# The ste-lint file walk skips this prefix, so a page that uses
	# it would never meet the prose gate (WIKI-PAGES-2).
	my ( $rc, $out ) = _wiki( $co, 'note', 'SCRATCHPAD-1', "$dir/obs.md" );
	isnt( $rc, 0, 'note refuses a SCRATCHPAD page name' );
};

subtest 'close marks the page and stays idempotent' => sub {
	my $dir    = tempdir( CLEANUP => 1 );
	my $origin = _origin($dir);
	my $co     = _checkout( $dir, 'c1', $origin );
	_wiki( $co, 'open', 'FuguSTX', 'sess-1' );
	_write( "$dir/obs.md", "Claim: x\n" );
	_wiki( $co, 'note', "Session-FuguSTX-$today-1", "$dir/obs.md" );

	my ( $rc, $out ) = _wiki( $co, 'close', 'sess-1' );
	is( $rc, 0, 'close exits zero' );

	( $rc, $out ) = _wiki( $co, 'close', 'sess-1' );
	like( $out, qr/already closed/, 'a second close changes nothing' );

	( $rc, $out ) = _wiki( $co, 'status' );
	like( $out, qr/open sessions: none/, 'a closed page is not open' );

	# A session that ran no campaign has no page, and that is
	# normal (WIKI-CAPTURE-2).
	( $rc, $out ) = _wiki( $co, 'close', 'sess-never-opened' );
	is( $rc, 0, 'close of an unknown session exits zero' );
};

subtest 'candidates reports the undelivered ones with an age' => sub {
	my $dir    = tempdir( CLEANUP => 1 );
	my $origin = _origin($dir);
	my $co     = _checkout( $dir, 'c1', $origin );

	# The third item wraps: the prose gate reflows the page, so
	# "Delivered:" lands on a continuation line.
	_write(
		"$co/Wiki/Rule-candidates.md", <<'END'
# Rule candidates

- 2026-08-01 the observer must not edit code
- 2026-08-20 the verifier reads the log. Delivered: FuguTTX AGT-OBS-3
- 2026-08-21 a page must not hold a bucket suffix, because the library
  is public. Delivered: FuguTTX AGT-SKILL-4
END
	);

	my ( $rc, $out ) = _wiki( $co, 'candidates' );
	is( $rc, 0, 'candidates exits zero' );
	like( $out, qr/the observer must not edit code/,
		'an undelivered candidate appears' );
	unlike( $out, qr/the verifier reads the log/,
		'a delivered candidate does not appear' );
	unlike( $out, qr/a page must not hold a bucket suffix/,
		'a delivered candidate that wraps does not appear' );
	like( $out, qr/^\s*\d+ d\s+2026-08-01/m, 'the age is in days' );

	# The target runs inside make check, so a checkout with no
	# library must still pass (WIKI-STATUS-3).
	my $bare = tempdir( CLEANUP => 1 );
	_write( "$bare/.toolingrc", "wiki.origin\tfile://$origin\n" );
	( $rc, $out ) = _wiki( $bare, 'candidates' );
	is( $rc, 0, 'candidates exits zero with no library clone' );
};

done_testing();
