use strict;
use warnings;
use utf8;

use Test::Most;

use App::Actions::I18N qw(i18n throw validate_args);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Nothing here should depend on the environment of whoever runs the suite.
delete local $ENV{ACTION_RUN_LANG};

my $en = App::Actions::I18N->new;

subtest 'placeholders are named sprintf conversions' => sub {
	is($en->message('workflow.empty', { file => 'ci.yml' }), "Workflow 'ci.yml' is empty",
		'a %(name)s placeholder takes its argument');
	is($en->message('workflow.empty'), "Workflow '' is empty",
		'a missing string argument renders as empty, without a warning');
	my $text;
	warnings_are { $text = $en->message('cache.removed', { count => 'many', size => '1 MB' }) } [],
		'a non-numeric count does not warn';
	is($text, 'Removed 0 images, 1 MB freed.', 'it is formatted as 0 and takes the plural form');
};

subtest 'plural forms follow the language rule' => sub {
	my $fr = App::Actions::I18N->new(language => 'fr');
	my $zh = App::Actions::I18N->new(language => 'zh');

	is($en->message('span.day', { count => 1 }), '1 day', 'English one');
	is($en->message('span.day', { count => 0 }), '0 days', 'English counts 0 as plural');
	is($fr->message('span.day', { count => 0 }), '0 jour', 'French counts 0 as singular');
	is($fr->message('span.day', { count => 2 }), '2 jours', 'French plural');
	is($zh->message('span.day', { count => 1 }), '1 天', 'Chinese has one form');
	is($zh->message('span.day', { count => 5 }), '5 天', 'and uses it for every count');
};

subtest 'gender selects a branch, which may be pluralised in turn' => sub {
	App::Actions::I18N->add_messages(en => {
		'test.ran' => {
			gender => {
				female => { plural => { one => 'She ran %(count)d job', other => 'She ran %(count)d jobs' } },
				male => 'He ran %(count)d jobs',
				other => 'They ran %(count)d jobs',
			},
		},
	});

	is($en->message('test.ran', { gender => 'female', count => 1 }), 'She ran 1 job', 'female, singular');
	is($en->message('test.ran', { gender => 'FEMALE', count => 3 }), 'She ran 3 jobs', 'gender is case-insensitive');
	is($en->message('test.ran', { gender => 'male', count => 3 }), 'He ran 3 jobs', 'male');
	is($en->message('test.ran', { count => 3 }), 'They ran 3 jobs', 'no gender is other');
	is($en->message('test.ran', { gender => 'robot', count => 3 }), 'They ran 3 jobs', 'an unknown gender is other');
};

subtest 'a missing translation falls back to English' => sub {
	App::Actions::I18N->add_messages(en => { 'test.only_english' => 'only %(what)s' });
	my $de = App::Actions::I18N->new(language => 'de');

	is($de->message('test.only_english', { what => 'English' }), 'only English',
		'a key German lacks is rendered from the English catalogue');
	is($de->message('workflow.empty', { file => 'x' }), "Der Workflow 'x' ist leer",
		'a key German has is rendered in German');
};

subtest 'an unknown key or language degrades rather than dies' => sub {
	my $text;
	warning_like { $text = $en->message('no.such.key') } qr/No message is defined for 'no\.such\.key'/,
		'an unknown key warns';
	is($text, 'no.such.key', 'and renders as itself');

	my $ja;
	warning_like { $ja = App::Actions::I18N->new(language => 'ja') } qr/Language 'ja' has no catalogue; using English/,
		'a language without a catalogue warns';
	is($ja->language, 'en', 'and falls back to English');
};

subtest 'the language is chosen by argument, config, environment, then English' => sub {
	is(App::Actions::I18N->new(language => 'de_DE.UTF-8')->language, 'de', 'a POSIX locale name is reduced to its language');
	is(App::Actions::I18N->new(language => 'fr-CA')->language, 'fr', 'so is a BCP 47 tag');
	is(App::Actions::I18N->new(language => 'de', country => 'FR')->language, 'de', 'language wins over country');

	{
		local $App::Actions::I18N::config{language} = 'fr';
		local $ENV{ACTION_RUN_LANG} = 'de';
		is(App::Actions::I18N->new->language, 'fr', 'config wins over the environment');
	}
	{
		local $ENV{ACTION_RUN_LANG} = 'de';
		is(App::Actions::I18N->new->language, 'de', 'the environment is used when nothing else chooses');
		is(App::Actions::I18N->shared->language, 'de', 'and by the shared default');
	}
	is(App::Actions::I18N->shared->language, 'en', 'the default follows a change to the environment');
	is_deeply(App::Actions::I18N->languages, [qw(de en fr zh)], 'the catalogues are listed');
};

subtest 'every catalogue agrees with English' => sub {
	# A translation must have the same keys and use the same placeholders,
	# or a message would silently lose (or invent) one of its arguments.
	my %english_keys = map { $_ => 1 } @{ App::Actions::I18N->catalogue_keys('en') };
	for my $language (grep { $_ ne 'en' } @{ App::Actions::I18N->languages }) {
		my %translated = map { $_ => 1 } @{ App::Actions::I18N->catalogue_keys($language) };
		my @missing = grep { !$translated{$_} && !/\Atest\./ } sort keys %english_keys;
		is_deeply(\@missing, [], "$language has every English key");
	}

	# Every placeholder the English texts use, found in the texts themselves,
	# so that a new message cannot slip past with an argument nobody checks.
	# A plural or gender choice is a hash of texts, which is searched too.
	my @texts = values %{ App::Actions::I18N::en->messages };
	my %placeholders;
	while (defined(my $text = shift @texts)) {
		if (ref $text eq 'HASH') {
			push @texts, values %{$text};
			next;
		}
		$placeholders{$1} = 1 while $text =~ /%\((\w+)\)/g;
	}
	ok(scalar(keys %placeholders) > 20, 'the English texts name their placeholders');
	my %args = map { $_ => "<$_>" } keys %placeholders;
	$args{count} = 2;
	for my $language (@{ App::Actions::I18N->languages }) {
		my $translator = App::Actions::I18N->new(language => $language);
		for my $key (sort keys %english_keys) {
			my @names = sort($en->message($key, \%args) =~ /<(\w+)>/g);
			my @translated = sort($translator->message($key, \%args) =~ /<(\w+)>/g);
			is_deeply(\@translated, \@names, "$language $key uses the same placeholders") or last;
		}
	}
};

subtest 'i18n and throw act as methods' => sub {
	{
		package Local::Thing;
		use App::Actions::I18N qw(i18n throw);
		sub new { my ($class, %args) = @_; return bless { %args }, $class }
		sub fail { my $self = shift; $self->throw('workflow.no_jobs', { file => 'f.yml', @_ }) }
	}

	my $german = Local::Thing->new(i18n => App::Actions::I18N->new(language => 'de'));
	like($german->i18n('workflow.empty', { file => 'x' }), qr/ist leer/, 'an object with its own translator uses it');
	like(Local::Thing->i18n('workflow.empty', { file => 'x' }), qr/is empty/, 'a class name uses the default');

	# The line of the call to fail() is where croak would have pointed had
	# Local::Thing croaked itself; throw must not move it.
	my $line = __LINE__ + 1;
	throws_ok { Local::Thing->new->fail } qr/Workflow 'f\.yml' has no 'jobs' mapping at .+ line $line\.$/,
		'throw reports from the caller of the throwing routine';

	throws_ok { Local::Thing->new->fail(trace => 1) } qr/has no 'jobs' mapping at .*Local::Thing::fail/s,
		'trace => 1 confesses with a stack trace';
};

subtest 'validate_args reports bad arguments in the catalogue' => sub {
	throws_ok { App::Actions::I18N->new(language => 7) }
		qr/^Invalid arguments to App::Actions::I18N::new: Parameter 'language' \(7\) must match pattern/,
		'a mistyped argument is named, without the validator\'s own location';
	throws_ok { App::Actions::I18N->new(dialect => 'scouse') }
		qr/^Invalid arguments to App::Actions::I18N::new: Unknown parameter 'dialect'/,
		'an unknown argument is refused';
	throws_ok { App::Actions::I18N->language_for_country('GBR') } qr/Invalid arguments/,
		'a three-letter country is refused';

	local $ENV{ACTION_RUN_LANG} = 'fr';
	throws_ok { $en->message(undef) } qr/^Arguments invalides pour App::Actions::I18N::message/,
		'the complaint is in the language of the run';
};

subtest 'private subroutines are enforced outside the test harness bypass' => sub {
	local $Sub::Private::config{harness_bypass} = 0;

	throws_ok { App::Actions::I18N::_render('x', {}) }
		qr/_render\(\) is a private subroutine of App::Actions::I18N and cannot be called from main/,
		'a private helper cannot be called from outside its package';
	is($en->message('where.job', { job => 'j' }), "job 'j'", 'while the public interface still works');
};

done_testing();
