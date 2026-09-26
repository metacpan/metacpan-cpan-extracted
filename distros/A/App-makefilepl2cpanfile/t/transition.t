use strict;
use warnings;

# State-transition tests for the finite state machine drawn under
# "=head1 STATE DIAGRAM" in lib/App/makefilepl2cpanfile.pm.
#
# States (one call to generate()):
#   START, READ_UTF8, READ_RAW, PARSE, MERGE, CONFIG, DEFAULTS, VALIDATE,
#   INJECT, EMIT, RETURN, and three error exits:
#   DIE_CANNOT_READ, DIE_IO, DIE_PARSE_CONFIG.
# The command-line tool adds WRITE / PRINT / DIFF after RETURN.
#
# The path taken is observed, not inferred: Test::Mockingbird 'around'
# hooks on the routine that implements each state append the state's name
# to a trace as it is entered.  MERGE and INJECT are not separate routines,
# so they are recognised from the structure handed to _emit (entries that
# only the existing cpanfile, or only the configuration, could provide).
#
# Every documented edge has a subtest named "State: A -> Trigger: T ->
# State: B".  Edges that are NOT in the diagram are attempted too and must
# be refused at the first possible point, without side effects.  (The two
# discrepancies this file once flagged - READ_RAW -> DIE and the command
# line tool's own states - are now drawn in the diagram and tested below
# as ordinary edges.)

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Capture::Tiny ();
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Path::Tiny;
use POSIX qw(EIO);
use Readonly;
use YAML::Tiny;

use_ok('App::makefilepl2cpanfile');

Readonly my $PKG => 'App::makefilepl2cpanfile';

Readonly my %CFG => (
	cfg_dir     => '.config',
	cfg_file    => 'makefilepl2cpanfile.yml',
	cpanfile    => 'cpanfile',
	written     => 'cpanfile written successfully.',
	all_found   => 'All Makefile.PL prerequisites are present in the output.',
	decode_err  => "Can't decode ill-formed UTF-8 octet sequence <FF>",
	config_tool => 'Configured::Tool',
	kept_tool   => 'Kept::Tool',
);

Readonly my @DEFAULTS => qw(Devel::Cover Perl::Critic Test::Pod Test::Pod::Coverage);

Readonly my $LIB => path($Bin)->parent->child('lib')->absolute->stringify;
Readonly my $BIN => path($Bin)->parent->child('bin', 'makefilepl2cpanfile')->absolute->stringify;

Readonly my $MSG_EIO => do { local $! = EIO; "$!" };

Readonly my $MF      => "WriteMakefile(PREREQ_PM => { 'Moo' => 0 });\n";
Readonly my $EXISTING => "on 'develop' => sub {\n\trequires '$CFG{kept_tool}';\n};\n";

# Routine => state entered when it is called.
Readonly my %STATE_OF => (
	'Path::Tiny::slurp_utf8'                   => 'READ_UTF8',
	'Path::Tiny::slurp_raw'                    => 'READ_RAW',
	"${PKG}::parse_prereqs"                    => 'PARSE',
	"${PKG}::_load_develop_config"             => 'CONFIG',
	"${PKG}::_emit"                            => 'EMIT',
);

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

sub make_mf {
	my $mf = path(tempdir(CLEANUP => 1))->child('Makefile.PL');
	$mf->spew_raw($_[0] // $MF);
	return "$mf";
}

# A home directory: no config (undef), a hashref config, or raw YAML text.
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

# Runs generate(%args) with every state routine traced.  Returns a hashref:
#   trace    - states entered, in order, ending in RETURN or a DIE_* state
#   result   - the returned text (undef on error)
#   error    - the exception (undef on success)
#   warnings - warnings raised
#   deps     - the structure handed to _emit (undef if EMIT not reached)
sub run_traced {
	my %args = @_;
	my (@trace, $deps, @warnings);

	for my $target (sort keys %STATE_OF) {
		my $state = $STATE_OF{$target};
		around $target => sub {
			my ($orig, @a) = @_;
			push @trace, $state;
			$deps = $a[0] if $state eq 'EMIT';
			my @r = wantarray ? $orig->(@a) : scalar $orig->(@a);
			if($state eq 'CONFIG') {
				# Leaving CONFIG: through DEFAULTS, or through VALIDATE.
				my %got = %{ $r[0] };
				push @trace, (join(',', sort keys %got) eq join(',', @DEFAULTS)) ? 'DEFAULTS' : 'VALIDATE';
				push @trace, 'INJECT';
			}
			return wantarray ? @r : $r[0];
		};
	}
	# A successful YAML read means VALIDATE was entered (possibly on the way
	# to DEFAULTS when there is no develop key).
	around 'YAML::Tiny::read' => sub {
		my ($orig, @a) = @_;
		my $r = $orig->(@a);
		push @trace, 'VALIDATE' if $r;
		return $r;
	};

	my $result = do {
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		eval { App::makefilepl2cpanfile::generate(%args) };
	};
	my $error = $@;

	unmock($_) for 'YAML::Tiny::read', sort keys %STATE_OF;

	# Tidy the CONFIG bookkeeping: VALIDATE recorded by the YAML read and
	# again on leaving CONFIG collapses to one; DEFAULTS reached from
	# VALIDATE keeps both.
	my @clean;
	for my $s (@trace) {
		next if @clean && $clean[-1] eq $s;
		push @clean, $s;
	}

	# MERGE: an entry only the existing cpanfile could supply reached _emit.
	if($deps && ($args{existing} // q{}) =~ /\Q$CFG{kept_tool}\E/
			&& grep { exists $deps->{develop}{$_}{ $CFG{kept_tool} } } keys %{ $deps->{develop} || {} }) {
		my ($i) = grep { $clean[$_] eq 'PARSE' } 0 .. $#clean;
		splice @clean, $i + 1, 0, 'MERGE';
	}

	unshift @clean, 'START';
	if($error) {
		push @clean, $error =~ /\ACannot read / ? 'DIE_CANNOT_READ'
			: $error =~ /\AFailed to parse / ? 'DIE_PARSE_CONFIG'
			: 'DIE_IO';
	} else {
		push @clean, 'RETURN';
	}
	diag "trace: @clean" if $ENV{TEST_VERBOSE};
	return { trace => \@clean, result => $result, error => $error, warnings => \@warnings, deps => $deps };
}

sub path_ok {
	my ($run, $expected, $name) = @_;
	is_deeply $run->{trace}, $expected, "$name: " . join(' -> ', @{$expected});
	return;
}

# -----------------------------------------------------------------------
# START
# -----------------------------------------------------------------------

subtest 'State: START -> Trigger: makefile unreadable -> State: DIE (Cannot read)' => sub {
	my ($g) = use_home();
	my $r = run_traced(makefile => '/no/such/Makefile.PL');
	path_ok($r, [qw(START DIE_CANNOT_READ)], 'refused before any read');
	like $r->{error}, qr/\ACannot read '\/no\/such\/Makefile\.PL' at /, 'documented message';
};

subtest 'State: START -> Trigger: makefile readable -> State: READ_UTF8 -> ok -> State: PARSE' => sub {
	my ($g) = use_home();
	my $r = run_traced(makefile => make_mf(), with_develop => 0);
	path_ok($r, [qw(START READ_UTF8 PARSE EMIT RETURN)], 'shortest successful path');
	returns_is($r->{result}, { type => 'string' }, 'RETURN yields the text');
	is scalar @{ $r->{warnings} }, 0, 'no warnings on this path';
};

# -----------------------------------------------------------------------
# READ_UTF8
# -----------------------------------------------------------------------

subtest 'State: READ_UTF8 -> Trigger: decode error -> State: READ_RAW -> State: PARSE' => sub {
	my ($g) = use_home();
	my $mf = make_mf();
	my $m = mock_scoped 'Path::Tiny::slurp_utf8' => sub { die "$CFG{decode_err}\n" };
	my $r = run_traced(makefile => $mf, with_develop => 0);
	path_ok($r, [qw(START READ_UTF8 READ_RAW PARSE EMIT RETURN)], 'raw read then continue');
	like $r->{warnings}[0], qr/\AWarning: '\Q$mf\E' contains invalid UTF-8/, 'side effect: carp "invalid UTF-8"';
};

subtest 'State: READ_UTF8 -> Trigger: other I/O error -> State: DIE (error passed on)' => sub {
	my ($g) = use_home();
	my $m = mock_scoped 'Path::Tiny::slurp_utf8' => sub { Path::Tiny::Error->throw('read', 'Makefile.PL', $MSG_EIO) };
	my $r = run_traced(makefile => make_mf(), with_develop => 0);
	path_ok($r, [qw(START READ_UTF8 DIE_IO)], 'no raw read, no parse');
	isa_ok $r->{error}, 'Path::Tiny::Error', 'the original error object';
	is scalar @{ $r->{warnings} }, 0, 'no invalid-UTF-8 warning';
};

subtest 'State: READ_RAW -> Trigger: raw read fails -> State: DIE (error passed on)' => sub {
	my ($g) = use_home();
	my $m = mock_scoped(
		'Path::Tiny::slurp_utf8' => sub { die "$CFG{decode_err}\n" },
		'Path::Tiny::slurp_raw'  => sub { Path::Tiny::Error->throw('read', 'Makefile.PL', $MSG_EIO) },
	);
	my $r = run_traced(makefile => make_mf(), with_develop => 0);
	path_ok($r, [qw(START READ_UTF8 READ_RAW DIE_IO)], 'the call fails safely');
	isa_ok $r->{error}, 'Path::Tiny::Error', 'the raw read error is passed on';
};

# -----------------------------------------------------------------------
# PARSE / MERGE and the with_develop decision
# -----------------------------------------------------------------------

subtest 'State: PARSE -> Trigger: develop section in existing -> State: MERGE' => sub {
	my ($g) = use_home();
	my $r = run_traced(makefile => make_mf(), existing => $EXISTING, with_develop => 0);
	path_ok($r, [qw(START READ_UTF8 PARSE MERGE EMIT RETURN)], 'merge then emit');
	ok exists $r->{deps}{develop}{requires}{ $CFG{kept_tool} }, 'side effect: existing entry copied';
};

subtest 'State: PARSE -> Trigger: no develop section, with_develop false -> State: EMIT' => sub {
	my ($g) = use_home();
	for my $existing (q{}, "requires 'X';\n", "on 'develop' => sub {\n\trequires 'Unclosed';\n") {
		my $r = run_traced(makefile => make_mf(), existing => $existing, with_develop => 0);
		path_ok($r, [qw(START READ_UTF8 PARSE EMIT RETURN)], 'MERGE and CONFIG skipped');
		ok !exists $r->{deps}{develop}, 'no develop phase created';
	}
};

subtest 'State: MERGE -> Trigger: with_develop true -> State: CONFIG' => sub {
	my ($g) = use_home();
	my $r = run_traced(makefile => make_mf(), existing => $EXISTING, with_develop => 1);
	path_ok($r, [qw(START READ_UTF8 PARSE MERGE CONFIG DEFAULTS INJECT EMIT RETURN)], 'merge, then configuration');
};

# -----------------------------------------------------------------------
# CONFIG
# -----------------------------------------------------------------------

subtest 'State: CONFIG -> Trigger: no home / missing / not a regular file -> State: DEFAULTS' => sub {
	my @cases = (
		[ 'no home directory', sub { mock_scoped 'File::HomeDir::my_home' => sub { undef } } ],
		[ 'config missing',    sub { (use_home())[0] } ],
		[ 'config is a directory', sub { my ($g, $cfg) = use_home(); $cfg->mkpath; $g } ],
	);
	for my $case (@cases) {
		my ($name, $setup) = @{$case};
		my $g = $setup->();
		my $r = run_traced(makefile => make_mf(), with_develop => 1);
		path_ok($r, [qw(START READ_UTF8 PARSE CONFIG DEFAULTS INJECT EMIT RETURN)], $name);
		is scalar @{ $r->{warnings} }, 0, "$name: silent";
		ok exists $r->{deps}{develop}{requires}{$_}, "$name: default tool $_ injected" for @DEFAULTS;
	}
};

subtest 'State: CONFIG -> Trigger: regular config file -> State: VALIDATE -> State: INJECT' => sub {
	my ($g) = use_home({ develop => { $CFG{config_tool} => '1.0' } });
	my $r = run_traced(makefile => make_mf(), with_develop => 1);
	path_ok($r, [qw(START READ_UTF8 PARSE CONFIG VALIDATE INJECT EMIT RETURN)], 'configured tools');
	is $r->{deps}{develop}{requires}{ $CFG{config_tool} }{version}, '1.0', 'side effect: configured tool injected';
};

subtest 'State: CONFIG -> Trigger: stat/read/YAML error -> State: DIE (Failed to parse)' => sub {
	my ($g, $cfg) = use_home("develop: [\n  x");
	my $r = run_traced(makefile => make_mf(), with_develop => 1);
	path_ok($r, [qw(START READ_UTF8 PARSE CONFIG DIE_PARSE_CONFIG)], 'no INJECT, no EMIT');
	like $r->{error}, qr/\AFailed to parse \Q$cfg\E: /, 'documented message';
};

# -----------------------------------------------------------------------
# VALIDATE
# -----------------------------------------------------------------------

subtest 'State: VALIDATE -> Trigger: no develop key -> State: DEFAULTS' => sub {
	my ($g, $cfg) = use_home({ other => 1 });
	my $r = run_traced(makefile => make_mf(), with_develop => 1);
	path_ok($r, [qw(START READ_UTF8 PARSE CONFIG VALIDATE DEFAULTS INJECT EMIT RETURN)], 'read, then defaults');
	like $r->{warnings}[0], qr/\ANo 'develop' key found in \Q$cfg\E; using defaults/, 'side effect: carp';
};

subtest 'State: VALIDATE -> Trigger: bad name / bad version -> State: VALIDATE (carp) -> State: INJECT' => sub {
	my ($g) = use_home({ develop => { 'Bad Name' => 0, $CFG{config_tool} => '1.0x' } });
	my $r = run_traced(makefile => make_mf(), with_develop => 1);
	path_ok($r, [qw(START READ_UTF8 PARSE CONFIG VALIDATE INJECT EMIT RETURN)], 'stays on the validate path');
	is scalar @{ $r->{warnings} }, 2, 'side effect: one carp per bad entry';
	ok !exists $r->{deps}{develop}{requires}{'Bad Name'}, 'bad name skipped';
	is $r->{deps}{develop}{requires}{ $CFG{config_tool} }{version}, 0, 'bad version replaced by 0';
};

# -----------------------------------------------------------------------
# INJECT -> EMIT -> RETURN
# -----------------------------------------------------------------------

subtest 'State: INJECT -> State: EMIT -> State: RETURN (no file written, globals kept)' => sub {
	my ($g) = use_home({ develop => { $CFG{kept_tool} => '9', $CFG{config_tool} => 0 } });
	my $dir = path(tempdir(CLEANUP => 1));
	my $mf  = $dir->child('Makefile.PL');
	$mf->spew_utf8($MF);
	my @before = sort map { "$_" } $dir->children;

	local $_ = 'topic';
	local $@ = 'eval error';
	my $r = run_traced(makefile => "$mf", existing => $EXISTING, with_develop => 1);
	path_ok($r, [qw(START READ_UTF8 PARSE MERGE CONFIG VALIDATE INJECT EMIT RETURN)], 'the longest path');
	is $r->{deps}{develop}{requires}{ $CFG{kept_tool} }{version}, 0, 'INJECT: listed tool not overwritten';
	ok exists $r->{deps}{develop}{requires}{ $CFG{config_tool} }, 'INJECT: new tool added';
	is_deeply [ sort map { "$_" } $dir->children ], \@before, 'RETURN: no file written';
	is $_, 'topic', 'RETURN: $_ unchanged';
};

# -----------------------------------------------------------------------
# Edges that are not in the diagram must be impossible
# -----------------------------------------------------------------------

subtest 'Invalid: START -> PARSE without a readable makefile' => sub {
	my ($g) = use_home();
	for my $bad ('/no/such/file', tempdir(CLEANUP => 1), [], q{}) {
		my $r = run_traced(makefile => $bad);
		path_ok($r, [qw(START DIE_CANNOT_READ)], 'trapped at START: ' . (ref $bad || "'$bad'"));
	}
	throws_ok { App::makefilepl2cpanfile::generate(makefile => {}) } qr/\ACannot read 'HASH\(0x[0-9a-f]+\)' at /,
		'a reference cannot enter READ_UTF8';
};

subtest 'Invalid: READ_UTF8 -> READ_RAW on an I/O error, or -> PARSE after any error' => sub {
	my ($g) = use_home();
	for my $err ([ 'error object', sub { Path::Tiny::Error->throw('read', '/src/utf8/decode/x', $MSG_EIO) } ],
			[ 'plain I/O message', sub { die "$MSG_EIO\n" } ]) {
		my $m = mock_scoped 'Path::Tiny::slurp_utf8' => $err->[1];
		my $r = run_traced(makefile => make_mf(), with_develop => 0);
		path_ok($r, [qw(START READ_UTF8 DIE_IO)], "$err->[0]: neither READ_RAW nor PARSE reached");
	}
};

subtest 'Invalid: CONFIG entered while with_develop is false' => sub {
	my ($g) = use_home("develop: [\n  x");		# would die if CONFIG were entered
	for my $off (0, q{}, '0') {
		my $r = run_traced(makefile => make_mf(), with_develop => $off);
		path_ok($r, [qw(START READ_UTF8 PARSE EMIT RETURN)], "with_develop '$off': CONFIG skipped");
	}
};

subtest 'Invalid: CONFIG -> INJECT or EMIT after a configuration error' => sub {
	my ($g) = use_home("develop: [\n  x");
	my $emits = 0;
	my $m = mock_scoped "${PKG}::_emit" => sub { $emits++; return q{} };
	throws_ok { App::makefilepl2cpanfile::generate(makefile => make_mf(), with_develop => 1) }
		qr/\AFailed to parse /, 'trapped at CONFIG';
	is $emits, 0, 'EMIT never reached';
};

subtest 'Invalid: CONFIG -> VALIDATE for a file that is not regular' => sub {
	my ($g, $cfg) = use_home();
	$cfg->mkpath;
	my $reads = 0;
	my $m = mock_scoped 'YAML::Tiny::read' => sub { $reads++; die "should not be read\n" };
	App::makefilepl2cpanfile::generate(makefile => make_mf(), with_develop => 1);
	is $reads, 0, 'the YAML reader is never called';
};

subtest 'Invalid: a failed call leaves state behind for the next one' => sub {
	# The machine has no memory: after any DIE the next call starts at
	# START and behaves exactly like a first call.
	my ($g) = use_home();
	my $mf = make_mf();
	my $fresh = App::makefilepl2cpanfile::generate(makefile => $mf, with_develop => 0);
	eval { App::makefilepl2cpanfile::generate(makefile => '/no/such/file') };
	{
		my $m = mock_scoped 'Path::Tiny::slurp_utf8' => sub { die "$MSG_EIO\n" };
		eval { App::makefilepl2cpanfile::generate(makefile => $mf, with_develop => 0) };
	}
	is App::makefilepl2cpanfile::generate(makefile => $mf, with_develop => 0), $fresh,
		'after two failed calls the result is identical to a fresh call';
};

# -----------------------------------------------------------------------
# Command-line states after RETURN
# -----------------------------------------------------------------------

sub run_cli {
	my ($dir, @args) = @_;
	my $cwd = Path::Tiny->cwd;
	local $ENV{HOME} = tempdir(CLEANUP => 1);
	chdir $dir or die "chdir $dir: $!";
	my ($out, $err, $exit) = Capture::Tiny::capture(sub { system $^X, "-I$LIB", $BIN, @args });
	chdir $cwd or die "chdir $cwd: $!";
	s/\r\n/\n/g for $out, $err;
	return ($out, $err, $exit >> 8);
}

sub cli_project {
	my $dir = path(tempdir(CLEANUP => 1));
	$dir->child('Makefile.PL')->spew_utf8($MF);
	return $dir;
}

subtest 'State: RETURN -> Trigger: (default) -> State: WRITE' => sub {
	my $dir = cli_project();
	my ($out, $err, $exit) = run_cli($dir, '--no-develop');
	is $exit, 0, 'exit 0';
	is $out, "$CFG{written}\n", 'reports the write';
	like $dir->child($CFG{cpanfile})->slurp_utf8, qr/^requires 'Moo';$/m, 'side effect: cpanfile written';
};

subtest 'State: RETURN -> Trigger: --dry-run -> State: PRINT' => sub {
	my $dir = cli_project();
	my ($out, undef, $exit) = run_cli($dir, '--no-develop', '--dry-run');
	is $exit, 0, 'exit 0';
	like $out, qr/^requires 'Moo';$/m, 'text printed';
	ok !$dir->child($CFG{cpanfile})->exists, 'nothing written';
};

subtest 'State: RETURN -> Trigger: --diff -> State: DIFF' => sub {
	my $dir = cli_project();
	my ($out, undef, $exit) = run_cli($dir, '--no-develop', '--diff');
	is $exit, 0, 'exit 0';
	like $out, qr/^\+requires 'Moo';$/m, 'diff printed';
	ok !$dir->child($CFG{cpanfile})->exists, 'nothing written';
};

# The command-line tool's own states: OPTIONS and GUARD before START, and
# CHECK after RETURN.
subtest 'CLI: State: OPTIONS / GUARD -> Trigger: bad options or cpanfile -> exit; State: CHECK' => sub {
	{
		my $dir = cli_project();
		my (undef, $err, $exit) = run_cli($dir, '--with-develop', '--no-develop');
		isnt $exit, 0, 'conflicting options: stops before START';
		like $err, qr/mutually exclusive/, 'conflicting options: reported';
		ok !$dir->child($CFG{cpanfile})->exists, 'conflicting options: nothing written';
	}
	SKIP: {
		my $dir = cli_project();
		symlink '/nonexistent', $dir->child($CFG{cpanfile})->stringify or skip "cannot create a symlink: $!", 2;
		my (undef, $err, $exit) = run_cli($dir);
		isnt $exit, 0, 'symlinked cpanfile: stops before START';
		like $err, qr/Refusing to use 'cpanfile': it is a symbolic link/, 'symlinked cpanfile: reported';
	}
	{
		# Found by this test: with a directory named cpanfile, the new text
		# was moved INTO the directory and success was reported.
		my $dir = cli_project();
		$dir->child($CFG{cpanfile})->mkpath;
		my (undef, $err, $exit) = run_cli($dir, '--no-develop');
		isnt $exit, 0, 'cpanfile is a directory: stops before START';
		like $err, qr/Refusing to use 'cpanfile': it is not a regular file/, 'cpanfile is a directory: reported';
		is_deeply [ $dir->child($CFG{cpanfile})->children ], [], 'cpanfile is a directory: nothing put inside it';
	}
	{
		my ($out, undef, $exit) = run_cli(cli_project(), '--no-develop', '--check', '--dry-run');
		is($exit, 0, '--check: succeeds');
		like($out, qr/^\Q$CFG{all_found}\E$/m, '--check: reports after RETURN');
		is($exit, 0, '--check with nothing missing: exit status 0');
	}
};

done_testing();
