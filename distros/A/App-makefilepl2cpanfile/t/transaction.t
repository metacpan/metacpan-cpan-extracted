use strict;
use warnings;

# Transaction-flow tests.  The tool has no database: its transaction is a
# command-line run that turns Makefile.PL (plus the user's configuration
# and any existing cpanfile) into a cpanfile on disk:
#
#   read Makefile.PL -> read existing cpanfile -> load config -> generate
#     -> create temporary file -> write it -> rename it over cpanfile
#
# The commit point is the final rename.  Every step before it must be
# undoable: whatever fails, the project directory must afterwards hold
# exactly what it held before - the old cpanfile byte for byte, and no
# temporary files.  A later run must then succeed normally.
#
# Each subtest is one phase of a cpanfile's life: create, preview, update,
# repeat (idempotency), and failure at every step with recovery.
# Failures are injected in the child process by a small wrapper script
# that installs Test::Mockingbird mocks before loading the CLI.

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Capture::Tiny ();
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Path::Tiny;
use POSIX qw(EIO ENOSPC);
use Readonly;
use YAML::Tiny;

use App::makefilepl2cpanfile;

Readonly my %CFG => (
	makefile   => 'Makefile.PL',
	cpanfile   => 'cpanfile',
	written    => 'cpanfile written successfully.',
	all_found  => 'All Makefile.PL prerequisites are present in the output.',
	repeats    => 5,
	fd_dir     => '/proc/self/fd',
	full_dev   => '/dev/full',
);

Readonly my $LIB => path($Bin)->parent->child('lib')->absolute->stringify;
Readonly my $BIN => path($Bin)->parent->child('bin', 'makefilepl2cpanfile')->absolute->stringify;

Readonly my $MSG_EIO    => do { local $! = EIO;    "$!" };
Readonly my $MSG_ENOSPC => do { local $! = ENOSPC; "$!" };

Readonly my $MF_V1 => <<'END_MF';
WriteMakefile(
	MIN_PERL_VERSION => '5.010',
	PREREQ_PM     => { 'Moo' => '2.0', 'Try::Tiny' => 0 },
	TEST_REQUIRES => { 'Test::More' => 0 },
);
END_MF

# Version 2: one dependency bumped, one added, one removed.
Readonly my $MF_V2 => <<'END_MF';
WriteMakefile(
	MIN_PERL_VERSION => '5.010',
	PREREQ_PM     => { 'Moo' => '2.5', 'JSON::PP' => 0 },
	TEST_REQUIRES => { 'Test::More' => 0 },
);
END_MF

# One wrapper per injected failure.  Each installs its mock and then runs
# the real CLI.  (Written to files: Windows cannot pass a multi-line -e.)
Readonly my %FAULT => (
	'read Makefile.PL' => <<'END_PERL',
Test::Mockingbird::around('Path::Tiny::slurp_utf8', sub {
	my ($orig, $self, @args) = @_;
	if ($self->basename eq 'Makefile.PL') { local $! = POSIX::EIO(); die "Error read: $!\n" }
	return $orig->($self, @args);
});
END_PERL
	'generate' => <<'END_PERL',
Test::Mockingbird::mock('App::makefilepl2cpanfile::_emit', sub { die "generation failed\n" });
END_PERL
	'create temporary file' => <<'END_PERL',
Test::Mockingbird::mock('Path::Tiny::tempfile', sub { local $! = POSIX::ENOSPC(); die "Error tempfile: $!\n" });
END_PERL
	'write (disk full)' => <<'END_PERL',
Test::Mockingbird::around('Path::Tiny::filehandle', sub {
	my ($orig, $self, @args) = @_;
	my $fh = $orig->($self, @args);
	return $fh unless $self->basename =~ /\A\.cpanfile-/;
	open my $full, '>', '/dev/full' or die "open /dev/full: $!";
	return $full;
});
END_PERL
	'rename' => <<'END_PERL',
Test::Mockingbird::mock('Path::Tiny::move', sub { local $! = POSIX::EIO(); die "Error move: $!\n" });
END_PERL
);

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

sub make_project {
	my $dir = path(tempdir(CLEANUP => 1));
	$dir->child($CFG{makefile})->spew_utf8($_[0]);
	return $dir;
}

sub make_home {
	my $data = $_[0];
	my $home = path(tempdir(CLEANUP => 1));
	if(defined $data) {
		my $cfg = $home->child('.config', 'makefilepl2cpanfile.yml');
		$cfg->parent->mkpath;
		ref $data ? YAML::Tiny->new($data)->write("$cfg") : $cfg->spew_utf8($data);
	}
	return $home;
}

# Runs the CLI in $dir.  $fault names an entry of %FAULT, or is undef.
sub run_cli {
	my ($dir, $home, $fault, @args) = @_;
	my @perl = ($^X, "-I$LIB");
	if(defined $fault) {
		my $wrapper = path(tempdir(CLEANUP => 1))->child('fault.pl');
		# Load everything a mock replaces first: loading a module after its
		# function is mocked would put the real function back.
		$wrapper->spew_utf8("use App::makefilepl2cpanfile;\nuse Path::Tiny;\nuse POSIX ();\nuse Test::Mockingbird;\n$FAULT{$fault}do \$ARGV[0];\ndie \$@ if \$@;\n");
		push @perl, "$wrapper";
	}
	my $cwd = Path::Tiny->cwd;
	local $ENV{HOME} = "$home";
	chdir $dir or die "chdir $dir: $!";
	my ($out, $err, $exit) = Capture::Tiny::capture(sub { system @perl, $BIN, @args });
	chdir $cwd or die "chdir $cwd: $!";
	s/\r\n/\n/g for $out, $err;
	diag "run @args (fault: " . ($fault // 'none') . ")\nSTDOUT: $out\nSTDERR: $err" if $ENV{TEST_VERBOSE};
	return ($out, $err, $exit >> 8);
}

# Everything in the project directory: name => content.  Comparing two of
# these proves nothing was added, removed or changed.
sub snapshot {
	my $dir = $_[0];
	return { map { $_->basename => $_->slurp_raw } grep { $_->is_file } $dir->children };
}

sub cpanfile_text { return $_[0]->child($CFG{cpanfile})->slurp_utf8 }

# The cpanfile as Module::CPANfile (and so cpanm) sees it.
sub cpanfile_specs {
	require Module::CPANfile;
	return Module::CPANfile->load($_[0]->child($CFG{cpanfile})->stringify)->prereq_specs;
}

# -----------------------------------------------------------------------
# Phase 1: create
#
# A project with no cpanfile.  The run must commit exactly one new file,
# equal to what the library produces, readable by Module::CPANfile, and
# after which a --diff reports nothing left to change.
# -----------------------------------------------------------------------
subtest 'phase 1: create a cpanfile' => sub {
	my $dir  = make_project($MF_V1);
	my $home = make_home();
	my $before = snapshot($dir);

	my ($out, $err, $exit) = run_cli($dir, $home, undef, '--no-develop', '--check');
	is $exit, 0, 'run succeeds';
	like $out, qr/^\Q$CFG{all_found}\E$/m, 'check: every dependency present';
	like $out, qr/^\Q$CFG{written}\E$/m, 'commit reported';

	my $after = snapshot($dir);
	is_deeply [ sort keys %{$after} ], [ sort(keys %{$before}, $CFG{cpanfile}) ], 'exactly one file added';
	is $after->{ $CFG{makefile} }, $before->{ $CFG{makefile} }, 'Makefile.PL untouched';

	my $text = cpanfile_text($dir);
	returns_is($text, { type => 'string', matches => qr/\A# Generated from Makefile\.PL/ }, 'cpanfile has the documented form');
	{
		local $ENV{HOME} = "$home";
		is $text, App::makefilepl2cpanfile::generate(
			makefile => $dir->child($CFG{makefile})->stringify, with_develop => 0,
		), 'committed text equals the library result';
	}
	is_deeply cpanfile_specs($dir)->{runtime}{requires},
		{ perl => '5.010', Moo => '2.0', 'Try::Tiny' => 0 }, 'Module::CPANfile reads the committed state';

	($out) = run_cli($dir, $home, undef, '--no-develop', '--diff');
	is $out, q{}, 'afterwards --diff has nothing to change';
};

# -----------------------------------------------------------------------
# Phase 2: preview
#
# --dry-run, --diff and --check with --dry-run inspect a transaction
# without committing it: the directory must be byte-for-byte unchanged.
# -----------------------------------------------------------------------
subtest 'phase 2: previews never commit' => sub {
	my $dir  = make_project($MF_V1);
	my $home = make_home();
	run_cli($dir, $home, undef, '--no-develop');
	$dir->child($CFG{makefile})->spew_utf8($MF_V2);
	my $before = snapshot($dir);

	for my $args ([ '--dry-run' ], [ '--diff' ], [ '--check', '--dry-run' ]) {
		my ($out, $err, $exit) = run_cli($dir, $home, undef, '--no-develop', @{$args});
		is $exit, 0, "@{$args}: succeeds";
		like $out, qr/JSON::PP/, "@{$args}: shows the pending change";
		is_deeply snapshot($dir), $before, "@{$args}: nothing committed";
	}
};

# -----------------------------------------------------------------------
# Phase 3: update
#
# Hand edits to the develop block and changes to Makefile.PL both flow
# into the next committed state: new and bumped dependencies appear,
# removed ones disappear, and the hand-written entries survive.
# -----------------------------------------------------------------------
subtest 'phase 3: update after hand edits and Makefile.PL changes' => sub {
	my $dir  = make_project($MF_V1);
	my $home = make_home({ develop => { 'Perl::Critic' => 0 } });
	run_cli($dir, $home, undef);

	my $edited = cpanfile_text($dir);
	$edited =~ s/^(on 'develop' => sub \{\n)/$1\trequires 'Hand::Tool', '1.5';\n\trecommends 'Nice::Tool';\n/m
		or BAIL_OUT('fixture edit failed');
	$dir->child($CFG{cpanfile})->spew_utf8($edited);
	$dir->child($CFG{makefile})->spew_utf8($MF_V2);

	my (undef, undef, $exit) = run_cli($dir, $home, undef);
	is $exit, 0, 'update run succeeds';
	my $specs = cpanfile_specs($dir);
	is_deeply $specs->{runtime}{requires}, { perl => '5.010', Moo => '2.5', 'JSON::PP' => 0 },
		'bumped and added dependencies present, removed one gone';
	is_deeply $specs->{develop},
		{ requires => { 'Hand::Tool' => '1.5', 'Perl::Critic' => 0 }, recommends => { 'Nice::Tool' => 0 } },
		'hand-written develop entries survive next to the configured tool';
};

# -----------------------------------------------------------------------
# Phase 4: repeat (idempotency)
#
# Running the same transaction again and again must reproduce the same
# committed state exactly: no duplicated entries, no drift, no debris.
# -----------------------------------------------------------------------
subtest 'phase 4: repeated runs are idempotent' => sub {
	my $dir  = make_project($MF_V1);
	my $home = make_home({ develop => { 'Perl::Critic' => '1.1' } });
	run_cli($dir, $home, undef);
	my $first = snapshot($dir);

	for my $n (2 .. $CFG{repeats}) {
		my (undef, undef, $exit) = run_cli($dir, $home, undef);
		is $exit, 0, "run $n succeeds";
		is_deeply snapshot($dir), $first, "run $n: directory identical to run 1";
	}
	my @critic = cpanfile_text($dir) =~ /Perl::Critic/g;
	is scalar @critic, 1, 'the configured tool appears once after all runs';

	# The library transaction is idempotent too.
	local $ENV{HOME} = "$home";
	my $mf = $dir->child($CFG{makefile})->stringify;
	my $existing = cpanfile_text($dir);
	is App::makefilepl2cpanfile::generate(makefile => $mf, existing => $existing), $existing,
		'feeding the committed cpanfile back in reproduces it exactly';
};

# -----------------------------------------------------------------------
# Phase 5: failure at every step, with rollback and recovery
#
# From an established state, inject a failure at each step of the run.
# Every failure must be reported (non-zero exit, no success message) and
# rolled back completely: the directory, including the previous cpanfile,
# is exactly as before, with no temporary files left.  A clean run
# afterwards must commit normally.
# -----------------------------------------------------------------------
subtest 'phase 5: a failure at any step leaves the previous state intact' => sub {
	my %expect = (
		'read Makefile.PL'      => qr/\Q$MSG_EIO\E/,
		'generate'              => qr/generation failed/,
		'create temporary file' => qr/\Q$MSG_ENOSPC\E/,
		'write (disk full)'     => qr/\Q$MSG_ENOSPC\E/,
		'rename'                => qr/\Q$MSG_EIO\E/,
	);
	for my $step (sort keys %FAULT) {
		SKIP: {
			skip "$CFG{full_dev} not available", 5 if $step =~ /disk full/ && !-e $CFG{full_dev};
			my $dir  = make_project($MF_V1);
			my $home = make_home();
			run_cli($dir, $home, undef, '--no-develop');
			$dir->child($CFG{makefile})->spew_utf8($MF_V2);	# a change the failed run would commit
			my $before = snapshot($dir);

			my ($out, $err, $exit) = run_cli($dir, $home, $step, '--no-develop');
			isnt $exit, 0, "$step: failure reported by the exit status";
			like $err, $expect{$step}, "$step: the cause is reported";
			unlike $out, qr/\Q$CFG{written}\E/, "$step: no success message";
			is_deeply snapshot($dir), $before, "$step: directory unchanged - old cpanfile kept, nothing left behind";

			run_cli($dir, $home, undef, '--no-develop');
			like cpanfile_text($dir), qr/^requires 'JSON::PP';$/m, "$step: a clean run afterwards commits the change";
		}
	}

	# A broken configuration aborts before anything is written.
	my $dir  = make_project($MF_V1);
	my $home = make_home("develop: [\n  x");
	my $before = snapshot($dir);
	my (undef, $err, $exit) = run_cli($dir, $home, undef);
	isnt $exit, 0, 'broken config: failure reported';
	like $err, qr/Failed to parse /, 'broken config: the documented message';
	is_deeply snapshot($dir), $before, 'broken config: nothing written';
};

# -----------------------------------------------------------------------
# Phase 6: failure during the very first run
#
# With no previous cpanfile there is nothing to restore, so a failed
# first run must leave the directory as it found it: no cpanfile and no
# temporary files.
# -----------------------------------------------------------------------
subtest 'phase 6: a failed first run creates nothing' => sub {
	for my $step ('create temporary file', 'write (disk full)', 'rename') {
		SKIP: {
			skip "$CFG{full_dev} not available", 2 if $step =~ /disk full/ && !-e $CFG{full_dev};
			my $dir = make_project($MF_V1);
			my $before = snapshot($dir);
			my (undef, undef, $exit) = run_cli($dir, make_home(), $step, '--no-develop');
			isnt $exit, 0, "$step: failure reported";
			is_deeply snapshot($dir), $before, "$step: no cpanfile and no temporary file";
		}
	}
};

# -----------------------------------------------------------------------
# Phase 7: the library part of the transaction under failure
#
# generate() is the in-process part of the run.  When it fails part way
# (reading, parsing the config, or generating) it must leave the caller's
# arguments untouched and release every file handle it opened.
# -----------------------------------------------------------------------
subtest 'phase 7: library failures leave no partial state and no open handles' => sub {
	my $dir = make_project($MF_V1);
	my $mf  = $dir->child($CFG{makefile})->stringify;
	my $count_fds = sub {
		opendir my $dh, $CFG{fd_dir} or return;
		my $n = grep { /\A\d+\z/ } readdir $dh;
		closedir $dh;
		return $n;
	};

	my %failures = (
		'read'     => sub { mock_scoped 'Path::Tiny::slurp_utf8' => sub { local $! = EIO; die "Error read: $!\n" } },
		'config'   => sub { mock_scoped 'YAML::Tiny::read' => sub { die "config unreadable\n" } },
		'generate' => sub { mock_scoped 'App::makefilepl2cpanfile::_emit' => sub { die "generation failed\n" } },
	);
	my $home = make_home({ develop => { 'Tool' => 0 } });
	my $g = mock_scoped 'File::HomeDir::my_home' => sub { "$home" };
	for my $name (sort keys %failures) {
		my %args = (makefile => $mf, existing => "on 'develop' => sub {\n\trequires 'X';\n};\n");
		my %copy = %args;
		my $fds  = $count_fds->();
		{
			my $m = $failures{$name}->();
			my $ok = eval { App::makefilepl2cpanfile::generate(\%args); 1 };
			ok !$ok, "$name: the failure reaches the caller";
		}
		is_deeply \%args, \%copy, "$name: arguments unchanged";
		SKIP: {
			skip "$CFG{fd_dir} not available", 1 unless defined $fds;
			is $count_fds->(), $fds, "$name: no file handles left open";
		}
	}
};

done_testing;
