use strict;
use warnings;

# End-to-end integration tests for App::makefilepl2cpanfile and the
# bin/makefilepl2cpanfile command-line tool.
#
# The workflows exercised here cross routine and process boundaries:
#   - parse_prereqs() and generate() agreeing on the same Makefile.PL
#   - generate() output parsed back by Module::CPANfile (the consumer)
#   - the user config file feeding the develop phase
#   - repeated CLI runs, where each run's cpanfile is the next run's input
#   - independent runs in parallel that must not interfere
#   - behaviour with every combination of Path::Tiny's optional UTF-8
#     decoders present or hidden via Test::Without::Module
#
# The API is functional (there is no constructor), so the "independent
# instances" requirement is met by independent calls with independent
# inputs, both interleaved in one process and in concurrent processes.
#
# Collaborators are observed with Test::Mockingbird spies (which call
# through to the real code), never replaced, so every test runs the real
# pipeline.

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Capture::Tiny qw(capture);
use Config;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use IPC::Open3 qw(open3);
use Path::Tiny;
use Readonly;
use YAML::Tiny;

BEGIN { use_ok('App::makefilepl2cpanfile') }

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

Readonly my %CFG => (
	header         => '# Generated from Makefile.PL using makefilepl2cpanfile',
	makefile       => 'Makefile.PL',
	cpanfile       => 'cpanfile',
	cfg_dir        => '.config',
	cfg_file       => 'makefilepl2cpanfile.yml',
	msg_written    => 'cpanfile written successfully.',
	msg_all_found  => 'All Makefile.PL prerequisites are present in the output.',
	msg_exclusive  => '--with-develop and --no-develop are mutually exclusive',
	msg_usage      => 'Usage:',
	msg_bad_utf8   => qr/UTF-8|decode|does not map/i,
	parallel_runs  => 4,
);

Readonly my $LIB => path($Bin)->parent->child('lib')->absolute->stringify;
Readonly my $BIN => path($Bin)->parent->child('bin', 'makefilepl2cpanfile')->absolute->stringify;

# Path::Tiny picks its UTF-8 decoder from these optional modules, which
# changes what happens when a Makefile.PL contains invalid UTF-8.
Readonly my @OPTIONAL_DECODERS => qw(Unicode::UTF8 PerlIO::utf8_strict);

Readonly my @DEFAULT_DEV_TOOLS => qw(Devel::Cover Perl::Critic Test::Pod Test::Pod::Coverage);

Readonly my %GENERATE_OUTPUT => (
	type    => 'string',
	matches => qr/\A\Q$CFG{header}\E\n.*(?<!\n)\n\z/s,
);

# -----------------------------------------------------------------------
# Fixtures
# -----------------------------------------------------------------------

# Every simple key, a structured block, META_MERGE, versions and comments.
Readonly my $MF_FULL => <<'END_MF';
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME               => 'Full::Dist',
	MIN_PERL_VERSION   => '5.010',
	CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },
	BUILD_REQUIRES     => { 'Module::Build' => '0.42' },
	TEST_REQUIRES      => { 'Test::More' => '0.98' },
	PREREQ_PM          => {
		'Moo'       => '2.000',	# object system
		'Try::Tiny' => 0,
	},
	META_MERGE => {
		prereqs => {
			runtime => { recommends => { 'Cpanel::JSON::XS' => '4.00' } },
			test    => { suggests   => { 'Test::Differences' => 0 } },
		},
	},
);
END_MF

# The Database-Abstraction layout: legacy recommends/suggests directly
# under META_MERGE, next to unrelated META_MERGE content.
Readonly my $MF_LEGACY => <<'END_MF';
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME      => 'Legacy::Dist',
	PREREQ_PM => { 'DBI' => 1.6 },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		recommends => {
			# Optional runtime backends
			'JSON::MaybeXS' => 0,		# JSON backend
			'XML::Simple'   => 0,		# XML backend
		},
		suggests => { 'YAML::XS' => '0.88' },
		resources => {
			repository => { type => 'git', url => 'git://example.com/x.git' },
		},
	},
);
END_MF

# Valid ASCII dependency lines followed by a comment with invalid UTF-8.
Readonly my $MF_BAD_UTF8 => "WriteMakefile(PREREQ_PM => { 'Raw::Mod' => 0 }); # \xff\xfe\n";

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

# A project directory containing a Makefile.PL and, optionally, a cpanfile.
sub make_project {
	my ($makefile, $cpanfile) = @_;
	my $dir = path(tempdir(CLEANUP => 1));
	$dir->child($CFG{makefile})->spew_raw($makefile);
	$dir->child($CFG{cpanfile})->spew_utf8($cpanfile) if defined $cpanfile;
	return $dir;
}

# A home directory, with a config file when $data is given.
sub make_home {
	my $data = $_[0];
	my $home = path(tempdir(CLEANUP => 1));
	if($data) {
		$home->child($CFG{cfg_dir})->mkpath;
		YAML::Tiny->new($data)->write($home->child($CFG{cfg_dir}, $CFG{cfg_file})->stringify);
	}
	return $home;
}

# Routes the library's home-directory lookup to $home for the guard's life.
sub use_home {
	my $home = $_[0];
	return mock_scoped 'File::HomeDir::my_home' => sub { "$home" };
}

# The command that runs the CLI in a fresh perl, hiding @without modules.
sub cli_command {
	my ($without, @args) = @_;
	my @hide = @{$without} ? ('-MTest::Without::Module=' . join(q{,}, @{$without})) : ();
	return ($^X, "-I$LIB", @hide, $BIN, @args);
}

# Runs the CLI in $dir with HOME=$home.  Returns (stdout, stderr, exit).
sub run_cli {
	my ($dir, $home, @args) = @_;
	my $without = ref $args[0] eq 'ARRAY' ? shift @args : [];
	my $cwd = Path::Tiny->cwd;
	local $ENV{HOME} = "$home";
	chdir $dir or die "chdir $dir: $!";
	my ($out, $err, $exit) = capture { system cli_command($without, @args) };
	# A child's STDOUT/STDERR use CRLF on Windows; the tests check content.
	s/\r\n/\n/g for $out, $err;
	chdir $cwd or die "chdir $cwd: $!";
	diag "CLI @args\nSTDOUT:\n$out\nSTDERR:\n$err" if $ENV{TEST_VERBOSE};
	return ($out, $err, $exit >> 8);
}

# Loads cpanfile text with Module::CPANfile and flattens it to
# { phase => { rel => { module => version } } } for comparison.
sub cpanfile_prereqs {
	my $text = $_[0];
	require Module::CPANfile;
	my $file = path(tempdir(CLEANUP => 1))->child($CFG{cpanfile});
	$file->spew_utf8($text);
	return Module::CPANfile->load("$file")->prereq_specs;
}

# Flattens parse_prereqs() output to the same shape as prereq_specs.
sub flatten_deps {
	my $deps = $_[0];
	my %flat;
	for my $phase (keys %{$deps}) {
		for my $rel (keys %{ $deps->{$phase} }) {
			for my $mod (keys %{ $deps->{$phase}{$rel} }) {
				$flat{$phase}{$rel}{$mod} = $deps->{$phase}{$rel}{$mod}{version};
			}
		}
	}
	return \%flat;
}

# Every non-empty subset of @list.
sub all_subsets {
	my @list = @_;
	return map {
		my $mask = $_;
		[ map { $list[$_] } grep { $mask & (1 << $_) } 0 .. $#list ]
	} 0 .. (1 << @list) - 1;
}

# -----------------------------------------------------------------------
# 1. Library pipeline: parse_prereqs() -> generate() -> Module::CPANfile
#
# Strategy: the cpanfile is only useful if cpanm can read it.  Parse the
# generated text with Module::CPANfile (the real consumer) and check that
# it declares exactly what parse_prereqs() found - nothing lost, nothing
# invented, every version intact.
# -----------------------------------------------------------------------
subtest 'pipeline: generate() output is a valid cpanfile matching parse_prereqs()' => sub {
	my $home = make_home();
	my $g    = use_home($home);

	for my $case ([$MF_FULL, '5.010', 'full fixture'], [$MF_LEGACY, undef, 'legacy META_MERGE fixture']) {
		my ($content, $min_perl, $name) = @{$case};
		my $dir = make_project($content);

		my $parsed = App::makefilepl2cpanfile::parse_prereqs($content);
		my $out = App::makefilepl2cpanfile::generate(
			makefile => $dir->child($CFG{makefile})->stringify, with_develop => 0,
		);
		returns_is($out, \%GENERATE_OUTPUT, "$name: output matches the documented schema");

		my $specs = cpanfile_prereqs($out);
		my $perl  = delete $specs->{runtime}{requires}{perl};
		is $perl, $min_perl, "$name: perl requirement matches MIN_PERL_VERSION";
		delete $specs->{runtime}{requires} unless %{ $specs->{runtime}{requires} || {} };
		is_deeply $specs, flatten_deps($parsed),
			"$name: Module::CPANfile sees exactly what parse_prereqs() found";
	}
};

# -----------------------------------------------------------------------
# 2. Legacy META_MERGE layout end to end through the CLI
#
# Strategy: the motivating real-world case.  Run the CLI on a Makefile.PL
# with recommends/suggests directly under META_MERGE and confirm the
# written cpanfile carries them as runtime recommendations/suggestions,
# with comments, and that --check agrees nothing was dropped.
# -----------------------------------------------------------------------
subtest 'CLI: legacy recommends/suggests reach the written cpanfile' => sub {
	my $dir  = make_project($MF_LEGACY);
	my $home = make_home();

	my ($out, $err, $exit) = run_cli($dir, $home, '--no-develop', '--check');
	is $exit, 0, 'exit status 0';
	is $err, q{}, 'nothing on STDERR';
	like $out, qr/^\Q$CFG{msg_all_found}\E$/m, '--check reports every module present';
	like $out, qr/^\Q$CFG{msg_written}\E$/m,   'write confirmed';

	my $written = $dir->child($CFG{cpanfile})->slurp_utf8;
	like $written, qr/^recommends 'JSON::MaybeXS';   # JSON backend$/m, 'recommends with comment';
	like $written, qr/^recommends 'XML::Simple';   # XML backend$/m,     'second recommends';
	like $written, qr/^suggests 'YAML::XS', '0\.88';$/m,                 'suggests with version';
	unlike $written, qr/git:/, 'unrelated META_MERGE content ignored';
};

# -----------------------------------------------------------------------
# 3. Stateful CLI workflow across runs
#
# Strategy: simulate a maintainer's life cycle in one project directory.
# Each run reads the cpanfile the previous run wrote, so state flows
# between runs through the filesystem:
#   run 1 creates the cpanfile;
#   the maintainer hand-adds develop entries;
#   run 2 must keep them, still add the default tools, and not duplicate;
#   run 3 (no changes) must be byte-identical to run 2 (idempotence);
#   --dry-run and --diff must report without touching the file.
# -----------------------------------------------------------------------
subtest 'CLI: create, hand-edit, regenerate, preview' => sub {
	my $dir  = make_project($MF_FULL);
	my $home = make_home();
	my $cpanfile = $dir->child($CFG{cpanfile});

	# Run 1: fresh project.
	my ($out, $err, $exit) = run_cli($dir, $home);
	is $exit, 0, 'run 1: exit status 0';
	is $out, "$CFG{msg_written}\n", 'run 1: confirmation printed';
	ok $cpanfile->is_file, 'run 1: cpanfile created';

	# The CLI must produce exactly what the library produces for the same
	# inputs - it is documented as a thin wrapper around generate().
	{
		my $g = use_home($home);
		is $cpanfile->slurp_utf8,
			App::makefilepl2cpanfile::generate(makefile => $dir->child($CFG{makefile})->stringify),
			'run 1: CLI output identical to generate()';
	}

	# Hand edit: pin a default tool and add a private one.
	my $edited = $cpanfile->slurp_utf8;
	$edited =~ s/^\trequires 'Perl::Critic';$/\trequires 'Perl::Critic', '1.140';\n\trecommends 'My::Linter';/m
		or BAIL_OUT('fixture edit failed');
	$cpanfile->spew_utf8($edited);

	# Run 2: the hand edits survive; defaults are not duplicated.
	($out, $err, $exit) = run_cli($dir, $home);
	is $exit, 0, 'run 2: exit status 0';
	my $run2 = $cpanfile->slurp_utf8;
	like $run2, qr/^\trequires 'Perl::Critic', '1\.140';$/m, 'run 2: pinned version kept';
	like $run2, qr/^\trecommends 'My::Linter';$/m,           'run 2: private tool kept';
	my @critic = $run2 =~ /Perl::Critic/g;
	is scalar @critic, 1, 'run 2: Perl::Critic not duplicated';
	like $run2, qr/^\trequires '\Q$_\E';$/m, "run 2: default $_ still present"
		for grep { $_ ne 'Perl::Critic' } @DEFAULT_DEV_TOOLS;

	# Run 3: nothing changed, so nothing may change.
	run_cli($dir, $home);
	is $cpanfile->slurp_utf8, $run2, 'run 3: regeneration is idempotent';

	# Preview modes: report, never write.
	my $mtime = $cpanfile->stat->mtime;
	$dir->child($CFG{makefile})->spew_utf8($MF_FULL =~ s/'Try::Tiny' => 0,/'Try::Tiny' => 0,\n\t\t'New::Dep' => 0,/r);

	($out, $err, $exit) = run_cli($dir, $home, '--dry-run');
	is $exit, 0, '--dry-run: exit status 0';
	like $out, qr/^requires 'New::Dep';$/m, '--dry-run: new dependency printed';
	like $out, qr/^\trecommends 'My::Linter';$/m, '--dry-run: hand edits included';

	($out, $err, $exit) = run_cli($dir, $home, '--diff');
	is $exit, 0, '--diff: exit status 0';
	like $out, qr/^\+requires 'New::Dep';$/m, '--diff: new dependency shown as an addition';
	unlike $out, qr/^[-+]\trecommends 'My::Linter'/m, '--diff: unchanged hand edit not in the diff';

	is $cpanfile->slurp_utf8, $run2, 'preview modes left the cpanfile untouched';
	is $cpanfile->stat->mtime, $mtime, 'and did not rewrite it';
};

# -----------------------------------------------------------------------
# 4. --diff with no existing cpanfile
#
# Strategy: a preview option must never write, even when there is nothing
# to diff against; every generated line should appear as an addition.
# -----------------------------------------------------------------------
subtest 'CLI: --diff without an existing cpanfile writes nothing' => sub {
	my $dir  = make_project($MF_FULL);
	my ($out, $err, $exit) = run_cli($dir, make_home(), '--diff', '--no-develop');
	is $exit, 0, 'exit status 0';
	like $out, qr/^\+\Q$CFG{header}\E$/m, 'header shown as an addition';
	like $out, qr/^\+requires 'Moo', '2\.000';/m, 'dependencies shown as additions';
	ok !$dir->child($CFG{cpanfile})->exists, 'no cpanfile written';
};

# -----------------------------------------------------------------------
# 5. CLI option handling
#
# Strategy: each option's documented effect on what generate() receives,
# observed through the written output, plus the documented error and the
# help exit.
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# --check exit status
#
# Strategy: --check exists to catch dependencies the conversion lost.  A
# wrapper makes generation drop one module; the run must name it and exit
# with status 1 so that CI fails, whatever output mode was chosen.
# -----------------------------------------------------------------------
subtest 'CLI: --check exits 1 when a module is missing' => sub {
	my $wrapper = path(tempdir(CLEANUP => 1))->child('drop.pl');
	$wrapper->spew_utf8(<<'END_PERL');
use App::makefilepl2cpanfile;
use Test::Mockingbird;
Test::Mockingbird::around('App::makefilepl2cpanfile::_emit', sub {
	my ($orig, @args) = @_;
	return $orig->(@args) =~ s/^requires 'Moo'.*\n//mr;
});
do $ARGV[0];
die $@ if $@;
END_PERL
	for my $mode ([], ['--dry-run'], ['--diff']) {
		my $dir = make_project($MF_FULL);
		my $cwd = Path::Tiny->cwd;
		local $ENV{HOME} = make_home()->stringify;
		chdir $dir or die "chdir: $!";
		my ($out, $err, $exit) = capture { system $^X, "-I$LIB", "$wrapper", $BIN, '--check', '--no-develop', @{$mode} };
		chdir $cwd or die "chdir: $!";
		s/\r\n/\n/g for $out, $err;
		my $name = @{$mode} ? "@{$mode}" : 'write';
		is $exit >> 8, 1, "$name: exit status 1";
		like $err, qr/^  Moo$/m, "$name: the missing module is named";
	}
	my ($out, $err, $exit) = run_cli(make_project($MF_FULL), make_home(), '--check', '--no-develop');
	is $exit, 0, 'nothing missing: exit status 0';
};

subtest 'CLI: option handling' => sub {
	my $home = make_home({ develop => { 'Configured::Tool' => '2.0' } });

	{
		my $dir = make_project($MF_FULL);
		run_cli($dir, $home, '--no-develop');
		unlike $dir->child($CFG{cpanfile})->slurp_utf8, qr/on 'develop'/,
			'--no-develop: no develop block';
	}
	{
		my $dir = make_project($MF_FULL);
		run_cli($dir, $home, '--with-develop');
		like $dir->child($CFG{cpanfile})->slurp_utf8, qr/^\trequires 'Configured::Tool', '2\.0';$/m,
			'--with-develop: tools from the config in $HOME';
	}
	{
		my $dir = make_project($MF_FULL);
		my ($out, $err, $exit) = run_cli($dir, $home, '--with-develop', '--no-develop');
		isnt $exit, 0, 'conflicting options: non-zero exit';
		like $err, qr/^\Q$CFG{msg_exclusive}\E$/m, 'conflicting options: documented message';
		ok !$dir->child($CFG{cpanfile})->exists, 'conflicting options: nothing written';
	}
	{
		my $dir = make_project($MF_FULL);
		my ($out, $err, $exit) = run_cli($dir, $home, '--help');
		is $exit, 0, '--help: exit status 0';
		like $out, qr/\Q$CFG{msg_usage}\E/, '--help: usage printed';
		ok !$dir->child($CFG{cpanfile})->exists, '--help: nothing written';
	}
};

# -----------------------------------------------------------------------
# 6. Which collaborators generate() uses, and with what
#
# Strategy: spies record calls while the real code runs.  They confirm the
# documented side effects: the Makefile.PL is read once, parse_prereqs()
# receives its content, and the config is consulted only when with_develop
# is true - and then from the documented path.
# -----------------------------------------------------------------------
subtest 'collaborators: generate() reads what the POD says it reads' => sub {
	my $home = make_home({ develop => { 'Spy::Tool' => 0 } });
	my $g    = use_home($home);
	my $dir  = make_project($MF_FULL);
	my $mf   = $dir->child($CFG{makefile})->stringify;
	my $cfg  = $home->child($CFG{cfg_dir}, $CFG{cfg_file})->stringify;

	my %spy = map { $_ => spy($_) } qw(
		App::makefilepl2cpanfile::parse_prereqs
		Path::Tiny::slurp_utf8
		YAML::Tiny::read
	);

	App::makefilepl2cpanfile::generate(makefile => $mf, with_develop => 1);

	my @parse = $spy{'App::makefilepl2cpanfile::parse_prereqs'}->();
	is scalar @parse, 1, 'parse_prereqs called once';
	is $parse[0][1], $MF_FULL, 'with the Makefile.PL content';

	my @slurp = $spy{'Path::Tiny::slurp_utf8'}->();
	is scalar @slurp, 1, 'Makefile.PL read once';
	is "$slurp[0][1]", $mf, 'from the requested path';

	my @yaml = $spy{'YAML::Tiny::read'}->();
	is scalar @yaml, 1, 'config read once when with_develop is true';
	is $yaml[0][2], $cfg, 'from ~/.config/makefilepl2cpanfile.yml';

	# Spies accumulate; a with_develop => 0 call must add no config read.
	App::makefilepl2cpanfile::generate(makefile => $mf, with_develop => 0);
	is scalar(my @after = $spy{'YAML::Tiny::read'}->()), 1,
		'config not read when with_develop is false';

	restore($_) for keys %spy;
};

# -----------------------------------------------------------------------
# 7. Independence of interleaved calls in one process
#
# Strategy: alternate calls with different Makefile.PLs, homes and configs.
# If any state (a cached config, a regex position, a shared hash) leaked
# between calls, a repeat call would differ from its first result.
# -----------------------------------------------------------------------
subtest 'independence: interleaved calls with different inputs' => sub {
	my %jobs = (
		full_default   => [ $MF_FULL,   make_home() ],
		full_config    => [ $MF_FULL,   make_home({ develop => { 'Only::Here' => 0 } }) ],
		legacy_config  => [ $MF_LEGACY, make_home({ develop => { 'Legacy::Tool' => '1.0' } }) ],
	);

	my $run = sub {
		my ($content, $home) = @{ $jobs{ $_[0] } };
		my $g = use_home($home);
		return App::makefilepl2cpanfile::generate(
			makefile => make_project($content)->child($CFG{makefile})->stringify,
		);
	};

	my %first = map { $_ => $run->($_) } sort keys %jobs;
	for my $name (reverse sort keys %jobs) {
		is $run->($name), $first{$name}, "$name: repeat call identical after the others ran";
	}

	unlike $first{full_default},  qr/Only::Here|Legacy::Tool/, 'no config leaked into the default run';
	like   $first{full_config},   qr/Only::Here/,              'own config used';
	unlike $first{full_config},   qr/Legacy::Tool|Perl::Critic/, 'no other config or defaults leaked';
	like   $first{legacy_config}, qr/^\trequires 'Legacy::Tool', '1\.0';$/m, 'own config used';

	# parse_prereqs() is pure: the same input always yields the same result.
	my $a1 = App::makefilepl2cpanfile::parse_prereqs($MF_FULL);
	my $b1 = App::makefilepl2cpanfile::parse_prereqs($MF_LEGACY);
	is_deeply App::makefilepl2cpanfile::parse_prereqs($MF_FULL),   $a1, 'parse_prereqs repeatable (A)';
	is_deeply App::makefilepl2cpanfile::parse_prereqs($MF_LEGACY), $b1, 'parse_prereqs repeatable (B)';
};

# -----------------------------------------------------------------------
# 8. Concurrent CLI runs
#
# Strategy: start several CLI processes at once, each in its own project
# with its own HOME and config, before waiting for any of them.  Each
# must write only its own cpanfile, containing only its own tool.
# -----------------------------------------------------------------------
subtest 'concurrency: parallel CLI runs do not interfere' => sub {
	my @jobs = map {
		my $n = $_;
		{
			n    => $n,
			dir  => make_project($MF_FULL =~ s/'Try::Tiny' => 0,/'Try::Tiny' => 0,\n\t\t'Only::In::$n' => 0,/r),
			home => make_home({ develop => { "Tool::For::$n" => 0 } }),
		}
	} 1 .. $CFG{parallel_runs};

	# Launch all before reaping any.  open3 is used rather than fork+exec
	# because it works on Windows too, where fork is emulated with threads
	# and reopening STDOUT in the child would redirect the parent's as well.
	# Each child inherits the working directory and HOME in force at the
	# moment it is spawned.
	my $cwd = Path::Tiny->cwd;
	for my $job (@jobs) {
		local $ENV{HOME} = "$job->{home}";
		chdir $job->{dir} or die "chdir $job->{dir}: $!";
		$job->{pid} = open3(my $stdin, my $output, undef, cli_command([]));
		close $stdin;
		$job->{output} = $output;
		chdir $cwd or die "chdir $cwd: $!";
	}
	for my $job (@jobs) {
		my $text = do { local $/; readline $job->{output} };
		waitpid $job->{pid}, 0;
		is $? >> 8, 0, "run $job->{n}: exit status 0" or diag $text;
	}

	for my $job (@jobs) {
		my $text = $job->{dir}->child($CFG{cpanfile})->slurp_utf8;
		my @tools  = $text =~ /Tool::For::(\d+)/g;
		my @unique = $text =~ /Only::In::(\d+)/g;
		is_deeply \@tools,  [ $job->{n} ], "run $job->{n}: only its own config tool";
		is_deeply \@unique, [ $job->{n} ], "run $job->{n}: only its own dependency";
	}
};

# -----------------------------------------------------------------------
# 9. Optional UTF-8 decoders
#
# Strategy: Path::Tiny uses Unicode::UTF8 and/or PerlIO::utf8_strict when
# installed, else the :encoding layer, and each reacts differently to
# invalid UTF-8 (a lenient warning, or an exception that generate()
# catches and turns into a raw-byte re-read).  The POD promises the same
# outcome in every case: a warning, never an exception, and the complete
# dependency list.  Run the CLI with every combination of the optional
# modules hidden and compare against a valid-UTF-8 baseline.
# -----------------------------------------------------------------------
subtest 'optional dependencies: invalid UTF-8 under every decoder combination' => sub {
	my $home = make_home();
	my $baseline = do {
		my $clean = $MF_BAD_UTF8 =~ s/[\x80-\xff]+//gr;
		my ($out) = run_cli(make_project($clean), $home, '--dry-run', '--no-develop');
		$out;
	};
	like $baseline, qr/^requires 'Raw::Mod';$/m, 'baseline parsed';

	for my $hidden (all_subsets(@OPTIONAL_DECODERS)) {
		my $label = @{$hidden} ? 'without ' . join(', ', @{$hidden}) : 'with all decoders available';
		SKIP: {
			my @missing = grep { my $m = $_; !eval "require $m; 1" } @OPTIONAL_DECODERS;
			my %hidden = map { $_ => 1 } @{$hidden};
			skip "$label: @missing not installed, so this combination cannot be simulated", 3
				if grep { !$hidden{$_} } @missing;

			my ($out, $err, $exit) = run_cli(make_project($MF_BAD_UTF8), $home,
				$hidden, '--dry-run', '--no-develop');
			is $exit, 0, "$label: exit status 0 (no exception)";
			like $err, $CFG{msg_bad_utf8}, "$label: invalid UTF-8 reported as a warning";
			is_deeply [ $out =~ /^requires '([^']+)'/mg ], [ $baseline =~ /^requires '([^']+)'/mg ],
				"$label: same dependencies as the valid-UTF-8 baseline";
		}
	}
};

# -----------------------------------------------------------------------
# 10. Hidden hard dependencies fail loudly
#
# Strategy: the runtime dependencies are mandatory; hiding one must stop
# the tool with a "Can't locate" error rather than let it run degraded
# and write an incomplete cpanfile.
# -----------------------------------------------------------------------
subtest 'hard dependencies: a missing one stops the tool before writing' => sub {
	for my $module (qw(YAML::Tiny Params::Get File::HomeDir)) {
		my $dir = make_project($MF_FULL);
		my ($out, $err, $exit) = run_cli($dir, make_home(), [$module]);
		isnt $exit, 0, "without $module: non-zero exit";
		my $file = join('/', split /::/, $module) . '.pm';
		like $err, qr/Can't locate \Q$file\E/, "without $module: reported";
		ok !$dir->child($CFG{cpanfile})->exists, "without $module: nothing written";
	}
};

done_testing;
