#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The settings writer of the hook verb (HOOK-INSTALL).
#
# Each case runs bin/fugubench as a child with -Ilib, and it writes
# inside its temporary tree only. The child reads that tree as its
# home, so no case reads the operator home, and no case reaches the
# network.
#
# The bytes of the file are a part of the contract, because prettier
# formats the settings file of a checkout. So the cases read the
# indent, the colon, and the final newline of the written file.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use JSON::PP   ();
use lib "$RealBin/../../lib";

use Fugu::File;
use Fugu::Process;

my $root    = "$RealBin/../..";
my $program = "$root/bin/fugubench";

# The command of each entry, without the event (HOOK-INSTALL-2).
my $SHIM = '"$CLAUDE_PROJECT_DIR/scripts/fugubench" hook ';

# The timeout of each event, in seconds (HOOK-INSTALL-3).
my %TIMEOUT = (
	SessionEnd     => 30,
	SessionStart   => 60,
	WorktreeCreate => 120,
	WorktreeRemove => 60,
);

# The decoder of one written file.
my $JSON = JSON::PP->new->utf8;

# _env($home):
#	The environment of one child. The child reads the temporary
#	tree as its home, so it reads no file of the operator home.
#	The child gets this environment in place of the environment of
#	the test, so this environment must carry PERL5LIB. CI installs
#	Fugu into a local library, and names that library in PERL5LIB.
sub _env ($home)
{
	my %env = ( PATH => $ENV{PATH}, HOME => $home );

	# An undefined value is an error, and a host that installs
	# Fugu in the default \@INC sets no PERL5LIB.
	$env{PERL5LIB} = $ENV{PERL5LIB} if defined $ENV{PERL5LIB};

	return \%env;
}

# _write($path, $text):
#	Write one file, and make its parent directories.
sub _write ( $path, $text )
{
	make_path( $path =~ s{/[^/]+\z}{}r );
	Fugu::File->write( $path, $text ) or die "write $path";

	return;
}

# _checkout($tree):
#	A checkout of the tree, and the path of its settings file, in
#	that order. The walk of the program stops at the .toolingrc.
sub _checkout ($tree)
{
	my $dir = "$tree/co";
	_write( "$dir/.toolingrc", "wiki.project\tBench\n" );

	return ( $dir, "$dir/.claude/settings.json" );
}

# _install($tree, $dir, @argv):
#	Run hook install on one checkout, and return the result of
#	Fugu::Process->run.
#
#	The payload of the standard input is no JSON. The subcommand
#	answers no event, so it must read no payload, and a warning
#	about the parse would name a read.
sub _install ( $tree, $dir, @argv )
{
	my $result = Fugu::Process->run(
		cmd => [
			$^X, "-I$root/lib", $program, '-C', $dir, 'hook',
			@argv ? @argv : 'install'
		],
		env   => _env($tree),
		stdin => 'not json at all',
	);
	die "cannot run $program: $result->{error}\n"
	    if defined $result->{error};

	return $result;
}

# _decode($path):
#	The settings of one written file, as a hash reference.
sub _decode ($path)
{
	my $text = Fugu::File->read($path);
	die "read $path" unless defined $text;

	return $JSON->decode($text);
}

subtest 'an absent file gets the four entries and the base reference' => sub {
	my $tree = tempdir( CLEANUP => 1 );
	my ( $dir, $path ) = _checkout($tree);

	my $r = _install( $tree, $dir );
	is( $r->{exit_code}, 0, 'the subcommand exits zero' )
	    or diag $r->{stderr};
	is( $r->{stdout}, q{}, 'the subcommand writes no result line' );
	unlike( $r->{stderr}, qr/does not parse/,
		'the subcommand reads no payload' );

	my $settings = _decode($path);
	is( $settings->{worktree}{baseRef},
		'head', 'the base reference is the local head' );
	is_deeply(
		[ sort keys %{ $settings->{hooks} } ],
		[ sort keys %TIMEOUT ],
		'the file holds the four events'
	);

	for my $event ( sort keys %TIMEOUT ) {
		my $list = $settings->{hooks}{$event};
		is( scalar @$list, 1, "$event holds one group" );
		is_deeply( [ keys %{ $list->[0] } ],
			['hooks'], "$event holds a matcher-less group" );
		is( scalar @{ $list->[0]{hooks} }, 1, "$event holds one entry" );
		is_deeply(
			$list->[0]{hooks}[0],
			{
				type    => 'command',
				command => "$SHIM$event",
				timeout => $TIMEOUT{$event},
			},
			"$event runs the shim with its timeout"
		);
	}

	# The entry runs the shim alone, and it needs no jq (D-07).
	my $text = Fugu::File->read($path);
	unlike( $text, qr/\bjq\b/, 'no entry needs jq' );

	# The timeout is a number, and a quoted value would reach the
	# harness as a string.
	like( $text, qr/^\s+"timeout": 120,$/m, 'the timeout is a number' );
	unlike( $text, qr/statusMessage/, 'an entry carries three keys' );
};

subtest 'the writer keeps every key that it does not own' => sub {
	my $tree = tempdir( CLEANUP => 1 );
	my ( $dir, $path ) = _checkout($tree);

	# A key in front of hooks, a key after it, a key beside
	# baseRef, and an event outside the four.
	_write( $path, <<'JSON' );
{
  "autoMode": { "environment": ["a"] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "true" }] }
    ],
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "old", "timeout": 5 }] }
    ]
  },
  "permissions": { "allow": ["Bash(git commit:*)"] },
  "worktree": { "baseRef": "origin/main", "other": 1 }
}
JSON

	my $r = _install( $tree, $dir );
	is( $r->{exit_code}, 0, 'the subcommand exits zero' )
	    or diag $r->{stderr};

	my $settings = _decode($path);
	is_deeply( $settings->{autoMode}, { environment => ['a'] },
		'a key in front of hooks stays' );
	is_deeply(
		$settings->{permissions},
		{ allow => ['Bash(git commit:*)'] },
		'a key after hooks stays'
	);
	is( $settings->{worktree}{other}, 1, 'a key beside baseRef stays' );
	is( $settings->{worktree}{baseRef},
		'head', 'the base reference takes the new value' );

	# The writer owns the four events, and no other event.
	is( $settings->{hooks}{PreToolUse}[0]{matcher},
		'Bash', 'an event outside the four stays' );
	my $entry = $settings->{hooks}{SessionStart}[0]{hooks}[0];
	is( $entry->{command}, "${SHIM}SessionStart",
		'an event of the four takes the shim' );
	is( $entry->{timeout}, 60, 'an event of the four takes its timeout' );

	# The keys reach the file in sorted order, at every level.
	my $text = Fugu::File->read($path);
	is_deeply(
		[ $text =~ /^  "(\w+)":/mg ],
		[qw(autoMode hooks permissions worktree)],
		'the top-level keys are sorted'
	);
	my @order = qw(PreToolUse SessionEnd SessionStart WorktreeCreate
	    WorktreeRemove);
	my @at = map { index $text, qq{\n    "$_":} } @order;
	is( scalar( grep { $_ < 0 } @at ),
		0, 'the file holds each event key at one level' );
	is_deeply( \@at, [ sort { $a <=> $b } @at ],
		'the event keys are sorted' );
};

subtest 'the second run leaves the bytes equal' => sub {
	my $tree = tempdir( CLEANUP => 1 );
	my ( $dir, $path ) = _checkout($tree);

	_install( $tree, $dir );
	my $first = Fugu::File->read($path);
	my $r     = _install( $tree, $dir );
	is( $r->{exit_code}, 0, 'the second run exits zero' )
	    or diag $r->{stderr};
	is( Fugu::File->read($path), $first, 'the second run causes no change' );

	# The bytes are the shape that prettier writes.
	like(
		$first,
		qr{\A\{\n  "hooks": \{\n    "SessionEnd": \[\n      \{\n},
		'each level indents two spaces more than its parent'
	);
	unlike( $first, qr/^\t/m, 'no line starts with a tab' );
	unlike( $first, qr/ :/,    'no space comes in front of a colon' );
	unlike( $first, qr/[ \t]\n/, 'no line ends with a space' );
	like( $first, qr/\}\n\z/, 'the file ends with one newline' );

	my @odd = grep { /\A( +)/ && length($1) % 2 } split /\n/, $first;
	is( scalar @odd, 0, 'every indent is a multiple of two spaces' );
};

subtest 'a file that does not parse is a failure' => sub {
	my $tree = tempdir( CLEANUP => 1 );
	my ( $dir, $path ) = _checkout($tree);

	my $broken = qq[{ "hooks": }\n];
	_write( $path, $broken );
	my $r = _install( $tree, $dir );
	is( $r->{exit_code}, 1, 'a file that does not parse exits 1' );
	is( Fugu::File->read($path), $broken, 'that file stays as it was' );
	like( $r->{stderr}, qr/\Q$path\E/, 'the report names the file' );

	# An empty file holds no JSON object either.
	_write( $path, q{} );
	is( _install( $tree, $dir )->{exit_code}, 1, 'an empty file exits 1' );
	is( Fugu::File->read($path), q{}, 'the empty file stays as it was' );

	# A hooks key of another kind belongs to no file that the
	# subcommand can extend.
	my $wrong = qq[{ "hooks": [] }\n];
	_write( $path, $wrong );
	$r = _install( $tree, $dir );
	is( $r->{exit_code}, 1, 'a hooks key that is no object exits 1' );
	is( Fugu::File->read($path), $wrong, 'that file stays as it was' );
	like( $r->{stderr}, qr/hooks key holds no object/,
		'the report names the key' );
};

subtest 'the subcommand takes the checkout and no argument' => sub {
	my $tree = tempdir( CLEANUP => 1 );
	my ( $dir, $path ) = _checkout($tree);

	# A start with no .toolingrc above it is a configuration error
	# (CLI-CHECKOUT-3).
	my $outside = "$tree/outside";
	make_path($outside);
	my $r = _install( $tree, $outside );
	is( $r->{exit_code}, 3, 'a start with no checkout exits 3' );
	ok( !-e "$outside/.claude", 'that start writes no file' );

	# An argument after the word is a usage error.
	$r = _install( $tree, $dir, 'install', 'again' );
	is( $r->{exit_code}, 2, 'an argument after install exits 2' );
	ok( !-e $path, 'the usage error writes no file' );

	$r = _install( $tree, $dir, '--help' );
	is( $r->{exit_code}, 0, 'the help of the verb exits 0' );
	like( $r->{stdout}, qr/install/, 'the usage names the subcommand' );
};

done_testing();
