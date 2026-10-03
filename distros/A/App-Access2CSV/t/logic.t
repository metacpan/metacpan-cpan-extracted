#!perl

# Logic tests: every boolean expression in the code is proved over ALL
# the combinations of its inputs (its full truth table), the invariants
# of the Z specification are checked before, during and after a run, and
# inputs that contradict a documented premise are shown to be rejected
# at the first check that can see them.
#
# t/logic-proofs.t proves the ORDER of the decisions from outside; this
# file proves each decision on its own, so private helpers are called
# directly (white-box).  Rows that cannot happen are listed, with the
# reason, rather than silently left out.
#
# Set TEST_VERBOSE=1 to see internal state.

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'uses symbolic links and Unix stand-in programs') if $^O eq 'MSWin32';
}

use Capture::Tiny qw(capture capture_stderr);
use Errno qw(ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Test::Mockingbird;

use lib File::Spec->catdir($Bin, 'lib');
use FakeMDB qw(install_fake_mdbtools make_database);

use App::Access2CSV;

# White-box: private and protected helpers are called directly
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
	fake_bin     => '/fake/bin',
);

Readonly::Array my @PROGRAMS => qw(mdb-tables mdb-export mdb-count);
Readonly::Array my @ENCODINGS => qw(utf8 utf8-bom cp1252);
Readonly::Scalar my $ENOENT_TEXT => do { local $! = ENOENT; "$!" };

local $ENV{PATH} = join(':', install_fake_mdbtools(), $ENV{PATH});

sub verbose_diag {
	my ($label, $data) = @_;
	diag("$label: ", Test::More::explain($data)) if $ENV{TEST_VERBOSE};
	return;
}

# All 2**n combinations of n booleans, as arrayrefs of 0/1
sub truth_table {
	my $n = shift;
	return [ map { my $row = $_; [ map { ($row >> $_) & 1 } reverse 0 .. $n - 1 ] } 0 .. 2**$n - 1 ];
}

sub row_name {
	my ($names, $row) = @_;
	return join(', ', map { "$names->[$_]=$row->[$_]" } 0 .. $#{$names});
}

sub exporter { return $CONFIG{exporter}->new(progress => 0, @_) }

# A logger that records messages by level
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

subtest '_narrow: context gate  ref(entry) AND defined(context) AND exists(form)' => sub {
	# 3 inputs, 8 rows.  When the entry is a plain string there are no
	# forms, so "exists" can only be 0: rows (0, *, 1) are impossible.
	my %template = (hash => { female => 'F', other => 'O' }, string => 'S');
	foreach my $row (@{ truth_table(3) }) {
		my ($is_hash, $has_context, $form_exists) = @{$row};
		my $name = row_name([qw(hash context exists)], $row);
		if(!$is_hash && $form_exists) {
			pass("$name: impossible (a string has no forms)");
			next;
		}
		my $args = $has_context ? { context => $form_exists ? 'female' : 'robot' } : {};
		my $entry = $is_hash ? $template{hash} : $template{string};
		my $expected = !$is_hash ? 'S' : ($has_context && $form_exists) ? 'F' : 'O';
		is(App::Access2CSV::I18N::_narrow($entry, 'en', $args), $expected, $name);
	}
};

subtest '_narrow: plural gate and result guard  defined(entry) AND NOT ref(entry)' => sub {
	# After narrowing: category form present? "other" present? The result
	# is usable only when it is a defined, plain string.
	my $narrow = \&App::Access2CSV::I18N::_narrow;
	foreach my $row (@{ truth_table(2) }) {
		my ($has_category, $has_other) = @{$row};
		my %forms = (($has_category ? (one => 'ONE') : ()), ($has_other ? (other => 'OTHER') : ()));
		my $expected = $has_category ? 'ONE' : $has_other ? 'OTHER' : undef;
		is($narrow->({ %forms }, 'en', { count => 1 }), $expected, row_name([qw(category other)], $row));
	}

	# The result guard over its own inputs: (defined, is a reference)
	is($narrow->('text', 'en', {}), 'text', 'defined=1, ref=0: usable');
	is($narrow->({ other => { nested => 1 } }, 'en', {}), undef, 'defined=1, ref=1: not usable');
	is($narrow->(undef, 'en', {}), undef, 'defined=0: not usable (defined=0, ref=1 cannot happen)');
};

subtest '_plural_category: defined(count) x known(language)' => sub {
	my $plural = \&App::Access2CSV::I18N::_plural_category;
	my %cases = (
		'count=1, known=1'  => [['fr', 0], 'one'],     # French rule: 0 is singular
		'count=1, known=0'  => [['xx', 0], 'other'],   # English rule used: 0 is plural
		'count=0, known=1'  => [['fr', undef], 'other'],
		'count=0, known=0'  => [['xx', undef], 'other'],
	);
	is($plural->(@{ $cases{$_}[0] }), $cases{$_}[1], $_) foreach sort keys %cases;
};

subtest '_language: object gate  ref(self) AND language' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { x => 'y' };
	local $ENV{LANG} = 'de';
	my $class = $CONFIG{i18n};
	my %cases = (
		'object=1, language=1' => [bless({ language => 'en' }, $class), 'en'],
		'object=1, language=0' => [bless({}, $class), 'de'],
		'object=0 (class)'     => [$class, 'de'],   # a class has no language; row (0, 1) cannot happen
	);
	is($cases{$_}[0]->_language(), $cases{$_}[1], $_) foreach sort keys %cases;
};

subtest '_language: filter  length(value) AND NOT neutral(value)' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { x => 'y' };
	local $App::Access2CSV::I18N::MESSAGES{fr} = { x => 'y' };
	my $class = $CONFIG{i18n};
	# LANGUAGE is the value under test; LANG=fr shows whether it was skipped
	my %cases = (
		'length=1, neutral=0' => ['de', 'de'],
		'length=1, neutral=1' => ['C', 'fr'],
		'length=0 (empty)'    => ['', 'fr'],       # an empty value cannot also be C/POSIX
	);
	foreach my $case (sort keys %cases) {
		local $ENV{LANGUAGE} = $cases{$case}[0];
		local $ENV{LANG} = 'fr';
		is($class->_language(), $cases{$case}[1], $case);
	}
};

subtest '_language: result  defined(code) AND catalog exists' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { x => 'y' };
	my %cases = (
		'code=1, catalog=1' => ['de_DE', 'de'],
		'code=1, catalog=0' => ['xx_XX', 'en'],
		'code=0'            => ['!', 'en'],   # no code, so no catalog to look for
	);
	foreach my $case (sort keys %cases) {
		local $ENV{LANG} = $cases{$case}[0];
		is($CONFIG{i18n}->_language(), $cases{$case}[1], $case);
	}
};

subtest '_lookup: key in language x key in English' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { only_de => 'nur', both => 'beide' };
	local $App::Access2CSV::I18N::MESSAGES{en} = { %{ $App::Access2CSV::I18N::MESSAGES{en} }, both => 'both', only_en => 'english' };
	my $class = $CONFIG{i18n};
	is($class->_lookup('de', 'both'), 'beide', 'in_de=1, in_en=1: the language wins');
	is($class->_lookup('de', 'only_de'), 'nur', 'in_de=1, in_en=0');
	is($class->_lookup('de', 'only_en'), 'english', 'in_de=0, in_en=1: English');
	throws_ok { $class->_lookup('de', 'neither') } qr/\AUnknown message key: neither at /, 'in_de=0, in_en=0: confess';
};

subtest 'i18n: values gate  defined(params) AND non-empty' => sub {
	local $App::Access2CSV::I18N::MESSAGES{en}{pct} = '%% %s';
	my $i18n = $CONFIG{i18n};
	is($i18n->i18n('pct', {}), '%% %s', 'defined=0: template untouched');
	is($i18n->i18n('pct', { params => [] }), '%% %s', 'defined=1, non-empty=0: untouched');
	is($i18n->i18n('pct', { params => ['x'] }), '% x', 'defined=1, non-empty=1: sprintf');
};

subtest 'i18n: tries  (language is English) x (gap in language) x (gap in English)' => sub {
	# At most two attempts.  Truth table of where the text comes from.
	my $i18n = $CONFIG{i18n};
	local $App::Access2CSV::I18N::MESSAGES{de} = { ok => { one => 'DE', other => 'DE' }, gap => { one => 'DE' } };
	local $App::Access2CSV::I18N::MESSAGES{en} = {
		%{ $App::Access2CSV::I18N::MESSAGES{en} },
		ok => { one => 'EN', other => 'EN' }, gap => { one => 'EN', other => 'EN' }, bad => { one => 'EN' },
	};
	my @rows = (
		[1, 0, 0, 'en', 'ok',  2, 'EN'],
		[1, 0, 1, 'en', 'bad', 2, undef],   # English has a gap: confess
		[0, 0, 0, 'de', 'ok',  2, 'DE'],
		[0, 1, 0, 'de', 'gap', 2, 'EN'],    # second try, in English
		[0, 1, 1, 'de', 'bad', 2, undef],
	);
	# (1, 1, *) is impossible: if the language is English, a gap in the
	# language IS a gap in English.  (0, 0, 1) behaves like (0, 0, 0):
	# the first try already succeeded.
	foreach my $row (@rows) {
		my ($is_en, $gap_lang, $gap_en, $lang, $key, $count, $expected) = @{$row};
		local $ENV{LANG} = $lang;
		my $name = row_name([qw(english gap_in_language gap_in_english)], [$is_en, $gap_lang, $gap_en]);
		if(defined $expected) {
			is($i18n->i18n($key, { count => $count }), $expected, $name);
		} else {
			throws_ok { $i18n->i18n($key, { count => $count }) } qr/\AUnknown message key: $key at /, "$name: confess";
		}
	}
};

#######################################################################
# App::Access2CSV::Exporter
#######################################################################

subtest 'De Morgan: "exists" = -e OR -l = NOT(NOT -e AND NOT -l)' => sub {
	# The four states a directory entry can be in, and both forms agree
	my $dir = tempdir(CLEANUP => 1);
	open my $fh, '>', "$dir/file" or die $!;
	close $fh;
	symlink("$dir/file", "$dir/link") or die $!;
	symlink("$dir/nowhere", "$dir/dangling") or die $!;
	my %states = (
		'file:          -e=1, -l=0' => ["$dir/file", 1],
		'link to file:  -e=1, -l=1' => ["$dir/link", 1],
		'dangling link: -e=0, -l=1' => ["$dir/dangling", 1],
		'absent:        -e=0, -l=0' => ["$dir/absent", 0],
	);
	foreach my $state (sort keys %states) {
		my ($path, $exists) = @{ $states{$state} };
		my $or_form = (-e $path || -l $path) ? 1 : 0;
		my $and_form = !(!-e $path && !-l $path) ? 1 : 0;
		is($or_form, $exists, "$state: OR form");
		is($and_form, $or_form, "$state: De Morgan form agrees");
	}
};

subtest '_export_table: refuse = NOT overwrite AND exists  (all 8 rows)' => sub {
	# overwrite x -e x -l.  Row (-e=0, -l=0) is "absent", (-e=0, -l=1) a
	# dangling link, (-e=1, -l=0) a file, (-e=1, -l=1) a link to a file.
	foreach my $row (@{ truth_table(3) }) {
		my ($overwrite, $e, $l) = @{$row};
		my $dir = tempdir(CLEANUP => 1);
		my $db = make_database($dir, 'T');
		my $out = "$dir/out";
		mkdir $out or die $!;
		open my $fh, '>', "$dir/real" or die $!;
		close $fh;
		if($e && $l)    { symlink("$dir/real", "$out/T.csv") or die $! }
		elsif($e)       { open my $f, '>', "$out/T.csv" or die $!; close $f }
		elsif($l)       { symlink("$dir/nowhere", "$out/T.csv") or die $! }
		my $refuse = (!$overwrite && ($e || $l)) ? 1 : 0;

		my $status;
		capture { $status = exporter(output_dir => $out, overwrite => $overwrite)->run($db) };
		is($status, $refuse ? $CONFIG{exit_failure} : $CONFIG{exit_ok}, row_name([qw(overwrite -e -l)], $row) . ($refuse ? ': refused' : ': written'));
	}
};

subtest '_check_database: -e, -f, -r (the feasible rows)' => sub {
	# -f and -r imply -e, so rows with -e=0 collapse to one ("missing").
	my $dir = tempdir(CLEANUP => 1);
	my $e = exporter();
	my $file = make_database($dir, 'T');
	throws_ok { $e->_check_database("$dir/missing") } qr/\ACannot read database .*: \Q$ENOENT_TEXT\E at /, '-e=0: not found';
	throws_ok { $e->_check_database($dir) } qr/is not a regular file at /, '-e=1, -f=0: not a file';
	SKIP: {
		skip('root can read anything', 1) if $> == 0;
		chmod 0, $file;
		throws_ok { $e->_check_database($file) } qr/is not readable at /, '-e=1, -f=1, -r=0: unreadable';
		chmod oct(644), $file;
	}
	is($e->_check_database($file), $e, '-e=1, -f=1, -r=1: accepted');
};

subtest '_verify_dependencies: tables x export x count x show_counts (all 16 rows)' => sub {
	foreach my $row (@{ truth_table(4) }) {
		my ($tables, $export, $count, $show) = @{$row};
		my %present = ('mdb-tables' => $tables, 'mdb-export' => $export, 'mdb-count' => $count);
		my $guard = mock_scoped("$CONFIG{exporter}::which" => sub { $present{ $_[0] } ? "$CONFIG{fake_bin}/$_[0]" : undef });
		my $e = exporter(show_counts => $show);
		my $name = row_name([qw(tables export count show_counts)], $row);

		if(!$tables || !$export) {
			my $first = $tables ? 'mdb-export' : 'mdb-tables';
			throws_ok { $e->_verify_dependencies() } qr/\ARequired program not found in PATH: $first at /, "$name: fatal, names $first";
			next;
		}
		my $stderr = capture_stderr { $e->_verify_dependencies() };
		my $counting = $show && $count;
		is($e->{show_counts}, $counting ? 1 : 0, "$name: show_counts ends " . ($counting ? 'on' : 'off'));
		is(exists($e->{programs}{'mdb-count'}) ? 1 : 0, $counting ? 1 : 0, "$name: mdb-count stored only when used");
		is(($stderr =~ /mdb-count not found/) ? 1 : 0, ($show && !$count) ? 1 : 0, "$name: warning only when wanted but missing");
	}
};

subtest '_find_program: log debug = found AND verbose' => sub {
	foreach my $row (@{ truth_table(2) }) {
		my ($found, $verbose) = @{$row};
		my $guard = mock_scoped("$CONFIG{exporter}::which" => sub { $found ? "$CONFIG{fake_bin}/x" : undef });
		my $logger = Local::Logger->new();
		exporter(verbose => $verbose, logger => $logger)->_find_program('x');
		is(scalar(@{ $logger->{lines} }), ($found && $verbose) ? 1 : 0, row_name([qw(found verbose)], $row));
	}
};

subtest '_select_tables: filter given x some names missing' => sub {
	my @all = ('A', 'B');
	my %cases = (
		'filter=0'            => [undef, [qw(A B)], 0],   # no filter, so nothing can be missing
		'filter=1, missing=0' => [['B'], ['B'], 0],
		'filter=1, missing=1' => [['B', 'Z'], ['B'], 1],
	);
	foreach my $case (sort keys %cases) {
		my ($filter, $expected, $warns) = @{ $cases{$case} };
		my $picked;
		my $stderr = capture_stderr { $picked = exporter(tables => $filter)->_select_tables([@all]) };
		is_deeply($picked, $expected, "$case: selection");
		is(($stderr =~ /not found in database/) ? 1 : 0, $warns, "$case: warning");
	}
};

subtest '_make_output_dir: failed = errors reported OR director still missing' => sub {
	# 2 inputs, 4 rows, forced through a mocked make_path
	foreach my $row (@{ truth_table(2) }) {
		my ($errors, $made) = @{$row};
		my $dir = File::Spec->catdir(tempdir(CLEANUP => 1), 'out');
		my $guard = mock_scoped("$CONFIG{exporter}::make_path" => sub {
			my ($path, $opts) = @_;
			mkdir $path if $made;
			${ $opts->{error} } = $errors ? [{ $path => 'Simulated' }] : [];
			$! = ENOENT;
			return;
		});
		my $name = row_name([qw(errors made)], $row);
		if($errors || !$made) {
			my $reason = $errors ? 'Simulated' : $ENOENT_TEXT;
			throws_ok { exporter(output_dir => $dir)->_make_output_dir() } qr/\ACannot create output directory \Q$dir\E: \Q$reason\E at /, "$name: fails, reason from " . ($errors ? 'File::Path' : '$!');
		} else {
			lives_ok { exporter(output_dir => $dir)->_make_output_dir() } "$name: succeeds";
		}
	}
};

subtest '_make_output_dir: reason = error for this director, else the last error, else $!' => sub {
	my $dir = File::Spec->catdir(tempdir(CLEANUP => 1), 'out');
	my %cases = (
		'own=1'              => [[{ '/parent' => 'P' }, { $dir => 'Own' }], 'Own'],
		'own=0, others=1'    => [[{ '/a' => 'First' }, { '/b' => 'Last' }], 'Last'],
		'own=0, others=0'    => [[], $ENOENT_TEXT],
	);
	foreach my $case (sort keys %cases) {
		my ($errors, $reason) = @{ $cases{$case} };
		my $guard = mock_scoped("$CONFIG{exporter}::make_path" => sub { ${ $_[1]{error} } = $errors; $! = ENOENT; return });
		throws_ok { exporter(output_dir => $dir)->_make_output_dir() } qr/: \Q$reason\E at /, $case;
	}
};

subtest '_run_program: status = -1 | signal | exit code | 0' => sub {
	# The four classes of $? are disjoint, and -1 must be tested first
	# because -1 & 127 = 127 would otherwise look like a signal
	my $e = exporter();
	$e->{programs} = { p => "$CONFIG{fake_bin}/p" };
	my %cases = (
		'-1'     => [-1, qr/\Ap could not be run: /],
		'signal' => [$CONFIG{signal}, qr/\Ap was killed by signal $CONFIG{signal} /],
		'exit'   => [$CONFIG{exit_code} << 8, qr/\Ap failed with exit status $CONFIG{exit_code}: /],
	);
	foreach my $case (sort keys %cases) {
		my ($status, $message) = @{ $cases{$case} };
		my $guard = mock_scoped("$CONFIG{exporter}::run3" => sub { ${ $_[3] } = ''; $? = $status; return 1 });
		throws_ok { $e->_run_program('p', [], \my $out) } $message, $case;
	}
	my $guard = mock_scoped("$CONFIG{exporter}::run3" => sub { ${ $_[3] } = ''; $? = 0; return 1 });
	is($e->_run_program('p', [], \my $out), $e, '0: success');
};

subtest '_csv_filename: defined(table), reserved, empty after cleaning, collision' => sub {
	my $e = exporter();
	my %cases = (
		'defined=0'                    => [undef, 'unnamed.csv'],
		'defined=1, reserved=1'        => ['NUL', '_NUL.csv'],
		'defined=1, empty after clean' => [' . ', 'unnamed_2.csv'],   # collides with the first
		'defined=1, collision=0'       => ['Orders', 'Orders.csv'],
		'defined=1, collision=1'       => ['ORDERS', 'ORDERS_2.csv'],
	);
	# Order matters for the collision rows, so run them in a fixed order
	foreach my $case ('defined=0', 'defined=1, reserved=1', 'defined=1, empty after clean', 'defined=1, collision=0', 'defined=1, collision=1') {
		is($e->_csv_filename($cases{$case}[0]), $cases{$case}[1], $case);
	}
};

subtest '_log: logger present x logger dies' => sub {
	{
		package Local::Dying;
		sub new { bless {}, shift }
		sub info { die "broken\n" }
		sub debug { } sub warn { }
	}
	my %cases = (
		'logger=0'         => [undef, 0, 0],
		'logger=1, dies=0' => [Local::Logger->new(), 0, 1],
		'logger=1, dies=1' => [Local::Dying->new(), 1, 0],
	);
	foreach my $case (sort keys %cases) {
		my ($logger, $warns, $kept) = @{ $cases{$case} };
		my $e = exporter($logger ? (logger => $logger) : ());
		my $stderr = capture_stderr { $e->_log(info => 'dry_run_title') };
		is(($stderr =~ /Cannot write to the log/) ? 1 : 0, $warns, "$case: warning");
		is($e->{logger} ? 1 : 0, $kept, "$case: logger kept");
	}
};

subtest '_os_error: is a blessed object x can errno' => sub {
	# The error may be a plain string, an object with errno (autodie), an
	# object without it, or an UNBLESSED reference.  A reference must not
	# be asked ->can(): that would die and hide the real error.
	{
		package Local::WithErrno;
		sub new { bless {}, shift }
		sub errno { 'from errno' }
		use overload '""' => sub { 'stringified' }, fallback => 1;
		package Local::NoErrno;
		sub new { bless {}, shift }
		use overload '""' => sub { 'plain object' }, fallback => 1;
	}
	my $os_error = \&App::Access2CSV::Exporter::_os_error;
	is($os_error->("text\n"), 'text', 'blessed=0 (string)');
	is($os_error->(Local::WithErrno->new()), 'from errno', 'blessed=1, errno=1');
	is($os_error->(Local::NoErrno->new()), 'plain object', 'blessed=1, errno=0');
	my $unblessed;
	lives_ok { $unblessed = $os_error->({ reason => 'x' }) } 'unblessed reference: does not die';
	like($unblessed, qr/\AHASH\(0x/, '... and is simply stringified');
};

#######################################################################
# App::Access2CSV
#######################################################################

subtest '_parse_options: parsed x help x one name (all 8 rows)' => sub {
	# The outcome is decided by the first gate that applies: not parsed
	# -> 2, help -> 0, otherwise one usable name -> go on, else 2
	my @usage;
	my $guard = mock_scoped("$CONFIG{app}::_usage" => sub { push @usage, $_[1]; return $_[1] });
	foreach my $row (@{ truth_table(3) }) {
		my ($parsed, $help, $one_name) = @{$row};
		my @argv = (($parsed ? () : '--bogus'), ($help ? '--help' : ()), ($one_name ? 'db' : ()));
		my $expected = !$parsed ? $CONFIG{exit_usage} : $help ? $CONFIG{exit_ok} : $one_name ? undef : $CONFIG{exit_usage};
		my $got;
		{
			local $SIG{__WARN__} = sub { };   # Getopt::Long warns about --bogus
			$got = $CONFIG{app}->_parse_options(\@argv, {});
		}
		is($got, $expected, row_name([qw(parsed help one_name)], $row) . ' => ' . ($expected // 'go on'));
	}
};

subtest '_make_logger: log wanted x can be opened x logger created' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my %cases = (
		'wanted=0'                        => [{ log => '' }, 1, 'none'],
		'wanted=1, open=0'                => [{ log => "$dir/no/x.log" }, 1, 'croak'],
		'wanted=1, open=1, created=0'     => [{ log => "$dir/a.log" }, 0, 'croak'],
		'wanted=1, open=1, created=1'     => [{ log => "$dir/b.log" }, 1, 'logger'],
	);
	foreach my $case (sort keys %cases) {
		my ($opt, $creates, $outcome) = @{ $cases{$case} };
		my $guard = mock_scoped('Log::Abstraction::new' => sub { $creates ? Local::Logger->new() : undef });
		if($outcome eq 'croak') {
			throws_ok { $CONFIG{app}->_make_logger($opt) } qr/\ACannot open log file /, "$case: fatal";
		} elsif($outcome eq 'none') {
			is($CONFIG{app}->_make_logger($opt), undef, "$case: no logger");
		} else {
			isa_ok($CONFIG{app}->_make_logger($opt), 'Local::Logger', "$case: logger");
		}
	}
};

subtest '_report_fatal: has text x verbose' => sub {
	foreach my $row (@{ truth_table(2) }) {
		my ($text, $verbose) = @{$row};
		my $error = $text ? "boom at x.pm line 1.\n" : undef;
		my $stderr = capture_stderr { $CONFIG{app}->_report_fatal($error, $verbose) };
		my $expected = !$text ? 'Unknown error' : $verbose ? 'boom at x.pm line 1.' : 'boom';
		is($stderr, "access2csv: $expected\n", row_name([qw(text verbose)], $row));
	}
};

subtest '_usage: help goes to STDOUT exactly when the status is 0' => sub {
	my @calls;
	my $guard = mock_scoped("$CONFIG{app}::pod2usage" => sub { push @calls, {@_}; return });
	$CONFIG{app}->_usage($CONFIG{exit_ok}, 1);
	$CONFIG{app}->_usage($CONFIG{exit_usage}, 0, 'why');
	is($calls[0]{-output}, \*STDOUT, 'status 0: STDOUT');
	is($calls[1]{-output}, \*STDERR, 'status 2: STDERR');
	ok(!exists $calls[0]{-message} && $calls[1]{-message} eq 'why', 'message only when given');
};

#######################################################################
# Invariants (Z specification)
#######################################################################

subtest 'invariant Exporter: before, during and after a run' => sub {
	# Z Exporter schema:
	#	settings(encoding) in {utf8, utf8-bom, cp1252}
	#	used_names unique ignoring case
	# plus: programs only ever names the three mdbtools programs, and
	# show_counts => mdb-count is known once programs have been found
	my $check = sub {
		my ($e, $when) = @_;
		my @names = keys %{ $e->{used_names} };
		my %lower = map { lc($_) => 1 } @names;
		ok((grep { $_ eq $e->{encoding} } @ENCODINGS), "$when: encoding is one of the three");
		is(scalar(keys %lower), scalar(@names), "$when: names unique ignoring case");
		ok(!grep({ my $p = $_; !grep { $_ eq $p } @PROGRAMS } keys %{ $e->{programs} }), "$when: only mdbtools programs known");
		ok(!$e->{show_counts} || !%{ $e->{programs} } || exists($e->{programs}{'mdb-count'}), "$when: counting implies mdb-count is known");
	};

	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, qw(orders Orders ORDERS Unicode));
	my $e = exporter(output_dir => "$dir/out", show_counts => 1, encoding => 'cp1252');
	$check->($e, 'before');

	# "during": check after every table, from inside the run
	my $checks = 0;
	after("$CONFIG{exporter}::_export_table", sub { $check->($_[0], 'during'); $checks++ });
	capture { $e->run($db) };
	unmock("$CONFIG{exporter}::_export_table");
	is($checks, 4, 'checked after each of the four tables');

	$check->($e, 'after');
};

subtest 'invariant I18N: the catalog is never changed by a call' => sub {
	# Xi Catalog: i18n only reads MESSAGES, whatever path it takes
	my $before = Test::More::explain(\%App::Access2CSV::I18N::MESSAGES);
	my $i18n = $CONFIG{i18n};
	$i18n->i18n('summary', { params => [1, 0], count => 1 });
	{ local $ENV{LANG} = 'de'; $i18n->i18n('dry_run_title') }
	eval { $i18n->i18n('no_such_key') };
	is(Test::More::explain(\%App::Access2CSV::I18N::MESSAGES), $before, 'unchanged after normal, fallback and failing calls');
};

subtest 'invariant App: status is always one of 0..3' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, qw(A Broken));
	my @argvs = (['--help'], ['--bogus'], [], ['--no-log', "$dir/missing"], ['--no-log', '--output-dir', "$dir/o", $db], ['--no-log', '--dry-run', $db]);
	my %seen;
	foreach my $argv (@argvs) {
		my $status;
		capture { local $SIG{__WARN__} = sub { }; $status = $CONFIG{app}->run(@{$argv}) };
		ok($status =~ /\A[0-3]\z/, "'@{$argv}' => $status");
		$seen{$status} = 1;
	}
	is_deeply([sort keys %seen], [0, 1, 2, 3], 'and every one of the four statuses is reachable');
};

#######################################################################
# Contradictions: inputs that break a premise are stopped at once
#######################################################################

subtest 'contradiction: settings that break the Exporter premises' => sub {
	# Premise: new() only creates exporters that satisfy the invariant.
	# So a contradictory setting is refused by new(), before any run.
	my $class = $CONFIG{exporter};
	throws_ok { $class->new(encoding => 'latin1') } qr/Parameter 'encoding'/, 'encoding outside the set';
	throws_ok { $class->new(tables => [undef, ['x']]) } qr/tables/, 'table names that are not strings';
	throws_ok { $class->new(overwrite => 'maybe') } qr/must be a boolean/, 'a boolean that is neither true nor false';
};

subtest 'contradiction: a count below zero' => sub {
	# Premise: counts are natural numbers (0 and up).  -1 contradicts it.
	throws_ok { $CONFIG{i18n}->i18n('summary', { count => -1 }) } qr/Parameter 'count' \(-1\) must be at least 0/, 'refused by validation, before any lookup';
};

subtest 'contradiction: a database that is not a regular file' => sub {
	# Premise: the database is a readable regular file.  A director
	# contradicts it; nothing may happen after the check.
	my $dir = tempdir(CLEANUP => 1);
	my $which = spy("$CONFIG{exporter}::which");
	throws_ok { exporter()->run($dir) } qr/is not a regular file/, 'refused';
	is(scalar($which->()), 0, 'before any program was even looked for');
	restore_all();
};

subtest 'contradiction: two databases, or none' => sub {
	# Premise: exactly one database.  Two contradict it: rejected before
	# the log file is opened
	my $dir = tempdir(CLEANUP => 1);
	my ($db1, $db2) = map { make_database(tempdir(CLEANUP => 1), 'T') } 1 .. 2;
	my $log = "$dir/x.log";
	my ($status) = do { my $s; capture { $s = $CONFIG{app}->run('--log', $log, $db1, $db2) }; $s };
	is($status, $CONFIG{exit_usage}, 'refused');
	ok(!-e $log, 'before the log was created');
};

subtest 'not a contradiction: --log and --no-log together, last one wins' => sub {
	# Getopt::Long applies options in order, so the later one decides.
	# This is deterministic, not an error.
	my ($dir, $db) = (tempdir(CLEANUP => 1));
	$db = make_database($dir, 'T');
	capture { $CONFIG{app}->run('--log', "$dir/first.log", '--no-log', '--dry-run', $db) };
	ok(!-e "$dir/first.log", '--log then --no-log: no log');
	capture { $CONFIG{app}->run('--no-log', '--log', "$dir/second.log", '--dry-run', $db) };
	ok(-e "$dir/second.log", '--no-log then --log: log');
};

restore_all();

done_testing();
