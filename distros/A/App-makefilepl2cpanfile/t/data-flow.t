use strict;
use warnings;

# Data-flow tests: follow each piece of data from where it is defined (D),
# through every place it is used (U), to where it is killed (K) - dropped,
# overridden, or released at the end of its scope.
#
# Define-Use chains covered:
#
#   Makefile.PL entry   D: file text
#                       U: parse_prereqs -> deps -> _emit -> output line
#                       K: a later duplicate (first occurrence wins),
#                          commented-out code, invalid name/version
#   MIN_PERL_VERSION    D: file text  U: _parse_min_perl -> _emit -> line 1
#                       K: not a version number
#   existing develop    D: caller's string  U: merge -> deps -> output
#                       K: same module+relationship from Makefile.PL,
#                          commented-out line; version K'd if invalid
#   config tools        D: YAML file  U: validate -> inject -> output
#                       K: module already listed anywhere in develop
#   caller's inputs     D: caller  U: read only - never modified
#   file handles        O: Path::Tiny::filehandle / YAML::Tiny::read
#                       C: released when the read finishes or dies
#   globals             $_ $@ $! $/ pos $1 - read or localised, never leaked
#
# Handles are tracked by wrapping Path::Tiny::filehandle with a
# Test::Mockingbird 'around' hook that records a weak reference to every
# handle it returns: once the call finishes, every weak reference must be
# gone, which proves the handle was destroyed (and so closed).

use Test::Most;
use Test::Mockingbird;
use Test::Memory::Cycle;
use Test::Returns;
use File::Temp qw(tempdir);
use Path::Tiny;
use POSIX qw(EIO);
use Readonly;
use Scalar::Util qw(weaken refaddr);
use YAML::Tiny;

use App::makefilepl2cpanfile;

Readonly my $PKG => 'App::makefilepl2cpanfile';

Readonly my %CFG => (
	header       => '# Generated from Makefile.PL using makefilepl2cpanfile',
	cfg_dir      => '.config',
	cfg_file     => 'makefilepl2cpanfile.yml',
	repeat       => 25,		# calls per leak check; a leak of 1 per call shows as 25
	fd_dir       => '/proc/self/fd',
	sentinel_mod => 'Trace::Me',
	sentinel_ver => '1.2_03',
	sentinel_cmt => 'why: parser -> emit, verbatim #1',
	min_perl     => '5.010001',
	cfg_tool     => 'Config::Tool',
	cfg_ver      => '4.5',
	topic        => 'caller topic',
	evalerr      => 'caller eval error',
);

Readonly my $MF_TRACE => <<"END_MF";
WriteMakefile(
	MIN_PERL_VERSION => '$CFG{min_perl}',
	PREREQ_PM => {
		'$CFG{sentinel_mod}' => '$CFG{sentinel_ver}',	# $CFG{sentinel_cmt}
		'Dup::Mod' => '1.00',
		'Dup::Mod' => '9.99',
	},
	TEST_REQUIRES => { 'Test::Only' => 0 },
	META_MERGE => {
		prereqs => {
			runtime => { requires => { 'Dup::Mod' => '5.55' } },
			develop => { requires => { 'Shared::Dev' => '3.0' } },
		},
	},
);
END_MF

Readonly my $EXISTING => <<'END_CPANFILE';
on 'develop' => sub {
	requires 'Shared::Dev', '1.0';
	recommends 'Shared::Dev';
	requires 'Hand::Tool', '2.0';
	# requires 'Dead::Tool';
	requires 'Bad::Ver', '1.0\';
};
END_CPANFILE

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

sub make_mf {
	my $content = $_[0];
	my $mf = path(tempdir(CLEANUP => 1))->child('Makefile.PL');
	$mf->spew_utf8($content);
	return $mf;
}

# Home directory with an optional YAML config; returns (guard, config path).
sub use_home {
	my $data = $_[0];
	my $home = path(tempdir(CLEANUP => 1));
	my $cfg  = $home->child($CFG{cfg_dir}, $CFG{cfg_file});
	if(defined $data) {
		$cfg->parent->mkpath;
		ref $data ? YAML::Tiny->new($data)->write("$cfg") : $cfg->spew_utf8($data);
	}
	return (mock_scoped('File::HomeDir::my_home' => sub { "$home" }), $cfg);
}

sub quiet {
	my $code = $_[0];
	local $SIG{__WARN__} = sub { };
	return $code->();
}

# Wraps _emit so the exact structure generate() hands it can be inspected.
# The captured deps are deep-copied: the original must be free to die.
sub capture_emit {
	my $seen = $_[0];
	return mock_scoped "${PKG}::_emit" => do {
		my $real = \&App::makefilepl2cpanfile::_emit;
		sub {
			my ($deps, $min_perl) = @_;
			${$seen} = { deps => YAML::Tiny::Load(YAML::Tiny::Dump($deps)), min_perl => $min_perl };
			return $real->(@_);
		};
	};
}

# Tracks every handle Path::Tiny opens during $code.  Returns (result,
# number opened, number still alive afterwards, error).
sub track_handles {
	my $code = $_[0];
	my @weak;
	around 'Path::Tiny::filehandle' => sub {
		my ($orig, @args) = @_;
		my $fh = $orig->(@args);
		push @weak, $fh;
		weaken $weak[-1];
		return $fh;
	};
	my $r = eval { $code->() };
	my $err = $@;
	unmock 'Path::Tiny::filehandle';
	return ($r, scalar(@weak), scalar(grep { defined } @weak), $err);
}

sub open_fds {
	opendir my $dh, $CFG{fd_dir} or return;
	my @fds = grep { /\A\d+\z/ } readdir $dh;
	closedir $dh;
	return scalar @fds;
}

# -----------------------------------------------------------------------
# D -> U: a Makefile.PL entry reaches the output unchanged
#
# Strategy: plant one entry with an unusual (but valid) version and a
# comment full of characters that could be mangled, then inspect it at
# each stage: parse_prereqs, the structure handed to _emit, and the
# final line.  The value must be identical at every stage.
# -----------------------------------------------------------------------
subtest 'DU: Makefile.PL entry -> parse -> emit -> output line' => sub {
	my ($g) = use_home();
	my $mf  = make_mf($MF_TRACE);

	my $parsed = App::makefilepl2cpanfile::parse_prereqs($MF_TRACE);
	is_deeply $parsed->{runtime}{requires}{ $CFG{sentinel_mod} },
		{ version => $CFG{sentinel_ver}, comment => $CFG{sentinel_cmt} },
		'stage 1 (parse_prereqs): version and comment captured verbatim';

	my $seen;
	my $ge = capture_emit(\$seen);
	my $out = App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0);

	is_deeply $seen->{deps}{runtime}{requires}{ $CFG{sentinel_mod} },
		$parsed->{runtime}{requires}{ $CFG{sentinel_mod} },
		'stage 2 (_emit input): same entry as parse_prereqs produced';
	like $out, qr/^requires '\Q$CFG{sentinel_mod}\E', '\Q$CFG{sentinel_ver}\E';   # \Q$CFG{sentinel_cmt}\E$/m,
		'stage 3 (output): the same version and comment';
	returns_is($out, { type => 'string', matches => qr/\A\Q$CFG{header}\E\n/ }, 'output is the documented string');
};

subtest 'DU: MIN_PERL_VERSION -> _parse_min_perl -> emit' => sub {
	my ($g) = use_home();
	my $seen;
	my $ge = capture_emit(\$seen);

	my $out = App::makefilepl2cpanfile::generate(makefile => make_mf($MF_TRACE)->stringify, with_develop => 0);
	is $seen->{min_perl}, $CFG{min_perl}, '_emit receives the declared version';
	like $out, qr/\A\Q$CFG{header}\E\n\nrequires 'perl', '\Q$CFG{min_perl}\E';\n/, 'and writes it after the header';

	# K: a value that is not a version never reaches _emit.
	App::makefilepl2cpanfile::generate(
		makefile => make_mf("WriteMakefile(MIN_PERL_VERSION => '._');\n")->stringify, with_develop => 0,
	);
	is $seen->{min_perl}, undef, 'invalid MIN_PERL_VERSION is killed before _emit';
};

# -----------------------------------------------------------------------
# K: where entries are deliberately dropped
#
# Strategy: every kill point must remove the value completely - it may not
# survive in the intermediate structure or leak into the output.
# -----------------------------------------------------------------------
subtest 'K: later duplicates, comments and invalid data never reach the output' => sub {
	my ($g) = use_home();
	my $seen;
	my $ge = capture_emit(\$seen);
	my $out = App::makefilepl2cpanfile::generate(
		makefile => make_mf($MF_TRACE . "# PREREQ_PM => { 'Commented::Out' => 0 },\n")->stringify,
		with_develop => 0,
	);

	is $seen->{deps}{runtime}{requires}{'Dup::Mod'}{version}, '1.00',
		'first definition kept in the structure';
	unlike $out, qr/9\.99|5\.55/, 'later definitions (same block, prereqs block) killed';
	ok !exists $seen->{deps}{runtime}{requires}{'Commented::Out'}, 'commented-out block never defined';
	unlike $out, qr/Commented::Out/, 'and never output';
};

# -----------------------------------------------------------------------
# existing develop block: D in the caller's string, U in the output
#
# Strategy: the existing cpanfile defines entries that meet the Makefile.PL
# data in the develop phase.  Check who wins at each collision and that
# sanitised values flow on as "no version".
# -----------------------------------------------------------------------
subtest 'DU: existing develop entries merge with Makefile.PL data' => sub {
	my ($g) = use_home();
	my $seen;
	my $ge = capture_emit(\$seen);
	my @w;
	{
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		App::makefilepl2cpanfile::generate(
			makefile => make_mf($MF_TRACE)->stringify, existing => $EXISTING, with_develop => 0,
		);
	}
	my $dev = $seen->{deps}{develop};

	is $dev->{requires}{'Shared::Dev'}{version}, '3.0',
		'Makefile.PL definition kills the existing one for the same module and relationship';
	ok exists $dev->{recommends}{'Shared::Dev'}, 'a different relationship is a separate definition';
	is $dev->{requires}{'Hand::Tool'}{version}, '2.0', 'hand-written entry flows through';
	ok !exists $dev->{requires}{'Dead::Tool'}, 'commented-out existing entry never defined';
	is $dev->{requires}{'Bad::Ver'}{version}, 0, 'invalid version replaced by 0 ...';
	is scalar(grep { /Bad::Ver/ } @w), 1, '... with one warning';
	ok !defined $dev->{requires}{'Hand::Tool'}{comment}, 'existing entries carry no comment';
};

# -----------------------------------------------------------------------
# Config tools: D in YAML, U as develop requires, K when already listed
# -----------------------------------------------------------------------
subtest 'DU: config tools are injected only where nothing is defined' => sub {
	my ($g) = use_home({ develop => {
		$CFG{cfg_tool} => $CFG{cfg_ver},
		'Shared::Dev'  => '99',
		'Hand::Tool'   => '99',
	} });
	my $seen;
	my $ge = capture_emit(\$seen);
	quiet(sub {
		App::makefilepl2cpanfile::generate(makefile => make_mf($MF_TRACE)->stringify, existing => $EXISTING)
	});
	my $dev = $seen->{deps}{develop};

	is_deeply $dev->{requires}{ $CFG{cfg_tool} }, { version => $CFG{cfg_ver}, comment => undef },
		'new tool defined with the configured version';
	is $dev->{requires}{'Shared::Dev'}{version}, '3.0', 'tool from Makefile.PL not overwritten';
	is $dev->{requires}{'Hand::Tool'}{version},  '2.0', 'tool from existing not overwritten';
};

# -----------------------------------------------------------------------
# Structure integrity at the parse -> emit boundary
#
# Strategy: whatever path produced it, every leaf handed to _emit must be
# a well-formed entry, and no empty phase/relationship hash may exist
# (the signature of accidental autovivification).
# -----------------------------------------------------------------------
subtest 'integrity: the structure handed to _emit is well formed' => sub {
	my ($g) = use_home({ develop => { $CFG{cfg_tool} => 0 } });
	my $seen;
	my $ge = capture_emit(\$seen);
	quiet(sub {
		App::makefilepl2cpanfile::generate(makefile => make_mf($MF_TRACE)->stringify, existing => $EXISTING)
	});
	my $deps = $seen->{deps};
	diag explain $deps if $ENV{TEST_VERBOSE};

	my @problems;
	for my $phase (sort keys %{$deps}) {
		push @problems, "empty phase $phase" unless %{ $deps->{$phase} };
		for my $rel (sort keys %{ $deps->{$phase} }) {
			my $mods = $deps->{$phase}{$rel};
			push @problems, "empty $phase/$rel" unless %{$mods};
			for my $m (sort keys %{$mods}) {
				my $e = $mods->{$m};
				push @problems, "$m: keys" unless join(',', sort keys %{$e}) eq 'comment,version';
				push @problems, "$m: version undef" unless defined $e->{version};
				push @problems, "$m: empty comment" if defined $e->{comment} && $e->{comment} eq q{};
			}
		}
	}
	is_deeply \@problems, [], 'no empty hashes and every entry has a defined version';
};

# -----------------------------------------------------------------------
# Caller data is read, never written
#
# Strategy: snapshot every input (and the regex position of the content
# string, a hidden piece of per-string state) and compare after the call.
# -----------------------------------------------------------------------
subtest 'scope: caller inputs are never modified' => sub {
	my ($g) = use_home();
	my $mf = make_mf($MF_TRACE);
	# Omit the optional keys: a routine that filled in its defaults by
	# writing to the caller's hash would add them here.
	my %args = (makefile => "$mf");
	my $snapshot = YAML::Tiny::Dump(\%args);
	quiet(sub { App::makefilepl2cpanfile::generate(\%args) });
	is YAML::Tiny::Dump(\%args), $snapshot, 'partial hashref unchanged (no defaults written back)';

	my %full = (makefile => "$mf", existing => $EXISTING, with_develop => 1);
	$snapshot = YAML::Tiny::Dump(\%full);
	quiet(sub { App::makefilepl2cpanfile::generate(\%full) });
	is YAML::Tiny::Dump(\%full), $snapshot, 'full hashref unchanged';

	my $content = $MF_TRACE;
	$content =~ /PREREQ_PM/g;
	my $pos = pos $content;
	App::makefilepl2cpanfile::parse_prereqs($content);
	is $content, $MF_TRACE, 'parse_prereqs leaves its argument unchanged';
	is pos($content), $pos, 'including its regex position';
};

# -----------------------------------------------------------------------
# Results do not share storage
#
# Strategy: a result that aliased internal state (a constant, a cache, or
# a previous result) would let one caller's edit change another's data.
# -----------------------------------------------------------------------
subtest 'scope: every call returns fresh, independent data' => sub {
	my $a = App::makefilepl2cpanfile::parse_prereqs($MF_TRACE);
	my $b = App::makefilepl2cpanfile::parse_prereqs($MF_TRACE);
	isnt refaddr($a), refaddr($b), 'parse_prereqs: distinct top-level hashes';
	isnt refaddr($a->{runtime}{requires}{'Dup::Mod'}), refaddr($b->{runtime}{requires}{'Dup::Mod'}),
		'parse_prereqs: distinct leaf entries';
	$a->{runtime}{requires}{'Dup::Mod'}{version} = 'changed';
	is App::makefilepl2cpanfile::parse_prereqs($MF_TRACE)->{runtime}{requires}{'Dup::Mod'}{version}, '1.00',
		'editing one result does not affect the next';

	my ($g) = use_home();
	my $c1 = App::makefilepl2cpanfile::_load_develop_config();
	my $c2 = App::makefilepl2cpanfile::_load_develop_config();
	isnt refaddr($c1), refaddr($c2), 'config: distinct hashes';
	%{$c1} = ();
	ok scalar keys %{ App::makefilepl2cpanfile::_load_develop_config() }, 'emptying one does not empty the defaults';
};

# -----------------------------------------------------------------------
# Internal data is released when generate() returns
#
# Strategy: take a weak reference to the structure handed to _emit.  Once
# generate() returns nothing may still hold it - otherwise large inputs
# would accumulate across calls.
# -----------------------------------------------------------------------
subtest 'lifecycle: internal structures die with the call' => sub {
	my ($g) = use_home();
	my $weak;
	my $ge = mock_scoped "${PKG}::_emit" => do {
		my $real = \&App::makefilepl2cpanfile::_emit;
		sub { $weak = $_[0]; weaken $weak; memory_cycle_ok($_[0], 'deps has no cycles'); $real->(@_) };
	};
	App::makefilepl2cpanfile::generate(makefile => make_mf($MF_TRACE)->stringify);
	ok !defined $weak, 'deps structure freed after generate() returns';
};

# -----------------------------------------------------------------------
# File handles: Open -> Use -> Close on every path
#
# Strategy: track every handle Path::Tiny opens.  On success exactly one
# read happens and its handle is released.  To simulate a failure after
# the open, a second hook dies with EIO immediately after the handle is
# created: the handle must still be released and the error propagated.
# -----------------------------------------------------------------------
subtest 'handles: every Path::Tiny handle is released, even on errors' => sub {
	my ($g) = use_home();
	my $mf = make_mf($MF_TRACE);

	my ($out, $opened, $alive, $err) = track_handles(sub {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0)
	});
	is $err, q{}, 'success path: no error';
	is $opened, 1, 'success path: Makefile.PL opened once';
	is $alive, 0, 'success path: handle released';

	# Invalid UTF-8: whichever decoder is installed, all handles are released.
	my $bad = path(tempdir(CLEANUP => 1))->child('Makefile.PL');
	$bad->spew_raw("WriteMakefile(PREREQ_PM => { 'A' => 0 }); # \xff\n");
	($out, $opened, $alive, $err) = track_handles(sub {
		quiet(sub { App::makefilepl2cpanfile::generate(makefile => "$bad", with_develop => 0) })
	});
	cmp_ok $opened, '>=', 1, 'invalid UTF-8: file opened';
	is $alive, 0, "invalid UTF-8: all $opened handle(s) released";

	# Failure right after the open.
	my $msg_eio = do { local $! = EIO; "$!" };
	my @weak;
	around 'Path::Tiny::filehandle' => sub {
		my ($orig, @args) = @_;
		my $fh = $orig->(@args);
		push @weak, $fh;
		weaken $weak[-1];
		die "read: $msg_eio\n";
	};
	throws_ok { App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0) }
		qr/\Aread: \Q$msg_eio\E\n\z/, 'I/O error after open propagates unchanged';
	unmock 'Path::Tiny::filehandle';
	is scalar(@weak), 1, 'the handle had been opened';
	ok !defined $weak[0], 'and was released despite the exception';
};

# -----------------------------------------------------------------------
# File descriptors across all paths, including YAML::Tiny's own open
#
# Strategy: YAML::Tiny opens the config with the open() builtin, which
# cannot be wrapped after compile time, so count the process's open file
# descriptors instead: repeated calls on each path must not grow the count.
# -----------------------------------------------------------------------
subtest 'handles: no file descriptor leaks on any path' => sub {
	plan skip_all => "$CFG{fd_dir} not available" unless defined open_fds();
	my $mf = make_mf($MF_TRACE);

	my %paths = (
		'success with config' => [ { develop => { $CFG{cfg_tool} => 0 } } ],
		'YAML syntax error'   => [ "develop: [\n  x" ],
		'no develop key'      => [ { other => 1 } ],
		'no config'           => [ undef ],
	);
	for my $name (sort keys %paths) {
		my ($g) = use_home(@{ $paths{$name} });
		my $before = open_fds();
		for (1 .. $CFG{repeat}) {
			eval { quiet(sub { App::makefilepl2cpanfile::generate(makefile => "$mf") }) };
		}
		is open_fds(), $before, "$name: no descriptors leaked over $CFG{repeat} calls";
	}
};

# -----------------------------------------------------------------------
# Globals: read-only, localised, or ignored - never leaked
#
# Strategy: set every global the module could touch to a hostile value.
# The output must not change (so nothing depends on the caller's values)
# and the values must be intact afterwards (so nothing leaks out).
# -----------------------------------------------------------------------
subtest 'globals: hostile caller globals neither change the result nor leak' => sub {
	my ($g) = use_home({ develop => { $CFG{cfg_tool} => 0 } });
	my $mf = make_mf($MF_TRACE);
	my $reference = App::makefilepl2cpanfile::generate(makefile => "$mf");

	for my $rs ([\1, 'record reads'], [undef, 'slurp mode'], [q{}, 'paragraph mode'], ['}', 'odd separator']) {
		local $/ = $rs->[0];
		is App::makefilepl2cpanfile::generate(makefile => "$mf"), $reference, "\$/ = $rs->[1]: same output";
		is $/, $rs->[0], "\$/ = $rs->[1]: preserved";
	}

	{
		local $, = '|';
		local $\ = "\n!";
		local $" = '::';
		is App::makefilepl2cpanfile::generate(makefile => "$mf"), $reference, 'output separators have no effect';
	}

	local $_ = $CFG{topic};
	local $@ = $CFG{evalerr};
	local $! = EIO;
	'captured' =~ /(capt)/;
	App::makefilepl2cpanfile::generate(makefile => "$mf");
	App::makefilepl2cpanfile::parse_prereqs($MF_TRACE);
	is $_, $CFG{topic}, '$_ preserved';
	is $@, $CFG{evalerr}, '$@ preserved';
	is 0 + $!, EIO, '$! preserved';
	is $1, 'capt', "caller's \$1 preserved";
};

done_testing;
