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

package App::FuguBench::Traces;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Cwd            ();
use File::Basename qw(basename);
use File::Spec     ();
use JSON::PP       ();

use Fugu::CLI qw(EXIT_SUCCESS EXIT_ERROR);
use Fugu::Sandbox;

# App::FuguBench::Traces - the traces verb.
#
# The verb measures the Claude Code sessions of one checkout. Claude
# Code keeps one trace directory for each working directory, under
# ~/.claude/projects/. The name of the directory is the absolute path
# of the working directory, and the harness replaces each character
# outside a letter, a digit and a hyphen with a hyphen.
#
# The verb derives that name from the checkout root, it matches the
# trace directories of the checkout, and it prints one line for each
# session in them that holds a request.
#
# The derivation cuts the root at the last .claude/worktrees/ marker,
# because a nested checkout holds the marker more than one time
# (TRACE-NAME-1). Three name forms belong to one checkout: the
# checkout itself, a worktree of it, and a project clone in either of
# them. The match takes the exact forms, so a sibling checkout, such
# as a backup, stays out (TRACE-NAME-2).
#
# The option --root names a trace root in place of the one under the
# home of the operator. The option --name replaces the derived name
# (TRACE-NAME-3).
#
# The columns are:
#
#     session  the first eight characters of the session identifier
#     start    the time of the first record of the session, in UTC
#     reqs     the requests of the main session
#     peak     the largest context of one request: the fresh input
#              tokens, the cache writes and the cache reads
#     out      the output tokens of the main session, thinking
#              included
#     panel    the rounds of the review panel
#     edits    the file edits of the main session after the first
#              panel launch: a file inside the checkout, outside
#              scratch/ and SCRATCHPAD*.md
#     sub-in   the input tokens of every sub-agent of the session
#     sub-out  the output tokens of every sub-agent
#     rev-peak the largest peak context of one panel reviewer
#
# One request writes one record for each content block, and each
# record carries the usage of the whole request. An early record can
# carry a partial count, so the verb takes the usage of the last
# record of a request (TRACE-USAGE-1). A tool_use block appears in one
# record only, so each block counts one time.
#
# The sub-in and sub-out columns hold every sub-agent together, so
# neither one measures one reviewer (TRACE-SUB-1). A panel launch is a
# tool_use block with an identifier, and each sub-agent trace has a
# sibling <agent>.meta.json that carries the identifier of its launch.
# The rev-peak column maps the launch identifiers of the panel to
# their traces, and it reports the largest peak of them (TRACE-SUB-2).
#
# This verb and the hook verb hold the Claude Code assumptions of the
# program, and every other verb is agent-agnostic (D-10).

# The marker of a worktree path, and the trace root of the harness
# under the home of the operator.
use constant MARKER   => '/.claude/worktrees/';
use constant PROJECTS => '.claude/projects';

# The format of one line. The columns are session, start, reqs, peak,
# out, panel, edits, sub-in, sub-out and rev-peak (TRACE-COLUMNS-2).
# The format lives in a variable: on the floor perl, printf reads a
# bareword in that place as a filehandle, and the pragma block of the
# file forbids one.
my $ROW = "%-8s  %-16s  %6s  %8s  %8s  %6s  %6s  %10s  %10s  %8s\n";

# The tools that change a file. The panel reviews a commit, so an edit
# of the main session after the first launch of a round is an edit
# that no reviewer saw (TRACE-PANEL-3).
my %EDIT = map { $_ => 1 } qw(Edit Write MultiEdit NotebookEdit);

# The scratch space of the repository. The panel writes its ledger
# under scratch/, an audit writes its findings to a SCRATCHPAD-<N>.md
# file, and .gitignore holds both. The name must start a path segment
# and the scratchpad must end the path, so myscratch/x.md,
# NOTSCRATCHPAD.md and SCRATCHPAD-3.md.bak stay edits.
my $SCRATCH = qr{(?:\A|/)(?:scratch/|SCRATCHPAD[^/]*\.md\z)};

# The tools that launch a sub-agent, and the agent types that name no
# role. A launch of a catch-all type carries the role of the agent in
# its description only (TRACE-PANEL-1).
my %LAUNCH   = map { $_ => 1 } qw(Agent Task);
my %CATCHALL = map { $_ => 1 } qw(general-purpose claude);

# The decoder of one record. It takes the bytes of a line, and it
# decodes the UTF-8 itself. An :encoding layer loads the
# PerlIO::encoding extension at the first open, and `stdio rpath`
# gives no promise for the load of a shared object.
my $JSON = JSON::PP->new->utf8;

# App::FuguBench::Traces->command($verb):
#	The entry of the Fugu::CLI table. The module holds one verb,
#	so it ignores the name.
sub command ( $, $ )
{
	return {
		summary => 'measure the sessions of the checkout',
		usage   => '[--root <dir>] [--name <name>]',
		options => {
			'root=s' => 'the trace root, in place of the one'
			    . ' under the home',
			'name=s' => 'the checkout name, in place of the'
			    . ' derived one',
		},
		run => sub ( $app, @argv ) { return _run( $app, @argv ) },
	};
}

# App::FuguBench::Traces->unveil_paths($app):
#	The unveil list of the sandbox row (CLI-SANDBOX-2). The verb
#	opens the trace files itself and runs no child, so its row
#	names each path that the verb reads after the entry, and it
#	names nothing else.
#
#	perl loads a module on an error path, so the list holds the
#	library directories of the interpreter. Each one is optional,
#	because the build of a perl records a directory that the host
#	can omit.
#
#	The trace root is optional too. The verb reports an absent
#	root itself, with the path in the message, and a required
#	entry would die in front of that report.
#
#	The verb resolves the real path of the checkout root after the
#	entry, so the row names the root. The unveil list names that
#	root, so the walk to the .toolingrc runs here, in front of the
#	entry. Every run reads the checkout,
#	because the edit boundary comes from it and --name leaves that
#	boundary alone (TRACE-PANEL-3).
sub unveil_paths ( $, $app )
{
	my @paths =
	    map { [ $_, 'r', { optional => 1 } ] } Fugu::Sandbox->perl_lib_dirs;

	my $checkout = $app->checkout;
	push @paths, [ $checkout->root, 'r' ] if $checkout;

	push @paths, [ _trace_root($app), 'r', { optional => 1 } ];

	return @paths;
}

# _run($app, @argv):
#	The body of the verb. It takes no argument, and an argument
#	is a usage error.
#
#	The rows sort by start time, under one header. A session with
#	no request gets no row, and a name that matches no directory
#	gives the one line that says so (TRACE-COLUMNS-1).
sub _run ( $app, @argv )
{
	return $app->cli->command_usage_error('traces') if @argv;

	my $log = $app->cli->log;

	# The checkout comes first. A start under no .toolingrc is a
	# configuration error (CLI-CHECKOUT-3), and the trace root
	# under the home of the operator is absent on a host that runs
	# no Claude Code. The other order hides the configuration
	# error behind a failure there.
	my ( $code, $checkout ) = _checkout_path($app);
	return $code if $code != EXIT_SUCCESS;

	my $root = _trace_root($app);
	unless ( -d $root ) {
		$log->error( 'no such trace root: %s', $root );
		return EXIT_ERROR;
	}

	my $name = $app->cli->option('name')
	    // ( $checkout =~ s/[^A-Za-z0-9-]/-/gr );

	opendir my $dh, $root or do {
		$log->error( 'cannot read %s: %s', $root, $! );
		return EXIT_ERROR;
	};
	my $match = _match($name);
	my @dirs  = sort grep { /$match/ && -d "$root/$_" } readdir $dh;
	closedir $dh;

	my @rows;
	push @rows, _sessions( "$root/$_", $checkout ) for @dirs;
	unless (@rows) {
		say "no session of $name";
		return EXIT_SUCCESS;
	}

	printf $ROW, qw(session start reqs peak out panel edits sub-in
	    sub-out rev-peak);
	for my $row ( sort { $a->{start} cmp $b->{start} } @rows ) {
		printf $ROW, substr( $row->{id}, 0, 8 ),
		    substr( $row->{start}, 0, 16 ), $row->{reqs},
		    $row->{peak}, $row->{out}, $row->{panel}, $row->{edits},
		    $row->{sub_in}, $row->{sub_out}, $row->{rev_peak};
	}

	return EXIT_SUCCESS;
}

# _trace_root($app):
#	The trace root of the run: the --root value, or the directory
#	of the harness under the home of the operator.
sub _trace_root ($app)
{
	my $root = $app->cli->option('root');
	return $root if defined $root;

	return File::Spec->catdir( $ENV{HOME} // q{.}, PROJECTS );
}

# _checkout_path($app):
#	The exit code and the path of the checkout, in that order. The
#	code is EXIT_SUCCESS when the path holds a value, and the
#	method reports every failure itself.
#
#	The path is the real path of the checkout root, cut at the
#	last marker (TRACE-NAME-1). The trace name comes from it, with
#	each character outside a letter, a digit and a hyphen replaced
#	by a hyphen. The edits column takes a file inside the path
#	only, and --name leaves that boundary alone (TRACE-PANEL-3),
#	so every run reads the checkout.
#
#	A worktree holds a .toolingrc of its own, so the walk stops in
#	the worktree and the cut reaches the checkout. CLI-CHECKOUT-4
#	names this cut as the one exception.
sub _checkout_path ($app)
{
	my $checkout = $app->checkout
	    or return Fugu::CLI::EXIT_CONFIG_ERROR();

	my $path = Cwd::abs_path( $checkout->root );
	unless ( defined $path ) {
		$app->cli->log->error( 'cannot resolve %s', $checkout->root );
		return EXIT_ERROR;
	}

	my $at = rindex $path, MARKER;
	$path = substr $path, 0, $at if $at >= 0;

	return ( EXIT_SUCCESS, $path );
}

# _match($name):
#	The pattern of the trace directories of one checkout: the
#	checkout itself, each worktree of it, and each project clone
#	in either of them (TRACE-NAME-2). The pattern takes the whole
#	name, so a sibling of the checkout stays out.
sub _match ($name)
{
	my $token = qr{[A-Za-z0-9-]+};

	return qr{
		\A\Q$name\E
		(?:--claude-worktrees-$token)?
		(?:-Projects-$token)?
		\z
	}x;
}

# _sessions($dir, $checkout):
#	One row for each session of one trace directory. A session
#	with no request never reached the model, so it gets no row
#	(TRACE-COLUMNS-1).
#
#	A sub-agent of a workflow gets a directory of its own. The
#	sub-agent columns hold every sub-agent of the session
#	(TRACE-SUB-1). The launch identifiers of the panel select the
#	reviewers among them, so rev-peak takes the largest peak of
#	one reviewer (TRACE-SUB-2).
sub _sessions ( $dir, $checkout )
{
	my @rows;
	for my $path ( _jsonl($dir) ) {
		my $row = _tally( $path, $checkout );
		next unless $row->{reqs};

		my $id  = basename($path) =~ s/\.jsonl\z//r;
		my $sub = "$dir/$id/subagents";
		my ( $in, $out, $rev ) = ( 0, 0, 0 );
		for my $file ( _jsonl($sub),
			map { _jsonl($_) } _subdirs("$sub/workflows") )
		{
			my $agent = _tally( $file, $checkout );
			$in  += $agent->{in};
			$out += $agent->{out};
			$rev = $agent->{peak}
			    if $agent->{peak} > $rev
			    && $row->{launches}{ _meta_id($file) };
		}

		@{$row}{qw(id sub_in sub_out rev_peak)} =
		    ( $id, $in, $out, $rev );
		push @rows, $row;
	}

	return @rows;
}

# _jsonl($dir):
#	The trace files directly in one directory. A directory that no
#	reader can open holds none.
sub _jsonl ($dir)
{
	opendir my $dh, $dir or return ();
	my @names = sort grep { /\.jsonl\z/ && -f "$dir/$_" } readdir $dh;
	closedir $dh;

	return map { "$dir/$_" } @names;
}

# _subdirs($dir):
#	The subdirectories of one directory, without the hidden ones.
sub _subdirs ($dir)
{
	opendir my $dh, $dir or return ();
	my @names = sort grep { !/\A[.]/ && -d "$dir/$_" } readdir $dh;
	closedir $dh;

	return map { "$dir/$_" } @names;
}

# _tally($path, $checkout):
#	The measures of one trace file. A file that no reader can open
#	gives the empty measures, and the caller drops the session.
#
#	The start time comes from the first record that carries one,
#	whatever the type of that record. After that the reader
#	decodes an assistant record only, because a full parse of
#	every record costs minutes over a long history
#	(TRACE-USAGE-2). Every usage block and every tool_use block
#	sits in an assistant record, and every one of those records
#	holds the word `assistant`, so the filter loses no count.
#
#	A line that fails to decode is no record.
#
#	One request writes one record for each content block, and an
#	early record of it can carry a partial count, so the tally
#	keeps the usage of the last record of each request
#	(TRACE-USAGE-1).
sub _tally ( $path, $checkout )
{
	my %row = (
		start => q{},
		reqs  => 0,
		peak  => 0,
		in    => 0,
		out   => 0,
		panel => 0,
		edits => 0,

		# The identifiers of the panel launches of the file.
		launches => {},
	);
	open my $fh, '<', $path or return \%row;

	my ( %usage, @order, %round );
	my $launched = 0;
	while ( my $line = <$fh> ) {
		my $rec;

		if ( !length $row{start} ) {
			$rec = eval { $JSON->decode($line) };
			$row{start} = $rec->{timestamp} // q{}
			    if ref $rec eq 'HASH';
		}

		$rec = eval { $JSON->decode($line) }
		    if !defined $rec && index( $line, 'assistant' ) >= 0;
		next
		    unless ref $rec eq 'HASH'
		    && ( $rec->{type} // q{} ) eq 'assistant';

		# An old trace carries no requestId, and its records
		# then count one by one, which is the safe direction.
		my $req = $rec->{requestId} // $rec->{uuid} // q{};
		push @order, $req unless exists $usage{$req};
		$usage{$req} = _usage_of($rec);

		for my $block ( @{ $rec->{message}{content} // [] } ) {
			next unless ( $block->{type} // q{} ) eq 'tool_use';

			if ( _is_panel($block) ) {
				$launched                      = 1;
				$round{$req}                   = 1;
				$row{launches}{ $block->{id} } = 1
				    if length( $block->{id} // q{} );
			}
			elsif (    $launched
				&& $EDIT{ $block->{name} // q{} } )
			{
				$row{edits}++
				    if _repo_edit( $block, $checkout );
			}
		}
	}
	close $fh;

	for my $req (@order) {
		my ( $in, $out ) = @{ $usage{$req} };
		$row{in}  += $in;
		$row{out} += $out;
		$row{peak} = $in if $in > $row{peak};
	}
	$row{reqs}  = scalar @order;
	$row{panel} = scalar keys %round;

	return \%row;
}

# _usage_of($rec):
#	The context and the output of one request, in that order. The
#	context is the input that the request paid for: the fresh
#	input, the cache writes and the cache reads (TRACE-COLUMNS-3).
sub _usage_of ($rec)
{
	my $u = $rec->{message}{usage} // {};
	my $in =
	    ( $u->{input_tokens}                // 0 ) +
	    ( $u->{cache_creation_input_tokens} // 0 ) +
	    ( $u->{cache_read_input_tokens}     // 0 );

	return [ $in, $u->{output_tokens} // 0 ];
}

# _repo_edit($block, $checkout):
#	True when one edit block changes a repository file. The target
#	is file_path, or notebook_path for a notebook.
#
#	An absolute target must sit inside the checkout, on a
#	directory boundary, so a write to the home of the operator, or
#	to a sibling such as <checkout>-backup, is no repository file.
#	A relative target sits inside it, because the path resolves
#	against the working directory of the session. A block with no
#	target counts as an edit, which is the safe direction
#	(TRACE-PANEL-3).
#
#	A target in scratch space is no repository file: a path under
#	scratch/, or a SCRATCHPAD*.md file.
sub _repo_edit ( $block, $checkout )
{
	my $input = $block->{input}     // {};
	my $path  = $input->{file_path} // $input->{notebook_path} // q{};
	return 0 if $path =~ m{\A/} && index( $path, "$checkout/" ) != 0;

	return $path =~ $SCRATCH ? 0 : 1;
}

# _is_panel($block):
#	One launch of one panel member. The type of the agent decides
#	first: a reviewer is a member, and another role, such as a
#	fixer, is not one. A catch-all type and an absent type name no
#	role, so the description decides. The panel of an early
#	session dispatched a catch-all agent, and the description of
#	each member names the panel (TRACE-PANEL-1).
sub _is_panel ($block)
{
	return 0 unless $LAUNCH{ $block->{name} // q{} };

	my $input = $block->{input}         // {};
	my $type  = $input->{subagent_type} // q{};
	return 1 if $type eq 'reviewer';
	return 0 if length $type && !$CATCHALL{$type};

	return ( $input->{description} // q{} ) =~ /panel/i ? 1 : 0;
}

# _meta_id($path):
#	The launch identifier of one sub-agent trace. The trace has a
#	sibling meta file, and the file names the tool_use block that
#	launched the sub-agent. A trace with no meta file gives the
#	empty string, which matches no launch (TRACE-SUB-2).
sub _meta_id ($path)
{
	my $meta = $path =~ s/\.jsonl\z/.meta.json/r;
	open my $fh, '<', $meta or return q{};
	my $text = do { local $/ = undef; <$fh> };
	close $fh;

	my $rec = eval { $JSON->decode( $text // q{} ) };

	return ref $rec eq 'HASH' ? $rec->{toolUseId} // q{} : q{};
}

1;
