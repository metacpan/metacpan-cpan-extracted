#!perl

# White-box tests: one or more subtests for every function, public and
# private, in each module under lib/, taken one module at a time:
#
#	1. App::Access2CSV::I18N
#	2. App::Access2CSV::Exporter
#	3. App::Access2CSV
#
# Strategy: each function is tested on its own.  The other functions it
# calls - in the same module or in non-core modules such as IPC::Run3,
# File::Which and Log::Abstraction - are replaced with Test::Mockingbird
# mocks, so a failure points at exactly one function.  Params::Get,
# Params::Validate::Strict and Return::Set are spied on rather than
# replaced, because validating arguments is part of each function's job.
#
# Set TEST_VERBOSE=1 to see the internal state behind each check.

use strict;
use warnings;

use Test::Most;
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Returns;

use Capture::Tiny qw(capture capture_stderr capture_stdout);
use Errno qw(ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;

# Loading the application loads all three modules, at compile time, so
# the access-control wrappers of Sub::Private/Sub::Protected are in place
use App::Access2CSV;

# These are white-box tests, so private and protected methods may be called
$Sub::Private::BYPASS = 1;
$Sub::Protected::BYPASS = 1;

# Messages must be English whatever locale the tester uses
delete @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)};

# Names and values shared by many subtests
Readonly::Hash my %CONFIG => (
	i18n          => 'App::Access2CSV::I18N',
	exporter      => 'App::Access2CSV::Exporter',
	app           => 'App::Access2CSV',
	database      => 'shop.accdb',
	table         => 'Orders',
	mdb_tables    => 'mdb-tables',
	mdb_export    => 'mdb-export',
	mdb_count     => 'mdb-count',
	fake_path     => '/opt/mdbtools/bin',
	exit_ok       => 0,
	exit_failure  => 1,
	exit_usage    => 2,
	exit_fatal    => 3,
	child_status  => 3,
	signal        => 15,
	row_count     => 42,
	pod_synopsis  => 0,
	pod_options   => 1,
	pod_full      => 2,
	utf8_bom      => "\xEF\xBB\xBF",
	sentinel      => "sentinel error\n",
	max_name_chars => 64,
	max_name_bytes => 240,
	name_max      => 255,
);

# The text Perl itself uses for ENOENT, in the current locale
Readonly::Scalar my $ENOENT_TEXT => do { local $! = ENOENT; "$!" };

# Show internal state, but only when asked to
sub verbose_diag {
	my ($label, $data) = @_;
	diag("$label: ", Test::More::explain($data)) if $ENV{TEST_VERBOSE};
	return;
}

# UTF-8 bytes of a character string, the form mdbtools gives names in
sub bytes {
	my $text = shift;
	utf8::encode($text);
	return $text;
}

# An exporter with progress lines switched off, so output stays clean
sub new_exporter {
	return $CONFIG{exporter}->new(progress => 0, @_);
}

# Full path of a mocked program, as _verify_dependencies would store it
sub program_path {
	return "$CONFIG{fake_path}/$_[0]";
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

# An exporter double, returned by the mocked Exporter->new in the App tests
{
	package Local::Exporter;

	sub new { my ($class, %args) = @_; return bless { %args }, $class }
	sub run { my ($self, $db) = @_; $self->{ran_with} = $db; return $self->{status} }
}

#######################################################################
# 1. App::Access2CSV::I18N
#######################################################################

subtest 'I18N::i18n formats a plain template with sprintf' => sub {
	# Isolate i18n from language detection and catalog lookup
	my $guard = mock_scoped($CONFIG{i18n},
		_language => sub { 'en' },
		_lookup   => sub { 'Hello %s, you have %d' },
	);

	my $text = $CONFIG{i18n}->i18n('any_key', { params => ['Ann', 2] });
	verbose_diag('formatted', $text);
	is($text, 'Hello Ann, you have 2', 'params are interpolated in order');
	returns_ok($text, { type => 'string' }, 'returns a string');
};

subtest 'I18N::i18n returns a template untouched when there are no params' => sub {
	# A literal "%" would confuse sprintf, so no params must mean no sprintf
	my $guard = mock_scoped($CONFIG{i18n},
		_language => sub { 'en' },
		_lookup   => sub { '100% done' },
	);

	is($CONFIG{i18n}->i18n('any_key'), '100% done', 'percent sign survives');
};

subtest 'I18N::i18n narrows context first, then plural' => sub {
	# The template has context forms, one of which has plural forms
	my $guard = mock_scoped($CONFIG{i18n},
		_language => sub { 'en' },
		_lookup   => sub {
			return {
				female => { one => 'She has %d', other => 'She has %d (many)' },
				other  => 'They have %d',
			};
		},
	);

	my $i18n = $CONFIG{i18n};
	is($i18n->i18n('k', { params => [1], count => 1, context => 'female' }), 'She has 1', 'context + plural one');
	is($i18n->i18n('k', { params => [2], count => 2, context => 'female' }), 'She has 2 (many)', 'context + plural other');
	is($i18n->i18n('k', { params => [2], count => 2, context => 'male' }), 'They have 2', 'unknown context: falls to other');
	is($i18n->i18n('k', { params => [2] }), 'They have 2', 'no context and no count: other');
};

subtest 'I18N::i18n uses "other" when the plural category is missing' => sub {
	# A translation may omit a category; "other" is the safety net
	my $guard = mock_scoped($CONFIG{i18n},
		_language        => sub { 'en' },
		_lookup          => sub { { other => 'n=%d' } },
		_plural_category => sub { 'few' },
	);

	is($CONFIG{i18n}->i18n('k', { params => [3], count => 3 }), 'n=3', 'fell back to other');
};

subtest 'I18N::i18n accepts both calling styles and treats undef as absent' => sub {
	my $i18n = $CONFIG{i18n};
	my $positional = $i18n->i18n('summary', { params => [2, 0], count => 2 });

	is($i18n->i18n({ key => 'summary', args => { params => [2, 0], count => 2 } }), $positional, 'hashref style');
	is($i18n->i18n('missing_database', undef), 'Missing database filename', 'undef args');
	is($i18n->i18n('summary', { params => [2, 0], count => undef }), 'Processed 2 tables, 0 failed', 'undef count');
};

subtest 'I18N::i18n validates its arguments through Params::Validate::Strict' => sub {
	# The spy proves validation is delegated, and the throws prove it bites
	my $spy = spy("$CONFIG{i18n}::validate_strict");
	my $ret = spy("$CONFIG{i18n}::set_return");

	$CONFIG{i18n}->i18n('missing_database');
	my @calls = $spy->();
	verbose_diag('validate_strict calls', \@calls);
	is(scalar(@calls), 1, 'validate_strict called once');
	is(scalar($ret->()), 1, 'set_return called once');
	restore_all();

	my $i18n = $CONFIG{i18n};
	throws_ok { $i18n->i18n() } qr/validate_strict: Required parameter 'key' is missing at /, 'no key';
	throws_ok { $i18n->i18n('') } qr/'key'/, 'empty key';
	throws_ok { $i18n->i18n('summary', 'text') } qr/'args'/, 'args not a hashref';
	throws_ok { $i18n->i18n('summary', { bogus => 1 }) } qr/validate_strict: Unknown parameter 'bogus' at /, 'unknown field';
	throws_ok { $i18n->i18n('summary', { count => -1 }) } qr/Parameter 'count' \(-1\) must be at least 0/, 'negative count';
	throws_ok { $i18n->i18n('summary', { params => 'x' }) } qr/Parameter 'params' must be an arrayref/, 'params not an array';
};

subtest 'I18N::_croak_i18n croaks with the translated text, blaming the caller' => sub {
	my @seen;
	my $guard = mock_scoped("$CONFIG{i18n}::i18n" => sub { shift; @seen = @_; return 'translated boom' });

	my $line = __LINE__ + 1;
	throws_ok { $CONFIG{i18n}->_croak_i18n('some_key', { params => [1] }) } qr/\Atranslated boom at \Q${\ __FILE__ }\E line $line\.\n\z/, 'exact message and location';
	is_deeply(\@seen, ['some_key', { params => [1] }], 'key and args passed through');
};

subtest 'I18N::_carp_i18n warns with the translated text and returns $self' => sub {
	my $guard = mock_scoped("$CONFIG{i18n}::i18n" => sub { 'translated warning' });

	my $result;
	warning_like { $result = $CONFIG{i18n}->_carp_i18n('k') } qr/\Atranslated warning at /, 'warning text';
	is($result, $CONFIG{i18n}, 'returns the invocant for chaining');
};

subtest 'I18N::_language picks the language from object, then environment' => sub {
	# A German catalog must exist, or every choice would fall back to English
	local $App::Access2CSV::I18N::MESSAGES{de} = { dry_run_title => 'PROBELAUF' };
	my $class = $CONFIG{i18n};

	foreach my $case (
		[{}, 'en', 'nothing set: default'],
		[{ LANG => 'de_DE.UTF-8' }, 'de', 'LANG'],
		[{ LANG => 'DE_de' }, 'de', 'case-insensitive'],
		[{ LANGUAGE => 'de:fr', LANG => 'en_GB' }, 'de', 'LANGUAGE wins, first entry'],
		[{ LANGUAGE => 'fr:de' }, 'en', 'only the first LANGUAGE entry counts'],
		[{ LC_ALL => 'C', LANG => 'de_DE' }, 'de', 'C means no preference'],
		[{ LC_ALL => 'POSIX' }, 'en', 'POSIX alone: default'],
		[{ LANG => 'ja_JP.UTF-8' }, 'en', 'no Japanese catalog'],
		[{ LANG => '!!' }, 'en', 'garbage'],
		[{ LANG => 'de@euro' }, 'de', 'modifier without territory'],
	) {
		my ($env, $expected, $name) = @{$case};
		local @ENV{keys %{$env}} = values %{$env};
		is($class->_language(), $expected, $name);
	}

	local $ENV{LANG} = 'de_DE';
	is(bless({ language => 'en' }, $class)->_language(), 'en', 'object language beats the environment');
	is(bless({}, $class)->_language(), 'de', 'object without language uses the environment');
};

subtest 'I18N::_lookup falls back to English and confesses on unknown keys' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { dry_run_title => 'PROBELAUF' };
	my $class = $CONFIG{i18n};

	is($class->_lookup('de', 'dry_run_title'), 'PROBELAUF', 'translated key');
	is($class->_lookup('de', 'column_rows'), 'ROWS', 'untranslated key falls back');
	is($class->_lookup('xx', 'column_rows'), 'ROWS', 'unknown language falls back');
	is(ref($class->_lookup('en', 'summary')), 'HASH', 'structured template returned as is');

	# confess (not croak) because an unknown key is a programming error
	throws_ok { $class->_lookup('en', 'nope') } qr/\AUnknown message key: nope at .*\n.*called at /s, 'confess with a stack trace';

	# The error must still be readable if the catalog lost its own message
	local $App::Access2CSV::I18N::MESSAGES{en} = { %{ $App::Access2CSV::I18N::MESSAGES{en} } };
	delete $App::Access2CSV::I18N::MESSAGES{en}{unknown_message};
	throws_ok { $class->_lookup('en', 'nope') } qr/\AUnknown message key: nope at /, 'built-in fallback text';
};

subtest 'I18N::_plural_category applies per-language rules' => sub {
	my $plural = \&App::Access2CSV::I18N::_plural_category;

	is($plural->('en', 1), 'one', 'en 1');
	is($plural->('en', 0), 'other', 'en 0');
	is($plural->('en', 2), 'other', 'en 2');
	is($plural->('fr', 0), 'one', 'fr treats 0 as singular');
	is($plural->('ja', 1), 'other', 'ja has no singular');
	is($plural->('xx', 1), 'one', 'unknown language uses the English rule');
	is($plural->('en', undef), 'other', 'no count means other');
};

#######################################################################
# 2. App::Access2CSV::Exporter
#######################################################################

subtest 'Exporter::new applies defaults, drops undef and copies the table list' => sub {
	my @tables = ('A');
	my $spy = spy("$CONFIG{exporter}::validate_strict");
	my $e = $CONFIG{exporter}->new(tables => \@tables, overwrite => undef, encoding => 'cp1252');
	push @tables, 'B';
	verbose_diag('new exporter', $e);

	is(scalar($spy->()), 1, 'arguments validated');
	restore_all();

	returns_ok($e, { type => 'object', isa => $CONFIG{exporter} }, 'returns an exporter');
	is($e->{output_dir}, File::Spec->curdir(), 'default output_dir');
	is($e->{overwrite}, 0, 'undef means default');
	is($e->{progress}, 1, 'default progress');
	is($e->{encoding}, 'cp1252', 'given value kept');
	is_deeply($e->{tables}, ['A'], 'caller changes do not leak in');
	is_deeply($e->{used_names}, {}, 'no names used yet');
	is_deeply($e->{programs}, {}, 'no programs found yet');
	memory_cycle_ok($e, 'no reference cycles');

	isa_ok($CONFIG{exporter}->new({ dry_run => 1 }), $CONFIG{exporter}, 'hashref form');
};

subtest 'Exporter::new rejects bad settings' => sub {
	my $class = $CONFIG{exporter};
	throws_ok { $class->new(bogus => 1) } qr/Unknown parameter 'bogus'/, 'unknown setting';
	throws_ok { $class->new(encoding => 'latin1') } qr/Parameter 'encoding' \(latin1\) must be one of utf8, utf8-bom, cp1252/, 'encoding';
	throws_ok { $class->new(logger => 'x.log') } qr/Parameter 'logger' must be an object/, 'logger not an object';
	throws_ok { $class->new(logger => bless({}, 'Local::Mute')) } qr/understands the debug method/, 'logger without methods';
	throws_ok { $class->new(tables => 'Orders') } qr/'tables'/, 'tables not an array';
	throws_ok { $class->new(tables => [[1]]) } qr/'?tables'? can only contain strings/, 'tables of non-strings';
	throws_ok { $class->new(output_dir => '') } qr/'output_dir'/, 'empty output_dir';
};

subtest 'Exporter::run calls its steps in order and maps failures to status' => sub {
	my @order;
	my $failures = 0;

	# Every step is mocked; each records its name so the order can be checked
	my $guard = mock_scoped($CONFIG{exporter},
		_check_database      => sub { push @order, "check:$_[1]"; $_[0] },
		_verify_dependencies => sub { push @order, 'verify'; $_[0] },
		_reset_names         => sub { push @order, 'reset'; $_[0] },
		_get_tables          => sub { push @order, 'list'; ['A', 'B'] },
		_select_tables       => sub { push @order, 'select'; $_[1] },
		_dry_run             => sub { push @order, 'dry_run'; $_[0] },
		_make_output_dir     => sub { push @order, 'mkdir'; $_[0] },
		_export_all          => sub { push @order, "export:@{ $_[2] }"; $failures },
	);

	my $e = new_exporter();
	my $status = $e->run($CONFIG{database});
	verbose_diag('call order', \@order);
	is_deeply(\@order, ["check:$CONFIG{database}", qw(verify reset list select mkdir), 'export:A B'], 'order');
	returns_ok($status, { type => 'integer', min => 0, max => 1 }, 'status in range');
	is($status, $CONFIG{exit_ok}, 'no failures: 0');

	$failures = 2;
	is($e->run({ database => $CONFIG{database} }), $CONFIG{exit_failure}, 'failures: 1 (hashref form)');

	@order = ();
	is(new_exporter(dry_run => 1)->run($CONFIG{database}), $CONFIG{exit_ok}, 'dry run: 0');
	ok(!grep({ /^(?:mkdir|export)/ } @order), 'dry run neither creates the directory nor exports');
	ok((grep { $_ eq 'dry_run' } @order), 'dry run listing produced');
};

subtest 'Exporter::run requires a database argument' => sub {
	throws_ok { new_exporter()->run() } qr/\AUsage: .*run\(database => \$val\)/, 'missing database';
	throws_ok { new_exporter()->run('') } qr/'database'/, 'empty database';
};

subtest 'Exporter::_check_database accepts only readable regular files' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $e = new_exporter();
	my $missing = File::Spec->catfile($dir, 'missing.accdb');

	my $line = __LINE__ + 1;
	throws_ok { $e->_check_database($missing) } qr/\ACannot read database \Q$missing\E: \Q$ENOENT_TEXT\E at \Q${\ __FILE__ }\E line $line\.\n\z/, 'missing: exact message with OS text';
	throws_ok { $e->_check_database($dir) } qr/\ADatabase \Q$dir\E is not a regular file at /, 'directory';

	my $db = File::Spec->catfile($dir, $CONFIG{database});
	open my $fh, '>', $db or die "$db: $!";
	close $fh;
	is($e->_check_database($db), $e, 'readable file: returns $self');

	SKIP: {
		# chmod 0 cannot make a file unreadable for root, nor on Windows
		skip('root can read any file', 1) if $> == 0;
		skip('chmod cannot make a file unreadable on Windows', 1) if $^O eq 'MSWin32';
		chmod 0, $db;
		throws_ok { $e->_check_database($db) } qr/\ADatabase \Q$db\E is not readable at /, 'unreadable';
		chmod oct(644), $db;
	}
};

subtest 'Exporter::_verify_dependencies finds the required programs' => sub {
	my @looked_up;
	my $guard = mock_scoped("$CONFIG{exporter}::_find_program" => sub { push @looked_up, $_[1]; program_path($_[1]) });

	my $e = new_exporter();
	is($e->_verify_dependencies(), $e, 'returns $self');
	is_deeply(\@looked_up, [$CONFIG{mdb_tables}, $CONFIG{mdb_export}], 'mdb-count not looked for without show_counts');
	is_deeply($e->{programs}, {
		$CONFIG{mdb_tables} => program_path($CONFIG{mdb_tables}),
		$CONFIG{mdb_export} => program_path($CONFIG{mdb_export}),
	}, 'paths stored');

	@looked_up = ();
	my $counting = new_exporter(show_counts => 1);
	$counting->_verify_dependencies();
	is($looked_up[-1], $CONFIG{mdb_count}, 'mdb-count looked for with show_counts');
	is($counting->{programs}{ $CONFIG{mdb_count} }, program_path($CONFIG{mdb_count}), 'and stored');
};

subtest 'Exporter::_verify_dependencies croaks or degrades when programs are missing' => sub {
	my %present;
	my @warned;
	my $guard = mock_scoped($CONFIG{exporter},
		_find_program => sub { $present{ $_[1] } ? program_path($_[1]) : undef },
		_warn         => sub { push @warned, $_[1]; $_[0] },
	);

	throws_ok { new_exporter()->_verify_dependencies() } qr/\ARequired program not found in PATH: mdb-tables at /, 'first missing program named';

	%present = ($CONFIG{mdb_tables} => 1);
	throws_ok { new_exporter()->_verify_dependencies() } qr/\ARequired program not found in PATH: mdb-export at /, 'second program checked too';

	# A missing mdb-count only switches row counts off, with a warning
	%present = ($CONFIG{mdb_tables} => 1, $CONFIG{mdb_export} => 1);
	my $e = new_exporter(show_counts => 1);
	lives_ok { $e->_verify_dependencies() } 'mdb-count is optional';
	is($e->{show_counts}, 0, 'show_counts switched off');
	ok(!exists $e->{programs}{ $CONFIG{mdb_count} }, 'no undef entry left behind');
	is_deeply(\@warned, ['no_row_counter'], 'warned once');
};

subtest 'Exporter::_find_program wraps File::Which and logs in verbose mode' => sub {
	my $found = program_path($CONFIG{mdb_export});
	my $guard = mock_scoped("$CONFIG{exporter}::which" => sub { $_[0] eq $CONFIG{mdb_export} ? $found : undef });

	my $logger = Local::Logger->new();
	my $e = new_exporter(verbose => 1, logger => $logger);
	is($e->_find_program($CONFIG{mdb_export}), $found, 'path returned');
	is_deeply($logger->{lines}, [['debug', "Found $CONFIG{mdb_export} at $found"]], 'debug message');

	is($e->_find_program('nothing'), undef, 'not found: undef');
	is(scalar(@{ $logger->{lines} }), 1, 'nothing logged for a missing program');

	my $quiet = Local::Logger->new();
	new_exporter(logger => $quiet)->_find_program($CONFIG{mdb_export});
	is_deeply($quiet->{lines}, [], 'nothing logged without verbose');
};

subtest 'Exporter::_reset_names forgets allocated file names' => sub {
	my $e = new_exporter();
	my $old = $e->{used_names};
	$old->{'orders.csv'} = 1;

	is($e->_reset_names(), $e, 'returns $self');
	is_deeply($e->{used_names}, {}, 'empty');
	isnt($e->{used_names}, $old, 'a new hash, so old references cannot interfere');
};

subtest 'Exporter::_get_tables lists, filters and sorts user tables' => sub {
	my @calls;
	my $guard = mock_scoped("$CONFIG{exporter}::_run_program" => sub {
		my ($self, $name, $args, $stdout) = @_;
		push @calls, [$name, $args];
		${$stdout} = "Orders\r\nMSysObjects\n\nCustomers\n~TMPCLP\nUSysRibbons\n";
		return $self;
	});

	my $tables = new_exporter()->_get_tables($CONFIG{database});
	verbose_diag('tables', $tables);
	returns_ok($tables, { type => 'arrayref' }, 'arrayref');
	is_deeply($tables, ['Customers', 'Orders'], 'sorted, system tables and blanks dropped, CR removed');
	is_deeply(\@calls, [[$CONFIG{mdb_tables}, ['-1', '--', $CONFIG{database}]]], 'one name per line, options ended by --');
};

subtest 'Exporter::_is_system_table recognises Access internal tables' => sub {
	my $e = new_exporter();
	is($e->_is_system_table($_), 1, "$_ is a system table") foreach qw(MSysObjects msysACEs USysRibbons ~TMPCLP1);
	is($e->_is_system_table($_), 0, "$_ is a user table") foreach ('Orders', 'MyMSys', 'Sys', 'User ~ table');
};

subtest 'Exporter::_select_tables applies the table filter' => sub {
	my @warned;
	my $guard = mock_scoped("$CONFIG{exporter}::_warn" => sub { shift; push @warned, [@_]; return });

	my $all = ['A', 'B', 'C'];
	is(new_exporter()->_select_tables($all), $all, 'no filter: same list');

	my $picked = new_exporter(tables => ['C', 'A', 'Nope', 'Nada'])->_select_tables($all);
	is_deeply($picked, ['A', 'C'], 'database order kept');
	is_deeply(\@warned, [['unknown_tables', { params => ['Nada, Nope'], count => 2 }]], 'unknown names warned, sorted, with count');

	@warned = ();
	new_exporter(tables => ['B'])->_select_tables($all);
	is_deeply(\@warned, [], 'no warning when all are found');
};

subtest 'Exporter::_make_output_dir creates the directory or croaks' => sub {
	my $dir = tempdir(CLEANUP => 1);

	# An existing directory must not even reach File::Path
	my $spy = spy("$CONFIG{exporter}::make_path");
	my $e = new_exporter(output_dir => $dir);
	is($e->_make_output_dir(), $e, 'existing directory: returns $self');
	is(scalar($spy->()), 0, 'make_path not called');
	restore_all();

	my $nested = File::Spec->catdir($dir, 'a', 'b');
	new_exporter(output_dir => $nested)->_make_output_dir();
	ok(-d $nested, 'nested directory created');

	# File::Path reports errors through its error option
	my $bad = File::Spec->catdir($dir, 'denied');
	my $guard = mock_scoped("$CONFIG{exporter}::make_path" => sub {
		my ($path, $opts) = @_;
		${ $opts->{error} } = [{ $path => 'Permission denied' }];
		return;
	});
	throws_ok { new_exporter(output_dir => $bad)->_make_output_dir() } qr/\ACannot create output directory \Q$bad\E: Permission denied at /, 'exact message';
};

subtest 'Exporter::_make_output_dir notices a directory that silently did not appear' => sub {
	my $bad = File::Spec->catdir(tempdir(CLEANUP => 1), 'ghost');
	my $guard = mock_scoped("$CONFIG{exporter}::make_path" => sub { ${ $_[1]{error} } = []; $! = ENOENT; return });
	throws_ok { new_exporter(output_dir => $bad)->_make_output_dir() } qr/\ACannot create output directory \Q$bad\E: \Q$ENOENT_TEXT\E at /, 'OS text used';
};

subtest 'Exporter::_export_all carries on past failures and counts them' => sub {
	my (@exported, @warned, @logged);
	my $guard = mock_scoped($CONFIG{exporter},
		_export_table => sub { push @exported, $_[2]; die "kaput\n" if $_[2] eq 'Bad'; $_[0] },
		_warn         => sub { shift; push @warned, [@_]; return },
		_log          => sub { shift; push @logged, [@_]; return },
	);

	my $e = new_exporter(progress => 1);
	my $failed;
	my $stderr = capture_stderr { $failed = $e->_export_all($CONFIG{database}, ['A', 'Bad', 'C']) };
	verbose_diag('progress', $stderr);

	is($failed, 1, 'one failure');
	returns_ok($failed, { type => 'integer', min => 0 }, 'a count');
	is_deeply(\@exported, ['A', 'Bad', 'C'], 'every table attempted');
	is($stderr, "[1/3] A\n[2/3] Bad\n[3/3] C\n", 'progress lines');
	is_deeply(\@warned, [['export_failed', { params => ['Bad', 'kaput'] }]], 'failure warned without newline');
	is_deeply(\@logged, [['info', 'summary', { params => [3, 1], count => 3 }]], 'summary logged');

	my $quiet;
	$stderr = capture_stderr { $quiet = new_exporter()->_export_all($CONFIG{database}, []) };
	is($quiet, 0, 'empty list: no failures');
	is($stderr, '', 'no progress when switched off');
};

subtest 'Exporter::_export_all exports every table even if the list was partly iterated' => sub {
	# A caller may have used each() on the same array; that must not
	# make the export skip tables
	my @exported;
	my $guard = mock_scoped($CONFIG{exporter},
		_export_table => sub { push @exported, $_[2]; $_[0] },
		_log          => sub { $_[0] },
	);

	my @tables = ('A', 'B', 'C');
	my ($first) = each @tables;
	new_exporter()->_export_all($CONFIG{database}, \@tables);
	is_deeply(\@exported, ['A', 'B', 'C'], 'no table skipped');
};

subtest 'Exporter::_export_all leaves the caller\'s $@ alone' => sub {
	my $guard = mock_scoped($CONFIG{exporter},
		_export_table => sub { die "kaput\n" },
		_warn         => sub { $_[0] },
		_log          => sub { $_[0] },
	);

	# Build the object first: the constructor's own validation may reset $@
	my $e = new_exporter();
	local $@ = $CONFIG{sentinel};
	$e->_export_all($CONFIG{database}, ['A']);
	is($@, $CONFIG{sentinel}, '$@ localised');
};

# Export helpers write through _run_program into a file handle; this
# double does the same with fixed content
sub mock_export_output {
	my ($content, $calls) = @_;
	return ("$CONFIG{exporter}::_run_program" => sub {
		my ($self, $name, $args, $fh) = @_;
		push @{$calls}, [$name, $args] if $calls;
		print {$fh} $content;
		$fh->flush();
		return $self;
	});
}

subtest 'Exporter::_export_table writes the data through a temporary file' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my (@calls, %installed, @logged);

	my $guard = mock_scoped(
		mock_export_output("\"id\"\n1\n", \@calls),
		"$CONFIG{exporter}::_csv_filename" => sub { "$_[1].csv" },
		"$CONFIG{exporter}::_install_file" => sub {
			my ($self, $tmp, $out) = @_;
			open my $fh, '<:raw', $tmp->filename() or die $!;
			local $/;
			%installed = (content => scalar(<$fh>), out => $out, tmp => $tmp->filename());
			return $self;
		},
		"$CONFIG{exporter}::_log" => sub { shift; push @logged, [@_]; $_[0] },
	);

	my $e = new_exporter(output_dir => $dir);
	is($e->_export_table($CONFIG{database}, $CONFIG{table}), $e, 'returns $self');
	verbose_diag('installed', \%installed);

	my $outfile = File::Spec->catfile($dir, "$CONFIG{table}.csv");
	is($installed{content}, "\"id\"\n1\n", 'data copied unchanged');
	is($installed{out}, $outfile, 'target path');
	like((File::Spec->splitpath($installed{tmp}))[2], qr/\A\.access2csv-/, 'hidden temporary file');
	is((File::Spec->splitpath($installed{tmp}))[1], (File::Spec->splitpath($outfile))[1], 'temporary file next to the target');
	is_deeply(\@calls, [[$CONFIG{mdb_export}, ['--', $CONFIG{database}, $CONFIG{table}]]], 'mdb-export arguments, options ended by --');
	is_deeply(\@logged, [['info', 'exported', { params => [$CONFIG{table}, $outfile] }]], 'logged');

	new_exporter(output_dir => $dir, encoding => 'utf8-bom')->_export_table($CONFIG{database}, $CONFIG{table});
	is($installed{content}, "$CONFIG{utf8_bom}\"id\"\n1\n", 'BOM written once, before the data');
};

subtest 'Exporter::_export_table sends cp1252 through the transcoder and counts rows' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my (@transcoded, @ran, @logged);

	my $guard = mock_scoped($CONFIG{exporter},
		_run_program       => sub { push @ran, $_[1]; $_[0] },
		_export_transcoded => sub { push @transcoded, $_[2]; $_[0] },
		_install_file      => sub { $_[0] },
		_count_rows        => sub { $CONFIG{row_count} },
		_log               => sub { shift; push @logged, [@_]; $_[0] },
	);

	new_exporter(output_dir => $dir, encoding => 'cp1252', show_counts => 1)->_export_table($CONFIG{database}, $CONFIG{table});
	is_deeply(\@transcoded, [$CONFIG{table}], 'transcoder used');
	is_deeply(\@ran, [], 'mdb-export not run directly');
	is($logged[0][1], 'exported_rows', 'row count message');
	is($logged[0][2]{count}, $CONFIG{row_count}, 'count chooses the plural form');
};

subtest 'Exporter::_export_table refuses to overwrite without permission' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $outfile = File::Spec->catfile($dir, "$CONFIG{table}.csv");
	open my $fh, '>', $outfile or die "$outfile: $!";
	close $fh;

	my @ran;
	my $guard = mock_scoped(
		"$CONFIG{exporter}::_run_program" => sub { push @ran, 1; $_[0] },
		"$CONFIG{exporter}::_install_file" => sub { $_[0] },
		"$CONFIG{exporter}::_log" => sub { $_[0] },
	);

	throws_ok { new_exporter(output_dir => $dir)->_export_table($CONFIG{database}, $CONFIG{table}) }
		qr/\AOutput file already exists: \Q$outfile\E \(use --overwrite to replace it\) at /, 'exact message';
	is(scalar(@ran), 0, 'nothing exported before the check');

	lives_ok { new_exporter(output_dir => $dir, overwrite => 1)->_export_table($CONFIG{database}, $CONFIG{table}) } 'allowed with overwrite';
};

subtest 'Exporter::_export_transcoded converts UTF-8 to Windows-1252' => sub {
	my @calls;
	my $guard = mock_scoped(mock_export_output("\"name\"\n\"Caf\xC3\xA9 \xE2\x82\xAC\"\n", \@calls));

	open my $out, '>:raw', \my $buffer or die $!;
	my $e = new_exporter(output_dir => tempdir(CLEANUP => 1));
	is($e->_export_transcoded($CONFIG{database}, $CONFIG{table}, $out), $e, 'returns $self');
	close $out;

	is($buffer, "\"name\"\n\"Caf\xE9 \x80\"\n", 'e-acute and Euro converted');
	is_deeply(\@calls, [[$CONFIG{mdb_export}, ['--', $CONFIG{database}, $CONFIG{table}]]], 'mdb-export arguments, options ended by --');
};

subtest 'Exporter::_export_transcoded reports bad input with line numbers' => sub {
	my $dir = tempdir(CLEANUP => 1);
	open my $out, '>:raw', \my $buffer or die $!;

	{
		my $guard = mock_scoped(mock_export_output("ok\nCaf\xE9\n"));
		throws_ok { new_exporter(output_dir => $dir)->_export_transcoded($CONFIG{database}, $CONFIG{table}, $out) }
			qr/\ATable $CONFIG{table}, line 2: output of mdb-export is not valid UTF-8 at /, 'invalid UTF-8';
	}
	{
		my $guard = mock_scoped(mock_export_output("ok\nok\n\xE6\x97\xA5\n"));
		throws_ok { new_exporter(output_dir => $dir)->_export_transcoded($CONFIG{database}, $CONFIG{table}, $out) }
			qr/\ATable $CONFIG{table}, line 3: cannot be represented in cp1252 at /, 'unmappable character';
	}
};

subtest 'Exporter::_export_transcoded leaves the caller\'s $. and $@ alone' => sub {
	# Reading the spool file must not change which handle $. refers to
	open my $in, '<', \"one\ntwo\nthree\n" or die $!;
	<$in> for 1 .. 2;
	my $before = $.;

	my $guard = mock_scoped(mock_export_output("a\nb\nc\nd\n"));
	open my $out, '>:raw', \my $buffer or die $!;
	my $e = new_exporter(output_dir => tempdir(CLEANUP => 1));
	local $@ = $CONFIG{sentinel};
	$e->_export_transcoded($CONFIG{database}, $CONFIG{table}, $out);

	is($., $before, '$. still refers to the caller\'s handle');
	is($@, $CONFIG{sentinel}, '$@ localised');
};

subtest 'Exporter::_install_file renames into place with normal permissions' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $outfile = File::Spec->catfile($dir, 'out.csv');
	my $e = new_exporter(output_dir => $dir);

	my $old_umask = umask(oct(22));
	{
		my $tmp = File::Temp->new(DIR => $dir, UNLINK => 1);
		print {$tmp} "data\n";
		local $@ = $CONFIG{sentinel};
		is($e->_install_file($tmp, $outfile), $e, 'returns $self');
		is($@, $CONFIG{sentinel}, '$@ localised');
		ok(!-e $tmp->filename(), 'temporary name gone');
	}
	umask($old_umask);

	ok(-f $outfile, 'still there after the temporary object is destroyed');

	# Whatever the platform, the result is an ordinary file the user can
	# read and write (File::Temp's own files are private, mode 0600)
	ok(-r $outfile && -w $outfile, 'readable and writable');

	SKIP: {
		# Windows has no Unix permission bits: stat() makes the mode up from
		# the read-only flag (0666 for any writable file) and umask has no
		# effect, so the exact bits can only be checked elsewhere
		skip('Unix permission bits do not exist on Windows', 1) if $^O eq 'MSWin32';
		is((stat($outfile))[2] & oct(777), oct(644), '0666 less umask 022');
	}
};

subtest 'Exporter::_install_file croaks with the OS reason on failure' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $outfile = File::Spec->catfile($dir, 'no', 'such', 'dir', 'out.csv');
	my $tmp = File::Temp->new(DIR => $dir, UNLINK => 1);

	throws_ok { new_exporter()->_install_file($tmp, $outfile) } qr/\ACannot write \Q$outfile\E: \Q$ENOENT_TEXT\E at /, 'exact message';
};

subtest 'Exporter::_count_rows reads the number from mdb-count' => sub {
	my ($output, @calls) = ("  $CONFIG{row_count}\n");
	my $guard = mock_scoped("$CONFIG{exporter}::_run_program" => sub {
		push @calls, [$_[1], $_[2]];
		${ $_[3] } = $output;
		return $_[0];
	});

	my $rows = new_exporter()->_count_rows($CONFIG{database}, $CONFIG{table});
	is($rows, $CONFIG{row_count}, 'number parsed despite whitespace');
	returns_ok($rows, { type => 'integer', min => 0 }, 'an integer');
	is_deeply(\@calls, [[$CONFIG{mdb_count}, ['--', $CONFIG{database}, $CONFIG{table}]]], 'mdb-count arguments, options ended by --');

	# Anything that is not just a number is reported, never taken as 0
	$output = '';
	throws_ok { new_exporter()->_count_rows($CONFIG{database}, $CONFIG{table}) } qr/\Amdb-count printed no number: "" at /, 'no output: reported';
	$output = "count: 12 rows\n";
	throws_ok { new_exporter()->_count_rows($CONFIG{database}, $CONFIG{table}) } qr/\Amdb-count printed no number: "count: 12 rows\\x0A" at /, 'extra text: reported';
};

# Replaces run3 with a double that records its arguments, writes to
# stderr and sets the child status
sub mock_run3 {
	my ($status, $stderr_text, $calls) = @_;
	return ("$CONFIG{exporter}::run3" => sub {
		my ($cmd, $stdin, $stdout, $stderr) = @_;
		push @{$calls}, [$cmd, $stdin, $stdout] if $calls;
		${$stderr} = $stderr_text;
		$? = $status;
		return 1;
	});
}

subtest 'Exporter::_run_program runs the program with a list, not a shell string' => sub {
	my @calls;
	my $guard = mock_scoped(mock_run3(0, '', \@calls));

	my $e = new_exporter();
	$e->{programs} = { $CONFIG{mdb_export} => program_path($CONFIG{mdb_export}) };
	my $stdout = '';
	is($e->_run_program($CONFIG{mdb_export}, [$CONFIG{database}, 'Or; rm -rf /'], \$stdout), $e, 'returns $self');
	verbose_diag('run3 call', \@calls);

	is_deeply($calls[0][0], [program_path($CONFIG{mdb_export}), $CONFIG{database}, 'Or; rm -rf /'], 'command as a list');
	is(${ $calls[0][1] }, undef, 'stdin is empty');
	is($calls[0][2], \$stdout, 'stdout passed through');
};

subtest 'Exporter::_run_program croaks on exit status and signals' => sub {
	my $e = new_exporter();
	$e->{programs} = { $CONFIG{mdb_export} => program_path($CONFIG{mdb_export}) };

	{
		my $guard = mock_scoped(mock_run3($CONFIG{child_status} << 8, "corrupt table\n"));
		throws_ok { $e->_run_program($CONFIG{mdb_export}, [], \my $out) }
			qr/\A$CONFIG{mdb_export} failed with exit status $CONFIG{child_status}: corrupt table at /, 'exit status, stderr chomped';
	}
	{
		my $guard = mock_scoped(mock_run3($CONFIG{signal}, ''));
		throws_ok { $e->_run_program($CONFIG{mdb_export}, [], \my $out) }
			qr/\A$CONFIG{mdb_export} was killed by signal $CONFIG{signal} at /, 'signal';
	}
};

subtest 'Exporter::_run_program leaves the caller\'s $? alone' => sub {
	my $e = new_exporter();
	$e->{programs} = { $CONFIG{mdb_export} => program_path($CONFIG{mdb_export}) };
	my $guard = mock_scoped(mock_run3(0, ''));

	local $? = $CONFIG{child_status} << 8;
	open my $in, '<', \"a\nb\n" or die $!;
	<$in>;
	$e->_run_program($CONFIG{mdb_export}, [], \my $out);
	is($? >> 8, $CONFIG{child_status}, '$? localised');
	is($., 1, '$. still refers to the caller\'s handle');
};

subtest 'Exporter::_csv_filename makes safe, unique names' => sub {
	# The full matrix is in t/filename-collision.t; these are the rules
	my $e = new_exporter();
	is($e->_csv_filename('A/B'), 'A_B.csv', 'unsafe character');
	is($e->_csv_filename('a:b'), 'a_b_2.csv', 'case-insensitive collision');
	is($e->_csv_filename('A_B_2'), 'A_B_2_2.csv', 'suffix cannot collide with a real name');
	is($e->_csv_filename('NUL'), '_NUL.csv', 'device name');
	is($e->_csv_filename(' .x. '), '_x.csv', 'trim, no hidden file, no trailing dot');
	is($e->_csv_filename(undef), 'unnamed.csv', 'undef');
	is_deeply([sort keys %{ $e->{used_names} }], [sort map { lc } qw(A_B.csv a_b_2.csv A_B_2_2.csv _NUL.csv _x.csv unnamed.csv)], 'all names recorded in lower case');
	returns_ok($e->_csv_filename('z'), { type => 'string', matches => qr/\.csv\z/ }, 'a .csv name');
};

subtest 'Exporter::_csv_filename replaces bad bytes, shortens long names, then trims the end' => sub {
	my $e = new_exporter();
	my $max = $CONFIG{max_name_chars};
	is($e->_csv_filename(('a' x ($max - 1)) . ' bc'), ('a' x ($max - 1)) . '.csv', 'space left at the cut is removed');
	is($e->_csv_filename(('b' x ($max - 1)) . '.c'), ('b' x ($max - 1)) . '.csv', 'dot left at the cut is removed');
	is($e->_csv_filename("Caf\xE9 \xC3"), 'Caf_ _.csv', 'bytes that are not UTF-8 replaced');
	is($e->_csv_filename(('c' x ($max - 1)) . "\xFF\xFF"), ('c' x ($max - 1)) . '_.csv', 'replaced before shortening');
};

subtest 'Exporter::_shorten_name keeps whole graphemes within both limits' => sub {
	my $e = new_exporter();
	my $max = $CONFIG{max_name_chars};

	is($e->_shorten_name('a' x $max), 'a' x $max, 'at the limit: unchanged');
	is($e->_shorten_name('a' x ($max + 1)), 'a' x $max, 'one over: cut');

	# Characters in, characters out (and bytes in, bytes out)
	my $chars = "\x{fc}" x $CONFIG{name_max};
	utf8::upgrade($chars);    # below U+0100, Perl would otherwise keep it as bytes
	my $short = $e->_shorten_name($chars);
	ok(utf8::is_utf8($short), 'character string stays a character string');
	is($short, "\x{fc}" x $max, 'counted in characters, not bytes');

	my $bytes = $chars;
	utf8::encode($bytes);
	$short = $e->_shorten_name($bytes);
	ok(!utf8::is_utf8($short), 'byte string stays a byte string');
	is($short, bytes("\x{fc}" x $max), 'UTF-8 bytes: 64 whole characters');

	# 64 emoji are 256 bytes: the byte limit applies first
	my $emoji = "\x{1F600}";
	is($e->_shorten_name($emoji x $max), $emoji x ($CONFIG{max_name_bytes} / 4), 'byte limit: 60 emoji');

	# A 4-byte character that would cross the byte limit is dropped whole
	$short = $e->_shorten_name(bytes('xx' . ($emoji x ($max - 2))));
	is($short, bytes('xx' . ($emoji x 59)), 'not split at the byte limit');
	ok(utf8::decode(my $copy = $short), 'result is still valid UTF-8');

	# A letter is not separated from its combining accent (2 characters)
	my $accented = "e\x{301}";
	is($e->_shorten_name($accented x $max), $accented x ($max / 2), 'graphemes kept whole');
	is($e->_shorten_name('x' . ($accented x $max)), 'x' . ($accented x ($max / 2 - 1)), 'one that would be cut is dropped');

};

subtest 'Exporter::_dry_run prints the table list' => sub {
	my $guard = mock_scoped($CONFIG{exporter},
		_csv_filename => sub { "$_[1].csv" },
		_count_rows   => sub { $CONFIG{row_count} },
	);

	my $e = new_exporter();
	my $result;
	my $stdout = capture_stdout { $result = $e->_dry_run($CONFIG{database}, ['Orders']) };
	verbose_diag('dry run', $stdout);
	is($result, $e, 'returns $self');
	is($stdout, "\nDRY RUN\n=======\n\n" . sprintf("%-40s %s\n", 'TABLE', 'OUTPUT FILE') . ('-' x 70) . "\n" . sprintf("%-40s %s\n", 'Orders', 'Orders.csv') . "\n", 'exact layout');

	$stdout = capture_stdout { new_exporter(show_counts => 1)->_dry_run($CONFIG{database}, ['Orders']) };
	like($stdout, qr/^TABLE\s+ROWS  OUTPUT FILE$/m, 'ROWS column');
	like($stdout, qr/^Orders\s+$CONFIG{row_count}  Orders\.csv$/m, 'count shown');
};

subtest 'Exporter::_warn both warns and logs' => sub {
	my (@carped, @logged);
	my $guard = mock_scoped($CONFIG{exporter},
		_carp_i18n => sub { shift; push @carped, [@_]; return },
		_log       => sub { my $self = shift; push @logged, [@_]; return $self },
	);

	my $e = new_exporter();
	is($e->_warn('k', { params => [1] }), $e, 'returns $self');
	is_deeply(\@carped, [['k', { params => [1] }]], 'warned');
	is_deeply(\@logged, [['warn', 'k', { params => [1] }]], 'logged at warn level');
};

subtest 'Exporter::_log sends translated text to the logger, if any' => sub {
	my $guard = mock_scoped("$CONFIG{exporter}::i18n" => sub { "text for $_[1]" });

	my $logger = Local::Logger->new();
	my $e = new_exporter(logger => $logger);
	is($e->_log(info => 'k'), $e, 'returns $self');
	is_deeply($logger->{lines}, [['info', 'text for k']], 'logged');
	memory_cycle_ok($e, 'exporter with a logger has no cycles');

	my $plain = new_exporter();
	is($plain->_log(info => 'k'), $plain, 'no logger: still returns $self');
};

subtest 'Exporter::_os_error extracts readable text' => sub {
	my $os_error = \&App::Access2CSV::Exporter::_os_error;

	is($os_error->("plain text\n"), 'plain text', 'string, chomped');

	# autodie exceptions carry the original errno text
	eval {
		use autodie qw(open);
		open my $fh, '<', File::Spec->catfile(tempdir(CLEANUP => 1), 'missing');
	};
	isa_ok($@, 'autodie::exception');
	is($os_error->($@), $ENOENT_TEXT, 'errno text from autodie');
};

#######################################################################
# 3. App::Access2CSV
#######################################################################

subtest 'App::run stops early when option parsing decides the outcome' => sub {
	my @made;
	my $guard = mock_scoped($CONFIG{app},
		_parse_options => sub { $CONFIG{exit_usage} },
		_make_logger   => sub { push @made, 1; return },
	);

	my $status = $CONFIG{app}->run('--bogus');
	is($status, $CONFIG{exit_usage}, 'parser status returned');
	returns_ok($status, { type => 'integer', min => 0, max => 3 }, 'status in range');
	is(scalar(@made), 0, 'no log opened');
};

subtest 'App::run builds an exporter from the options and returns its status' => sub {
	my %built;
	my $logger = Local::Logger->new();
	my $guard = mock_scoped(
		"$CONFIG{app}::_parse_options" => sub { my ($class, $argv, $opt) = @_; $opt->{dry_run} = 1; return },
		"$CONFIG{app}::_make_logger"   => sub { $logger },
		"$CONFIG{exporter}::new"       => sub { shift; %built = @_; Local::Exporter->new(%built, status => $CONFIG{exit_failure}) },
	);

	my @argv = ($CONFIG{database});
	is($CONFIG{app}->run(@argv), $CONFIG{exit_failure}, 'exporter status returned');
	verbose_diag('exporter arguments', \%built);
	is($built{dry_run}, 1, 'parsed options passed on');
	is($built{logger}, $logger, 'logger passed on');
	ok(!exists $built{log}, 'log file name is not an exporter setting');
	is_deeply(\@argv, [$CONFIG{database}], 'caller array unchanged');
};

subtest 'App::run turns an exception into the fatal status' => sub {
	my @reported;
	my $guard = mock_scoped(
		"$CONFIG{app}::_parse_options" => sub { return },
		"$CONFIG{app}::_make_logger"   => sub { return },
		"$CONFIG{app}::_report_fatal"  => sub { shift; push @reported, [@_]; $CONFIG{exit_fatal} },
		# The settings are fine (new succeeds); the export itself fails
		"$CONFIG{exporter}::new"       => sub { bless {}, 'Local::Exploding' },
	);
	{
		package Local::Exploding;
		sub run { die "exploded\n" }
	}

	is($CONFIG{app}->run($CONFIG{database}), $CONFIG{exit_fatal}, 'fatal status');
	is_deeply(\@reported, [["exploded\n", 0]], 'error and verbose flag reported');
};

subtest 'App::_parse_options fills the settings' => sub {
	my @usage;
	my $guard = mock_scoped("$CONFIG{app}::_usage" => sub { shift; push @usage, [@_]; $_[0] });

	my %opt = (log => 'default.log');
	my @argv = ('--output-dir', 'out', '--table', 'A', '--table', 'B', '--overwrite', '--no-progress', '--encoding', 'cp1252', '--no-log', $CONFIG{database});
	is($CONFIG{app}->_parse_options(\@argv, \%opt), undef, 'undef: go ahead');
	verbose_diag('parsed options', \%opt);

	is($opt{output_dir}, 'out', 'output dir');
	is_deeply($opt{tables}, ['A', 'B'], 'repeated --table');
	is($opt{overwrite}, 1, 'overwrite');
	is($opt{progress}, 0, 'negated progress');
	is($opt{encoding}, 'cp1252', 'encoding');
	is($opt{log}, undef, '--no-log');
	is_deeply(\@argv, [$CONFIG{database}], 'only the database left');
	is_deeply(\@usage, [], 'no usage printed');
};

subtest 'App::_parse_options handles help and usage errors' => sub {
	my @usage;
	my $guard = mock_scoped("$CONFIG{app}::_usage" => sub { shift; push @usage, [@_]; $_[0] });
	my $parse = sub { @usage = (); my @argv = @_; return $CONFIG{app}->_parse_options(\@argv, {}) };

	is($parse->('--help'), $CONFIG{exit_ok}, '--help');
	is_deeply(\@usage, [[$CONFIG{exit_ok}, $CONFIG{pod_options}]], 'options section');
	is($parse->('--man'), $CONFIG{exit_ok}, '--man');
	is_deeply(\@usage, [[$CONFIG{exit_ok}, $CONFIG{pod_full}]], 'full manual');

	my $result;
	warning_like { $result = $parse->('--bogus', $CONFIG{database}) } qr/Unknown option: bogus/, 'Getopt::Long warns';
	is($result, $CONFIG{exit_usage}, 'bad option');
	is_deeply(\@usage, [[$CONFIG{exit_usage}, $CONFIG{pod_synopsis}]], 'synopsis only');

	is($parse->(), $CONFIG{exit_usage}, 'no database');
	is_deeply(\@usage, [[$CONFIG{exit_usage}, $CONFIG{pod_synopsis}, 'Missing database filename']], 'with a message');
	is($parse->('a', 'b'), $CONFIG{exit_usage}, 'two databases');
};

subtest 'App::_usage calls Pod::Usage without exiting' => sub {
	my @calls;
	my $guard = mock_scoped("$CONFIG{app}::pod2usage" => sub { push @calls, {@_}; return });

	is($CONFIG{app}->_usage($CONFIG{exit_ok}, $CONFIG{pod_options}), $CONFIG{exit_ok}, 'returns the status');
	is($calls[0]{-exitval}, 'NOEXIT', 'never exits');
	is($calls[0]{-verbose}, $CONFIG{pod_options}, 'verbosity');
	is($calls[0]{-output}, \*STDOUT, 'help goes to STDOUT');
	like($calls[0]{-input}, qr/Access2CSV\.pm\z/, 'POD read from the module');
	ok(!exists $calls[0]{-message}, 'no message');

	$CONFIG{app}->_usage($CONFIG{exit_usage}, $CONFIG{pod_synopsis}, 'why');
	is($calls[1]{-output}, \*STDERR, 'errors go to STDERR');
	is($calls[1]{-message}, 'why', 'message passed');
};

subtest 'App::_make_logger opens the log only when wanted' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my @created;
	my $guard = mock_scoped('Log::Abstraction::new' => sub { shift; push @created, {@_}; bless {}, 'Local::Logger' });

	is($CONFIG{app}->_make_logger({ log => undef }), undef, 'undef: no log');
	is($CONFIG{app}->_make_logger({ log => '' }), undef, 'empty: no log');
	is(scalar(@created), 0, 'Log::Abstraction not called');

	my $file = File::Spec->catfile($dir, 'x.log');
	local $@ = $CONFIG{sentinel};
	isa_ok($CONFIG{app}->_make_logger({ log => $file }), 'Local::Logger');
	is($@, $CONFIG{sentinel}, '$@ localised');
	ok(-e $file, 'file created up front');
	is_deeply([sort keys %{$created[0]}], [qw(level logger)], 'only logger and level given');
	is($created[0]{level}, 'info', 'info level');
	is_deeply([keys %{$created[0]{logger}}], ['fd'], 'logger is a handle, not a file name');
	my $fd = $created[0]{logger}{fd};
	ok(defined fileno($fd), 'handle is open');
	is(join(':', (stat $fd)[0, 1]), join(':', (stat $file)[0, 1]), 'handle is on the log file');
	ok($fd->autoflush(), 'each line is written at once');

	$CONFIG{app}->_make_logger({ log => $file, verbose => 1 });
	is($created[1]{level}, 'debug', 'verbose: debug level');
};

subtest 'App::_make_logger croaks when the log cannot be written' => sub {
	my $file = File::Spec->catfile(tempdir(CLEANUP => 1), 'no', 'such', 'x.log');
	throws_ok { $CONFIG{app}->_make_logger({ log => $file }) } qr/\ACannot open log file \Q$file\E: \Q$ENOENT_TEXT\E at /, 'exact message';
};

subtest 'App::_report_fatal prints one clean line' => sub {
	my ($status, $stderr);
	$stderr = capture_stderr { $status = $CONFIG{app}->_report_fatal("boom at lib/X.pm line 3.\n", 0) };
	is($stderr, "access2csv: boom\n", 'location removed');
	is($status, $CONFIG{exit_fatal}, 'fatal status');

	$stderr = capture_stderr { $CONFIG{app}->_report_fatal("boom at lib/X.pm line 3.\n", 1) };
	is($stderr, "access2csv: boom at lib/X.pm line 3.\n", 'verbose keeps the location');

	$stderr = capture_stderr { $CONFIG{app}->_report_fatal("boom at /home/me/My Libs/X.pm line 3.\n", 0) };
	is($stderr, "access2csv: boom\n", 'location removed even when the path contains spaces');

	$stderr = capture_stderr { $CONFIG{app}->_report_fatal("Cannot read database /d/meet at noon.accdb: gone at /l/X.pm line 3.\n", 0) };
	is($stderr, "access2csv: Cannot read database /d/meet at noon.accdb: gone\n", 'an " at " inside the message is kept');

	$stderr = capture_stderr { $CONFIG{app}->_report_fatal(undef, 0) };
	is($stderr, "access2csv: Unknown error\n", 'no error text');
};

restore_all();

done_testing();
