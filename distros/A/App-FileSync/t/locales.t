#!/usr/bin/env perl

# Message catalogues and locale selection.  "Geographic" tests drive the
# language from a country code (as a GeoIP lookup or a locale's territory
# would supply it); "system" tests run child processes under real LC_ALL
# values and check that OS error text reaches our messages unchanged.

use strict;
use warnings;

use Errno qw(ENOENT);
use File::Find ();
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Test::Most;

use App::FileSync::I18N qw(message);
use App::FileSync::I18N::en;
use App::FileSync::Admin;

my $lib = File::Spec->catdir($Bin, '..', 'lib');

# Stub catalogues: just enough to tell the languages apart.  Real
# translations would ship as App::FileSync::I18N::xx modules.
my %STUB = (
	fr => {
		'word.file'      => { _by => 'count', one => '%{count}d fichier', other => '%{count}d fichiers' },
		'admin.locked'   => q{Une autre session tient le verrou du depot '%{repo}s'},
		'test.greeting'  => { _by => 'gender', female => 'Chere %{name}s', male => 'Cher %{name}s', other => 'Bonjour %{name}s' },
	},
	de => {
		'word.file'      => { _by => 'count', one => '%{count}d Datei', other => '%{count}d Dateien' },
		'admin.locked'   => q{Eine andere Sitzung halt die Sperre fur '%{repo}s'},
	},
	zh => {
		'word.file'      => { _by => 'count', one => '%{count}d ge wenjian', other => '%{count}d ge wenjian' },
	},
);
App::FileSync::I18N::register($_ => $STUB{$_}) for sort keys %STUB;

# The country -> language table drives everything below; if it has drifted,
# every later failure would be noise.
subtest 'sanity: country mapping' => sub {
	my %expected = (GB => 'en', US => 'en', FR => 'fr', DE => 'de', CN => 'zh');
	my $ok = 1;
	for my $country (sort keys %expected) {
		$ok &&= is(App::FileSync::I18N::country_language($country), $expected{$country}, "$country maps to $expected{$country}");
	}
	BAIL_OUT('the country -> language table has drifted') unless $ok;
};

subtest 'geographic: each country selects its catalogue' => sub {
	local $ENV{$_} for qw(LC_ALL LC_MESSAGES LANG FILESYNC_LANG);
	is(message('word.file', { count => 2 }, 'GB'), '2 files', 'GB gets English');
	is(message('word.file', { count => 2 }, 'US'), '2 files', 'US gets English');
	is(message('word.file', { count => 2 }, 'FR'), '2 fichiers', 'FR gets French');
	is(message('word.file', { count => 2 }, 'DE'), '2 Dateien', 'DE gets German');
	is(message('word.file', { count => 2 }, 'CN'), '2 ge wenjian', 'CN gets Chinese');
};

subtest 'geographic: case-insensitivity' => sub {
	for my $code (qw(fr Fr fR FR)) {
		is(App::FileSync::I18N::country_language($code), 'fr', "country '$code'");
	}
	is(App::FileSync::I18N::language('fr_fr'), 'fr', 'a lower-case territory');
	is(App::FileSync::I18N::language('DE_de.utf8'), 'de', 'an upper-case language');
	is(App::FileSync::I18N::language('de-AT'), 'de', 'a hyphen instead of an underscore');
};

subtest 'geographic: unknown and empty' => sub {
	is(App::FileSync::I18N::country_language('ZZ'), undef, 'an unknown country maps to nothing');
	is(App::FileSync::I18N::country_language(undef), undef, 'no country maps to nothing');
	is(message('word.file', { count => 2 }, 'ZZ'), '2 files', 'and falls back to English');
	is(message('word.file', { count => 2 }, 'JP'), '2 files', 'a language with no catalogue falls back to English');
	is(message('word.file', { count => 2 }, 'C'), '2 files', 'the C locale is English');
};

subtest 'geographic: concurrent instances keep their own language' => sub {
	my $root = tempdir(CLEANUP => 1);
	my %admin = map { $_ => App::FileSync::Admin->new(root => $root, language => $_) } qw(en fr de);

	# Interleave the calls: a shared "current language" would leak between them.
	is($admin{fr}->i18n('word.file', { count => 1 }), '1 fichier', 'French object');
	is($admin{de}->i18n('word.file', { count => 1 }), '1 Datei', 'German object');
	is($admin{en}->i18n('word.file', { count => 1 }), '1 file', 'English object');
	is($admin{fr}->i18n('word.file', { count => 3 }), '3 fichiers', 'French object again');
	is($admin{fr}->language, 'fr', 'each object reports its own language');

	# Errors raised by each object are rendered in that object's language.
	throws_ok { $admin{de}->_throw('admin.locked', { repo => 'docs' }) } qr/Sperre fur 'docs'/, 'German error';
	throws_ok { $admin{fr}->_throw('admin.locked', { repo => 'docs' }) } qr/verrou du depot 'docs'/, 'French error';
	throws_ok { $admin{en}->_throw('admin.locked', { repo => 'docs' }) } qr/holds the lock for repo 'docs'/, 'English error';
};

subtest 'plural rules' => sub {
	is(message('word.file', { count => 0 }, 'en'), '0 files', 'English zero is plural');
	is(message('word.file', { count => 1 }, 'en'), '1 file', 'English one');
	is(message('word.file', { count => 0 }, 'fr'), '0 fichier', 'French zero is singular');
	is(message('word.file', { count => 1 }, 'fr'), '1 fichier', 'French one');
	is(message('word.file', { count => 2 }, 'fr'), '2 fichiers', 'French two');
	is(message('word.file', { count => 'many' }, 'en'), '0 files', 'a non-numeric count is treated as zero');
};

subtest 'gender selection, with fallback' => sub {
	is(message('test.greeting', { name => 'Alex', gender => 'female' }, 'fr'), 'Chere Alex', 'female form');
	is(message('test.greeting', { name => 'Alex', gender => 'male' }, 'fr'), 'Cher Alex', 'male form');
	is(message('test.greeting', { name => 'Alex' }, 'fr'), 'Bonjour Alex', 'no gender uses the neutral form');
	is(message('test.greeting', { name => 'Alex', gender => 'nonbinary' }, 'fr'), 'Bonjour Alex', 'an unlisted gender uses the neutral form');
};

subtest 'sprintf formats and escapes' => sub {
	App::FileSync::I18N::register(xx => {
		'test.format' => '%{name}-6s|%{n}05.1f|%{count}3d|100%%',
	});
	is(message('test.format', { name => 'ab', n => 3.14159, count => 7 }, 'xx'), 'ab    |003.1|  7|100%', 'width, precision and %% are honoured');
	is(message('test.format', {}, 'xx'), '      |000.0|  0|100%', 'missing arguments render as empty or zero');
	is(message('test.format', { name => '%{n}f' }, 'xx'), '%{n}f |000.0|  0|100%', 'a value is never re-interpreted as a template');
	App::FileSync::I18N::unregister('xx');
	is(message('no.such.key', { a => 1 }), 'no.such.key (a=1)', 'an unknown key still shows its arguments');
};

subtest 'environment selects the language' => sub {
	local $App::FileSync::I18N::config{language};
	local $ENV{FILESYNC_LANG};
	local $ENV{LC_MESSAGES};
	local $ENV{LANG};

	local $ENV{LC_ALL} = 'fr_FR.UTF-8';
	is(message('word.file', { count => 2 }), '2 fichiers', 'LC_ALL is honoured');

	local $ENV{FILESYNC_LANG} = 'de';
	is(message('word.file', { count => 2 }), '2 Dateien', 'FILESYNC_LANG beats LC_ALL');

	local $App::FileSync::I18N::config{language} = 'en';
	is(message('word.file', { count => 2 }), '2 files', 'the configured language beats the environment');
};

subtest 'catalogue completeness' => sub {
	my %catalogue = %App::FileSync::I18N::en::MESSAGES;
	my (%used, @files);
	File::Find::find(sub { push @files, $File::Find::name if /\.pm\z/ }, $lib);

	# Literal keys passed to the message functions.  Keys built at run time
	# (server.op.$kind, cli.usage.$command, ...) are checked as families below.
	my $call = qr/\b(?:throw|_throw|message|i18n|_say|warning)\(\s*'([a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+)'/;
	for my $file (@files) {
		open my $fh, '<', $file or die "$file: $!";
		my $source = do { local $/; <$fh> };

		# Code only: POD examples are checked by reading them, not here.
		$source =~ s/^=[a-zA-Z].*?(?:^=cut\b[^\n]*\n|\z)//msg;
		$used{$1} = $file while $source =~ /$call/g;
	}

	ok(scalar(keys %used) > 100, 'the scan found the message calls');
	my @missing = grep { !exists $catalogue{$_} } sort keys %used;
	is_deeply(\@missing, [], 'every literal key is in the English catalogue')
		or diag(join("\n", map { "missing: $_ (in $used{$_})" } @missing));

	for my $family (
		[ 'server.op.', qw(read write delta pull mkdir delete ack) ],
		[ 'cli.usage.', qw(server init sync status log settings verify restore snapshot snapshot_list snapshot_restore
			repo_create admin_log reindex admin_verify admin_restore client_allow client_list client_forget) ],
		[ 'cli.source.', qw(default merged env file repo_only) ],
		[ 'cli.repo_source.', qw(repo process default) ],
		[ 'cli.transfer.', qw(pulled pushed report) ],
		[ 'cli.repo.created.', qw(name master config) ],
		[ 'cli.snapshot.column.', qw(date files size path) ],
	) {
		my ($prefix, @names) = @{$family};
		ok(exists $catalogue{"$prefix$_"}, "$prefix$_ exists") for @names;
	}

	# POD and messages must stay ASCII so any terminal can show them.
	my @non_ascii = grep { !ref $catalogue{$_} && $catalogue{$_} =~ /[^\x00-\x7f]/ } keys %catalogue;
	is_deeply(\@non_ascii, [], 'the English catalogue is ASCII');
};

# --- system (POSIX) locales --------------------------------------------------
#
# Each child sets LC_ALL before Perl starts, then compares our io.read error
# with Perl's own text for ENOENT.  The expected text comes from
# "local $! = ENOENT; "$!"" - never POSIX::strerror - so both sides go through
# the same layer and cannot diverge on a C library that translates
# differently.

my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'no-such-file');

for my $locale ('en_US.UTF-8', 'de_DE.UTF-8', 'ja_JP.UTF-8') {
	subtest "system locale $locale" => sub {
		my $child = <<'CHILD';
use strict;
use warnings;
use Errno qw(ENOENT);
use POSIX qw(setlocale LC_MESSAGES);
use App::FileSync::IO qw(read_text);
my $expected = do { local $! = ENOENT; "$!" };
my $error = eval { read_text($ARGV[0]); 1 } ? 'no error' : "$@";
my $in_effect = setlocale(LC_MESSAGES) // 'C';
print "EXPECTED=$expected\nERROR=$error\nLOCALE=$in_effect\n";
CHILD
		local $ENV{LC_ALL} = $locale;
		local $ENV{FILESYNC_LANG};
		local $ENV{HARNESS_ACTIVE} = 1;

		# A locale this machine lacks makes perl warn at start-up and fall back
		# to C; the test still holds, so keep the output quiet.
		local $ENV{PERL_BADLANG} = 0;

		open my $pipe, '-|', $^X, "-I$lib", '-e', $child, $missing or die "cannot start perl: $!";
		my $output = do { local $/; <$pipe> };
		close $pipe;

		my ($expected) = $output =~ /^EXPECTED=(.*)$/m;
		my ($error) = $output =~ /^ERROR=(.*)$/m;
		my ($in_effect) = $output =~ /^LOCALE=(.*)$/m;

		ok(defined $expected && length $expected, 'Perl describes ENOENT');
		isnt($error, 'no error', 'reading a missing file raises');
		like($error, qr/\A\QCannot read $missing: \E/, 'the message is the catalogued one (English: no catalogue for this language ships)');
		like($error, qr/\Q$expected\E/, "it carries Perl's own ENOENT text ($expected)");
		unlike($error, qr/ at \S+ line \d+.*\n.* at \S+ line \d+/s, 'no stack trace without FILESYNC_TRACE');

		# The checks above hold under any locale, so they always run; this one
		# shows in the TAP whether they ran under the locale asked for or under
		# a fallback (perl uses LANG, then C, when LC_ALL names a missing one).
		my ($name) = split /\./, $locale;
		SKIP: {
			skip("$locale is not installed here; the child fell back to " . ($in_effect // 'C'), 1)
				unless defined $in_effect && $in_effect =~ /\A\Q$name\E/i;
			pass("the child ran under $locale ($in_effect)");
		}
	};
}

done_testing();
