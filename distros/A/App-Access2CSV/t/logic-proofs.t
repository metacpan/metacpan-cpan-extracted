#!perl

# Logic proofs: one test per outcome of each decision in the code, and a
# test for the ORDER of decisions wherever the order matters.  No two
# tests cover the same outcome of the same decision.
#
# Each subtest states its premises and conclusion in plain words:
#	Premise 1 - a rule of the system (from the POD / Z specification)
#	Premise 2 - the situation set up by the test
#	Conclusion - what must therefore happen, which the test asserts
#
# Set TEST_VERBOSE=1 to see internal state.

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'uses Unix stand-in programs') if $^O eq 'MSWin32';
}

use Capture::Tiny qw(capture);
use Errno qw(ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Test::Mockingbird;

use lib File::Spec->catdir($Bin, 'lib');
use FakeMDB qw(install_fake_mdbtools make_database);

use App::Access2CSV;

delete @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)};

Readonly::Hash my %CONFIG => (
	app          => 'App::Access2CSV',
	exporter     => 'App::Access2CSV::Exporter',
	i18n         => 'App::Access2CSV::I18N',
	exit_ok      => 0,
	exit_failure => 1,
	exit_usage   => 2,
	exit_fatal   => 3,
	signal       => 9,
	core_flag    => 128,
	exit_code    => 1,
);

Readonly::Scalar my $ENOENT_TEXT => do { local $! = ENOENT; "$!" };

local $ENV{PATH} = join(':', install_fake_mdbtools(), $ENV{PATH});

sub verbose_diag {
	my ($label, $data) = @_;
	diag("$label: ", Test::More::explain($data)) if $ENV{TEST_VERBOSE};
	return;
}

sub new_database {
	my $dir = tempdir(CLEANUP => 1);
	return ($dir, make_database($dir, @_));
}

sub cli {
	my @argv = @_;
	my $status;
	my ($stdout, $stderr) = capture { $status = $CONFIG{app}->run(@argv) };
	return ($status, $stderr);
}

# Number of calls recorded by a Test::Mockingbird spy whose first argument matches
sub calls_matching {
	my ($spy, $pattern) = @_;
	return scalar grep { my @call = @{$_}; grep({ defined && !ref && /$pattern/ } @call[1 .. $#call]) } $spy->();
}

#######################################################################
# App::Access2CSV: the command-line gates, in order
#######################################################################

subtest 'gate order: bad option > help > database count' => sub {
	# Premise 1: _parse_options checks, in this order, (a) the options
	# parsed, (b) help was asked for, (c) exactly one non-empty name.
	# Premise 2: each case below makes two gates true at once.
	# Conclusion: the earlier gate decides the exit status.
	my ($status) = cli('--help', '--bogus');
	is($status, $CONFIG{exit_usage}, '(a) beats (b): bad option wins over --help');

	($status) = cli('--help');
	is($status, $CONFIG{exit_ok}, '(b) beats (c): --help needs no database');

	($status) = cli('--help', 'a', 'b');
	is($status, $CONFIG{exit_ok}, '(b) beats (c): --help ignores two databases');
};

subtest 'gate (c): exactly one non-empty name' => sub {
	# Premise 1: length("") is 0 and undef is turned into "" first.
	# Premise 2: "0" has length 1.
	# Conclusion: "", undef, none and two are refused; "0" is a name.
	my %cases = (
		'no name'  => [[], $CONFIG{exit_usage}],
		'empty'    => [[''], $CONFIG{exit_usage}],
		'undef'    => [[undef], $CONFIG{exit_usage}],
		'two'      => [['a', 'b'], $CONFIG{exit_usage}],
		'"0"'      => [['0'], $CONFIG{exit_fatal}],   # a name: gets as far as "not found"
	);
	foreach my $case (sort keys %cases) {
		my ($argv, $expected) = @{ $cases{$case} };
		my ($status) = cli('--no-log', @{$argv});
		is($status, $expected, $case);
	}
};

#######################################################################
# App::Access2CSV::Exporter::run: fail fast, in order
#######################################################################

subtest 'fail-fast order: database > programs > tables > folder' => sub {
	# Premise 1: run() checks the database, then finds the programs, then
	# lists the tables, then makes the folder.
	# Premise 2: each case makes one step fail.
	# Conclusion: no later step runs at all.
	my ($dir, $db) = new_database('T');
	my $out = "$dir/out";
	my $which = spy("$CONFIG{exporter}::which");
	my $run3 = spy("$CONFIG{exporter}::run3");
	my $mkdir = spy("$CONFIG{exporter}::make_path");
	my $e = $CONFIG{exporter}->new(output_dir => $out, progress => 0);

	throws_ok { $e->run("$dir/missing") } qr/\ACannot read database /, 'step 1 fails';
	is(scalar($which->()), 0, '... so no program was looked up');

	{
		local $ENV{PATH} = install_fake_mdbtools('mdb-tables');
		throws_ok { $e->run($db) } qr/\ARequired program not found in PATH: mdb-export /, 'step 2 fails';
	}
	is(scalar($run3->()), 0, '... so no program was run');

	my ($bad_dir, $bad_db) = new_database('FAIL');
	throws_ok { $e->run($bad_db) } qr/\Amdb-tables failed /, 'step 3 fails';
	is(scalar($mkdir->()), 0, '... so no folder was made');
	ok(!-e $out, '... and none exists');

	restore_all();
};

subtest 'dry run always succeeds and never makes the folder' => sub {
	# Premise 1: a dry run returns before mkdir and exports nothing.
	# Premise 2: a table that would fail to export is present.
	# Conclusion: status 0, and make_path is never called.
	my ($dir, $db) = new_database('Broken');
	my $mkdir = spy("$CONFIG{exporter}::make_path");
	my $status;
	capture { $status = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, dry_run => 1)->run($db) };
	is($status, $CONFIG{exit_ok}, 'status 0 despite a broken table');
	is(scalar($mkdir->()), 0, 'no mkdir');
	restore_all();
};

subtest 'post-condition: status is 1 if and only if some table failed' => sub {
	# Z: status! = (if failed = {} then 0 else 1).  Two rows prove it.
	my ($dir, $db) = new_database('A', 'Broken');
	my %rows = ('failed = {}' => [['A'], $CONFIG{exit_ok}], 'failed /= {}' => [['A', 'Broken'], $CONFIG{exit_failure}]);
	foreach my $row (sort keys %rows) {
		my ($tables, $expected) = @{ $rows{$row} };
		my $status;
		capture { $status = $CONFIG{exporter}->new(output_dir => "$dir/$expected", progress => 0, tables => $tables)->run($db) };
		is($status, $expected, $row);
	}
};

#######################################################################
# _run_program: the exit status gates, in order
#######################################################################

subtest 'status gates: -1 > signal > exit code > success' => sub {
	# Premise 1: $? == -1 means "never started", and -1 & 127 == 127.
	# Premise 2: so a signal test done first would report "signal 127".
	# Conclusion: -1 must be tested first.  The rest follow the usual
	# layout of $?: low 7 bits signal, 128 core flag, high byte exit code.
	my ($dir, $db) = new_database('T');
	my %cases = (
		'-1'             => [-1, qr/\Amdb-tables could not be run: \Q$ENOENT_TEXT\E /],
		'signal'         => [$CONFIG{signal}, qr/\Amdb-tables was killed by signal $CONFIG{signal} /],
		'signal + core'  => [$CONFIG{signal} | $CONFIG{core_flag}, qr/\Amdb-tables was killed by signal $CONFIG{signal} /],
		'exit code'      => [$CONFIG{exit_code} << 8, qr/\Amdb-tables failed with exit status $CONFIG{exit_code}: /],
	);
	foreach my $case (sort keys %cases) {
		my ($status, $message) = @{ $cases{$case} };
		my $guard = mock_scoped("$CONFIG{exporter}::run3" => sub { ${ $_[3] } = ''; $! = ENOENT; $? = $status; return 1 });
		throws_ok { $CONFIG{exporter}->new(progress => 0, dry_run => 1)->run($db) } $message, "\$? = $status: $case";
	}

	my $guard = mock_scoped("$CONFIG{exporter}::run3" => sub { ${ $_[2] } = "T\n" if ref($_[2]) eq 'SCALAR'; ${ $_[3] } = ''; $? = 0; return 1 });
	my $status;
	capture { $status = $CONFIG{exporter}->new(progress => 0, dry_run => 1)->run($db) };
	is($status, $CONFIG{exit_ok}, '$? = 0: success');
};

#######################################################################
# Row counts: one branch decides "store" or "switch off"
#######################################################################

subtest 'show_counts gate: off | on and found | on and missing' => sub {
	# Premise 1: mdb-count is only looked for when counts are wanted.
	# Premise 2: _find_program returns a path or false.
	# Conclusion: three outcomes, and the program table never holds a
	# false entry for mdb-count.
	my ($dir, $db) = new_database('T');
	my $which = spy("$CONFIG{exporter}::which");

	my $off = $CONFIG{exporter}->new(progress => 0, dry_run => 1);
	capture { $off->run($db) };
	is(calls_matching($which, qr/\Amdb-count\z/), 0, 'off: never looked for');
	ok(!exists $off->{programs}{'mdb-count'}, 'off: not stored');
	restore_all();

	my $found = $CONFIG{exporter}->new(progress => 0, dry_run => 1, show_counts => 1);
	capture { $found->run($db) };
	ok($found->{programs}{'mdb-count'}, 'on and found: stored');
	is($found->{show_counts}, 1, 'on and found: still on');

	local $ENV{PATH} = install_fake_mdbtools(qw(mdb-tables mdb-export));
	my $missing = $CONFIG{exporter}->new(progress => 0, dry_run => 1, show_counts => 1);
	capture { $missing->run($db) };
	ok(!exists $missing->{programs}{'mdb-count'}, 'on and missing: no entry at all (not even a false one)');
	is($missing->{show_counts}, 0, 'on and missing: switched off');
};

#######################################################################
# Existing files: the overwrite truth table
#######################################################################

subtest 'overwrite x exists: all four rows' => sub {
	# Premise 1: a table is refused only when overwrite is off AND the
	# name exists.  Premise 2: AND is false as soon as one side is false.
	# Conclusion: the four rows of the truth table give refuse only once.
	my %rows = (
		'overwrite off, exists'  => [0, 1, $CONFIG{exit_failure}],
		'overwrite off, absent'  => [0, 0, $CONFIG{exit_ok}],
		'overwrite on, exists'   => [1, 1, $CONFIG{exit_ok}],
		'overwrite on, absent'   => [1, 0, $CONFIG{exit_ok}],
	);
	foreach my $row (sort keys %rows) {
		my ($overwrite, $exists, $expected) = @{ $rows{$row} };
		my ($dir, $db) = new_database('T');
		mkdir "$dir/out" or die $!;
		if($exists) {
			open my $fh, '>', "$dir/out/T.csv" or die $!;
			close $fh;
		}
		my $status;
		capture { $status = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, overwrite => $overwrite)->run($db) };
		is($status, $expected, $row);
	}
};

subtest '"exists" includes symbolic links, even broken ones' => sub {
	# Premise: -e follows links, so a broken link is not -e; -l catches it.
	# Conclusion: "-e OR -l" refuses both kinds of link.
	my ($dir, $db) = new_database('Good', 'Broken_link');
	mkdir "$dir/out" or die $!;
	symlink("$dir/target", "$dir/out/Good.csv") or die $!;
	open my $fh, '>', "$dir/target" or die $!;
	close $fh;
	symlink("$dir/nowhere", "$dir/out/Broken_link.csv") or die $!;

	my ($status, $stderr);
	(undef, $stderr) = capture { $status = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0)->run($db) };
	is($status, $CONFIG{exit_failure}, 'refused');
	is(scalar(() = $stderr =~ /Output file already exists/g), 2, 'both links counted as existing');
};

#######################################################################
# i18n: the narrowing gates
#######################################################################

subtest 'i18n narrowing: context gate, then plural gate' => sub {
	# Premise 1: a matching context is chosen first; plural forms are
	# chosen from whatever is left.  Premise 2: this template has plural
	# forms both inside a context and at the top level.
	# Conclusion: the full truth table of (context matches) x (count is 1).
	local $App::Access2CSV::I18N::MESSAGES{en}{gates} = {
		female => { one => 'F1', other => 'F*' },
		one    => 'N1',
		other  => 'N*',
	};
	my $i18n = $CONFIG{i18n};
	my %rows = (
		'context matches, count 1'    => [{ context => 'female', count => 1 }, 'F1'],
		'context matches, count 2'    => [{ context => 'female', count => 2 }, 'F*'],
		'context differs, count 1'    => [{ context => 'robot', count => 1 }, 'N1'],
		'context differs, count 2'    => [{ context => 'robot', count => 2 }, 'N*'],
		'no context, no count'        => [{}, 'N*'],
	);
	is($i18n->i18n('gates', $rows{$_}[0]), $rows{$_}[1], $_) foreach sort keys %rows;
};

subtest 'i18n fallback gate: translation gap > English > programming error' => sub {
	# Premise 1: English templates are complete.  Premise 2: a template
	# left without a usable form is either a translation gap or a bug.
	# Conclusion: gaps fall back to English; an English gap confesses.
	local $App::Access2CSV::I18N::MESSAGES{de} = { summary => { one => 'eins' } };
	local $App::Access2CSV::I18N::MESSAGES{en}{broken} = { one => 'x' };
	my $i18n = $CONFIG{i18n};
	{
		local $ENV{LANG} = 'de';
		is($i18n->i18n('summary', { params => [2, 0], count => 2 }), 'Processed 2 tables, 0 failed', 'German gap: English');
	}
	throws_ok { $i18n->i18n('broken', { count => 2 }) } qr/\AUnknown message key: broken at .*called at /s, 'English gap: confess, with stack trace';
};

subtest 'i18n params gate: sprintf only when there are values' => sub {
	# Premise: sprintf would read "%" as a format.  Conclusion: with no
	# values the template is returned untouched; with values it is not.
	local $App::Access2CSV::I18N::MESSAGES{en}{pct} = '100%% %s';
	my $i18n = $CONFIG{i18n};
	is($i18n->i18n('pct'), '100%% %s', 'absent: untouched');
	is($i18n->i18n('pct', { params => [] }), '100%% %s', 'empty list: untouched');
	is($i18n->i18n('pct', { params => ['done'] }), '100% done', 'values: formatted');
};

subtest 'language gate: object > first usable variable > English' => sub {
	# Premise 1: an object's language wins; otherwise the first variable
	# that is set, non-empty and not C/POSIX.  Premise 2: an empty first
	# entry in LANGUAGE (":de") is not usable.
	# Conclusion: the search goes on to the next variable.
	local $App::Access2CSV::I18N::MESSAGES{de} = { dry_run_title => 'PROBELAUF' };
	local $App::Access2CSV::I18N::MESSAGES{fr} = { dry_run_title => 'ESSAI' };
	my $i18n = $CONFIG{i18n};
	my %rows = (
		'object beats environment'       => [{ LANG => 'de' }, 'fr', 'ESSAI'],
		'empty object language: env'     => [{ LANG => 'de' }, '', 'PROBELAUF'],
		'first usable variable wins'     => [{ LANGUAGE => 'fr', LANG => 'de' }, undef, 'ESSAI'],
		'C skipped'                      => [{ LC_ALL => 'C', LANG => 'de' }, undef, 'PROBELAUF'],
		'empty LANGUAGE entry skipped'   => [{ LANGUAGE => ':fr', LANG => 'de' }, undef, 'PROBELAUF'],
		'nothing usable: English'        => [{ LC_ALL => 'POSIX' }, undef, 'DRY RUN'],
	);
	foreach my $row (sort keys %rows) {
		my ($env, $language, $expected) = @{ $rows{$row} };
		local @ENV{keys %{$env}} = values %{$env};
		my $who = defined $language ? bless({ language => $language }, $CONFIG{i18n}) : $CONFIG{i18n};
		is($who->i18n('dry_run_title'), $expected, $row);
	}
};

#######################################################################
# System invariant
#######################################################################

subtest 'invariant: file names are unique ignoring case' => sub {
	# Z: forall n1, n2 : used_names . lower(n1) = lower(n2) => n1 = n2.
	# Premise: every name is checked against the lower-case set before use.
	# Conclusion: names differing only in case never share a file.
	my ($dir, $db) = new_database(qw(orders Orders ORDERS oRdErS));
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0);
	capture { $e->run($db) };
	opendir my $dh, "$dir/out" or die $!;
	my @files = grep { /\.csv\z/ } readdir $dh;
	verbose_diag('files', \@files);
	my %lower = map { lc($_) => 1 } @files;
	is(scalar(@files), 4, 'four files');
	is(scalar(keys %lower), 4, 'four different names even ignoring case');
};

done_testing();
