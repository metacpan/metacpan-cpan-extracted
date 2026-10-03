#!perl

# Path-coverage tests: every distinct path through every routine,
# including implicit else branches, early (guard) exits, exception exits
# and loop boundaries (0, 1 and more iterations).
#
# Each path has an ID in %PATHS (routine initials + number) with a short
# description of the route it takes.  A test that drives execution down
# a path calls took('ID'); the last subtest fails if any path was never
# taken.  Collaborators are mocked with Test::Mockingbird so each path is
# reached on purpose, not by chance.
#
# Loop analysis (no loop needs changing):
#	i18n tries         1..2 passes     _lookup catalogs   1..2 passes
#	_verify_deps       always 2 passes (one per required program)
#	_export_all        0..n            _export_transcoded 0..n
#	_csv_filename      0..n            _dry_run           0..n
#
# Dead code: Exporter::run used to test whether Params::Get had returned
# a hash reference.  It always does (or dies), so that test could never
# fail; it has been removed, and the proof that this is safe is kept
# below (DEAD1).

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'uses Unix stand-in programs and permissions') if $^O eq 'MSWin32';
}

use Capture::Tiny qw(capture capture_stderr capture_stdout);
use Errno qw(ENOENT ENOSPC);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Params::Get qw(get_params);
use Readonly;
use Test::Mockingbird;
use Test::Returns;

use lib File::Spec->catdir($Bin, 'lib');
use FakeMDB qw(install_fake_mdbtools make_database);

use App::Access2CSV;

$Sub::Private::BYPASS = 1;
$Sub::Protected::BYPASS = 1;

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
	exit_code    => 2,
	rows         => 7,
	fake_bin     => '/fake/bin',
	utf8_bom     => "\xEF\xBB\xBF",
	max_name_chars => 64,
);

Readonly::Scalar my $ENOENT_TEXT => do { local $! = ENOENT; "$!" };
Readonly::Scalar my $ENOSPC_TEXT => do { local $! = ENOSPC; "$!" };

# Every path, by routine
my %PATHS = (
	# I18N::i18n
	I1 => 'positional form, English, plain template, no params',
	I2 => 'hashref calling form',
	I3 => 'validation fails',
	I4 => 'other language, first try succeeds',
	I5 => 'other language, first try fails, English succeeds',
	I6 => 'English, try fails -> unknown key',
	I7 => 'other language, both tries fail -> unknown key',
	I8 => 'params given -> sprintf',
	CI1 => '_croak_i18n: croaks',
	CA1 => '_carp_i18n: warns, returns self',
	# _language
	L1 => 'object language used',
	L2 => 'environment variable used',
	L3 => 'nothing usable -> English',
	L4 => 'code without catalog -> English',
	# _lookup
	K1 => 'key in the language (first pass returns)',
	K2 => 'key only in English (second pass returns)',
	K3 => 'no catalog for the language (first pass skipped)',
	K4 => 'key nowhere -> unknown key',
	# _narrow
	N1 => 'plain string passes through',
	N2 => 'context form taken',
	N3 => 'plural category form taken',
	N4 => 'category missing -> other',
	N5 => 'no usable form -> undef',
	N6 => 'form is still a reference -> undef',
	# _unknown_key, _plural_category
	U1 => '_unknown_key: catalog message',
	U2 => '_unknown_key: built-in text when the catalog lost it',
	P1 => '_plural_category: known language, count',
	P2 => '_plural_category: unknown language -> English rule',
	P3 => '_plural_category: no count -> other',

	# Exporter::new
	E1 => 'no arguments',
	E2 => 'tables given -> copied',
	E3 => 'undef values dropped',
	E4 => 'validation fails',
	# Exporter::run
	R1 => 'no argument -> Params::Get dies',
	R2 => 'undef database -> missing',
	R3 => 'database check fails',
	R4 => 'dry run exit',
	R5 => 'export, no failures -> 0',
	R6 => 'export, failures -> 1',
	R7 => 'nothing selected -> no output directory, straight to the summary',
	# _check_database
	D1 => 'does not exist', D2 => 'not a regular file', D3 => 'not readable', D4 => 'accepted',
	# _verify_dependencies
	V1 => 'first required program missing',
	V2 => 'second required program missing',
	V3 => 'both found, counts not wanted',
	V4 => 'counts wanted, mdb-count found',
	V5 => 'counts wanted, mdb-count missing',
	# _find_program
	F1 => 'found, verbose -> logged', F2 => 'found, quiet', F3 => 'not found',
	RN1 => '_reset_names',
	# _get_tables, _is_system_table
	G1 => '_get_tables: output', G2 => '_get_tables: no output at all',
	S1 => 'system table', S2 => 'user table',
	# _select_tables
	T1 => 'no filter -> early return', T2 => 'filter, all found', T3 => 'filter, some missing -> warn',
	# _make_output_dir
	M1 => 'exists -> early return', M2 => 'created',
	M3 => 'error for this directory', M4 => 'errors, none for this directory -> last one',
	M5 => 'no errors but no directory -> $!',
	# _export_all
	A1 => 'loop 0 times', A2 => 'loop 1 time, success, progress',
	A3 => 'loop many times, a failure warned', A4 => 'false exception -> "Unknown error"',
	A5 => 'progress off',
	# _export_table
	X1 => 'exists, no overwrite -> croak before any work',
	X2 => 'utf8', X3 => 'utf8-bom', X4 => 'utf8-bom, flush fails -> croak',
	X5 => 'cp1252 -> transcoder', X6 => 'row count logged', X7 => 'plain log',
	X8 => 'row count fails after the file is in place -> warning, still exported',
	# _export_transcoded
	Y1 => 'loop 0 times (no output)', Y2 => 'lines converted',
	Y3 => 'invalid UTF-8 -> croak', Y4 => 'unmappable -> croak',
	# _install_file
	IF1 => 'renamed into place', IF2 => 'rename fails -> croak',
	# _count_rows
	CR1 => 'number', CR2 => 'no output -> croak (not a silent 0)', CR3 => 'not a number -> croak (not a silent 0)',
	# _run_program
	RP1 => '$? -1 -> could not be run', RP2 => 'signal', RP3 => 'exit code', RP4 => 'success',
	# _csv_filename
	CF1 => 'undef name', CF2 => 'reserved device name', CF3 => 'empty after cleaning',
	CF4 => 'collision loop 0 times', CF5 => 'collision loop 1 time', CF6 => 'collision loop many times',
	CF7 => 'character string: no UTF-8 check', CF8 => 'byte string: bytes that are not UTF-8 replaced',
	# _shorten_name
	SN1 => 'fits: unchanged', SN2 => 'too long, UTF-8 bytes: whole graphemes',
	SN3 => 'too long, characters: whole graphemes, still characters',
	# _dry_run
	DR1 => 'no counts, loop 0 times', DR2 => 'counts, loop many times',
	DR3 => 'a count fails -> "?" and a warning',
	# _try_count_rows
	TC1 => 'count returned', TC2 => 'count fails -> warning, undef', TC3 => 'interrupted -> passed on',
	W1 => '_warn',
	# _log
	LG1 => 'no logger -> early return', LG2 => 'logged', LG3 => 'logger dies -> warned, dropped',
	# _os_error
	O1 => 'object with errno', O2 => 'anything else',

	# App::run
	AR1 => 'option parsing decides', AR2 => 'export status returned', AR3 => 'exception -> fatal report',
	AR4 => 'invalid settings -> usage error, before standard input or the log is touched',
	AR5 => '"-" -> standard input copied, the copy exported',
	# _parse_options
	PO1 => 'parse fails', PO2 => 'help', PO3 => 'wrong database count', PO4 => 'go ahead',
	# _usage
	US1 => 'status 0, no message', US2 => 'error status, message',
	# _make_logger
	ML1 => 'no log wanted', ML2 => 'cannot open', ML3 => 'no logger created', ML4 => 'logger',
	# _report_fatal
	RF1 => 'no error text', RF2 => 'location removed', RF3 => 'verbose keeps location',

	# Dead-code proof
	DEAD1 => 'Exporter::run: Params::Get never returns a non-hash, so no ref() test is needed',
);

my %taken;
sub took {
	foreach my $id (@_) {
		die "Unknown path ID $id" unless exists $PATHS{$id};
		$taken{$id}++;
	}
	return;
}

local $ENV{PATH} = join(':', install_fake_mdbtools(), $ENV{PATH});

sub exporter { return $CONFIG{exporter}->new(progress => 0, @_) }

{
	package Local::Logger;
	sub new { return bless { lines => [] }, shift }
	foreach my $level (qw(debug info warn)) {
		no strict 'refs';
		*{$level} = sub { push @{ $_[0]{lines} }, [$level, $_[1]]; return };
	}
}

#######################################################################
# App::Access2CSV::I18N
#######################################################################

subtest 'i18n paths' => sub {
	my $i18n = $CONFIG{i18n};
	local $App::Access2CSV::I18N::MESSAGES{de} = { t => { one => 'DE1', other => 'DE*' }, gap => { one => 'DE1' }, bad => { one => 'x' } };
	local $App::Access2CSV::I18N::MESSAGES{en} = {
		%{ $App::Access2CSV::I18N::MESSAGES{en} },
		t => 'EN', gap => { one => 'EN1', other => 'EN*' }, bad => { one => 'x' },
	};

	is($i18n->i18n('t'), 'EN', 'I1'); took('I1');
	is($i18n->i18n({ key => 't' }), 'EN', 'I2'); took('I2');
	throws_ok { $i18n->i18n('') } qr/'key'/, 'I3'; took('I3');
	is($i18n->i18n('summary', { params => [2, 0], count => 2 }), 'Processed 2 tables, 0 failed', 'I8'); took('I8');
	throws_ok { $i18n->i18n('bad', { count => 2 }) } qr/\AUnknown message key: bad at /, 'I6'; took('I6');
	{
		local $ENV{LANG} = 'de';
		is($i18n->i18n('t', { count => 1 }), 'DE1', 'I4'); took('I4');
		is($i18n->i18n('gap', { count => 2 }), 'EN*', 'I5'); took('I5');
		throws_ok { $i18n->i18n('bad', { count => 2 }) } qr/\AUnknown message key: bad at /, 'I7'; took('I7');
	}

	my $guard = mock_scoped("$CONFIG{i18n}::i18n" => sub { 'text' });
	throws_ok { $i18n->_croak_i18n('k') } qr/\Atext at /, 'CI1'; took('CI1');
	my $result;
	warning_like { $result = $i18n->_carp_i18n('k') } qr/\Atext at /, 'CA1 warns';
	is($result, $i18n, 'CA1 returns self'); took('CA1');
};

subtest '_language paths' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { x => 'y' };
	my $class = $CONFIG{i18n};
	is(bless({ language => 'de' }, $class)->_language(), 'de', 'L1'); took('L1');
	{
		local $ENV{LANG} = 'de_DE';
		is($class->_language(), 'de', 'L2'); took('L2');
	}
	is($class->_language(), 'en', 'L3'); took('L3');
	{
		local $ENV{LANG} = 'xx_XX';
		is($class->_language(), 'en', 'L4'); took('L4');
	}
};

subtest '_lookup paths' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { mine => 'meins' };
	my $class = $CONFIG{i18n};
	is($class->_lookup('de', 'mine'), 'meins', 'K1'); took('K1');
	is($class->_lookup('de', 'column_rows'), 'ROWS', 'K2'); took('K2');
	is($class->_lookup('zz', 'column_rows'), 'ROWS', 'K3'); took('K3');
	throws_ok { $class->_lookup('de', 'nope') } qr/\AUnknown message key: nope at /, 'K4'; took('K4');
};

subtest '_narrow paths' => sub {
	my $narrow = \&App::Access2CSV::I18N::_narrow;
	is($narrow->('s', 'en', {}), 's', 'N1'); took('N1');
	is($narrow->({ f => 'F', other => 'O' }, 'en', { context => 'f' }), 'F', 'N2'); took('N2');
	is($narrow->({ one => '1', other => '*' }, 'en', { count => 1 }), '1', 'N3'); took('N3');
	is($narrow->({ other => '*' }, 'en', { count => 1 }), '*', 'N4'); took('N4');
	is($narrow->({ one => '1' }, 'en', { count => 2 }), undef, 'N5'); took('N5');
	is($narrow->({ other => {} }, 'en', {}), undef, 'N6'); took('N6');
};

subtest '_unknown_key and _plural_category paths' => sub {
	throws_ok { App::Access2CSV::I18N::_unknown_key('k') } qr/\AUnknown message key: k at /, 'U1'; took('U1');
	{
		local $App::Access2CSV::I18N::MESSAGES{en} = { %{ $App::Access2CSV::I18N::MESSAGES{en} } };
		delete $App::Access2CSV::I18N::MESSAGES{en}{unknown_message};
		throws_ok { App::Access2CSV::I18N::_unknown_key('k') } qr/\AUnknown message key: k at /, 'U2'; took('U2');
	}
	my $plural = \&App::Access2CSV::I18N::_plural_category;
	is($plural->('fr', 0), 'one', 'P1'); took('P1');
	is($plural->('zz', 1), 'one', 'P2'); took('P2');
	is($plural->('en', undef), 'other', 'P3'); took('P3');
};

#######################################################################
# App::Access2CSV::Exporter
#######################################################################

subtest 'new paths' => sub {
	my $e = $CONFIG{exporter}->new();
	returns_ok($e, { type => 'object' }, 'E1'); took('E1');
	my @tables = ('A');
	my $copy = $CONFIG{exporter}->new(tables => \@tables);
	push @tables, 'B';
	is_deeply($copy->{tables}, ['A'], 'E2'); took('E2');
	is($CONFIG{exporter}->new(overwrite => undef)->{overwrite}, 0, 'E3'); took('E3');
	throws_ok { $CONFIG{exporter}->new(bogus => 1) } qr/Unknown parameter 'bogus'/, 'E4'; took('E4');
};

subtest 'run paths' => sub {
	my $status = 0;
	my $tables = ['T'];
	my $made = 0;
	my $guard = mock_scoped($CONFIG{exporter},
		_check_database      => sub { die "bad db\n" if $_[1] eq 'bad'; $_[0] },
		_verify_dependencies => sub { $_[0] },
		_get_tables          => sub { $tables },
		_dry_run             => sub { $_[0] },
		_make_output_dir     => sub { $made++; $_[0] },
		_export_all          => sub { $status },
	);
	throws_ok { exporter()->run() } qr/\AUsage: /, 'R1'; took('R1');
	throws_ok { exporter()->run(undef) } qr/Required parameter 'database' is missing/, 'R2'; took('R2');
	throws_ok { exporter()->run('bad') } qr/\Abad db/, 'R3'; took('R3');
	is(exporter(dry_run => 1)->run('db'), $CONFIG{exit_ok}, 'R4'); took('R4');
	is(exporter()->run('db'), $CONFIG{exit_ok}, 'R5'); took('R5');
	$status = 2;
	is(exporter()->run('db'), $CONFIG{exit_failure}, 'R6'); took('R6');
	($status, $tables, $made) = (0, [], 0);
	is(exporter()->run('db'), $CONFIG{exit_ok}, 'R7: status');
	is($made, 0, 'R7: no output directory made'); took('R7');
};

subtest 'dead code: Params::Get never returns anything but a hash' => sub {
	# The "not a hash" side of Exporter::run's ref() test.  Every input
	# shape either dies inside Params::Get or yields a hash reference.
	foreach my $case ([], [undef], ['x'], [{ database => 'x' }], [{}], [[]], [\*STDIN], ['a', 'b'], [database => 'x'], [\'x']) {
		my $result = eval { get_params('database', $case) };
		ok($@ || ref($result) eq 'HASH', 'input of ' . scalar(@{$case}) . ' element(s): dies or hash');
	}
	took('DEAD1');
};

subtest '_check_database paths' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'T');
	my $e = exporter();
	throws_ok { $e->_check_database("$dir/x") } qr/: \Q$ENOENT_TEXT\E at /, 'D1'; took('D1');
	throws_ok { $e->_check_database($dir) } qr/not a regular file/, 'D2'; took('D2');
	SKIP: {
		skip('root can read anything', 1) if $> == 0;
		chmod 0, $db;
		throws_ok { $e->_check_database($db) } qr/not readable/, 'D3';
		chmod oct(644), $db;
	}
	took('D3');
	is($e->_check_database($db), $e, 'D4'); took('D4');
};

subtest '_verify_dependencies paths' => sub {
	my %present;
	my $guard = mock_scoped("$CONFIG{exporter}::which" => sub { $present{ $_[0] } ? "$CONFIG{fake_bin}/$_[0]" : undef });
	throws_ok { exporter()->_verify_dependencies() } qr/PATH: mdb-tables at /, 'V1'; took('V1');
	%present = ('mdb-tables' => 1);
	throws_ok { exporter()->_verify_dependencies() } qr/PATH: mdb-export at /, 'V2'; took('V2');
	%present = ('mdb-tables' => 1, 'mdb-export' => 1);
	is_deeply([sort keys %{ exporter()->_verify_dependencies()->{programs} }], ['mdb-export', 'mdb-tables'], 'V3'); took('V3');
	my $e = exporter(show_counts => 1);
	capture_stderr { $e->_verify_dependencies() };
	is($e->{show_counts}, 0, 'V5'); took('V5');
	$present{'mdb-count'} = 1;
	ok(exporter(show_counts => 1)->_verify_dependencies()->{programs}{'mdb-count'}, 'V4'); took('V4');
};

subtest '_find_program, _reset_names paths' => sub {
	my $found = 1;
	my $guard = mock_scoped("$CONFIG{exporter}::which" => sub { $found ? "$CONFIG{fake_bin}/p" : undef });
	my $logger = Local::Logger->new();
	exporter(verbose => 1, logger => $logger)->_find_program('p');
	is(scalar(@{ $logger->{lines} }), 1, 'F1'); took('F1');
	my $quiet = Local::Logger->new();
	exporter(logger => $quiet)->_find_program('p');
	is(scalar(@{ $quiet->{lines} }), 0, 'F2'); took('F2');
	$found = 0;
	is(exporter()->_find_program('p'), undef, 'F3'); took('F3');
	my $e = exporter();
	$e->{used_names}{x} = 1;
	is_deeply($e->_reset_names()->{used_names}, {}, 'RN1'); took('RN1');
};

subtest '_get_tables, _is_system_table paths' => sub {
	my $output = "B\nMSysX\nA\n";
	my $guard = mock_scoped("$CONFIG{exporter}::_run_program" => sub { ${ $_[3] } = $output; $_[0] });
	is_deeply(exporter()->_get_tables('db'), ['A', 'B'], 'G1'); took('G1');
	$output = undef;
	is_deeply(exporter()->_get_tables('db'), [], 'G2'); took('G2');
	is(exporter()->_is_system_table('MSysX'), 1, 'S1'); took('S1');
	is(exporter()->_is_system_table('Orders'), 0, 'S2'); took('S2');
};

subtest '_select_tables paths' => sub {
	my $all = ['A', 'B'];
	is(exporter()->_select_tables($all), $all, 'T1'); took('T1');
	is_deeply(exporter(tables => ['B'])->_select_tables($all), ['B'], 'T2'); took('T2');
	my $stderr = capture_stderr { exporter(tables => ['Z'])->_select_tables($all) };
	like($stderr, qr/Table not found in database: Z/, 'T3'); took('T3');
};

subtest '_make_output_dir paths' => sub {
	my $dir = tempdir(CLEANUP => 1);
	is(exporter(output_dir => $dir)->_make_output_dir()->{output_dir}, $dir, 'M1'); took('M1');
	exporter(output_dir => "$dir/new")->_make_output_dir();
	ok(-d "$dir/new", 'M2'); took('M2');

	my $target = "$dir/fails";
	my @errors;
	my $made = 0;
	my $guard = mock_scoped("$CONFIG{exporter}::make_path" => sub { ${ $_[1]{error} } = [@errors]; mkdir $target if $made; $! = ENOENT; return });
	@errors = ({ '/p' => 'Parent' }, { $target => 'Own' });
	throws_ok { exporter(output_dir => $target)->_make_output_dir() } qr/: Own at /, 'M3'; took('M3');
	@errors = ({ '/a' => 'First' }, { '/b' => 'Last' });
	throws_ok { exporter(output_dir => $target)->_make_output_dir() } qr/: Last at /, 'M4'; took('M4');
	@errors = ();
	throws_ok { exporter(output_dir => $target)->_make_output_dir() } qr/: \Q$ENOENT_TEXT\E at /, 'M5'; took('M5');
};

subtest '_export_all paths' => sub {
	my %fail;
	my $guard = mock_scoped($CONFIG{exporter},
		_export_table => sub { my $why = $fail{ $_[2] }; die $why if defined $why; $_[0] },
		_log          => sub { $_[0] },
	);
	is(exporter()->_export_all('db', []), 0, 'A1: 0 iterations'); took('A1');
	my $stderr = capture_stderr { exporter(progress => 1)->_export_all('db', ['T']) };
	is($stderr, "[1/1] T\n", 'A2: 1 iteration with progress'); took('A2');

	%fail = (B => "broken\n");
	my $failed;
	$stderr = capture_stderr { $failed = exporter()->_export_all('db', ['A', 'B', 'C']) };
	is($failed, 1, 'A3: many iterations, one failure');
	like($stderr, qr/FAILED: B: broken/, 'A3: warned'); took('A3');
	unlike($stderr, qr/^\[/m, 'A5: no progress when off'); took('A5');

	# An exception that is false (an object whose truth value is false)
	{
		package Local::FalseError;
		use overload 'bool' => sub { 0 }, '""' => sub { '' }, fallback => 1;
	}
	%fail = (A => bless({}, 'Local::FalseError'));
	$stderr = capture_stderr { exporter()->_export_all('db', ['A']) };
	like($stderr, qr/FAILED: A: Unknown error/, 'A4'); took('A4');
};

subtest '_export_table paths' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my (@ran, %installed, @logged, @transcoded);
	my $flush_ok = 1;
	my $count_fails = 0;
	my $real_flush = \&IO::Handle::flush;
	my $guard = mock_scoped(
		"$CONFIG{exporter}::_run_program" => sub { push @ran, 1; print { $_[3] } "d\n"; $_[3]->flush(); $_[0] },
		"$CONFIG{exporter}::_export_transcoded" => sub { push @transcoded, 1; $_[0] },
		"$CONFIG{exporter}::_install_file" => sub {
			open my $fh, '<:raw', $_[1]->filename() or die $!;
			local $/;
			%installed = (content => scalar(<$fh>));
			return $_[0];
		},
		"$CONFIG{exporter}::_count_rows" => sub { die "count broke\n" if $count_fails; $CONFIG{rows} },
		"$CONFIG{exporter}::_log" => sub { shift; push @logged, $_[1]; $_[0] },
		'IO::Handle::flush' => sub {
			return $real_flush->(@_) if $flush_ok || !$_[0]->isa('File::Temp');
			$! = ENOSPC;
			return;
		},
	);

	open my $fh, '>', "$dir/T.csv" or die $!;
	close $fh;
	throws_ok { exporter(output_dir => $dir)->_export_table('db', 'T') } qr/already exists/, 'X1';
	is(scalar(@ran), 0, 'X1: nothing run'); took('X1');

	exporter(output_dir => $dir, overwrite => 1)->_export_table('db', 'T');
	is($installed{content}, "d\n", 'X2'); took('X2');
	is($logged[-1], 'exported', 'X7'); took('X7');

	exporter(output_dir => $dir, overwrite => 1, encoding => 'utf8-bom')->_export_table('db', 'T');
	is($installed{content}, "$CONFIG{utf8_bom}d\n", 'X3'); took('X3');

	$flush_ok = 0;
	throws_ok { exporter(output_dir => $dir, overwrite => 1, encoding => 'utf8-bom')->_export_table('db', 'T') } qr/\ACannot write .*: \Q$ENOSPC_TEXT\E at /, 'X4'; took('X4');
	$flush_ok = 1;

	exporter(output_dir => $dir, overwrite => 1, encoding => 'cp1252')->_export_table('db', 'T');
	is(scalar(@transcoded), 1, 'X5'); took('X5');

	exporter(output_dir => $dir, overwrite => 1, show_counts => 1)->_export_table('db', 'T');
	is($logged[-1], 'exported_rows', 'X6'); took('X6');

	$count_fails = 1;
	my $stderr = capture_stderr { exporter(output_dir => $dir, overwrite => 1, show_counts => 1)->_export_table('db', 'T') };
	is($logged[-1], 'exported', 'X8: logged as exported, without a count');
	like($stderr, qr/Cannot count the rows of T: count broke/, 'X8: warning'); took('X8');
};

subtest '_export_transcoded paths' => sub {
	my $output = '';
	my $guard = mock_scoped("$CONFIG{exporter}::_run_program" => sub { print { $_[3] } $output; $_[3]->flush(); $_[0] });
	my $e = exporter(output_dir => tempdir(CLEANUP => 1));
	my $run = sub { open my $out, '>:raw', \my $buffer or die $!; $e->_export_transcoded('db', 'T', $out); close $out; return $buffer // '' };

	is($run->(), '', 'Y1: 0 iterations'); took('Y1');
	$output = "Caf\xC3\xA9\n";
	is($run->(), "Caf\xE9\n", 'Y2'); took('Y2');
	$output = "Caf\xE9\n";
	throws_ok { $run->() } qr/line 1: output of mdb-export is not valid UTF-8/, 'Y3'; took('Y3');
	$output = "\xE6\x97\xA5\n";
	throws_ok { $run->() } qr/line 1: cannot be represented in cp1252/, 'Y4'; took('Y4');
};

subtest '_install_file paths' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $tmp = File::Temp->new(DIR => $dir, UNLINK => 1);
	exporter()->_install_file($tmp, "$dir/out.csv");
	ok(-f "$dir/out.csv", 'IF1'); took('IF1');
	my $tmp2 = File::Temp->new(DIR => $dir, UNLINK => 1);
	throws_ok { exporter()->_install_file($tmp2, "$dir/no/such/out.csv") } qr/\ACannot write .*: \Q$ENOENT_TEXT\E at /, 'IF2'; took('IF2');
};

subtest '_count_rows paths' => sub {
	my $output;
	my $guard = mock_scoped("$CONFIG{exporter}::_run_program" => sub { ${ $_[3] } = $output; $_[0] });
	$output = "$CONFIG{rows}\n";
	is(exporter()->_count_rows('db', 'T'), $CONFIG{rows}, 'CR1'); took('CR1');
	$output = undef;
	throws_ok { exporter()->_count_rows('db', 'T') } qr/\Amdb-count printed no number: "" at /, 'CR2'; took('CR2');
	$output = '-5';
	throws_ok { exporter()->_count_rows('db', 'T') } qr/\Amdb-count printed no number: "-5" at /, 'CR3'; took('CR3');
};

subtest '_run_program paths' => sub {
	my $status;
	my $guard = mock_scoped("$CONFIG{exporter}::run3" => sub { ${ $_[3] } = "why\n"; $? = $status; return 1 });
	my $e = exporter();
	$e->{programs} = { p => "$CONFIG{fake_bin}/p" };
	my %cases = (
		RP1 => [-1, qr/\Ap could not be run: /],
		RP2 => [$CONFIG{signal}, qr/\Ap was killed by signal $CONFIG{signal} /],
		RP3 => [$CONFIG{exit_code} << 8, qr/\Ap failed with exit status $CONFIG{exit_code}: why at /],
	);
	foreach my $id (sort keys %cases) {
		$status = $cases{$id}[0];
		throws_ok { $e->_run_program('p', [], \my $out) } $cases{$id}[1], $id;
		took($id);
	}
	$status = 0;
	is($e->_run_program('p', [], \my $out), $e, 'RP4'); took('RP4');
};

subtest '_csv_filename paths' => sub {
	my $e = exporter();
	is($e->_csv_filename(undef), 'unnamed.csv', 'CF1'); took('CF1');
	is($e->_csv_filename('AUX'), '_AUX.csv', 'CF2'); took('CF2');
	is($e->_csv_filename(' .. '), 'unnamed_2.csv', 'CF3 (and CF5: one collision pass)'); took('CF3', 'CF5');
	is($e->_csv_filename('Orders'), 'Orders.csv', 'CF4: 0 collision passes'); took('CF4');
	is($e->_csv_filename(''), 'unnamed_3.csv', 'CF6: two collision passes'); took('CF6');
	my $chars = "Caf\x{e9}";
	utf8::upgrade($chars);
	is($e->_csv_filename($chars), "Caf\x{e9}.csv", 'CF7'); took('CF7');
	is($e->_csv_filename("Caf\xE9!"), 'Caf_!.csv', 'CF8'); took('CF8');
};

subtest '_shorten_name paths' => sub {
	my $e = exporter();
	my $max = $CONFIG{max_name_chars};
	is($e->_shorten_name('a'), 'a', 'SN1'); took('SN1');
	is($e->_shorten_name("\xC3\xBC" x ($max + 1)), "\xC3\xBC" x $max, 'SN2'); took('SN2');
	my $chars = "\x{fc}" x ($max + 1);
	utf8::upgrade($chars);
	my $short = $e->_shorten_name($chars);
	ok(utf8::is_utf8($short) && $short eq "\x{fc}" x $max, 'SN3'); took('SN3');
};

subtest '_dry_run paths' => sub {
	my $guard = mock_scoped("$CONFIG{exporter}::_count_rows" => sub { $CONFIG{rows} });
	my $stdout = capture_stdout { exporter()->_dry_run('db', []) };
	unlike($stdout, qr/ROWS|\.csv/, 'DR1: no counts, 0 iterations'); took('DR1');
	$stdout = capture_stdout { exporter(show_counts => 1)->_dry_run('db', ['A', 'B']) };
	is(scalar(() = $stdout =~ /^\w\s+$CONFIG{rows}\s+\w\.csv$/mg), 2, 'DR2: counts, 2 iterations'); took('DR2');
	restore_all();

	my $failing = mock_scoped("$CONFIG{exporter}::_count_rows" => sub { die "count broke\n" });
	my $stderr;
	($stdout, $stderr) = capture { exporter(show_counts => 1)->_dry_run('db', ['A']) };
	like($stdout, qr/^A\s+\?\s+A\.csv$/m, 'DR3: "?" shown');
	like($stderr, qr/Cannot count the rows of A/, 'DR3: warning'); took('DR3');
};

subtest '_try_count_rows paths' => sub {
	my $behaviour = 'ok';
	my $guard = mock_scoped("$CONFIG{exporter}::_count_rows" => sub {
		die "count broke\n" if $behaviour eq 'fail';
		if($behaviour eq 'interrupt') { $_[0]{interrupted} = 'INT'; die "Interrupted\n" }
		return $CONFIG{rows};
	});
	is(exporter()->_try_count_rows('db', 'T'), $CONFIG{rows}, 'TC1'); took('TC1');

	$behaviour = 'fail';
	my $got = 'not called';
	my $stderr = capture_stderr { $got = exporter()->_try_count_rows('db', 'T') };
	is($got, undef, 'TC2: undef');
	like($stderr, qr/Cannot count the rows of T: count broke/, 'TC2: warning'); took('TC2');

	$behaviour = 'interrupt';
	throws_ok { exporter()->_try_count_rows('db', 'T') } qr/\AInterrupted/, 'TC3'; took('TC3');
};

subtest '_warn, _log, _os_error paths' => sub {
	my $logger = Local::Logger->new();
	my $e = exporter(logger => $logger);
	my $stderr = capture_stderr { $e->_warn('dry_run_title') };
	ok($stderr =~ /DRY RUN/ && $logger->{lines}[-1][0] eq 'warn', 'W1'); took('W1');

	is(exporter()->_log(info => 'dry_run_title')->{logger}, undef, 'LG1'); took('LG1');
	$e->_log(info => 'dry_run_title');
	is($logger->{lines}[-1][1], 'DRY RUN', 'LG2'); took('LG2');
	{
		package Local::DyingLogger;
		sub new { bless {}, shift }
		sub info { die "gone\n" }
		sub debug { } sub warn { }
	}
	my $dying = exporter(logger => Local::DyingLogger->new());
	$stderr = capture_stderr { $dying->_log(info => 'dry_run_title') };
	ok($stderr =~ /Cannot write to the log: gone/ && !$dying->{logger}, 'LG3'); took('LG3');

	eval { use autodie qw(open); open my $fh, '<', '/nonexistent/x' };
	is(App::Access2CSV::Exporter::_os_error($@), $ENOENT_TEXT, 'O1'); took('O1');
	is(App::Access2CSV::Exporter::_os_error("plain\n"), 'plain', 'O2'); took('O2');
};

#######################################################################
# App::Access2CSV
#######################################################################

subtest 'App::run paths' => sub {
	my ($parse, $die) = (undef, 0);
	{
		package Local::FakeExporter;
		sub new { my ($class, %a) = @_; die "bad encoding\n" if ($a{encoding} // '') eq 'latin1'; bless {%a}, $class }
		sub run { $Local::FakeExporter::ran = $_[1]; $CONFIG{exit_failure} }
		package Local::FakeCopy;
		sub filename { '/tmp/copy-of-stdin' }
	}
	my (%opened, $read);
	my $guard = mock_scoped(
		"$CONFIG{app}::_parse_options" => sub { my (undef, undef, $opt) = @_; $opt->{encoding} = $parse->{encoding} if ref $parse; ref($parse) ? undef : $parse },
		"$CONFIG{app}::_make_logger"   => sub { $opened{log}++; die "no log\n" if $die; return },
		"$CONFIG{app}::_read_stdin"    => sub { $read++; bless {}, 'Local::FakeCopy' },
		"$CONFIG{app}::_report_fatal"  => sub { $CONFIG{exit_fatal} },
		"$CONFIG{exporter}::new"       => sub { shift; Local::FakeExporter->new(@_) },
	);
	$parse = $CONFIG{exit_usage};
	is($CONFIG{app}->run('--x'), $CONFIG{exit_usage}, 'AR1'); took('AR1');
	$parse = undef;
	is($CONFIG{app}->run('db'), $CONFIG{exit_failure}, 'AR2'); took('AR2');
	$die = 1;
	is($CONFIG{app}->run('db'), $CONFIG{exit_fatal}, 'AR3'); took('AR3');

	# Separate assignments: a hash in a list assignment would swallow the
	# values meant for the variables after it
	$die = 0;
	%opened = ();
	$read = 0;
	$parse = { encoding => 'latin1' };
	my $ar4;
	capture { $ar4 = $CONFIG{app}->run('-') };
	is($ar4, $CONFIG{exit_usage}, 'AR4: usage error');
	ok(!$opened{log} && !$read, 'AR4: neither the log nor standard input touched'); took('AR4');

	$parse = undef;
	is($CONFIG{app}->run('-'), $CONFIG{exit_failure}, 'AR5: exported');
	is($Local::FakeExporter::ran, '/tmp/copy-of-stdin', 'AR5: the copy was exported'); took('AR5');
};

subtest '_parse_options paths' => sub {
	my @usage;
	my $guard = mock_scoped("$CONFIG{app}::_usage" => sub { push @usage, $_[1]; $_[1] });
	my $parse = sub { my @a = @_; local $SIG{__WARN__} = sub { }; $CONFIG{app}->_parse_options(\@a, {}) };
	is($parse->('--bogus'), $CONFIG{exit_usage}, 'PO1'); took('PO1');
	is($parse->('--help'), $CONFIG{exit_ok}, 'PO2'); took('PO2');
	is($parse->(), $CONFIG{exit_usage}, 'PO3'); took('PO3');
	is($parse->('db'), undef, 'PO4'); took('PO4');
};

subtest '_usage, _make_logger, _report_fatal paths' => sub {
	my @calls;
	{
		my $guard = mock_scoped("$CONFIG{app}::pod2usage" => sub { push @calls, {@_}; return });
		$CONFIG{app}->_usage($CONFIG{exit_ok}, 1);
		ok($calls[-1]{-output} == \*STDOUT && !exists $calls[-1]{-message}, 'US1'); took('US1');
		$CONFIG{app}->_usage($CONFIG{exit_usage}, 0, 'why');
		ok($calls[-1]{-output} == \*STDERR && $calls[-1]{-message} eq 'why', 'US2'); took('US2');
	}

	my $dir = tempdir(CLEANUP => 1);
	my $creates = 1;
	my $guard = mock_scoped('Log::Abstraction::new' => sub { $creates ? Local::Logger->new() : undef });
	is($CONFIG{app}->_make_logger({ log => undef }), undef, 'ML1'); took('ML1');
	throws_ok { $CONFIG{app}->_make_logger({ log => "$dir/no/x.log" }) } qr/Cannot open log file .*: \Q$ENOENT_TEXT\E at /, 'ML2'; took('ML2');
	$creates = 0;
	throws_ok { $CONFIG{app}->_make_logger({ log => "$dir/a.log" }) } qr/no logger was created/, 'ML3'; took('ML3');
	$creates = 1;
	isa_ok($CONFIG{app}->_make_logger({ log => "$dir/b.log" }), 'Local::Logger', 'ML4'); took('ML4');

	my %cases = (
		RF1 => [undef, 0, 'Unknown error'],
		RF2 => ["boom at x line 1.\n", 0, 'boom'],
		RF3 => ["boom at x line 1.\n", 1, 'boom at x line 1.'],
	);
	foreach my $id (sort keys %cases) {
		my ($error, $verbose, $text) = @{ $cases{$id} };
		my $stderr = capture_stderr { $CONFIG{app}->_report_fatal($error, $verbose) };
		is($stderr, "access2csv: $text\n", $id);
		took($id);
	}
};

#######################################################################

subtest 'every path was taken' => sub {
	my @missed = sort grep { !$taken{$_} } keys %PATHS;
	fail("path never taken: $_ ($PATHS{$_})") foreach @missed;
	pass(scalar(keys %PATHS) . ' paths, all taken') unless @missed;
};

restore_all();

done_testing();
