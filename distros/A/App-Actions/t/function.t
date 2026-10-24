#!/usr/bin/env perl

# White-box tests of the routines in lib/, internal helpers included, one
# module at a time.  Each subtest says what the routine is meant to do and
# then spends most of its effort trying to break it: bad arguments, failures
# injected half way through with Test::Mockingbird, hostile input, and the
# guard clauses that are supposed to stop all of that.  Collaborators are
# mocked so that a test fails because of the routine it names and nothing
# else.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;

use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util qw(blessed);

# Object::Configure reads the developer's own configuration files (~/.conf
# and the like), where a UNIVERSAL logger would take the messages these tests
# read off standard error.  An empty directory leaves the defaults in force.
local $ENV{CONFIG_DIR} = tempdir(CLEANUP => 1);

# Every message below is compared in English; the developer's own language
# setting must not translate it.
delete local $ENV{ACTION_RUN_LANG};

# Keep the cache record and the logs out of the developer's own.
local $ENV{ACTION_RUN_CACHE_FILE} = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
local $ENV{ACTION_RUN_LOG_DIR} = File::Spec->catdir(tempdir(CLEANUP => 1), 'logs');

use App::Actions::Access;
use App::Actions::Error;
use App::Actions::I18N qw(i18n throw validate_args);
use App::Actions::Util qw(load_yaml_mapping mapping normalize_step stringify trim);

# These are white-box tests: they call the _private helpers directly, which
# Sub::Private forbids everywhere else.  prove bypasses the check through
# HARNESS_ACTIVE; this makes "perl -Ilib t/function.t" behave the same.
{
	no warnings 'once';
	$Sub::Private::BYPASS = 1;
}

# Values the tests share, named so that a failure says what was meant.
Readonly::Hash my %config => (
	sentinel => 'caller value of $_',	# what $_ holds before a helper runs
	big => 100_000,			# "large" input for linear-time checks
	time_limit => 2,		# seconds a linear routine may take on it
);

# Shows a routine's internal state when the run is verbose, and stays quiet
# otherwise so the normal output is only the test lines.
sub show_state {
	my ($label, $value) = @_;
	diag($label, ': ', explain($value)) if $ENV{TEST_VERBOSE};
	return;
}

# Runs a block and returns what it died with (undef when it lived), so that
# an exception object can be inspected rather than only matched as text.
sub caught(&) {
	my ($code) = @_;
	my $error;
	eval { $code->(); 1 } or $error = $@;
	return $error;
}

# Asserts that a block raised an App::Actions::Error with this code and this
# exact message, the two things a caller is allowed to rely on.
sub throws_code {
	my ($code, $want_code, $want_message, $name) = @_;
	my $error = caught { $code->() };
	subtest $name => sub {
		ok(blessed($error) && $error->isa('App::Actions::Error'), 'an App::Actions::Error was thrown')
			or return diag(explain($error));
		is($error->code, $want_code, 'with the expected code');
		is($error->message, $want_message, 'and the exact message') if defined $want_message;
		show_state('error', { code => $error->code, message => $error->message });
	};
	return $error;
}

# Runs a helper with $_ set, and says whether it was left alone: a helper that
# assigns to $_ without localising it corrupts the caller's loop variable.
sub keeps_topic {
	my ($code, $name) = @_;
	local $_ = $config{sentinel};
	$code->();
	is($_, $config{sentinel}, "$name leaves the caller's \$_ alone");
	return;
}

# Writes a file into a fresh directory and returns its path.
sub write_file {
	my ($name, $content, $dir) = @_;
	$dir ||= tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, $name);
	open my $handle, '>', $path or die "cannot write $path: $!";
	binmode $handle;
	print {$handle} $content;
	close $handle or die "cannot close $path: $!";
	return $path;
}

# ---------------------------------------------------------------------------
# App::Actions::Util
# ---------------------------------------------------------------------------

subtest 'App::Actions::Util' => sub {
	# The YAML loader is the front door for every workflow and action file,
	# so most of its tests feed it things that are not a usable mapping.
	subtest 'load_yaml_mapping' => sub {
		my $good = write_file('ci.yml', "name: CI\non: push\njobs:\n  b: {}\n  a: {}\n");
		my $data = load_yaml_mapping($good, 'workflow');
		returns_ok($data, { type => 'hashref' }, 'a mapping is returned as a hash reference');
		is_deeply([ keys %{ $data->{jobs} } ], [qw(b a)], 'job order is the order the user wrote');
		memory_cycle_ok($data, 'the loaded document holds no reference cycle');
		is_deeply(load_yaml_mapping(file => $good, kind => 'workflow'), $data,
			'named arguments mean the same as positional ones');

		throws_code(sub { load_yaml_mapping(undef, 'workflow') }, 'workflow.file_required',
			'No workflow file given', 'no file at all is refused');
		throws_code(sub { load_yaml_mapping('', 'action') }, 'action.file_required',
			'No action metadata file given', 'an empty name is refused, in the words of its kind');
		my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'nope.yml');
		throws_code(sub { load_yaml_mapping($missing, 'workflow') }, 'workflow.file_missing',
			"Workflow file '$missing' does not exist", 'a file that does not exist is refused');
		my $dir = tempdir(CLEANUP => 1);
		throws_code(sub { load_yaml_mapping($dir, 'workflow') }, 'workflow.file_missing',
			"Workflow file '$dir' does not exist", 'a directory is not a workflow file');

		my $empty = write_file('empty.yml', '');
		throws_code(sub { load_yaml_mapping($empty, 'workflow') }, 'workflow.empty',
			"Workflow '$empty' is empty", 'an empty document is refused');
		my $list = write_file('list.yml', "- a\n- b\n");
		throws_code(sub { load_yaml_mapping($list, 'action') }, 'action.not_mapping',
			"Action metadata '$list' must contain a YAML mapping", 'a list is not a mapping');
		my $scalar = write_file('scalar.yml', "just text\n");
		throws_code(sub { load_yaml_mapping($scalar, 'workflow') }, 'workflow.not_mapping',
			"Workflow '$scalar' must contain a YAML mapping", 'a plain string is not a mapping');
		my $broken = write_file('broken.yml', "jobs: [unclosed\n");
		my $error = throws_code(sub { load_yaml_mapping($broken, 'workflow') }, 'workflow.parse_failed',
			undef, 'a syntax error is reported as a parse failure');
		like($error->message, qr/\AUnable to parse workflow '\Q$broken\E': \S/, 'naming the file and the reason');

		# A failure inside the parser, rather than in the file, must still
		# come out as the module's own exception with the reason trimmed.
		{
			my $guard = mock_scoped('YAML::PP::load_file' => sub { die "  disk on fire  \n" });
			throws_code(sub { load_yaml_mapping($good, 'workflow') }, 'workflow.parse_failed',
				"Unable to parse workflow '$good': disk on fire", 'a parser that dies mid-flight is reported, trimmed');
		}

		throws_ok { load_yaml_mapping($good, 'playbook') }
			qr/\AInvalid arguments to App::Actions::Util::load_yaml_mapping: Parameter 'kind' \(playbook\) must be one of action, workflow/,
			'a kind other than workflow or action is a programming error';
		throws_ok { load_yaml_mapping($good) }
			qr/\AInvalid arguments to App::Actions::Util::load_yaml_mapping: /, 'the kind is required';
	};

	# mapping() turns an optional mapping into a fresh hash, and refuses
	# anything that is present but is not one.
	subtest 'mapping' => sub {
		my $original = { A => 1 };
		my $copy = mapping($original, 'env of the job');
		returns_ok($copy, { type => 'hashref' }, 'a hash reference comes back');
		is_deeply($copy, { A => 1 }, 'with the same entries');
		$copy->{B} = 2;
		ok(!exists $original->{B}, 'and it is a copy, so the caller\'s hash is not changed');
		is_deeply(mapping(undef, 'x'), {}, 'an absent mapping is an empty one');

		for my $bad ([ 'a string', 'FOO=bar' ], [ 'a list', [ 'FOO=bar' ] ], [ 'a code reference', sub { } ], [ 'zero', 0 ]) {
			my ($what, $value) = @{$bad};
			throws_code(sub { mapping($value, 'env of the job') }, 'mapping.invalid',
				'env of the job must be a mapping', "$what is refused");
		}
		throws_code(sub { mapping('x', [ 'where.step_env', { where => 'job build' } ]) }, 'mapping.invalid',
			'env of a step in job build must be a mapping', 'a catalogue place is rendered into the message');
	};

	# normalize_step() is the one check every step passes through before it
	# is run, so a malformed step must never get past it.
	subtest 'normalize_step' => sub {
		my $step = { run => 'make', env => { A => 1 } };
		my $normal = normalize_step($step, 'job test');
		is_deeply($normal, { run => 'make', env => { A => 1 }, with => {} }, 'env and with are always mappings');
		isnt($normal->{env}, $step->{env}, 'and are copies of the caller\'s');
		memory_cycle_ok($normal, 'the normalised step holds no reference cycle');
		is_deeply(normalize_step({ uses => 'actions/checkout@v4' }, 'x')->{with}, {}, 'a uses step is accepted');

		throws_code(sub { normalize_step('make test', 'job test') }, 'step.not_mapping',
			'A step in job test is not a mapping', 'a bare string step is refused');
		throws_code(sub { normalize_step(undef, 'job test') }, 'step.not_mapping',
			'A step in job test is not a mapping', 'an empty step is refused');
		throws_code(sub { normalize_step({ name => 'x' }, 'job test') }, 'step.no_command',
			"A step in job test has neither 'run' nor 'uses'", 'a step with nothing to do is refused');
		throws_code(sub { normalize_step({ run => { make => 'test' } }, 'job test') }, 'step.field_not_string',
			"Step field 'run' in job test must be a string", 'mis-indented YAML that nests a command is refused');
		for my $field (qw(uses shell working-directory name id if)) {
			throws_code(sub { normalize_step({ run => 'x', $field => [ 1 ] }, 'job test') }, 'step.field_not_string',
				"Step field '$field' in job test must be a string", "a list in $field is refused");
		}
		throws_code(sub { normalize_step({ run => 'x', with => 'a=b' }, 'job test') }, 'mapping.invalid',
			'with of a step in job test must be a mapping', 'with must be a mapping');
		throws_code(sub { normalize_step({ run => 'x', env => [] }, 'job test') }, 'mapping.invalid',
			'env of a step in job test must be a mapping', 'env must be a mapping');

		# The mapping check is delegated; a failure there must propagate
		# rather than be swallowed into a half-normalised step.
		{
			my $guard = mock_scoped('App::Actions::Util::mapping' => sub { die "mapping failed\n" });
			throws_ok { normalize_step({ run => 'x' }, 'job') } qr/\Amapping failed$/, 'a failure in mapping() propagates';
		}
	};

	subtest 'stringify' => sub {
		is(stringify(undef), '', 'undef is the empty string');
		is(stringify(0), '0', 'zero stays zero, not empty');
		is(stringify('text'), 'text', 'a string is unchanged');
		is(stringify(JSON::PP::true()), 'true', 'a JSON true is true');
		is(stringify(JSON::PP::false()), 'false', 'a JSON false is false, not empty');
		is(stringify({ b => 1, a => [ 1, 2 ] }), '{"a":[1,2],"b":1}', 'a structure is canonical JSON');
		my $cycle = {};
		$cycle->{self} = $cycle;
		dies_ok { stringify($cycle) } 'a self-referencing structure is refused rather than recursing for ever';
		returns_ok(stringify('x'), { type => 'string' }, 'the result is a string');
	};

	subtest 'trim' => sub {
		is(trim("  a b  \n"), 'a b', 'white space is removed from both ends only');
		is(trim(undef), '', 'undef is the empty string');
		is(trim("\t\n "), '', 'all white space is empty');
		my $text = '  keep  ';
		trim($text);
		is($text, '  keep  ', 'the caller\'s variable is not changed');

		# The two anchors are separate substitutions so that a long run of
		# inner white space is linear, not quadratic; a regression shows up
		# as a timeout here rather than as a wrong answer.
		my $hostile = 'a' . (' ' x $config{big}) . 'b' . (' ' x $config{big});
		my $started = time;
		is(length trim($hostile), $config{big} + 2, 'a long run of inner spaces is kept');
		cmp_ok(time - $started, '<=', $config{time_limit}, 'and trimming it takes linear time');
		keeps_topic(sub { trim(' x ') }, 'trim');
	};

	subtest '_place_text' => sub {
		is(App::Actions::Util::_place_text('job x'), 'job x', 'a string is used as it is');
		is(App::Actions::Util::_place_text(undef), '', 'nothing is the empty string');
		is(App::Actions::Util::_place_text([ 'where.step_env', { where => 'job a' } ]), 'env of a step in job a',
			'a catalogue key is rendered');
		is(App::Actions::Util::_place_text([ 'where.step_env', { where => [ 'where.step_with', { where => 'job a' } ] } ]),
			'env of a step in with of a step in job a', 'nested places are rendered from the inside out');

		# The rendering is the catalogue's job: the helper must hand it the
		# key and the rendered arguments, and return what it says.
		my @seen;
		my $guard = mock_scoped('App::Actions::I18N::message' => sub { shift; push @seen, [@_]; 'rendered' });
		is(App::Actions::Util::_place_text([ 'k.x', { a => 1 } ]), 'rendered', 'the catalogue\'s text is returned');
		is_deeply(\@seen, [ [ 'k.x', { a => 1 } ] ], 'and it was given the key and arguments');
		keeps_topic(sub { App::Actions::Util::_place_text([ 'k.x', { a => 1, b => 2 } ]) }, '_place_text');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Access
# ---------------------------------------------------------------------------

subtest 'App::Actions::Access' => sub {
	# private_names() decides which routines Sub::Private hides, so a wrong
	# answer either exposes a helper or breaks a public routine.
	subtest 'private_names' => sub {
		{
			package Local::Access::Owner;
			sub _mine { 1 }
			sub _also { 1 }
			sub public { 1 }
			sub __dunder { 1 }
			our $_scalar_only = 1;
		}
		{
			no warnings 'once';
			*Local::Access::Owner::_borrowed = \&App::Actions::Util::_place_text;
		}
		my $names = App::Actions::Access->private_names('Local::Access::Owner');
		returns_ok($names, { type => 'arrayref' }, 'an array reference comes back');
		is_deeply($names, [qw(_also _mine)], 'own underscore routines only, sorted, not imported or dunder ones');
		is_deeply(App::Actions::Access->private_names('Local::Access::Owner', '_mine'), ['_also'],
			'a name can be excepted');
		is_deeply(App::Actions::Access->private_names('Local::Access::Nothing'), [], 'an empty package has none');

		for my $bad (undef, '', 'not a package', 'Foo::', '::Foo', "Foo\nBar", 'Foo;system') {
			throws_ok { App::Actions::Access->private_names($bad) } qr/\AA package name is required at /,
				'refused: ' . (defined $bad ? "'$bad'" : 'undef');
		}
		keeps_topic(sub { App::Actions::Access->private_names('Local::Access::Owner') }, 'private_names');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Error
# ---------------------------------------------------------------------------

subtest 'App::Actions::Error' => sub {
	subtest 'new and the accessors' => sub {
		my $args = { file => 'ci.yml' };
		my $error = App::Actions::Error->new(code => 'workflow.empty', message => 'Workflow is empty', args => $args,
			location => " at x line 1.\n");
		isa_ok($error, 'App::Actions::Error');
		is($error->code, 'workflow.empty', 'code');
		is($error->message, 'Workflow is empty', 'message');
		is($error->location, " at x line 1.\n", 'location');
		is($error->text, "Workflow is empty at x line 1.\n", 'text is message and location');
		is("$error", $error->text, 'and is what the object stringifies to');
		is_deeply($error->args, $args, 'args');
		$error->args->{file} = 'changed';
		$args->{file} = 'changed too';
		is($error->args->{file}, 'ci.yml', 'args are copied in and out, so neither side can change them');
		memory_cycle_ok($error, 'the exception holds no reference cycle');
		is(App::Actions::Error->new(code => 'a.b', message => 'm')->location, "\n", 'no location is a bare newline');

		for my $bad ([ 'no code', message => 'm' ], [ 'no message', code => 'a.b' ],
			[ 'an undotted code', code => 'nodot', message => 'm' ], [ 'an upper-case code', code => 'A.B', message => 'm' ],
			[ 'a code with spaces', code => 'a.b c', message => 'm' ], [ 'args that are not a hash', code => 'a.b', message => 'm', args => [] ],
			[ 'an undef message', code => 'a.b', message => undef ], [ 'an undef code', code => undef, message => 'm' ],
			[ 'an unknown option', code => 'a.b', message => 'm', colour => 'red' ]) {
			my ($what, @arguments) = @{$bad};
			throws_ok { App::Actions::Error->new(@arguments) } qr/\AInvalid arguments to App::Actions::Error::new: /,
				"$what is refused";
		}
	};

	subtest 'is' => sub {
		my $error = App::Actions::Error->new(code => 'runner.image.pull_failed', message => 'm');
		is($error->is('runner.image.pull_failed'), 1, 'the full code matches');
		is($error->is('runner.image.'), 1, 'a family prefix ending in a dot matches');
		is($error->is('runner.'), 1, 'so does a wider family');
		is($error->is('runner.image'), 0, 'a prefix without the dot is a code, not a family');
		is($error->is('runner.ima'), 0, 'half a word is not a family');
		is($error->is('runner.image.pull_failed.'), 0, 'a longer family does not match');
		is($error->is('.*'), 0, 'the argument is text, not a pattern');
	};

	subtest 'caught' => sub {
		my $error = App::Actions::Error->new(code => 'a.b', message => 'm');
		is(App::Actions::Error->caught($error), $error, 'an exception of the class is returned');
		is(App::Actions::Error->caught("a.b at x line 1.\n"), undef, 'a string is not');
		is(App::Actions::Error->caught(undef), undef, 'nor is nothing');
		is(App::Actions::Error->caught(bless {}, 'Other::Error'), undef, 'nor an object of another class');
		is(App::Actions::Error->caught({ code => 'a.b' }), undef, 'nor an unblessed hash that looks like one');
	};

	subtest 'describe' => sub {
		my $error = App::Actions::Error->new(code => 'a.b', message => 'Image missing', location => " at lib/X.pm line 4.\n");
		is(App::Actions::Error->describe($error), 'Image missing', 'an exception is its message');
		is(App::Actions::Error->describe("boom at lib/X.pm line 12.\n"), 'boom', 'a die location is removed');
		is(App::Actions::Error->describe("boom at /path with spaces/X.pm line 12.\n"), 'boom', 'even a path with spaces');
		is(App::Actions::Error->describe("bad at character offset 9 at lib/X.pm line 1.\n"), 'bad at character offset 9',
			'an "at" inside the message is kept');
		is(App::Actions::Error->describe("plain message\n"), 'plain message', 'a message with no location is kept');
		is(App::Actions::Error->describe(undef), '', 'nothing is the empty string');
		is(App::Actions::Error->describe("line 3 is wrong\n"), 'line 3 is wrong', 'a message that mentions a line is kept');

		# The location patterns were rewritten to be linear; text built to
		# make the old one quadratic must still finish quickly.
		my $hostile = ('x at f line ' x ($config{big} / 10)) . "\n";
		my $started = time;
		ok(defined App::Actions::Error->describe($hostile), 'text full of " at f line " is described');
		cmp_ok(time - $started, '<=', $config{time_limit}, 'in linear time');
		keeps_topic(sub { App::Actions::Error->describe("boom at x line 1.\n") }, 'describe');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::I18N
# ---------------------------------------------------------------------------

subtest 'App::Actions::I18N' => sub {
	subtest 'new and language' => sub {
		is(App::Actions::I18N->new->language, 'en', 'English by default');
		is(App::Actions::I18N->new(language => 'fr')->language, 'fr', 'a language can be chosen');
		is(App::Actions::I18N->new(language => 'de_DE.UTF-8')->language, 'de', 'a locale name means its language');
		is(App::Actions::I18N->new(country => 'cn')->language, 'zh', 'a country chooses its language, in any case');
		is(App::Actions::I18N->new(language => 'fr', country => 'DE')->language, 'fr', 'the language wins over the country');
		{
			local $ENV{ACTION_RUN_LANG} = 'de';
			is(App::Actions::I18N->new->language, 'de', 'ACTION_RUN_LANG is used when nothing else says');
		}
		my $object = App::Actions::I18N->new;
		memory_cycle_ok($object, 'a translator holds no reference cycle');
		returns_ok($object, { type => 'object', isa => 'App::Actions::I18N' }, 'an object of the class');

		warning_like { is(App::Actions::I18N->new(language => 'tlh')->language, 'en', 'falls back to English') }
			qr/\ALanguage 'tlh' has no catalogue; using English at /, 'an unknown language is a warning, not a failure';
		for my $bad ([ language => '1x' ], [ language => '' ], [ country => 'GBR' ], [ country => '1' ], [ dialect => 'x' ]) {
			throws_ok { App::Actions::I18N->new(@{$bad}) } qr/\AInvalid arguments to App::Actions::I18N::new: /,
				"refused: $bad->[0] => '$bad->[1]'";
		}
	};

	subtest 'shared' => sub {
		my $first = App::Actions::I18N->shared;
		is(App::Actions::I18N->shared, $first, 'the same translator is reused');
		{
			local $ENV{ACTION_RUN_LANG} = 'fr';
			my $french = App::Actions::I18N->shared;
			isnt($french, $first, 'a change of language makes a new one');
			is($french->language, 'fr', 'in the new language');
		}
		is(App::Actions::I18N->shared->language, 'en', 'and changing back is seen too');
	};

	subtest 'languages, catalogue_keys and language_for_country' => sub {
		is_deeply(App::Actions::I18N->languages, [qw(de en fr zh)], 'the four catalogues');
		my $keys = App::Actions::I18N->catalogue_keys('en');
		returns_ok($keys, { type => 'arrayref' }, 'catalogue_keys returns an array reference');
		ok(scalar(grep { $_ eq 'workflow.empty' } @{$keys}), 'containing the English keys');
		is_deeply($keys, [ sort @{$keys} ], 'sorted');
		is_deeply(App::Actions::I18N->catalogue_keys('xx'), [], 'a language without a catalogue has no keys');
		throws_ok { App::Actions::I18N->catalogue_keys('EN') } qr/\AInvalid arguments to App::Actions::I18N::catalogue_keys: /,
			'a language code must be lower case';
		throws_ok { App::Actions::I18N->catalogue_keys } qr/\AInvalid arguments to /, 'and is required';
		is(App::Actions::I18N->language_for_country('fr'), 'fr', 'France speaks French');
		is(App::Actions::I18N->language_for_country('ZZ'), undef, 'an unknown country has no language');
		throws_ok { App::Actions::I18N->language_for_country('FRA') } qr/\AInvalid arguments to /,
			'a three-letter code is refused';
	};

	subtest 'message' => sub {
		my $english = App::Actions::I18N->new;
		is($english->message('workflow.empty', { file => 'ci.yml' }), "Workflow 'ci.yml' is empty", 'placeholders are filled');
		is($english->message(key => 'workflow.empty', args => { file => 'a' }), "Workflow 'a' is empty", 'named arguments work');
		isnt(App::Actions::I18N->new(language => 'de')->message('workflow.empty', { file => 'x' }), "Workflow 'x' is empty",
			'and German is not English');
		is($english->message('workflow.empty'), "Workflow '' is empty", 'a missing argument renders as empty, without a warning');
		is($english->message('workflow.empty', { file => '%(file)s' }), "Workflow '%(file)s' is empty",
			'a value that looks like a placeholder is not expanded again');

		# A key that is missing from a translation borrows the English text.
		App::Actions::I18N->add_messages('en', { 'test.english_only' => 'Only in %(where)s' });
		is(App::Actions::I18N->new(language => 'zh')->message('test.english_only', { where => 'English' }), 'Only in English',
			'so a translation without the key still says something useful');
		my $result;
		warning_like { $result = $english->message('no.such_key') } qr/\ANo message is defined for 'no.such_key' at /,
			'an unknown key warns';
		is($result, 'no.such_key', 'and comes back as the key itself');
		throws_ok { $english->message } qr/\AInvalid arguments to App::Actions::I18N::message: /, 'a key is required';
		throws_ok { $english->message('workflow.empty', 'file') } qr/\AInvalid arguments to /, 'args must be a hash';
	};

	subtest 'add_messages' => sub {
		my $translator = App::Actions::I18N->new;
		is($translator->add_messages('en', { 'test.only_here' => 'Only %(what)s' }), $translator, 'returns the object, to chain');
		is($translator->message('test.only_here', { what => 'here' }), 'Only here', 'the new entry is used');
		$translator->add_messages('en', { 'test.second' => 'Second' });
		is($translator->message('test.only_here', { what => 'still' }), 'Only still', 'entries are merged, not replaced');
		throws_ok { $translator->add_messages('EN', {}) } qr/\AInvalid arguments to /, 'the language code is checked';
		throws_ok { $translator->add_messages('en', []) } qr/\AInvalid arguments to /, 'entries must be a hash';
	};

	subtest 'i18n and throw' => sub {
		{
			package Local::I18N::User;
			sub new { return bless {}, shift }
		}
		my $object = Local::I18N::User->new;
		is(App::Actions::I18N::i18n($object, 'workflow.empty', { file => 'f' }), "Workflow 'f' is empty",
			'i18n renders with the shared translator');
		$object->{i18n} = App::Actions::I18N->new(language => 'fr');
		is(App::Actions::I18N::i18n($object, 'workflow.empty', { file => 'f' }),
			App::Actions::I18N->new(language => 'fr')->message('workflow.empty', { file => 'f' }),
			'or with the object\'s own translator');

		my $error = throws_code(sub { App::Actions::I18N::throw('Local::I18N::User', 'workflow.empty', { file => 'f' }) },
			'workflow.empty', "Workflow 'f' is empty", 'throw raises the message as an exception');
		is_deeply($error->args, { file => 'f' }, 'carrying its arguments');
		like($error->location, qr/\A at \S+ line \d+\.\n\z/, 'and a location');
		my $advice = caught { App::Actions::I18N::throw('Local::I18N::User', 'workflow.empty', { file => 'f', location => 0 }) };
		is($advice->location, "\n", 'location => 0 names no place');
		my $traced = caught { App::Actions::I18N::throw('Local::I18N::User', 'workflow.empty', { trace => 1 }) };
		like($traced->location, qr/called at/, 'trace => 1 carries the stack');
		my $undotted;
		warning_like { $undotted = caught { App::Actions::I18N::throw('X', 'not_dotted') } }
			qr/\ANo message is defined for 'not_dotted' at /, 'an unknown key warns before it is thrown';
		is(App::Actions::Error->caught($undotted), undef, 'and a key that is not a valid code cannot become an exception');
		like($undotted, qr/\AInvalid arguments to App::Actions::Error::new: /, 'it is refused as such');
	};

	subtest '_translator_for' => sub {
		my $own = App::Actions::I18N->new(language => 'de');
		is(App::Actions::I18N::_translator_for(bless { i18n => $own }, 'Local::X'), $own, 'a hash object\'s own translator');
		is(App::Actions::I18N::_translator_for('Some::Class'), App::Actions::I18N->shared, 'a class name shares the default');
		is(App::Actions::I18N::_translator_for(bless [], 'Local::Array'), App::Actions::I18N->shared, 'so does an array object');
		is(App::Actions::I18N::_translator_for(bless { i18n => 'fr' }, 'Local::X'), App::Actions::I18N->shared,
			'a translator that is not an object is ignored');
		is(App::Actions::I18N::_translator_for(bless { i18n => bless({}, 'Other') }, 'Local::X'), App::Actions::I18N->shared,
			'as is an object of another class');
	};

	subtest '_wanted_language' => sub {
		is(App::Actions::I18N::_wanted_language({}), 'en', 'nothing says English');
		is(App::Actions::I18N::_wanted_language({ language => 'FR-ca' }), 'fr', 'a tag is reduced to its language');
		is(App::Actions::I18N::_wanted_language({ country => 'ZZ', language => undef }), 'en',
			'a country with no language says nothing');
		is(App::Actions::I18N::_wanted_language({ language => '' }), 'en', 'an empty language says nothing');
		{
			local $App::Actions::I18N::config{language} = 'zh';
			is(App::Actions::I18N::_wanted_language({}), 'zh', 'the configuration is used');
			local $ENV{ACTION_RUN_LANG} = 'de';
			is(App::Actions::I18N::_wanted_language({}), 'zh', 'and wins over the environment');
		}
		keeps_topic(sub { App::Actions::I18N::_wanted_language({ language => 'fr' }) }, '_wanted_language');
	};

	subtest '_select and _plural_category' => sub {
		my $english = App::Actions::I18N->new;
		my $entry = { plural => { one => '%(count)d job', other => '%(count)d jobs' } };
		is($english->_select($entry, { count => 1 }), '%(count)d job', 'one');
		is($english->_select($entry, { count => 2 }), '%(count)d jobs', 'other');
		is($english->_select($entry, { count => 'many' }), '%(count)d jobs', 'a count that is not a number is zero');
		my $gendered = { gender => { female => 'elle', other => 'il' } };
		is($english->_select($gendered, { gender => 'FEMALE' }), 'elle', 'gender, in any case');
		is($english->_select($gendered, { gender => 'robot' }), 'il', 'an unknown gender is other');
		is($english->_select({ gender => { other => { plural => { one => 'a', other => 'b' } } } }, { count => 5 }), 'b',
			'gender then number');
		is($english->_select({ colour => 'red' }, {}), '', 'a malformed entry is empty, not a hash address');
		is($english->_select({ plural => { one => 'x' } }, { count => 3 }), '', 'a missing plural form is empty');
		is($english->_plural_category(1), 'one', 'English one');
		is($english->_plural_category(-1), 'one', 'minus one is one too');
		is($english->_plural_category(undef), 'other', 'no count is zero, which is other');
		is(App::Actions::I18N->new(language => 'zh')->_plural_category(1), 'other', 'Chinese has one form');
	};

	subtest '_render' => sub {
		is(App::Actions::I18N::_render('%(a)s and %(b)s', { a => 1, b => 2 }), '1 and 2', 'each placeholder is filled');
		is(App::Actions::I18N::_render('%(n)d', { n => 'abc' }), '0', 'a non-number in a numeric slot is zero');
		is(App::Actions::I18N::_render('%(n)05.1f', { n => 2 }), '002.0', 'a sprintf format is honoured');
		is(App::Actions::I18N::_render('%(a)s %(a)s', { a => 'x' }), 'x x', 'a repeated placeholder is filled twice');
		is(App::Actions::I18N::_render('100%', {}), '100%', 'a lone percent sign is left alone');
		my @warnings;
		{
			local $SIG{__WARN__} = sub { push @warnings, @_ };
			App::Actions::I18N::_render('%(missing)s %(gone)d', {});
		}
		is_deeply(\@warnings, [], 'missing values raise no warning');
		is(App::Actions::I18N::_render('%(a)s', { a => '%n%s%x' }), '%n%s%x', 'a value full of formats is not a format');
	};

	subtest 'validate_args' => sub {
		my $schema = { file => { type => 'string' }, kind => { type => 'string', optional => 1 } };
		is_deeply(validate_args('X::y', [ 'f', 'k' ], $schema, [qw(file kind)]), { file => 'f', kind => 'k' }, 'positional');
		is_deeply(validate_args('X::y', [ file => 'f', kind => 'k' ], $schema, [qw(file kind)]), { file => 'f', kind => 'k' },
			'named pairs to a routine with positional names');
		is_deeply(validate_args('X::y', [ { file => 'f' } ], $schema, [qw(file kind)]), { file => 'f' }, 'a hash reference');
		is_deeply(validate_args('X::y', [], { a => { type => 'string', optional => 1 } }), {}, 'no arguments is an empty hash');
		throws_ok { validate_args('X::y', [], $schema) }
			qr/\AInvalid arguments to X::y: /, 'a required argument that is missing is reported with the routine';
		throws_ok { validate_args('X::y', [ file => 'f', colour => 'red' ], $schema) }
			qr/\AInvalid arguments to X::y: .*colour/, 'an unknown argument is named';
		my $error = caught { validate_args('X::y', [ file => [] ], $schema) };
		unlike($error, qr/ at \S+ line \d+\. at /, 'the validator\'s own locations are cut from the reason');
	};

	subtest '_named_pairs' => sub {
		my $schema = { file => {}, kind => {} };
		is(App::Actions::I18N::_named_pairs([ file => 1, kind => 2 ], $schema), 1, 'pairs of known keys are named');
		is(App::Actions::I18N::_named_pairs([ file => 1, kind => ], $schema), 0, 'an odd count is not pairs');
		is(App::Actions::I18N::_named_pairs([ file => 1, colour => 2 ], $schema), 0, 'an unknown key is not');
		is(App::Actions::I18N::_named_pairs([ undef, 1, kind => 2 ], $schema), 0, 'an undef key is not');
		is(App::Actions::I18N::_named_pairs([ [ 'file' ], 1 ], $schema), 0, 'a reference key is not');
		keeps_topic(sub { App::Actions::I18N::_named_pairs([ file => 1 ], $schema) }, '_named_pairs');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Docker::Variable
# ---------------------------------------------------------------------------

use App::Actions::Docker::Variable;

subtest 'App::Actions::Docker::Variable' => sub {
	# The object exists to keep a secret off the command line, so the tests
	# check that it holds exactly what it was given and nothing else.
	subtest 'new, name and value' => sub {
		my $variable = App::Actions::Docker::Variable->new('TOKEN', 's3cret');
		isa_ok($variable, 'App::Actions::Docker::Variable');
		is($variable->name, 'TOKEN', 'name');
		is($variable->value, 's3cret', 'value');
		is("$variable", 'TOKEN=s3cret', 'it reads as NAME=VALUE');
		ok($variable eq 'TOKEN=s3cret', 'and compares as that string');
		is(App::Actions::Docker::Variable->new('X', undef)->value, '', 'undef is the empty string');
		is(App::Actions::Docker::Variable->new('X', 0)->value, '0', 'zero is kept, not emptied');
		is(App::Actions::Docker::Variable->new('X', "a=b\nc")->value, "a=b\nc", 'equals signs and newlines are kept');
		memory_cycle_ok($variable, 'a variable holds no reference cycle');

		my $value = 'original';
		my $copy = App::Actions::Docker::Variable->new('X', $value);
		$value = 'changed';
		is($copy->value, 'original', 'the value is copied, so changing the caller\'s variable does not change it');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Schema::Invalid
# ---------------------------------------------------------------------------

use App::Actions::Schema::Invalid;

subtest 'App::Actions::Schema::Invalid' => sub {
	subtest 'new' => sub {
		my $error = App::Actions::Schema::Invalid->new("check document: \$.x: missing\n");
		isa_ok($error, 'App::Actions::Error', 'it is an App::Actions::Error');
		is($error->code, 'schema.invalid', 'with the schema code');
		is("$error", "check document: \$.x: missing\n", 'and no source location: it is about a document');
		ok($error->is('schema.'), 'it belongs to the schema family');
		throws_ok { App::Actions::Schema::Invalid->new(undef) } qr/\AInvalid arguments to App::Actions::Schema::Invalid::new: /,
			'a message is required';
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Schema
# ---------------------------------------------------------------------------

use App::Actions::Schema qw(validate assert_valid describe_errors);

subtest 'App::Actions::Schema' => sub {
	# A small schema that uses every keyword the validator knows.
	my $schema = {
		type => 'object',
		required => [qw(schema_version name)],
		properties => {
			schema_version => { const => '1.0.0' },
			name => { type => 'string' },
			count => { type => 'integer' },
			ratio => { type => [qw(number null)] },
			state => { enum => [qw(ok failed)] },
			flag => { type => 'boolean' },
			items => { type => 'array', items => { type => 'string' } },
			either => { oneOf => [ { type => 'integer' }, { type => 'array' } ] },
		},
	};
	my %good = (schema_version => '1.0.0', name => 'n', count => 3, ratio => undef, state => 'ok',
		flag => JSON::PP::true(), items => [ 'a' ], either => [ 1 ]);

	subtest 'validate' => sub {
		is_deeply([ validate({ %good }, $schema) ], [], 'a good document has no errors');
		is_deeply([ validate({ %good, extra => 1 }, $schema) ], [ '$.extra: unexpected key' ], 'an unknown key is an error');
		is_deeply([ validate({ name => 'n' }, $schema) ], [ '$.schema_version: missing' ], 'a required key is missing');
		is_deeply([ validate({ %good, schema_version => '0.9.0' }, $schema) ], [ q{$.schema_version: expected '1.0.0', got '0.9.0'} ],
			'a stale version is reported with both values');
		is_deeply([ validate({ %good, count => '3.5' }, $schema) ], [ '$.count: expected integer, got 3.5' ], 'not an integer');
		is_deeply([ validate({ %good, count => "3\n" }, $schema) ], [ qq{\$.count: expected integer, got '3\n'} ],
			'a trailing newline is not an integer');
		is_deeply([ validate({ %good, state => 'maybe' }, $schema) ], [ q{$.state: 'maybe' is not one of 'ok', 'failed'} ],
			'a value outside the enum');
		is_deeply([ validate({ %good, flag => 1 }, $schema) ], [ '$.flag: expected boolean, got 1' ], 'a number is not a boolean');
		is_deeply([ validate({ %good, items => [ 'a', [] ] }, $schema) ], [ '$.items[1]: expected string, got ARRAY' ],
			'each item is checked, with its index');
		like(join('', validate({ %good, either => 'x' }, $schema)), qr/\A\$\.either: matches none of the alternative shapes \(first said: /,
			'oneOf with no match');
		is_deeply([ validate('text', { type => 'object' }) ], [ q{$: expected object, got 'text'} ], 'the root is $');
		is_deeply([ validate([], { type => 'object' }, 'doc') ], [ 'doc: expected object, got ARRAY' ], 'a path can be given');
		my @several = validate({ a => 1, b => 2 }, { type => 'object', properties => {} });
		is(scalar @several, 2, 'every error is reported, not only the first');
		is_deeply([ validate(undef, { type => 'string' }) ], [ '$: expected string, got null' ], 'null is not a string');

		# A document can be deeply nested; the validator must not be
		# confused by a hostile depth, only report it.
		# Perl warns about recursion deeper than 100 calls; that is expected here.
		local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /\ADeep recursion on subroutine "App::Actions::Schema::validate"/ };
		my $deep = 'leaf';
		$deep = { a => $deep } for 1 .. 200;
		my $nest = { type => 'string' };
		$nest = { type => 'object', properties => { a => $nest } } for 1 .. 200;
		is_deeply([ validate($deep, $nest) ], [], 'a deep document is walked to the leaf');

		keeps_topic(sub { validate({ %good }, $schema) }, 'validate');
	};

	subtest 'assert_valid' => sub {
		is(assert_valid({ %good }, $schema, 'doc'), 1, 'a good document passes');
		my $error = caught { assert_valid({ name => 1, extra => 1 }, $schema, 'check document') };
		ok(App::Actions::Schema::Invalid->caught($error), 'a bad one raises App::Actions::Schema::Invalid');
		is("$error", "check document: \$.extra: unexpected key (and 1 more)\n", 'naming the first error and how many more');

		# The error text comes from describe_errors(); a failure there must
		# not turn a broken document into a passing one.
		my $guard = mock_scoped('App::Actions::Schema::describe_errors' => sub { die "describe failed\n" });
		throws_ok { assert_valid({}, $schema, 'doc') } qr/\Adescribe failed$/, 'a failure while describing still fails';
	};

	subtest 'describe_errors' => sub {
		is(describe_errors([]), '', 'no errors is empty');
		is(describe_errors([ 'one' ]), 'one', 'one error is itself');
		is(describe_errors([qw(one two three)]), 'one (and 2 more)', 'more are counted');
	};

	subtest 'invalid_exit' => sub {
		is(App::Actions::Schema->invalid_exit, 70, 'EX_SOFTWARE, the status of a document that breaks its schema');
		isnt(App::Actions::Schema->invalid_exit, $_, "distinct from the run status $_") for 0 .. 2;
	};

	subtest '_is_type' => sub {
		my %cases = (
			null => [ [ undef ], [ 0, '' ] ],
			boolean => [ [ JSON::PP::true(), JSON::PP::false() ], [ 1, 0, 'true' ] ],
			array => [ [ [] ], [ {}, 'a' ] ],
			object => [ [ {} ], [ [], 'a' ] ],
			integer => [ [ 0, -3, '42' ], [ '1.0', '1e3', ' 1', "1\n", undef, [] ] ],
			number => [ [ 0, '-1.5', '.5', '1e-3', '3.' ], [ 'NaN', 'Inf', '1e', '', undef ] ],
			string => [ [ '', 'x', 0 ], [ undef, [], JSON::PP::true() ] ],
		);
		for my $type (sort keys %cases) {
			my ($yes, $no) = @{ $cases{$type} };
			is(App::Actions::Schema::_is_type($_, $type), 1, "$type accepts " . App::Actions::Schema::_show($_)) for @{$yes};
			is(App::Actions::Schema::_is_type($_, $type), 0, "$type refuses " . App::Actions::Schema::_show($_)) for @{$no};
		}
		is(App::Actions::Schema::_is_type('x', 'colour'), 0, 'an unknown type accepts nothing');
	};

	subtest '_same' => sub {
		is(App::Actions::Schema::_same(undef, undef), 1, 'two nulls');
		is(App::Actions::Schema::_same('1', 1), 1, 'scalars compare as strings');
		is(App::Actions::Schema::_same('1.0', 1), 0, 'so 1.0 is not 1');
		is(App::Actions::Schema::_same(undef, ''), 0, 'null is not empty');
		is(App::Actions::Schema::_same([], []), 0, 'structures are never the same');
		is(App::Actions::Schema::_same(JSON::PP::true(), JSON::PP::true()), 1, 'two trues are the same');
		is(App::Actions::Schema::_same(JSON::PP::false(), JSON::PP::false()), 1, 'two falses are the same');
		is(App::Actions::Schema::_same(JSON::PP::true(), JSON::PP::false()), 0, 'true is not false');
		is(App::Actions::Schema::_same(JSON::PP::true(), 1), 0, 'true is not the number 1');
		is(App::Actions::Schema::_same(JSON::PP::false(), undef), 0, 'false is not null');
		is_deeply([ validate(JSON::PP::true(), { enum => [ JSON::PP::true() ] }) ], [], 'so an enum of booleans works');
	};

	subtest '_show' => sub {
		is(App::Actions::Schema::_show(undef), 'null', 'null');
		is(App::Actions::Schema::_show(JSON::PP::false()), 'false', 'false');
		is(App::Actions::Schema::_show(12), '12', 'a number is bare');
		is(App::Actions::Schema::_show('12a'), q{'12a'}, 'a string is quoted');
		is(App::Actions::Schema::_show({}), 'HASH', 'a structure is named by its kind');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Process
# ---------------------------------------------------------------------------

use App::Actions::Process;

# Shell exit statuses the Process tests expect, by meaning.
Readonly::Hash my %STATUS => (
	ok => 0,
	failed => 3,		# what the test programs exit with when told to fail
	interrupted => 130,	# 128 + SIGINT
	not_started => 255,	# the program could not be run at all
	not_found => 127,	# a forked child that could not exec
);

# A command that runs this Perl, so the tests need nothing installed.
sub perl_command { return [ $^X, '-e', @_ ] }

subtest 'App::Actions::Process' => sub {
	subtest 'exit_code' => sub {
		is(App::Actions::Process::exit_code(0), $STATUS{ok}, 'success');
		is(App::Actions::Process::exit_code(undef), $STATUS{ok}, 'no status is success');
		is(App::Actions::Process::exit_code($STATUS{failed} << 8), $STATUS{failed}, 'an exit status');
		is(App::Actions::Process::exit_code(2), $STATUS{interrupted}, 'a signal is 128 plus its number');
		is(App::Actions::Process::exit_code(2 | 128), $STATUS{interrupted}, 'with or without a core dump');
		is(App::Actions::Process::exit_code(-1), $STATUS{not_started}, 'a program that could not start is 255');
		returns_ok(App::Actions::Process::exit_code(256), { type => 'integer', min => 0, max => 255 }, 'always a shell status');
	};

	subtest 'cpu_count' => sub {
		my $count = App::Actions::Process::cpu_count();
		returns_ok($count, { type => 'integer', min => 1 }, 'one processor or more');
		{
			local $^O = 'MSWin32';
			local $ENV{NUMBER_OF_PROCESSORS} = '12';
			is(App::Actions::Process::cpu_count(), 12, 'Windows says how many in the environment');
			for my $bad ('0', '-4', 'many', '4; rm -rf /', '') {
				local $ENV{NUMBER_OF_PROCESSORS} = $bad;
				my $fallback = App::Actions::Process::cpu_count();
				cmp_ok($fallback, '>=', 1, "a hostile NUMBER_OF_PROCESSORS ('$bad') is ignored");
			}
		}
	};

	subtest 'capture' => sub {
		# binmode, so a Windows child writes the CRLF itself rather than its
		# text layer turning the \n into a second one.
		my ($output, $status) = App::Actions::Process::capture(perl_command('binmode STDOUT; print qq{a\r\nb}; exit 3'));
		is($output, "a\nb", 'standard output is captured with CRLF made LF');
		is($status, $STATUS{failed}, 'with the status');
		($output) = App::Actions::Process::capture(perl_command('print STDERR q{noise}; print q{data}'), quiet_stderr => 1);
		is($output, 'data', 'quiet_stderr keeps standard error out');
		($output) = App::Actions::Process::capture(perl_command('$|=1; print q{1}; print STDERR q{2}; print q{3}'), merge_stderr => 1);
		is($output, '123', 'merge_stderr interleaves the two streams in order');
		($output, $status) = App::Actions::Process::capture([ File::Spec->catfile(tempdir(CLEANUP => 1), 'missing') ]);
		is_deeply([ $output, $status ], [ '', $STATUS{not_started} ], 'a missing program is no output and 255');

		# The command is a list, never a shell string: metacharacters are data.
		($output) = App::Actions::Process::capture(perl_command('print join q{|}, @ARGV', 'a;echo pwned', '$(id)', '`x`'));
		is($output, 'a;echo pwned|$(id)|`x`', 'shell metacharacters reach the program untouched');

		for my $bad (undef, [], 'echo hi', { 0 => 'echo' }) {
			throws_ok { App::Actions::Process::capture($bad) } qr/\ANo command given at /, 'refused: ' . explain($bad);
		}

		# A failure while the command runs must propagate, not hand back an
		# empty capture that looks like a silent success.
		{
			my $guard = mock_scoped('App::Actions::Process::run' => sub { die "spawn failed\n" });
			throws_ok { App::Actions::Process::capture(perl_command('1')) } qr/\Aspawn failed$/, 'a failure mid-flight propagates';
		}
		{
			local $/ = 'caller separator';
			App::Actions::Process::capture(perl_command('print 1'));
			is($/, 'caller separator', 'the input record separator is restored');
		}
	};

	subtest 'quote_win32' => sub {
		my %cases = (
			'plain' => 'plain',
			'' => '""',
			'two words' => '"two words"',
			'say "hi"' => '"say \\"hi\\""',
			'C:\\dir\\' => 'C:\\dir\\',
			'C:\\my dir\\' => '"C:\\my dir\\\\"',
			'a\\"b' => '"a\\\\\\"b"',
			"tab\there" => "\"tab\there\"",
		);
		for my $argument (sort keys %cases) {
			is(App::Actions::Process::quote_win32($argument), $cases{$argument}, "quoted: $argument");
		}
		is(App::Actions::Process::quote_win32(undef), '""', 'undef is an empty argument, kept');
		keeps_topic(sub { App::Actions::Process::quote_win32('a b') }, 'quote_win32');
	};

	subtest '_spawn_args' => sub {
		{
			# Set, not assumed: on Windows itself $^O is already MSWin32.
			local $^O = 'linux';
			is_deeply([ App::Actions::Process::_spawn_args([ 'prog', 'a b', '' ]) ], [ 'prog', 'a b', '' ],
				'elsewhere the arguments are passed as they are');
		}
		local $^O = 'MSWin32';
		is_deeply([ App::Actions::Process::_spawn_args([ 'prog', 'a b', '' ]) ], [ 'prog', '"a b"', '""' ],
			'on Windows they are quoted, the program name is not');
	};

	subtest '_windows_program_found' => sub {
		# Windows would retry a program it cannot start through cmd.exe, so
		# the program is looked for first, the way Windows looks: a bare name
		# in the current directory and on PATH with a PATHEXT extension, a
		# name with an extension as it is, a path where it says.
		my $dir = tempdir(CLEANUP => 1);
		write_file('tool.EXE', '', $dir);
		write_file('script.pl', '', $dir);
		mkdir File::Spec->catdir($dir, 'folder.EXE') or die $!;
		local $ENV{PATH} = $dir;
		local $ENV{PATHEXT} = '.EXE;.BAT';
		my $found = sub { App::Actions::Process::_windows_program_found($_[0]) };
		is($found->('tool'), 1, 'a bare name is found on PATH with a PATHEXT extension');
		is($found->('tool.EXE'), 1, 'a name with its own extension is found as it is');
		is($found->('script.pl'), 1, 'whatever that extension is');
		is($found->('script'), 0, 'but no extension outside PATHEXT is added');
		is($found->('tool.COM'), 0, 'an extension is never swapped for another');
		is($found->(File::Spec->catfile($dir, 'tool')), 1, 'a path is looked for where it says, with an extension added');
		is($found->(File::Spec->catfile(tempdir(CLEANUP => 1), 'tool')), 0, 'and only there, not on PATH');
		is($found->('folder'), 0, 'a directory is not a program');
		is($found->($_), 0, 'missing: ' . explain($_)) for undef, '', 'missing', 'tool & calc', 'tool | x';
		{
			local $ENV{PATHEXT} = '';
			is($found->('tool'), 1, 'an empty PATHEXT means the Windows default list');
		}
		{
			local $ENV{PATH} = '';
			is($found->('tool'), 0, 'nothing on PATH, nothing found');
		}
		returns_ok($found->('tool'), { type => 'integer', min => 0, max => 1 }, 'a plain yes or no');
		keeps_topic(sub { $found->('tool') }, '_windows_program_found');
	};

	subtest '_system on Windows' => sub {
		# A program that is not there is never handed to system(), so no
		# shell sees its arguments; the result is a program that could not
		# start, as everywhere else.
		local $^O = 'MSWin32';
		local $ENV{PATH} = tempdir(CLEANUP => 1);
		local ($!, $?);
		is(App::Actions::Process::_system([ 'missing', '& echo pwned' ]), -1, 'a missing program is -1');
		is($?, -1, 'with $? saying it did not start');
		is($! + 0, POSIX::ENOENT(), 'and $! saying why');
		is(App::Actions::Process::exit_code($?), $STATUS{not_started}, 'which is status 255');

		# Windows adds an extension to a path that has none, so Perl must be
		# named as perl.exe; where $^X has no extension, a link gives it one.
		my $perl = $^X;
		if ($perl !~ /\.exe\z/i) {
			$perl = File::Spec->catfile(tempdir(CLEANUP => 1), 'perl.EXE');
			symlink($^X, $perl) or return plan(skip_all => "no symbolic links: $!");
		}
		App::Actions::Process::_system([ $perl, '-eexit(3)' ]);
		is(App::Actions::Process::exit_code($?), $STATUS{failed}, 'a program given by its path still runs');
	};

	subtest '_system' => sub {
		App::Actions::Process::_system(perl_command('exit 3'));
		is(App::Actions::Process::exit_code($?), $STATUS{failed}, 'the child status is in $?');

		# The list form means a program name with a space is one program,
		# not a command and its arguments.
		my $dir = tempdir(CLEANUP => 1);
		local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /\ACan't exec / };
		App::Actions::Process::_system([ File::Spec->catfile($dir, 'no such') . ' program' ]);
		isnt($?, 0, 'a name with spaces is not split into a command');
	};

	subtest 'run_quiet' => sub {
		my $status;
		my $printed = do {
			open my $saved, '>&', \*STDOUT or die $!;
			my $file = File::Spec->catfile(tempdir(CLEANUP => 1), 'out');
			open STDOUT, '>', $file or die $!;
			$status = App::Actions::Process::run_quiet(perl_command('print q{loud}; print STDERR q{louder}; exit 3'));
			open STDOUT, '>&', $saved or die $!;
			-s $file;
		};
		is($status, $STATUS{failed}, 'the status is returned');
		ok(!$printed, 'and nothing reaches the caller\'s standard output');
		throws_ok { App::Actions::Process::run_quiet([]) } qr/\ANo command given at /, 'an empty command is refused';
	};

	subtest 'stream' => sub {
		{
			my $guard = mock_scoped('App::Actions::Process::_system' => sub { $? = $STATUS{failed} << 8; return });
			is(App::Actions::Process::stream([ 'anything' ]), $STATUS{failed}, 'the status of the child is returned');
		}
		{
			my $guard = mock_scoped('App::Actions::Process::_system' => sub { $? = 2; return });
			is(App::Actions::Process::stream([ 'anything' ]), $STATUS{interrupted}, 'an interrupt is 130');
		}
		throws_ok { App::Actions::Process::stream('ls -l') } qr/\ANo command given at /, 'a string is not a command';
	};

	subtest '_redirect_child' => sub {
		# The routine is for a forked child, so it is tested in one.
		my $dir = tempdir(CLEANUP => 1);
		my $out = File::Spec->catfile($dir, 'child.out');
		my $pid = fork();
		die "fork: $!" unless defined $pid;
		if (!$pid) {
			App::Actions::Process::_redirect_child(stdout => $out);
			print "redirected\n";
			close STDOUT;
			POSIX::_exit(0);
		}
		waitpid($pid, 0);
		is($?, 0, 'the child ran');
		open my $handle, '<', $out or die $!;
		is(scalar <$handle>, "redirected\n", 'its standard output went to the file');
		close $handle;

		my $bad = File::Spec->catfile($dir, 'no', 'such', 'dir', 'file');
		$pid = fork();
		die "fork: $!" unless defined $pid;
		if (!$pid) {
			open STDERR, '>', File::Spec->devnull;
			App::Actions::Process::_redirect_child(stdout => $bad);
			POSIX::_exit(0);
		}
		waitpid($pid, 0);
		is(App::Actions::Process::exit_code($?), $STATUS{not_found}, 'a file it cannot open ends the child with 127');
	};

	subtest 'run_parallel' => sub {
		my $codes = App::Actions::Process::run_parallel([ perl_command('exit 3'), perl_command('exit 0'), perl_command('exit 1') ],
			concurrency => 2);
		returns_ok($codes, { type => 'arrayref' }, 'an array reference');
		is_deeply($codes, [ 3, 0, 1 ], 'with each status in the slot of its command');
		is_deeply(App::Actions::Process::run_parallel([]), [], 'no commands, no statuses');
		is_deeply(App::Actions::Process::run_parallel([ perl_command('exit 3') ], concurrency => 1), [ 3 ], 'one at a time');

		my $dir = tempdir(CLEANUP => 1);
		my $err = File::Spec->catfile($dir, 'err');
		$codes = App::Actions::Process::run_parallel([ [ File::Spec->catfile($dir, 'missing') ], perl_command('exit 0') ],
			concurrency => 2, stderr => $err);
		is_deeply($codes, [ $STATUS{not_found}, 0 ], 'a program that cannot run is 127, and the others still run');
		open my $handle, '<', $err or die $!;
		like(do { local $/; <$handle> }, qr/\AUnable to run '\Q$dir\E/, 'and says why, where it was told to');
		close $handle;

		# Every program writes to the same file; each must add to it, not
		# replace what the others wrote, and what was there before is gone.
		my $shared = write_file('shared.out', "stale\n", $dir);
		for my $concurrency (1, 3) {
			App::Actions::Process::run_parallel([ map { perl_command("print qq{$_\\n}") } qw(one two three) ],
				concurrency => $concurrency, stdout => $shared);
			open my $in, '<', $shared or die $!;
			is_deeply([ sort <$in> ], [ "one\n", "three\n", "two\n" ], "concurrency $concurrency keeps every program's output");
			close $in;
		}
		throws_ok { App::Actions::Process::run_parallel([ perl_command('1') ], stdout => File::Spec->catfile($dir, 'no', 'dir')) }
			qr/\AUnable to open '/, 'a file that cannot be emptied is refused before anything runs';

		throws_ok { App::Actions::Process::run_parallel('echo') } qr/\ANo commands given at /, 'a string is refused';
		throws_ok { App::Actions::Process::run_parallel(undef) } qr/\ANo commands given at /, 'and so is nothing';

		# An exception while waiting (an interrupt, say) must kill the
		# children rather than leave them running behind the report.
		my $guard = mock_scoped('App::Actions::Process::exit_code' => sub { die "interrupted\n" });
		my $started = time;
		throws_ok {
			App::Actions::Process::run_parallel([ perl_command('exit 0'), perl_command('sleep 60') ], concurrency => 2);
		} qr/\Ainterrupted$/, 'the exception propagates';
		cmp_ok(time - $started, '<', 30, 'and the sleeping child was killed, not waited for');
	};

	subtest 'run' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $out = File::Spec->catfile($dir, 'out');
		my $err = File::Spec->catfile($dir, 'err');
		is(App::Actions::Process::run(perl_command('print q{o}; print STDERR q{e}; exit 3'), stdout => $out, stderr => $err),
			$STATUS{failed}, 'the status');
		open my $handle, '<', $out or die $!;
		is(do { local $/; <$handle> }, 'o', 'standard output went to its file');
		open $handle, '<', $err or die $!;
		is(do { local $/; <$handle> }, 'e', 'standard error to its own');
		close $handle;

		my @warnings;
		{
			local $SIG{__WARN__} = sub { push @warnings, @_ };
			is(App::Actions::Process::run([ File::Spec->catfile($dir, 'missing') ]), $STATUS{not_started}, 'a missing program is 255');
		}
		is_deeply(\@warnings, [], 'without Perl\'s "Can\'t exec" warning');

		my $unwritable = File::Spec->catfile($dir, 'no', 'such', 'dir');
		throws_ok { App::Actions::Process::run(perl_command('1'), stdout => $unwritable) }
			qr/\AUnable to redirect command output: /, 'an output file that cannot be opened is an error';
		ok(print(STDOUT ''), 'and standard output was put back after it');
		App::Actions::Process::run(perl_command('print q{more}'), stdout => $out, append => 1);
		open $handle, '<', $out or die $!;
		is(do { local $/; <$handle> }, 'omore', 'append adds to the file');
		close $handle;
		throws_ok { App::Actions::Process::run([], stdout => $out) } qr/\ANo command given at /, 'an empty command is refused';
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Docker
# ---------------------------------------------------------------------------

use App::Actions::Docker;

subtest 'App::Actions::Docker' => sub {
	# Every Docker test replaces the three Process entry points, so nothing
	# is run: each call is recorded with the environment it would have had,
	# and answers with what the test says the client printed.
	my (@calls, @answers);
	my $record = sub {
		my ($kind) = @_;
		return sub {
			my ($command, %options) = @_;
			push @calls, { kind => $kind, command => [ @{$command} ], token => $ENV{TOKEN}, options => {%options} };
			my $answer = @answers ? shift @answers : [ '', 0 ];
			return $kind eq 'capture' ? @{$answer} : $answer->[1];
		};
	};
	my $fake_process = sub {
		@calls = ();
		@answers = @_;
		return mock_scoped(
			'App::Actions::Process::capture' => $record->('capture'),
			'App::Actions::Process::stream' => $record->('stream'),
			'App::Actions::Process::run_quiet' => $record->('run_quiet'),
		);
	};
	my $docker = sub { App::Actions::Docker->new(bin => 'docker', @_) };

	# What a block printed to standard output.
	my $printed = sub {
		my ($code) = @_;
		my $text = '';
		open my $handle, '>', \$text or die $!;
		my $old = select $handle;
		$code->();
		select $old;
		close $handle;
		return $text;
	};

	subtest 'new and the accessors' => sub {
		my $object = App::Actions::Docker->new(bin => 'podman', dry_run => 'yes', explain => 0, verbose => 7, quiet => undef,
			platform => 'linux/arm64', secrets => { TOKEN => 's3cret', EMPTY => '', UNDEF => undef });
		is($object->bin, 'podman', 'bin');
		is($object->dry_run, 1, 'flags are made 0 or 1');
		is($object->explain, 0, 'explain');
		is($object->verbose, 1, 'verbose');
		is($object->quiet, 0, 'quiet');
		is_deeply([ $object->platform_args ], [ '--platform', 'linux/arm64' ], 'platform_args');
		is_deeply($object->{secret_values}, { s3cret => 1 }, 'empty and undefined secrets are never redacted, or everything would be');
		is_deeply($object->{secret_names}, { TOKEN => 1, EMPTY => 1, UNDEF => 1 }, 'but every name is known');
		memory_cycle_ok($object, 'a Docker object holds no reference cycle');
		{
			local $ENV{DOCKER} = 'from-env';
			is(App::Actions::Docker->new->bin, 'from-env', 'DOCKER chooses the client when bin does not');
			is(App::Actions::Docker->new(bin => 'given')->bin, 'given', 'and bin wins over it');
		}
		{
			delete local $ENV{DOCKER};
			is(App::Actions::Docker->new->bin, 'docker', 'the default is docker');
		}
		is_deeply([ App::Actions::Docker->new(platform => '')->platform_args ], [], 'an empty platform adds nothing');
	};

	subtest '_interpreter_prefix' => sub {
		my $dir = tempdir(CLEANUP => 1);
		is_deeply([ App::Actions::Docker::_interpreter_prefix(write_file('wrapper', "#!/usr/bin/env perl\nprint 1;\n", $dir)) ],
			[ $^X ], 'a Perl wrapper is run with this Perl');
		is_deeply([ App::Actions::Docker::_interpreter_prefix(write_file('w.pl', "print 1;\n", $dir)) ], [ $^X ], 'so is a .pl file');
		is_deeply([ App::Actions::Docker::_interpreter_prefix(write_file('sh', "#!/bin/sh\necho perl\n", $dir)) ], [],
			'a shell script that only mentions perl later is not Perl');
		is_deeply([ App::Actions::Docker::_interpreter_prefix(write_file('d.exe', "#!perl\n", $dir)) ], [], 'a Windows program is not');
		is_deeply([ App::Actions::Docker::_interpreter_prefix('docker') ], [], 'a name on the PATH is run directly');
		is_deeply([ App::Actions::Docker::_interpreter_prefix($dir) ], [], 'a directory is not a wrapper');
		is_deeply([ App::Actions::Docker::_interpreter_prefix(undef) ], [], 'nor is nothing');
		is_deeply([ App::Actions::Docker::_interpreter_prefix([]) ], [], 'nor a reference');
		# A large binary is not read whole to find its first line.
		my $big = write_file('big', ("\0" x $config{big}) . "#!perl\n", $dir);
		is_deeply([ App::Actions::Docker::_interpreter_prefix($big) ], [], 'a binary with "perl" deep inside is not Perl');
	};

	subtest '_command' => sub {
		my $object = $docker->();
		is_deeply([ $object->_command('ps', '-a') ], [ 'docker', 'ps', '-a' ], 'the client then the arguments');
		$object->{interpreter} = [ $^X ];
		is_deeply([ $object->_command('ps') ], [ $^X, 'docker', 'ps' ], 'with the interpreter first when there is one');
	};

	subtest 'check' => sub {
		{
			my $guard = $fake_process->([ "Docker version 27\n", 0 ], [ "27.0\n", 0 ]);
			is($docker->()->check, 1, 'a usable client and daemon pass');
			is_deeply([ map { $_->{command}[1] } @calls ], [ '--version', 'info' ], 'after asking for the version, then the daemon');
		}
		{
			my $guard = $fake_process->([ '', 127 ]);
			throws_ok { $docker->()->check } qr/\ADocker executable 'docker' was not found or is not usable at /,
				'a client that does not run is reported';
		}
		{
			my $guard = $fake_process->([ "v\n", 0 ], [ '', 1 ]);
			throws_ok { $docker->()->check } qr/\ACannot connect to the Docker daemon\. Is Docker running, and can this user access it\? at /,
				'a daemon that does not answer is reported';
		}
		{
			my $guard = $fake_process->();
			is($docker->(dry_run => 1)->check, 1, 'a dry run checks nothing');
			is(scalar @calls, 0, 'and runs nothing');
		}
	};

	subtest 'image_exists and image_size' => sub {
		{
			my $guard = $fake_process->([ "sha256:1\n", 0 ], [ '', 1 ]);
			is($docker->()->image_exists('a'), 1, 'an image that inspects is present');
			is($docker->()->image_exists('b'), 0, 'one that does not is absent');
		}
		{
			my $guard = $fake_process->([ " 12345 \r\n", 0 ], [ "1.5e3\n", 0 ], [ '', 1 ], [ "-5\n", 0 ]);
			is($docker->()->image_size('a'), 12345, 'the size in bytes, white space removed');
			is($docker->()->image_size('a'), undef, 'a size that is not a whole number is unknown');
			is($docker->()->image_size('a'), undef, 'so is the size of an image that is not there');
			is($docker->()->image_size('a'), undef, 'and a negative one');
		}
		my $guard = $fake_process->();
		is($docker->(dry_run => 1)->image_exists('x'), 1, 'a dry run has every image');
		is($docker->(dry_run => 1)->image_size('x'), undef, 'but knows no sizes');
		is(scalar @calls, 0, 'and asks nothing');
	};

	subtest 'pull and pull_many' => sub {
		{
			my $guard = $fake_process->([ '', 0 ], [ '', 1 ]);
			is($docker->(platform => 'linux/amd64')->pull('alpine'), 1, 'a pull that works');
			is_deeply($calls[0]{command}, [qw(docker pull --platform linux/amd64 alpine)], 'with the platform');
			throws_ok { $docker->()->pull('nope') } qr/\AFailed to pull Docker image 'nope' \(exit 1\)\n\z/,
				'a failed pull is advice, with no source location';
		}
		{
			my @commands;
			my $guard = mock_scoped('App::Actions::Process::run_parallel' => sub {
				my ($given, %options) = @_;
				@commands = ([ @{$given} ], {%options});
				return [ 0, 1 ];
			});
			my $results = $docker->()->pull_many([qw(a b)], concurrency => 2, quiet => 1);
			is_deeply($results, { a => 0, b => 1 }, 'each image gets its own status');
			is_deeply($commands[0], [ [qw(docker pull a)], [qw(docker pull b)] ], 'one pull command per image');
			is($commands[1]{concurrency}, 2, 'the concurrency is passed on');
			is($commands[1]{stdout}, File::Spec->devnull, 'quiet sends the output nowhere');
			$docker->()->pull_many([ 'a' ]);
			is($commands[1]{concurrency}, 4, 'four at a time by default');
			ok(!exists $commands[1]{stdout}, 'and the output is shown when not quiet');
		}
		my $guard = $fake_process->();
		my $text = $printed->(sub { is_deeply($docker->(dry_run => 1)->pull_many([qw(a)]), { a => 0 }, 'a dry run pulls nothing') });
		is($text, "[dry-run] docker pull a\n", 'and says what it would have run');
		is($printed->(sub { $docker->(dry_run => 1, explain => 1)->pull_many([qw(a)]) }), '', 'explain prints no commands');
		for my $bad (undef, [], 'alpine') {
			throws_ok { $docker->()->pull_many($bad) } qr/\ANo images given at /, 'refused: ' . explain($bad);
		}
	};

	subtest 'the thin wrappers' => sub {
		my $guard = $fake_process->(([ '', 0 ]) x 10);
		my $object = $docker->();
		$object->image_remove('img');
		$object->network_create('net');
		$object->network_remove('net');
		$object->container_start('--name', 'c', 'img');
		$object->container_exec('c', 'true');
		$object->container_logs('c');
		$object->container_logs('c', 5);
		$object->container_remove('c');
		is_deeply([ map { [ $_->{kind}, @{ $_->{command} }[ 1 .. $#{ $_->{command} } ] ] } @calls ], [
			[qw(run_quiet image rm -f img)],
			[qw(run_quiet network create net)],
			[qw(run_quiet network rm net)],
			[qw(run_quiet run -d --name c img)],
			[qw(stream exec c true)],
			[qw(stream logs --tail 200 c)],
			[qw(stream logs --tail 5 c)],
			[qw(run_quiet rm -f c)],
		], 'each runs the docker command it is named for, quietly or not');
	};

	subtest 'container_start_captured and container_log_text' => sub {
		my $guard = $fake_process->([ "id\n", 0 ], [ 'error', 125 ], [ "last lines\n", 0 ]);
		is_deeply([ $docker->()->container_start_captured('img') ], [ "id\n", 0 ], 'the output and status of the start');
		is_deeply([ $docker->()->container_start_captured('img') ], [ 'error', 125 ], 'a failed start says why');
		ok($calls[0]{options}{merge_stderr}, 'with standard error merged in');
		is($docker->()->container_log_text('c'), "last lines\n", 'the last lines of a log');
		is_deeply([ @{ $calls[2]{command} }[ 1 .. 4 ] ], [qw(logs --tail 10 c)], 'ten by default');
		is($docker->(dry_run => 1)->container_log_text('c'), '', 'a dry run has no logs');
	};

	subtest 'container state' => sub {
		{
			my $guard = $fake_process->([ "true\n", 0 ], [ "false\n", 0 ], [ "true\n", 1 ]);
			is($docker->()->container_running('c'), 1, 'running');
			is($docker->()->container_running('c'), 0, 'stopped');
			is($docker->()->container_running('c'), 0, 'an inspect that fails is not running, whatever it printed');
		}
		{
			my $guard = $fake_process->([ "3\n", 0 ], [ "-1\r\n", 0 ], [ "oops\n", 0 ], [ "3\n", 1 ]);
			is($docker->()->container_exit_code('c'), 3, 'an exit code');
			is($docker->()->container_exit_code('c'), -1, 'a negative one, as Docker reports some failures');
			is($docker->()->container_exit_code('c'), undef, 'text is not an exit code');
			is($docker->()->container_exit_code('c'), undef, 'nor is the answer of an inspect that failed');
		}
		{
			my $guard = $fake_process->([ "exited\n", 0 ], [ "\n", 0 ], [ "running", 1 ]);
			is($docker->()->container_status('c'), 'exited', 'a status');
			is($docker->()->container_status('c'), undef, 'an empty status is unknown');
			is($docker->()->container_status('c'), undef, 'so is one from an inspect that failed');
		}
		{
			my $guard = $fake_process->([ "2\n", 0 ], [ "-2\n", 0 ], [ "x\n", 0 ]);
			is($docker->()->container_restart_count('c'), 2, 'a restart count');
			is($docker->()->container_restart_count('c'), undef, 'a negative count is not one');
			is($docker->()->container_restart_count('c'), undef, 'nor is text');
		}
		my $guard = $fake_process->();
		my $dry = $docker->(dry_run => 1);
		is_deeply([ $dry->container_running('c'), $dry->container_exit_code('c'), $dry->container_status('c'),
			$dry->container_restart_count('c') ], [ 1, 0, 'running', 0 ], 'a dry run\'s containers run and exit cleanly');
		is(scalar @calls, 0, 'without asking the daemon');
	};

	subtest '_inspect_field' => sub {
		my $guard = $fake_process->([ " a b \r\n", 0 ], [ 'x', 1 ]);
		is($docker->()->_inspect_field('c', '{{.X}}'), 'ab', 'all white space is removed from a field');
		is_deeply([ @{ $calls[0]{command} }[ 1 .. 4 ] ], [ 'inspect', '--format', '{{.X}}', 'c' ], 'the format is passed as one argument');
		is($docker->()->_inspect_field('c', '{{.X}}'), undef, 'a failed inspect is undef');
	};

	subtest 'run, run_silent and _spawn' => sub {
		my $secret = App::Actions::Docker::Variable->new('TOKEN', 's3cret');
		{
			delete local $ENV{TOKEN};
			my $guard = $fake_process->([ '', 3 ], [ '', 0 ]);
			is($docker->()->run('run', '-e', $secret, 'img'), 3, 'run returns the status');
			is_deeply($calls[0]{command}, [qw(docker run -e TOKEN img)], 'a variable is passed by name only');
			is($calls[0]{token}, 's3cret', 'with its value in the client\'s environment while it runs');
			ok(!exists $ENV{TOKEN}, 'and gone again afterwards');
			is($docker->()->run_silent('ps'), 0, 'run_silent returns the status');
			is($calls[1]{kind}, 'run_quiet', 'and keeps the output quiet');
		}
		{
			local $ENV{TOKEN} = 'the caller\'s';
			my $guard = $fake_process->([ '', 0 ]);
			$docker->()->run('run', '-e', $secret, 'img');
			is($ENV{TOKEN}, 'the caller\'s', 'a variable of the caller\'s own is put back');
		}
		{
			my $guard = $fake_process->();
			my $text = $printed->(sub { is($docker->(dry_run => 1)->run('rm', 'x'), 0, 'a dry run succeeds') });
			is($text, "[dry-run] docker rm x\n", 'and only says what it would do');
			is(scalar @calls, 0, 'having run nothing');
		}
		# A failure inside the client must not leave the secret behind in
		# this process's environment.
		{
			delete local $ENV{TOKEN};
			my $guard = mock_scoped('App::Actions::Process::stream' => sub { die "client crashed\n" });
			throws_ok { $docker->()->run('run', '-e', $secret, 'img') } qr/\Aclient crashed$/, 'a crash propagates';
			ok(!exists $ENV{TOKEN}, 'and the secret is not left in the environment');
		}
	};

	subtest '_hide_variables' => sub {
		my $var = sub { App::Actions::Docker::Variable->new(@_) };
		my ($command, $hidden) = App::Actions::Docker::_hide_variables(undef, '-e', $var->('A', '1'), 'img');
		is_deeply([ $command, $hidden ], [ [ '-e', 'A', 'img' ], { A => '1' } ], 'a variable moves to the environment');

		for my $case (
			[ 'a client variable', 'DOCKER_HOST', 'tcp://evil:2375' ],
			[ 'PATH', 'PATH', '/tmp/evil' ],
			[ 'a proxy', 'https_proxy', 'http://evil' ],
			[ 'a name with a space', 'MY VAR', 'x' ],
			[ 'a name that starts with a dash', '-X', 'x' ],
			[ 'a name that starts with a digit', '1X', 'x' ],
			[ 'an empty name', '', 'x' ],
			[ 'a value with a NUL', 'OK', "a\0b" ],
		) {
			my ($what, $name, $value) = @{$case};
			($command, $hidden) = App::Actions::Docker::_hide_variables(undef, '-e', $var->($name, $value));
			is_deeply([ $command, $hidden ], [ [ '-e', "$name=$value" ], {} ], "$what stays on the command line");
		}
		# GitHub's INPUT_* names keep - and ., and an input is often a token.
		($command, $hidden) = App::Actions::Docker::_hide_variables(undef, '-e', $var->('INPUT_GITHUB-TOKEN', 's3cret'), '-e', $var->('A.B', 1));
		is_deeply([ $command, $hidden ], [ [ '-e', 'INPUT_GITHUB-TOKEN', '-e', 'A.B' ], { 'INPUT_GITHUB-TOKEN' => 's3cret', 'A.B' => 1 } ],
			'a name with - or . after its first character is hidden');
		($command, $hidden) = App::Actions::Docker::_hide_variables(undef, '-e', $var->('Path2', 'a'), '-e', $var->('PATH2', 'b'));
		is_deeply($hidden, {}, 'names that differ only in case both stay on the command line');
		($command) = App::Actions::Docker::_hide_variables(undef, 'NAME=value', 'plain');
		is_deeply($command, [ 'NAME=value', 'plain' ], 'a plain string is never moved');
		keeps_topic(sub { App::Actions::Docker::_hide_variables(undef, $var->('A', 1)) }, '_hide_variables');
	};

	subtest '_announce' => sub {
		my $guard = $fake_process->();
		is($printed->(sub { is($docker->()->_announce('ps'), 1, 'an ordinary call goes ahead') }), '', 'silently');
		is($printed->(sub { $docker->(verbose => 1)->_announce('ps', '-a') }), "+ docker ps -a\n", 'verbose echoes the command');
		is($printed->(sub { $docker->(verbose => 1, quiet => 1)->_announce('ps') }), '', 'quiet wins over verbose');
		is($printed->(sub { is($docker->(dry_run => 1)->_announce('ps'), 0, 'a dry run does not go ahead') }),
			"[dry-run] docker ps\n", 'and says so');
		is($printed->(sub { $docker->(dry_run => 1, quiet => 1)->_announce('ps') }), '', 'quietly when asked');
	};

	subtest 'capture, capture_silent, capture_merged and _capture' => sub {
		my $guard = $fake_process->(([ "out\n", 0 ]) x 3);
		is_deeply([ $docker->()->capture('ps') ], [ "out\n", 0 ], 'capture returns output and status');
		$docker->()->capture_silent('ps');
		$docker->()->capture_merged('ps');
		is_deeply([ map { [ $_->{options}{quiet_stderr}, $_->{options}{merge_stderr} ] } @calls ], [ [ 0, 0 ], [ 1, 0 ], [ 1, 1 ] ],
			'each asks for its own treatment of standard error');
		is_deeply([ $docker->(dry_run => 1, quiet => 1)->capture('ps') ], [ '', 0 ], 'a dry run captures nothing and succeeds');
		delete local $ENV{TOKEN};
		$docker->()->capture('run', '-e', App::Actions::Docker::Variable->new('TOKEN', 'v'));
		is($calls[-1]{token}, 'v', 'a captured command gets its variables in the environment too');
		ok(!exists $ENV{TOKEN}, 'only while it runs');
	};

	subtest 'redact' => sub {
		my $object = $docker->(secrets => { SHORT => 'abc', LONG => 'abcdef', META => 'a.c*' });
		is($object->redact('x abcdef y abc'), 'x *** y ***', 'the longest secret is replaced first');
		is($object->redact('aXc a.c*'), 'aXc ***', 'a secret is text, not a pattern');
		is($object->redact(undef), undef, 'undef stays undef');
		is($object->redact('nothing secret'), 'nothing secret', 'other text is unchanged');
		is($docker->()->redact('abc'), 'abc', 'with no secrets nothing is hidden');
		my $long = 'abc' x $config{big};
		my $started = time;
		is(length $object->redact($long), 3 * $config{big}, 'a long text full of secrets');
		cmp_ok(time - $started, '<=', $config{time_limit}, 'is redacted in linear time');
	};

	subtest '_display and _quote' => sub {
		my $object = $docker->(secrets => { TOKEN => 's3cret' });
		is($object->_display('run', '-e', 'TOKEN=anything', 'img'), q{run -e 'TOKEN=***' img}, 'a secret variable shows no value (quoted, since * is a glob)');
		is($object->_display('echo', 'my s3cret!'), q{echo 'my ***!'}, 'a secret anywhere is hidden');
		is($object->_display('-e', App::Actions::Docker::Variable->new('TOKEN', 'v')), q{-e 'TOKEN=***'},
			'a Variable object is hidden the same way');
		is($object->_display('a', undef, ''), q{a '' ''}, 'undef and empty show as empty quotes');
		my @args = ('TOKEN=x');
		$object->_display(@args);
		is($args[0], 'TOKEN=x', 'the caller\'s arguments are not changed');
		is(App::Actions::Docker::_quote('plain-word_1.2/x:y@z'), 'plain-word_1.2/x:y@z', 'a safe word is bare');
		is(App::Actions::Docker::_quote("it's"), q{'it'\''s'}, 'an embedded quote is closed, escaped and reopened');
		is(App::Actions::Docker::_quote('$(rm -rf /)'), q{'$(rm -rf /)'}, 'shell syntax is quoted');
		is(App::Actions::Docker::_quote("a\nb"), "'a\nb'", 'a newline is quoted');
		keeps_topic(sub { $object->_display('a', 'b') }, '_display');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Expression
# ---------------------------------------------------------------------------

use App::Actions::Expression;

subtest 'App::Actions::Expression' => sub {
	my $context = {
		matrix => { os => 'ubuntu-latest', perl => '5.38', list => [qw(a b)], flag => JSON::PP::false() },
		env => { Name => 'value', EMPTY => '' },
		github => { event_name => 'push' },
	};
	my $new = sub { App::Actions::Expression->new };
	my $value = sub { $new->()->evaluate(@_, $context) };

	subtest 'new' => sub {
		my $expression = $new->();
		isa_ok($expression, 'App::Actions::Expression');
		is_deeply([ @{$expression}{qw(context status)} ], [ {}, {} ], 'it starts with no context and no status');
		memory_cycle_ok($expression, 'an evaluator holds no reference cycle');
	};

	subtest 'evaluate' => sub {
		is($value->('matrix.os'), 'ubuntu-latest', 'a property path');
		is($value->(q{matrix['os']}), 'ubuntu-latest', 'an index by string');
		is($value->('env.name'), 'value', 'property names ignore case');
		is($value->('matrix.list[1]'), 'b', 'an array index');
		is($value->(q{'it''s'}), q{it's}, 'a doubled quote in a string');
		is($value->('1.5e1'), 15, 'a number with an exponent');
		is($value->('-1.5'), -1.5, 'a negative number, which GitHub allows');
		throws_ok { $value->('- 1') } qr/\AUnexpected character '-' in expression '- 1' at /, 'a sign must touch its number';
		is($value->(q{(1 == 1) && 'yes'}), 'yes', '&& returns its right operand');
		is($value->(q{'' || 'fallback'}), 'fallback', '|| returns the first truthy operand');
		ok(JSON::PP::is_bool($value->('1 == 1')), 'a comparison is a boolean');
		ok(JSON::PP::is_bool($value->('true')) && JSON::PP::is_bool($value->('!0')), 'so are true and !');
		is($value->('null'), undef, 'null');

		my $expression = $new->();
		is_deeply($expression->_evaluate('matrix.missing', $context), { value => undef, unresolved => 1 },
			'_evaluate reports a missing value as a miss');
		is_deeply($expression->_evaluate('env.EMPTY', $context), { value => '', unresolved => 0 },
			'an empty value that exists is not a miss');
		is($expression->_evaluate('matrix.list[5]', $context)->{unresolved}, 1, 'an index past the end is a miss');
		is($expression->_evaluate('matrix.list[-3]', $context)->{unresolved}, 1, 'and so is one before the start');

		# A lookup may run another evaluation on the same object (the runner's
		# env works out a variable when it is first read).  The inner one must
		# not disturb the outer parse, and neither may keep the context.
		{
			package Local::NestedContext;
			require Tie::Hash;
			our @ISA = ('Tie::StdHash');
			sub FETCH { my ($self, $key) = @_; return $key eq 'inner' ? $self->{evaluator}->evaluate(q{'a' == 'a'}, {}) : $self->{$key} }
		}
		my $evaluator = $new->();
		tie my %nested, 'Local::NestedContext';
		%nested = (evaluator => $evaluator, inner => 1);
		is($evaluator->evaluate(q{format('{0}-{1}', ctx.inner, 'outer') == 'true-outer'}, { ctx => \%nested }), JSON::PP::true(),
			'an evaluation inside a lookup leaves the outer one intact');
		untie %nested;
		is_deeply([ @{$evaluator}{qw(context status)} ], [ {}, {} ], 'and the object keeps no context afterwards');
		ok(!grep({ exists $evaluator->{$_} } qw(tokens pos unresolved)), 'nor any parse state');

		throws_ok { $new->()->evaluate(undef) } qr/\ACannot evaluate an undefined expression at /, 'undef is refused';
		throws_ok { $new->()->evaluate(" \t ") } qr/\ACannot evaluate an empty expression at /, 'blank is refused';
		throws_ok { $new->()->evaluate('1 2') } qr/\AUnexpected '2' in expression '1 2' at /, 'trailing tokens are refused';
		throws_ok { $new->()->evaluate('(1') } qr/\AExpected '\)' in expression at /, 'an unclosed parenthesis';
		throws_ok { $new->()->evaluate('1 ==') } qr/\AUnexpected end of expression at /, 'a missing operand';
		throws_ok { $new->()->evaluate(q{'open}) } qr/\AUnterminated string in expression ''open' at /, 'an unclosed string';
		throws_ok { $new->()->evaluate('a.(b)') } qr/\AExpected a property name after dot at /, 'a parenthesis after a dot';
		throws_ok { $new->()->evaluate('a.1') } qr/\AExpected a property name after dot at /, 'a number after a dot is not a property name';
		throws_ok { $new->()->evaluate('a; rm -rf /') } qr/\AUnexpected character ';' in expression /, 'shell syntax is not an expression';
		throws_ok { $new->()->evaluate('system("id")') } qr/\AUnexpected character '"' in expression /, 'nor is Perl';
		throws_ok { $new->()->evaluate('exec(1)') } qr/\AUnknown function 'exec\(\)' in expression at /, 'an unknown function is refused';

		# A huge expression must be tokenised in linear time; the tokenizer
		# was rewritten to avoid copying the rest of the text per token.
		my $long = join ' || ', ('false') x ($config{big} / 10);
		my $started = time;
		is($new->()->evaluate($long), 0, 'a long chain of || is evaluated');
		cmp_ok(time - $started, '<=', $config{time_limit}, 'in linear time');
	};

	subtest 'interpolate' => sub {
		my $expression = $new->();
		is($expression->interpolate('os=${{ matrix.os }}!', $context), 'os=ubuntu-latest!', 'an expression is replaced');
		is($expression->interpolate('${{ 1 == 2 }} ${{ 1 != 1 }} ${{ true }} ${{ 2 > 1 }}', $context), 'false false true true',
			'every boolean is written as true or false, as GitHub writes it');
		is($expression->interpolate('${{ matrix.flag }}', $context), 'false', 'including a boolean from the matrix');
		is($expression->interpolate('${{ matrix.list }}', $context), '["a","b"]', 'a structure is written as JSON');
		is($expression->interpolate('${{ matrix.missing }}', $context), '', 'a missing value is empty');
		is($expression->interpolate(q{${{ '${{ nested }}' }}x}, $context), '${{ nested }}x',
			'a result is not interpolated again, so a value cannot inject an expression');
		is($expression->interpolate(q<[${{ '}}' }}] [${{ 'it''s }}' }}]>, $context), q<[}}] [it's }}]>,
			'a }} inside a quoted string does not end the expression');
		my $unclosed_string = q<${{ 'open }}>;
		throws_ok { $expression->interpolate($unclosed_string, $context) } qr/\AUnclosed expression in /,
			'an unclosed string leaves the expression unclosed';
		my $many = '${{ \'}}\' }}' x ($config{big} / 10);
		my $started = time;
		is(length $expression->interpolate($many, $context), 2 * $config{big} / 10, 'many expressions with quoted braces');
		cmp_ok(time - $started, '<=', $config{time_limit}, 'are found in linear time');
		is($expression->interpolate(undef, $context), undef, 'undef passes through');
		my $reference = [];
		is($expression->interpolate($reference, $context), $reference, 'so does a reference');
		is($expression->interpolate('no expressions', $context), 'no expressions', 'plain text is unchanged');
		throws_ok { $expression->interpolate('${{ matrix.os', $context) } qr/\AUnclosed expression in '\$\{\{ matrix.os' at /,
			'an unclosed expression is refused';

		# A failure inside one expression must stop the interpolation rather
		# than leave a half-replaced string.
		my $guard = mock_scoped('App::Actions::Expression::_evaluate' => sub { die "evaluation failed\n" });
		throws_ok { $expression->interpolate('${{ x }}', $context) } qr/\Aevaluation failed$/, 'a failure mid-flight propagates';
	};

	subtest 'interpolate_strict' => sub {
		my $expression = $new->();
		is($expression->interpolate_strict('${{ env.EMPTY }}x', $context), 'x', 'an empty value that exists is fine');
		throws_ok { $expression->interpolate_strict('${{ matrix.nope }}', $context) }
			qr/\Aunable to resolve '\$\{\{ matrix\.nope \}\}' from the values available at /, 'a miss is an error';
		throws_ok { $expression->interpolate_strict('${{ matrix.list[9] }}', $context) }
			qr/\Aunable to resolve '\$\{\{ matrix\.list\[9\] \}\}'/, 'and so is an index past the end';
		ok(!$expression->{strict}, 'strict mode does not outlive the call, even after an error');
	};

	subtest 'interpolate_known' => sub {
		my $expression = $new->();
		is($expression->interpolate_known('${{ matrix.os }}/${{ secrets.TOKEN }}', $context), 'ubuntu-latest/${{ secrets.TOKEN }}',
			'what is known is replaced, what is not stays for later');
		is($expression->interpolate_known('${{ a }}${{ a }}', $context), '${{ a }}${{ a }}', 'repeated unknowns are all kept');
		throws_ok { $expression->interpolate_known('${{ x', $context) } qr/\AUnclosed expression in /, 'unclosed is refused';
	};

	subtest 'condition' => sub {
		my $expression = $new->();
		is($expression->condition(undef), 1, 'no condition is true');
		is($expression->condition('  '), 1, 'a blank one too');
		is($expression->condition('${{ matrix.os == \'ubuntu-latest\' }}', $context), 1, 'a wrapped condition');
		is($expression->condition("github.event_name == 'pull_request'", $context), 0, 'a bare one');
		is($expression->condition(JSON::PP::false()), 0, 'a YAML false is false');
		is($expression->condition(!!0), 0, "Perl's own false, as YAML::PP loads it from 5.36, is false");
		is($expression->condition(!!1), 1, 'and its true is true');
		is($expression->condition('matrix.flag', $context), 0, 'a false boolean value is false');
		is($expression->condition("'0'", $context), 0, 'the string 0 is false');
		is($expression->condition("'false'", $context), 1, 'the string false is true, as on GitHub');
		throws_ok { $expression->condition('(', $context) } qr/\AUnexpected end of expression at /, 'a broken condition is an error';
	};

	subtest '_tokenize' => sub {
		my $tokens = App::Actions::Expression::_tokenize(undef, q{a.b[0] >= 1.5 && !'x' || f(1,2)});
		is_deeply([ map { $_->{type} } @{$tokens} ],
			[qw(ident punct ident punct num punct op num op op str op ident punct num punct num punct eof)], 'every kind of token');
		is($tokens->[-1]{type}, 'eof', 'the list ends with eof');
		is_deeply(App::Actions::Expression::_tokenize(undef, 'my-var_2'), [ { type => 'ident', value => 'my-var_2' }, { type => 'eof', value => '' } ],
			'a dash is part of a name');
		throws_ok { App::Actions::Expression::_tokenize(undef, 'a = b') } qr/\AUnexpected character '=' in expression 'a = b' at /,
			'a single = is not an operator';
		throws_ok { App::Actions::Expression::_tokenize(undef, 'a & b') } qr/\AUnexpected character '&'/, 'nor is a single &';
		throws_ok { App::Actions::Expression::_tokenize(undef, "'unterminated ''") } qr/\AUnterminated string/,
			'a doubled quote at the end does not close the string';
	};

	subtest '_closing' => sub {
		is(App::Actions::Expression::_closing('a }} b }}', 0), 2, 'the first }}');
		is(App::Actions::Expression::_closing(q<'}}' }}>, 0), 5, 'not one inside a string');
		is(App::Actions::Expression::_closing(q<'a''b}}' }}>, 0), 9, 'nor inside a string with a doubled quote');
		is(App::Actions::Expression::_closing(q<'open }}>, 0), -1, 'an unclosed string has no end');
		is(App::Actions::Expression::_closing('none', 0), -1, 'no }} at all');
		is(App::Actions::Expression::_closing('}} x }}', 3), 5, 'the search starts where it is told');
	};

	subtest '_peek, _next, _peek_value and _expect' => sub {
		my $expression = $new->();
		$expression->{tokens} = App::Actions::Expression::_tokenize(undef, '( 1');
		$expression->{pos} = 0;
		is($expression->_peek_value, '(', '_peek_value looks without moving');
		is($expression->_expect('(')->{value}, '(', '_expect takes the token it wants');
		is($expression->_next->{value}, 1, '_next moves on');
		is($expression->_next->{type}, 'eof', 'and stops at eof');
		is($expression->_next->{type}, 'eof', 'however often it is called');
		throws_ok { $expression->_expect(')') } qr/\AExpected '\)' in expression at /, '_expect refuses another token';
	};

	subtest 'the parser' => sub {
		is($value->('1 || 0 && 0'), 1, '&& binds tighter than ||');
		is($value->('!!1'), 1, '! may be repeated');
		is($value->('!1 == 0'), 1, '! binds tighter than ==, so this is (!1) == 0');
		is($value->('2 > 1 == true'), 1, 'relational binds tighter than equality');
		is($value->(q{'B' == 'b'}), 1, 'string equality ignores case');
		is($value->(q{'10' == 10}), 1, 'a numeric string equals its number');
		is($value->(q{'abc' < 'abd'}), 1, 'strings compare as text');
		is($value->('false == 0'), 1, 'false compares as 0');
		is($value->('(((((1)))))'), 1, 'nested parentheses');
		throws_ok { $value->(')') } qr/\AUnexpected '\)' in expression at /, 'a stray parenthesis';
	};

	subtest '_postfix and _lookup' => sub {
		my $expression = $new->();
		is($expression->_lookup({ Key => 1 }, 'key'), 1, 'a key in another case is found');
		is($expression->_lookup([qw(a b)], -1), 'b', 'a negative index counts from the end');
		$expression->{unresolved} = 0;
		is($expression->_lookup([qw(a b)], 'x'), undef, 'a name is not an array index');
		is($expression->{unresolved}, 1, 'and is a miss');
		for my $case ([ 'undef object', undef, 'a' ], [ 'undef key', {}, undef ], [ 'a reference key', { a => 1 }, [] ],
			[ 'a scalar object', 'text', 'length' ], [ 'an index past the end', [ 1 ], 1 ]) {
			my ($what, $object, $key) = @{$case};
			$expression->{unresolved} = 0;
			is($expression->_lookup($object, $key), undef, "$what finds nothing");
			is($expression->{unresolved}, 1, "and $what is a miss");
		}
	};

	subtest '_missing' => sub {
		my $expression = $new->();
		is($expression->_missing, undef, 'nothing is found');
		is($expression->{unresolved}, 1, 'and the miss is recorded');
	};

	subtest '_call_function' => sub {
		my $expression = $new->();
		$expression->{status} = { success => 1 };
		is_deeply([ map { $expression->_call_function($_, []) . '' } qw(success failure always cancelled) ], [ 1, 0, 1, 0 ],
			'the status functions');
		is($expression->_call_function('CONTAINS', [ [qw(a B)], 'b' ]), 1, 'contains on an array, ignoring case');
		is($expression->_call_function('contains', [ 'Hello', 'ELL' ]), 1, 'contains on a string');
		is($expression->_call_function('startsWith', [ 'abc', 'AB' ]), 1, 'startsWith');
		is($expression->_call_function('endsWith', [ 'abc', 'abcd' ]), 0, 'endsWith a longer string is false');
		is($expression->_call_function('format', [ '{0}-{1}-{{2}}', 'a', 'b' ]), 'a-b-{2}', 'format with escaped braces');
		is($expression->_call_function('format', [ '{5}' ]), '', 'a missing format argument is empty');
		is($expression->_call_function('format', [ '{0}}}', 1 ]), '1}', 'the brace that closes {0} is not half of an escape');
		is($expression->_call_function('format', [ '{{0}}', 'x' ]), '{0}', 'an escaped placeholder is text');
		is($expression->_call_function('format', [ '{1}{0}', 'a', 'b' ]), 'ba', 'arguments in any order');
		is($expression->_call_function('join', [ [ 1, 2 ], ', ' ]), '1, 2', 'join');
		is($expression->_call_function('toJSON', [ { b => 1, a => 2 } ]), '{"a":2,"b":1}', 'toJSON is canonical');
		is_deeply($expression->_call_function('fromJSON', [ '{"a":[1]}' ]), { a => [ 1 ] }, 'fromJSON');

		my %bad = (
			contains => [ [ 1 ], qr/\Acontains\(\) expects two arguments at / ],
			startsWith => [ [ 1, 2, 3 ], qr/\AstartsWith\(\) expects two arguments at / ],
			format => [ [], qr/\Aformat\(\) expects at least one argument at / ],
			join => [ [ 'x', ',' ], qr/\Ajoin\(\) first argument must be an array at / ],
			toJSON => [ [], qr/\AtoJSON\(\) expects one argument at / ],
			fromJSON => [ [ '{bad' ], qr/\AfromJSON\(\) failed: / ],
			hashFiles => [ [ '**' ], qr/\AhashFiles\(\) is not supported by local action-run at / ],
			unknown => [ [], qr/\AUnknown function 'unknown\(\)' in expression at / ],
		);
		for my $name (sort keys %bad) {
			my ($args, $error) = @{ $bad{$name} };
			throws_ok { $expression->_call_function($name, $args) } $error, "$name refuses bad arguments";
		}
		my $before = [ '{0}', 'x' ];
		$expression->_call_function('format', $before);
		is_deeply($before, [ '{0}', 'x' ], 'format does not consume the caller\'s argument list');
	};

	subtest '_is_core_boolean' => sub {
		SKIP: {
			skip 'Perl has no booleans of its own before 5.36', 2 if $] < 5.036;
			is(App::Actions::Expression::_is_core_boolean($_), 1, 'a boolean: ' . ($_ ? 'true' : 'false')) for !!1, !!0;
		}
		is(App::Actions::Expression::_is_core_boolean($_), 0, "not a boolean: '$_'") for '', 0, 1, 'false';
	};

	subtest '_truthy' => sub {
		my @true = (1, 'false', ' ', [], {}, JSON::PP::true(), '0.0');
		my @false = (undef, '', 0, '0', JSON::PP::false());
		is(App::Actions::Expression::_truthy($_), 1, 'true: ' . explain($_)) for @true;
		is(App::Actions::Expression::_truthy($_), 0, 'false: ' . explain($_)) for @false;
	};

	subtest '_equal, _compare and _is_number' => sub {
		is(App::Actions::Expression::_equal(1, '1.0'), 1, 'numbers compare by value');
		is(App::Actions::Expression::_equal(JSON::PP::true(), 1), 1, 'true is 1');
		is(App::Actions::Expression::_equal(undef, ''), 1, 'null and empty are equal as text');
		is(App::Actions::Expression::_compare('a', 'B'), -1, 'text ignores case');
		is(App::Actions::Expression::_compare(10, 9), 1, 'numbers are not compared as text');
		is(App::Actions::Expression::_is_number('1e3'), 1, 'an exponent is a number');
		is(App::Actions::Expression::_is_number(''), 0, 'empty is not');
		is(App::Actions::Expression::_is_number([]), 0, 'a reference is not');
		is(App::Actions::Expression::_is_number(JSON::PP::false()), 1, 'a boolean is');
		is(App::Actions::Expression::_is_number(undef), 0, 'null is not');
	};

	subtest '_stringify and _boolean' => sub {
		my @seen;
		my $guard = mock_scoped('App::Actions::Util::stringify' => sub { push @seen, $_[0]; 'S' });
		is(App::Actions::Expression::_stringify('x'), 'S', '_stringify is Util::stringify');
		is_deeply(\@seen, [ 'x' ], 'given the value');
		undef $guard;
		ok(JSON::PP::is_bool(App::Actions::Expression::_boolean('yes')), '_boolean makes a boolean');
		is(App::Actions::Expression::_boolean('yes') . '', '1', 'true counts as 1');
		is(App::Actions::Expression::_boolean('') . '', '0', 'false counts as 0');
		is(App::Actions::Util::stringify(App::Actions::Expression::_boolean(0)), 'false', 'and is written false');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Action
# ---------------------------------------------------------------------------

use App::Actions::Action;

subtest 'App::Actions::Action' => sub {
	# Writes action.yml (or another name) into a fresh directory.
	my $action_dir = sub {
		my ($yaml, $name) = @_;
		my $dir = tempdir(CLEANUP => 1);
		write_file($name || 'action.yml', $yaml, $dir);
		return $dir;
	};
	my $composite = <<'YAML';
name: Setup
description: Sets things up
inputs:
  who:
    description: Who to greet
    required: true
    default: world
  shorthand: hello
  bare:
outputs:
  greeting:
    description: The greeting
    value: ${{ steps.say.outputs.text }}
runs:
  using: Composite
  steps:
    - run: echo hi
      shell: bash
YAML

	subtest 'load_from_dir' => sub {
		my $dir = $action_dir->($composite);
		my $action = App::Actions::Action->load_from_dir($dir);
		isa_ok($action, 'App::Actions::Action');
		is($action->file, File::Spec->catfile($dir, 'action.yml'), 'action.yml is found');
		memory_cycle_ok($action, 'an action holds no reference cycle');

		my $both = $action_dir->("runs:\n  using: node20\n  main: a.js\n");
		write_file('action.yaml', "runs:\n  using: composite\n  steps: []\n", $both);
		is(App::Actions::Action->load_from_dir($both)->kind, 'javascript', 'action.yml wins over action.yaml');
		is(App::Actions::Action->load_from_dir($action_dir->("runs:\n  using: docker\n", 'action.yaml'))->kind, 'docker',
			'action.yaml is found on its own');

		throws_code(sub { App::Actions::Action->load_from_dir(undef) }, 'action.dir_required', 'No action directory given',
			'no directory is refused');
		throws_code(sub { App::Actions::Action->load_from_dir('') }, 'action.dir_required', undef, 'nor an empty one');
		my $missing = File::Spec->catdir(tempdir(CLEANUP => 1), 'gone');
		throws_code(sub { App::Actions::Action->load_from_dir($missing) }, 'action.dir_missing',
			"Action directory '$missing' does not exist", 'a directory that does not exist');
		my $empty = tempdir(CLEANUP => 1);
		throws_code(sub { App::Actions::Action->load_from_dir($empty) }, 'action.no_metadata',
			"No action.yml or action.yaml found in '$empty'", 'a directory with no metadata');
		throws_code(sub { App::Actions::Action->load_from_dir(write_file('file', 'x')) }, 'action.dir_missing', undef,
			'a file is not a directory');
		my $named = $action_dir->("runs: {using: docker}\n", 'Action.YML');
		throws_code(sub { App::Actions::Action->load_from_dir($named) }, 'action.no_metadata', undef,
			'the name must be exactly action.yml or action.yaml')
			if !-f File::Spec->catfile($named, 'action.yml');
	};

	subtest 'load and the accessors' => sub {
		my $dir = $action_dir->($composite);
		my $action = App::Actions::Action->load(File::Spec->catfile($dir, 'action.yml'));
		is($action->dir, $dir, 'dir is the directory of the file');
		is($action->name, 'Setup', 'name');
		is($action->description, 'Sets things up', 'description');
		is($action->using, 'composite', 'using is lower case');
		is($action->kind, 'composite', 'kind');
		is($action->is_composite, 1, 'is_composite');
		is($action->is_javascript, 0, 'is_javascript');
		is_deeply($action->inputs, {
			who => { description => 'Who to greet', default => 'world', required => 1 },
			shorthand => { default => 'hello', required => 0 },
			bare => { default => '', required => 0 },
		}, 'inputs are normalised, shorthand included');
		is_deeply($action->outputs, { greeting => { description => 'The greeting', value => '${{ steps.say.outputs.text }}' } },
			'outputs are normalised');
		is_deeply($action->steps, [ { run => 'echo hi', shell => 'bash', env => {}, with => {} } ], 'steps are normalised');
		is($action->runs->{using}, 'Composite', 'runs is the mapping as written');
		$action->runs->{using} = 'changed';
		is($action->using, 'composite', 'and changing it does not change the kind');
		is(App::Actions::Action->load(write_file('action.yml', "runs: {using: node16, main: x.js}\n"))->is_javascript, 1,
			'any nodeNN runtime is JavaScript');
		is(App::Actions::Action->load(write_file('action.yml', "runs: {using: future-thing}\n"))->kind, 'future-thing',
			'an unknown runtime is recorded as given, for the runner to decide');

		my %bad = (
			"name: x\n" => [ 'action.no_runs', "has no 'runs' mapping" ],
			"runs: text\n" => [ 'action.no_runs', "has no 'runs' mapping" ],
			"runs: {main: x}\n" => [ 'action.no_using', "has no 'runs.using'" ],
			"runs: {using: ''}\n" => [ 'action.no_using', "has no 'runs.using'" ],
			"runs: {using: composite}\n" => [ 'action.no_steps', "has no 'runs.steps' list" ],
			"runs: {using: composite, steps: {a: 1}}\n" => [ 'action.no_steps', "has no 'runs.steps' list" ],
			"runs: {using: node20}\n" => [ 'action.no_main', "has no 'runs.main'" ],
			"runs: {using: node20, main: [a.js]}\n" => [ 'action.no_main', "has no 'runs.main'" ],
			"runs: {using: node20, main: ''}\n" => [ 'action.no_main', "has no 'runs.main'" ],
			"inputs: [a]\nruns: {using: docker}\n" => [ 'action.inputs_invalid', "The 'inputs' of " ],
			"inputs: {a: [1]}\nruns: {using: docker}\n" => [ 'action.input_invalid', "Input 'a' of " ],
			"outputs: text\nruns: {using: docker}\n" => [ 'action.outputs_invalid', "The 'outputs' of " ],
			"runs: {using: composite, steps: [text]}\n" => [ 'step.not_mapping', 'is not a mapping' ],
		);
		for my $yaml (sort keys %bad) {
			my ($code, $text) = @{ $bad{$yaml} };
			my $file = write_file('action.yml', $yaml);
			my $error = throws_code(sub { App::Actions::Action->load($file) }, $code, undef, "refused: $yaml");
			like($error && $error->message, qr/\Q$text\E/, '  with the reason');
		}
		throws_code(sub { App::Actions::Action->load(undef) }, 'action.file_required', undef, 'no file is refused');
	};

	subtest '_kind_and_steps' => sub {
		is_deeply([ App::Actions::Action->_kind_and_steps('docker', {}, 'f') ], [ 'docker', [] ], 'docker');
		is_deeply([ App::Actions::Action->_kind_and_steps('node24', { main => 'x' }, 'f') ], [ 'javascript', [] ], 'node24');
		is_deeply([ App::Actions::Action->_kind_and_steps('nodejs', {}, 'f') ], [ 'nodejs', [] ], 'nodejs is not a node runtime');
		# The step check is normalize_step's job; its failure must surface.
		my $guard = mock_scoped('App::Actions::Action::normalize_step' => sub { die "bad step\n" });
		throws_ok { App::Actions::Action->_kind_and_steps('composite', { steps => [ {} ] }, 'f') } qr/\Abad step$/,
			'a failure in normalize_step propagates';
	};

	subtest '_declarations' => sub {
		is_deeply(App::Actions::Action->_declarations('inputs', undef, 'f'), {}, 'nothing declared is empty');
		is_deeply(App::Actions::Action->_declarations('outputs', { o => 'v' }, 'f'), { o => { value => 'v' } },
			'a shorthand output has no required flag');
		is_deeply(App::Actions::Action->_declarations('inputs', { n => { default => 3 } }, 'f'),
			{ n => { description => undef, default => '3', required => 0 } }, 'a default is a string');
		is_deeply(App::Actions::Action->_declarations('inputs', { b => { default => JSON::PP::false() } }, 'f')->{b}{default}, 'false',
			'a boolean default is written as GitHub writes it');
		throws_code(sub { App::Actions::Action->_declarations('outputs', { o => [] }, 'f') }, 'action.output_invalid',
			"Output 'o' of 'f' must be a mapping", 'a list is not a declaration');
	};

	subtest '_boolean' => sub {
		is(App::Actions::Action::_boolean($_), 1, "true: $_") for qw(true TRUE yes Yes 1);
		is(App::Actions::Action::_boolean(JSON::PP::true()), 1, 'a YAML true');
		is(App::Actions::Action::_boolean(JSON::PP::false()), 0, 'a YAML false');
		for my $false (undef, '', 'false', 'no', '0', 2, 'truely', ' true', "true\n", "yes\nno") {
			is(App::Actions::Action::_boolean($false), 0, 'false: ' . explain($false));
		}
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Workflow
# ---------------------------------------------------------------------------

use App::Actions::Workflow;

subtest 'App::Actions::Workflow' => sub {
	my $yaml = <<'YAML';
name: CI
env:
  GLOBAL: 1
defaults:
  run:
    shell: bash
jobs:
  build:
    runs-on: ubuntu-22.04
    container: perl:5.38
    steps:
      - run: make
  test:
    name: Test ${{ matrix.perl }}
    needs: build
    runs-on: [self-hosted, linux]
    strategy:
      matrix:
        perl: ['5.36', '5.38']
        os: [ubuntu-latest]
    steps:
      - uses: shogo82148/actions-setup-perl@v1
        with:
          perl-version: ${{ matrix.perl }}
      - run: prove
YAML
	my $file = write_file('ci.yml', $yaml);
	my $workflow = App::Actions::Workflow->load($file);
	my $job = sub { $workflow->job_by_id($_[0]) };

	subtest 'load and the accessors' => sub {
		isa_ok($workflow, 'App::Actions::Workflow');
		is($workflow->file, $file, 'file');
		is($workflow->name, 'CI', 'name');
		is_deeply($workflow->env, { GLOBAL => 1 }, 'env');
		is_deeply($workflow->defaults, { run => { shell => 'bash' } }, 'defaults');
		is_deeply([ map { $_->{id} } @{ $workflow->jobs } ], [qw(build test)], 'jobs, in the order written');
		is_deeply([ sort keys %{ $workflow->raw } ], [qw(defaults env jobs name)], 'raw is the document');
		memory_cycle_ok($workflow, 'a workflow holds no reference cycle');
		is(App::Actions::Workflow->load(write_file('unnamed.yml', "jobs:\n  a:\n    steps: [{run: x}]\n"))->name, 'unnamed.yml',
			'a workflow without a name is called by its file name');

		my %bad = (
			"name: x\n" => [ 'workflow.no_jobs', "has no 'jobs' mapping" ],
			"jobs: [a]\n" => [ 'workflow.no_jobs', "has no 'jobs' mapping" ],
			"jobs:\n  a: text\n" => [ 'workflow.job_not_mapping', "Job 'a' must be a mapping" ],
			"jobs:\n  a: {runs-on: x}\n" => [ 'workflow.job_no_steps', "Job 'a' has no 'steps' list" ],
			"jobs:\n  a: {steps: [{run: x}], container: [x]}\n" => [ 'workflow.container_invalid', "Job 'a' container must be a mapping or a string" ],
			"jobs:\n  a: {steps: [{run: x}], services: [db]}\n" => [ 'workflow.services_invalid', "Job 'a' services must be a mapping" ],
			"env: [A]\njobs:\n  a: {steps: [{run: x}]}\n" => [ 'mapping.invalid', 'workflow env must be a mapping' ],
			"defaults: {run: bash}\njobs:\n  a: {steps: [{run: x}]}\n" => [ 'workflow.defaults_run_invalid', 'workflow defaults run must be a mapping' ],
			"jobs:\n  a: {steps: [{run: x}], strategy: fast}\n" => [ 'mapping.invalid', "strategy of job 'a' must be a mapping" ],
			"jobs:\n  a: {steps: [{name: x}]}\n" => [ 'step.no_command', "job 'a' has neither" ],
		);
		for my $text (sort keys %bad) {
			my ($code, $words) = @{ $bad{$text} };
			my $error = throws_code(sub { App::Actions::Workflow->load(write_file('bad.yml', $text)) }, $code, undef, "refused: $text");
			like($error && $error->message, qr/\Q$words\E/, '  with the reason');
		}
		throws_code(sub { App::Actions::Workflow->load(undef) }, 'workflow.file_required', undef, 'no file is refused');
	};

	subtest 'job_by_id' => sub {
		is($job->('build')->{id}, 'build', 'a job is found by its key');
		is_deeply([ $workflow->job_by_id('nope') ], [ undef ], 'an unknown job is undef, also in list context');
		throws_ok { $workflow->job_by_id(undef) } qr/\AInvalid arguments to App::Actions::Workflow::job_by_id: /, 'undef is refused';
		throws_ok { $workflow->job_by_id([ 'build' ]) } qr/\AInvalid arguments to /, 'a list is refused';
	};

	subtest 'expand_jobs' => sub {
		my $instances = $workflow->expand_jobs;
		is(scalar @{$instances}, 3, 'one build, two test instances');
		my @test = grep { $_->{base_id} eq 'test' } @{$instances};
		is_deeply([ map { $_->{display_name} } @test ], [ 'Test 5.36', 'Test 5.38' ], 'the name is interpolated per instance');
		is_deeply([ map { $_->{setup_perl_version} } @test ], [qw(5.36 5.38)], 'and so is the setup-perl version');
		is_deeply([ map { "$_->{matrix_index}/$_->{matrix_total}" } @test ], [ '0/2', '1/2' ], 'with its place in the matrix');
		$test[0]{steps}[0]{with}{'perl-version'} = 'changed';
		is($workflow->job_by_id('test')->{steps}[0]{with}{'perl-version'}, '${{ matrix.perl }}',
			'an instance cannot change the job it came from') or diag('instances share the job\'s steps');
		memory_cycle_ok($instances, 'the instances hold no reference cycle');
	};

	subtest 'runs_on_text' => sub {
		is($workflow->runs_on_text('ubuntu-${{ matrix.v }}', { v => '24.04' }), 'ubuntu-24.04', 'interpolated with the matrix');
		is($workflow->runs_on_text([ 'self-hosted', 'linux' ]), 'self-hosted linux', 'a list is joined');
		is($workflow->runs_on_text(undef), '', 'none is empty');
		throws_code(sub { $workflow->runs_on_text({ group => 'big' }) }, 'workflow.runs_on_invalid',
			q{'runs-on' must be a string or a list}, 'a runner group is refused');
		throws_ok { $workflow->runs_on_text('x', 'not a hash') } qr/\AInvalid arguments to /, 'the matrix must be a hash';
	};

	subtest 'is_linux_runner' => sub {
		is(App::Actions::Workflow->is_linux_runner($_), 1, "Linux: $_") for ('ubuntu-latest', 'self-hosted', 'my-windowsish-box', '');
		is(App::Actions::Workflow->is_linux_runner(undef), 1, 'an unknown runner is assumed to be Linux');
		is(App::Actions::Workflow->is_linux_runner($_), 0, "not Linux: $_") for ('windows-latest', 'macos-14', 'MacOS-13', 'self-hosted darwin');
	};

	subtest 'default_image_for_runner' => sub {
		is(App::Actions::Workflow->default_image_for_runner('ubuntu-22.04'), 'ubuntu:22.04', 'a versioned Ubuntu');
		is(App::Actions::Workflow->default_image_for_runner('Ubuntu-Latest'), 'ubuntu:latest', 'latest, in any case');
		is(App::Actions::Workflow->default_image_for_runner('self-hosted', 'mine:1'), 'mine:1', 'anything else uses the fallback');
		is(App::Actions::Workflow->default_image_for_runner(undef), undef, 'nothing with no fallback is nothing');
		is(App::Actions::Workflow->default_image_for_runner('ubuntu-22.04; rm -rf /'), 'ubuntu:22.04', 'only the release is taken');
	};

	subtest 'perl_image_for_version' => sub {
		is(App::Actions::Workflow->perl_image_for_version('5.38'), 'perl:5.38', 'the default template');
		is(App::Actions::Workflow->perl_image_for_version('v5.40'), 'perl:5.40', 'a leading v is dropped');
		is(App::Actions::Workflow->perl_image_for_version($_), 'perl:latest', "'$_' means latest") for qw(latest dev LATEST);
		is(App::Actions::Workflow->perl_image_for_version(''), 'perl:latest', 'no version is latest');
		is(App::Actions::Workflow->perl_image_for_version('5.38', 'reg/%s/perl:%s'), 'reg/5.38/perl:5.38', 'every %s is filled');
		is(App::Actions::Workflow->perl_image_for_version('5.38', 'my/perl'), 'my/perl:5.38', 'a template without %s gets a tag');
		is(App::Actions::Workflow->perl_image_for_version('5.38', 'reg%2F/%s'), 'reg%2F/5.38', 'a literal % is not a conversion');
	};

	subtest 'container_image' => sub {
		is($workflow->container_image($job->('build')), 'perl:5.38', 'the job container');
		is($workflow->container_image({ container => { image => 'img:${{ matrix.v }}-${{ env.X }}' }, matrix => { v => 2 } }),
			'img:2-${{ env.X }}', 'the matrix is filled in and anything else is left for later');
		is($workflow->container_image({ setup_perl_version => '5.36' }, 'ubuntu-latest', 'x', 'p:%s'), 'p:5.36',
			'setup-perl chooses a Perl image');
		is($workflow->container_image({}, 'ubuntu-24.04'), 'ubuntu:24.04', 'otherwise the runner\'s image');
		is($workflow->container_image({ setup_perl_version => '' }, 'x', 'fallback'), 'fallback', 'an empty version is none');
		throws_ok { $workflow->container_image('build') } qr/\AInvalid arguments to App::Actions::Workflow::container_image: /,
			'a job must be a hash';
	};

	subtest '_expression' => sub {
		my $first = $workflow->_expression;
		is($workflow->_expression, $first, 'a workflow keeps one evaluator');
		isnt(App::Actions::Workflow->_expression, App::Actions::Workflow->_expression, 'a class call makes a new one each time');
	};

	subtest '_normalize_job' => sub {
		my $normal = App::Actions::Workflow->_normalize_job('j', { steps => [ { run => 'x' } ], needs => 'a', container => 'img' });
		is_deeply($normal->{needs}, [ 'a' ], 'needs: a is a list of one');
		is_deeply($normal->{container}, { image => 'img' }, 'a container string is its image');
		is_deeply([ @{$normal}{qw(services env defaults strategy)} ], [ {}, {}, {}, {} ], 'the optional mappings are empty mappings');
		my $services = { db => { image => 'postgres' } };
		my $with = App::Actions::Workflow->_normalize_job('j', { steps => [ { run => 'x' } ], services => $services });
		isnt($with->{services}, $services, 'services are copied');
		is_deeply(App::Actions::Workflow->_normalize_job('j', { steps => [ { run => 'x' } ], needs => [ 1, 2 ] })->{needs}, [ '1', '2' ],
			'needs are strings');
	};

	subtest '_defaults' => sub {
		my $given = { run => { shell => 'sh' } };
		my $copy = App::Actions::Workflow::_defaults($given, ['where.workflow_defaults']);
		$copy->{run}{shell} = 'changed';
		is($given->{run}{shell}, 'sh', 'defaults.run is copied');
		is_deeply(App::Actions::Workflow::_defaults(undef, ['where.workflow_defaults']), {}, 'no defaults is empty');
		throws_code(sub { App::Actions::Workflow::_defaults({ run => [] }, [ 'where.job_defaults', { job => 'j' } ]) },
			'workflow.defaults_run_invalid', "defaults of job 'j' run must be a mapping", 'the place is named');
	};

	subtest '_expand_matrix' => sub {
		is_deeply(App::Actions::Workflow::_expand_matrix(undef), [ {} ], 'no matrix is one run');
		is_deeply(App::Actions::Workflow::_expand_matrix({ b => [ 1, 2 ], a => 'x' }),
			[ { a => 'x', b => 1 }, { a => 'x', b => 2 } ], 'a scalar is one value and keys expand in sorted order');
		is_deeply(App::Actions::Workflow::_expand_matrix({ include => [ { a => 1 }, { a => 2 }, 'junk' ] }), [ { a => 1 }, { a => 2 } ],
			'only includes: one run each');
		is_deeply(App::Actions::Workflow::_expand_matrix({ include => [] }), [ {} ], 'no includes and no keys is one run');
		is_deeply(App::Actions::Workflow::_expand_matrix({ os => [qw(a b)], exclude => [ { os => 'a' } ] }), [ { os => 'b' } ], 'exclude');
		is_deeply(App::Actions::Workflow::_expand_matrix({ os => [qw(a b)], include => [ { os => 'a', x => 1 }, { os => 'c' } ] }),
			[ { os => 'a', x => 1 }, { os => 'b' }, { os => 'c' } ], 'include extends a match, or adds a new run');
		throws_code(sub { App::Actions::Workflow::_expand_matrix('${{ fromJSON(x) }}') }, 'workflow.matrix_not_mapping',
			'strategy.matrix must be a mapping', 'a matrix expression is refused');
		throws_code(sub { App::Actions::Workflow::_expand_matrix({ os => [] }) }, 'workflow.matrix_empty',
			q{Matrix key 'os' must be a list with at least one value}, 'an empty dimension is refused');
		throws_code(sub { App::Actions::Workflow::_expand_matrix({ os => [ 1 ], exclude => [ 'os' ] }) }, 'workflow.exclude_invalid',
			'Each matrix exclude entry must be a mapping', 'a malformed exclude');
		throws_code(sub { App::Actions::Workflow::_expand_matrix({ os => [ 1 ], include => [ [] ] }) }, 'workflow.include_invalid',
			'Each matrix include entry must be a mapping', 'a malformed include');

		# A matrix is user input; a large one is expensive but must still be
		# exactly the product of its dimensions.
		my $wide = { map { ("k$_" => [ 1 .. 4 ]) } 1 .. 6 };
		is(scalar @{ App::Actions::Workflow::_expand_matrix($wide) }, 4 ** 6, 'six dimensions of four make 4096 runs');
	};

	subtest '_cartesian_product' => sub {
		is_deeply(App::Actions::Workflow::_cartesian_product({ a => [ 1, 2 ], b => [ 3 ] }, [qw(a b)]),
			[ { a => 1, b => 3 }, { a => 2, b => 3 } ], 'every combination');
		is_deeply(App::Actions::Workflow::_cartesian_product({}, []), [ {} ], 'no keys is one empty combination');
		throws_code(sub { App::Actions::Workflow::_cartesian_product({ a => undef }, ['a']) }, 'workflow.matrix_empty', undef,
			'an undefined dimension is empty');
	};

	subtest '_apply_includes' => sub {
		my $result = App::Actions::Workflow::_apply_includes([ { os => 'a' }, { os => 'b' } ], [ { extra => 1 } ], { os => 1 });
		is_deeply($result, [ { os => 'a', extra => 1 }, { os => 'b', extra => 1 } ], 'an include with no original key extends all');
		$result = App::Actions::Workflow::_apply_includes([ { os => 'a', v => 1 } ], [ { v => 2 } ], { os => 1, v => 1 });
		is_deeply($result, [ { os => 'a', v => 1 }, { v => 2 } ], 'one that contradicts an original value is a new run');
		$result = App::Actions::Workflow::_apply_includes([ { os => 'a' } ], [ { os => 'a', x => 1 }, { os => 'a', x => 2 } ], { os => 1 });
		is_deeply($result, [ { os => 'a', x => 2 } ], 'a later include may overwrite a value an earlier one added');
	};

	subtest '_as_list, _matches and _scalar_equal' => sub {
		is_deeply(App::Actions::Workflow::_as_list(undef), [], 'undef is no values');
		is_deeply(App::Actions::Workflow::_as_list('a'), [ 'a' ], 'a scalar is one');
		my $list = [ 1 ];
		is(App::Actions::Workflow::_as_list($list), $list, 'a list is itself');
		is(App::Actions::Workflow::_matches({ a => 1, b => 2 }, { a => 1 }), 1, 'a subset matches');
		is(App::Actions::Workflow::_matches({ a => 1 }, { a => 1, b => 2 }), 0, 'a missing key does not');
		is(App::Actions::Workflow::_matches({ a => 1 }, {}), 1, 'an empty filter matches everything');
		is(App::Actions::Workflow::_scalar_equal(JSON::PP::true(), 'true'), 1, 'a boolean equals its word');
		is(App::Actions::Workflow::_scalar_equal(1, '1'), 1, 'numbers compare as text');
		is(App::Actions::Workflow::_scalar_equal('1.0', '1'), 0, 'so 1.0 is not 1, as GitHub sees it');
		is(App::Actions::Workflow::_scalar_equal(undef, ''), 0, 'undef is not empty');
		is(App::Actions::Workflow::_scalar_equal(undef, undef), 1, 'undef is undef');
		is(App::Actions::Workflow::_scalar_equal({ a => [ 1 ] }, { a => [ 1 ] }), 1, 'structures compare by content');
	};

	subtest '_job_display_name' => sub {
		my $expression = App::Actions::Expression->new;
		is(App::Actions::Workflow::_job_display_name({ id => 'j' }, {}, $expression), 'j', 'no matrix: the id');
		is(App::Actions::Workflow::_job_display_name({ id => 'j' }, { b => 2, a => JSON::PP::true() }, $expression), 'j (a=true, b=2)',
			'matrix values in sorted order');
		is(App::Actions::Workflow::_job_display_name({ id => 'j', name => [ 'x' ] }, {}, $expression), 'j',
			'a name that is not a string is ignored');
		is(App::Actions::Workflow::_job_display_name({ id => 'j', name => '${{ matrix.v }}!' }, { v => 1 }, $expression), '1!',
			'a name is interpolated');
	};

	subtest '_find_setup_perl_version' => sub {
		my $expression = App::Actions::Expression->new;
		my $steps = [ { uses => 'actions/checkout@v4', with => {} }, { uses => 'perl-actions/setup-perl@v1', with => { 'perl-version' => '5.40' } },
			{ uses => 'shogo82148/actions-setup-perl@v1', with => { 'perl-version' => '5.30' } } ];
		is(App::Actions::Workflow::_find_setup_perl_version({ steps => $steps }, {}, $expression), '5.40', 'the first setup-perl wins');
		is(App::Actions::Workflow::_find_setup_perl_version({ steps => [] }, {}, $expression), undef, 'none is undef');
		is(App::Actions::Workflow::_find_setup_perl_version({}, {}, $expression), undef, 'a job with no steps is undef');
		is(App::Actions::Workflow::_find_setup_perl_version({ steps => [ { uses => 'evil/shogo82148/actions-setup-perl@v1', with => { 'perl-version' => 1 } } ] },
			{}, $expression), undef, 'a look-alike action is not setup-perl');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Cache
# ---------------------------------------------------------------------------

use App::Actions::Cache;

# Seconds in a day, for building ages.
Readonly::Scalar my $DAY => 24 * 60 * 60;

subtest 'App::Actions::Cache' => sub {
	my $fresh = sub { App::Actions::Cache->new(file => File::Spec->catfile(tempdir(CLEANUP => 1), 'sub', 'cache.json')) };

	# A Docker object whose image sizes and removals are whatever the test
	# says, so no daemon is needed.
	my %sizes;
	my %remove_status;
	my @removed;
	my $docker = App::Actions::Docker->new(bin => 'docker');
	my $daemon = sub {
		%sizes = %{ $_[0] || {} };
		%remove_status = %{ $_[1] || {} };
		@removed = ();
		return mock_scoped(
			'App::Actions::Docker::image_size' => sub { $sizes{ $_[1] } },
			'App::Actions::Docker::image_remove' => sub { push @removed, $_[1]; $remove_status{ $_[1] } || 0 },
		);
	};

	subtest 'json_schema and json_schema_version' => sub {
		my $schema = App::Actions::Cache->json_schema;
		returns_ok($schema, { type => 'hashref' }, 'the schema is a hash');
		is($schema->{properties}{schema_version}{const}, App::Actions::Cache->json_schema_version, 'and names its own version');
		$schema->{changed} = 1;
		ok(!exists App::Actions::Cache->json_schema->{changed}, 'each call returns a fresh copy');
	};

	subtest 'base_directory and default_path' => sub {
		{
			local $ENV{XDG_CACHE_HOME} = '/x/cache';
			is(App::Actions::Cache::base_directory(), '/x/cache', 'XDG_CACHE_HOME');
		}
		{
			local $ENV{XDG_CACHE_HOME} = '';
			local $ENV{HOME} = '/home/me';
			is(App::Actions::Cache::base_directory(), File::Spec->catdir('/home/me', '.cache'), 'an empty XDG_CACHE_HOME is ignored');
		}
		{
			delete local $ENV{XDG_CACHE_HOME};
			delete local $ENV{HOME};
			is(App::Actions::Cache::base_directory(), File::Spec->catdir(File::Spec->curdir, '.cache'),
				'no home falls back to here, not to /.cache at the root');
		}
		{
			local $^O = 'MSWin32';
			local $ENV{LOCALAPPDATA} = '';
			local $ENV{USERPROFILE} = 'C:\\Users\\me';
			is(App::Actions::Cache::base_directory(), File::Spec->catdir('C:\\Users\\me', 'AppData', 'Local'), 'Windows without LOCALAPPDATA');
		}
		{
			local $ENV{ACTION_RUN_CACHE_FILE} = '/tmp/x.json';
			is(App::Actions::Cache::default_path(), '/tmp/x.json', 'ACTION_RUN_CACHE_FILE wins');
			local $ENV{ACTION_RUN_CACHE_FILE} = '';
			like(App::Actions::Cache::default_path(), qr/action-run.cache\.json\z/, 'an empty one is ignored');
		}
	};

	subtest 'new and file' => sub {
		is(App::Actions::Cache->new(file => '/a/b.json')->file, '/a/b.json', 'a file can be given');
		is(App::Actions::Cache->new(file => '')->file, App::Actions::Cache::default_path(), 'an empty one means the default');
		memory_cycle_ok(App::Actions::Cache->new, 'a cache holds no reference cycle');
	};

	subtest 'load' => sub {
		my $cache = $fresh->();
		is_deeply($cache->load, { version => 1, images => {} }, 'a missing file is an empty cache');
		is($cache->load, $cache->load, 'the record is read once');

		my %damaged = (
			'not json at all' => {},
			'[1, 2]' => {},
			'{"images": "x"}' => {},
			'{"images": {"a": "not an entry", "b": {"pulls": 2, "last_used": 10}}}' => { b => { pulls => 2, last_used => 10 } },
			'{"images": {"a": {"pulls": "many", "last_used": "yesterday"}}}' => { a => { pulls => 0, last_used => undef } },
			'{"images": {"a": {"pulls": -3, "last_used": 1.5}}}' => { a => { pulls => 0, last_used => undef } },
			'{"images": {"a": {"pulls": [1], "last_used": {"x": 1}}}}' => { a => { pulls => 0, last_used => undef } },
		);
		for my $text (sort keys %damaged) {
			my $file = write_file('cache.json', $text);
			is_deeply(App::Actions::Cache->new(file => $file)->load->{images}, $damaged{$text}, "a damaged record is read safely: $text");
		}
		my $unreadable = tempdir(CLEANUP => 1);
		is_deeply(App::Actions::Cache->new(file => $unreadable)->load->{images}, {}, 'a directory in its place is an empty cache');
	};

	subtest 'save' => sub {
		my $cache = $fresh->();
		$cache->load->{images}{alpine} = { pulls => 1, last_used => 5 };
		is($cache->save, 1, 'saving works');
		ok(-f $cache->file, 'and makes the directory and the file');
		is_deeply(App::Actions::Cache->new(file => $cache->file)->load->{images}, { alpine => { pulls => 1, last_used => 5 } },
			'which reads back the same');
		my $dir = (File::Spec->splitpath($cache->file))[1];
		opendir my $handle, $dir or die $!;
		is_deeply([ grep { /\.tmp\z/ } readdir $handle ], [], 'no temporary file is left behind');
		closedir $handle;

		delete $cache->load->{images}{alpine};
		$cache->save;
		ok(!-e $cache->file, 'an empty cache removes the file');
		is($cache->save, 1, 'and saving it again is fine');

		# The rename is the last step.  A directory that is not empty where
		# the file belongs makes it fail: the error must say why, and the
		# temporary file must not be left behind.
		my $occupied = File::Spec->catdir(tempdir(CLEANUP => 1), 'cache.json');
		mkdir $occupied or die $!;
		write_file('keep', 'x', $occupied);
		my $other = App::Actions::Cache->new(file => $occupied);
		$other->load->{images}{b} = { pulls => 1, last_used => 1 };
		throws_ok { $other->save } qr/\Acannot replace '\Q$occupied\E': /, 'a failed rename is reported';
		opendir my $parent, (File::Spec->splitpath($occupied))[1] or die $!;
		is_deeply([ grep { /\.tmp\z/ } readdir $parent ], [], 'and its temporary file is removed');
		closedir $parent;

		my $blocked = write_file('blocker', 'x');
		my $impossible = App::Actions::Cache->new(file => File::Spec->catfile($blocked, 'cache.json'));
		$impossible->load->{images}{a} = { pulls => 1, last_used => 1 };
		dies_ok { $impossible->save } 'a record under a file, not a directory, cannot be written';
	};

	subtest 'remember' => sub {
		my $cache = $fresh->();
		is($cache->remember('a', 'b', undef, ''), 2, 'empty and undefined names are skipped');
		is($cache->remember('a'), 1, 'a second pull');
		my $entries = { map { $_->{image} => $_ } @{ $cache->entries } };
		is($entries->{a}{pulls}, 2, 'counts pulls');
		cmp_ok(abs($entries->{a}{last_used} - time), '<=', 5, 'and the time of the last');
		is($cache->remember, 0, 'nothing to remember changes nothing');
	};

	subtest 'entries' => sub {
		my $cache = $fresh->();
		$cache->remember(qw(b a));
		is_deeply([ map { $_->{image} } @{ $cache->entries } ], [qw(a b)], 'sorted by image');
		$cache->entries->[0]{pulls} = 99;
		is($cache->entries->[0]{pulls}, 1, 'and copies, so a caller cannot change the record');
	};

	subtest 'forget' => sub {
		my $cache = $fresh->();
		$cache->remember(qw(a b));
		is($cache->forget('a', 'nope', undef), 1, 'only known images are counted');
		is_deeply([ map { $_->{image} } @{ App::Actions::Cache->new(file => $cache->file)->entries } ], [ 'b' ], 'and it is saved');
		is($cache->forget, 0, 'nothing to forget');
	};

	subtest 'format_size' => sub {
		my %cases = (0 => '0 B', 1 => '1 B', 1023 => '1023 B', 1024 => '1.0 KB', 1536 => '1.5 KB', 1024 ** 3 => '1.0 GB',
			1024 ** 5 => '1024.0 TB');
		is(App::Actions::Cache::format_size($_), $cases{$_}, "$_ bytes") for sort { $a <=> $b } keys %cases;
		is(App::Actions::Cache::format_size(undef), '0 B', 'unknown is nothing');
		is(App::Actions::Cache::format_size(-5), '0 B', 'a negative size is nothing');
	};

	subtest 'parse_duration' => sub {
		is(App::Actions::Cache::parse_duration('30d'), 30 * $DAY, 'days');
		is(App::Actions::Cache::parse_duration(' 2 Weeks '), 14 * $DAY, 'a word, any case, spaces around');
		is(App::Actions::Cache::parse_duration('0s'), 0, 'zero');
		for my $bad (undef, '', '30', 'd', '1.5d', '-1d', '3 fortnights', '1d2h', "1d\n2h") {
			is_deeply([ App::Actions::Cache::parse_duration($bad) ], [], 'not a duration: ' . explain($bad));
		}
	};

	subtest 'format_span and format_age' => sub {
		is(App::Actions::Cache::format_span(1), '1 second', 'one second');
		is(App::Actions::Cache::format_span(90 * 60), '1 hour', '90 minutes is an hour');
		is(App::Actions::Cache::format_span(40 * $DAY), '1 month', '40 days is a month');
		is(App::Actions::Cache::format_span(800 * $DAY), '2 years', 'years');
		is(App::Actions::Cache::format_span(-5), '0 seconds', 'a negative span is none');
		is(App::Actions::Cache::format_span('soon'), '0 seconds', 'so is one that is not a number');
		is(App::Actions::Cache::format_age(30), 'just now', 'under a minute');
		is(App::Actions::Cache::format_age(2 * $DAY), '2 days ago', 'an age');
		is(App::Actions::Cache::format_age(undef), 'just now', 'unknown is now');
	};

	subtest '_selected_entries and _stamp' => sub {
		my $cache = $fresh->();
		$cache->load->{images} = { old => { pulls => 1, last_used => 0 }, new => { pulls => 1, last_used => 100 * $DAY },
			unknown => { pulls => 1, last_used => undef } };
		is(scalar @{ $cache->_selected_entries }, 3, 'no filter: everything');
		is_deeply([ map { $_->{image} } @{ $cache->_selected_entries(older_than => 30 * $DAY, now => 100 * $DAY) } ], [ 'old' ],
			'only old enough, and never one whose age is unknown');
		like(App::Actions::Cache::_stamp(0), qr/\A\d{4}-\d\d-\d\d \d\d:\d\d\z/, 'a time stamp');
		is(App::Actions::Cache::_stamp($_), '-', 'no stamp for ' . explain($_)) for (undef, 'x', -1, '1.5');
	};

	subtest 'report' => sub {
		my $cache = $fresh->();
		like($cache->report, qr/No images have been cached yet\.\n\z/, 'an empty cache says so');
		$cache->remember('alpine', 'gone');
		my $guard = $daemon->({ alpine => 2048 });
		my $text = $cache->report(docker => $docker);
		like($text, qr/^  IMAGE\s+SIZE\s+LAST USED\s+AGE$/m, 'a table');
		like($text, qr/^  alpine\s+2\.0 KB\s/m, 'with the size of each image');
		like($text, qr/^  gone\s+missing\s/m, 'and missing for one that is not on the daemon');
		like($text, qr/^2 images, 2\.0 KB on disk\.$/m, 'a summary');
		like($text, qr/^1 image is no longer on the daemon\.$/m, 'and a note of the missing one');
		like($cache->report, qr/The Docker daemon is not reachable/, 'no Docker means no sizes');
		like($cache->report(older_than => 30 * $DAY), qr/No cached images are older than 1 month\.\n\z/, 'a filter that matches nothing');
	};

	subtest 'prune' => sub {
		my $cache = $fresh->();
		$cache->remember(qw(keep-failing remove gone));
		my $guard = $daemon->({ 'keep-failing' => 10, remove => 20 }, { 'keep-failing' => 1 });
		my ($text, $status, $data) = $cache->prune(docker => $docker);
		is($status, 1, 'a failed removal fails the prune');
		is_deeply($data, { removed => 1, freed => 20, forgotten => 1, failed => [ 'keep-failing' ] }, 'and the counts are right');
		is_deeply([ sort @removed ], [qw(keep-failing remove)], 'only images that are there are removed');
		is_deeply([ map { $_->{image} } @{ App::Actions::Cache->new(file => $cache->file)->entries } ], [ 'keep-failing' ],
			'the removed and the gone are forgotten, the failed is kept');
		like($text, qr/^Could not remove 1 image:\n  keep-failing$/m, 'the failure is named');

		my ($none, $ok) = $fresh->()->prune(docker => $docker);
		is($ok, 0, 'an empty cache prunes cleanly');
		like($none, qr/No images have been cached yet/, 'and says so');
		throws_ok { $cache->prune } qr/\Apruning the image cache needs a Docker command at /, 'a Docker object is required';
	};

	subtest 'document' => sub {
		my $cache = $fresh->();
		$cache->remember(qw(a b));
		my $guard = $daemon->({ a => 5 });
		my $document = $cache->document(docker => $docker, reachable => 1, now => time);
		is($document->{schema_version}, App::Actions::Cache->json_schema_version, 'the schema version');
		is_deeply($document->{totals}, { images => 2, size => 5, present => 1, missing => 1 }, 'the totals');
		is_deeply([ map { $_->{present} ? 1 : 0 } @{ $document->{images} } ], [ 1, 0 ], 'present is a boolean per image');
		is($document->{docker}{bin}, 'docker', 'the Docker command');
		memory_cycle_ok($document, 'the document holds no reference cycle');
		my $offline = $cache->document;
		is_deeply($offline->{totals}, { images => 2, size => undef, present => undef, missing => undef }, 'unreachable: unknown');
		ok(!$offline->{docker}{reachable}, 'and says the daemon was not reachable');

		my $future = $fresh->();
		$future->load->{images}{a} = { pulls => 1, last_used => time + $DAY };
		is($future->document->{images}[0]{age}, 0, 'a last use in the future is age 0, not negative');

		# The document is checked against its own schema before it is
		# returned; a broken document must never reach the caller.
		my $broken = mock_scoped('App::Actions::Schema::assert_valid' => sub { die "document invalid\n" });
		throws_ok { $cache->document } qr/\Adocument invalid$/, 'a document that fails its schema is not returned';
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Logs
# ---------------------------------------------------------------------------

use App::Actions::Logs;

# Names in the shapes the runner writes.
Readonly::Hash my %LOG_NAME => (
	old_run => '20260101-000000-abc123',
	new_run => '20261020-120000-def456',
	log => 'job-1-test.log',
);

subtest 'App::Actions::Logs' => sub {
	# A log directory with two runs, an old one and a new one, plus things
	# the module must leave alone.
	my $tree = sub {
		my $root = tempdir(CLEANUP => 1);
		for my $run (@LOG_NAME{qw(old_run new_run)}) {
			my $dir = File::Spec->catdir($root, $run);
			mkdir $dir or die $!;
			my $path = write_file($LOG_NAME{log}, 'x' x 10, $dir);
			utime 0, 0, $path if $run eq $LOG_NAME{old_run};
			write_file('notes.txt', 'not a log', $dir);
		}
		mkdir File::Spec->catdir($root, 'not-a-run') or die $!;
		write_file($LOG_NAME{log}, 'x', File::Spec->catdir($root, 'not-a-run'));
		mkdir File::Spec->catdir($root, '20260202-000000-aaaa') or die $!;	# a run with no logs
		return $root;
	};

	subtest 'json_schema, json_schema_version and default_directory' => sub {
		is(App::Actions::Logs->json_schema->{properties}{schema_version}{const}, App::Actions::Logs->json_schema_version,
			'the schema names its own version');
		local $ENV{ACTION_RUN_LOG_DIR} = '/somewhere';
		is(App::Actions::Logs::default_directory(), '/somewhere', 'ACTION_RUN_LOG_DIR');
		local $ENV{ACTION_RUN_LOG_DIR} = '';
		like(App::Actions::Logs::default_directory(), qr/action-run.logs\z/, 'an empty one is ignored');
	};

	subtest 'new and directory' => sub {
		is(App::Actions::Logs->new(directory => '/d')->directory, '/d', 'a directory');
		is(App::Actions::Logs->new(directory => '')->directory, App::Actions::Logs::default_directory(), 'empty means the default');
		memory_cycle_ok(App::Actions::Logs->new, 'no reference cycle');
	};

	subtest 'entries' => sub {
		my $root = $tree->();
		my $entries = App::Actions::Logs->new(directory => $root)->entries;
		is_deeply([ map { $_->{name} } @{$entries} ], [ @LOG_NAME{qw(new_run old_run)} ], 'runs with logs, newest first');
		is_deeply([ map { $_->{name} } @{ $entries->[0]{logs} } ], [ $LOG_NAME{log} ], 'only job logs, not other files');
		is($entries->[0]{logs}[0]{size}, 10, 'with their size');
		is_deeply(App::Actions::Logs->new(directory => File::Spec->catdir($root, 'none'))->entries, [], 'no directory, no logs');

		SKIP: {
			skip 'symbolic links are not available here', 2 unless eval { symlink('', ''); 1 };
			my $outside = tempdir(CLEANUP => 1);
			write_file($LOG_NAME{log}, 'secret', $outside);
			symlink $outside, File::Spec->catdir($root, '20261021-000000-ffff') or die $!;
			symlink File::Spec->catfile($outside, $LOG_NAME{log}), File::Spec->catfile($root, $LOG_NAME{new_run}, 'job-9.log') or die $!;
			my $names = [ map { $_->{name} } @{ App::Actions::Logs->new(directory => $root)->entries } ];
			ok(!grep({ $_ eq '20261021-000000-ffff' } @{$names}), 'a linked run directory is not followed');
			my ($new) = grep { $_->{name} eq $LOG_NAME{new_run} } @{ App::Actions::Logs->new(directory => $root)->entries };
			ok(!grep({ $_->{name} eq 'job-9.log' } @{ $new->{logs} }), 'nor is a linked log file');
		}
		my $file = write_file('plain', 'x');
		is_deeply(App::Actions::Logs->new(directory => $file)->entries, [], 'a file in place of the directory has no logs');
	};

	subtest '_selected_runs' => sub {
		my $logs = App::Actions::Logs->new(directory => $tree->());
		is(scalar @{ $logs->_selected_runs }, 2, 'everything without a filter');
		is_deeply([ map { $_->{name} } @{ $logs->_selected_runs(older_than => 3600) } ], [ $LOG_NAME{old_run} ], 'only old logs');
		is_deeply($logs->_selected_runs(older_than => 3600, now => 0), [], 'nothing is old at the epoch');
	};

	subtest 'format_age' => sub {
		my @seen;
		my $guard = mock_scoped('App::Actions::Cache::format_age' => sub { push @seen, $_[0]; 'aged' });
		is(App::Actions::Logs::format_age(5), 'aged', 'the cache\'s wording is used');
		is_deeply(\@seen, [ 5 ], 'for the same number of seconds');
	};

	subtest 'report' => sub {
		my $logs = App::Actions::Logs->new(directory => $tree->());
		my $text = $logs->report;
		like($text, qr/^  RUN\s+LOG\s+SIZE\s+AGE$/m, 'a table');
		like($text, qr/^2 logs, 20 B on disk\.$/m, 'with a summary');
		like($logs->report(older_than => 100 * 365 * 24 * 3600), qr/No job logs are older than 100 years\.\n\z/, 'nothing that old');
		like(App::Actions::Logs->new(directory => tempdir(CLEANUP => 1))->report, qr/No job logs have been kept yet\.\n\z/, 'none at all');
	};

	subtest 'prune' => sub {
		my $root = $tree->();
		my $logs = App::Actions::Logs->new(directory => $root);
		my ($text, $status, $data) = $logs->prune(older_than => 3600);
		is($status, 0, 'pruning old logs works');
		is_deeply($data, { removed => 1, freed => 10, failed => [] }, 'one log, ten bytes');
		ok(-d File::Spec->catdir($root, $LOG_NAME{old_run}), 'a run directory holding other files is kept');
		ok(-f File::Spec->catfile($root, $LOG_NAME{new_run}, $LOG_NAME{log}), 'the new log is kept');
		ok(-f File::Spec->catfile($root, 'not-a-run', $LOG_NAME{log}), 'and a directory that is not a run is never touched');

		# A log that cannot be removed fails its run, and the failure is
		# reported with the run and the reason.
		my $guard = mock_scoped('App::Actions::Logs::_unlink' => sub { $! = 13; return 0 });
		($text, $status, $data) = $logs->prune;
		is($status, 1, 'a removal that fails fails the prune');
		is($data->{failed}[0]{run}, $LOG_NAME{new_run}, 'naming the run');
		like($data->{failed}[0]{error}, qr/\Acannot remove '.*\Q$LOG_NAME{log}\E': /, 'and why');
		like($text, qr/^  \Q$LOG_NAME{new_run}\E: cannot remove /m, 'in the text too');
		undef $guard;

		my (undef, $ok, $empty) = App::Actions::Logs->new(directory => tempdir(CLEANUP => 1))->prune;
		is_deeply([ $ok, $empty ], [ 0, { removed => 0, freed => 0, failed => [] } ], 'nothing to prune is not a failure');
	};

	subtest 'document' => sub {
		my $logs = App::Actions::Logs->new(directory => $tree->());
		my $document = $logs->document(now => 100);
		is($document->{totals}{logs}, 2, 'every log');
		is($document->{totals}{runs}, 2, 'in every run');
		ok(!grep({ $_->{age} < 0 } @{ $document->{logs} }), 'an age is never negative');
		memory_cycle_ok($document, 'no reference cycle');
		my $guard = mock_scoped('App::Actions::Schema::assert_valid' => sub { die "invalid\n" });
		throws_ok { $logs->document } qr/\Ainvalid$/, 'a document that fails its schema is not returned';
	};

	subtest '_unlink' => sub {
		my $file = write_file('x.log', 'x');
		is(App::Actions::Logs->_unlink($file), 1, 'a file is removed');
		ok(!-e $file, 'and is gone');
		is(App::Actions::Logs->_unlink($file), 0, 'a file that is not there is a failure');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Check
# ---------------------------------------------------------------------------

use App::Actions::Check;

subtest 'App::Actions::Check' => sub {
	# The daemon's answers, in the order the check asks: client version,
	# server version, OS type, then the probe container.
	my @answers;
	my @asked;
	my $daemon = sub {
		@answers = @_;
		@asked = ();
		my $answer = sub { push @asked, [ @_[ 1 .. $#_ ] ]; return @{ shift(@answers) || [ '', 1 ] } };
		return mock_scoped(
			'App::Actions::Docker::capture_silent' => $answer,
			'App::Actions::Docker::capture' => $answer,
		);
	};
	my $text = '';
	my $check = sub {
		$text = '';
		open my $handle, '>', \$text or die $!;
		return App::Actions::Check->new(output => $handle, @_);
	};

	subtest 'json_schema, json_schema_version, new and image' => sub {
		is(App::Actions::Check->json_schema->{properties}{schema_version}{const}, App::Actions::Check->json_schema_version,
			'the schema names its own version');
		is(App::Actions::Check->new->image, 'alpine:3.20', 'the default probe image');
		is(App::Actions::Check->new(image => '')->image, 'alpine:3.20', 'an empty image is the default');
		my $object = App::Actions::Check->new(os => 'MSWin32', quiet => 'yes', json => 0, summary => 0, title => undef);
		is_deeply([ @{$object}{qw(os quiet json summary title schema_line)} ], [ 'MSWin32', 1, 0, 0, undef, 1 ], 'the options');
		# Devel::Cycle cannot walk a GLOB, so look at everything but the handle.
		memory_cycle_ok({ map { $_ => $object->{$_} } grep { $_ ne q{output} } keys %{$object} }, q{no reference cycle});
	};

	subtest 'run' => sub {
		my $guard = $daemon->([ "27.0\n", 0 ], [ "27.0\n", 0 ], [ "linux\n", 0 ], [ (join '-', time, $$) . "\n", 0 ]);
		my $object = $check->();
		is($object->run, 0, 'everything ready is 0');
		like($text, qr/\Aaction-run check\n/, 'the report has a title');
		like($text, qr/^Result: ready$/m, 'and a verdict');

		$guard = $daemon->([ '', 127 ]);
		$object = $check->(quiet => 1);
		is($object->run, 2, 'a problem is 2');
		like($text, qr/^  problem   the Docker command 'docker' could not be run$/m, 'and is printed even when quiet');
		like($text, qr/^Result: not ready \(1 problem\)$/m, 'with a count');

		$guard = $daemon->([ "27.0\n", 0 ], [ "27.0\n", 0 ], [ "linux\n", 0 ], [ (join '-', time, $$) . "\n", 0 ]);
		$object = $check->(quiet => 1);
		is($object->run, 0, 'a quiet check that passes');
		is($text, '', 'prints nothing');

		$guard = $daemon->([ '', 127 ]);
		$object = $check->(json => 1);
		$object->run;
		my $document = JSON::PP->new->decode($text);
		is($document->{ready}, JSON::PP::false(), 'the JSON report says not ready, as a boolean');
		is($document->{issues}[0]{problem}, q{the Docker command 'docker' could not be run}, 'and lists the problem');

		# A check that dies part way must not leave the object writing into
		# its private buffer.
		my $handle_before = $check->();
		my $original = $handle_before->{output};
		my $dies = mock_scoped('App::Actions::Check::_run_checks' => sub { die "probe exploded\n" });
		throws_ok { $handle_before->run } qr/\Aprobe exploded$/, 'a failure mid-flight propagates';
		is($handle_before->{output}, $original, 'and the output handle is put back');
	};

	subtest '_run_checks' => sub {
		my $guard = $daemon->([ "27.0\n", 0 ], [ '', 1 ]);
		my $object = $check->(summary => 0, schema_line => 0, title => '');
		is($object->_run_checks, 2, 'an unreachable daemon is a problem');
		unlike($text, qr/Result:|schema|action-run check/, 'without a title, schema line or verdict when they are turned off');
		is($object->{data}{docker}{bin}, 'docker', 'the Docker command is recorded');
	};

	subtest 'host_info and _host_description' => sub {
		my $info = App::Actions::Check->host_info('linux');
		is_deeply([ @{$info}{qw(os name)} ], [ 'linux', 'Linux' ], 'a known platform has a name');
		is(App::Actions::Check->host_info('plan9')->{name}, 'plan9', 'an unknown one is named as itself');
		is(App::Actions::Check->new(os => 'darwin')->host_info->{os}, 'darwin', 'an object uses its own platform');
		is(App::Actions::Check->new(os => q{darwin})->host_info(q{})->{os}, q{darwin}, q{an empty platform is the object's});
		is(App::Actions::Check->new(os => q{darwin})->host_info(q{linux})->{os}, q{linux}, q{an argument beats the object});
		like(App::Actions::Check->new(os => 'linux')->_host_description, qr/\ALinux \(linux\), perl \d+\.\d+\.\d+, \S+\z/, 'a description');
	};

	subtest '_check_daemon' => sub {
		my $docker = App::Actions::Docker->new(bin => 'docker');
		my %cases = (
			'no client' => [ [ [ '', 1 ] ], 0, qr/could not be run/ ],
			'empty client version' => [ [ [ "  \n", 0 ] ], 0, qr/could not be run/ ],
			'no daemon' => [ [ [ "1\n", 0 ], [ '', 1 ] ], 0, qr/the daemon is not reachable/ ],
			'Windows containers' => [ [ [ "1\n", 0 ], [ "1\n", 0 ], [ "windows\n", 0 ] ], 0, qr/runs 'windows' containers/ ],
			'unknown containers' => [ [ [ "1\n", 0 ], [ "1\n", 0 ], [ '', 1 ] ], 0, qr/runs 'unknown' containers/ ],
			'ready' => [ [ [ "1\n", 0 ], [ "2\n", 0 ], [ "Linux\n", 0 ] ], 1, qr/^  daemon    2, linux containers$/m ],
		);
		for my $name (sort keys %cases) {
			my ($answers, $result, $pattern) = @{ $cases{$name} };
			my $guard = $daemon->(@{$answers});
			my $object = $check->();
			is($object->_check_daemon($docker), $result, "$name: result");
			like($text, $pattern, "$name: report");
		}
		my $guard = $daemon->([ '', 1 ]);
		my $windows = $check->(os => 'MSWin32');
		$windows->_check_daemon($docker);
		like($text, qr/docker\.exe/, 'the remedy suits Windows');
	};

	subtest '_check_mounts' => sub {
		my $docker = App::Actions::Docker->new(bin => 'docker');
		my $token = join '-', time, $$;
		{
			my $guard = $daemon->([ "$token\n0\n", 0 ]);
			is($check->()->_check_mounts($docker), 1, 'the marker comes back');
			like($text, qr{^  mount     .+ -> /action-run-check: OK$}m, 'the mount is reported');
			ok(grep({ $_ eq '--network' } @{ $asked[0] }), 'the probe has no network');
		}
		{
			my $guard = $daemon->([ "wrong\n", 0 ]);
			my $object = $check->();
			is($object->_check_mounts($docker), 0, 'a marker that does not come back');
			like($text, qr/could not read the mounted temporary directory/, 'is a problem');
		}
		{
			my $guard = $daemon->([ '', 125 ]);
			is($check->()->_check_mounts($docker), 0, 'a probe container that fails');
			like($text, qr/^  problem   the probe container failed \(exit 125\)$/m, 'is reported with its status');
		}
		my $project = tempdir(CLEANUP => 1);
		write_file($_, 'x', $project) for qw(a b);
		{
			my $guard = $daemon->([ "$token\n2\n", 0 ]);
			is($check->(directory => $project)->_check_mounts($docker), 1, 'the project shows the same entries');
			like($text, qr/OK \(2 entries\)/, 'and says how many');
		}
		{
			my $guard = $daemon->([ "$token\n0\n", 0 ]);
			my $object = $check->(directory => $project);
			is($object->_check_mounts($docker), 0, 'an empty project mount');
			like($text, qr/sees 0 entries, the host has 2/, 'is a problem');
			is($object->{data}{mounts}[-1]{ok}, JSON::PP::false(), 'and the mount is marked not OK');
		}
		{
			my $guard = $daemon->([ "$token\nlots\n", 0 ]);
			is($check->(directory => $project)->_check_mounts($docker), 0, 'a count that is not a number');
			like($text, qr/could not count the entries/, 'is a problem');
		}
		my $guard = $daemon->();
		is($check->(directory => File::Spec->catdir($project, 'gone'))->_check_mounts($docker), 0, 'a project that is not there');
		like($text, qr/is not a directory/, 'is a problem before any container runs');
		is(scalar @asked, 0, 'and nothing was run');
	};

	subtest '_entry_count' => sub {
		my $dir = tempdir(CLEANUP => 1);
		is(App::Actions::Check::_entry_count($dir), 0, 'an empty directory');
		write_file('.hidden', 'x', $dir);
		is(App::Actions::Check::_entry_count($dir), 1, 'hidden files count, as ls -A counts them');
		is(App::Actions::Check::_entry_count(File::Spec->catdir($dir, 'gone')), undef, 'an unreadable directory has no count');
	};

	subtest '_problem' => sub {
		my $object = $check->();
		is($object->_problem('broken', 'fix it', undef, '', 'or this'), 0, 'returns 0, for "return $self->_problem"');
		is($text, "  problem   broken\n  remedy    fix it\n  remedy    or this\n", 'empty remedies are skipped');
		is_deeply($object->{data}{issues}, [ { problem => 'broken', remedies => [ 'fix it', 'or this' ] } ], 'and recorded');
		is($object->{problems}, 1, 'and counted');
	};

	subtest 'summary and _json_report' => sub {
		my $object = $check->();
		$object->_problem('x');
		my $summary = $object->summary(2);
		is_deeply([ @{$summary}{qw(ready problems)} ], [ 0, 1 ], 'not ready, one problem');
		is($object->summary(0)->{ready}, 1, 'ready when the exit is 0');
		my $guard = mock_scoped('App::Actions::Schema::assert_valid' => sub { die "invalid\n" });
		throws_ok { $object->_json_report(2) } qr/\Ainvalid$/, 'a document that fails its schema is not printed';
	};

	subtest '_is_windows and _trim' => sub {
		is(App::Actions::Check->new(os => $_)->_is_windows ? 1 : 0, 1, "Windows: $_") for qw(MSWin32 cygwin msys);
		is(App::Actions::Check->new(os => $_)->_is_windows ? 1 : 0, 0, "not Windows: $_") for qw(linux darwin);
		is(App::Actions::Check::_trim("  a b \r\n"), 'a b', '_trim');
		is(App::Actions::Check::_trim(undef), '', 'undef is empty');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Support
# ---------------------------------------------------------------------------

use App::Actions::Expression;
use App::Actions::Runner::Support::Env;
use App::Actions::Runner::Support qw(
	action_inputs boolean_value chomp_error default_logger env_args has_status_function
	local_action_dir local_action_path null_logger redact resolve_env status_flags
	trim_error write_container_file
);

# Stand-ins for the runner's collaborators.  Each records what it was asked,
# so a test can tell whether the evaluator was consulted at all.
{
	package Local::FakeExpression;
	sub new { my ($class, %answer) = @_; return bless { %answer, asked => [] }, $class }
	sub condition { my ($self, $text) = @_; push @{ $self->{asked} }, $text; return $self->{condition} }
	sub interpolate {
		my ($self, $text) = @_;
		push @{ $self->{asked} }, $text;
		die $self->{dies} if $self->{dies};
		return $self->{interpolate} ? $self->{interpolate}->($text) : $text;
	}

	package Local::FakeAction;
	sub new { my ($class, $inputs) = @_; return bless { inputs => $inputs }, $class }
	sub inputs { return $_[0]{inputs} }

	package Local::Redactor;
	sub new { return bless {}, shift }
	sub redact { my (undef, $text) = @_; (my $copy = $text) =~ s/hunter2/***/g; return $copy }
}

subtest 'App::Actions::Runner::Support' => sub {
	subtest 'status_flags' => sub {
		is_deeply(status_flags(0), { success => 1, failure => 0, cancelled => 0 }, 'a job that has not failed');
		is_deeply(status_flags('yes'), { success => 0, failure => 1, cancelled => 0 }, 'any true value is a failure');
		is_deeply(status_flags(undef), status_flags(0), 'undef is not a failure');
		returns_ok(status_flags(1), { type => 'hashref' }, 'a hash reference');
	};

	subtest 'chomp_error and trim_error' => sub {
		is(chomp_error("broken \n\t"), 'broken', 'trailing white space goes');
		is(chomp_error("  kept"), '  kept', 'leading white space stays');
		is(chomp_error(undef), '', 'undef is empty');
		is(chomp_error(App::Actions::Error->new(code => 'x.y', message => 'm', location => "\n")), 'm', 'an object reads as its text');
		is(trim_error("lost at lib/X.pm line 3.\n"), 'lost', 'the location is cut off');
		is(trim_error(undef), undef, 'undef has no description');
		is(trim_error(''), undef, 'nor has an empty error');
		keeps_topic(sub { chomp_error("x\n"); trim_error("x\n") }, 'chomp_error and trim_error');
	};

	subtest 'default_logger and null_logger' => sub {
		my $stderr = '';
		{
			local *STDERR;
			open STDERR, '>', \$stderr or die $!;
			default_logger()->warn('careful');
			default_logger()->error('broken');
			null_logger()->error('never seen');
		}
		is($stderr, "careful\nbroken\n", 'the default logger prints plain lines; the null logger prints nothing');
		isa_ok(default_logger(), 'Log::Abstraction');
		isnt(default_logger(), default_logger(), 'each call is a fresh logger');
	};

	subtest 'resolve_env' => sub {
		my $expression = App::Actions::Expression->new;
		my $env = resolve_env($expression, [ { A => 'a', B => 'x' }, 'not a layer', { B => '${{ env.A }}-b' } ], {});
		is_deeply($env, { A => 'a', B => 'a-b' }, 'later layers win, and refer to earlier values');

		# A chain longer than one pass settles whatever order keys come in.
		$env = resolve_env($expression, [ { C => '${{ env.B }}c', B => '${{ env.A }}b', A => 'a' } ], {});
		is($env->{C}, 'abc', 'a chain of references settles');

		# B is resolved before Z (sorted), so Z is worked out in the middle of
		# B's expression, which must then carry on where it was.
		$env = resolve_env($expression, [ { Z => 'a', B => q{${{ env.Z == 'a' }}-${{ format('{0}+{1}', env.Z, 2) }}} } ], {});
		is($env->{B}, 'true-a+2', 'a variable worked out mid-expression');

		# Two variables that refer to each other, or one that refers to
		# itself, have no value; they must be reported, not grown pass by pass.
		throws_code(sub { resolve_env($expression, [ { A => '${{ env.B }}x', B => '${{ env.A }}y' } ], {}) }, 'runner.env_cycle',
			"Environment variable 'A' refers to itself, directly or through other variables", 'a cycle is reported');
		my $started = time;
		throws_code(sub { resolve_env($expression, [ { A => '${{ env.A }}' x $config{big} } ], {}) }, 'runner.env_cycle',
			undef, 'so is a value that repeats itself many times');
		ok(time - $started <= $config{time_limit}, 'and that is found at once');

		# A value is interpolated once: ${{ }} text that came from the
		# context (a commit message, say) must never be evaluated.
		my $hostile = { github => { event => { message => '${{ secrets.TOKEN }}' } }, secrets => { TOKEN => 'hunter2' } };
		is(resolve_env($expression, [ { MSG => '${{ github.event.message }}', B => '${{ env.MSG }}' } ], $hostile)->{B},
			'${{ secrets.TOKEN }}', 'expression text from the context is not expanded, even through another variable');
		is(resolve_env($expression, [ { A => '${{ env.MISSING }}z' } ], {})->{A}, 'z', 'an unknown variable is empty');

		# The env context holds the resolver, which holds the context: that
		# loop must be broken on the way out, even when a cycle aborts the run.
		my $weak;
		{
			# The context is copied, so watch a value it holds, not the hash.
			my $context = { github => {} };
			Scalar::Util::weaken($weak = $context->{github});
			caught { resolve_env($expression, [ { A => '${{ env.A }}' } ], $context) };
		}
		ok(!defined $weak, 'a failed resolution leaves nothing behind');

		is_deeply(resolve_env($expression, [], {}), {}, 'no layers, no variables');
		is_deeply(resolve_env($expression, [ { N => 3, B => JSON::PP::true() } ], {}), { N => '3', B => 'true' }, 'values are strings');

		my $broken = Local::FakeExpression->new(dies => "bad expression\n");
		throws_code(sub { resolve_env($broken, [ { NAME => '${{ nope( }}' } ], {}) }, 'runner.env_failed',
			"Unable to evaluate environment variable 'NAME': bad expression", 'an expression that fails names the variable');
		my $context = { github => { x => 1 } };
		resolve_env(Local::FakeExpression->new, [ { A => 'a' } ], $context);
		is_deeply($context, { github => { x => 1 } }, 'the caller\'s context is not given an env');
	};

	# The tie behind resolve_env, driven by hand so that each path - a value
	# worked out once, a cycle, a failure further down a chain - is seen
	# without the evaluator in between.
	subtest 'App::Actions::Runner::Support::Env' => sub {
		my %calls;
		my %resolved;
		my %lazy;
		my $raw = { A => 'a', B => 'uses A', SELF => 'uses SELF', BAD => 'broken', C => 'uses BAD' };
		my $state = tie %lazy, 'App::Actions::Runner::Support::Env', $raw, \%resolved, sub {
			my ($key) = @_;
			$calls{$key}++;
			die "cannot parse\n  \n" if $key eq 'BAD';
			return $raw->{$key} =~ /\Auses (\w+)\z/ ? "<$lazy{$1}>" : $raw->{$key};
		};

		is($lazy{B}, '<a>', 'a variable is worked out from the one it uses');
		is($lazy{B}, '<a>', 'and read again');
		is_deeply(\%calls, { A => 1, B => 1 }, 'each is worked out once');
		is_deeply(\%resolved, { A => 'a', B => '<a>' }, 'and stored');
		is($lazy{NOPE}, undef, 'a name that is not a variable is undef');
		ok(exists $lazy{SELF} && !exists $lazy{NOPE}, 'exists sees the raw names');
		is_deeply([ sort keys %lazy ], [ sort keys %{$raw} ], 'and so does keys');
		ok(scalar(%lazy), 'a hash with variables is true');
		ok(!exists $resolved{SELF}, 'walking the keys works nothing out');
		is($state->failure, undef, 'no failure yet');

		my $error = throws_code(sub { return $lazy{SELF} }, 'runner.env_cycle',
			"Environment variable 'SELF' refers to itself, directly or through other variables", 'a variable that uses itself');
		is($state->failure, $error, 'is remembered');
		ok(!exists $resolved{SELF}, 'and has no value');
		throws_ok { $lazy{X} = 1 } qr/STORE/, 'the hash cannot be written';
		undef $state;
		untie %lazy;

		# A failure at the end of a chain is reported as itself, once.
		$state = tie %lazy, 'App::Actions::Runner::Support::Env', $raw, {}, sub {
			my ($key) = @_;
			die "cannot parse\n  \n" if $key eq 'BAD';
			my $inner = eval { $lazy{BAD} };
			die "lost: $@" unless defined $inner;	# as the evaluator does: the code is gone
			return $inner;
		};
		throws_code(sub { return $lazy{C} }, 'runner.env_failed',
			"Unable to evaluate environment variable 'BAD': cannot parse", 'the failing variable is named, not the one that used it');
		is($state->failure->code, 'runner.env_failed', 'and kept with its code');
		undef $state;
		untie %lazy;

		my $empty = tie my %none, 'App::Actions::Runner::Support::Env', {}, {}, sub { die 'never' };
		ok(!scalar(%none), 'a hash with no variables is false');
		is_deeply([ keys %none ], [], 'and has no keys');
		undef $empty;
		untie %none;
	};

	subtest 'boolean_value' => sub {
		my $expression = Local::FakeExpression->new(condition => 1);
		is(boolean_value($expression, JSON::PP::true()), 1, 'a YAML true');
		is(boolean_value($expression, JSON::PP::false()), 0, 'a YAML false');
		is(boolean_value($expression, $_), 1, "the word '$_'") for qw(true TRUE yes Yes 1);
		is(boolean_value($expression, $_), 0, "the word '$_'") for (qw(false No 0), '', '  ');
		is(boolean_value($expression, undef), 0, 'no value');
		is_deeply($expression->{asked}, [], 'none of which reaches the evaluator');

		# Near misses are expressions, not words.
		for my $text ('yes please', 'truely', '01', "true\n1") {
			$expression->{asked} = [];
			is(boolean_value($expression, $text), 1, "'$text' is evaluated");
			is(scalar @{ $expression->{asked} }, 1, "'$text' asks the evaluator once");
		}
		$expression->{condition} = 0;
		is(boolean_value($expression, 'env.FLAG'), 0, 'a false expression');
		keeps_topic(sub { boolean_value($expression, ' yes ') }, 'boolean_value');
	};

	subtest 'has_status_function' => sub {
		is(has_status_function($_), 1, "'$_' calls a status function")
			for ('always()', 'success() && x', 'failure ( )', "x || cancelled()");
		is(has_status_function($_), 0, "'$_' does not")
			for ('alwaysx()', 'my_success()', 'success', 'env.always', '');
		is(has_status_function(undef), 0, 'nor does no condition');
	};

	subtest 'write_container_file' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'step-1.sh');
		is(write_container_file($path, "echo hi\n", 'the script'), undef, 'returns nothing');
		is(do { open my $h, '<', $path or die $!; local $/; <$h> }, "echo hi\n", 'the contents');
		is((stat $path)[2] & oct('0777'), oct('0600'), 'readable by its owner only');
		write_container_file($path, "second\n", 'the script');
		is(-s $path, 7, 'a file this run wrote before is replaced');
		write_container_file($path, '', 'the script');
		is(-s $path, 0, 'empty contents are fine');

		SKIP: {
			skip 'symbolic links are not available here', 2 unless eval { symlink('', ''); 1 };
			my $target = write_file('target', 'untouched');
			my $link = File::Spec->catfile($dir, 'planted.sh');
			symlink $target, $link or die $!;
			# The link is removed, not followed: unlink works in a directory
			# we own, and the new file is created where the link was.
			write_container_file($link, 'secret', 'the script');
			is(do { open my $h, '<', $target or die $!; local $/; <$h> }, 'untouched', 'a planted link is never written through');
			ok(!-l $link, 'and is replaced by a plain file');
		}

		my $missing = File::Spec->catfile($dir, 'no', 'such', 'file');
		my $error = throws_code(sub { write_container_file($missing, 'x', 'the step script') }, 'runner.write_failed',
			undef, 'a file that cannot be created');
		local $! = 2;
		is($error->message, "Unable to write the step script: $!", 'names what was being written and why');

		# unlink cannot remove a directory, so the exclusive create meets it
		# and must refuse rather than write somewhere else.
		my $blocker = File::Spec->catfile($dir, 'blocked');
		mkdir $blocker or die $!;
		throws_code(sub { write_container_file($blocker, 'x', 'the env file') }, 'runner.write_failed', undef,
			'an existing directory in the way is refused');
	};

	subtest 'local_action_path' => sub {
		my %good = (
			'./actions/hello' => 'actions/hello',
			'actions/hello/' => 'actions/hello',
			'/actions//hello//' => 'actions//hello',
			'./.github/actions/x' => '.github/actions/x',
			'./a/..b/c' => 'a/..b/c',
			'./a/b..' => 'a/b..',
		);
		is(local_action_path($_), $good{$_}, "'$_'") for sort keys %good;

		throws_code(sub { local_action_path($_) }, 'runner.local_action_empty',
			"Local action '$_' does not name a directory inside the project", "'$_' names nothing")
			for ('./', '/', '//', '');
		throws_code(sub { local_action_path($_) }, 'runner.local_action_escapes',
			"Local action '$_' must not escape the project directory", "'$_' climbs out")
			for ('../x', './..', './a/../../x', '/..', 'a/../b', '..');
		keeps_topic(sub { local_action_path('./a') }, 'local_action_path');
	};

	subtest 'local_action_dir' => sub {
		my $project = tempdir(CLEANUP => 1);
		mkdir File::Spec->catdir($project, 'act') or die $!;
		is_deeply(local_action_dir($project, './act'), { relative => 'act', dir => File::Spec->catdir($project, 'act') },
			'a directory inside the project');
		is(local_action_dir($project, './missing')->{relative}, 'missing', 'one that does not exist is the caller\'s to report');

		SKIP: {
			skip 'symbolic links are not available here', 2 unless eval { symlink('', ''); 1 };
			my $outside = tempdir(CLEANUP => 1);
			symlink $outside, File::Spec->catdir($project, 'out') or die $!;
			throws_code(sub { local_action_dir($project, './out') }, 'runner.local_action_escapes',
				"Local action './out' must not escape the project directory", 'a link out of the project is refused');
			symlink File::Spec->catdir($project, 'act'), File::Spec->catdir($project, 'in') or die $!;
			is(local_action_dir($project, './in')->{relative}, 'in', 'a link that stays inside is allowed');
		}
		throws_code(sub { local_action_dir($project, '../x') }, 'runner.local_action_escapes', undef,
			'the path is checked before the disk');
	};

	subtest 'action_inputs' => sub {
		my $expression = Local::FakeExpression->new(interpolate => sub { (my $t = shift) =~ s/\$\{\{ x \}\}/X/g; $t });
		my $action = Local::FakeAction->new({
			who => { default => 'world' },
			empty => { default => '' },
			need => { required => 1 },
			over => { default => 'default' },
		});
		my $inputs = action_inputs($expression, $action, { with => { need => '${{ x }}', over => 'mine', extra => [ 1, 2 ] } }, './a', {});
		is_deeply($inputs, { who => 'world', empty => '', need => 'X', over => 'mine', extra => '[1,2]' },
			'defaults, then the step\'s values, structures as JSON');
		ok(!grep({ /\[1,2\]/ } @{ $expression->{asked} }), 'a structure is never interpolated');

		throws_code(sub { action_inputs($expression, $action, {}, './a', {}) }, 'runner.input_required',
			"Action './a' requires the input 'need'", 'a required input not given');
		throws_code(sub { action_inputs($expression, $action, { with => { need => '' } }, './a', {}) }, 'runner.input_required',
			undef, 'an empty value does not satisfy it');
		my $two = Local::FakeAction->new({ b => { required => 1 }, a => { required => 'true' } });
		throws_code(sub { action_inputs($expression, $two, { with => 'junk' }, 'o/r@v1', {}) }, 'runner.input_required',
			"Action 'o/r\@v1' requires the input 'a'", 'the first missing input by name, every time; junk with is ignored');
		is_deeply(action_inputs($expression, Local::FakeAction->new(undef), {}, './a', {}), {}, 'an action with no inputs');

		my $broken = Local::FakeExpression->new(dies => "bad\n");
		throws_ok { action_inputs($broken, $action, { with => { need => 'y' } }, './a', {}) } qr/\Abad$/,
			'an expression that fails propagates';
	};

	subtest 'redact' => sub {
		is(redact(Local::Redactor->new, 'pw hunter2'), 'pw ***', 'a client that can redact');
		is(redact(Local::FakeAction->new, 'pw hunter2'), 'pw hunter2', 'one that cannot leaves the text');
		is(redact(Local::Redactor->new, undef), undef, 'undef stays undef');
	};

	subtest 'env_args' => sub {
		my $args = env_args({ B => 'two', A => 'one; rm -rf /' });
		is(scalar @{$args}, 4, 'two -e pairs');
		is_deeply([ @{$args}[0, 2] ], [ '-e', '-e' ], 'each value follows -e');
		isa_ok($args->[1], 'App::Actions::Docker::Variable');
		is("$args->[1]", 'A=one; rm -rf /', 'sorted, and the value is carried unchanged, never split');
		is_deeply(env_args({}), [], 'no variables');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Report
# ---------------------------------------------------------------------------

use App::Actions::Runner::Report;

# A logger that remembers what it was told, so a test can see a warning
# without reading standard error.
{
	package Local::Logger;
	sub new { return bless { lines => [] }, shift }
	sub warn { my ($self, @text) = @_; push @{ $self->{lines} }, [ warn => join '', @text ]; return }
	sub error { my ($self, @text) = @_; push @{ $self->{lines} }, [ error => join '', @text ]; return }
	sub notice { my ($self, @text) = @_; push @{ $self->{lines} }, [ notice => join '', @text ]; return }
}

subtest 'App::Actions::Runner::Report' => sub {
	my $report = sub { App::Actions::Runner::Report->new(docker => Local::Redactor->new, logger => Local::Logger->new, @_) };

	# Everything the report says goes to standard output; capture it.
	my $printed = sub {
		my ($code) = @_;
		my $text = '';
		open my $handle, '>', \$text or die $!;
		my $old = select $handle;
		{
			local *STDOUT = $handle;
			$code->();
		}
		select $old;
		close $handle;
		return $text;
	};

	subtest 'new' => sub {
		my $object = $report->();
		is_deeply([ @{$object}{qw(entries failed kept_dir kept_logs)} ], [ [], 0, undef, [] ], 'a report starts empty');
		memory_cycle_ok($object, 'no reference cycle');
		isa_ok(App::Actions::Runner::Report->new(docker => Local::Redactor->new)->{logger}, 'Log::Abstraction', 'the default logger');

		# validate_args croaks plain text naming the routine and the parameter.
		my $prefix = 'Invalid arguments to App::Actions::Runner::Report::new: ';
		throws_ok { App::Actions::Runner::Report->new } qr/\A\Q${prefix}Required parameter 'docker' is missing\E at /,
			'a Docker client is required';
		throws_ok { App::Actions::Runner::Report->new(docker => 'docker') } qr/\A\Q${prefix}Parameter 'docker' must be an object\E at /,
			'and must be an object';
		throws_ok { App::Actions::Runner::Report->new(docker => Local::Redactor->new, logger => Local::Redactor->new) }
			qr/\A\Q${prefix}Parameter 'logger' must be an object that understands the warn method\E at /,
			'a logger must be able to warn, error and notice';
		throws_ok { App::Actions::Runner::Report->new(docker => Local::Redactor->new, colour => 1) }
			qr/\A\Q${prefix}Unknown parameter 'colour'\E at /, 'an unknown option is refused';
	};

	subtest 'record, fail and failed' => sub {
		my $object = $report->();
		is($object->record('build', 'success'), $object, 'record returns the object');
		is($object->failed, 0, 'not failed');
		is($object->fail, $object, 'fail returns the object');
		is($object->failed, 1, 'failed');
		$object->fail;
		is($object->failed, 1, 'and failing again changes nothing');
		is_deeply($object->{entries}, [ { name => 'build', result => 'success' } ], 'the entry');
	};

	subtest 'print_summary' => sub {
		my $object = $report->()->record('use hunter2', 'success')->record('test', 'failure')->fail;
		my $text = $printed->(sub { $object->print_summary });
		like($text, qr/^  use \*\*\*\s+success$/m, 'a secret in a job name is redacted');
		like($text, qr/^  test\s+failure$/m, 'every job');
		unlike($text, qr/hunter2/, 'the secret is nowhere');
		my $last = (split /\n/, $text)[-1];
		show_state('summary', $text);
		isnt($last, '', 'and a verdict last');

		my $empty = $printed->(sub { $report->()->print_summary });
		my $ok = $printed->(sub { $report->()->record('a', 'success')->print_summary });
		isnt($empty, $ok, 'no jobs reads differently from a job');
		is($printed->(sub { $report->(quiet => 1)->record('a', 'b')->print_summary }), '', 'quiet prints nothing');
	};

	subtest 'report_images' => sub {
		my $text = $printed->(sub {
			$report->()->report_images([
				{ image => 'perl:5.40', source => 'job a', status => 'present' },
				{ image => '', expression => '${{ matrix.image }}', status => 'deferred', error => 'matrix.image is not known' },
				{ status => 'missing' },
			]);
		});
		like($text, qr/perl:5\.40/, 'an image by name');
		like($text, qr/\$\{\{ matrix\.image \}\}/, 'an empty name falls back to the expression');
		like($text, qr/matrix\.image is not known/, 'and a deferred image says why');
		is(scalar(() = $text =~ /\n/g), 4, 'one line per image, plus the reason');
		is($printed->(sub { $report->()->report_images([]) }), '', 'nothing to report');
	};

	subtest 'keep_logs and print_kept_logs' => sub {
		my $source = tempdir(CLEANUP => 1);
		my $log = write_file('slot.log', "output\n", $source);
		my $root = tempdir(CLEANUP => 1);
		my @logs = ({ name => 'build', file => 'job-1-build.log', path => $log }, { name => 'gone', file => 'job-2.log', path => "$log.none" });
		my $object = $report->();
		is($object->keep_logs(\@logs, $root, 'abc'), $object, 'returns the object');
		like($object->{kept_dir}, qr/\Q$root\E.\d{8}-\d{6}-abc\z/, 'a directory named after the time and the run');
		is((stat $object->{kept_dir})[2] & oct('0777'), oct('0700'), 'private');
		my $copy = File::Spec->catfile($object->{kept_dir}, 'job-1-build.log');
		ok(-f $copy, 'the log is copied');
		is((stat $copy)[2] & oct('0777'), oct('0600'), 'and private too');
		is_deeply([ map { $_->{name} } @{ $object->{kept_logs} } ], [ 'build' ], 'a log that is not there is skipped');
		like($printed->(sub { $object->print_kept_logs }), qr/^  build  job-1-build\.log$/m, 'and the kept logs are listed');
		is($printed->(sub { $report->()->print_kept_logs }), '', 'nothing kept, nothing printed');

		my $quiet = $report->(quiet => 1)->keep_logs([ { %{ $logs[0] } } ], $root, 'q');
		ok(defined $quiet->{kept_dir}, 'a quiet run keeps its logs');
		is($printed->(sub { $quiet->print_kept_logs }), '', 'but does not say so');

		$object = $report->()->keep_logs([], $root, 'none');
		is($object->{kept_dir}, undef, 'no logs, no directory');

		# Names that would put a copy somewhere else are refused, and nothing
		# is created for them.
		for my $bad ('../escape.log', '..', '.', 'a/b.log', '', undef) {
			my $label = defined $bad ? "'$bad'" : 'undef';
			my $target = tempdir(CLEANUP => 1);
			$object = $report->()->keep_logs([ { name => 'x', file => $bad, path => $log } ], $target, 'r');
			is($object->{kept_dir}, undef, "a file name of $label is refused");
			my $shown = defined $bad ? $bad : '';
			is_deeply($object->{logger}{lines}, [ [ warn => "action-run: could not keep the job logs: '$shown' is not a plain file name" ] ],
				"with a warning for $label");
			opendir my $dh, $target or die $!;
			is_deeply([ grep { !/\A\.\.?\z/ } readdir $dh ], [], "and nothing is made for $label");
		}
		$object = $report->()->keep_logs([ { %{ $logs[0] } } ], $root, '../up');
		like($object->{logger}{lines}[0][1], qr/'\.\.\/up' is not a plain file name/, 'a run identifier that climbs is refused too');

		# A copy that fails mid-flight is a warning, not a failed run.
		my $guard = mock_scoped('App::Actions::Runner::Report::copy' => sub { $! = 28; return 0 });
		$object = $report->()->keep_logs([ { %{ $logs[0] } } ], $root, 'full');
		is($object->{kept_dir}, undef, 'a copy that fails keeps nothing');
		local $! = 28;
		like($object->{logger}{lines}[0][1], qr/\Aaction-run: could not keep the job logs: cannot copy '\Q$log\E' to '.+job-1-build\.log': \Q$!\E\z/,
			'and says which copy and why');
		is($object->failed, 0, 'and the run has not failed');
	};

	subtest 'print_kept_resources' => sub {
		my $object = $report->();
		my $text = $printed->(sub { $object->print_kept_resources({ containers => [ 'c1' ], networks => [ 'n1' ] }, '/tmp/x') });
		like($text, qr/c1/, 'a container');
		like($text, qr/n1/, 'a network');
		like($text, qr{/tmp/x}, 'the temporary directory');
		my $quiet = $printed->(sub { $report->(quiet => 1)->print_kept_resources({ containers => [ 'c1' ] }) });
		like($quiet, qr/c1/, 'a quiet run still lists what is left behind');
		is(scalar(() = $quiet =~ /\n/g), 1, 'without the heading');
		is($printed->(sub { $object->print_kept_resources({}, undef) }), '', 'nothing left behind');
		is($printed->(sub { $object->print_kept_resources({ containers => undef }, '') }), '', 'even when the lists are undef');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Parallel
# ---------------------------------------------------------------------------

use App::Actions::Runner::Parallel;

# An exception that is false, as $@ can be when a destructor clears it.
{
	package Local::FalseError;
	use overload 'bool' => sub { 0 }, '""' => sub { '' }, fallback => 1;
	sub new { return bless {}, shift }
}

subtest 'App::Actions::Runner::Parallel' => sub {
	# Each test gets its own temporary directory, as a run does.
	my $parallel = sub {
		my (%options) = @_;
		return App::Actions::Runner::Parallel->new(
			capacity => 4,
			temp_path => tempdir(CLEANUP => 1),
			run_job => sub { return { result => 'success' } },
			quiet => 1,
			logger => Local::Logger->new,
			%options,
		);
	};
	my $plans = sub { return [ map { { display_name => "job $_" } } @_ ] };

	# What the parent prints, captured from the selected handle.
	my $printed = sub {
		my ($code) = @_;
		my $text = '';
		open my $handle, '>', \$text or die $!;
		my $old = select $handle;
		my $ok = eval { $code->(); 1 };
		my $error = $@;
		select $old;
		close $handle;
		die $error unless $ok;
		return $text;
	};

	subtest 'new and logs' => sub {
		my $object = $parallel->();
		is_deeply([ $object->{slots}, $object->logs ], [ 0, [] ], 'nothing started');
		is(ref $object->{on_result}, 'CODE', 'a result callback that does nothing by default');
		memory_cycle_ok($object, 'no reference cycle');
		my $prefix = 'Invalid arguments to App::Actions::Runner::Parallel::new: ';
		throws_ok { App::Actions::Runner::Parallel->new(temp_path => '/t', run_job => sub { }) }
			qr/\A\Q${prefix}Required parameter 'capacity' is missing\E at /, 'a capacity is required';
		throws_ok { $parallel->(capacity => 0) } qr/\A\Q$prefix\E.*'capacity'/, 'and must be at least one';
		throws_ok { $parallel->(run_job => 'code') } qr/\A\Q$prefix\E.*'run_job'/, 'run_job must be code';
		throws_ok { $parallel->(temp_path => '') } qr/\A\Q$prefix\E.*'temp_path'/, 'an empty temporary path';
	};

	subtest '_capacity' => sub {
		my $object = $parallel->(capacity => 3);
		is($object->_capacity([]), 0, 'no plans');
		is($object->_capacity($plans->(1 .. 2)), 2, 'never more than there are plans');
		is($object->_capacity($plans->(1 .. 5)), 3, 'the configured capacity');
		my %max = (2 => 2, '9' => 3, '0' => 3, '-1' => 3, '1.5' => 3, ' 2' => 3, '02' => 3, abc => 3);
		for my $max (sort keys %max) {
			my $group = [ map { { display_name => $_, max_parallel => $max } } 1 .. 5 ];
			is($object->_capacity($group), $max{$max}, "max-parallel '$max'");
		}
		is($object->_capacity([ map { { max_parallel => [ 1 ] } } 1 .. 5 ]), 3, 'a structure is not a number');
	};

	subtest 'run' => sub {
		is($parallel->()->run($plans->(1)), undef, 'one job is run serially');
		is($parallel->(capacity => 1)->run($plans->(1, 2)), undef, 'so is a capacity of one');
		is($parallel->()->run([]), undef, 'and no jobs at all');

		my @seen;
		my $object = $parallel->(
			run_job => sub { my ($entry) = @_; print "hello from $entry->{plan}{display_name}\n"; return { result => 'success', job => $entry->{plan}{display_name} } },
			on_result => sub { push @seen, $_[0]{job} },
		);
		my $outcomes = $object->run($plans->(1 .. 3));
		is_deeply([ map { $_->{result}{job} } @{$outcomes} ], [ 'job 1', 'job 2', 'job 3' ], 'every result, in plan order');
		is_deeply([ sort @seen ], [ 'job 1', 'job 2', 'job 3' ], 'each passed to on_result in the parent');
		is_deeply([ map { $_->{file} } @{ $object->logs } ], [ 'job-1-job_1.log', 'job-2-job_2.log', 'job-3-job_3.log' ], 'a log per job');
		like(do { open my $h, '<', $object->logs->[0]{path} or die $!; local $/; <$h> }, qr/\Ahello from job 1\n\z/, 'holding its output');
		memory_cycle_ok($outcomes, 'the outcomes hold no cycle');

		# fail_fast stops jobs that have not started; with two slots the
		# third waits, and the first failure stops it.
		$object = $parallel->(capacity => 2, run_job => sub { return { result => 'failure' } });
		$outcomes = $object->run($plans->(1 .. 3), 1);
		is_deeply([ map { $_->{started} } @{$outcomes} ], [ 1, 1, 0 ], 'fail-fast leaves a waiting job unstarted');
		$outcomes = $parallel->(capacity => 2, run_job => sub { return { result => 'failure' } })->run($plans->(1 .. 3), 0);
		is_deeply([ map { $_->{started} } @{$outcomes} ], [ 1, 1, 1 ], 'without it, every job runs');
		$outcomes = $parallel->(capacity => 2, run_job => sub { return { status => 'odd' } })->run($plans->(1 .. 3), 1);
		is(scalar(grep { $_->{started} } @{$outcomes}), 3, 'a result with no verdict is not a failure');

		# A job's plain print belongs in its log even when the caller has
		# selected another handle for its own output.
		$object = $parallel->(run_job => sub { print "to the log\n"; return { result => 'success' } });
		my $leaked = $printed->(sub { $object->run($plans->(1, 2)) });
		is($leaked, '', 'nothing a job printed reaches the caller\'s selected handle');
		is(do { open my $h, '<', $object->logs->[0]{path} or die $!; local $/; <$h> }, "to the log\n", 'it is in the log');

		# A job that dies leaves no result: the group fails, naming it.  The
		# default logger writes the reason to standard error, which is the log.
		$object = $parallel->(logger => App::Actions::Runner::Support::default_logger(),
			run_job => sub { die "exploded\n" if $_[0]{plan}{display_name} eq 'job 2'; return { result => 'success' } });
		throws_ok { $object->run($plans->(1, 2)) } qr/\Ajob 'job 2' did not run$/, 'a job that dies fails the group';
		like(do { open my $h, '<', $object->logs->[1]{path} or die $!; local $/; <$h> }, qr/^action-run: exploded$/m,
			'and its log says why');

		# A child that exits without writing anything is the same.
		throws_ok { $parallel->(run_job => sub { POSIX::_exit(0) })->run($plans->(1, 2)) } qr/\Ajob 'job \d' did not run$/,
			'a child that vanishes';
		throws_ok { $parallel->(temp_path => File::Spec->catdir(tempdir(CLEANUP => 1), 'gone'))->run($plans->(1, 2)) }
			qr/\Ajob 'job \d' did not run$/, 'a child that cannot open its log';

		# Children the system reaps by itself (SIGCHLD ignored) are still
		# collected, not dropped from the results.
		{
			local $SIG{CHLD} = 'IGNORE';
			my $outcomes = $parallel->()->run($plans->(1 .. 3));
			is(scalar(grep { $_->{result} } @{$outcomes}), 3, 'auto-reaped children are still collected');
		}

		# An error in the parent kills what is still running before it
		# propagates, so no job carries on behind the report.
		my $marker = File::Spec->catfile(tempdir(CLEANUP => 1), 'late');
		$object = $parallel->(run_job => sub { sleep 3; open my $h, '>', $marker or die; close $h; return { result => 'success' } });
		my $guard = mock_scoped('App::Actions::Runner::Parallel::_watch' => sub { die "interrupted\n" });
		my $started = time;
		throws_ok { $object->run($plans->(1, 2)) } qr/\Ainterrupted$/, 'an interruption propagates';
		ok(time - $started < 3, 'without waiting for the jobs');
		sleep 1 while time - $started < 4;
		ok(!-e $marker, 'which were killed');
	};

	subtest '_run_here' => sub {
		# fork() can fail (too many processes); the job then runs in this
		# process, its output still going to its own log.  fork itself is
		# compiled in and cannot be mocked, so the fallback is called directly.
		my $dir = tempdir(CLEANUP => 1);
		my $entry = { plan => { display_name => 'here' }, log => File::Spec->catfile($dir, 'job.log'),
			result_path => File::Spec->catfile($dir, 'job.json'), shown => 0, pending => '' };
		my $object = $parallel->(run_job => sub { print "inline\n"; print STDERR "to stderr\n"; return { result => 'success', pid => $$ } });
		my ($out_before, $err_before) = (fileno(STDOUT), fileno(STDERR));
		my $text = $printed->(sub { $object->_run_here($entry) });
		is($entry->{result}{pid}, $$, 'the job ran here');
		is(App::Actions::Runner::Parallel::_read_from($entry->{log}, 0), "inline\nto stderr\n", 'into its log');
		is_deeply([ fileno(STDOUT), fileno(STDERR) ], [ $out_before, $err_before ], 'and STDOUT and STDERR are put back');
		is($text, '', 'nothing reached the caller\'s selected handle');

		my $unwritable = { %{$entry}, log => File::Spec->catfile($dir, 'no', 'job.log') };
		my $error = throws_code(sub { $object->_run_here($unwritable) }, 'runner.file_write_failed', undef,
			'a log that cannot be opened is refused');
		like($error->message, qr/\AUnable to write '\Q$unwritable->{log}\E': /, 'naming it');
		is(fileno(STDOUT), $out_before, 'and STDOUT is still standard output');
	};

	subtest '_note_missing' => sub {
		my $object = $parallel->();
		my $group = { stopping => 0, error => undef };
		$object->_note_missing($group, { result => { result => 'success' }, plan => { display_name => 'a' } });
		is_deeply($group, { stopping => 0, error => undef }, 'a job with a result is fine');
		$object->_note_missing($group, { plan => { display_name => 'b' } });
		is_deeply($group, { stopping => 1, error => "job 'b' did not run\n" }, 'one without stops the group');
		$object->_note_missing($group, { plan => { display_name => 'c' } });
		is($group->{error}, "job 'b' did not run\n", 'the first error is kept');
	};

	subtest '_run_job and _write_result' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $entry = { plan => { display_name => 'x' }, result_path => File::Spec->catfile($dir, 'r.json') };
		is($parallel->(run_job => sub { { result => 'success', b => 1, a => 2 } })->_run_job($entry), 0, 'a result written is 0');
		is(App::Actions::Runner::Parallel::_read_from($entry->{result_path}, 0), '{"a":2,"b":1,"result":"success"}', 'as canonical JSON');

		my $object = $parallel->(run_job => sub { die "boom\n" });
		is($object->_run_job($entry), 1, 'a job that dies is 1');
		is_deeply($object->{logger}{lines}, [ [ error => 'action-run: boom' ] ], 'and is logged as an error');
		$object = $parallel->(run_job => sub { die "\n" });
		$object->_run_job($entry);
		is_deeply($object->{logger}{lines}, [ [ error => 'action-run: ' ] ], 'an empty error is still logged');
		# die '' becomes "Died at ...", so the only error with nothing to say
		# is one that is false: an object whose overloading makes it so.
		$object = $parallel->(run_job => sub { die Local::FalseError->new });
		$object->_run_job($entry);
		is($object->{logger}{lines}[0][1], "action-run: job 'x' did not run", 'an error that is false names the job');

		throws_code(sub { $parallel->()->_write_result(File::Spec->catfile($dir, 'no', 'r.json'), {}) }, 'runner.file_write_failed',
			undef, 'a result that cannot be written');
		throws_ok { $parallel->()->_write_result(File::Spec->catfile($dir, 'x.json'), { code => sub { } }) } qr/encountered CODE/,
			'a result that is not data';
	};

	subtest '_stream and _collect' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $log = write_file('job.log', "one\r\n\ntwo\npart", $dir);
		my $entry = { plan => { display_name => 'build' }, log => $log, shown => 0, pending => '', result_path => undef };
		my $object = $parallel->(quiet => 0);
		is($printed->(sub { $object->_stream($entry) }), "[build] one\n\n[build] two\n", 'whole lines, named; a blank line stays blank');
		is($entry->{pending}, 'part', 'a partial line waits');
		is($printed->(sub { $object->_stream($entry) }), '', 'nothing new, nothing printed');
		open my $h, '>>', $log or die $!;
		print {$h} "ial\n";
		close $h;
		is($printed->(sub { $object->_stream($entry) }), "[build] partial\n", 'and is finished when the rest arrives');
		is($printed->(sub { $parallel->()->_stream({ %{$entry}, shown => 0 }) }), '', 'quiet shows nothing');

		my @results;
		$object = $parallel->(quiet => 0, on_result => sub { push @results, $_[0] });
		$entry = { plan => { display_name => undef }, log => write_file('j.log', 'last', $dir), shown => 0, pending => '',
			result_path => write_file('r.json', '{"result":"success"}', $dir) };
		is($printed->(sub { $object->_collect($entry) }), "[] last\n", 'a last line without a newline is shown');
		is_deeply([ $entry->{result}, \@results ], [ { result => 'success' }, [ { result => 'success' } ] ], 'and the result read');

		for my $case ([ 'not JSON', '{oops' ], [ 'JSON that is not an object', '[1]' ], [ 'an empty file', '' ]) {
			my $bad = { plan => {}, log => $log, shown => -s $log, pending => '', result_path => write_file('bad.json', $case->[1], $dir) };
			$parallel->()->_collect($bad);
			ok(!exists $bad->{result}, "$case->[0] is no result");
		}
		my $none = { plan => {}, log => $log, shown => -s $log, pending => '', result_path => File::Spec->catfile($dir, 'none') };
		$parallel->()->_collect($none);
		ok(!exists $none->{result}, 'nor is a missing file');

		my $guard = mock_scoped('App::Actions::Runner::Parallel::_read_from' => sub { return $_[1] ? undef : undef });
		throws_code(sub { $parallel->()->_collect({ plan => {}, log => $log, shown => 0, pending => '', result_path => $entry->{result_path} }) },
			'runner.file_read_failed', undef, 'a result that is there but cannot be read');
	};

	subtest '_read_from' => sub {
		my $file = write_file('f', 'abcdef');
		is(App::Actions::Runner::Parallel::_read_from($file, 0), 'abcdef', 'from the start');
		is(App::Actions::Runner::Parallel::_read_from($file, 4), 'ef', 'from an offset');
		is(App::Actions::Runner::Parallel::_read_from($file, 6), '', 'at the end');
		is(App::Actions::Runner::Parallel::_read_from(undef, 0), undef, 'no path');
		is(App::Actions::Runner::Parallel::_read_from("$file.none", 0), undef, 'a missing file');
		is(App::Actions::Runner::Parallel::_read_from(tempdir(CLEANUP => 1), 0), undef, 'a directory');
		is(App::Actions::Runner::Parallel::_read_from(write_file('u', "\x{e9}"), 0), "\x{e9}", 'bytes, not characters');
	};

	subtest '_log_name and _prefix' => sub {
		my %names = (
			'build' => 'job-1-build.log',
			'test (ubuntu, 5.40)' => 'job-1-test_ubuntu_5.40.log',
			'../../etc/passwd' => 'job-1-etc_passwd.log',
			'...' => 'job-1.log',
			'' => 'job-1.log',
			"\x{263a} smile" => 'job-1-smile.log',
			('a' x 59) . '_b' => 'job-1-' . ('a' x 59) . '.log',
			('x' x 100) => 'job-1-' . ('x' x 60) . '.log',
		);
		is(App::Actions::Runner::Parallel::_log_name(1, $_), $names{$_}, /[^\x00-\x7f]/ ? 'a name with a non-ASCII character' : "'$_'")
			for sort keys %names;
		is(App::Actions::Runner::Parallel::_log_name(2, undef), 'job-2.log', 'undef');
		keeps_topic(sub { App::Actions::Runner::Parallel::_log_name(1, 'x y') }, '_log_name');

		my $started = time;
		App::Actions::Runner::Parallel::_log_name(1, '_' x $config{big} . 'x' . '-' x $config{big});
		ok(time - $started <= $config{time_limit}, 'a name made of separators is linear');

		is(App::Actions::Runner::Parallel::_prefix({ plan => { display_name => 'a b' } }), '[a b] ', '_prefix');
		is(App::Actions::Runner::Parallel::_prefix({ plan => {} }), '[] ', 'with no name');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Images
# ---------------------------------------------------------------------------

use App::Actions::Runner::Images;

# A Docker client that knows a fixed set of images and records every pull.
# Without pull_many it is the "caller's own object" the module must cope with.
{
	package Local::ImageDocker;
	sub new { my ($class, %option) = @_; return bless { present => {}, pulls => [], fail => {}, %option }, $class }
	sub image_exists { my ($self, $image) = @_; return $self->{present}{$image} ? 1 : 0 }
	sub pull {
		my ($self, $image) = @_;
		push @{ $self->{pulls} }, $image;
		die "pull of $image refused\n" if $self->{fail}{$image};
		$self->{present}{$image} = 1;
		return 1;
	}

	package Local::ManyDocker;
	our @ISA = ('Local::ImageDocker');
	sub pull_many {
		my ($self, $images, %option) = @_;
		$self->{many} = [ $images, \%option ];
		return $self->{answer} ? $self->{answer}->($images) : { map { $_ => ($self->{fail}{$_} ? 1 : 0) } @{$images} };
	}
}

subtest 'App::Actions::Runner::Images' => sub {
	my $project = tempdir(CLEANUP => 1);
	my $workflow = App::Actions::Workflow->load(write_file('ci.yml', "on: push\njobs:\n  a:\n    runs-on: ubuntu-latest\n    steps: [{run: x}]\n"));
	my $expression = App::Actions::Expression->new;
	my $images = sub {
		my (%option) = @_;
		return App::Actions::Runner::Images->new(
			docker => Local::ImageDocker->new,
			expression => $expression,
			workflow => $workflow,
			project_dir => $project,
			context => sub { return { matrix => $_[0]{matrix} || {}, github => {}, env => {} } },
			quiet => 1,
			logger => Local::Logger->new,
			%option,
		);
	};
	my $job = sub { my (%job) = @_; return { base_id => 'a', display_name => 'a', 'runs-on' => 'ubuntu-latest', steps => [], %job } };

	# A local action whose image comes from its input, used through a
	# composite that passes the input on.
	my $action = sub {
		my ($dir, $yaml) = @_;
		my $path = File::Spec->catdir($project, split m{/}, $dir);
		require File::Path;
		File::Path::make_path($path);
		write_file('action.yml', $yaml, $path);
		return "./$dir";
	};
	$action->('actions/inner', "name: inner\ninputs:\n  image: {default: 'alpine:1'}\nruns:\n  using: composite\n  steps:\n    - uses: docker://\${{ inputs.image }}\n");
	$action->('actions/outer', "name: outer\nruns:\n  using: composite\n  steps:\n    - uses: ./actions/inner\n      with: {image: 'busybox:2'}\n");
	$action->('actions/loop', "name: loop\nruns:\n  using: composite\n  steps:\n    - uses: ./actions/loop\n    - uses: docker://loop:1\n");

	subtest 'new and concurrency' => sub {
		my $object = $images->();
		is($object->concurrency, $^O eq 'MSWin32' ? 1 : 4, 'four pulls at once by default');
		is($images->(pull_concurrency => 9)->concurrency, $^O eq 'MSWin32' ? 1 : 9, 'or as configured');
		{
			local $^O = 'MSWin32';
			is($images->(pull_concurrency => 9)->concurrency, 1, 'one at a time where fork is emulated');
		}
		is_deeply([ $object->{pulled}, $object->{pulled_once} ], [ {}, {} ], 'nothing pulled yet');
		memory_cycle_ok($object, 'no reference cycle');

		my $prefix = 'Invalid arguments to App::Actions::Runner::Images::new: ';
		throws_ok { $images->(docker => Local::Logger->new) } qr/\A\Q${prefix}Parameter 'docker' must be an object that understands the image_exists method\E at /,
			'a Docker client must be able to look for an image';
		throws_ok { $images->(project_dir => '') } qr/\A\Q$prefix\E.*'project_dir'/, 'an empty project directory';
		throws_ok { $images->(pull_concurrency => 0) } qr/\A\Q$prefix\E.*'pull_concurrency'/, 'a concurrency of 0';
		throws_ok { $images->(context => {}) } qr/\A\Q$prefix\E.*'context'/, 'a context that is not code';
	};

	subtest 'job_expressions' => sub {
		my $object = $images->();
		my $entries = $object->job_expressions($job->(
			services => { z => { image => 'redis:7' }, a => 'postgres:16', none => { image => '' } },
			steps => [ { uses => 'docker://perl:5.40' }, { uses => './actions/outer' }, { run => 'echo' }, { uses => 'actions/checkout@v4' } ],
		), 'ubuntu-latest', { github => {} });
		is_deeply([ map { $_->{expression} } @{$entries} ], [ 'ubuntu:latest', 'postgres:16', 'redis:7', 'perl:5.40', 'busybox:2' ],
			'the job, its services in name order, then its steps, through nested actions');
		is_deeply([ map { $_->{kind} } @{$entries}[0 .. 2] ], [ 'job', 'service:a', 'service:z' ], 'with what each is for');
		is($entries->[4]{source}, "action 'docker://\${{ inputs.image }}' in local action './actions/inner' of job 'a'", 'a nested action names its way in');
		is($entries->[3]{source}, "action 'docker://perl:5.40' in job 'a'", 'a top-level one does not');

		my $self_using = $object->job_expressions($job->(steps => [ { uses => './actions/loop' } ]), 'ubuntu-latest', {});
		is_deeply([ map { $_->{expression} } @{$self_using} ], [ 'ubuntu:latest', 'loop:1' ], 'an action that uses itself is walked once');

		my $hostile = $object->job_expressions($job->(steps => [ { uses => '../../outside' }, { uses => './missing' }, { uses => './' } ]), 'ubuntu-latest', {});
		is(scalar @{$hostile}, 1, 'actions outside the project, missing or empty are skipped, not fatal');

		my $deferred = $object->job_expressions($job->(steps => [ { uses => 'docker://${{ steps.x.outputs.image }}' } ]), 'ubuntu-latest', {});
		is($deferred->[1]{expression}, '${{ steps.x.outputs.image }}', 'a value only the job will know is kept as written');

		my $plain = $object->job_expressions($job->(container => { options => '--cpus 1' }), 'ubuntu-latest', {});
		is_deeply([ map { $_->{expression} } @{$plain} ], [ 'ubuntu:latest' ], 'a container without an image runs in the runner\'s');
		my $broken = $object->job_expressions($job->(container => { image => '${{ unclosed' }), 'ubuntu-latest', {});
		is_deeply($broken, [], 'an image that cannot be read names nothing here (the run reports it)');
	};

	subtest 'required' => sub {
		my $object = $images->();
		my $entries = $object->required([
			$job->(),
			$job->(display_name => 'b', steps => [ { uses => 'docker://ubuntu:latest' } ]),
			$job->(display_name => 'w', 'runs-on' => 'windows-latest'),
			$job->(display_name => 'c', steps => [ { uses => 'docker://${{ steps.x.outputs.image }}' } ]),
			$job->(display_name => 'c', steps => [ { uses => 'docker://${{ steps.x.outputs.image }}' } ]),
			$job->(display_name => 'm', matrix => { tag => '' }, container => { image => 'img:${{ matrix.tag }}' }),
		]);
		is_deeply([ map { $_->{image} } grep { defined $_->{image} } @{$entries} ], [ 'ubuntu:latest', 'img:' ],
			'an image named twice is listed once; a non-Linux job adds nothing');
		my @unresolved = grep { !defined $_->{image} } @{$entries};
		is(scalar @unresolved, 1, 'an unresolved expression is listed once per source');
		like($unresolved[0]{error}, qr/unable to resolve/, 'with why');
		is_deeply($object->required([]), [], 'no jobs');
	};

	subtest '_resolve_strictly' => sub {
		my $object = $images->();
		is_deeply([ $object->_resolve_strictly('perl:${{ matrix.v }}', { matrix => { v => 5 } }) ], [ 'perl:5', undef ], 'a name');
		my ($image, $error) = $object->_resolve_strictly('${{ matrix.none }}', { matrix => {} });
		is($image, undef, 'an unknown value is not a name');
		is($error, q{unable to resolve '${{ matrix.none }}' from the values available}, 'and says so');
		is_deeply([ $object->_resolve_strictly('${{ matrix.v }}', { matrix => { v => '' } }) ], [ undef, 'the image name is empty' ],
			'an empty name is refused');
		($image, $error) = $object->_resolve_strictly('${{ (( }}', {});
		like($error, qr/\A\S/, 'a broken expression gives its error');
	};

	subtest 'prepare and _initial_record' => sub {
		my $object = $images->(docker => Local::ManyDocker->new(present => { 'ubuntu:latest' => 1 }));
		my $result = $object->prepare([ $job->(services => { db => 'postgres:16' }) ]);
		is_deeply([ map { [ $_->{image}, $_->{status} ] } @{ $result->{records} } ], [ [ 'ubuntu:latest', 'present' ], [ 'postgres:16', 'pulled' ] ],
			'a present image is used, a missing one pulled');
		is_deeply($result->{failures}, [], 'nothing failed');
		is_deeply($object->pulled, [ 'postgres:16' ], 'and the pulled one is remembered');
		is_deeply($object->{docker}{many}, [ [ 'postgres:16' ], { concurrency => $object->concurrency } ], 'all at once, at the concurrency');
		ok(!grep({ exists $_->{present} } @{ $result->{records} }), 'the working field is removed');

		$object = $images->(docker => Local::ManyDocker->new(present => { 'ubuntu:latest' => 1 }), pull => 1);
		$result = $object->prepare([ $job->() ], quiet => 1);
		is($result->{records}[0]{status}, 'pulled', '--pull refreshes a present image');
		is_deeply($object->pulled, [], 'but it was there before, so it is not removed later');
		is($object->{docker}{many}[1]{quiet}, 1, 'and a quiet prepare pulls quietly');

		$object = $images->(no_pull => 1);
		$result = $object->prepare([ $job->() ]);
		is_deeply([ map { $_->{status} } @{ $result->{failures} } ], [ 'failed' ], '--no-pull fails a missing image');
		is($result->{failures}[0]{error}, "Docker image 'ubuntu:latest' is not available locally (--no-pull)", 'with advice');
		is_deeply($object->{docker}{pulls}, [], 'before anything is pulled');

		$object = $images->(docker => Local::ManyDocker->new(fail => { 'ubuntu:latest' => 1 }));
		$result = $object->prepare([ $job->() ]);
		is($result->{failures}[0]{error}, "Failed to pull Docker image 'ubuntu:latest' (exit 1)", 'a pull that fails');

		# A client of the caller's that leaves an image out of its answer has
		# not shown that it arrived.
		$object = $images->(docker => Local::ManyDocker->new(answer => sub { {} }));
		$result = $object->prepare([ $job->() ]);
		is($result->{failures}[0]{error}, "Failed to pull Docker image 'ubuntu:latest' (exit -1)", 'a missing status is a failure');
		is_deeply($object->pulled, [], 'and nothing is recorded as pulled');

		# Without pull_many, images are pulled one by one and a pull that
		# dies keeps its own message.
		$object = $images->(docker => Local::ImageDocker->new(fail => { 'postgres:16' => 1 }));
		$result = $object->prepare([ $job->(services => { db => 'postgres:16' }) ]);
		is_deeply($object->{docker}{pulls}, [ 'ubuntu:latest', 'postgres:16' ], 'one at a time');
		is($result->{failures}[0]{error}, 'pull of postgres:16 refused', 'a pull that dies says why');
		is_deeply($object->pulled, [ 'ubuntu:latest' ], 'and what did arrive is still recorded for cleanup');

		$result = $images->(dry_run => 1)->prepare([ $job->() ]);
		is($result->{records}[0]{status}, 'present', 'a dry run assumes every image is there');

		my $deferred = $images->()->_initial_record({ image => undef, expression => '${{ x }}', source => 's', error => 'e' }, 0);
		is_deeply($deferred, { image => undef, expression => '${{ x }}', source => 's', status => 'deferred', error => 'e' }, 'a deferred record');

		my $prefix = 'Invalid arguments to App::Actions::Runner::Images::prepare: ';
		throws_ok { $images->()->prepare('jobs') } qr/\A\Q$prefix\E.*'instances'/, 'instances must be a list';
		throws_ok { $images->()->prepare([], loud => 1) } qr/\A\Q${prefix}Unknown parameter 'loud'\E/, 'an unknown option';
	};

	subtest 'prepare_job and ensure' => sub {
		my $object = $images->();
		my $prepared = $object->prepare_job($job->(steps => [ { uses => 'docker://perl:5.40' }, { uses => 'docker://perl:5.40' },
			{ uses => 'docker://${{ steps.x.outputs.image }}' } ]), { github => {} });
		is($prepared->{image}, 'ubuntu:latest', 'the job image');
		is_deeply($object->{docker}{pulls}, [ 'ubuntu:latest', 'perl:5.40' ], 'each image prepared once');
		is_deeply([ map { $_->{expression} } @{ $prepared->{deferred} } ], [ '${{ steps.x.outputs.image }}' ], 'a step image is deferred');

		throws_code(sub { $object->prepare_job($job->(container => { image => '${{ github.none }}' }), { github => {} }) }, 'runner.image.unresolved',
			q{cannot resolve the image '${{ github.none }}', needed by job 'a': unable to resolve '${{ github.none }}' from the values available},
			'a job image that cannot be named is an error before anything runs');
		throws_code(sub { $object->prepare_job($job->(services => { db => '${{ env.DB }}' }), { env => {} }) }, 'runner.image.unresolved',
			undef, 'so is a service image');
		my $refusing = $images->(docker => Local::ImageDocker->new(fail => { 'ubuntu:latest' => 1 }));
		throws_code(sub { $refusing->prepare_job($job->(), {}) }, 'runner.image.unprepared',
			q{cannot prepare the image 'ubuntu:latest', needed by job 'a': pull of ubuntu:latest refused}, 'a pull that fails names the image');

		$object = $images->(docker => Local::ImageDocker->new(present => { 'x:1' => 1 }));
		is($object->ensure('x:1'), 1, 'a present image');
		is_deeply($object->{docker}{pulls}, [], 'is not pulled');
		$object->ensure('y:1');
		$object->ensure('y:1');
		is_deeply($object->{docker}{pulls}, [ 'y:1' ], 'a missing one is pulled once per run');
		$object = $images->(docker => Local::ImageDocker->new(present => { 'x:1' => 1 }), pull => 1);
		$object->ensure('x:1');
		is_deeply([ $object->{docker}{pulls}, $object->pulled ], [ [ 'x:1' ], [] ], '--pull refreshes, without marking it for removal');
		throws_code(sub { $images->(no_pull => 1)->ensure('z:1') }, 'runner.image.not_local',
			"Docker image 'z:1' is not available locally (--no-pull)", '--no-pull refuses a missing image');
		$object = $images->(dry_run => 1);
		is($object->ensure('z:1'), 1, 'a dry run does nothing');
		is_deeply($object->{docker}{pulls}, [], 'and pulls nothing');
	};

	subtest 'probe' => sub {
		is($images->()->probe([ $job->() ]), 'ubuntu:latest', 'the first Linux job\'s image');
		is($images->()->probe([ $job->('runs-on' => 'windows-latest') ]), 'alpine:3.20', 'none: the default probe image');
		is($images->(image => 'mine:1')->probe([]), 'mine:1', 'or the configured image');
		is($images->()->probe([ $job->(container => { image => '${{ steps.a.outputs.i }}' }), $job->(container => { image => 'second:1' }) ]),
			'second:1', 'an image only a step can name is passed over');
		my $context = sub { { github => { repository => 'o/r' } } };
		is($images->(context => $context)->probe([ $job->(container => { image => 'ghcr.io/${{ github.repository }}:1' }) ]), 'ghcr.io/o/r:1',
			'github values known before the run are filled in');
	};

	subtest 'note_pulled, pulled and remember' => sub {
		my $object = $images->();
		is($object->note_pulled('b:1', undef, '', 'a:1'), $object, 'note_pulled returns the object');
		is_deeply($object->pulled, [ 'a:1', 'b:1' ], 'empty names are ignored; the list is sorted');

		my @remembered;
		my $guard = mock_scoped('App::Actions::Cache::remember' => sub { shift; push @remembered, @_; 1 });
		my $cache = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
		is($object->remember($cache), $object, 'remember returns the object');
		is_deeply(\@remembered, [ 'a:1', 'b:1' ], 'and records every pulled image');
		@remembered = ();
		$images->()->remember($cache);
		$images->(dry_run => 1)->note_pulled('c:1')->remember($cache);
		is_deeply(\@remembered, [], 'nothing pulled, or a dry run, records nothing');
		undef $guard;

		$guard = mock_scoped('App::Actions::Cache::remember' => sub { die "disk full\n" });
		$object = $images->(verbose => 1)->note_pulled('a:1');
		$object->remember($cache);
		is_deeply($object->{logger}{lines}, [ [ warn => 'action-run: could not update the image cache: disk full' ] ], 'a failure warns when verbose');
		$object = $images->()->note_pulled('a:1');
		$object->remember($cache);
		is_deeply($object->{logger}{lines}, [], 'and is quiet otherwise');
	};

	subtest 'failure_message' => sub {
		is($images->()->failure_message({ image => 'i', source => "job 'a'", error => 'e' }), "cannot prepare the image 'i', needed by job 'a': e",
			'the message for a failed record');
	};

	subtest '_collect_action_images' => sub {
		my @found;
		my $add = sub { push @found, $_[0] };
		my $object = $images->();
		$object->_collect_action_images('./actions/inner', {}, 'a', {}, $add, {}, 10);
		is_deeply(\@found, [], 'nothing below the depth limit');
		$object->_collect_action_images('./actions/inner', {}, 'a', {}, $add, { 'actions/inner' => 1 }, 0);
		is_deeply(\@found, [], 'nor an action already on the path');
		$object->_collect_action_images('./actions/inner', {}, 'a', {}, $add, {}, 0);
		is_deeply(\@found, [ 'alpine:1' ], 'an input\'s default names the image');
		my $docker = $action->('actions/docker', "name: d\nruns:\n  using: docker\n  image: Dockerfile\n");
		@found = ();
		$object->_collect_action_images($docker, {}, 'a', {}, $add, {}, 0);
		is_deeply(\@found, [], 'a Docker action is not a composite');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Containers
# ---------------------------------------------------------------------------

use App::Actions::Runner::Containers;

# A daemon whose answers a test sets, recording each request in order.
{
	package Local::ContainerDocker;
	sub new {
		my ($class, %answer) = @_;
		return bless {
			calls => [],
			start => 0, captured => [ '', 0 ], running => 1, status => 'running', restarts => 0, exit => 0, log => '',
			network => 0, run => 0, has => { bash => 1 }, path => [ '/usr/bin:/bin', 0 ],
			%answer,
		}, $class;
	}
	sub record { my ($self, @call) = @_; push @{ $self->{calls} }, [ map { "$_" } @call ]; return }
	sub container_start { my $self = shift; $self->record(start => @_); return $self->{start} }
	sub container_start_captured { my $self = shift; $self->record(start_captured => @_); return @{ $self->{captured} } }
	sub container_running { my ($self, $name) = @_; $self->record(running => $name); return $self->{running} }
	sub container_status { my ($self, $name) = @_; return $self->{status} }
	sub container_restart_count { my ($self, $name) = @_; return $self->{restarts} }
	sub container_exit_code { my ($self, $name) = @_; return $self->{exit} }
	sub container_log_text { my ($self, $name) = @_; return $self->{log} }
	sub container_remove { my ($self, $name) = @_; $self->record(remove => $name); return 0 }
	sub network_create { my ($self, $name) = @_; $self->record(network_create => $name); return $self->{network} }
	sub network_remove { my ($self, $name) = @_; $self->record(network_remove => $name); return 0 }
	sub run { my $self = shift; $self->record(run => @_); return $self->{run} }
	sub capture_silent {
		my ($self, @args) = @_;
		$self->record(capture => @args);
		return @{ $self->{path} } if grep { /PATH/ } @args;
		return ('', $self->{has}{ $args[-1] } ? 0 : 1);
	}
}

subtest 'App::Actions::Runner::Containers' => sub {
	my $expression = App::Actions::Expression->new;
	my $containers = sub {
		my (%option) = @_;
		return App::Actions::Runner::Containers->new(
			docker => Local::ContainerDocker->new(%{ delete $option{answers} || {} }),
			expression => $expression,
			project_dir => '/project',
			run_id => '1234567890abcdef',
			logger => Local::Logger->new,
			quiet => 1,
			%option,
		);
	};
	my $job = sub { return { base_id => 'build', matrix_index => 0, @_ } };
	my $calls = sub { my ($object, $kind) = @_; return [ grep { $_->[0] eq $kind } @{ $object->{docker}{calls} } ] };

	subtest 'new' => sub {
		my $object = $containers->();
		is_deeply([ @{$object}{qw(containers networks counter)} ], [ [], [], 0 ], 'nothing made yet');
		memory_cycle_ok($object, 'no reference cycle');
		my $prefix = 'Invalid arguments to App::Actions::Runner::Containers::new: ';
		throws_ok { $containers->(docker => Local::Logger->new) }
			qr/\A\Q${prefix}Parameter 'docker' must be an object that understands the container_start method\E at /, 'a daemon that cannot start containers';
		throws_ok { $containers->(run_id => '') } qr/\A\Q$prefix\E.*'run_id'/, 'an empty run id';
		throws_ok { $containers->(project_dir => undef) } qr/\A\Q${prefix}Required parameter 'project_dir' is missing\E/, 'no project';
	};

	subtest 'name and _hostname' => sub {
		my $object = $containers->();
		is($object->name('job', $job->()), 'action-run-90abcdef-1-job-build-0', 'kind, job and index, with the last eight of the run id');
		is($object->name('svc', $job->(), 'db'), 'action-run-90abcdef-2-svc-build-0-db', 'a counter keeps names apart, and a suffix');
		like($object->name('net', $job->(base_id => 'a b/c;$(rm)', matrix_index => 3), 'x y'), qr/\Aaction-run-90abcdef-3-net-a-b-c---rm--3-x-y\z/,
			'unsafe characters become hyphens');
		is(length $object->name('job', $job->(base_id => 'j' x 200), 's' x 200), 63, 'at most 63 characters');
		like($object->name('job', $job->(base_id => 'j' x 200)), qr/-j{20}-0\z/, 'a long job id is cut to twenty');
		is($containers->(run_id => 'abc')->name('job', $job->()), 'action-run-abc-1-job-build-0', 'a short run id is used whole');
		keeps_topic(sub { $object->name('job', $job->()) }, 'name');

		my %hosts = (build => 'build', '_build' => 'build', 'build_' => 'build', 'a.b' => 'a.b', '.-.' => 'local', '' => 'local',
			('h' x 62) . '_x' => 'h' x 62, "\x{263a}" => 'local', 'test-matrix_1' => 'test-matrix-1');
		is(App::Actions::Runner::Containers::_hostname($_), $hosts{$_}, /[^\x00-\x7f]/ ? 'a non-ASCII id' : "hostname for '$_'")
			for sort keys %hosts;
		is(App::Actions::Runner::Containers::_hostname(undef), 'local', 'no id');
		my $started = time;
		App::Actions::Runner::Containers::_hostname('-' x $config{big} . 'x' . '.' x $config{big});
		ok(time - $started <= $config{time_limit}, 'a hostname made of separators is trimmed in linear time');
	};

	subtest 'create_network' => sub {
		my $object = $containers->();
		my $network = $object->create_network($job->());
		is($network, 'action-run-90abcdef-1-net-build-0', 'a network named for the job');
		is_deeply($object->remaining->{networks}, [ $network ], 'and remembered for cleanup');
		throws_code(sub { $containers->(answers => { network => 1 })->create_network($job->()) }, 'runner.network_failed',
			"Failed to create Docker network 'action-run-90abcdef-1-net-build-0' (exit 1)", 'a network that cannot be made');
	};

	subtest 'start_services and check_services' => sub {
		my $object = $containers->();
		my @started;
		my $running = $object->start_services($job->(services => {
			db => { image => 'postgres:${{ matrix.v }}', env => { PASSWORD => 'secret' }, ports => '5432', volumes => [ 'v:/v' ], options => '--health-cmd "pg_isready -q"' },
			cache => 'redis:7',
		}), 'net', { matrix => { v => 16 } }, \@started);
		is_deeply($running, [ [ 'cache', 'action-run-90abcdef-1-svc-build-0-cache' ], [ 'db', 'action-run-90abcdef-2-svc-build-0-db' ] ],
			'services start in name order');
		is_deeply(\@started, [ map { $_->[1] } @{$running} ], 'and are added to the caller\'s list');
		my $db = $calls->($object, 'start')->[1];
		is($db->[-1], 'postgres:16', 'the image is interpolated');
		ok(join(' ', @{$db}) =~ /--health-cmd pg_isready -q --name /, 'options are split as a shell would');
		ok(join(' ', @{$db}) =~ /--network net --network-alias db/, 'the service is reachable by its id');
		ok((grep { $_ eq 'PASSWORD=secret' } @{$db}), 'its environment is passed');

		my %refused = (
			'a list' => [ { s => [ 'x' ] }, 'runner.service.not_mapping', "Service 's' must be a mapping" ],
			'no image' => [ { s => { env => {} } }, 'runner.service.no_image', "Service 's' has no image" ],
			'an empty image' => [ { s => '' }, 'runner.service.no_image', undef ],
			'an unclosed quote' => [ { s => { image => 'x', options => q{--label "a b} } }, 'runner.options_invalid',
				q{Unable to read the container options '--label "a b': a quote is not closed} ],
		);
		for my $name (sort keys %refused) {
			my ($services, $code, $message) = @{ $refused{$name} };
			my $fresh = $containers->();
			throws_code(sub { $fresh->start_services($job->(services => $services), 'net', {}, []) }, $code, $message, "a service with $name");
			is_deeply($calls->($fresh, 'start'), [], "and nothing is started for $name");
		}

		# A secret in the options must not appear in the error that quotes them.
		my $fresh = $containers->();
		my $error = caught { $fresh->start_services($job->(services => { s => { image => 'x', options => q{--env "T=${{ secrets.T }}} } }), 'net',
			{ secrets => { T => 'hunter2' } }, []) };
		unlike($error->message, qr/hunter2/, 'the quoted options are as written, not with secrets filled in');

		$fresh = $containers->(answers => { start => 125 });
		@started = ();
		throws_code(sub { $fresh->start_services($job->(services => { s => 'x' }), 'net', {}, \@started) }, 'runner.service.start_failed',
			"Failed to start service 's' (exit 125)", 'a service that fails to start');
		is(scalar @started, 1, 'is still listed, so that it is removed');

		$fresh = $containers->(answers => { running => 0, exit => 3, log => "fatal: no config\r\n\n" });
		throws_code(sub { $fresh->start_services($job->(services => { s => 'x' }), 'net', {}, []) }, 'runner.container.stopped',
			"Service 's' did not stay running (exit 3); its last output was:\n  fatal: no config", 'a service that stops, with its output');

		for my $case ([ 'restarting', 0, "Service 's' is restarting; it printed nothing" ],
			[ 'dead', undef, "Service 's' is dead (its restart count could not be read); it printed nothing" ],
			[ 'running', 2, "Service 's' is restarting (restart count 2); it printed nothing" ]) {
			my ($status, $restarts, $message) = @{$case};
			my $object = $containers->(answers => { status => $status, restarts => $restarts });
			my $label = defined $restarts ? $restarts : 'unknown';
			throws_code(sub { $object->check_services([ [ 's', 'c' ] ]) }, 'runner.container.restarting', $message,
				"status $status, restarts $label");
		}
		my $healthy = $containers->();
		is($healthy->check_services([ [ 's', 'c' ] ]), $healthy, 'a healthy service passes');
		is($containers->(answers => { status => undef, restarts => undef })->check_services([ [ 's', 'c' ] ])->{counter}, 0,
			'and so does one the daemon says nothing about');

		my $credentialed = $containers->(quiet => 0);
		$credentialed->start_services($job->(services => { s => { image => 'x', credentials => { username => 'u' } } }), 'net', {}, []);
		is_deeply($credentialed->{logger}{lines}, [ [ warn => "action-run: service 's' credentials are not supported; using the local Docker login" ] ],
			'credentials are warned about');
	};

	subtest 'start_job' => sub {
		my $object = $containers->(user => '1000:1000', platform => 'linux/arm64');
		my $name = $object->start_job($job->(container => { options => '--cpus 2', volumes => 'cache:/cache' }), 'net', { A => 'b' }, {}, 'ubuntu:24.04', '/tmp/run');
		is($name, 'action-run-90abcdef-1-job-build-0', 'the job container');
		my @args = @{ $calls->($object, 'start_captured')->[0] };
		shift @args;
		is_deeply([ @args[0 .. 3] ], [ '--platform', 'linux/arm64', '--cpus', '2' ], 'the platform first, so options can override it');
		like(join(' ', @args), qr{--hostname build --user 1000:1000 -v /project:/github/workspace -v /tmp/run:/github/actions-runner -v cache:/cache -w /github/workspace -e A=b --entrypoint /bin/sh ubuntu:24.04 -c while :; do sleep 3600; done\z},
			'mounts, user, environment and an idle command');

		$object = $containers->(answers => { captured => [ "Error: No such image: ubuntu:24.04\n", 125 ] });
		throws_code(sub { $object->start_job($job->(), 'net', {}, {}, 'ubuntu:24.04', '/t') }, 'runner.container.start_failed',
			"Job container 'action-run-90abcdef-1-job-build-0' could not be started (exit 125); at fault: the image 'ubuntu:24.04'; the daemon said:\n  Error: No such image: ubuntu:24.04",
			'a refused container names the image');
		is_deeply($calls->($object, 'remove'), [ [ remove => 'action-run-90abcdef-1-job-build-0' ] ], 'and is removed');

		$object = $containers->(answers => { running => 0, exit => undef });
		throws_code(sub { $object->start_job($job->(), 'net', {}, {}, 'x', '/t') }, 'runner.container.stopped',
			"Job container 'action-run-90abcdef-1-job-build-0' did not stay running (its exit status could not be read); it printed nothing",
			'one that stops at once');
		throws_code(sub { $containers->()->start_job($job->(container => { options => q{--label 'x} }), 'net', {}, {}, 'x', '/t') },
			'runner.options_invalid', undef, 'unreadable options are refused before anything starts');
	};

	subtest 'inspect and _has_command' => sub {
		my $object = $containers->();
		is_deeply($object->inspect('c'), { has_bash => 1, has_node => 0, path => '/github/actions-runner/bin:/github/actions-runner/aptbin:/usr/bin:/bin' },
			'what the container has, and the shims first on the path');
		$object = $containers->(answers => { path => [ '', 1 ], has => { sudo => 1 } });
		is($object->inspect('c')->{path}, '/github/actions-runner/aptbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
			'a path the container will not give is assumed; an image with sudo keeps its own');
		is($containers->(user => 'me')->inspect('c')->{path} =~ m{actions-runner/bin} ? 1 : 0, 0, 'another user gets no pretend sudo');

		$object = $containers->();
		$object->_has_command('c', '$(touch /tmp/pwned)');
		is_deeply($calls->($object, 'capture')->[0], [ 'capture', 'exec', 'c', 'sh', '-c', 'command -v "$1" >/dev/null 2>&1', 'sh', '$(touch /tmp/pwned)' ],
			'a command name is an argument, never shell text');
	};

	subtest 'run_action' => sub {
		my $object = $containers->(answers => { run => 7 });
		my %action = (image => 'img', network => 'net', workdir => '/w', temp_path => '/t', env => { X => 1 }, title => 'action');
		is($object->run_action(%action, entrypoint => '/entry', arguments => [ 'a', 'b c' ]), 7, 'the action\'s status');
		is_deeply($calls->($object, 'run')->[0], [ qw(run run --rm --network net -v /project:/github/workspace -v /t:/github/actions-runner -w /w --entrypoint /entry -e X=1 img a), 'b c' ],
			'each argument stays one word');
		$object->run_action(%action);
		ok(!grep({ $_ eq '--entrypoint' } @{ $calls->($object, 'run')->[1] }), 'no entrypoint, the image\'s own');
		my $prefix = 'Invalid arguments to App::Actions::Runner::Containers::run_action: ';
		throws_ok { $object->run_action(%action, image => '') } qr/\A\Q$prefix\E.*'image'/, 'an empty image';
		throws_ok { $object->run_action(%action, arguments => 'a b') } qr/\A\Q$prefix\E.*'arguments'/, 'arguments must be a list';
		my %no_title = %action;
		delete $no_title{title};
		throws_ok { $object->run_action(%no_title) } qr/\A\Q${prefix}Required parameter 'title' is missing\E/, 'a title is required';
	};

	subtest 'cleanup_job, remaining and remove_all' => sub {
		my $object = $containers->();
		my $network = $object->create_network($job->());
		$object->start_services($job->(services => { a => 'x', b => 'y' }), $network, {}, my $started = []);
		my $copy = $object->remaining;
		push @{ $copy->{containers} }, 'not mine';
		is(scalar @{ $object->remaining->{containers} }, 2, 'remaining is a copy');

		is($object->cleanup_job($network, [ $started->[0] ]), $object, 'cleanup_job returns the object');
		is_deeply($object->remaining, { containers => [ $started->[1] ], networks => [] }, 'and forgets what it removed');
		$object->remove_all;
		is_deeply($object->remaining, { containers => [], networks => [] }, 'remove_all leaves nothing');
		is_deeply([ map { $_->[1] } @{ $calls->($object, 'remove') } ], [ $started->[0], $started->[1] ], 'each container removed once');

		my $kept = $containers->(keep => 1);
		$network = $kept->create_network($job->());
		$kept->cleanup_job($network, []);
		is_deeply($kept->remaining->{networks}, [ $network ], '--keep keeps everything');
	};

	subtest '_service_entrypoint, _list_args and _explain' => sub {
		my $object = $containers->();
		my %entrypoints = ('--entrypoint /a --entrypoint /b' => '/a', '--entrypoint=/c' => '/c', '--cpus 1' => undef,
			'--entrypoint' => undef, '--entrypoint ""' => '');
		for my $options (sort keys %entrypoints) {
			is($object->_service_entrypoint({ options => $options }, {}), $entrypoints{$options}, "entrypoint from '$options'");
		}
		is($object->_service_entrypoint({}, {}), undef, 'no options');
		is_deeply($object->_list_args('-p', undef, {}), [], 'no values');
		is_deeply($object->_list_args('-p', '80:80', {}), [ '-p', '80:80' ], 'a scalar');
		is_deeply($object->_list_args('-v', [ '${{ matrix.d }}:/d', 'x' ], { matrix => { d => '/host' } }), [ '-v', '/host:/d', '-v', 'x' ], 'a list, interpolated');

		my $explained = '';
		{
			open my $handle, '>', \$explained or die $!;
			my $old = select $handle;
			$containers->(explain => 1)->_explain(title => 'T', image => 'i');
			select $old;
		}
		is($explained, "==> T\n    image      i\n    entrypoint (the image's own)\n    command    (the image's own)\n", 'an explain block');
	};

	subtest '_start_fault and _with_output' => sub {
		my $object = $containers->();
		my %faults = (
			'Error: manifest unknown' => "the image 'img'",
			'Bind for 0.0.0.0:80 failed: port is already allocated' => 'the published port',
			'exec: "/entry": stat /entry: no such file or directory' => "the entrypoint '/entry'",
			'exec: "/other": no such file or directory' => undef,
			'something else' => undef,
			'' => undef,
		);
		is($object->_start_fault($_, image => 'img', entrypoint => '/entry'), $faults{$_}, "fault in '$_'") for sort keys %faults;
		is($object->_start_fault('pull access denied', image => 'x:1'), "the image 'x:1'", 'pull access denied blames the image');
		is($object->_start_fault(undef), undef, 'no message');

		my $error = $object->_with_output('x.y', 'S', "a\r\nb\r\n  \n", 'runner.container.silent', 'runner.container.output');
		is_deeply([ $error->code, $error->message, "$error" ], [ 'x.y', "S; its last output was:\n  a\n  b", "S; its last output was:\n  a\n  b\n" ],
			'output is quoted, CRs and trailing blank lines dropped, with no location');
		is($object->_with_output('x.y', 'S', "\n\n", 'runner.container.silent', 'runner.container.output')->message, 'S; it printed nothing',
			'blank output is no output');
		keeps_topic(sub { $object->_with_output('x.y', 'S', "a\r\n", 'runner.container.silent', 'runner.container.output') }, '_with_output');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Steps
# ---------------------------------------------------------------------------

use App::Actions::Runner::Steps;

# A job container.  Each docker exec is recorded with its environment, and
# a test's callback can act as the command: it is given the environment,
# with each runner path turned into the host path the test can write to.
{
	package Local::StepDocker;
	sub new { my ($class, %option) = @_; return bless { execs => [], status => 0, %option }, $class }
	sub container_exec {
		my ($self, @args) = @_;
		my (%env, @rest);
		while (@args) {
			my $arg = shift @args;
			if ($arg eq '-e') { my $variable = shift @args; $env{ $variable->name } = $variable->value; next }
			push @rest, "$arg";
		}
		my %host = map { my $v = $env{$_}; $v =~ s{\A/github/actions-runner}{$self->{temp}}; ($_ => $v) } keys %env;
		push @{ $self->{execs} }, { env => \%env, args => \@rest };
		return $self->{act} ? $self->{act}->(\%host, \@rest, \%env) : $self->{status};
	}
	sub redact { my ($self, $text) = @_; (my $copy = $text) =~ s/hunter2/***/g; return $copy }

	package Local::StepImages;
	sub new { return bless { ensured => [] }, shift }
	sub ensure { my ($self, $image) = @_; push @{ $self->{ensured} }, $image; return 1 }

	package Local::StepContainers;
	sub new { my ($class, %option) = @_; return bless { runs => [], status => 0, %option }, $class }
	sub run_action { my ($self, %action) = @_; push @{ $self->{runs} }, \%action; return $self->{status} }

	package Local::StepWorkflow;
	sub new { my ($class, $defaults) = @_; return bless { defaults => $defaults || {} }, $class }
	sub defaults { return $_[0]{defaults} }
}

subtest 'App::Actions::Runner::Steps' => sub {
	my $project = tempdir(CLEANUP => 1);
	my $steps = sub {
		my (%option) = @_;
		my $temp = tempdir(CLEANUP => 1);
		mkdir File::Spec->catdir($temp, $_) or die $! for qw(scripts env output path summary);
		my $docker = Local::StepDocker->new(temp => $temp, %{ delete $option{docker} || {} });
		return App::Actions::Runner::Steps->new(
			expression => App::Actions::Expression->new,
			docker => $docker,
			images => Local::StepImages->new,
			containers => Local::StepContainers->new(%{ delete $option{containers} || {} }),
			workflow => Local::StepWorkflow->new(delete $option{defaults}),
			project_dir => $project,
			temp_path => $temp,
			job => { base_id => 'build', steps => delete $option{steps} || [] },
			container => 'job-container',
			network => 'net',
			facts => { path => '/usr/bin:/bin', has_bash => 1, has_node => 1, %{ delete $option{facts} || {} } },
			job_env => delete $option{job_env} || {},
			context => { github => { repository => 'o/r' }, secrets => { TOKEN => 'hunter2' } },
			quiet => 1,
			logger => Local::Logger->new,
			%option,
		);
	};
	my $read = sub { my ($path) = @_; open my $h, '<', $path or die "$path: $!"; local $/; return scalar <$h> };
	my $append = sub { my ($path, $text) = @_; open my $h, '>>', $path or die "$path: $!"; print {$h} $text; close $h; return 0 };

	subtest 'new' => sub {
		my $object = $steps->(job_env => { A => 1 });
		is_deeply([ @{$object}{qw(base_path has_bash has_node depth failed)} ], [ '/usr/bin:/bin', 1, 1, 0, 0 ], 'the container facts');
		is_deeply($object->{ctx}{env}, { A => 1 }, 'the context sees the job env');
		is($object->{ctx}{job}{status}, 'success', 'and a job that has not failed');
		memory_cycle_ok($object, 'no reference cycle');
		my $prefix = 'Invalid arguments to App::Actions::Runner::Steps::new: ';
		throws_ok { $steps->(container => '') } qr/\A\Q$prefix\E.*'container'/, 'an empty container name';
		throws_ok { $steps->(images => Local::StepWorkflow->new) }
			qr/\A\Q${prefix}Parameter 'images' must be an object that understands the ensure method\E/, 'an images object that cannot prepare';
	};

	subtest 'run with run: steps' => sub {
		my $object = $steps->(
			steps => [
				{ id => 'one', run => 'echo ${{ github.repository }}' },
				{ id => 'two', run => 'false' },
				{ id => 'three', run => 'skipped after a failure' },
				{ id => 'four', if => 'failure()', run => 'cleanup' },
			],
			docker => { act => sub {
				my ($host, $args) = @_;
				return $args->[-1] =~ /step-2/ ? 1 : 0;
			} },
		);
		my $result = $object->run;
		is($result->{result}, 'failure', 'a failing step fails the job');
		is_deeply([ map { $object->{ctx}{steps}{$_}{outcome} } qw(one two three four) ], [ qw(success failure skipped success) ],
			'later steps are skipped, except one asking for failure()');
		my $script = $read->(File::Spec->catfile($object->{temp_path}, 'scripts', 'step-1.sh'));
		is($script, "echo o/r\n", 'the script is interpolated and ends in a newline');
		is((stat File::Spec->catfile($object->{temp_path}, 'scripts', 'step-1.sh'))[2] & oct('0777'), oct('0600'), 'and is private');
		my $exec = $object->{docker}{execs}[0];
		is_deeply([ @{ $exec->{args} }[0, 1, -4, -3, -2] ], [ '-w', '/github/workspace', 'job-container', 'sh', '-c' ], 'run in the job container');
		is($exec->{args}[-1], q{bash -e '/github/actions-runner/scripts/step-1.sh'}, 'with bash -e, the default where there is bash');
		is_deeply([ @{ $exec->{env} }{qw(GITHUB_ACTION GITHUB_ACTION_PATH PATH)} ], [ 'one', '', '/usr/bin:/bin' ], 'and the GITHUB_ACTION values');
	};

	subtest 'step files: env, outputs, path, summary' => sub {
		my $object = $steps->(
			steps => [
				{ id => 'w', run => 'write' },
				{ id => 'r', run => 'read ${{ steps.w.outputs.answer }} ${{ env.FROM_STEP }}' },
			],
			docker => { act => sub {
				my ($host) = @_;
				return 0 unless -s $host->{GITHUB_ENV} == 0 && $read->($host->{GITHUB_ENV}) eq '' && !$main::wrote++;
				$append->($host->{GITHUB_ENV}, "FROM_STEP=yes\nMULTI<<EOF\nline 1\r\nline 2\nEOF\nnot a pair\n1BAD=x\n");
				$append->($host->{GITHUB_OUTPUT}, "answer=42\n");
				$append->($host->{GITHUB_PATH}, "  /opt/tool/bin  \n\n/second\n");
				$append->($host->{GITHUB_STEP_SUMMARY}, "## Done\n");
				return 0;
			} },
		);
		local $main::wrote = 0;
		$object->run;
		is_deeply($object->{job_env}, { FROM_STEP => 'yes', MULTI => "line 1\nline 2" }, 'GITHUB_ENV, heredocs and all; junk lines ignored');
		is_deeply($object->{ctx}{steps}{w}{outputs}, { answer => 42 }, 'GITHUB_OUTPUT becomes the step\'s outputs');
		is($read->(File::Spec->catfile($object->{temp_path}, 'scripts', 'step-2.sh')), "read 42 yes\n", 'which the next step reads');
		is($object->{docker}{execs}[1]{env}{PATH}, '/opt/tool/bin:/second:/usr/bin:/bin', 'GITHUB_PATH goes in front, trimmed');
		ok(!-e File::Spec->catfile($object->{temp_path}, 'env', 'step-1.env'), 'the step files are removed');
	};

	subtest '_execute_step failures' => sub {
		my $object = $steps->(quiet => 0);
		is($object->_execute_step({ id => 'e', env => { X => '${{ nope( }}' }, run => 'x' }), 'failure', 'an env that does not evaluate');
		is($object->{ctx}{steps}{e}{outcome}, 'failure', 'is recorded');
		is($object->{ctx}{job}{status}, 'failure', 'and fails the job');
		like($object->{logger}{lines}[0][1], qr/\Aaction-run: /, 'with a warning');

		$object = $steps->(quiet => 0);
		my $out = '';
		{
			open my $h, '>', \$out or die $!;
			my $old = select $h;
			is($object->_execute_step({ id => 'c', if => 'nope(', run => 'x' }), 'failure', 'a condition that does not evaluate');
			select $old;
		}
		is_deeply($object->{ctx}{steps}{c}, { outputs => {}, outcome => 'failure', conclusion => 'failure' },
			'is recorded too, so steps.c.outcome can be read');
		is($object->{failed}, 1, 'and fails the job');
		is_deeply($object->{docker}{execs}, [], 'nothing ran for either');

		my $dies = $steps->(quiet => 0, steps => [ { id => 'd', run => 'x' } ]);
		my $guard = mock_scoped('App::Actions::Runner::Steps::_run_script_step' => sub { die "exec exploded\n" });
		my $said = '';
		{
			open my $h, '>', \$said or die $!;
			my $old = select $h;
			is($dies->_execute_step({ id => 'd', run => 'x' }), 'failure', 'a step whose machinery dies');
			select $old;
		}
		is_deeply($dies->{logger}{lines}[0], [ warn => 'action-run: exec exploded' ], 'says why');
	};

	subtest '_should_run' => sub {
		my $object = $steps->();
		my %cases = ('no condition' => [ undef, 0, 1 ], 'no condition after a failure' => [ undef, 1, 0 ],
			'true' => [ 'true', 0, 1 ], 'true after a failure' => [ 'true', 1, 0 ], 'always()' => [ 'always()', 1, 1 ],
			'failure()' => [ 'failure()', 1, 1 ], 'failure() before one' => [ 'failure()', 0, 0 ], 'false' => [ 'false', 0, 0 ]);
		for my $name (sort keys %cases) {
			my ($condition, $failed, $want) = @{ $cases{$name} };
			local $object->{failed} = $failed;
			is($object->_should_run($condition, {}, status_flags($failed)), $want, $name);
		}
		throws_ok { $object->_should_run('nope(', {}, {}) } qr/./, 'a condition that does not parse croaks';
	};

	subtest '_conclude' => sub {
		my $object = $steps->();
		is($object->_conclude({ 'continue-on-error' => 'true' }, { outcome => 'failure' }, '', {}, {}), 'failure', 'the outcome stays failure');
		is_deeply([ $object->{last_conclusion}, $object->{failed} ], [ 'success', 0 ], 'but continue-on-error concludes success');
		$object->_conclude({}, { outcome => 'failure', error => 'bad' }, '', {}, {});
		is($object->{failed}, 1, 'a plain failure fails the job');
		$object = $steps->(quiet => 0);
		$object->_conclude({ 'continue-on-error' => 'nope(' }, { outcome => 'failure' }, '', {}, {});
		is($object->{failed}, 1, 'a continue-on-error that does not evaluate does not continue');
		like($object->{logger}{lines}[0][1], qr/continue-on-error/i, 'and says so');
		$object = $steps->(job_env => { A => 1 });
		$object->_conclude({}, { outcome => 'success', env => { B => 2 }, path => [ '/p2' ] }, '', {}, {});
		$object->_conclude({}, { outcome => 'success', path => [ '/p3' ] }, '', {}, {});
		is_deeply([ $object->{job_env}, $object->{path_additions} ], [ { A => 1, B => 2 }, [ '/p3', '/p2' ] ], 'exports and paths, newest first');
		is($object->_conclude({}, {}, '', {}, {}), 'success', 'no outcome is success');
	};

	subtest '_run_uses_step' => sub {
		my $object = $steps->(quiet => 0);
		my $run = sub { my ($step) = @_; my $out = ''; open my $h, '>', \$out or die; my $old = select $h;
			my $result = $object->_run_uses_step($step, 1, {}, { github => {} }, {}); select $old; return ($result, $out) };
		my ($result, $out) = $run->({ uses => 'actions/checkout@v4', with => { path => 'sub', submodules => 'true', ref => 'main' } });
		is($result->{outcome}, 'success', 'checkout is a no-op');
		is(scalar @{ $object->{logger}{lines} }, 3, 'each option it ignores is warned about');
		($result, $out) = $run->({ uses => 'shogo82148/actions-setup-perl@v1', with => { 'perl-version' => q{5.${{ '40' }}} } });
		like($out, qr/Perl 5\.40/, 'setup-perl names the version');
		($result) = $run->({ uses => 'actions/cache/restore@v4' });
		is($result->{outcome}, 'success', 'cache is a no-op');
		($result) = $run->({ uses => 'Actions/Upload-Artifact@v4' });
		is($result->{outcome}, 'success', 'case does not matter');
		($result) = $run->({ uses => 'actions/cachex@v1' });
		is($result->{outcome}, 'skipped', 'a near miss is an unsupported action');
		($result) = $run->({ uses => 'someone/else@v1' });
		is($result->{outcome}, 'skipped', 'a remote action is skipped');
		my $strict = $steps->(strict_actions => 1);
		is($strict->_run_uses_step({ uses => 'someone/else@v1' }, 1, {}, {}, {})->{outcome}, 'failure', 'or fails under --strict-actions');
	};

	subtest '_run_docker_action and _action_arguments' => sub {
		my $object = $steps->();
		my $result = $object->_run_docker_action({ id => 'd', uses => 'docker://alpine:3', with => { args => q{echo "a b" ${{ github.repository }}}, entrypoint => '/bin/sh' } },
			1, 'alpine:3', { E => 1 }, { github => { repository => 'o/r' } }, {});
		is($result->{outcome}, 'success', 'it ran');
		is_deeply($object->{images}{ensured}, [ 'alpine:3' ], 'the image is prepared first');
		my $run = $object->{containers}{runs}[0];
		is_deeply([ @{$run}{qw(image network entrypoint)}, $run->{arguments} ], [ 'alpine:3', 'net', '/bin/sh', [ 'echo', 'a b', 'o/r' ] ],
			'image, network, entrypoint and arguments split as a shell would');
		is($run->{env}{E}, 1, 'with the step env');

		throws_code(sub { $object->_run_docker_action({ uses => 'docker://${{ x }}' }, 1, '', {}, {}, {}) }, 'runner.docker_action.no_image',
			q{Docker action 'docker://${{ x }}' in job 'build' has no image name; check the expression it uses}, 'an image that is empty');
		throws_code(sub { $object->_run_docker_action({ uses => 'docker://a' }, 1, 'x:${{ y }}', {}, {}, {}) }, 'runner.docker_action.bad_image',
			undef, 'an image that still holds an expression');
		throws_code(sub { $object->_action_arguments({ uses => 'docker://a' }, q{--token "${{ secrets.TOKEN }}}, { secrets => { TOKEN => 'hunter2' } }, {}) },
			'runner.docker_action.bad_args', q{Unable to read the args of 'docker://a' ('--token "${{ secrets.TOKEN }}'): a quote is not closed},
			'args with an unclosed quote are refused, quoted as written');
		is_deeply($object->_action_arguments({}, '  ', {}, {}), [], 'blank args are no args');
		is_deeply($object->_action_arguments({}, undef, {}, {}), [], 'and so are none');
		is($steps->(containers => { status => 3 })->_run_docker_action({ uses => 'docker://a' }, 1, 'a', {}, {}, {})->{exit_code}, 3,
			'the action\'s status is the step\'s');
	};

	subtest 'local, composite and JavaScript actions' => sub {
		my $dir = sub {
			my ($name, $yaml, %files) = @_;
			my $path = File::Spec->catdir($project, $name);
			mkdir $path;
			write_file('action.yml', $yaml, $path);
			write_file($_, $files{$_}, $path) for keys %files;
			return "./$name";
		};
		my $composite = $dir->('comp', "name: c\ninputs:\n  who: {default: world}\noutputs:\n  said: {value: '\${{ steps.s.outputs.said }}'}\nruns:\n  using: composite\n  steps:\n    - id: s\n      run: echo \${{ inputs.who }}\n      shell: sh\n");
		my $object = $steps->(docker => { act => sub { my ($host) = @_; $append->($host->{GITHUB_OUTPUT}, "said=hi\n") if $host->{GITHUB_OUTPUT}; $append->($host->{GITHUB_ENV}, "LEAK=1\n") if $host->{GITHUB_ENV}; 0 } });
		my $result = $object->_run_local_action({ uses => $composite, with => { who => 'you' } }, 1, $composite, { KEEP => 'k' }, { github => {} }, {});
		is_deeply([ $result->{outcome}, $result->{outputs} ], [ 'success', { said => 'hi' } ], 'a composite runs its steps and declares outputs');
		is($read->(File::Spec->catfile($object->{temp_path}, 'scripts', 'step-1.sh')), "echo you\n", 'with its inputs');
		is($object->{job_env}{LEAK}, 1, 'and what it exports reaches the job');
		ok(!exists $object->{job_env}{KEEP}, 'but the step\'s own env does not');

		throws_code(sub { $object->_run_local_action({ uses => './missing' }, 1, './missing', {}, {}, {}) }, 'runner.local_action.missing', undef,
			'a local action that is not there');
		throws_code(sub { $object->_run_local_action({ uses => '../x' }, 1, '../x', {}, {}, {}) }, 'runner.local_action_escapes', undef,
			'one outside the project');
		my $deep = $steps->();
		$deep->{depth} = 10;
		throws_code(sub { $deep->_run_composite_action(App::Actions::Action->load_from_dir(File::Spec->catdir($project, 'comp')), { uses => './comp' }, '/w', {}, {}, {}) },
			'runner.composite.too_deep', undef, 'composites nest ten deep at most');
		my $docker_action = $dir->('dock', "name: d\nruns:\n  using: docker\n  image: Dockerfile\n");
		is($object->_run_local_action({ uses => $docker_action }, 1, $docker_action, {}, {}, {})->{outcome}, 'skipped', 'a local Docker action is unsupported');

		my $js = $dir->('js', "name: j\ninputs:\n  perl-version: {default: '5.40'}\n  github token: {default: x}\nruns:\n  using: node20\n  pre: pre.js\n  main: main.js\n  post: post.js\n  post-if: failure()\n");
		$object = $steps->(docker => { act => sub {
			my ($host, $args, $env) = @_;
			$append->($host->{GITHUB_STATE}, "phase=pre\n") if $args->[-1] =~ /pre\.js/;
			return $args->[-1] =~ /main\.js/ && !defined $env->{STATE_phase} ? 9 : 0;
		} });
		$result = $object->_run_local_action({ id => 'j', uses => $js }, 1, $js, {}, { github => {} }, {});
		is($result->{outcome}, 'success', 'a JavaScript action: pre, then main');
		my $main = $object->{docker}{execs}[1];
		is_deeply([ @{ $main->{env} }{ 'INPUT_PERL-VERSION', 'INPUT_GITHUB_TOKEN', 'STATE_phase' } ], [ '5.40', 'x', 'pre' ],
			'inputs named as GitHub names them; pre\'s state reaches main');
		is_deeply([ @{ $main->{args} }[-2, -1] ], [ 'node', '/github/workspace/js/main.js' ], 'run with node');
		is(scalar @{ $object->{post_actions} }, 1, 'the post step is queued');
		$object->_run_post_actions;
		is(scalar @{ $object->{docker}{execs} }, 2, 'and is skipped, its post-if wanting a failure');
		$object->{failed} = 1;
		$object->_run_post_actions;
		is($object->{docker}{execs}[2]{args}[-1], '/github/workspace/js/post.js', 'and runs after one');

		my $no_node = $steps->(facts => { has_node => 0 });
		throws_code(sub { $no_node->_run_local_action({ uses => $js }, 1, $js, {}, {}, {}) }, 'runner.javascript.no_node', undef, 'without node');
		my $pre_fails = $steps->(docker => { status => 4 });
		$result = $pre_fails->_run_local_action({ uses => $js }, 1, $js, {}, {}, {});
		is_deeply([ $result->{outcome}, $result->{exit_code}, scalar @{ $pre_fails->{docker}{execs} } ], [ 'failure', 4, 1 ], 'a failed pre stops main');
	};

	subtest '_shell_for, _working_directory and _default_for' => sub {
		my $object = $steps->(defaults => { run => { shell => 'sh', 'working-directory' => 'wf' } });
		is($object->_shell_for({}, {}, {})->{name}, 'sh', 'the workflow default');
		local $object->{job}{defaults} = { run => { shell => 'Perl ' } };
		is($object->_shell_for({}, {}, {})->{command}, 'perl {0}', 'the job default wins, case and space aside');
		is($object->_shell_for({ shell => 'bash' }, {}, {})->{command}, 'bash --noprofile --norc -eo pipefail {0}', 'the step wins');
		is_deeply($object->_shell_for({ shell => 'node --x' }, {}, {}), { name => 'custom', command => 'node --x {0}', extension => '.sh', requires_bash => 0 },
			'a custom shell');
		is($object->_shell_for({ shell => 'deno run {0} x' }, {}, {})->{command}, 'deno run {0} x', 'which may place the script');
		is($steps->(facts => { has_bash => 0 })->_shell_for({}, {}, {})->{name}, 'sh', 'no bash, sh -e');
		is($steps->(facts => { has_bash => 0 }, dry_run => 1)->_shell_for({}, {}, {})->{name}, 'bash', 'a dry run assumes bash');

		is($object->_working_directory({}, {}, {}), '/github/workspace/wf', 'a relative default is under the workspace');
		is($object->_working_directory({ 'working-directory' => '/abs' }, {}, {}), '/abs', 'an absolute one is kept');
		is($object->_working_directory({ 'working-directory' => '${{ env.NONE }}' }, { env => {} }, {}), '/github/workspace', 'an empty one is the workspace');
		is($steps->()->_default_for({}, 'shell'), undef, 'nothing set');

		my $missing = $steps->(facts => { has_bash => 0 });
		my $result = $missing->_run_script_step({ run => 'x', shell => 'bash' }, 1, {}, { github => {} }, {});
		is_deeply([ $result->{outcome}, $result->{error} ], [ 'failure', "Shell 'bash' is not available in the container" ], 'bash asked for but absent');
		is_deeply($missing->{docker}{execs}, [], 'and nothing ran');
	};

	subtest '_step_name' => sub {
		my $object = $steps->();
		is($object->_step_name({ name => 'Build ${{ github.repository }}' }, 1, { github => { repository => 'o/r' } }), 'Build o/r', 'a name, interpolated');
		is($object->_step_name({ uses => 'a/b@v1' }, 1, {}), 'a/b@v1', 'uses');
		is($object->_step_name({ run => "  make\n\t test  " }, 1, {}), 'make test', 'a script, on one line');
		is(length $object->_step_name({ run => 'x' x 200 }, 1, {}), 80, 'cut to eighty');
		like($object->_step_name({ run => 'x' x 200 }, 1, {}), qr/\.\.\.\z/, 'with an ellipsis');
		is($object->_step_name({}, 7, {}), 'Step 7', 'nothing to go on');
		is($object->_step_name({ name => '${{ nope( }}' }, 1, {}), '${{ nope( }}', 'a name that does not evaluate is shown as written');
		keeps_topic(sub { $object->_step_name({ run => "a\nb" }, 1, {}) }, '_step_name');
	};

	subtest 'step file parsing' => sub {
		my $file = write_file('kv', "A=1\nB=x=y\nH<<END\none\n\ntwo\nEND\nC=\nbad line\n  D=4\nU<<NEVER\nrest\n");
		is_deeply(App::Actions::Runner::Steps::_parse_kv_file($file), { A => 1, B => 'x=y', H => "one\n\ntwo", C => '', U => 'rest' },
			'pairs, heredocs, empty values; other lines are ignored');
		is_deeply(App::Actions::Runner::Steps::_parse_kv_file(undef), {}, 'no file');
		is_deeply(App::Actions::Runner::Steps::_parse_kv_file(tempdir(CLEANUP => 1)), {}, 'a directory');
		is_deeply(App::Actions::Runner::Steps::_read_lines(write_file('p', " /a \r\n\n\t\n/b")), [ '/a', '/b' ], '_read_lines');
		is_deeply(App::Actions::Runner::Steps::_read_lines("$file.none"), [], 'a missing path file');
		is(App::Actions::Runner::Steps::_read_file(write_file('s', '')), '', 'an empty summary');
		is(App::Actions::Runner::Steps::_read_file(undef), '', 'no summary');
		is(App::Actions::Runner::Steps::_open_if_readable(undef), undef, 'nothing to open');

		my $big = write_file('big', join('', map { "K$_=v\n" } 1 .. $config{big} / 10));
		my $started = time;
		is(scalar keys %{ App::Actions::Runner::Steps::_parse_kv_file($big) }, $config{big} / 10, 'a large file');
		ok(time - $started <= $config{time_limit}, 'is read in linear time');
		keeps_topic(sub { App::Actions::Runner::Steps::_parse_kv_file($file); App::Actions::Runner::Steps::_read_lines($file) }, 'the parsers');
	};

	subtest '_prepare_step_files, _collect_step_files and _chmod_private' => sub {
		my $object = $steps->();
		my $files = $object->_prepare_step_files(5, '-post');
		is_deeply([ sort keys %{ $files->{vars} } ], [ qw(GITHUB_ENV GITHUB_OUTPUT GITHUB_PATH GITHUB_STATE GITHUB_STEP_SUMMARY) ], 'every step file');
		is($files->{vars}{GITHUB_OUTPUT}, '/github/actions-runner/output/step-5-post.out', 'named after the step');
		is((stat $files->{host}{env})[2] & oct('0777'), oct('0600'), 'private');
		throws_code(sub { $steps->(temp_path => tempdir(CLEANUP => 1))->_prepare_step_files(1) }, 'runner.write_failed', undef,
			'a runner directory without the step folders');
		$append->($files->{host}{state}, "k=v\n");
		is_deeply($object->_collect_step_files($files, 1)->{state}, { k => 'v' }, 'the state is kept when asked');
		ok(-e $files->{host}{state} && !-e $files->{host}{env}, 'and only it survives');
		unlink $files->{host}{state};
		is_deeply($object->_collect_step_files($files, 0), { env => {}, outputs => {}, path => [], summary => '', state => {} },
			'files a step removed itself are no error');

		my $shared = $steps->(share_files => 1);
		my $path = write_file('f', 'x');
		$shared->_chmod_private($path);
		is((stat $path)[2] & oct('0777'), oct('0666'), 'shared with another container user');
	};

	subtest '_exec_env, _result and _shell_quote' => sub {
		my $object = $steps->();
		$object->{path_additions} = [ '/a', '/b' ];
		is_deeply($object->_exec_env({ X => 1 }, { vars => { GITHUB_ENV => '/e' } }, 'id', '/p'),
			{ X => 1, GITHUB_ENV => '/e', PATH => '/a:/b:/usr/bin:/bin', GITHUB_ACTION => 'id', GITHUB_ACTION_PATH => '/p' }, 'everything a command needs');
		is($object->_exec_env({ PATH => '/mine' }, undef, 'id', undef)->{PATH}, '/a:/b:/mine', 'a PATH of the step\'s own is the base');
		is_deeply(App::Actions::Runner::Steps->_result(outcome => 'skipped'), { outcome => 'skipped', env => {}, outputs => {}, path => [], summary => '' }, '_result');
		is(App::Actions::Runner::Steps::_shell_quote(q{/a b/it's}), q{'/a b/it'\''s'}, '_shell_quote');
		is(App::Actions::Runner::Steps::_shell_quote(undef), q{''}, 'of nothing');
	};

	subtest 'dry run and secrets' => sub {
		my $object = $steps->(dry_run => 1, verbose => 1, quiet => 0, steps => [ { run => 'echo ${{ secrets.TOKEN }}' } ]);
		my $out = '';
		{
			open my $h, '>', \$out or die $!;
			my $old = select $h;
			$object->run;
			select $old;
		}
		unlike($out, qr/hunter2/, 'a dry run shows the script with secrets redacted');
		like($out, qr/echo \*\*\*/, 'in their place');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner
# ---------------------------------------------------------------------------

use App::Actions::Runner;

# A Docker client for the runner itself: what the planner asks of it
# directly, everything else being mocked part by part.
{
	package Local::RunnerDocker;
	sub new { my ($class, %option) = @_; return bless { removed => [], present => {}, checks => 0, %option }, $class }
	sub check { my ($self) = @_; $self->{checks}++; die "Cannot connect to the Docker daemon\n" if $self->{down}; return 1 }
	sub bin { return 'docker' }
	sub image_exists { my ($self, $image) = @_; return $self->{present}{$image} ? 1 : 0 }
	sub image_remove { my ($self, $image) = @_; push @{ $self->{removed} }, $image; return 0 }
	sub container_start { return 0 }
	sub container_exec { return 0 }
	sub redact { my ($self, $text) = @_; (my $copy = $text) =~ s/hunter2/***/g; return $copy }

	# One of the caller's own, which need not say what command it runs.
	package Local::SilentDocker;
	our @ISA = ('Local::RunnerDocker');
	sub bin { die "no such method\n" }
}

subtest 'App::Actions::Runner' => sub {
	my $project = tempdir(CLEANUP => 1);
	my $yaml = <<'YAML';
name: CI
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        v: [1, 2, 3]
    steps: [{run: echo}]
  test:
    needs: build
    runs-on: ubuntu-latest
    steps: [{run: echo}]
  windows:
    runs-on: windows-latest
    steps: [{run: echo}]
YAML
	my $workflow = App::Actions::Workflow->load(write_file('ci.yml', $yaml));
	my $runner = sub {
		return App::Actions::Runner->new(workflow => $workflow, project_dir => $project, docker => Local::RunnerDocker->new,
			quiet => 1, logger => Local::Logger->new, @_);
	};

	# What the runner prints, from the selected handle.
	my $printed = sub {
		my ($code) = @_;
		my $text = '';
		open my $handle, '>', \$text or die $!;
		my $old = select $handle;
		my $ok = eval { $code->(); 1 };
		my $error = $@;
		select $old;
		die $error unless $ok;
		return $text;
	};

	subtest 'new' => sub {
		my $object = $runner->();
		is_deeply([ @{$object}{qw(project_dir perl_image keep_images parallel pull_concurrency dry_run)} ],
			[ Cwd::abs_path($project), 'perl:%s', 1, 1, 4, 0 ], 'the defaults');
		is($runner->(explain => 1)->{dry_run}, 1, 'an explain run is a dry run');
		is($runner->(keep_images => 0)->{keep_images}, 0, 'keeping images is the opt-out');
		is($runner->(verbose => 'yes')->{verbose}, 1, 'flags are read for truth');
		like($object->{run_id}, qr/\A[0-9a-f]+\z/, 'a run id that is a plain name');
		isa_ok($runner->(docker => undef)->{docker}, 'App::Actions::Docker', 'a Docker client of its own');
		isa_ok($object->{$_->[0]}, $_->[1], "the $_->[0] part") for [ images => 'App::Actions::Runner::Images' ],
			[ containers => 'App::Actions::Runner::Containers' ], [ report => 'App::Actions::Runner::Report' ];
		memory_cycle_ok($object, 'no reference cycle between the runner and its parts');

		throws_code(sub { App::Actions::Runner->new(project_dir => $project) }, 'runner.workflow_required', 'A workflow is required', 'no workflow');
		throws_code(sub { App::Actions::Runner->new(workflow => $workflow) }, 'runner.project_dir_required', 'A project directory is required', 'no project');
		my $gone = File::Spec->catdir($project, 'gone');
		throws_code(sub { $runner->(project_dir => $gone) }, 'runner.project_dir_missing', "Project directory '$gone' does not exist", 'a project that is not there');
		my $file = write_file('plain', 'x');
		throws_code(sub { $runner->(project_dir => $file) }, 'runner.project_dir_missing', undef, 'a file is not a project');
		throws_code(sub { $runner->(pull => 1, no_pull => 1) }, 'runner.pull_conflict', '--pull and --no-pull cannot be used together', 'pull and no-pull');
		throws_ok { $runner->(colour => 1) } qr/\AInvalid arguments to App::Actions::Runner::new: Unknown parameter 'colour'/, 'an unknown option';
		throws_ok { $runner->(workflow => Local::Logger->new) } qr/'workflow'/, 'a workflow that cannot expand its jobs';
	};

	subtest 'option_rules, json_schema, preflight_schema_version and workflow' => sub {
		my $rules = App::Actions::Runner->option_rules;
		is_deeply($rules->{quiet}, { type => 'string', optional => 1 }, 'a flag is an optional string');
		$rules->{quiet}{type} = 'tampered';
		is(App::Actions::Runner->option_rules->{quiet}{type}, 'string', 'and the table is a copy');
		is(App::Actions::Runner->json_schema->{properties}{schema_version}{const}, App::Actions::Runner->preflight_schema_version,
			'the schema names its own version');
		is(App::Actions::Runner->json_schema->{version}, App::Actions::Runner->preflight_schema_version, 'in both places');
		is($runner->()->workflow, $workflow, 'workflow');
	};

	subtest '_pull_concurrency and _job_parallelism' => sub {
		local $ENV{ACTION_RUN_PULL_CONCURRENCY};
		is(App::Actions::Runner->_pull_concurrency(undef), 4, 'four by default');
		is(App::Actions::Runner->_pull_concurrency('7'), 7, 'the option');
		$ENV{ACTION_RUN_PULL_CONCURRENCY} = 3;
		is(App::Actions::Runner->_pull_concurrency(undef), 3, 'the environment');
		is(App::Actions::Runner->_pull_concurrency(''), 3, 'an empty option falls through to it');
		is(App::Actions::Runner->_pull_concurrency(9), 9, 'and the option wins over it');
		for my $bad ('0', '-1', '1.5', 'two', ' 2', '02', "2\n") {
			(my $shown = $bad) =~ s/\n/\\n/;
			throws_code(sub { App::Actions::Runner->_pull_concurrency($bad) }, 'runner.pull_concurrency_invalid',
				"pull concurrency must be a positive integer, not '$bad'", "'$shown' is refused");
		}
		throws_code(sub { App::Actions::Runner->_pull_concurrency([ 2 ]) }, 'runner.pull_concurrency_invalid', undef, 'a structure is refused');

		is(App::Actions::Runner::_job_parallelism($_->[0]), $_->[1], "parallel '" . (defined $_->[0] ? $_->[0] : 'undef') . "'")
			for [ undef, 1 ], [ 4, 4 ], [ '0', 1 ], [ 'x', 1 ], [ '-3', 1 ], [ [ 2 ], 1 ];
	};

	subtest '_shares_runner_files' => sub {
		my $me = eval { (getpwuid $<)[0] };
		is(App::Actions::Runner::_shares_runner_files($_), 0, "'" . (defined $_ ? $_ : 'undef') . "' needs no shared directory")
			for (undef, '', 'root', '0', '0:0', "$<", "$<:100", ':1');
		SKIP: {
			skip 'no user name here', 2 unless defined $me && length $me;
			is(App::Actions::Runner::_shares_runner_files($me), 0, 'nor does the user running this, by name');
			is(App::Actions::Runner::_shares_runner_files("$me:staff"), 0, 'with a group too');
		}
		is(App::Actions::Runner::_shares_runner_files('nobody-' . $$), 1, 'another user does');
		is(App::Actions::Runner::_shares_runner_files($< + 1), 1, 'and so does another uid');
	};

	subtest '_select_jobs and list_jobs' => sub {
		my $object = $runner->();
		my $instances = $workflow->expand_jobs;
		my $selected = $object->_select_jobs($instances);
		is(scalar @{$selected}, 5, 'every instance without a filter');
		is_deeply($object->{job_order}, [ qw(build test windows) ], 'job ids in workflow order');
		is(scalar @{ $object->{job_groups}{build} }, 3, 'grouped');

		$object = $runner->(jobs => [ 'test', $instances->[1]{display_name} ]);
		is_deeply([ map { $_->{display_name} } @{ $object->_select_jobs($instances) } ], [ $instances->[1]{display_name}, 'test' ],
			'a filter by id or display name, kept in workflow order');
		throws_code(sub { $runner->(jobs => [ 'deploy' ])->_select_jobs($instances) }, 'runner.no_job_matched', "No job matched 'deploy'",
			'a filter that matches nothing');

		my $text = $printed->(sub { is($runner->()->list_jobs, 0, 'list_jobs returns 0') });
		is(scalar(() = $text =~ /\n/g), 5, 'one line per instance');
		like($text, qr/\Abuild\t/, 'id, a tab, then the display name');
	};

	subtest '_truthy_scalar and _log_root' => sub {
		is(App::Actions::Runner::_truthy_scalar($_->[0]), $_->[1], 'fail-fast ' . (defined $_->[0] ? "'$_->[0]'" : 'undef'))
			for [ JSON::PP::true(), 1 ], [ JSON::PP::false(), 0 ], [ undef, 0 ], [ 'false', 0 ], [ 'No', 0 ], [ '0', 0 ],
				[ 'true', 1 ], [ '', 0 ], [ !!0, 0 ], [ !!1, 1 ], [ 'maybe', 1 ];
		is($runner->(log_dir => '/logs')->_log_root, '/logs', 'log_dir');
		is($runner->(log_dir => '')->_log_root, App::Actions::Logs->default_directory, 'else the default');
	};

	subtest '_prepare_temp, _write_shim and _build_base_env' => sub {
		my $object = $runner->();
		$object->_prepare_temp;
		my $temp = $object->{temp_path};
		ok(-d File::Spec->catdir($temp, $_), "the $_ directory") for qw(_temp _tool home scripts env output summary path event bin aptbin);
		is((stat $temp)[2] & oct('07777'), oct('0700'), 'private');
		is((stat File::Spec->catfile($temp, 'bin', 'sudo'))[2] & oct('0777'), oct('0755'), 'the sudo shim is executable');
		like(do { open my $h, '<', File::Spec->catfile($temp, 'aptbin', 'apt-get') or die $!; local $/; <$h> }, qr{exec /usr/bin/apt-get "\$\@"},
			'the apt shims call the real program');

		my $guard = mock_scoped('App::Actions::Runner::_git' => sub {
			my (undef, @args) = @_;
			return $args[0] eq 'config' ? "git\@github.com:owner/repo.git\n" : $args[0] eq 'symbolic-ref' ? "feature\n" : "abc123\n";
		});
		$object->_build_base_env;
		my $env = $object->{base_env};
		is_deeply([ @{$env}{qw(GITHUB_REPOSITORY GITHUB_REPOSITORY_OWNER GITHUB_REF GITHUB_SHA CI GITHUB_WORKFLOW HOME)} ],
			[ 'owner/repo', 'owner', 'refs/heads/feature', 'abc123', 'true', 'CI', '/root' ], 'values from the checkout');
		ok(!exists $env->{RUNNER_DEBUG}, 'no debug unless verbose');
		my $event = JSON::PP->new->decode(do { open my $h, '<', File::Spec->catfile($temp, 'event.json') or die $!; local $/; <$h> });
		is($event->{repository}{name}, 'repo', 'event.json is written');
		is((stat File::Spec->catfile($temp, 'event.json'))[2] & oct('0777'), oct('0600'), 'privately');
		# The run's own earlier event.json is removed and made afresh, never
		# opened for writing as it stands (which would follow a planted link).
		$object->_build_base_env;
		is((stat File::Spec->catfile($temp, 'event.json'))[2] & oct('0777'), oct('0600'), 'a second build replaces it, still private');
		undef $guard;

		my $parallel_root = File::Spec->catdir(tempdir(CLEANUP => 1), 'job-1');
		my $child = $runner->();
		$child->_prepare_temp($parallel_root);
		is($child->{temp_path}, $parallel_root, 'a parallel job uses the directory it is given');

		my $shared = $runner->(user => 'nobody-' . $$, quiet => 0);
		$shared->_prepare_temp;
		is((stat $shared->{temp_path})[2] & oct('07777'), oct('1777'), 'a shared directory is sticky');
		like($shared->{logger}{lines}[0][1], qr/nobody-$$/, 'and the user is told');
		remove_tree_quietly($_) for $temp, $shared->{temp_path};
	};

	subtest '_repository_env' => sub {
		my %remotes = (
			'https://github.com/o/r.git' => 'o/r', 'git@github.com:o/r' => 'o/r', 'ssh://git@github.com/o/r/' => 'o/r',
			'https://gitlab.com/o/r.git' => undef, '' => undef,
		);
		for my $remote (sort keys %remotes) {
			my $object = $runner->();
			my $guard = mock_scoped('App::Actions::Runner::_git' => sub { $_[1] eq 'config' ? $remote : '' });
			my $env = $object->_repository_env;
			is($env->{GITHUB_REPOSITORY}, defined $remotes{$remote} ? $remotes{$remote} : File::Basename::basename($object->{project_dir}),
				"remote '$remote'");
			is_deeply([ @{$env}{qw(GITHUB_REF_NAME GITHUB_SHA)} ], [ 'main', '0' x 40 ], 'with no git, main and a zero commit');
			is($object->_repository_env, $env, 'and asked once');
		}
		my $started = time;
		my $object = $runner->();
		my $guard = mock_scoped('App::Actions::Runner::_git' => sub { $_[1] eq 'config' ? 'github.com:' . ('a/' x $config{big}) : '' });
		$object->_repository_env;
		ok(time - $started <= $config{time_limit}, 'a hostile remote is matched in linear time');
	};

	subtest '_github_context and _preflight_context' => sub {
		my $object = $runner->();
		my $guard = mock_scoped('App::Actions::Runner::_git' => sub { '' });
		my $github = $object->_github_context({ base_id => 'build' });
		is_deeply([ @{$github}{qw(job event_name ref workspace token)} ], [ 'build', 'push', 'refs/heads/main', '/github/workspace', '' ],
			'a context before the base environment exists');
		is($object->_github_context('test')->{job}, 'test', 'a job id is enough');
		my $context = $object->_preflight_context({ matrix => { v => 1 }, matrix_index => 0, matrix_total => 3 });
		is_deeply([ $context->{matrix}, $context->{needs}, $context->{strategy} ], [ { v => 1 }, {}, { 'job-index' => 0, 'job-total' => 3 } ],
			'needs are unknown before the run');
		$context->{env}{X} = 1;
		ok(!exists $object->{env}{X}, 'and the env is a copy');
	};

	subtest '_plan_instance and _admit' => sub {
		my $object = $runner->(secrets => { T => 'hunter2' });
		my $guard = mock_scoped('App::Actions::Runner::_git' => sub { '' });
		my $plan = $object->_plan_instance({ base_id => 'a', display_name => 'a hunter2', strategy => {} }, {}, 0, 1);
		is_deeply([ @{$plan}{qw(display_name should_run error fail_fast)} ], [ 'a ***', 1, undef, 1 ], 'a plain job runs; its name is redacted');
		is($object->_plan_instance({ base_id => 'a', strategy => {} }, {}, 1, 1)->{should_run}, 0, 'one whose needs failed does not');
		is($object->_plan_instance({ base_id => 'a', if => 'always()', strategy => {} }, {}, 1, 1)->{should_run}, 1, 'unless it says always()');
		is($object->_plan_instance({ base_id => 'a', if => 'true', strategy => {} }, {}, 1, 1)->{should_run}, 0, 'a condition with no status function is not enough');
		is($object->_plan_instance({ base_id => 'a', if => "github.job == 'b'", strategy => {} }, {}, 0, 1)->{should_run}, 0, 'a false condition');
		$plan = $object->_plan_instance({ base_id => 'a', display_name => 'a', if => 'nope(', strategy => {} }, {}, 0, 1);
		ok(defined $plan->{error}, 'a condition that does not evaluate');

		my $group = { result => 'skipped' };
		$object = $runner->(quiet => 0);
		my $out = $printed->(sub { is($object->_admit($plan, {}, $group), 0, 'is not admitted') });
		is_deeply([ $group->{result}, $object->{report}->failed ], [ 'failure', 1 ], 'and fails the run');
		like($object->{logger}{lines}[0][1], qr/\Aaction-run: unable to evaluate if for 'a': /, 'with a warning');
		$out = $printed->(sub { $object->_admit({ instance => { display_name => 's' }, display_name => 's', should_run => 0 }, {}, $group) });
		is($out, "==> Job: s (skipped)\n", 'a skipped job is said');
		my $runs = { instance => { display_name => 'r' }, display_name => 'r', should_run => 1 };
		is($object->_admit($runs, { x => 1 }, $group), 1, 'a runnable plan is admitted');
		is_deeply($runs->{instance}{needs_results}, { x => 1 }, 'with its needs');
	};

	subtest '_record_instance_result' => sub {
		my $object = $runner->();
		my $group = { result => 'skipped', stop => 0 };
		my $plan = { instance => { display_name => 'a' }, display_name => 'a', context => {}, fail_fast => 1 };
		$object->_record_instance_result($plan, { result => 'success' }, $group);
		is($group->{result}, 'success', 'a success');
		$object->_record_instance_result($plan, { result => 'skipped' }, $group);
		is($group->{result}, 'success', 'a skipped one changes nothing');
		$object->_record_instance_result($plan, { result => 'failure' }, $group);
		is_deeply([ @{$group}{qw(result stop)}, $object->{report}->failed ], [ 'failure', 1, 1 ], 'a failure stops a fail-fast group');

		# continue-on-error lets the rest of the matrix go on, as on GitHub.
		$object = $runner->();
		$group = { result => 'skipped', stop => 0 };
		my $continuing = { %{$plan}, instance => { display_name => 'b', 'continue-on-error' => 'true' } };
		$object->_record_instance_result($continuing, { result => 'failure' }, $group);
		is_deeply([ @{$group}{qw(result stop)}, $object->{report}->failed ], [ 'failure', 0, 0 ],
			'a failure that may happen stops nothing and fails nothing');

		$object = $runner->(quiet => 0);
		$group = { result => 'skipped', stop => 0 };
		$printed->(sub { $object->_record_instance_result({ %{$plan}, instance => { display_name => 'c', 'continue-on-error' => 'nope(' } }, { result => 'failure' }, $group) });
		is_deeply([ $group->{stop}, $object->{report}->failed ], [ 1, 1 ], 'one that does not evaluate does not continue');
		like($object->{logger}{lines}[0][1], qr/continue-on-error for 'a'/, 'and says so');
	};

	subtest '_run_base_job and _run_groups' => sub {
		my @ran;
		my %result = (build => 'success', test => 'success');
		my $guard = mock_scoped('App::Actions::Runner::_run_instance' => sub { push @ran, $_[1]{display_name}; { result => $result{ $_[1]{base_id} } || 'skipped' } });
		my $git = mock_scoped('App::Actions::Runner::_git' => sub { '' });
		my $object = $runner->();
		$object->_select_jobs($workflow->expand_jobs);
		my $results = $object->_run_groups;
		is_deeply([ map { $results->{$_}{result} } qw(build test windows) ], [ qw(success success skipped) ], 'every job, needs first');
		is(scalar @ran, 5, 'each instance ran once');

		@ran = ();
		$result{build} = 'failure';
		$object = $runner->();
		$object->_select_jobs($workflow->expand_jobs);
		$results = $object->_run_groups;
		is(scalar(grep { /build/ } @ran), 1, 'fail-fast stops the rest of the matrix');
		ok(!grep({ $_ eq 'test' } @ran), 'and a job that needs it is skipped');
		is($results->{test}{result}, 'skipped', 'as its result says');

		$object = $runner->(jobs => [ 'test' ], quiet => 0);
		$object->_select_jobs($workflow->expand_jobs);
		$printed->(sub { $object->_run_groups });
		like($object->{logger}{lines}[0][1], qr/needs 'build', which was not selected; assuming it succeeded/, 'a need not selected is assumed');

		my $cyclic = App::Actions::Workflow->load(write_file('cycle.yml', "on: push\njobs:\n  a: {needs: b, runs-on: x, steps: [{run: x}]}\n  b: {needs: a, runs-on: x, steps: [{run: x}]}\n"));
		$object = eval { App::Actions::Runner->new(workflow => $cyclic, project_dir => $project, docker => Local::RunnerDocker->new, quiet => 1) };
		SKIP: {
			skip 'the workflow refuses a cycle itself', 1 unless $object && eval { $object->_select_jobs($cyclic->expand_jobs); 1 };
			throws_code(sub { $object->_run_groups }, 'runner.dependency_cycle', undef, 'a dependency cycle is refused');
		}
		throws_code(sub { $runner->()->_run_base_job('ghost', { results => {}, visited => {}, running => {} }) }, 'runner.unknown_job',
			"Unknown job 'ghost'", 'an unknown job');
	};

	subtest '_runs_in_parallel' => sub {
		is($runner->(parallel => 4)->_runs_in_parallel, 1, 'parallel');
		is($runner->()->_runs_in_parallel, 0, 'not by default');
		is($runner->(parallel => 4, $_ => 1)->_runs_in_parallel, 0, "not with $_") for qw(keep dry_run explain);
	};

	subtest '_run_instance' => sub {
		my $git = mock_scoped('App::Actions::Runner::_git' => sub { '' });
		# The skip is reported, naming the job and the runner it asked for, so
		# a reader knows why it did not run; quiet says nothing.
		my $windows_job = { base_id => 'w', display_name => 'w', 'runs-on' => 'windows-latest' };
		my $object = $runner->(quiet => 0);
		my $windows = $printed->(sub { is($object->_run_instance($windows_job, {})->{result},
			'skipped', 'a job that is not for Linux is skipped') });
		is($windows, "==> Job: w (skipped: runs-on 'windows-latest' is not Linux)\n", 'and the skip says why');
		$object = $runner->();
		is($printed->(sub { $object->_run_instance($windows_job, {}) }), '', 'but not when quiet');

		my (@cleaned, $steps_dies);
		my $guards = [
			mock_scoped('App::Actions::Runner::Images::prepare_job' => sub { { image => 'ubuntu:latest', deferred => [] } }),
			mock_scoped('App::Actions::Runner::Containers::create_network' => sub { 'net' }),
			mock_scoped('App::Actions::Runner::Containers::start_services' => sub { [] }),
			mock_scoped('App::Actions::Runner::Containers::start_job' => sub { 'job-c' }),
			mock_scoped('App::Actions::Runner::Containers::inspect' => sub { { path => '/bin', has_bash => 1 } }),
			mock_scoped('App::Actions::Runner::Containers::check_services' => sub { $_[0] }),
			mock_scoped('App::Actions::Runner::Containers::cleanup_job' => sub { push @cleaned, [ @_[1, 2] ]; $_[0] }),
			mock_scoped('App::Actions::Runner::Steps::run' => sub { die "steps exploded\n" if $steps_dies; { result => 'success' } }),
		];
		$object = $runner->(env => { FROM_CLI => 'yes' });
		$object->_prepare_temp;
		$object->_build_base_env;
		my $job = { base_id => 'b', display_name => 'b', 'runs-on' => 'ubuntu-latest', env => { JOB => '${{ github.job }}' } };
		is($object->_run_instance($job, { github => { job => 'b' } })->{result}, 'success', 'a job that runs');
		is_deeply(\@cleaned, [ [ 'net', [ 'job-c' ] ] ], 'and is cleaned up');

		@cleaned = ();
		$steps_dies = 1;
		throws_ok { $object->_run_instance($job, { github => {} }) } qr/\Asteps exploded$/, 'an infrastructure failure propagates';
		is_deeply(\@cleaned, [ [ 'net', [ 'job-c' ] ] ], 'after cleaning up');

		my $no_image = mock_scoped('App::Actions::Runner::Images::prepare_job' => sub { { image => ' ', deferred => [] } });
		throws_code(sub { $object->_run_instance($job, {}) }, 'runner.job.no_image', "Unable to determine a container image for job 'b'",
			'a job with no image');
		remove_tree_quietly($object->{temp_path});
	};

	subtest '_reach_docker, _run_check, _skipped_images and _preflight_result' => sub {
		my $object = $runner->();
		my $reached = $object->_reach_docker;
		is_deeply([ @{$reached}{qw(reachable exit error)} ], [ 1, 0, undef ], 'a daemon that answers');
		my $down = $runner->(docker => Local::RunnerDocker->new(down => 1))->_reach_docker;
		is_deeply([ @{$down}{qw(reachable error)} ], [ 0, 'Cannot connect to the Docker daemon' ], 'one that does not');
		is($down->{summary}{issues}[0]{problem}, 'Cannot connect to the Docker daemon', 'is the problem');
		is($object->_docker_bin, 'docker', '_docker_bin');
		is($runner->(docker => Local::SilentDocker->new)->_docker_bin, undef, 'a client that will not say');

		my $result = $object->_preflight_result($down->{summary}, 0, $down->{summary}{issues}, [], 1, 'down');
		is_deeply([ $result->{exit}, $result->{error}, $result->{summary}{ready} ], [ 2, 'down', JSON::PP::false() ], 'a JSON result, validated');
		my $guard = mock_scoped('App::Actions::Schema::assert_valid' => sub { die "schema mismatch\n" });
		throws_ok { $object->_preflight_result($down->{summary}, 0, [], [], 1, undef) } qr/\Aschema mismatch$/, 'a document that does not match';
		is($object->_preflight_result({}, 1, [], [], 0, undef)->{exit}, 0, 'but a text result is not checked');
		undef $guard;

		my $git = mock_scoped('App::Actions::Runner::_git' => sub { '' });
		$object->_select_jobs($workflow->expand_jobs);
		my $skipped = $object->_skipped_images($object->{instances});
		is_deeply([ map { $_->{status} } @{$skipped} ], [ 'skipped' ], 'what a run that is not ready would have needed');
		$guard = mock_scoped('App::Actions::Check::run' => sub { 2 });
		my $check = $object->_run_check($object->{instances}, 1);
		is_deeply([ @{$check}{qw(reachable exit)} ], [ 1, 2 ], '_run_check');
	};

	subtest 'run and _cleanup' => sub {
		my $git = mock_scoped('App::Actions::Runner::_git' => sub { '' });
		my $base = mock_scoped('App::Actions::Runner::_check_environment' => sub { return });
		my $groups = mock_scoped('App::Actions::Runner::_run_groups' => sub { $_[0]{report}->record('a', 'success'); {} });
		my $object = $runner->();
		is($object->run, 0, 'a run that succeeds is 0');
		ok(!-d $object->{temp_path}, 'and leaves no temporary directory');
		is($object->{cleaned_up}, 1, 'cleaned up once');
		$object->_cleanup;
		is($object->{cleaned_up}, 2, 'and a second cleanup does nothing');

		undef $groups;
		$groups = mock_scoped('App::Actions::Runner::_run_groups' => sub { $_[0]{report}->record('a', 'failure')->fail; {} });
		is($runner->()->run, 1, 'a job that fails is 1');

		undef $groups;
		$groups = mock_scoped('App::Actions::Runner::_run_groups' => sub { die "daemon went away\n" });
		$object = $runner->(quiet => 0);
		$printed->(sub { is($object->run, 2, 'a run that breaks is 2') });
		is_deeply($object->{logger}{lines}, [ [ error => 'action-run: daemon went away' ] ], 'and says why');
		ok(!-d $object->{temp_path}, 'after cleaning up');

		undef $groups;
		$groups = mock_scoped('App::Actions::Runner::_run_groups' => sub { kill 'INT', $$; sleep 1; {} });
		is($runner->()->run, 2, 'an interrupt becomes an error, and the run still cleans up');

		undef $groups;
		$groups = mock_scoped('App::Actions::Runner::_run_groups' => sub { {} });
		$object = $runner->(keep_images => 0);
		$object->{images}->note_pulled('pulled:1');
		$object->run;
		is_deeply($object->{docker}{removed}, [ 'pulled:1' ], 'a run not keeping its images removes what it pulled');
		$object = $runner->(keep => 1);
		my $out = '';
		{
			open my $h, '>', \$out or die $!;
			my $old = select $h;
			$object->run;
			select $old;
		}
		ok(-d $object->{temp_path}, '--keep keeps the temporary directory');
		like($out, qr/\Q$object->{temp_path}\E/, 'and says where it is');
		remove_tree_quietly($object->{temp_path});
	};
};

# Removes a directory a test made, ignoring one already gone.
sub remove_tree_quietly {
	my ($dir) = @_;
	require File::Path;
	File::Path::remove_tree($dir) if defined $dir && -d $dir;
	return;
}

# ---------------------------------------------------------------------------
# App::Actions
# ---------------------------------------------------------------------------

use App::Actions;

subtest 'App::Actions' => sub {
	# A repository with its workflow where GitHub keeps it, so the project
	# directory can be worked out from the workflow's path.
	my $repository = tempdir(CLEANUP => 1);
	require File::Path;
	File::Path::make_path(File::Spec->catdir($repository, '.github', 'workflows'));
	my $file = write_file('ci.yml', "name: CI\non: push\njobs:\n  a:\n    runs-on: ubuntu-latest\n    steps: [{run: echo}]\n",
		File::Spec->catdir($repository, '.github', 'workflows'));
	my $actions = sub { return App::Actions->new(workflow_file => $file, docker => Local::RunnerDocker->new, logger => 'NULL', @_) };

	subtest 'new and the accessors' => sub {
		my $object = $actions->();
		is($object->project_dir, Cwd::abs_path($repository), 'the project is the repository the workflow is in');
		is($object->workflow_file, Cwd::abs_path($file), 'the workflow file, absolute');
		isa_ok($object->workflow, 'App::Actions::Workflow');
		is_deeply($object->{jobs}, [], 'no job filter');
		my $elsewhere = tempdir(CLEANUP => 1);
		is($actions->(project_dir => $elsewhere)->project_dir, Cwd::abs_path($elsewhere), 'an explicit project wins');
		memory_cycle_ok($object, 'no reference cycle');

		throws_code(sub { App::Actions->new }, 'actions.workflow_file_required', 'workflow_file is required', 'no workflow');
		my $missing = File::Spec->catfile($repository, 'none.yml');
		throws_code(sub { App::Actions->new(workflow_file => $missing) }, 'actions.workflow_file_missing',
			"Workflow file '$missing' does not exist", 'a workflow that is not there');
		throws_code(sub { App::Actions->new(workflow_file => $repository) }, 'actions.workflow_file_missing', undef, 'a directory is not a workflow');
		my $loose = write_file('loose.yml', "on: push\njobs:\n  a: {runs-on: x, steps: [{run: x}]}\n");
		throws_code(sub { App::Actions->new(workflow_file => $loose) }, 'actions.project_dir_required',
			'project_dir is required when the workflow is not inside .github/workflows', 'a workflow elsewhere needs a project');
		my $gone = File::Spec->catdir($repository, 'gone');
		throws_code(sub { $actions->(project_dir => $gone) }, 'actions.project_dir_missing', "Project directory '$gone' does not exist",
			'a project that is not there');
		throws_ok { $actions->(colour => 1) } qr/\AInvalid arguments to App::Actions::new: Unknown parameter 'colour'/, 'an unknown option';
		throws_ok { $actions->(jobs => 'a') } qr/'jobs'/, 'a job filter must be a list';
	};

	subtest '_project_dir' => sub {
		is(App::Actions->_project_dir(undef, "$repository/.github/workflows/ci.yml"), Cwd::abs_path($repository), 'from the workflow path');
		is(App::Actions->_project_dir(undef, '/.github/workflows/ci.yml'), '/', 'a repository at the root is the root, not the current directory');
		is(App::Actions->_project_dir(undef, "$repository/.github/workflows/odd\nname.yml"), Cwd::abs_path($repository),
			'a file name with a newline in it is still in the workflows folder');
		throws_code(sub { App::Actions->_project_dir(undef, "$repository/.github/workflows/sub/ci.yml") }, 'actions.project_dir_required', undef,
			'nor does one in a folder below the workflows');
		throws_code(sub { App::Actions->_project_dir(undef, "$repository/github/workflows/ci.yml") }, 'actions.project_dir_required', undef,
			'nor one that only looks like it');
	};

	subtest '_logger' => sub {
		my $object = Local::Logger->new;
		is(App::Actions::_logger($object), $object, 'an object is used as it is');
		my @lines;
		my $array = App::Actions::_logger(\@lines);
		isa_ok($array, 'Log::Abstraction');
		$array->warn('collected');
		ok(scalar(grep { /collected/ } map { ref $_ ? $_->{message} : $_ } @lines), 'an array collects the messages');
		my $null = App::Actions::_logger('NULL');
		isa_ok($null, 'Log::Abstraction');
		my $stderr = '';
		{
			local *STDERR;
			open STDERR, '>', \$stderr or die $!;
			$null->error('never seen');
		}
		is($stderr, '', 'NULL is silent');
		isa_ok(App::Actions::_logger({ level => 'error' }), 'Log::Abstraction', 'a hash of options');
		throws_ok { App::Actions->new(workflow_file => $file, logger => sub { }) } qr/'logger'/, 'a code reference is not one of the forms';
	};

	subtest 'the logger argument wins over the configuration' => sub {
		my $config = tempdir(CLEANUP => 1);
		write_file('app-actions.yml', "App__Actions:\n  logger:\n    level: debug\n", $config);
		local $ENV{CONFIG_DIR} = $config;
		my $mine = Local::Logger->new;
		is($actions->(logger => $mine)->{logger}, $mine, 'a logger given to new is kept');
	};

	subtest '_overrides and _runner' => sub {
		my $object = $actions->(quiet => 1, image => 'mine:1');
		is_deeply($object->_overrides('run', [ verbose => 1 ]), { verbose => 1 }, 'an override');
		is_deeply($object->_overrides('run', []), {}, 'none');
		throws_ok { $object->_overrides('run', [ colour => 1 ]) } qr/\AInvalid arguments to App::Actions::run: Unknown parameter 'colour'/,
			'an unknown override names the method';
		my $runner = $object->_runner({ image => undef, verbose => 1 });
		isa_ok($runner, 'App::Actions::Runner');
		is_deeply([ @{$runner}{qw(image verbose quiet)} ], [ undef, 1, 1 ], 'an override replaces, even with undef; the rest are the object\'s');
		is($object->_runner({ docker => undef })->{docker}, $object->{docker}, 'an undef docker keeps the object\'s');
	};

	subtest 'run, preflight and list_jobs' => sub {
		my $object = $actions->(quiet => 1);
		my %seen;
		my $guard = mock_scoped('App::Actions::Runner::run' => sub { $seen{run} = $_[0]{verbose}; 0 });
		is($object->run(verbose => 1), 0, 'run is the runner\'s');
		is($seen{run}, 1, 'with the overrides');
		undef $guard;

		$guard = mock_scoped('App::Actions::Runner::preflight' => sub { my (undef, %options) = @_; $seen{preflight} = { %options }; { exit => 0 } });
		$object->preflight(json => 1, schema_line => 0);
		is_deeply($seen{preflight}, { json => 1, schema_line => 0 }, 'json and schema_line go to the preflight');
		throws_ok { $object->preflight(loud => 1) } qr/\AInvalid arguments to App::Actions::preflight: Unknown parameter 'loud'/, 'an unknown option';
		undef $guard;

		$guard = mock_scoped('App::Actions::Runner::list_jobs' => sub { $seen{list} = [ @{ $_[0] }{qw(dry_run quiet)} ]; 0 });
		$object = $actions->();
		$object->list_jobs(dry_run => 0);
		is_deeply($seen{list}, [ 1, 1 ], 'listing never runs or prints anything but the list');
	};

	subtest 'json_schema' => sub {
		for my $name (qw(check preflight cache logs)) {
			is(ref App::Actions->json_schema($name), 'HASH', "the $name schema");
		}
		is_deeply(App::Actions->json_schema('preflight'), App::Actions::Runner->json_schema, 'each from its own module');
		throws_code(sub { App::Actions->json_schema }, 'actions.document_required', 'A document name is required', 'no name');
		throws_code(sub { App::Actions->json_schema('') }, 'actions.document_required', undef, 'an empty name');
		throws_code(sub { App::Actions->json_schema('Check') }, 'actions.document_unknown',
			"Unknown document 'Check'; expected check, preflight, cache or logs", 'names are exact');
		throws_code(sub { App::Actions->json_schema('../etc/passwd') }, 'actions.document_unknown', undef, 'a path is just an unknown name');
		throws_ok { App::Actions->json_schema([]) } qr/'name'/, 'a name that is not a string';
	};
};

# ---------------------------------------------------------------------------
# The cache and logs listings, and the lines a child process prints, in the
# chosen language
# ---------------------------------------------------------------------------

subtest 'translated listings and child messages' => sub {
	# The listings were English text written into the code; they now come
	# from the catalogues.  English must read exactly as before, another
	# language must replace every sentence and heading, and the columns must
	# still line up when a heading is longer than its English one.  Only
	# ASCII French is compared, so this file stays ASCII.
	my $fresh = sub {
		my $cache = App::Actions::Cache->new(file => File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json'));
		$cache->{data} = { format => 1, images => {} };
		return $cache;
	};

	subtest 'Cache::_heading_line and _nothing_selected' => sub {
		my $cache = $fresh->();
		is($cache->_heading_line, "Cache file: $cache->{file}\n", 'the first line names the record');
		is($cache->_nothing_selected(undef), "No images have been cached yet.\n", 'an empty record');
		is($cache->_nothing_selected($DAY), "No images have been cached yet.\n",
			'a threshold over an empty record still says nothing was cached, not that nothing is old');
		$cache->{data}{images}{'perl:5.40'} = { pulls => 1, last_used => time };
		is($cache->_nothing_selected($DAY), "No cached images are older than 1 day.\n", 'images, none old enough');
		is($cache->_nothing_selected(undef), "No images have been cached yet.\n",
			'without a threshold there is nothing to be too young for');
		my $file = $cache->{file};
		$cache->{file} = "a\nb";
		is($cache->_heading_line, "Cache file: a\nb\n", 'a name is shown as it is, not interpreted');
		$cache->{file} = $file;
		memory_cycle_ok($cache, 'no reference cycle');
	};

	subtest 'Logs::_heading_line and _nothing_selected' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $logs = App::Actions::Logs->new(directory => $dir);
		is($logs->_heading_line, "Logs directory: $dir\n", 'the first line names the directory');
		is($logs->_nothing_selected(undef), "No job logs have been kept yet.\n", 'nothing kept');
		is($logs->_nothing_selected($DAY), "No job logs have been kept yet.\n", 'a threshold over nothing');
		my $guard = mock_scoped('App::Actions::Logs::entries' => sub { [ { name => 'run' } ] });
		is($logs->_nothing_selected($DAY), "No job logs are older than 1 day.\n", 'logs, none old enough');
	};

	subtest 'a French listing' => sub {
		local $ENV{ACTION_RUN_LANG} = 'fr';
		my $cache = $fresh->();
		my $now = time;
		$cache->{data}{images}{'ubuntu:latest'} = { pulls => 1, last_used => $now - 2 * 3600 };
		my $out = $cache->report(now => $now);
		like($out, qr/\AFichier du cache : /, 'the first line is French');
		like($out, qr/il y a 2 heures$/m, 'and so is the age');
		unlike($out, qr/Cache file|LAST USED|\bago\b|not reachable|unknown/, 'no English is left');

		# The heading row and the image row put each column at the same
		# place, though "DERNIERE UTILISATION" is wider than a date.
		my ($heading, $row) = grep { /\A  \S/ } split /\n/, $out;
		my $at = sub { my ($line, $word) = @_; return index($line, $word) };
		ok($at->($heading, 'TAILLE') >= 0, 'the size heading is translated');
		my @heading_starts = map { $-[0] } $heading =~ /(?<=  )\S/g;
		my @row_starts = map { $-[0] } $row =~ /(?<=  )\S/g;
		is($row_starts[0], $heading_starts[0], 'the image column starts where its heading does');
		is($row_starts[-1], $heading_starts[-1], 'and so does the age column, after the widened date column');

		my $empty = $fresh->();
		like($empty->report, qr/^Aucune image n.a encore/m, 'an empty record says so in French');
		my $json = $cache->document(now => $now);
		is($json->{images}[0]{image}, 'ubuntu:latest', 'the JSON document is not translated');
	};

	subtest 'a French child process message' => sub {
		local $ENV{ACTION_RUN_LANG} = 'fr';
		my $dir = tempdir(CLEANUP => 1);
		my $err = File::Spec->catfile($dir, 'err');
		my $missing = File::Spec->catfile($dir, 'missing');
		# Two commands at once, so each runs in a child of its own; a single
		# command is run in this process, where a missing program is 255.
		my $codes = App::Actions::Process::run_parallel([ [ $missing ], perl_command('exit 0') ],
			concurrency => 2, stderr => $err);
		is_deeply($codes, [ $STATUS{not_found}, 0 ], 'a program that cannot run is still 127');
		open my $handle, '<', $err or die $!;
		like(do { local $/; <$handle> }, qr/\AImpossible d.ex.cuter '\Q$missing\E' : /, 'and the child says why in French');
		close $handle;

		# run_parallel opens the output files before it forks, so a file the
		# child cannot open is only reached by calling the child's routine in
		# a child: a directory is not a file it can write.
		my $pid = fork;
		die "fork: $!" unless defined $pid;
		if ($pid == 0) {
			open STDERR, '>', $err or POSIX::_exit(2);
			App::Actions::Process::_redirect_child(stdout => $dir);
			POSIX::_exit(0);
		}
		waitpid $pid, 0;
		is($? >> 8, $STATUS{not_found}, 'an output the child cannot open stops it with 127');
		open $handle, '<', $err or die $!;
		like(do { local $/; <$handle> }, qr/\AImpossible de rediriger stdout vers '\Q$dir\E' : /, 'and says so in French');
		close $handle;
	};
};

restore_all();
done_testing();
