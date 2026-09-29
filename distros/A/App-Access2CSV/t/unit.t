#!perl

# Black-box unit tests of the public API, exactly as the POD documents it,
# one module at a time:
#
#	1. App::Access2CSV::I18N      - i18n
#	2. App::Access2CSV::Exporter  - new, run
#	3. App::Access2CSV            - run
#
# Strategy: only public routines are called.  The outside world is
# mocked at its boundary - File::Which::which, IPC::Run3::run3 and
# Log::Abstraction->new - by a small scripted "mdbtools" (see
# mdbtools_scenario below), so every documented branch can be forced
# without mdbtools or a real Access database.  File system effects are
# real, in temporary directories.
#
# Every message and return state listed in the POD is entered in %LEDGER
# first.  Each check that triggers one deletes it; the last test fails
# if anything documented was never exercised.
#
# Set TEST_VERBOSE=1 to see the state behind each check.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;

use Capture::Tiny qw(capture);
use Errno qw(EACCES EISDIR ENOENT ENOTDIR);
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;

use App::Access2CSV;

# Messages must be English whatever locale the tester uses
delete @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)};

Readonly::Hash my %CONFIG => (
	i18n         => 'App::Access2CSV::I18N',
	exporter     => 'App::Access2CSV::Exporter',
	app          => 'App::Access2CSV',
	fake_bin     => '/fake/bin',
	mdb_tables   => 'mdb-tables',
	mdb_export   => 'mdb-export',
	mdb_count    => 'mdb-count',
	exit_ok      => 0,
	exit_failure => 1,
	exit_usage   => 2,
	exit_fatal   => 3,
	bad_status   => 2,
	signal       => 9,
	row_count    => 7,
	alarm_secs   => 1000,
	alarm_slack  => 5,
	sentinel     => "sentinel\n",
	signal_delay => 0.5,
	utf8_bom     => "\xEF\xBB\xBF",
	csv_body     => "\"id\",\"name\"\n1,\"x\"\n",
);

# OS error texts, taken from Perl's own $! in the current locale
Readonly::Hash my %OS => (
	enoent  => do { local $! = ENOENT; "$!" },
	enotdir => do { local $! = ENOTDIR; "$!" },
	eisdir  => do { local $! = EISDIR; "$!" },
	eacces  => do { local $! = EACCES; "$!" },
);

# The ledger: every documented message and return state, by POD section
my %LEDGER = map { $_ => 1 } (
	# App::Access2CSV::I18N::i18n
	'i18n: returns string',
	'i18n: Unknown message key',
	'i18n: Required parameter key is missing',
	'i18n: Unknown parameter X',
	'i18n: Parameter count must be',
	'i18n: Parameter params must be an arrayref',

	# App::Access2CSV::Exporter::new
	'new: returns object',
	'new: Unknown parameter X',
	'new: encoding must be one of',
	'new: logger must be an object',
	'new: tables must be',

	# App::Access2CSV::Exporter::run
	'run: returns 0',
	'run: returns 1',
	'run: Cannot read database',
	'run: must be called on an object',
	'run: Interrupted by signal',
	'run: Database is not a regular file',
	'run: Database is not readable',
	'run: Required program not found in PATH',
	'run: mdb-tables failed with exit status',
	'run: Cannot create output directory',
	'run: Tables not found in database',
	'run: mdb-count not found in PATH',
	'run: Cannot count the rows of',
	'run: FAILED',
	'run: Output file already exists',
	'run: mdb-export failed with exit status',
	'run: killed by signal (per table)',
	'run: killed by signal (fatal for mdb-tables)',
	'run: cannot be represented in cp1252',
	'run: output of mdb-export is not valid UTF-8',
	'run: Cannot write',
	'run: could not be run',
	'run: Cannot write to the log',

	# App::Access2CSV::run
	'app: returns 0',
	'app: returns 1',
	'app: returns 2',
	'app: returns 3',
	'app: Unknown option',
	'app: Option requires an argument',
	'app: Missing database filename',
	'app: Cannot open log file',
	'app: Invalid setting',
	'app: --version',
	'run: mdb-count printed no number',
	'app: no logger was created',
	'app: it is a symbolic link',
	'app: Standard input is empty',
	'app: Cannot read standard input',
	'app: Standard input is a terminal',
	'app: Interrupted while reading standard input',
	'app: access2csv: MESSAGE',
);

# Mark a documented condition as exercised
sub ticked {
	my $entry = shift;
	die "No such ledger entry: $entry" unless exists $LEDGER{$entry};
	delete $LEDGER{$entry};
	return;
}

sub verbose_diag {
	my ($label, $data) = @_;
	diag("$label: ", Test::More::explain($data)) if $ENV{TEST_VERBOSE};
	return;
}

# A logger double that records (level, message) pairs
{
	package Local::Logger;

	sub new { return bless { lines => [] }, shift }

	foreach my $level (qw(debug info warn)) {
		no strict 'refs';
		*{$level} = sub { push @{ $_[0]{lines} }, [$level, $_[1]]; return };
	}
}

# mdbtools_scenario(%scenario)
# Mocks File::Which and IPC::Run3 as the Exporter sees them, and returns
# a guard that restores them.  %scenario:
#	missing     => [programs that are not installed]
#	tables      => [table names mdb-tables lists]
#	tables_exit => exit status of mdb-tables (default 0)
#	tables_kill => signal that kills mdb-tables
#	data        => { table => bytes mdb-export prints }
#	exit        => { table => exit status of mdb-export }
#	kill        => { table => signal that kills mdb-export }
sub mdbtools_scenario {
	my %scenario = @_;
	my %missing = map { $_ => 1 } @{ $scenario{missing} || [] };

	return mock_scoped(
		"$CONFIG{exporter}::which" => sub {
			return $missing{ $_[0] } ? undef : "$CONFIG{fake_bin}/$_[0]";
		},
		"$CONFIG{exporter}::run3" => sub {
			my ($cmd, $stdin, $stdout, $stderr) = @_;
			my ($program, @args) = @{$cmd};
			$program =~ s{\A\Q$CONFIG{fake_bin}\E/}{};
			# Like mdbtools, treat everything after "--" as a file or table
			@args = grep { $_ ne '--' } @args;
			${$stderr} = '';
			$? = 0;

			if($program eq $CONFIG{mdb_tables}) {
				${$stdout} = join('', map { "$_\n" } @{ $scenario{tables} || [] });
				${$stderr} = "not an Access file\n" if $scenario{tables_exit};
				$? = ($scenario{tables_exit} || 0) << 8 | ($scenario{tables_kill} || 0);
			} elsif($program eq $CONFIG{mdb_export}) {
				my $table = $args[-1];
				print {$stdout} exists $scenario{data}{$table} ? $scenario{data}{$table} : $CONFIG{csv_body};
				$stdout->flush();
				${$stderr} = "corrupt table\n" if $scenario{exit}{$table};
				$? = ($scenario{exit}{$table} || 0) << 8 | ($scenario{kill}{$table} || 0);
			} elsif($program eq $CONFIG{mdb_count}) {
				${$stdout} = "$CONFIG{row_count}\n";
			}
			return 1;
		},
	);
}

# A fresh directory with an empty "database" file in it
sub workspace {
	my $dir = tempdir(CLEANUP => 1);
	my $db = File::Spec->catfile($dir, 'shop.accdb');
	open my $fh, '>', $db or die "$db: $!";
	close $fh;
	return ($dir, $db, File::Spec->catdir($dir, 'out'));
}

# Run an exporter; return (status, stdout, stderr, exception)
sub export {
	my ($db, %args) = @_;
	my ($status, $error);
	my ($stdout, $stderr) = capture {
		$status = eval { $CONFIG{exporter}->new(progress => 0, %args)->run($db) };
		$error = $@;
	};
	return ($status, $stdout, $stderr, $error);
}

# check_globals($name, $code)
# Runs $code with known values in $@, $!, $_ and $? and an alarm pending,
# and checks that all of them survive.  The values are set and read back
# inside the code block, because Capture::Tiny itself changes $!.
sub check_globals {
	my ($name, $code) = @_;

	local $SIG{ALRM} = sub { die "alarm fired\n" };
	alarm($CONFIG{alarm_secs});
	my %after;
	my ($stdout, $stderr) = capture {
		local $_ = $CONFIG{sentinel};
		local $@ = $CONFIG{sentinel};
		local $? = $CONFIG{bad_status} << 8;
		$! = ENOENT;
		$code->();
		# Copy into lexicals before testing: Test::More must not see aliases
		%after = (underscore => $_, eval_error => $@, errno => $! + 0, child => $? >> 8);
	};
	my $remaining = alarm(0);
	verbose_diag("$name globals", \%after);

	is($after{underscore}, $CONFIG{sentinel}, "$name: \$_ kept");
	is($after{eval_error}, $CONFIG{sentinel}, "$name: \$@ kept");
	is($after{errno}, ENOENT, "$name: \$! kept");
	is($after{child}, $CONFIG{bad_status}, "$name: \$? kept");
	SKIP: {
		# Windows emulates alarm() with a timer, and its alarm() always
		# returns 0 rather than the seconds left, so it cannot report
		# whether the alarm is still pending
		skip("$name: alarm() does not return the time left on Windows", 1) if $^O eq 'MSWin32';
		cmp_ok($remaining, '>=', $CONFIG{alarm_secs} - $CONFIG{alarm_slack}, "$name: alarm still pending");
	}
	return;
}

sub slurp {
	my $path = shift;
	open my $fh, '<:raw', $path or die "$path: $!";
	local $/;
	return scalar <$fh>;
}

#######################################################################
# 1. App::Access2CSV::I18N::i18n
#######################################################################

subtest 'i18n: returns the message, formatted, without a newline' => sub {
	# POD: "The message as a string, without a newline at the end"
	my $text = $CONFIG{i18n}->i18n('output_exists', { params => ['out/Orders.csv'] });
	is($text, 'Output file already exists: out/Orders.csv (use --overwrite to replace it)', 'POD example');
	returns_ok($text, { type => 'string' }, 'Output schema');
	unlike($text, qr/\n\z/, 'no trailing newline');
	ticked('i18n: returns string');

	is($CONFIG{i18n}->i18n({ key => 'progress', args => { params => [1, 3, 'Customers'] } }), '[1/3] Customers', 'hashref calling style');
	is(bless({}, $CONFIG{i18n})->i18n('missing_database'), 'Missing database filename', 'object method');
};

subtest 'i18n: plural and context forms' => sub {
	# POD: count chooses the plural form; no count means "other"
	my $i18n = $CONFIG{i18n};
	is($i18n->i18n('summary', { params => [1, 0], count => 1 }), 'Processed 1 table, 0 failed', 'one');
	is($i18n->i18n('summary', { params => [4, 0], count => 4 }), 'Processed 4 tables, 0 failed', 'other');
	is($i18n->i18n('summary', { params => [1, 0] }), 'Processed 1 tables, 0 failed', 'no count means plural');

	# POD EXAMPLE: context forms, with plural forms inside
	local $App::Access2CSV::I18N::MESSAGES{en}{greeting} = {
		female => { one => 'She sent %d letter', other => 'She sent %d letters' },
		other  => 'They sent %d letters',
	};
	is($i18n->i18n('greeting', { params => [2], count => 2, context => 'female' }), 'She sent 2 letters', 'POD example');
	is($i18n->i18n('greeting', { params => [1], count => 1, context => 'female' }), 'She sent 1 letter', 'context + one');
	is($i18n->i18n('greeting', { params => [2], context => 'robot' }), 'They sent 2 letters', 'unknown context is ignored');
};

subtest 'i18n: percent signs' => sub {
	# POD pitfall: without params the template is returned exactly
	local $App::Access2CSV::I18N::MESSAGES{en}{percent} = '100% done';
	local $App::Access2CSV::I18N::MESSAGES{en}{percent_param} = '%d%% done';
	is($CONFIG{i18n}->i18n('percent'), '100% done', 'no params: untouched');
	is($CONFIG{i18n}->i18n('percent_param', { params => [50] }), '50% done', 'with params: %% needed');
	is($CONFIG{i18n}->i18n('fatal', { params => ['100% bad'] }), 'access2csv: 100% bad', 'percent in a value is safe');
};

subtest 'i18n: language selection' => sub {
	# POD "Which language is used": object, then LANGUAGE/LC_ALL/
	# LC_MESSAGES/LANG, skipping C and POSIX; per-key English fallback
	local $App::Access2CSV::I18N::MESSAGES{de} = { missing_database => 'Name der Datenbankdatei fehlt' };
	my $i18n = $CONFIG{i18n};

	foreach my $case (
		[{ LANG => 'de_DE.UTF-8' }, 'Name der Datenbankdatei fehlt', 'LANG'],
		[{ LC_MESSAGES => 'de_DE' }, 'Name der Datenbankdatei fehlt', 'LC_MESSAGES'],
		[{ LC_ALL => 'DE_de' }, 'Name der Datenbankdatei fehlt', 'case does not matter'],
		[{ LANGUAGE => 'fr:de' }, 'Missing database filename', 'first LANGUAGE entry only'],
		[{ LC_ALL => 'C', LANG => 'de_DE' }, 'Name der Datenbankdatei fehlt', 'C is skipped'],
		[{ LC_ALL => 'POSIX', LANG => 'de_DE' }, 'Name der Datenbankdatei fehlt', 'POSIX is skipped'],
		[{ LANG => 'ja_JP.UTF-8' }, 'Missing database filename', 'no catalog: English'],
	) {
		my ($env, $expected, $name) = @{$case};
		local @ENV{keys %{$env}} = values %{$env};
		is($i18n->i18n('missing_database'), $expected, $name);
	}

	local $ENV{LANG} = 'de_DE';
	is($i18n->i18n('dry_run_title'), 'DRY RUN', 'untranslated key falls back to English');
	is($CONFIG{exporter}->new(language => 'en')->i18n('missing_database'), 'Missing database filename', 'object language wins');
};

subtest 'i18n: documented errors' => sub {
	my $i18n = $CONFIG{i18n};

	throws_ok { $i18n->i18n('no_such_key') } qr/\AUnknown message key: no_such_key at .*called at /s, 'unknown key, with stack trace';
	ticked('i18n: Unknown message key');

	throws_ok { $i18n->i18n() } qr/Required parameter 'key' is missing/, 'no key';
	throws_ok { $i18n->i18n(undef) } qr/Required parameter 'key' is missing/, 'undef key reported as missing';
	ticked('i18n: Required parameter key is missing');

	throws_ok { $i18n->i18n('summary', { gender => 'x' }) } qr/Unknown parameter 'gender'/, 'unknown args field';
	ticked('i18n: Unknown parameter X');

	throws_ok { $i18n->i18n('summary', { count => -2 }) } qr/Parameter 'count' \(-2\) must be/, 'negative count';
	throws_ok { $i18n->i18n('summary', { count => 1.5 }) } qr/Parameter 'count' \(1\.5\) must be/, 'fractional count';
	ticked('i18n: Parameter count must be');

	throws_ok { $i18n->i18n('summary', { params => 'x' }) } qr/Parameter 'params' must be an arrayref/, 'params not an array';
	ticked('i18n: Parameter params must be an arrayref');
};

subtest 'i18n: does not disturb global state' => sub {
	# POD: "Side Effects: None"
	check_globals('i18n', sub { $CONFIG{i18n}->i18n('summary', { params => [1, 0], count => 1 }) });
};

#######################################################################
# 2. App::Access2CSV::Exporter
#######################################################################

subtest 'new: returns an exporter; undef means default' => sub {
	my $e = $CONFIG{exporter}->new();
	returns_ok($e, { type => 'object', isa => $CONFIG{exporter} }, 'Output schema');
	ticked('new: returns object');

	isa_ok($CONFIG{exporter}->new({ dry_run => 1 }), $CONFIG{exporter}, 'hashref form');
	lives_ok { $CONFIG{exporter}->new(overwrite => undef, tables => undef, encoding => undef) } 'undef values are ignored';

	# POD: "Settings are copied, not shared"
	my @tables = ('A');
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(tables => ['A', 'B']);
	my $exporter = $CONFIG{exporter}->new(tables => \@tables, output_dir => $out, progress => 0);
	push @tables, 'B';
	$exporter->run($db);
	ok(-e "$out/A.csv" && !-e "$out/B.csv", 'later changes to the caller\'s list have no effect');
};

subtest 'new: documented errors' => sub {
	my $class = $CONFIG{exporter};

	throws_ok { $class->new(ouput_dir => 'x') } qr/Unknown parameter 'ouput_dir'/, 'misspelt setting';
	ticked('new: Unknown parameter X');

	throws_ok { $class->new(encoding => 'latin1') } qr/Parameter 'encoding' \(latin1\) must be one of utf8, utf8-bom, cp1252/, 'encoding';
	ticked('new: encoding must be one of');

	throws_ok { $class->new(logger => 'x.log') } qr/Parameter 'logger' must be an object/, 'logger';
	throws_ok { $class->new(logger => bless({}, 'Local::Silent')) } qr/'logger'/, 'logger without debug/info/warn';
	ticked('new: logger must be an object');

	throws_ok { $class->new(tables => 'Orders') } qr/Parameter 'tables' must be/, 'tables not an array';
	throws_ok { $class->new(tables => [['x']]) } qr/'?tables'? can only contain strings/, 'tables of non-strings';
	ticked('new: tables must be');
};

subtest 'run: exports every user table and returns 0' => sub {
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(tables => ['Orders', 'Customers', 'MSysObjects', 'USysRibbons', '~TMP']);
	my $logger = Local::Logger->new();

	my ($status, $stdout, $stderr, $error) = export($db, output_dir => $out, logger => $logger, progress => 1);
	verbose_diag('log', $logger->{lines});
	is($error, '', 'no exception');
	is($status, $CONFIG{exit_ok}, 'status 0');
	returns_ok($status, { type => 'integer', min => 0, max => 1 }, 'Output schema');
	ticked('run: returns 0');

	is(slurp("$out/Orders.csv"), $CONFIG{csv_body}, 'data written unchanged (utf8)');
	ok(-e "$out/Customers.csv", 'second table');
	ok(!-e "$out/MSysObjects.csv" && !-e "$out/USysRibbons.csv", 'system tables skipped');
	is($stdout, '', 'nothing on STDOUT');
	is($stderr, "[1/2] Customers\n[2/2] Orders\n", 'progress to STDERR, sorted');
	like($logger->{lines}[-1][1], qr/\AProcessed 2 tables, 0 failed\z/, 'summary logged');

	opendir my $dh, $out or die $!;
	is_deeply([sort grep { !/\A\.\.?\z/ } readdir $dh], ['Customers.csv', 'Orders.csv'], 'no temporary files left');
};

subtest 'run: encodings' => sub {
	# POD ENCODING: utf8 copied exactly, utf8-bom adds 3 bytes, cp1252 converted
	my $data = "\"n\"\n\"Caf\xC3\xA9 \xE2\x82\xAC \xF0\x9F\x98\x80\"\n";
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(tables => ['T'], data => { T => $data });

	export($db, output_dir => "$out/a");
	is(slurp("$out/a/T.csv"), $data, 'utf8: byte-exact, emoji kept');

	export($db, output_dir => "$out/b", encoding => 'utf8-bom');
	is(slurp("$out/b/T.csv"), "$CONFIG{utf8_bom}$data", 'utf8-bom: BOM first');

	my $guard2 = mdbtools_scenario(tables => ['T'], data => { T => "\"n\"\n\"Caf\xC3\xA9 \xE2\x82\xAC\"\n" });
	export($db, output_dir => "$out/c", encoding => 'cp1252');
	is(slurp("$out/c/T.csv"), "\"n\"\n\"Caf\xE9 \x80\"\n", 'cp1252: converted');
};

subtest 'run: per-table failures return 1 and leave no partial files' => sub {
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(
		tables => ['Bad', 'Emoji', 'Good', 'Killed', 'Latin1'],
		data   => { Emoji => "a\n\xF0\x9F\x98\x80\n", Latin1 => "a\nb\nCaf\xE9\n" },
		exit   => { Bad => $CONFIG{bad_status} },
		kill   => { Killed => $CONFIG{signal} },
	);
	my $logger = Local::Logger->new();

	my ($status, undef, $stderr) = export($db, output_dir => $out, encoding => 'cp1252', logger => $logger);
	verbose_diag('warnings', $stderr);
	is($status, $CONFIG{exit_failure}, 'status 1');
	returns_ok($status, { type => 'integer', min => 0, max => 1 }, 'Output schema');
	ticked('run: returns 1');

	like($stderr, qr/^FAILED: Bad: mdb-export failed with exit status $CONFIG{bad_status}: corrupt table at /m, 'exit status');
	ticked('run: FAILED');
	ticked('run: mdb-export failed with exit status');

	like($stderr, qr/^FAILED: Killed: mdb-export was killed by signal $CONFIG{signal} at /m, 'signal');
	ticked('run: killed by signal (per table)');

	like($stderr, qr/^FAILED: Emoji: Table Emoji, line 2: cannot be represented in cp1252 at /m, 'unmappable');
	ticked('run: cannot be represented in cp1252');

	like($stderr, qr/^FAILED: Latin1: Table Latin1, line 3: output of mdb-export is not valid UTF-8 at /m, 'invalid UTF-8');
	ticked('run: output of mdb-export is not valid UTF-8');

	ok(-e "$out/Good.csv", 'good table exported');
	ok(!-e "$out/$_.csv", "no partial $_.csv") foreach qw(Bad Emoji Killed Latin1);
	is(scalar(grep { $_->[0] eq 'warn' && $_->[1] =~ /\AFAILED: / } @{ $logger->{lines} }), 4, 'failures logged');
	like($logger->{lines}[-1][1], qr/\AProcessed 5 tables, 4 failed\z/, 'summary');
};

subtest 'run: existing files' => sub {
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(tables => ['Orders']);
	export($db, output_dir => $out);

	my ($status, undef, $stderr) = export($db, output_dir => $out);
	is($status, $CONFIG{exit_failure}, 'fails without overwrite');
	like($stderr, qr/^FAILED: Orders: Output file already exists: \Q$out\E.Orders\.csv \(use --overwrite to replace it\) at /m, 'message');
	ticked('run: Output file already exists');

	($status) = export($db, output_dir => $out, overwrite => 1);
	is($status, $CONFIG{exit_ok}, 'overwrite replaces');

	# A folder where the file should go cannot be replaced by rename
	mkdir "$out/Blocked.csv" or die $!;
	open my $fh, '>', "$out/Blocked.csv/keep" or die $!;
	close $fh;
	my $guard2 = mdbtools_scenario(tables => ['Blocked']);
	($status, undef, $stderr) = export($db, output_dir => $out, overwrite => 1);
	is($status, $CONFIG{exit_failure}, 'rename failure');
	# The operating system's own reason: "Is a directory" on Unix,
	# "Permission denied" on Windows
	like($stderr, qr/^FAILED: Blocked: Cannot write \Q$out\E.Blocked\.csv: (?:\Q$OS{eisdir}\E|\Q$OS{eacces}\E) at /m, 'message with OS text');
	ticked('run: Cannot write');
};

subtest 'run: a program that cannot be started' => sub {
	# $? == -1 from run3: the program was found but never ran
	my ($dir, $db, $out) = workspace();
	my $guard = mock_scoped(
		"$CONFIG{exporter}::which" => sub { "$CONFIG{fake_bin}/$_[0]" },
		"$CONFIG{exporter}::run3"  => sub { $! = ENOENT; $? = -1; return 1 },
	);
	throws_ok { $CONFIG{exporter}->new(output_dir => $out, progress => 0)->run($db) }
		qr/\Amdb-tables could not be run: \Q$OS{enoent}\E at /, 'exact message';
	ticked('run: could not be run');
};

subtest 'run: a failing logger' => sub {
	# POD pitfall: the export carries on, with one warning
	{
		package Local::BrokenLogger;
		sub new { return bless {}, shift }
		sub debug { die "log device gone\n" }
		sub info { die "log device gone\n" }
		sub warn { die "log device gone\n" }
	}
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(tables => ['A', 'B']);
	my ($status, undef, $stderr) = export($db, output_dir => $out, logger => Local::BrokenLogger->new());
	is($status, $CONFIG{exit_ok}, 'exports unaffected');
	is(scalar(() = $stderr =~ /^Cannot write to the log: log device gone at /mg), 1, 'warned once');
	ticked('run: Cannot write to the log');
};

subtest 'run: table filter' => sub {
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(tables => ['A', 'B', 'C']);

	my ($status, undef, $stderr) = export($db, output_dir => "$out/1", tables => ['C', 'A', 'nope', 'b']);
	is($status, $CONFIG{exit_ok}, 'unknown names are only a warning');
	ok(-e "$out/1/A.csv" && -e "$out/1/C.csv" && !-e "$out/1/B.csv", 'case-sensitive selection');
	like($stderr, qr/^Tables not found in database: b, nope at /m, 'plural message');

	(undef, undef, $stderr) = export($db, output_dir => "$out/2", tables => ['Z']);
	like($stderr, qr/^Table not found in database: Z at /m, 'singular message');
	ticked('run: Tables not found in database');

	# POD pitfall: an empty list exports nothing and returns 0
	($status) = export($db, output_dir => "$out/3", tables => []);
	is($status, $CONFIG{exit_ok}, 'empty list: 0');
	ok(!glob("$out/3/*.csv"), 'empty list: no files');
};

subtest 'run: dry run and row counts' => sub {
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(tables => ['Orders']);

	my ($status, $stdout) = export($db, output_dir => $out, dry_run => 1, show_counts => 1);
	verbose_diag('dry run', $stdout);
	is($status, $CONFIG{exit_ok}, 'dry run: 0');
	ok(!-e $out, 'nothing created, not even the folder');
	like($stdout, qr/^DRY RUN\n=======$/m, 'title');
	like($stdout, qr/^TABLE\s+ROWS\s+OUTPUT FILE$/m, 'ROWS column');
	like($stdout, qr/^Orders\s+$CONFIG{row_count}\s+Orders\.csv$/m, 'row');

	# POD: show_counts without mdb-count warns and is switched off
	my $guard2 = mdbtools_scenario(tables => ['Orders'], missing => [$CONFIG{mdb_count}]);
	my $e = $CONFIG{exporter}->new(dry_run => 1, show_counts => 1, progress => 0);
	my $stderr;
	($stdout, $stderr) = capture { $status = $e->run($db) };
	is($status, $CONFIG{exit_ok}, 'still 0');
	like($stderr, qr/^mdb-count not found in PATH; row counts are unavailable at /m, 'warning');
	ticked('run: mdb-count not found in PATH');
	unlike($stdout, qr/ROWS/, 'no ROWS column');
	is($e->{show_counts}, 0, 'setting switched off, as documented');
};

subtest 'run: a row count that fails is only a warning' => sub {
	# POD: a failed count warns; an exported table still counts as
	# exported, and a dry run shows "?"
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(tables => ['Orders']);
	my $scenario = \&App::Access2CSV::Exporter::run3;
	my $failing = mock_scoped("$CONFIG{exporter}::run3" => sub {
		return $scenario->(@_) unless $_[0][0] =~ /mdb-count\z/;
		${ $_[3] } = 'broken';
		$? = 1 << 8;
		return 1;
	});
	my ($status, undef, $stderr) = export($db, output_dir => $out, show_counts => 1);
	is($status, $CONFIG{exit_ok}, 'export: still 0');
	ok(-e "$out/Orders.csv", 'exported');
	like($stderr, qr/^Cannot count the rows of Orders: mdb-count failed with exit status 1: broken at /m, 'warning');
	ticked('run: Cannot count the rows of');

	my $stdout;
	($status, $stdout) = export($db, dry_run => 1, show_counts => 1);
	is($status, $CONFIG{exit_ok}, 'dry run: still 0');
	like($stdout, qr/^Orders\s+\?\s+Orders\.csv$/m, 'count shown as "?"');
};

subtest 'run: fatal errors croak before writing anything' => sub {
	my ($dir, $db, $out) = workspace();
	my $missing = File::Spec->catfile($dir, 'missing.accdb');
	my $guard = mdbtools_scenario(tables => ['A']);
	my $e = $CONFIG{exporter}->new(output_dir => $out, progress => 0);

	throws_ok { $e->run($missing) } qr/\ACannot read database \Q$missing\E: \Q$OS{enoent}\E at /, 'missing database';
	ticked('run: Cannot read database');

	throws_ok { $CONFIG{exporter}->run($db) } qr/\Arun\(\) must be called on an object created by new\(\) at /, 'run on the class, not an object';
	ticked('run: must be called on an object');

	{
		# Ctrl-C while mdb-tables runs: the child dies of SIGINT
		my $int = mock_scoped("$CONFIG{exporter}::run3" => sub { ${ $_[3] } = ''; $? = 2; return 1 });
		throws_ok { $e->run($db) } qr/\AInterrupted by SIGINT: stopped, and the table being exported was discarded at /, 'interrupted';
		ticked('run: Interrupted by signal');
	}

	throws_ok { $e->run($dir) } qr/\ADatabase \Q$dir\E is not a regular file at /, 'folder';
	ticked('run: Database is not a regular file');

	SKIP: {
		# chmod 0 cannot make a file unreadable for root, nor on Windows
		# (which has no Unix permission bits)
		skip('root can read any file, so this message cannot be triggered', 1) if $> == 0;
		skip('chmod cannot make a file unreadable on Windows', 1) if $^O eq 'MSWin32';
		chmod 0, $db;
		throws_ok { $e->run($db) } qr/\ADatabase \Q$db\E is not readable at /, 'unreadable';
		chmod oct(644), $db;
	}
	# Under root the condition is impossible, not untested
	ticked('run: Database is not readable');

	ok(!-e $out, 'nothing created by any of these');
};

subtest 'run: mdbtools problems are fatal' => sub {
	my ($dir, $db, $out) = workspace();
	my $e = $CONFIG{exporter}->new(output_dir => $out, progress => 0);

	foreach my $program ($CONFIG{mdb_tables}, $CONFIG{mdb_export}) {
		my $guard = mdbtools_scenario(tables => ['A'], missing => [$program]);
		throws_ok { $e->run($db) } qr/\ARequired program not found in PATH: $program at /, "$program missing";
	}
	ticked('run: Required program not found in PATH');

	{
		my $guard = mdbtools_scenario(tables_exit => $CONFIG{bad_status});
		throws_ok { $e->run($db) } qr/\Amdb-tables failed with exit status $CONFIG{bad_status}: not an Access file at /, 'mdb-tables fails';
		ticked('run: mdb-tables failed with exit status');
	}
	{
		my $guard = mdbtools_scenario(tables_kill => $CONFIG{signal});
		throws_ok { $e->run($db) } qr/\Amdb-tables was killed by signal $CONFIG{signal} at /, 'mdb-tables killed';
		ticked('run: killed by signal (fatal for mdb-tables)');
	}
	ok(!-e $out, 'nothing created');
};

subtest 'run: output folder cannot be created' => sub {
	my ($dir, $db) = workspace();
	my $guard = mdbtools_scenario(tables => ['A']);

	# A regular file in the way: the reason must be about the folder we
	# asked for, not about its parent
	my $out = File::Spec->catdir($db, 'sub');
	throws_ok { $CONFIG{exporter}->new(output_dir => $out, progress => 0)->run($db) }
		# Unix: "Not a directory".  Windows: "No such file or directory",
		# to which File::Path adds the Windows system message ($^E)
		qr/\ACannot create output directory \Q$out\E: (?:\Q$OS{enotdir}\E|\Q$OS{enoent}\E(?:; [^\n]+)?) at /, 'exact message';
	ticked('run: Cannot create output directory');
};

subtest 'run: argument checking' => sub {
	throws_ok { $CONFIG{exporter}->new()->run() } qr/database/, 'no database';
	throws_ok { $CONFIG{exporter}->new()->run('') } qr/'database'/, 'empty database';
};

subtest 'run: does not disturb global state' => sub {
	# The POD lists no global side effects, so none may change, even on
	# a run with a failing table.  (A fatal run croaks, which sets $@ in
	# the caller's eval by design, so it is not checked here.)
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(tables => ['A', 'Bad'], exit => { Bad => $CONFIG{bad_status} });
	my $e = $CONFIG{exporter}->new(output_dir => $out, progress => 0);

	check_globals('run with a failure', sub { $e->run($db) });
	check_globals('new', sub { $CONFIG{exporter}->new(progress => 0) });
};

#######################################################################
# 3. App::Access2CSV::run
#######################################################################

# Run the program; return (status, stdout, stderr)
sub cli {
	my @argv = @_;
	my $status;
	my ($stdout, $stderr) = capture { $status = $CONFIG{app}->run(@argv) };
	return ($status, $stdout, $stderr);
}

subtest 'app: exit 0 for success, --help and --man' => sub {
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(tables => ['Orders']);
	my $log = File::Spec->catfile($dir, 'a.log');
	my @made;
	my $lg = mock_scoped('Log::Abstraction::new' => sub { shift; push @made, {@_}; Local::Logger->new() });

	my ($status, $stdout, $stderr) = cli('--output-dir', $out, '--log', $log, $db);
	is($status, $CONFIG{exit_ok}, 'export: 0');
	returns_ok($status, { type => 'integer', min => 0, max => 3 }, 'Output schema');
	ticked('app: returns 0');
	ok(-e "$out/Orders.csv", 'file written');
	ok(-e $log, 'log file created');
	is($made[0]{logger}, $log, 'log goes to --log file');

	($status, $stdout) = cli('--help');
	is($status, $CONFIG{exit_ok}, '--help: 0');
	like($stdout, qr/Options:/, 'help on STDOUT');

	($status, $stdout) = cli('--man');
	is($status, $CONFIG{exit_ok}, '--man: 0');
	like($stdout, qr/EXIT STATUS/, 'manual on STDOUT');

	@made = ();
	($status) = cli('--no-log', '--dry-run', $db);
	is($status, $CONFIG{exit_ok}, '--dry-run: 0');
	is(scalar(@made), 0, '--no-log: no logger');
	cli('--log', '', '--dry-run', $db);
	is(scalar(@made), 0, "--log '': no logger");
};

subtest 'app: exit 1 when some tables fail' => sub {
	my ($dir, $db, $out) = workspace();
	my $guard = mdbtools_scenario(tables => ['A', 'Bad'], exit => { Bad => $CONFIG{bad_status} });

	my ($status) = cli('--no-log', '--no-progress', '--output-dir', $out, $db);
	is($status, $CONFIG{exit_failure}, 'exit status 1');
	ticked('app: returns 1');
	ok(-e "$out/A.csv", 'the other table was exported');
};

subtest 'app: exit 2 for command-line errors' => sub {
	my ($dir, $db) = workspace();

	my ($status, $stdout, $stderr) = cli('--bogus', $db);
	is($status, $CONFIG{exit_usage}, 'unknown option');
	like($stderr, qr/^Unknown option: bogus$/m, 'message on STDERR');
	is($stdout, '', 'nothing on STDOUT');
	ticked('app: Unknown option');

	($status, undef, $stderr) = cli('--output-dir');
	is($status, $CONFIG{exit_usage}, 'missing value');
	like($stderr, qr/^Option output-dir requires an argument$/m, 'message');
	ticked('app: Option requires an argument');

	($status, undef, $stderr) = cli();
	is($status, $CONFIG{exit_usage}, 'no database');
	like($stderr, qr/^Missing database filename$/m, 'message');
	($status) = cli('a.accdb', 'b.accdb');
	is($status, $CONFIG{exit_usage}, 'two databases');
	ticked('app: Missing database filename');
	ticked('app: returns 2');
};

subtest 'app: exit 3 for fatal errors, as one clean line' => sub {
	my ($dir, $db) = workspace();
	my $missing = File::Spec->catfile($dir, 'missing.accdb');

	my ($status, $stdout, $stderr) = cli('--no-log', $missing);
	is($status, $CONFIG{exit_fatal}, 'missing database');
	is($stderr, "access2csv: Cannot read database $missing: $OS{enoent}\n", 'exact line');
	ticked('app: access2csv: MESSAGE');
	ticked('app: returns 3');

	(undef, undef, $stderr) = cli('--no-log', '--verbose', $missing);
	like($stderr, qr/\Aaccess2csv: Cannot read database .* at \S+ line \d+\.\n\z/, '--verbose adds file and line');

	my $log = File::Spec->catfile($dir, 'no', 'such', 'x.log');
	($status, undef, $stderr) = cli('--log', $log, $db);
	is($status, $CONFIG{exit_fatal}, 'log cannot be opened');
	is($stderr, "access2csv: Cannot open log file $log: $OS{enoent}\n", 'exact line');
	ticked('app: Cannot open log file');

	SKIP: {
		# Windows only allows symbolic links with extra privileges
		skip("cannot create a symbolic link here: $!", 2) unless eval { symlink("$dir/elsewhere", "$dir/link.log") };
		($status, undef, $stderr) = cli('--log', "$dir/link.log", $db);
		is($status, $CONFIG{exit_fatal}, 'log file is a symbolic link');
		is($stderr, "access2csv: Cannot open log file $dir/link.log: it is a symbolic link\n", 'exact reason');
	}
	ticked('app: it is a symbolic link');

	# Database "-": read from standard input, which is reopened here
	my $with_stdin = sub {
		my ($source, @argv) = @_;
		open my $saved, '<&', \*STDIN or die $!;
		open STDIN, '<', $source or die "$source: $!";
		my @result = cli(@argv);
		open STDIN, '<&', $saved or die $!;
		return @result;
	};
	($status, undef, $stderr) = $with_stdin->(File::Spec->devnull(), '--no-log', '-');
	is($status, $CONFIG{exit_fatal}, 'empty standard input');
	is($stderr, "access2csv: Standard input is empty: no database was piped in\n", 'exact message');
	ticked('app: Standard input is empty');

	SKIP: {
		# A folder as standard input opens but cannot be read on Unix.
		# Windows refuses to open a folder as a file at all, and offers no
		# other simple way to make reading standard input fail.
		skip('cannot make reading standard input fail on Windows', 2) if $^O eq 'MSWin32';
		($status, undef, $stderr) = $with_stdin->($dir, '--no-log', '-');
		is($status, $CONFIG{exit_fatal}, 'unreadable standard input (a folder)');
		is($stderr, "access2csv: Cannot read standard input: $OS{eisdir}\n", 'exact message');
	}
	ticked('app: Cannot read standard input');

	SKIP: {
		skip('IO::Pty is needed to provide a terminal', 2) unless eval { require IO::Pty; 1 };
		my $pty = IO::Pty->new();
		($status, undef, $stderr) = $with_stdin->($pty->ttyname(), '--no-log', '-');
		is($status, $CONFIG{exit_usage}, 'terminal on standard input: usage error');
		like($stderr, qr/^Standard input is a terminal: pipe the database in, or give its file name$/m, 'exact message');
	}
	ticked('app: Standard input is a terminal');

	SKIP: {
		# A stalled pipe; a child process then sends SIGTERM to this one.
		# On Windows, fork is emulated and kill 'TERM' ends the whole process
		# outright (there are no signal handlers to catch it), so this can
		# only be tested elsewhere.
		skip('signals cannot interrupt a read on Windows', 2) if $^O eq 'MSWin32';
		pipe(my $reader, my $writer) or die "pipe: $!";
		my $parent = $$;
		my $pid = fork // die "fork: $!";
		if(!$pid) {
			close $reader;
			syswrite($writer, "T\n");
			select(undef, undef, undef, $CONFIG{signal_delay});
			kill 'TERM', $parent;
			select(undef, undef, undef, $CONFIG{signal_delay});
			exit 0;
		}
		close $writer;
		open my $saved, '<&', \*STDIN or die $!;
		open STDIN, '<&', $reader or die $!;
		($status, undef, $stderr) = cli('--no-log', '-');
		open STDIN, '<&', $saved or die $!;
		waitpid($pid, 0);
		is($status, $CONFIG{exit_fatal}, 'interrupted while reading');
		is($stderr, "access2csv: Interrupted by SIGTERM while reading the database from standard input\n", 'exact message');
	}
	ticked('app: Interrupted while reading standard input');

	{
		# mdb-count answers, but not with a number: a warning, count "?"
		my $guard = mdbtools_scenario(tables => ['T']);
		my $scenario = \&App::Access2CSV::Exporter::run3;
		my $odd = mock_scoped("$CONFIG{exporter}::run3" => sub {
			return $scenario->(@_) unless $_[0][0] =~ /mdb-count\z/;
			${ $_[2] } = "no idea\n";
			${ $_[3] } = '';
			$? = 0;
			return 1;
		});
		my $out;
		($status, $out, $stderr) = cli('--no-log', '--dry-run', '--show-counts', $db);
		is($status, $CONFIG{exit_ok}, 'unreadable count: still 0');
		like($stderr, qr/^Cannot count the rows of T: mdb-count printed no number: "no idea\\x0A" at /m, 'exact message');
		like($out, qr/^T\s+\?\s+T\.csv$/m, 'count shown as "?"');
	}
	ticked('run: mdb-count printed no number');

	{
		my $lg = mock_scoped('Log::Abstraction::new' => sub { return });
		($status, undef, $stderr) = cli('--log', File::Spec->catfile($dir, 'y.log'), $db);
		is($status, $CONFIG{exit_fatal}, 'logger constructor returned nothing');
		like($stderr, qr/\Aaccess2csv: Cannot open log file .*: no logger was created\n\z/, 'exact reason');
		ticked('app: no logger was created');
	}

	($status, undef, $stderr) = cli('--no-log', '--encoding', 'ebcdic', $db);
	is($status, $CONFIG{exit_usage}, 'bad encoding is a usage error');
	like($stderr, qr/^Invalid setting: Parameter 'encoding' \(ebcdic\) must be one of utf8, utf8-bom, cp1252$/m, 'exact message');
	ticked('app: Invalid setting');

	my $version_out;
	($status, $version_out) = cli('--version');
	is($status, $CONFIG{exit_ok}, '--version: 0');
	is($version_out, "access2csv version $App::Access2CSV::VERSION\n", '--version: exact text');
	ticked('app: --version');
};

subtest 'app: does not change the caller\'s array or global state' => sub {
	my ($dir, $db) = workspace();
	my $guard = mdbtools_scenario(tables => ['A']);
	my @argv = ('--no-log', '--dry-run', $db);

	check_globals('app success', sub { $CONFIG{app}->run(@argv) });
	check_globals('app fatal', sub { $CONFIG{app}->run('--no-log', File::Spec->catfile($dir, 'missing.accdb')) });
	check_globals('app usage error', sub { $CONFIG{app}->run('--bogus') });
	is_deeply(\@argv, ['--no-log', '--dry-run', $db], '@argv copy unchanged');
};

#######################################################################
# Ledger
#######################################################################

subtest 'every documented message and return state was exercised' => sub {
	verbose_diag('untested', [sort keys %LEDGER]);
	if(%LEDGER) {
		fail("untested POD condition: $_") foreach sort keys %LEDGER;
	} else {
		pass('ledger is empty');
	}
};

restore_all();

done_testing();
