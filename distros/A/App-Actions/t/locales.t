use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Errno qw(ENOENT);
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX qw(setlocale LC_ALL);
use Test::Most;

use App::Actions::I18N;
use App::Actions::Process;
use App::Actions::Workflow;

# Object::Configure reads the developer's own configuration files (~/.conf
# and the like), where a UNIVERSAL logger would take the messages these tests
# read off standard error.  An empty directory leaves the defaults in force.
local $ENV{CONFIG_DIR} = tempdir(CLEANUP => 1);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# The suite's own environment must not choose a language for it.
delete local $ENV{ACTION_RUN_LANG};

my $root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $lib = File::Spec->catdir($root, 'lib');
my $script = File::Spec->catfile($root, 'bin', 'action-run');
my $scratch = tempdir(CLEANUP => 1);

# The countries the catalogue is tested for, the language each must map to,
# and a fragment of workflow.file_missing that only that language says.
my %COUNTRY = (
	GB => { language => 'en', says => qr/does not exist/ },
	US => { language => 'en', says => qr/does not exist/ },
	FR => { language => 'fr', says => qr/n'existe pas/ },
	DE => { language => 'de', says => qr/existiert nicht/ },
	CN => { language => 'zh', says => qr/不存在/ },
);

# The POSIX locales the error paths are run under: English, German, and an
# East Asian language.  None needs to be installed; one that is not leaves
# the C locale in force, and the paths must throw the same way regardless.
my @LOCALES = qw(en_US.UTF-8 de_DE.UTF-8 ja_JP.UTF-8);

# A path whose directory does not exist, so opening it fails with ENOENT.
my $unreachable = File::Spec->catfile($scratch, 'no-such-directory', 'out.txt');
my $missing_workflow = File::Spec->catfile($scratch, 'absent.yml');

subtest 'sanity: the country-to-language mapping has not drifted' => sub {
	# Everything below assumes these five; if the table has moved, the later
	# failures would be noise, so stop the file here instead.
	for my $country (sort keys %COUNTRY) {
		my $got = App::Actions::I18N->language_for_country($country);
		is($got, $COUNTRY{$country}{language}, "$country maps to $COUNTRY{$country}{language}")
			or BAIL_OUT("The country-to-language mapping has drifted: $country gave "
				. (defined $got ? $got : 'undef') . ", expected $COUNTRY{$country}{language}");
	}
};

subtest 'geographic: each country gets its language' => sub {
	for my $country (sort keys %COUNTRY) {
		my $i18n = App::Actions::I18N->new(country => $country);
		is($i18n->language, $COUNTRY{$country}{language}, "$country selects $COUNTRY{$country}{language}");
		like($i18n->message('workflow.file_missing', { file => 'ci.yml' }), $COUNTRY{$country}{says},
			"$country reads the message in its language");
	}

	is(App::Actions::I18N->language_for_country('JP'), undef, 'a country with no catalogue maps to nothing');
	my $japan;
	warnings_are { $japan = App::Actions::I18N->new(country => 'JP') } [],
		'and choosing it does not warn';
	is($japan->language, 'en', 'it falls back to English');
};

subtest 'geographic: country codes are case-insensitive' => sub {
	for my $country (sort keys %COUNTRY) {
		my $want = $COUNTRY{$country}{language};
		my @spellings = (uc $country, lc $country, ucfirst lc $country, lcfirst $country);
		for my $spelling (@spellings) {
			is(App::Actions::I18N->language_for_country($spelling), $want, "'$spelling' maps to $want");
			is(App::Actions::I18N->new(country => $spelling)->language, $want, "'$spelling' selects $want");
		}
	}
};

subtest 'geographic: concurrent instances keep their own language' => sub {
	# One translator per country, all alive at once, used in an interleaved
	# order: no instance may pick up another's language, and none may
	# change the shared default.
	my %translator = map { $_ => App::Actions::I18N->new(country => $_) } sort keys %COUNTRY;

	for my $round (1 .. 3) {
		for my $country (reverse sort keys %COUNTRY) {
			like($translator{$country}->message('workflow.file_missing', { file => "r$round.yml" }),
				$COUNTRY{$country}{says}, "round $round: $country is still in its language");
		}
	}
	is(App::Actions::I18N->shared->language, 'en', 'the shared default is untouched');

	# Plural rules are per language: the same count, rendered by two
	# instances at once, takes each language's form.
	is($translator{FR}->message('span.day', { count => 0 }), '0 jour', 'French singular for 0');
	is($translator{GB}->message('span.day', { count => 0 }), '0 days', 'English plural for 0, at the same time');
};

# _in_locale
# Purpose:     Run a block with LC_ALL set in the environment and, where the
#              locale is installed, in the C library too.
# Entry:       $locale - the locale name; $code - the block.
# Exit status: Returns whether setlocale accepted the locale.
# Side effects: Changes and restores the process locale.
sub _in_locale {
	my ($locale, $code) = @_;

	local $ENV{LC_ALL} = $locale;
	my $previous = setlocale(LC_ALL);
	my $applied = setlocale(LC_ALL, $locale);

	my $ok = eval { $code->(); 1 };
	my $error = $@;
	setlocale(LC_ALL, $previous);
	die $error unless $ok;

	return defined $applied ? 1 : 0;
}

for my $locale (@LOCALES) {
	subtest "system: error paths under LC_ALL=$locale" => sub {
		my $applied = _in_locale($locale, sub {
			# The OS text is taken from Perl's own $!, set to the errno the
			# failure produces, rather than from POSIX::strerror: that keeps
			# the expectation in the same layer as the message being tested,
			# whatever the C library would say for this locale.
			my $enoent = do { local $! = ENOENT; "$!" };

			throws_ok {
				App::Actions::Process::run([ $^X, '-e', '1' ], stdout => $unreachable);
			} qr/Unable to redirect command output: \Q$enoent\E/,
				"an unwritable output file reports '$enoent'";

			# The catalogue deliberately ignores the POSIX locale, so the
			# message a CI script matches cannot change under it.
			throws_ok { App::Actions::Workflow->load($missing_workflow) }
				qr/^Workflow file '\Q$missing_workflow\E' does not exist/,
				'a catalogue error is still in English';

			local $ENV{ACTION_RUN_LANG} = 'de';
			throws_ok { App::Actions::Workflow->load($missing_workflow) }
				qr/^Die Workflow-Datei '\Q$missing_workflow\E' existiert nicht/,
				'ACTION_RUN_LANG, not the locale, chooses the language';
		});
		diag("$locale is not installed here; the C locale was in force") unless $applied;

		# The command a user runs: the error must still be raised, reported
		# on standard error and given the infrastructure exit status.
		local $ENV{LC_ALL} = $locale;
		my ($stdout, $stderr, $status) = capture {
			system($^X, "-I$lib", $script, $missing_workflow);
		};
		is($status >> 8, 2, "action-run exits 2 for a missing workflow under $locale");
		like($stderr, qr/^action-run: Workflow file '.*absent\.yml' does not exist$/m,
			'and says why on standard error');
	};
}

done_testing();
