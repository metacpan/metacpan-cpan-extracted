#!perl

# Domain tests: equivalence partitioning and boundary value analysis for
# every input of the public API, one parameter per subtest.
#
# For each parameter: one typical value from each valid and invalid
# partition, plus the exact edges (minimum, maximum, just below, just
# above).  Text inputs are also tested with non-ASCII partitions: German
# letters, multibyte emoji (including joined sequences), Zalgo text
# (stacked combining marks) and right-to-left override characters.
#
# Set TEST_VERBOSE=1 to see internal state.

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'uses Unix stand-in programs and /dev') if $^O eq 'MSWin32';
}

use Capture::Tiny qw(capture);
use Encode qw(encode);
use Errno qw(ENAMETOOLONG ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Storable qw(dclone);

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
	name_max     => 255,
	csv_suffix   => '.csv',
	access_max   => 64,
	big_count    => 2**53,
	many         => 10,
);

# Characters used to build the multibyte partitions, as UTF-8 bytes (the
# form mdbtools and the command line use) and as Perl characters
Readonly::Hash my %TEXT => (
	german  => "Gr\x{fc}\x{df}e",                           # umlaut + sharp s
	emoji   => "\x{1F600}",                                 # 4 bytes in UTF-8
	family  => "\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F467}", # joined emoji sequence
	zalgo   => 'Z' . ("\x{301}\x{316}\x{334}" x 10) . 'algo', # stacked combining marks
	rtl     => "report\x{202E}vsc.exe",                     # right-to-left override
	arabic  => "\x{645}\x{628}\x{64a}\x{639}\x{627}\x{62a}", # plain RTL text
);

# The OS texts for the errors we expect
Readonly::Hash my %OS => (
	enoent       => do { local $! = ENOENT; "$!" },
	enametoolong => do { local $! = ENAMETOOLONG; "$!" },
);

# The valid boolean spellings (Params::Validate::Strict / Readonly::Values::Boolean)
Readonly::Array my @BOOL_TRUE  => qw(1 true TRUE yes on);
Readonly::Array my @BOOL_FALSE => qw(0 false FALSE no off);
Readonly::Array my @BOOL_BAD   => ('', 2, -1, 'True', 'Yes', '0.0', ' 1');
Readonly::Array my @BOOLEANS   => qw(overwrite verbose dry_run show_counts progress);

local $ENV{PATH} = join(':', install_fake_mdbtools(), $ENV{PATH});

# Snapshot of the catalog, to prove no test leaves it changed
my $CATALOG = dclone(\%App::Access2CSV::I18N::MESSAGES);

sub verbose_diag {
	my ($label, $data) = @_;
	diag("$label: ", Test::More::explain($data)) if $ENV{TEST_VERBOSE};
	return;
}

sub bytes { return encode('UTF-8', shift) }

sub new_database {
	my $dir = tempdir(CLEANUP => 1);
	return ($dir, make_database($dir, @_));
}

sub dir_entries {
	my $dir = shift;
	opendir my $dh, $dir or return [];
	return [sort grep { !/\A\.\.?\z/ } readdir $dh];
}

sub slurp {
	my $path = shift;
	open my $fh, '<:raw', $path or die "$path: $!";
	local $/;
	return scalar <$fh>;
}

# export(\@tables, %settings): run a quiet exporter over a database of
# @tables; returns (status, stderr, output dir)
sub export {
	my ($tables, %settings) = @_;
	my ($dir, $db) = new_database(@{$tables});
	my $out = "$dir/out";
	my $status;
	my (undef, $stderr) = capture {
		$status = eval { $CONFIG{exporter}->new(output_dir => $out, progress => 0, %settings)->run($db) };
	};
	return ($status, $stderr, $out);
}

#######################################################################
# App::Access2CSV::I18N::i18n
#######################################################################

subtest 'i18n key: known | unknown | empty | undef | reference' => sub {
	my $i18n = $CONFIG{i18n};

	is($i18n->i18n('dry_run_title'), 'DRY RUN', 'valid: known key');
	throws_ok { $i18n->i18n('x') } qr/\AUnknown message key: x at /, 'invalid: unknown key (1 character, shortest non-empty)';
	throws_ok { $i18n->i18n('') } qr/Parameter 'key' .*must be at least 1/, 'invalid: empty (just below the 1-character minimum)';
	throws_ok { $i18n->i18n(undef) } qr/Required parameter 'key' is missing/, 'invalid: undef';
	throws_ok { $i18n->i18n({}) } qr/Required parameter 'key' is missing/, 'invalid: empty hashref';
	throws_ok { $i18n->i18n("dry_run_title\n") } qr/\AUnknown message key: dry_run_title\n at /, 'invalid: valid key plus newline';
};

subtest 'i18n count: below 0 | 0 | 1 | 2 | very large | fraction' => sub {
	# English: 1 is "one", everything else "other"
	my $i18n = $CONFIG{i18n};
	my $say = sub { $i18n->i18n('summary', { params => [$_[0], 0], count => $_[0] }) };

	throws_ok { $say->(-1) } qr/Parameter 'count' \(-1\) must be at least 0/, 'invalid: -1 (just below the minimum)';
	is($say->(0), 'Processed 0 tables, 0 failed', 'minimum 0: plural');
	is($say->(1), 'Processed 1 table, 0 failed', '1: singular');
	is($say->(2), 'Processed 2 tables, 0 failed', '2 (just above 1): plural');
	like($say->($CONFIG{big_count}), qr/\AProcessed 9007199254740992 tables, /, '2**53: plural, no overflow');
	throws_ok { $say->(1.5) } qr/Parameter 'count' \(1\.5\) must be/, 'invalid: fraction';
	throws_ok { $say->('one') } qr/Parameter 'count' \(one\) must be/, 'invalid: word';

	# The plural edge moves with the language
	local $App::Access2CSV::I18N::MESSAGES{fr} = { summary => { one => '%d table (fr)', other => '%d tables (fr)' } };
	local $App::Access2CSV::I18N::MESSAGES{ja} = { summary => { one => 'never used', other => '%d (ja)' } };
	my %expect = (
		fr => { 0 => '0 table (fr)', 1 => '1 table (fr)', 2 => '2 tables (fr)' },
		ja => { 0 => '0 (ja)', 1 => '1 (ja)', 2 => '2 (ja)' },
	);
	foreach my $lang (sort keys %expect) {
		local $ENV{LANG} = "${lang}_XX.UTF-8";
		foreach my $count (sort keys %{ $expect{$lang} }) {
			is($i18n->i18n('summary', { params => [$count], count => $count }), $expect{$lang}{$count}, "$lang, count $count");
		}
	}
};

subtest 'i18n params: none | exact | multibyte text' => sub {
	# Values are copied into the text exactly: no corruption, and length
	# is counted in characters for character strings, bytes for bytes
	my $i18n = $CONFIG{i18n};
	is($i18n->i18n('missing_database', { params => [] }), 'Missing database filename', 'empty list, no placeholders');
	is($i18n->i18n('progress', { params => [1, 1, 'T'] }), '[1/1] T', 'exact number of values');

	foreach my $name (sort keys %TEXT) {
		my $chars = $TEXT{$name};
		my $text = $i18n->i18n('fatal', { params => [$chars] });
		is($text, "access2csv: $chars", "$name as characters: unchanged");
		is(length($text), length('access2csv: ') + length($chars), "$name as characters: length in characters");
		is($i18n->i18n('fatal', { params => [bytes($chars)] }), 'access2csv: ' . bytes($chars), "$name as UTF-8 bytes: unchanged");
	}
};

subtest 'i18n context: known | unknown | empty' => sub {
	local $App::Access2CSV::I18N::MESSAGES{en}{ctx} = { female => 'she', male => 'he', other => 'they' };
	my $i18n = $CONFIG{i18n};
	is($i18n->i18n('ctx', { context => 'female' }), 'she', 'valid: known context');
	is($i18n->i18n('ctx', { context => 'robot' }), 'they', 'unknown context: falls back');
	is($i18n->i18n('ctx', { context => '' }), 'they', 'empty context: falls back');
	throws_ok { $i18n->i18n('ctx', { context => [] }) } qr/'context'/, 'invalid: not a string';
};

subtest 'i18n language (environment): partitions' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { dry_run_title => 'PROBELAUF' };
	my %cases = (
		'de'                => 'PROBELAUF',   # 2-letter minimum
		'deu'               => 'DRY RUN',     # 3 letters: a code, but no catalog
		'd'                 => 'DRY RUN',     # 1 letter: just below the minimum
		'de_DE.UTF-8@euro'  => 'PROBELAUF',   # everything after the code ignored
		'DE'                => 'PROBELAUF',   # case-insensitive
		"\x{fc}\x{df}"      => 'DRY RUN',     # non-ASCII letters are not a code
		'C'                 => 'DRY RUN',
		''                  => 'DRY RUN',
	);
	foreach my $value (sort keys %cases) {
		local $ENV{LANG} = $value;
		(my $shown = $value) =~ s/([^\x20-\x7E])/sprintf('\\x{%x}', ord $1)/ge;
		is($CONFIG{i18n}->i18n('dry_run_title'), $cases{$value}, "LANG='$shown'");
	}
};

#######################################################################
# App::Access2CSV::Exporter::new
#######################################################################

subtest 'new output_dir: empty | 1 character | long | non-ASCII | reference' => sub {
	my $class = $CONFIG{exporter};
	throws_ok { $class->new(output_dir => '') } qr/Parameter 'output_dir' .*must be at least 1/, 'invalid: empty (below the minimum)';
	lives_ok { $class->new(output_dir => '0') } 'valid: "0", the 1-character minimum';
	throws_ok { $class->new(output_dir => []) } qr/'output_dir'/, 'invalid: reference';

	# Non-ASCII folder names, given as UTF-8 bytes as they come from @ARGV
	my ($dir, $db) = new_database('T');
	foreach my $name (qw(german emoji zalgo arabic)) {
		my $folder = File::Spec->catdir($dir, bytes($TEXT{$name}));
		my $status;
		capture { $status = $class->new(output_dir => $folder, progress => 0)->run($db) };
		is($status, $CONFIG{exit_ok}, "$name folder: exported");
		ok(-f "$folder/T.csv", "$name folder: name not corrupted");
	}
};

subtest 'new tables: undef | empty | one | many | invalid elements' => sub {
	my ($status, undef, $out) = export([qw(A B C)], tables => undef);
	is_deeply(dir_entries($out), [qw(A.csv B.csv C.csv)], 'undef: all tables');

	($status, undef, $out) = export([qw(A B C)], tables => []);
	is_deeply(dir_entries($out), [], 'empty list (minimum size): no tables');

	($status, undef, $out) = export([qw(A B C)], tables => ['B']);
	is_deeply(dir_entries($out), ['B.csv'], 'one element');

	($status, undef, $out) = export([qw(A B C)], tables => [qw(A B C)]);
	is_deeply(dir_entries($out), [qw(A.csv B.csv C.csv)], 'every table');

	my $german = bytes($TEXT{german});
	($status, undef, $out) = export(['A', $german], tables => [$german]);
	is_deeply(dir_entries($out), ["$german.csv"], 'non-ASCII name given as UTF-8 bytes: matched');

	throws_ok { $CONFIG{exporter}->new(tables => 'A') } qr/Parameter 'tables' must be/, 'invalid: a string';
	throws_ok { $CONFIG{exporter}->new(tables => [[]]) } qr/'?tables'? can only contain strings/, 'invalid: element is a reference';
};

subtest 'new booleans: every valid spelling | every invalid neighbour' => sub {
	# Params::Validate::Strict's boolean domain is an exact list; near
	# misses (other capitalisation, padding, 2, -1) must be refused
	my $class = $CONFIG{exporter};
	foreach my $setting (@BOOLEANS) {
		foreach my $value (@BOOL_TRUE) {
			is($class->new($setting => $value)->{$setting}, 1, "$setting => '$value' is true");
		}
		foreach my $value (@BOOL_FALSE) {
			is($class->new($setting => $value)->{$setting}, 0, "$setting => '$value' is false");
		}
		foreach my $value (@BOOL_BAD) {
			throws_ok { $class->new($setting => $value) } qr/Parameter '$setting' \(\Q$value\E\) must be a boolean/, "$setting => '$value' refused";
		}
	}
};

subtest 'new encoding: the three names | near misses' => sub {
	my $class = $CONFIG{exporter};
	foreach my $value (qw(utf8 utf8-bom cp1252)) {
		is($class->new(encoding => $value)->{encoding}, $value, "valid: $value");
	}
	foreach my $value ('UTF8', 'utf-8', 'utf8bom', 'cp1251', 'CP1252', '', ' utf8') {
		throws_ok { $class->new(encoding => $value) } qr/Parameter 'encoding' \(\Q$value\E\) must be one of utf8, utf8-bom, cp1252/, "invalid: '$value'";
	}
};

subtest 'new logger: complete object | missing a method | not an object' => sub {
	{
		package Local::Full;
		sub new { bless {}, shift } sub debug { } sub info { } sub warn { }
		package Local::NoWarn;
		sub new { bless {}, shift } sub debug { } sub info { }
	}
	my $class = $CONFIG{exporter};
	lives_ok { $class->new(logger => Local::Full->new()) } 'valid: debug, info and warn';
	throws_ok { $class->new(logger => Local::NoWarn->new()) } qr/'logger'.*warn method/, 'invalid: one method short';
	throws_ok { $class->new(logger => {}) } qr/Parameter 'logger' must be an object/, 'invalid: plain hash';
	throws_ok { $class->new(logger => 'log.txt') } qr/Parameter 'logger' must be an object/, 'invalid: a file name';
};

subtest 'new language: code | empty | reference' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { dry_run_title => 'PROBELAUF' };
	my $class = $CONFIG{exporter};
	is($class->new(language => 'de')->i18n('dry_run_title'), 'PROBELAUF', 'valid code with a catalog');
	is($class->new(language => 'xx')->i18n('dry_run_title'), 'DRY RUN', 'valid code without a catalog');
	is($class->new(language => '')->i18n('dry_run_title'), 'DRY RUN', 'empty: use the environment');
	throws_ok { $class->new(language => []) } qr/'language'/, 'invalid: reference';
};

#######################################################################
# App::Access2CSV::Exporter::run
#######################################################################

subtest 'run database: file | missing | folder | device | empty | undef' => sub {
	my ($dir, $db) = new_database('T');
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, dry_run => 1);

	my $status;
	capture { $status = $e->run($db) };
	is($status, $CONFIG{exit_ok}, 'valid: readable regular file');
	throws_ok { $e->run("$dir/missing") } qr/\ACannot read database \Q$dir\E.missing: \Q$OS{enoent}\E at /, 'missing';
	throws_ok { $e->run($dir) } qr/\ADatabase \Q$dir\E is not a regular file at /, 'folder';
	throws_ok { $e->run('/dev/null') } qr/\ADatabase \/dev\/null is not a regular file at /, 'device';
	throws_ok { $e->run('') } qr/Parameter 'database' .*must be at least 1/, 'empty (below the 1-character minimum)';
	throws_ok { $e->run(undef) } qr/Required parameter 'database' is missing/, 'undef';
};

subtest 'run database: path component length 255 | 256' => sub {
	# NAME_MAX edge: 255 bytes is a legal (if missing) name; 256 is too long
	my $dir = tempdir(CLEANUP => 1);
	my $e = $CONFIG{exporter}->new(progress => 0);
	my $at_max = "$dir/" . ('d' x $CONFIG{name_max});
	my $over = "$dir/" . ('d' x ($CONFIG{name_max} + 1));
	throws_ok { $e->run($at_max) } qr/: \Q$OS{enoent}\E at /, '255: accepted by the OS, just missing';
	throws_ok { $e->run($over) } qr/: \Q$OS{enametoolong}\E at /, '256: too long';
};

subtest 'table name length: 1 | 64 | 251 | 252 bytes' => sub {
	# A file name is the table name plus ".csv", and at most 255 bytes, so
	# 251 is the longest table name that works
	my $max = $CONFIG{name_max} - length($CONFIG{csv_suffix});
	my %names = (
		one      => 'a',
		access   => 'b' x $CONFIG{access_max},
		at_max   => 'c' x $max,
		over_max => 'd' x ($max + 1),
	);
	my ($status, $stderr, $out) = export([values %names]);
	verbose_diag('files', dir_entries($out));
	is($status, $CONFIG{exit_failure}, 'only the over-long one fails');
	ok(-f "$out/$names{$_}.csv", "$_: exported") foreach qw(one access at_max);
	like($stderr, qr/FAILED: d+: .*\Q$OS{enametoolong}\E/, 'over_max: fails with the OS reason');
	is(scalar(@{ dir_entries($out) }), 3, 'no temporary file left for the failed one');
};

subtest 'table name length in multibyte characters: 125 | 126 x "u-umlaut"' => sub {
	# u-umlaut is 1 character but 2 bytes in UTF-8.  The file system sets
	# the limit, and they differ: Linux counts 255 bytes, macOS (APFS)
	# counts 255 characters.  So 126 u-umlauts (252 bytes + ".csv") is too
	# long on Linux but fine on a Mac.  Ask the file system which rule it
	# uses, then check the exporter follows it: whatever fits is exported
	# intact, whatever does not fails cleanly.
	my $u = bytes("\x{fc}");
	my $fits = int(($CONFIG{name_max} - length($CONFIG{csv_suffix})) / length($u));
	my $long = $u x ($fits + 1);

	my $probe_dir = tempdir(CLEANUP => 1);
	my $counts_bytes = !open(my $probe, '>', "$probe_dir/$long$CONFIG{csv_suffix}");
	close $probe if $probe;
	verbose_diag('file system limit counts', $counts_bytes ? 'bytes' : 'characters');

	my ($status, $stderr, $out) = export([$u x $fits, $long]);
	ok(-f "$out/" . ($u x $fits) . '.csv', "$fits characters (" . ($fits * length($u)) . ' bytes): exported, not corrupted');
	if($counts_bytes) {
		is($status, $CONFIG{exit_failure}, 'limit in bytes: one fits, one does not');
		like($stderr, qr/\Q$OS{enametoolong}\E/, ($fits + 1) . ' characters (' . length($long) . ' bytes): too long, reported');
	} else {
		is($status, $CONFIG{exit_ok}, 'limit in characters: both fit');
		ok(-f "$out/$long$CONFIG{csv_suffix}", ($fits + 1) . ' characters: exported, not corrupted');
	}
};

subtest 'table name characters: German, emoji, Zalgo, RTL text' => sub {
	# Kept exactly, byte for byte, in the file name and in the data
	my @names = map { bytes($TEXT{$_}) } qw(german emoji family zalgo arabic);
	my ($status, $stderr, $out) = export(\@names);
	is($status, $CONFIG{exit_ok}, 'all exported');
	is_deeply(dir_entries($out), [sort map { "$_.csv" } @names], 'file names byte-identical to the table names');
	like(slurp("$out/" . bytes($TEXT{family}) . '.csv'), qr/\Q${\ bytes($TEXT{family}) }\E/, 'joined emoji intact in the data');
};

subtest 'table name characters: invisible direction overrides are unsafe' => sub {
	# A right-to-left override makes "report<RLO>vsc.exe.csv" display as
	# "reportexe.csv.csv"-like text: a classic file-name spoofing trick.
	# Direction controls must be treated like other control characters.
	my @overrides = ("\x{202E}", "\x{202D}", "\x{2066}", "\x{2069}", "\x{200F}");
	my @names = map { bytes("t${_}x") } @overrides;
	push @names, bytes($TEXT{rtl});
	my ($status, undef, $out) = export(\@names);
	my @files = @{ dir_entries($out) };
	verbose_diag('files', \@files);
	is($status, $CONFIG{exit_ok}, 'exported');
	is(scalar(@files), scalar(@names), 'one file each');
	ok(!grep({ /\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]/ } @files), 'no direction control left in any file name');
	ok((grep { $_ eq 'report_vsc.exe.csv' } @files), 'spoofing name made visible');
};

subtest 'collision suffix: none | _2 | two digits' => sub {
	my @names = map { ('X' . (' ' x $_)) } 0 .. $CONFIG{many} - 1;
	my ($status, undef, $out) = export(\@names);
	my @files = @{ dir_entries($out) };
	is(scalar(@files), $CONFIG{many}, 'ten tables, ten files');
	ok((grep { $_ eq 'X.csv' } @files), 'first: no suffix');
	ok((grep { $_ eq 'X_2.csv' } @files), 'second: _2 (the lowest suffix)');
	ok((grep { $_ eq "X_$CONFIG{many}.csv" } @files), 'tenth: two-digit suffix');
};

subtest 'cp1252 data: the edges of Windows-1252' => sub {
	# U+00FF is the last Latin-1 letter; U+0100 the first outside;
	# U+20AC (Euro) is mapped; U+0080-U+009F are C1 controls, unmapped
	my %cases = (
		'U+00FF' => ["\x{ff}", "\xFF"],
		'U+20AC' => ["\x{20ac}", "\x80"],
		'sharp s and umlaut' => ["\x{df}\x{fc}", "\xDF\xFC"],
		'U+0100' => ["\x{100}", undef],
		'U+0081' => ["\x{81}", undef],
		'emoji'  => [$TEXT{emoji}, undef],
	);
	foreach my $case (sort keys %cases) {
		my ($chars, $expected) = @{ $cases{$case} };
		my $table = 'T';
		my ($dir, $db) = new_database($table);
		my $guard = do {
			require Test::Mockingbird;
			my $real = \&App::Access2CSV::Exporter::run3;
			Test::Mockingbird::mock_scoped('App::Access2CSV::Exporter::run3' => sub {
				my ($cmd, $in, $out, $err) = @_;
				return $real->(@_) unless $cmd->[0] =~ /mdb-export\z/;
				print {$out} bytes($chars) . "\n";
				$out->flush();
				${$err} = '';
				$? = 0;
				return 1;
			});
		};
		my $status;
		my (undef, $stderr) = capture {
			$status = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, encoding => 'cp1252')->run($db);
		};
		if(defined $expected) {
			is($status, $CONFIG{exit_ok}, "$case: converted");
			is(slurp("$dir/out/T.csv"), "$expected\n", "$case: right byte");
		} else {
			is($status, $CONFIG{exit_failure}, "$case: refused");
			like($stderr, qr/line 1: cannot be represented in cp1252/, "$case: reported");
		}
	}
};

subtest 'row counts: 0 | 1 | 2' => sub {
	# The plural edge in the log message
	require Test::Mockingbird;
	foreach my $rows (0, 1, 2) {
		my $real = \&App::Access2CSV::Exporter::run3;
		my $guard = Test::Mockingbird::mock_scoped('App::Access2CSV::Exporter::run3' => sub {
			my ($cmd, $in, $out, $err) = @_;
			return $real->(@_) unless $cmd->[0] =~ /mdb-count\z/;
			${$out} = "$rows\n";
			${$err} = '';
			$? = 0;
			return 1;
		});
		{
			package Local::Rec;
			sub new { bless { lines => [] }, shift }
			sub debug { } sub warn { }
			sub info { push @{ $_[0]{lines} }, $_[1] }
		}
		my $logger = Local::Rec->new();
		my ($dir, $db) = new_database('T');
		capture { $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, show_counts => 1, logger => $logger)->run($db) };
		my $word = $rows == 1 ? 'row' : 'rows';
		ok((grep { /\($rows $word\)\z/ } @{ $logger->{lines} }), "$rows: '($rows $word)'");
	}
};

#######################################################################
# App::Access2CSV::run
#######################################################################

sub cli {
	my @argv = @_;
	my $status;
	my ($stdout, $stderr) = capture { $status = $CONFIG{app}->run(@argv) };
	return ($status, $stdout, $stderr);
}

subtest 'argv: 0 | 1 | 2 database names' => sub {
	my ($dir, $db) = new_database('T');
	my @common = ('--no-log', '--dry-run');
	my ($status, undef, $stderr) = cli(@common);
	is($status, $CONFIG{exit_usage}, '0 (below the only valid count)');
	like($stderr, qr/^Missing database filename$/m, 'message');
	($status) = cli(@common, $db);
	is($status, $CONFIG{exit_ok}, 'exactly one (the only valid count)');
	($status, undef, $stderr) = cli(@common, $db, $db);
	is($status, $CONFIG{exit_usage}, '2 (above)');
	like($stderr, qr/^Missing database filename$/m, 'message');
};

subtest 'argv --encoding: valid names | invalid' => sub {
	my ($dir, $db) = new_database('T');
	foreach my $value (qw(utf8 utf8-bom cp1252)) {
		my ($status) = cli('--no-log', '--dry-run', '--encoding', $value, $db);
		is($status, $CONFIG{exit_ok}, "valid: $value");
	}
	my ($status, undef, $stderr) = cli('--no-log', '--encoding', 'latin1', $db);
	is($status, $CONFIG{exit_usage}, 'invalid: latin1 (usage error)');
	like($stderr, qr/^Invalid setting: Parameter 'encoding' \(latin1\) must be one of utf8, utf8-bom, cp1252$/m, 'message');
};

subtest 'argv --table: 0 | 1 | many | non-ASCII' => sub {
	my $german = bytes($TEXT{german});
	my ($dir, $db) = new_database('A', 'B', $german);
	my %cases = (
		0    => [[], 3],
		1    => [['A'], 1],
		many => [['A', 'B', $german], 3],
		utf8 => [[$german], 1],
	);
	foreach my $case (sort keys %cases) {
		my ($tables, $files) = @{ $cases{$case} };
		my $out = "$dir/$case";
		my ($status) = cli('--no-log', '--no-progress', '--output-dir', $out, (map { ('--table', $_) } @{$tables}), $db);
		is($status, $CONFIG{exit_ok}, "$case: success");
		is(scalar(@{ dir_entries($out) }), $files, "$case: $files file(s)");
	}
};

subtest 'argv --log: empty | file | --no-log' => sub {
	# The default log goes to the current folder, so run in an empty one:
	# a log someone left in the real current folder must not matter, and
	# a failing test must not leave one there either
	my ($dir, $db) = new_database('T');
	my $work = tempdir(CLEANUP => 1);
	my $cwd = File::Spec->rel2abs(File::Spec->curdir());
	chdir $work or die "$work: $!";

	cli('--log', '', '--dry-run', $db);
	ok(!-e 'access2csv.log', "'' means no log (no default file created)");
	cli('--log', "$dir/x.log", '--dry-run', $db);
	ok(-e "$dir/x.log", 'a file name: that file');
	cli('--no-log', '--dry-run', $db);
	ok(!-e 'access2csv.log', '--no-log: no file');

	chdir $cwd or die "$cwd: $!";
};

subtest 'no failure above changed shared state' => sub {
	is_deeply(\%App::Access2CSV::I18N::MESSAGES, $CATALOG, 'message catalog unchanged');
	ok(!exists $ENV{LANG}, 'LANG not left set');
};

done_testing();
