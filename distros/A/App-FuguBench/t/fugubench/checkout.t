#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The checkout walk, the keys of .toolingrc, and the two shape
# checks.
#
# The tree below is the shape that the program meets: a workspace
# that holds the library keys, and a clone under Projects/ that holds
# its own .toolingrc without them.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";

use Fugu::File;

use App::FuguBench::Checkout;

my $url  = 'https://example.org/Wiki.git';
my $tmp  = tempdir( CLEANUP => 1 );
my $ws   = "$tmp/ws";
my $proj = "$ws/Projects/proj";
my $deep = "$proj/sub";
my $bare = "$tmp/bare";

# _write($dir, $text):
#	Make one directory, and write its .toolingrc.
sub _write ( $dir, $text = undef )
{
	Fugu::File->ensure_dir($dir) or die "cannot make $dir\n";
	return $dir unless defined $text;

	Fugu::File->write( "$dir/.toolingrc", $text )
	    or die "cannot write $dir/.toolingrc\n";

	return $dir;
}

_write( $ws, <<"WORKSPACE" );
# the workspace of the organization
wiki.origin	$url
wiki.dir	Library
# wiki.projects	Commented
other.key	ignored
WORKSPACE

_write( $proj, <<'CLONE' );
wiki.dir	Clone
worktree.base	.worktrees
CLONE

_write( $bare, "# this clone sets no key\n" );
_write($deep);

# The walk: the start, a parent, and the root of a nested clone
{
	is(
		App::FuguBench::Checkout->new( start => $ws )->root,
		$ws, 'the walk finds the .toolingrc of the start'
	);
	is(
		App::FuguBench::Checkout->new( start => $deep )->root,
		$proj, 'the walk finds the .toolingrc of a parent'
	);
	is(
		App::FuguBench::Checkout->new( start => $proj )->root,
		$proj, 'the walk stops at the root of a nested clone'
	);
	ok(
		!defined App::FuguBench::Checkout->new( start => $tmp ),
		'the walk gives undef when it reaches the filesystem root'
	);
}

# The second stop: the nearest file that holds the key, and its home
{
	my $checkout = App::FuguBench::Checkout->new( start => $proj );

	my ( $dir, $dir_home ) = $checkout->config('wiki.dir');
	is( $dir,      'Clone', 'the nearest file wins over a parent file' );
	is( $dir_home, $proj,   'the home of the key is the nearest file' );

	my ( $origin, $origin_home ) = $checkout->config('wiki.origin');
	is( $origin, $url,
		'a key absent in the nearest file comes from the parent' );
	is( $origin_home, $ws, 'the home of that key is the parent file' );
}

# The defaults of the table, and the key with none
{
	my $checkout = App::FuguBench::Checkout->new( start => $bare );

	my %default = (
		'wiki.dir'      => 'Wiki',
		'wiki.project'  => 'bare',
		'wiki.projects' => 'Projects',
		'worktree.base' => '.claude/worktrees',
	);
	for my $key ( sort keys %default ) {
		my ( $value, $home ) = $checkout->config($key);
		is( $value, $default{$key}, "$key takes its default" );
		is( $home, $bare, "$key takes the root as its home" );
	}

	my @origin = $checkout->config('wiki.origin');
	is( scalar @origin, 0, 'wiki.origin has no default' );
}

# A comment line and an unknown key change nothing
{
	my $checkout = App::FuguBench::Checkout->new( start => $ws );

	my ($projects) = $checkout->config('wiki.projects');
	is( $projects, 'Projects', 'a comment line sets no key' );

	my @other = $checkout->config('other.key');
	is( scalar @other, 0, 'a key of another tool reads as absent' );
}

# The two shape checks
{
	my $checkout = App::FuguBench::Checkout->new( start => $ws );

	is( $checkout->dir_value('Wiki/pages'),
		'Wiki/pages', 'a relative path passes the directory check' );

	ok( !defined $checkout->dir_value('../Wiki'),
		'a parent segment fails the directory check' );
	like( $checkout->error, qr{\Q../Wiki\E},
		'the reason names the value' );

	ok( !defined $checkout->dir_value('/Wiki'),
		'an absolute path fails the directory check' );
	like( $checkout->error, qr{absolute}, 'the reason names the shape' );

	is( $checkout->url_value($url),
		$url, 'a URL with a scheme passes the URL check' );

	ok( !defined $checkout->url_value('example.org/Wiki.git'),
		'a URL without a scheme fails the URL check' );
	like( $checkout->error, qr{scheme}, 'the reason names the scheme' );
}

done_testing();
