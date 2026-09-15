#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The port of the Workspace test t/ci/traces.t (CLI-CONFORMANCE-1).
# It tests the trace name, the directory match, the session rows, and
# the columns of the traces verb (TRACE-NAME, TRACE-COLUMNS,
# TRACE-USAGE, TRACE-PANEL, TRACE-SUB).
#
# The test makes a fixture checkout and a fixture trace root in one
# temp tree, and it runs the verb with -C, --root and --name. The
# trace root holds the checkout, one worktree of it, one project
# clone in it, and one sibling checkout that must stay out. The
# checkout holds the main session, one session with no request, two
# sessions that hold a scratch path, three sessions that hold an edit
# path of one boundary, and one session that launches a catch-all
# agent type.
#
# The last test runs the verb with --root alone, against a -C
# directory that holds the marker two times, which reaches the name
# derivation.
#
# The checkout of the fixture is the -C directory, so no assertion
# holds an operator path. A boundary session builds its path from that
# directory, because the verb takes the edit boundary from the
# checkout. No test reads the operator home, and no test writes
# outside its temp tree.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use Cwd        qw(abs_path);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use JSON::PP   ();

my $lib     = "$RealBin/../../lib";
my $program = "$RealBin/../../bin/fugubench";
my $json    = JSON::PP->new->canonical;

# _write($path, $text):
#	Write one file, and make its parent directories.
sub _write ( $path, $text )
{
	make_path( $path =~ s{/[^/]+\z}{}r );
	open my $fh, '>', $path or die "write $path: $!";
	print {$fh} $text;
	close $fh;
}

# _tool($name, %input):
#	One tool_use content block.
sub _tool ( $name, %input )
{
	return {
		type  => 'tool_use',
		id    => "toolu_$name",
		name  => $name,
		input => {%input},
	};
}

# _record($req, $context, $out, @blocks):
#	One assistant record. $context holds the three input counts,
#	which the verb adds together.
sub _record ( $req, $context, $out, @blocks )
{
	return $json->encode( {
			type      => 'assistant',
			timestamp => '2026-09-09T10:00:00.000Z',
			requestId => $req,
			message   => {
				role  => 'assistant',
				usage => {
					input_tokens => $context->[0],
					cache_creation_input_tokens =>
					    $context->[1],
					cache_read_input_tokens =>
					    $context->[2],
					output_tokens => $out,
				},
				content => [@blocks],
			},
		} ) . "\n";
}

# _meta($path, $tool):
#	The meta file of one sub-agent trace. It carries the
#	identifier of the tool_use block that launched the sub-agent.
sub _meta ( $path, $tool )
{
	_write( $path, $json->encode( { toolUseId => $tool } ) . "\n" );
}

# _session($id):
#	A one-request trace, as the smallest session that gets a row.
sub _session ($id)
{
	return _record( "req_$id", [ 1, 2, 3 ],
		4, { type => 'text', text => 'x' } );
}

# _traces($checkout, $root, $name):
#	Run the verb against the fixture root, with the fixture
#	checkout as the -C directory. The exit code and the output.
sub _traces ( $checkout, $root, $name )
{
	my $cmd = qq("$^X" "-I$lib" "$program" -C "$checkout" traces);
	my $out = qx($cmd --root "$root" --name "$name" 2>&1);

	return ( $? >> 8, $out );
}

my $tree = tempdir( CLEANUP => 1 );
my $cwd  = "$tree/checkout";
my $root = "$tree/traces";
my $main = "$root/fixture";
my $id   = '11111111-1111-1111-1111-111111111111';

# The checkout walk of the program stops at a .toolingrc, so no run
# of the test reads the operator home (CLI-CHECKOUT-2).
_write( "$cwd/.toolingrc", q{} );

# The path of the fixture checkout. The edits column takes a file
# inside this path only, so each boundary case builds its path from
# it.
my $checkout = abs_path($cwd);

# The fixer of round 1. Its description holds the word panel, and its
# type names another role, so neither the panel count nor rev-peak
# takes it. _tool derives the identifier from the tool name, so the
# fixer needs an identifier of its own, apart from the panel launch.
my $fixer = _tool(
	'Agent',
	subagent_type => 'fixer',
	description   => 'Panel round 1 fixer'
);
$fixer->{id} = 'toolu_fixer';

# The main session: one leading record that carries the start time,
# then three requests. Request A writes three records, because one
# record carries one content block. Its first two records carry a
# partial count, and its last record carries the full count, which
# holds the peak of the file. Its Edit comes before the panel launch,
# so no count takes it. Request B holds two edits after the launch,
# and the launch of the fixer. Request C writes two files under
# scratch/, one path relative and one path absolute inside the
# checkout, which no count takes.
_write(
	"$main/$id.jsonl",
	$json->encode(
		{ type => 'user', timestamp => '2026-09-09T09:59:00.000Z' } )
	    . "\n"
	    . _record( 'req_a', [ 1, 20, 300 ],
		5, { type => 'text', text => 'x' } )
	    . _record( 'req_a', [ 2, 30, 400 ], 10, _tool('Edit') )
	    . _record( 'req_a', [ 30, 300, 3000 ],
		70, _tool( 'Agent', description => 'Panel review member 1' ) )
	    . _record(
		'req_b',        [ 20, 200, 2000 ],
		60,             _tool('Edit'),
		_tool('Write'), $fixer
	    )
	    . _record(
		'req_c',
		[ 5, 50, 500 ],
		10,
		_tool( 'Write', file_path => 'scratch/review/ledger.md' ),
		_tool(
			'NotebookEdit',
			notebook_path => "$checkout/scratch/note.ipynb"
		) ) );

# The sub-agents of the session. Agent A1 is the panel member: its
# meta file names the launch of request A, and _tool gives that block
# the identifier toolu_Agent. A1 holds two requests, one of them over
# two records, so its peak is smaller than its input total. Agent A2
# holds the larger peak, and its meta file names another launch, so
# rev-peak must leave A2 out.
_write(
	"$main/$id/subagents/agent-a1.jsonl",
	_record( 'req_s1', [ 7, 70, 700 ],
		5, { type => 'text', text => 'x' } )
	    . _record( 'req_s1', [ 7, 70, 700 ], 5, _tool('Read') )
	    . _record( 'req_s2', [ 8, 80, 800 ], 6, _tool('Read') )
);
_meta( "$main/$id/subagents/agent-a1.meta.json", 'toolu_Agent' );

_write( "$main/$id/subagents/agent-a2.jsonl",
	_record( 'req_t', [ 90, 900, 9000 ], 7, _tool('Read') ) );
_meta( "$main/$id/subagents/agent-a2.meta.json", 'toolu_other' );

# The trace of the fixer. Its peak is larger than the peak of A1, and
# its meta file names the launch of the fixer, so rev-peak must leave
# it out. The sub-agent totals hold it, as they hold every sub-agent.
_write( "$main/$id/subagents/agent-f1.jsonl",
	_record( 'req_f', [ 10, 100, 1000 ], 8, _tool('Read') ) );
_meta( "$main/$id/subagents/agent-f1.meta.json", 'toolu_fixer' );

# A session that holds records but no assistant record never reached
# the model, so it gets no row (TRACE-COLUMNS-1).
my $quiet = $json->encode(
	{ type => 'user', timestamp => '2026-09-09T10:01:00.000Z' } );
_write( "$main/77777777-7777.jsonl", "$quiet\n$quiet\n" );

# Two more sessions of the checkout, each one with a panel launch and
# then the writes of a scratch path. Session 8 holds the two files that
# .gitignore covers, one path relative and one path absolute inside
# the checkout, and the edits column must take neither one.
# Session 9 holds three near misses, and it must take every one: the
# name must start a path segment, and a scratchpad must end the path
# (TRACE-PANEL-3).
_write(
	"$main/88888888-8888.jsonl",
	_record( 'req_p1', [ 1, 2, 3 ], 4,
		_tool( 'Agent', description => 'Panel review member 1' ) )
	    . _record( 'req_p2', [ 1, 2, 3 ], 4,
		_tool( 'Write', file_path => 'SCRATCHPAD-1.md' ),
		_tool( 'Write', file_path => "$checkout/SCRATCHPAD-2.md" ) )
);
_write(
	"$main/99999999-9999.jsonl",
	_record( 'req_n1', [ 1, 2, 3 ], 4,
		_tool( 'Agent', description => 'Panel review member 1' ) )
	    . _record( 'req_n2', [ 1, 2, 3 ], 4,
		_tool( 'Write', file_path => 'myscratch/x.md' ),
		_tool( 'Write', file_path => 'NOTSCRATCHPAD.md' ),
		_tool( 'Write', file_path => 'SCRATCHPAD-3.md.bak' ) )
);

# Three sessions of the checkout boundary, each one with a panel
# launch and then one write. The edits column counts a repository file
# of the measured checkout only (TRACE-PANEL-3). Session B writes a
# file inside the checkout, which is one. Session C writes the memory
# file of a session, under a .claude/projects/ path of the operator
# HOME in shape, which is none. Session D writes a file of a sibling
# checkout, which is none, as the directory match rejects the sibling.
_write(
	"$main/bbbbbbbb-bbbb.jsonl",
	_record( 'req_b1', [ 1, 2, 3 ], 4,
		_tool( 'Agent', description => 'Panel review member 1' ) )
	    . _record( 'req_b2', [ 1, 2, 3 ], 4,
		_tool( 'Write', file_path => "$checkout/spec/workspace.md" ) )
);
_write(
	"$main/cccccccc-cccc.jsonl",
	_record( 'req_c1', [ 1, 2, 3 ], 4,
		_tool( 'Agent', description => 'Panel review member 1' ) )
	    . _record(
		'req_c2',
		[ 1, 2, 3 ],
		4,
		_tool(
			'Write',
			file_path => "$root/.claude/projects"
			    . '/-x-Work-FuguBSD/memory/session-rules.md'
		)
	    )
);
_write(
	"$main/dddddddd-dddd.jsonl",
	_record( 'req_d1', [ 1, 2, 3 ], 4,
		_tool( 'Agent', description => 'Panel review member 1' ) )
	    . _record( 'req_d2', [ 1, 2, 3 ], 4,
		_tool( 'Write',
			file_path => "$checkout-backup/spec/workspace.md" ) )
);

# One session of the panel of an early campaign, before the org pack
# shipped a reviewer agent. The launch carries a catch-all type, which
# names no role, so the description decides and the launch is a round.
_write(
	"$main/aaaaaaaa-aaaa.jsonl",
	_record( 'req_c1', [ 1, 2, 3 ], 4,
		_tool(
			'Agent',
			subagent_type => 'general-purpose',
			description   => 'Panel review member 1'
		) )
);

# One worktree of the checkout, one project clone in it, and one
# sibling checkout that the match must reject.
_write( "$root/fixture--claude-worktrees-w1/22222222-2222.jsonl",
	_session('w') );
_write( "$root/fixture-backup/33333333-3333.jsonl",           _session('b') );
_write( "$root/fixture-Projects-Tooling/44444444-4444.jsonl", _session('p') );

my ( $code, $out ) = _traces( $cwd, $root, 'fixture' );
is( $code, 0, 'traces exits zero' );

my ($row) = grep { /^11111111\b/ } split /\n/, $out;
ok( $row, 'the main session gets a row' ) or diag $out;
my @field = split q{ }, $row // q{};

is( $field[1], '2026-09-09T09:59', 'the start time is the first record' );
is( $field[2], 3,                  'the record count is a request count' );
is( $field[3], 3330,    'the peak reads the last record of a request' );
is( $field[4], 140,     'the output reads the last record of a request' );
is( $field[5], 1,       'a panel launch is a round, a fixer is not' );
is( $field[6], 2,
	'an edit before the launch, and a write under scratch/, do not count' );
is( $field[7], 12765, 'the sub-agent input counts one time' );
is( $field[8], 26,    'the sub-agent output counts one time' );
is( $field[9], 888,   'rev-peak takes the panel member, not the fixer' );

like( $out, qr/^22222222/m, 'a worktree of the checkout joins' );
like( $out, qr/^44444444/m, 'a project clone joins' );
unlike( $out, qr/^33333333/m, 'a sibling checkout stays out' );

unlike( $out, qr/^77777777/m, 'a session with no request gets no row' );

my @pad  = split q{ }, ( grep { /^88888888\b/ } split /\n/, $out )[0] // q{};
my @near = split q{ }, ( grep { /^99999999\b/ } split /\n/, $out )[0] // q{};
is( $pad[6], 0, 'a SCRATCHPAD*.md write is not an edit' ) or diag $out;
is( $near[6], 3, 'a near miss of the scratch pattern is an edit' )
    or diag $out;

my @in   = split q{ }, ( grep { /^bbbbbbbb\b/ } split /\n/, $out )[0] // q{};
my @home = split q{ }, ( grep { /^cccccccc\b/ } split /\n/, $out )[0] // q{};
my @sib  = split q{ }, ( grep { /^dddddddd\b/ } split /\n/, $out )[0] // q{};
is( $in[6], 1, 'a write inside the checkout is an edit' ) or diag $out;
is( $home[6], 0, 'a write to the operator HOME is not an edit' )
    or diag $out;
is( $sib[6], 0, 'a write to a sibling checkout is not an edit' )
    or diag $out;

my @cat = split q{ }, ( grep { /^aaaaaaaa\b/ } split /\n/, $out )[0] // q{};
is( $cat[5], 1, 'a catch-all agent type falls back to the description' )
    or diag $out;

my ( $none_code, $none_out ) = _traces( $cwd, $root, 'absent' );
is( $none_code, 0, 'a name with no trace directory exits zero' );
like( $none_out, qr/^no session of absent$/m, 'and it reports none' );

# Without --name, the verb derives the name from the checkout root,
# cut at the last .claude/worktrees/ marker (TRACE-NAME-1). The -C
# directory sits under two markers, and it holds a .toolingrc of its
# own, so it is the checkout root. The last marker names the inner
# checkout, and the first one names the outer checkout, whose trace
# directory must stay out.
my $nest = tempdir( CLEANUP => 1 );
my $deep = "$nest/.claude/worktrees/a/.claude/worktrees/b";
_write( "$deep/.toolingrc", q{} );

my $outer = abs_path($nest)                       =~ s/[^A-Za-z0-9-]/-/gr;
my $inner = abs_path("$nest/.claude/worktrees/a") =~ s/[^A-Za-z0-9-]/-/gr;
_write( "$nest/traces/$inner/55555555-5555.jsonl", _session('n') );
_write( "$nest/traces/$outer/66666666-6666.jsonl", _session('o') );

my $deep_cmd = qq("$^X" "-I$lib" "$program" -C "$deep" traces);
my $deep_out = qx($deep_cmd --root "$nest/traces" 2>&1);
is( $? >> 8, 0, 'the derived name exits zero' );
like( $deep_out, qr/^55555555/m, 'the derivation cuts at the last marker' )
    or diag $deep_out;
unlike( $deep_out, qr/^66666666/m, 'and the outer checkout stays out' );

done_testing();
