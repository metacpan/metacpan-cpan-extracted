use strict;
use warnings;

# Black-box tests of every public routine in lib/, written against the API
# its POD documents: the arguments it takes, what it returns, and every
# message and status the POD lists.  Private routines (_name) are never
# called here; t/function.t covers those.
#
# A ledger, filled at the start, holds every message key the catalogue
# defines and every return status the POD documents.  A message key is
# struck off when the code renders it (a spy on App::Actions::I18N::message
# sees each one); a status is struck off by the test that asserts it.  The
# script ends by asserting the ledger is empty, so a message or status no
# test reaches is a failure, not a gap nobody sees.

# Some documented failures need the operating system to refuse: a handle that
# cannot be duplicated or restored, a temporary file that cannot be rewound.
# Process.pm, Check.pm, Runner/Parallel.pm and Runner.pm (with what they
# load) are compiled with open, seek and fork overridden, so a test can make one
# particular call fail by setting a rule in %FAIL; with no rule every call
# goes straight to the real one.  The override is removed again before
# anything else is compiled.
our %FAIL;
BEGIN {
	require File::Spec;
	require File::Temp;
	require IO::Handle;
	require POSIX;
	require Symbol;
	require App::Actions::I18N;

	no warnings 'once';
	*CORE::GLOBAL::open = sub (*;$@) {
		if (my $rule = $main::FAIL{open}) {
			if ($rule->(@_)) {
				$! = POSIX::EBADF();
				return 0;
			}
		}
		# A bareword handle (STDOUT) arrives as its name.
		my $handle = (defined $_[0] && !ref $_[0]) ? Symbol::qualify_to_ref($_[0], scalar caller) : undef;
		return $handle
			? (@_ > 2 ? CORE::open($handle, $_[1], @_[2 .. $#_]) : CORE::open($handle, $_[1]))
			: (@_ > 2 ? CORE::open($_[0], $_[1], @_[2 .. $#_]) : CORE::open($_[0], $_[1]));
	};
	*CORE::GLOBAL::seek = sub (*$$) {
		if ($main::FAIL{seek}) {
			$! = POSIX::ESPIPE();
			return 0;
		}
		return CORE::seek($_[0], $_[1], $_[2]);
	};
	*CORE::GLOBAL::fork = sub () {
		if ($main::FAIL{fork}) {
			$! = POSIX::EAGAIN();
			return undef;
		}
		return CORE::fork();
	};
	require App::Actions::Process;
	require App::Actions::Check;
	require App::Actions::Runner::Parallel;
	require App::Actions::Runner;
	delete $CORE::GLOBAL::{open};
	delete $CORE::GLOBAL::{seek};
	delete $CORE::GLOBAL::{fork};
}

use Cwd ();
use Data::Dumper ();
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use POSIX ();
use Readonly;
use Scalar::Util qw(blessed);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

use App::Actions;
use App::Actions::Access;
use App::Actions::Action;
use App::Actions::Cache;
use App::Actions::Check;
use App::Actions::Docker;
use App::Actions::Docker::Variable;
use App::Actions::Error;
use App::Actions::Expression;
use App::Actions::I18N;
use App::Actions::Logs;
use App::Actions::Process;
use App::Actions::Runner;
use App::Actions::Runner::Containers;
use App::Actions::Runner::Images;
use App::Actions::Runner::Parallel;
use App::Actions::Runner::Report;
use App::Actions::Runner::Steps;
use App::Actions::Runner::Support;
use App::Actions::Runner::Support::Env;
use App::Actions::Schema;
use App::Actions::Schema::Invalid;
use App::Actions::Util;
use App::Actions::Workflow;

# Nothing here may depend on the environment of whoever runs the suite: the
# language, a developer's ~/.conf (Object::Configure reads it), or the real
# cache and log directories.
delete local $ENV{ACTION_RUN_LANG};
local $ENV{CONFIG_DIR} = tempdir(CLEANUP => 1);
local $ENV{ACTION_RUN_CACHE_FILE} = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
local $ENV{ACTION_RUN_LOG_DIR} = File::Spec->catdir(tempdir(CLEANUP => 1), 'logs');

Readonly::Hash my %config => (
	sentinel   => 'caller value',	# what $_, $@ and $! hold before a call
	errno      => POSIX::ENOENT(),	# the $! a routine must leave alone
	alarm      => 100,		# a caller's countdown, which must survive
	big        => 100_000,		# the size of a hostile input
	time_limit => 2,		# seconds a hostile input may take
);

# ---------------------------------------------------------------------------
# The ledger
# ---------------------------------------------------------------------------

# What the POD documents beyond the catalogue: return statuses ("status ...")
# and messages that are not catalogue entries ("text ...": a croak with a
# literal, or a problem a function returns rather than throws).  The test
# that asserts one calls settle() with the same text.
Readonly::Array my @DOCUMENTED => (
	'status Process: 0 success',
	'status Process: 1-125 program status',
	'status Process: 128+n signal',
	'status Process: 255 not started',
	'status Process: 127 child could not start',
	'text Process: No command given',
	'text Process: No commands given',
	'text Process: Unable to rewind captured output',
	'text Process: Unable to redirect command output',
	'text Process: Unable to duplicate STDOUT/STDERR',
	'text Process: Unable to restore STDOUT/STDERR',
	"text Process: Unable to open 'F'",
	'text Access: A package name is required',
	'text Error: Invalid arguments to App::Actions::Error::new',
	'status Schema: 70 invalid document',
	'text Schema: expected TYPE, got VALUE',
	'text Schema: expected X, got Y',
	'text Schema: V is not one of A, B',
	'text Schema: unexpected key',
	'text Schema: missing',
	'text Schema: matches none of the alternative shapes',
	'text Schema: WHAT: FIRST (and N more)',
	"text Docker: Docker executable 'BIN' was not found or is not usable",
	'text Docker: Cannot connect to the Docker daemon',
	'text Docker: No images given',
	(map { "text Expression: $_" }
		'Cannot evaluate an undefined expression', 'Cannot evaluate an empty expression', 'Unterminated string',
		'Unexpected character', 'Unexpected X', 'Unexpected end of expression', q{Expected 'X' in expression},
		'Expected a property name after dot', 'F() expects N argument(s)', 'join() first argument must be an array',
		'fromJSON() failed', 'hashFiles() is not supported', 'Unknown function', q{Unclosed expression in 'T'},
		'unable to resolve'),
	(map { "text Cache: $_" }
		'cannot write a new cache file', q{cannot write 'TEMP'}, q{cannot replace 'FILE'},
		'pruning the image cache needs a Docker command', 'the document does not match its schema'),
	(map { "text Logs: $_" }
		'cannot read the log directory', q{cannot remove 'PATH'}, 'the document does not match its schema'),
	'status Check: 0 ready',
	'status Check: 2 not ready',
	(map { "text Check: $_" }
		'could not be run', 'not reachable', 'windows containers', q{cannot write 'FILE'}, 'is not a directory', 'probe failed',
		'could not read the mounted temporary directory', 'could not count the entries', 'sees N entries',
		'the document does not match its schema', 'Unable to buffer the check report'),
	(map { "status Runner: $_" } 'run 0 success', 'run 1 workflow failure', 'run 2 usage or Docker error', 'preflight 0 ready',
		'preflight 2 not ready'),
	(map { "status Actions: $_" } 'run 0 success', 'run 1 job failed', 'run 2 usage or Docker error'),
);

my %ledger = (
	(map { ("message $_" => 1) } @{ App::Actions::I18N->catalogue_keys('en') }),
	(map { ($_ => 1) } @DOCUMENTED),
);

# Every message the code renders passes through I18N::message; the spy
# strikes its key off and returns what the real routine returns.
around('App::Actions::I18N::message' => sub {
	my ($original, @args) = @_;
	delete $ledger{"message $args[1]"} if defined $args[1];
	return $original->(@args);
});

# Every entry the ledger started with, so a misspelt settle() fails rather
# than silently striking off nothing.
my %known = map { $_ => 1 } keys %ledger;

# A status (or a message rendered outside I18N::message) has been asserted.
sub settle {
	my ($entry) = @_;

	ok($known{$entry}, "the ledger knows '$entry'");
	delete $ledger{$entry};
	return;
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# What a call threw: the error object, a plain message, or undef.
sub caught(&) {
	my ($code) = @_;

	local $@;
	return eval { $code->(); 1 } ? undef : $@;
}

# The call must throw an App::Actions::Error with this code and, when given,
# exactly this message (without its location).
sub throws_code {
	my ($code, $want_code, $want_message, $name) = @_;

	my $error = caught { $code->() };
	subtest $name => sub {
		ok(blessed($error) && $error->isa('App::Actions::Error'), 'an App::Actions::Error')
			or return diag('got: ' . (defined $error ? $error : 'no error'));
		is($error->code, $want_code, "code $want_code");
		is($error->message, $want_message, 'the documented message') if defined $want_message;
	};
	return $error;
}

# The routine must leave the caller's $_, $@, $! and alarm() countdown as
# they were.  $! is checked only for a routine that does no I/O of its own.
sub keeps_globals {
	my ($code, $name, %options) = @_;

	local $_ = $config{sentinel};
	local $@ = $config{sentinel};
	local $! = $config{errno};
	my $previous = alarm $config{alarm};

	# The globals are set and read inside the eval, around the call: entering
	# an eval clears $@, and leaving one successfully clears it again.
	my %after;
	my $ok = eval {
		($_, $@, $!) = ($config{sentinel}, $config{sentinel}, $config{errno});
		$code->();
		%after = (topic => $_, error => $@, errno => $! + 0);
		1;
	};
	my $failure = $@;
	my $remaining = alarm 0;
	alarm $previous if $previous;
	return fail("$name: died: $failure") unless $ok;

	subtest "$name keeps the caller's globals" => sub {
		is($after{topic}, $config{sentinel}, '$_');
		is($after{error}, $config{sentinel}, '$@');
		is($after{errno}, $config{errno}, '$!') unless $options{io};
		cmp_ok($remaining, '>', 0, 'the alarm countdown');
	};
	return;
}

# A returned value that must match both its documented schema and the
# value the POD says it is.  (Test::Returns' returns_is checks the schema
# only.)
sub is_returned {
	my ($value, $schema, $want, $name) = @_;

	subtest $name => sub {
		returns_ok($value, $schema, 'the documented shape');
		ref $want ? is_deeply($value, $want, 'the documented value') : is($value, $want, 'the documented value');
	};
	return $value;
}

# A value as one line of Perl, for a test name.  (Test::Most's explain
# prints its diagnostics rather than returning them.)
sub shown {
	my ($value) = @_;

	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 0;
	local $Data::Dumper::Sortkeys = 1;
	local $Data::Dumper::Useqq = 1;
	return Data::Dumper::Dumper($value);
}

# Internal states, shown only when asked for.
sub show_state {
	my ($label, $state) = @_;

	explain($label, $state);
	return;
}

sub write_file {
	my ($name, $content, $dir) = @_;

	$dir = tempdir(CLEANUP => 1) unless defined $dir;
	my $path = File::Spec->catfile($dir, $name);
	open my $handle, '>', $path or die "$path: $!";
	binmode $handle;
	print {$handle} $content;
	close $handle or die "$path: $!";
	return $path;
}

# A command that runs this Perl, so no other program is needed.
sub perl_command {
	my ($code, @args) = @_;

	return [ $^X, '-e', $code, @args ];
}

# ---- sections ----

# ---------------------------------------------------------------------------
# App::Actions::Util
# ---------------------------------------------------------------------------

subtest 'App::Actions::Util' => sub {
	# The shared YAML rules: a file that must hold a mapping, values that
	# must be mappings, and the shape of a step.  Every rule has a message,
	# and each is reached here through the public functions only.
	my $job = [ 'where.job', { job => 'test' } ];

	subtest 'load_yaml_mapping' => sub {
		my $file = write_file('ci.yml', "zebra: 1\napple: 2\nmiddle: 3\n");
		my $data = App::Actions::Util::load_yaml_mapping($file, 'workflow');
		returns_ok($data, { type => 'hashref' }, 'a hash reference');
		is_deeply([ keys %{$data} ], [ qw(zebra apple middle) ], 'with its keys in file order');
		keeps_globals(sub { App::Actions::Util::load_yaml_mapping($file, 'action') }, 'load_yaml_mapping', io => 1);

		# Each documented message, for both kinds: the kind chooses the words.
		my %words = (
			workflow => { required => 'No workflow file given', missing => "Workflow file '%s' does not exist",
				parse => "Unable to parse workflow '%s': ", empty => "Workflow '%s' is empty",
				mapping => "Workflow '%s' must contain a YAML mapping" },
			action => { required => 'No action metadata file given', missing => "Action metadata file '%s' does not exist",
				parse => "Unable to parse action metadata '%s': ", empty => "Action metadata '%s' is empty",
				mapping => "Action metadata '%s' must contain a YAML mapping" },
		);
		for my $kind (sort keys %words) {
			my $say = $words{$kind};
			throws_code(sub { App::Actions::Util::load_yaml_mapping(undef, $kind) }, "$kind.file_required", $say->{required},
				"$kind: no file");
			throws_code(sub { App::Actions::Util::load_yaml_mapping('', $kind) }, "$kind.file_required", $say->{required},
				"$kind: an empty name is no file");
			my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'none.yml');
			throws_code(sub { App::Actions::Util::load_yaml_mapping($missing, $kind) }, "$kind.file_missing",
				sprintf($say->{missing}, $missing), "$kind: a file that is not there");
			my $dir = tempdir(CLEANUP => 1);
			throws_code(sub { App::Actions::Util::load_yaml_mapping($dir, $kind) }, "$kind.file_missing",
				sprintf($say->{missing}, $dir), "$kind: a directory is not a file");
			my $broken = write_file('broken.yml', "a: [unclosed\n");
			my $error = throws_code(sub { App::Actions::Util::load_yaml_mapping($broken, $kind) }, "$kind.parse_failed", undef,
				"$kind: malformed YAML");
			like($error->message, qr/\A\Q${\ sprintf($say->{parse}, $broken)}\E\S/, "$kind: the parse error names the file and says why");
			my $empty = write_file('empty.yml', "# nothing\n");
			throws_code(sub { App::Actions::Util::load_yaml_mapping($empty, $kind) }, "$kind.empty", sprintf($say->{empty}, $empty),
				"$kind: a file with no document");
			for my $text ("- a\n- b\n", "just text\n") {
				my $other = write_file('other.yml', $text);
				throws_code(sub { App::Actions::Util::load_yaml_mapping($other, $kind) }, "$kind.not_mapping",
					sprintf($say->{mapping}, $other), "$kind: not a mapping: " . shown($text));
			}
		}
		throws_ok { App::Actions::Util::load_yaml_mapping($file, 'other') }
			qr/\AInvalid arguments to App::Actions::Util::load_yaml_mapping: Parameter 'kind' \(other\) must be one of action, workflow at /,
			'an unknown kind is refused';
	};

	subtest 'mapping' => sub {
		my $original = { a => [ 1 ] };
		my $copy = App::Actions::Util::mapping($original, $job);
		returns_ok($copy, { type => 'hashref' }, 'a hash reference');
		is_deeply($copy, $original, 'with the same contents');
		isnt($copy, $original, 'in a new hash');
		is($copy->{a}, $original->{a}, 'a shallow copy, as documented');
		is_deeply(App::Actions::Util::mapping(undef, $job), {}, 'an absent value is an empty hash');
		throws_code(sub { App::Actions::Util::mapping([ 1 ], $job) }, 'mapping.invalid', "job 'test' must be a mapping", 'a list');
		throws_code(sub { App::Actions::Util::mapping('text', 'the thing') }, 'mapping.invalid', 'the thing must be a mapping',
			'a scalar, with a place given as words');
		throws_code(sub { App::Actions::Util::mapping(\'x', [ 'where.step_env', { where => $job } ]) }, 'mapping.invalid',
			"env of a step in job 'test' must be a mapping", 'a place inside a place is rendered first');
		keeps_globals(sub { App::Actions::Util::mapping({ a => 1 }, $job) }, 'mapping');
	};

	subtest 'normalize_step' => sub {
		my $step = { run => 'make', name => 'build' };
		my $normal = App::Actions::Util::normalize_step($step, $job);
		returns_ok($normal, { type => 'hashref' }, 'a hash reference');
		is_deeply($normal, { run => 'make', name => 'build', env => {}, with => {} }, 'env and with are always hashes');
		ok(!exists $step->{env}, 'and the step given is not changed');
		is_deeply(App::Actions::Util::normalize_step({ uses => 'a/b@v1', with => { x => 1 } }, $job)->{with}, { x => 1 },
			'a uses step keeps its inputs');

		throws_code(sub { App::Actions::Util::normalize_step($_, $job) }, 'step.not_mapping', "A step in job 'test' is not a mapping",
			'not a step: ' . shown($_)) for 'run: make', [ 'run' ], undef;
		throws_code(sub { App::Actions::Util::normalize_step({ run => 'x', env => [ 'A=1' ] }, $job) }, 'mapping.invalid',
			"env of a step in job 'test' must be a mapping", 'env must be a mapping');
		throws_code(sub { App::Actions::Util::normalize_step({ run => 'x', with => 'a' }, $job) }, 'mapping.invalid',
			"with of a step in job 'test' must be a mapping", 'with must be a mapping');
		for my $field ('run', 'uses', 'shell', 'name', 'id', 'if', 'working-directory') {
			my %bad = (run => 'x', $field => { nested => 1 });
			throws_code(sub { App::Actions::Util::normalize_step(\%bad, $job) }, 'step.field_not_string',
				"Step field '$field' in job 'test' must be a string", "$field must be a string");
		}
		throws_code(sub { App::Actions::Util::normalize_step({ name => 'idle' }, $job) }, 'step.no_command',
			"A step in job 'test' has neither 'run' nor 'uses'", 'a step that does nothing');
		keeps_globals(sub { App::Actions::Util::normalize_step({ run => 'x' }, $job) }, 'normalize_step');
	};

	subtest 'stringify' => sub {
		is(App::Actions::Util::stringify(undef), '', 'undef is empty');
		is(App::Actions::Util::stringify(JSON::PP::true()), 'true', 'a JSON true');
		is(App::Actions::Util::stringify(JSON::PP::false()), 'false', 'a JSON false');
		SKIP: {
			skip 'core booleans need Perl 5.36', 2 if $] < 5.036;
			is(App::Actions::Util::stringify(!!1), 'true', 'a core true');
			is(App::Actions::Util::stringify(!!0), 'false', 'a core false');
		}
		is(App::Actions::Util::stringify(0), '0', 'a number is itself');
		is(App::Actions::Util::stringify('text'), 'text', 'a string is itself');
		is(App::Actions::Util::stringify({ b => 1, a => [ 2 ] }), '{"a":[2],"b":1}', 'a reference is canonical JSON');
		returns_ok(App::Actions::Util::stringify([ 1 ]), { type => 'string' }, 'always a string');
		keeps_globals(sub { App::Actions::Util::stringify({ a => 1 }) }, 'stringify');
	};

	subtest 'trim' => sub {
		is(App::Actions::Util::trim("  a b \n\t"), 'a b', 'both ends');
		is(App::Actions::Util::trim(undef), '', 'undef is empty');
		my $text = ' x ';
		App::Actions::Util::trim($text);
		is($text, ' x ', 'the argument is never changed');
		my $hostile = 'a' . (' ' x $config{big}) . 'b' . (' ' x $config{big});
		my $started = time;
		is(App::Actions::Util::trim($hostile), 'a' . (' ' x $config{big}) . 'b', 'inner white space is kept');
		cmp_ok(time - $started, '<=', $config{time_limit}, 'and long runs of it take linear time');
		keeps_globals(sub { App::Actions::Util::trim(' x ') }, 'trim');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Access, Error, I18N (and its catalogues), Docker::Variable,
# Schema::Invalid and Schema
# ---------------------------------------------------------------------------

# A package whose routines Access has not yet seen wrapped: two private
# routines, a public one, a double-underscore one and one it imported.
{
	package Local::Accessed;
	sub _one { 1 }
	sub _two { 2 }
	sub __hidden { 3 }
	sub visible { 4 }
	BEGIN { *_borrowed = \&App::Actions::Util::trim }
}

# A class that imports i18n and throw, as the modules do, with and without a
# translator of its own.
{
	package Local::Speaker;
	App::Actions::I18N->import(qw(i18n throw));
	sub new { my ($class, %args) = @_; return bless { %args }, $class }
	sub speak { my ($self, $key, $args) = @_; return $self->i18n($key, $args) }
	sub fail { my ($self, $key, $args) = @_; $self->throw($key, $args) }
}

subtest 'App::Actions::Access' => sub {
	# private_names is how each module chooses what Sub::Private hides, so
	# what it leaves out matters as much as what it lists.
	my $names = App::Actions::Access->private_names('Local::Accessed');
	returns_ok($names, { type => 'arrayref' }, 'an array reference');
	is_deeply($names, [ qw(_one _two) ], 'its own _ routines, sorted; not public, __ or imported ones');
	is_deeply(App::Actions::Access->private_names('Local::Accessed', '_two'), [ '_one' ], 'less the exceptions');
	is_deeply(App::Actions::Access->private_names('No::Such::Package'), [], 'a package with no routines');
	is_deeply(App::Actions::Access->private_names('App::Actions::Util'), [],
		'routines Sub::Private has already wrapped are not listed, as the POD warns');
	for my $bad (undef, '', 'not a name', 'A::', '::A', "A\nB") {
		throws_ok { App::Actions::Access->private_names($bad) } qr/\AA package name is required at /,
			'refused: ' . shown($bad);
	}
	settle('text Access: A package name is required');
	keeps_globals(sub { App::Actions::Access->private_names('Local::Accessed') }, 'private_names');
};

subtest 'App::Actions::Error' => sub {
	# The exception every failure is: its accessors, its stringification,
	# and the two class methods that accept any exception at all.
	my $args = { file => 'ci.yml' };
	my $error = App::Actions::Error->new(code => 'workflow.empty', message => "Workflow 'ci.yml' is empty",
		args => $args, location => " at x line 1.\n");
	isa_ok($error, 'App::Actions::Error');
	is($error->code, 'workflow.empty', 'code');
	is($error->message, "Workflow 'ci.yml' is empty", 'message, without the location');
	is($error->location, " at x line 1.\n", 'location');
	is($error->text, "Workflow 'ci.yml' is empty at x line 1.\n", 'text is message and location');
	is("$error", $error->text, 'and is what it stringifies to');
	is_deeply($error->args, $args, 'args');
	$error->args->{file} = 'changed';
	is($error->args->{file}, 'ci.yml', 'args returns a copy');
	is(App::Actions::Error->new(code => 'a.b', message => 'm')->location, "\n", 'the location defaults to a newline');
	is_deeply(App::Actions::Error->new(code => 'a.b', message => 'm')->args, {}, 'and the args to none');
	returns_ok($error->code, { type => 'string' }, 'code is a string');

	is($error->is('workflow.empty'), 1, 'is: the full code');
	is($error->is('workflow.'), 1, 'is: a family, by a prefix ending in a dot');
	is($error->is('workflow'), 0, 'is: a prefix without the dot is not a family');
	is($error->is('workflow.empt'), 0, 'is: nor is part of a code');
	is($error->is('action.'), 0, 'is: another family');

	is(App::Actions::Error->caught($error), $error, 'caught: an Error is returned');
	is(App::Actions::Error->caught("plain\n"), undef, 'caught: a string is not');
	is(App::Actions::Error->caught(undef), undef, 'caught: nor is undef');
	is(App::Actions::Error->caught(bless {}, 'Other'), undef, 'caught: nor another object');
	my $invalid = App::Actions::Schema::Invalid->new("bad\n");
	is(App::Actions::Error->caught($invalid), $invalid, 'caught: a subclass is an Error');
	is(App::Actions::Schema::Invalid->caught($error), undef, 'caught: but an Error is not the subclass');

	is(App::Actions::Error->describe($error), "Workflow 'ci.yml' is empty", 'describe: the message of an Error');
	is(App::Actions::Error->describe("failed at lib/X.pm line 3.\n"), 'failed', 'describe: a string loses its location');
	is(App::Actions::Error->describe("bad JSON at character offset 9 (before \"x\") at lib/X.pm line 3.\n"),
		'bad JSON at character offset 9 (before "x")', 'describe: a position of its own is kept');
	is(App::Actions::Error->describe("  spaced \n\n"), '  spaced', 'describe: trailing white space goes');
	is(App::Actions::Error->describe(undef), '', 'describe: undef is empty');

	throws_ok { App::Actions::Error->new(message => 'm') } qr/\AInvalid arguments to App::Actions::Error::new: .*'code'/s, 'no code';
	throws_ok { App::Actions::Error->new(code => 'a.b') } qr/\AInvalid arguments to App::Actions::Error::new: .*'message'/s,
		'no message';
	throws_ok { App::Actions::Error->new(code => $_, message => 'm') } qr/\AInvalid arguments to App::Actions::Error::new: /,
		'a code that is not dotted: ' . shown($_) for 'nodot', 'Upper.case', '.a', 'a.', 'a..b', "a.b\n";
	throws_ok { App::Actions::Error->new(code => 'a.b', message => 'm', args => [ 1 ]) }
		qr/\AInvalid arguments to App::Actions::Error::new: /, 'args must be a hash';
	settle('text Error: Invalid arguments to App::Actions::Error::new');
	keeps_globals(sub { App::Actions::Error->describe("x at y line 1.\n") }, 'describe');
	keeps_globals(sub { App::Actions::Error->new(code => 'a.b', message => 'm') }, 'new');
};

subtest 'App::Actions::I18N' => sub {
	# The translator: which language it chooses, how it renders plurals,
	# genders and missing placeholders, and what it does with a language or
	# a key it does not know.
	subtest 'new, language and language_for_country' => sub {
		is(App::Actions::I18N->new->language, 'en', 'English by default');
		is(App::Actions::I18N->new(language => 'fr')->language, 'fr', 'a language');
		is(App::Actions::I18N->new(language => 'de_DE')->language, 'de', 'only the part before _ is used');
		is(App::Actions::I18N->new(language => 'zh-CN')->language, 'zh', 'or before -');
		is(App::Actions::I18N->new(country => 'cn')->language, 'zh', 'a country, in any case');
		is(App::Actions::I18N->new(language => 'fr', country => 'DE')->language, 'fr', 'a language wins over a country');
		isa_ok(App::Actions::I18N->new, 'App::Actions::I18N');

		my @warnings;
		{
			local $SIG{__WARN__} = sub { push @warnings, @_ };
			is(App::Actions::I18N->new(language => 'xx')->language, 'en', 'a language with no catalogue is English');
		}
		like($warnings[0], qr/\ALanguage 'xx' has no catalogue; using English at /, 'and says so');
		settle('message i18n.unknown_language');

		throws_ok { App::Actions::I18N->new(language => $_) } qr/\AInvalid arguments to App::Actions::I18N::new: /,
			'a language that is not a code: ' . shown($_) for '1', 'f', 'english language';
		throws_ok { App::Actions::I18N->new(country => 'FRA') } qr/\AInvalid arguments to App::Actions::I18N::new: /,
			'a country that is not two letters';

		is(App::Actions::I18N->language_for_country('fr'), 'fr', 'language_for_country');
		is(App::Actions::I18N->language_for_country('CN'), 'zh', 'in any case');
		is(App::Actions::I18N->language_for_country('JP'), undef, 'a country with no catalogue is undef');
		throws_ok { App::Actions::I18N->language_for_country($_) }
			qr/\AInvalid arguments to App::Actions::I18N::language_for_country: /, 'not a country: ' . shown($_)
			for 'F', 'FRA', '12';
		keeps_globals(sub { App::Actions::I18N->language_for_country('DE') }, 'language_for_country');
	};

	subtest 'shared, languages and catalogue_keys' => sub {
		{
			local $ENV{ACTION_RUN_LANG} = 'de';
			is(App::Actions::I18N->shared->language, 'de', 'shared follows ACTION_RUN_LANG');
			is(App::Actions::I18N::shared()->language, 'de', 'as a function too');
			is(App::Actions::I18N->shared, App::Actions::I18N->shared, 'and is one object while nothing changes');
		}
		is(App::Actions::I18N->shared->language, 'en', 'and English without it');

		is_deeply(App::Actions::I18N->languages, [ qw(de en fr zh) ], 'languages: every catalogue, sorted');
		my $french = App::Actions::I18N->catalogue_keys('fr');
		returns_ok($french, { type => 'arrayref' }, 'catalogue_keys: an array reference');
		is_deeply($french, [ sort @{$french} ], 'sorted');
		is_deeply(App::Actions::I18N->catalogue_keys('xx'), [], 'empty for a language with no catalogue');
		throws_ok { App::Actions::I18N->catalogue_keys($_) } qr/\AInvalid arguments to App::Actions::I18N::catalogue_keys: /,
			'not a code: ' . shown($_) for 'FR', 'f', 'french';
	};

	subtest 'message and add_messages' => sub {
		my $english = App::Actions::I18N->new;
		is($english->message('workflow.empty', { file => 'ci.yml' }), "Workflow 'ci.yml' is empty", 'placeholders are filled');
		is(App::Actions::I18N->new(language => 'fr')->message('cache.summary', { count => 1 }), '1 image.', 'the singular');
		is(App::Actions::I18N->new(language => 'fr')->message('cache.summary', { count => 2 }), '2 images.', 'the plural');
		my @warnings;
		{
			local $SIG{__WARN__} = sub { push @warnings, @_ };
			is($english->message('workflow.empty'), "Workflow '' is empty", 'a placeholder without a value is empty');
			is($english->message('cache.summary', {}), '0 images.', 'and a number without one is 0');
		}
		is_deeply(\@warnings, [], 'never a warning');
		{
			local $SIG{__WARN__} = sub { push @warnings, @_ };
			is($english->message('no.such.key'), 'no.such.key', 'an unknown key is returned as it is');
		}
		like($warnings[0], qr/\ANo message is defined for 'no.such.key' at /, 'and warned about');
		settle('message i18n.unknown_key');
		throws_ok { $english->message('') } qr/\AInvalid arguments to App::Actions::I18N::message: /, 'an empty key';

		is(App::Actions::I18N->add_messages('en', {
			'unit.greeting' => { gender => { female => 'She is %(name)s', male => 'He is %(name)s', other => 'They are %(name)s' } },
			'unit.files' => { plural => { one => '%(count)d file', other => '%(count)d files' } },
		}), 'App::Actions::I18N', 'add_messages returns its invocant');
		is($english->message('unit.greeting', { name => 'Ana', gender => 'female' }), 'She is Ana', 'a gendered entry: female');
		is($english->message('unit.greeting', { name => 'Bo', gender => 'male' }), 'He is Bo', 'male');
		is($english->message('unit.greeting', { name => 'Cy' }), 'They are Cy', 'and other when none is given');
		is($english->message('unit.files', { count => 1 }), '1 file', 'an added plural');
		my $object = App::Actions::I18N->new;
		is($object->add_messages('en', {}), $object, 'chained from an object, it returns the object');
		throws_ok { App::Actions::I18N->add_messages('EN', {}) } qr/\AInvalid arguments to App::Actions::I18N::add_messages: /,
			'a language that is not a code';
		throws_ok { App::Actions::I18N->add_messages('en', []) } qr/\AInvalid arguments to App::Actions::I18N::add_messages: /,
			'entries that are not a hash';
		keeps_globals(sub { $english->message('workflow.empty', { file => 'x' }) }, 'message');
	};

	subtest 'i18n and throw, imported into a class' => sub {
		my $speaker = Local::Speaker->new;
		is($speaker->speak('workflow.empty', { file => 'a' }), "Workflow 'a' is empty", 'i18n uses the shared translator');
		my $french = Local::Speaker->new(i18n => App::Actions::I18N->new(language => 'fr'));
		like($french->speak('workflow.empty', { file => 'a' }), qr/\A\S.*'a'/, "or the object's own");
		isnt($french->speak('workflow.empty', { file => 'a' }), $speaker->speak('workflow.empty', { file => 'a' }),
			'which is French here');
		is(Local::Speaker->speak('workflow.empty', { file => 'a' }), "Workflow 'a' is empty", 'a class-method call is shared');

		my $line = __LINE__ + 1;
		my $error = throws_code(sub { $speaker->fail('workflow.empty', { file => 'b' }) }, 'workflow.empty',
			"Workflow 'b' is empty", 'throw raises the rendered message');
		like($error->location, qr/\A at .+ line \d+\.\n\z/, 'from where it was called');
		is_deeply($error->args, { file => 'b' }, 'with its arguments');
		$error = caught { $speaker->fail('workflow.empty', { file => 'c', trace => 1 }) };
		like($error->location, qr/called at /, 'trace => 1 carries a stack trace');
		$error = caught { $speaker->fail('workflow.empty', { file => 'd', location => 0 }) };
		is($error->location, "\n", 'location => 0 names no place');
	};

	subtest 'validate_args' => sub {
		my %schema = (file => { type => 'string' }, kind => { type => 'string', optional => 1 });
		my $params = App::Actions::I18N::validate_args('Local::r', [ 'a.yml', 'action' ], \%schema, [ qw(file kind) ]);
		returns_ok($params, { type => 'hashref' }, 'a hash reference');
		is_deeply($params, { file => 'a.yml', kind => 'action' }, 'positional arguments by name');
		is_deeply(App::Actions::I18N::validate_args('Local::r', [ file => 'a.yml', kind => 'x' ], \%schema, [ qw(file kind) ]),
			{ file => 'a.yml', kind => 'x' }, 'named pairs, though the routine has positional names');
		is_deeply(App::Actions::I18N::validate_args('Local::r', [ 'a.yml' ], \%schema, 'file'), { file => 'a.yml' },
			'a lone positional argument');
		throws_ok { App::Actions::I18N::validate_args('Local::r', [], \%schema, [ qw(file kind) ]) }
			qr/\AInvalid arguments to Local::r: Required parameter 'file' is missing at /, 'a missing argument';
		throws_ok { App::Actions::I18N::validate_args('Local::r', [ undef, 'x' ], \%schema, [ qw(file kind) ]) }
			qr/\AInvalid arguments to Local::r: Required parameter 'file' is missing at /, 'undef is missing';
		throws_ok { App::Actions::I18N::validate_args('Local::r', [ { file => 'a', colour => 1 } ], \%schema) }
			qr/\AInvalid arguments to Local::r: Unknown parameter 'colour' at /, 'an unknown argument';
		keeps_globals(sub { App::Actions::I18N::validate_args('Local::r', [ 'a' ], \%schema, 'file') }, 'validate_args');
	};

	subtest 'the catalogues' => sub {
		# Each language module hands back its own catalogue; every key in a
		# translation must also be an English key.
		my %english = %{ App::Actions::I18N::en->messages };
		for my $language (qw(en fr de zh)) {
			my $messages = "App::Actions::I18N::$language"->messages;
			returns_ok($messages, { type => 'hashref' }, "$language: a hash reference");
			ok(scalar keys %{$messages}, "$language: with entries");
			is_deeply([ grep { !exists $english{$_} } sort keys %{$messages} ], [], "$language: every key is an English key");
		}
	};
};

subtest 'App::Actions::Docker::Variable' => sub {
	# A name and value kept out of argv; its string form carries the secret,
	# which is why the POD warns against printing it.
	my $variable = App::Actions::Docker::Variable->new('TOKEN', 's3cret');
	isa_ok($variable, 'App::Actions::Docker::Variable');
	is($variable->name, 'TOKEN', 'name');
	is($variable->value, 's3cret', 'value');
	is("$variable", 'TOKEN=s3cret', 'it prints as NAME=VALUE');
	is(App::Actions::Docker::Variable->new('EMPTY', undef)->value, '', 'an undef value is empty');
	returns_ok($variable->value, { type => 'string' }, 'a string');
	keeps_globals(sub { App::Actions::Docker::Variable->new('A', 'b')->value }, 'Docker::Variable');
};

subtest 'App::Actions::Schema::Invalid and App::Actions::Schema' => sub {
	# validate lists every difference with its path; assert_valid throws the
	# first one as a Schema::Invalid; describe_errors and invalid_exit are
	# what the commands report and exit with.
	my $invalid = App::Actions::Schema::Invalid->new("the document is wrong\n");
	isa_ok($invalid, 'App::Actions::Error');
	is($invalid->code, 'schema.invalid', 'code schema.invalid');
	is($invalid->message, "the document is wrong\n", 'the message as given');
	is($invalid->location, '', 'and no location');
	is($invalid->is('schema.'), 1, 'is works');

	my $schema = {
		type => 'object',
		properties => {
			count => { type => 'integer' },
			version => { const => 3 },
			mode => { enum => [ 'fast', 'slow' ] },
			note => { oneOf => [ { type => 'string' }, { type => 'null' } ] },
			flags => { type => 'array', items => { type => 'boolean' } },
		},
		required => [ 'count', 'version' ],
		additionalProperties => JSON::PP::false(),
	};
	my $good = { count => 1, version => 3, mode => 'fast', note => undef, flags => [ JSON::PP::true() ] };
	is_deeply([ App::Actions::Schema::validate($good, $schema) ], [], 'validate: a matching value has no problems');

	my @errors = App::Actions::Schema::validate(
		{ count => '1x', version => 4, mode => 'warp', note => [ 1 ], flags => [ 1 ], extra => 1 }, $schema);
	my %said = map { $_ => 1 } @errors;
	my %want = (
		'$.count: expected integer, got \'1x\'' => 'text Schema: expected TYPE, got VALUE',
		'$.version: expected 3, got 4' => 'text Schema: expected X, got Y',
		'$.mode: \'warp\' is not one of \'fast\', \'slow\'' => 'text Schema: V is not one of A, B',
		'$.extra: unexpected key' => 'text Schema: unexpected key',
		'$.note: matches none of the alternative shapes (first said: $.note: expected string, got ARRAY)'
			=> 'text Schema: matches none of the alternative shapes',
		'$.flags[0]: expected boolean, got 1' => undef,
	);
	for my $message (sort keys %want) {
		ok($said{$message}, "validate says: $message");
		settle($want{$message}) if $want{$message} && $said{$message};
	}
	is(scalar @errors, scalar keys %want, 'and nothing else');
	is_deeply([ App::Actions::Schema::validate({}, $schema, 'doc') ], [ 'doc.count: missing', 'doc.version: missing' ],
		'a missing required key, under the path given');
	settle('text Schema: missing');

	is(App::Actions::Schema::assert_valid($good, $schema, 'the thing'), 1, 'assert_valid: 1 for a match');
	my $error = caught { App::Actions::Schema::assert_valid({}, $schema, 'the thing') };
	isa_ok($error, 'App::Actions::Schema::Invalid');
	is($error->message, "the thing: \$.count: missing (and 1 more)\n", 'assert_valid: WHAT: FIRST (and N more)');
	settle('text Schema: WHAT: FIRST (and N more)');

	is(App::Actions::Schema::describe_errors([]), '', 'describe_errors: none is empty');
	is(App::Actions::Schema::describe_errors([ 'a' ]), 'a', 'one is itself');
	is(App::Actions::Schema::describe_errors([ qw(a b c) ]), 'a (and 2 more)', 'more are counted');
	is(App::Actions::Schema::invalid_exit(), 70, 'invalid_exit is 70, EX_SOFTWARE');
	settle('status Schema: 70 invalid document');
	can_ok('App::Actions::Schema', 'invalid_exit');
	ok(eval { App::Actions::Schema->import('invalid_exit'); 1 }, 'and, like the others, it can be imported by name');

	my $deep = { type => 'array', items => { type => 'array', items => { type => 'integer' } } };
	my $nested = [ map { [ (1) x 10 ] } 1 .. $config{big} / 10 ];
	my $started = time;
	is_deeply([ App::Actions::Schema::validate($nested, $deep) ], [], 'a large document validates');
	cmp_ok(time - $started, '<=', $config{time_limit}, 'in reasonable time');
	keeps_globals(sub { App::Actions::Schema::validate($good, $schema) }, 'validate');
	keeps_globals(sub { App::Actions::Schema::assert_valid($good, $schema, 'x') }, 'assert_valid');
};

# ---------------------------------------------------------------------------
# App::Actions::Process
# ---------------------------------------------------------------------------

# Run $code with this process's STDOUT or STDERR going to a file, at the
# descriptor level so a child process writes there too; returns the text.
sub output_of {
	my ($stream, $code) = @_;

	my $file = File::Spec->catfile(tempdir(CLEANUP => 1), 'out');
	my $handle = $stream eq 'stdout' ? \*STDOUT : \*STDERR;
	$handle->flush;
	open my $keep, '>&', $handle or die "dup $stream: $!";
	open $handle, '>', $file or die "redirect $stream: $!";
	# $@ is restored afterwards, so a check of the caller's $@ around this
	# sees what the code did to it, not what this eval did.
	# Leaving an eval clears $@, so what the code left is read inside it.
	my ($ok, $error, $after);
	{
		my $before = $@;
		$ok = eval { $@ = $before; $code->(); $after = $@; 1 };
		$error = $@;
		$@ = $ok ? $after : $before;
	}
	$handle->flush;
	open $handle, '>&', $keep or die "restore $stream: $!";
	die $error unless $ok;
	open my $in, '<', $file or die $!;
	local $/;
	my $text = <$in>;
	return defined $text ? $text : '';
}

subtest 'App::Actions::Process' => sub {
	# Programs run as lists, never through a shell, and every function
	# reports the same exit statuses.  The failures the POD lists that need
	# the operating system to refuse are forced through %FAIL.
	subtest 'exit statuses' => sub {
		is(App::Actions::Process::run(perl_command('exit 0')), 0, 'a program that succeeds is 0');
		settle('status Process: 0 success');
		is(App::Actions::Process::run(perl_command('exit 3')), 3, 'one that fails is the number it chose');
		is(App::Actions::Process::run(perl_command('exit 125')), 125, 'up to 125');
		settle('status Process: 1-125 program status');
		is(App::Actions::Process::run(perl_command('kill q{TERM}, $$; sleep 5')), 128 + 15, 'a signal is 128 plus its number');
		settle('status Process: 128+n signal');
		my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'missing');
		is(App::Actions::Process::run([ $missing ]), 255, 'a program that cannot start is 255');
		settle('status Process: 255 not started');
	};

	subtest 'exit_code' => sub {
		is(App::Actions::Process::exit_code(0), 0, 'success');
		is(App::Actions::Process::exit_code(undef), 0, 'no status is success');
		is(App::Actions::Process::exit_code(3 << 8), 3, 'an exit status');
		is(App::Actions::Process::exit_code(2), 130, 'signal 2 is 130, as for Ctrl-C');
		is(App::Actions::Process::exit_code(2 | 128), 130, 'a core dump changes nothing');
		is(App::Actions::Process::exit_code(-1), 255, 'a program that did not start is 255');
		returns_ok(App::Actions::Process::exit_code(256 * 300), { type => 'integer', min => 0, max => 255 }, 'always 0 to 255');
		keeps_globals(sub { App::Actions::Process::exit_code(256) }, 'exit_code');
	};

	subtest 'cpu_count' => sub {
		returns_ok(App::Actions::Process::cpu_count(), { type => 'integer', min => 1 }, 'one processor or more');
		local $^O = 'MSWin32';
		local $ENV{NUMBER_OF_PROCESSORS} = '6';
		is(App::Actions::Process::cpu_count(), 6, 'Windows says in NUMBER_OF_PROCESSORS');
		for my $hostile ('0', '-2', 'lots', '4; rm -rf /', '') {
			local $ENV{NUMBER_OF_PROCESSORS} = $hostile;
			cmp_ok(App::Actions::Process::cpu_count(), '>=', 1, 'a NUMBER_OF_PROCESSORS of ' . shown($hostile) . ' is not believed');
		}
	};

	subtest 'capture' => sub {
		my ($output, $status) = App::Actions::Process::capture(perl_command('binmode STDOUT; print qq{a\r\nb}; exit 4'));
		is($output, "a\nb", 'the output, with CRLF made LF');
		is($status, 4, 'and the status');
		is(output_of(stderr => sub { ($output) = App::Actions::Process::capture(perl_command('print STDERR q{noise}; print q{d}')) }),
			'noise', 'the error output goes to the terminal by default');
		is($output, 'd', 'and is not in the output');
		is(output_of(stderr => sub { ($output) = App::Actions::Process::capture(perl_command('print STDERR q{x}; print q{d}'),
			quiet_stderr => 1) }), '', 'quiet_stderr throws it away');
		($output) = App::Actions::Process::capture(perl_command('$| = 1; print 1; print STDERR 2; print 3'), merge_stderr => 1);
		is($output, '123', 'merge_stderr includes it, in order');
		is_deeply([ App::Actions::Process::capture([ File::Spec->catfile(tempdir(CLEANUP => 1), 'none') ]) ], [ '', 255 ],
			'a missing program is no output and 255');
		($output) = App::Actions::Process::capture(perl_command('print join q{|}, @ARGV', 'a;echo no', '$(id)', '`x`', '*'));
		is($output, 'a;echo no|$(id)|`x`|*', 'arguments are never read by a shell');

		throws_ok { App::Actions::Process::capture($_) } qr/\ANo command given at /, 'refused: ' . shown($_)
			for undef, [], 'echo', { 0 => 'echo' };
		settle('text Process: No command given');

		{
			local $FAIL{seek} = 1;
			throws_ok { App::Actions::Process::capture(perl_command('print 1')) }
				qr/\AUnable to rewind captured output: \S/, 'a temporary file that cannot be rewound';
		}
		settle('text Process: Unable to rewind captured output');
		keeps_globals(sub { App::Actions::Process::capture(perl_command('print 1')) }, 'capture', io => 1);
	};

	subtest 'run' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $out = File::Spec->catfile($dir, 'out');
		my $err = File::Spec->catfile($dir, 'err');
		is(App::Actions::Process::run(perl_command('print q{o}; print STDERR q{e}'), stdout => $out, stderr => $err), 0, 'run');
		my $read = sub { open my $in, '<', $_[0] or die $!; local $/; my $text = <$in>; return defined $text ? $text : '' };
		is($read->($out), 'o', 'the output goes to stdout');
		is($read->($err), 'e', 'the error output to stderr');
		App::Actions::Process::run(perl_command('print q{p}'), stdout => $out, append => 1);
		is($read->($out), 'op', 'append adds to the file');
		App::Actions::Process::run(perl_command('$| = 1; print 1; print STDERR 2'), stdout => $out, stderr => $err, merge_stderr => 1);
		is($read->($out), '12', 'merge_stderr wins over stderr');
		is(output_of(stdout => sub { App::Actions::Process::run(perl_command('print q{gone}')) }), '',
			'without stdout the output is thrown away');

		throws_ok { App::Actions::Process::run(perl_command('1'), stdout => $dir) }
			qr/\AUnable to redirect command output: \S/, 'an output file that cannot be opened';
		settle('text Process: Unable to redirect command output');
		is(output_of(stdout => sub { print "still here\n" }), "still here\n", 'and STDOUT works afterwards');

		for my $stream (qw(STDOUT STDERR)) {
			my $handle = $stream eq 'STDOUT' ? \*STDOUT : \*STDERR;
			local $FAIL{open} = sub { !defined $_[0] && $_[1] eq '>&' && ref $_[2] && $_[2] == $handle };
			throws_ok { App::Actions::Process::run(perl_command('1')) } qr/\AUnable to duplicate $stream: \S/,
				"a $stream that cannot be duplicated";
		}
		settle('text Process: Unable to duplicate STDOUT/STDERR');

		for my $stream (qw(STDOUT STDERR)) {
			open my $keep, '>&', ($stream eq 'STDOUT' ? \*STDOUT : \*STDERR) or die $!;
			my $error;
			{
				local $FAIL{open} = sub { defined $_[0] && !ref $_[0] && $_[0] eq $stream && $_[1] eq '>&'
					&& ref $_[2] && $_[2] != \*STDOUT && $_[2] != \*STDERR };
				$error = caught { App::Actions::Process::run(perl_command('1')) };
			}
			open(($stream eq 'STDOUT' ? \*STDOUT : \*STDERR), '>&', $keep) or die $!;
			like($error, qr/\AUnable to restore $stream: \S/, "a $stream that cannot be restored");
		}
		settle('text Process: Unable to restore STDOUT/STDERR');
		keeps_globals(sub { App::Actions::Process::run(perl_command('exit 0')) }, 'run', io => 1);
	};

	subtest 'run_quiet and stream' => sub {
		my $quiet;
		is(output_of(stderr => sub { is(output_of(stdout => sub {
			$quiet = App::Actions::Process::run_quiet(perl_command('print q{o}; print STDERR q{e}; exit 2')) }), '', 'run_quiet: no output') }),
			'', 'and no error output');
		is($quiet, 2, 'run_quiet: the status');
		my $status;
		is(output_of(stdout => sub { $status = App::Actions::Process::stream(perl_command('print q{live}; exit 5')) }), 'live',
			'stream: the output reaches the terminal');
		is($status, 5, 'stream: the status');
		throws_ok { App::Actions::Process::stream($_) } qr/\ANo command given at /, 'stream refuses ' . shown($_) for undef, [];
		throws_ok { App::Actions::Process::run_quiet([]) } qr/\ANo command given at /, 'run_quiet refuses an empty command';
		keeps_globals(sub { App::Actions::Process::run_quiet(perl_command('1')) }, 'run_quiet', io => 1);
	};

	subtest 'run_parallel' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $out = File::Spec->catfile($dir, 'out');
		my $statuses = App::Actions::Process::run_parallel([ map { perl_command("print q{$_}; exit $_") } 0 .. 3 ],
			concurrency => 2, stdout => $out);
		returns_ok($statuses, { type => 'arrayref' }, 'an array reference');
		is_deeply($statuses, [ 0 .. 3 ], 'one status per command, in their order');
		open my $in, '<', $out or die $!;
		is(join('', sort split //, do { local $/; <$in> }), '0123', 'each program adds to the one file');
		close $in;
		write_file('out', 'old', $dir);
		App::Actions::Process::run_parallel([ perl_command('print q{new}') ], stdout => $out);
		open $in, '<', $out or die $!;
		is(do { local $/; <$in> }, 'new', 'which is emptied once, first');
		close $in;
		is_deeply(App::Actions::Process::run_parallel([]), [], 'no commands, no statuses');
		is_deeply(App::Actions::Process::run_parallel([ (perl_command('exit 1')) x 3 ]), [ 1, 1, 1 ], 'the default concurrency');

		# A program a child cannot start is 127, and the child says why.
		my $err = File::Spec->catfile($dir, 'err');
		my $missing = File::Spec->catfile($dir, 'missing');
		$statuses = App::Actions::Process::run_parallel([ [ $missing ], perl_command('exit 0') ], concurrency => 2, stderr => $err);
		is_deeply($statuses, [ 127, 0 ], 'a program a child cannot start is 127');
		settle('status Process: 127 child could not start');
		open $in, '<', $err or die $!;
		like(do { local $/; <$in> }, qr/\AUnable to run '\Q$missing\E': \S/, 'and the child says so');
		close $in;
		settle('message process.exec_failed');

		# A file the child cannot open: the parent emptied it, the child's
		# append is refused.
		my $said;
		{
			local $FAIL{open} = sub { defined $_[1] && $_[1] eq '>>' };
			$said = output_of(stderr => sub {
				$statuses = App::Actions::Process::run_parallel([ perl_command('1'), perl_command('1') ], concurrency => 2, stdout => $out);
			});
		}
		is_deeply($statuses, [ 127, 127 ], 'an output a child cannot open is 127');
		like($said, qr/^Unable to redirect stdout to '\Q$out\E': \S/m, 'and the child says so');
		settle('message process.redirect_failed');

		throws_ok { App::Actions::Process::run_parallel($_) } qr/\ANo commands given at /, 'refused: ' . shown($_)
			for undef, 'echo', {};
		settle('text Process: No commands given');
		throws_ok { App::Actions::Process::run_parallel([ perl_command('1') ], stdout => $dir) }
			qr/\AUnable to open '\Q$dir\E': \S/, 'an output file that cannot be emptied';
		settle(q{text Process: Unable to open 'F'});
		keeps_globals(sub { App::Actions::Process::run_parallel([ perl_command('1') ]) }, 'run_parallel', io => 1);
	};

	subtest 'quote_win32' => sub {
		my %quoted = (
			'plain' => 'plain',
			'' => '""',
			'two words' => '"two words"',
			'say "hi"' => '"say \\"hi\\""',
			'C:\\dir\\' => 'C:\\dir\\',
			'C:\\my dir\\' => '"C:\\my dir\\\\"',
			"tab\there" => "\"tab\there\"",
		);
		is(App::Actions::Process::quote_win32($_), $quoted{$_}, 'quoted: ' . shown($_)) for sort keys %quoted;
		is(App::Actions::Process::quote_win32(undef), '""', 'undef is the empty argument');
		returns_ok(App::Actions::Process::quote_win32('x'), { type => 'string', min => 1 }, 'never empty');
		keeps_globals(sub { App::Actions::Process::quote_win32('a b') }, 'quote_win32');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Docker
# ---------------------------------------------------------------------------

# A scripted stand-in for the docker client.  Each rule is a pattern matched
# against the arguments joined by spaces, then the status, the output and
# the error output to give; the first rule that matches wins and anything
# else succeeds silently.  Every call is logged twice: the arguments exactly
# as given (what any user of the host can read in ps), and, as "ENV NAME=VALUE"
# lines, each bare "-e NAME" the client found in its environment.  The name
# ends in .pl, so it is run with this Perl, as the POD says.
#
# The status PROBE plays App::Actions::Check's probe container: it prints the
# marker file from the folder mounted on /action-run-check, then the number
# of entries in the one on /check-project (0 when there is none), or the
# rule's output instead of that number when the rule gives one.
Readonly::Scalar my $FAKE_DOCKER => <<'FAKE';
use strict;
use warnings;

my @args = @ARGV;
if (open my $log, '>>', $ENV{UNIT_DOCKER_LOG}) {
	print {$log} join("\t", 'ARGV', @args), "\n";
	for my $index (1 .. $#args) {
		next unless $args[$index - 1] eq '-e' && exists $ENV{ $args[$index] };
		print {$log} "ENV\t$args[$index]=$ENV{ $args[$index] }\n";
	}
	close $log;
}
my $line = join ' ', @args;
open my $rules, '<', $ENV{UNIT_DOCKER_RULES} or exit 0;
while (my $rule = <$rules>) {
	chomp $rule;
	my ($pattern, $status, $out, $err) = split /\t/, $rule, 4;
	next unless $line =~ /$pattern/;
	s/\\n/\n/g, s/\\r/\r/g for grep { defined } $out, $err;
	$| = 1;
	if ($status eq 'PROBE') {
		my %mount = map { (split /:/, $args[$_ + 1])[1, 0] } grep { $args[$_] eq '-v' } 0 .. $#args - 1;
		open my $marker, '<', "$mount{'/action-run-check'}/marker" or exit 1;
		print scalar(<$marker>), "\n";
		my $count = 0;
		if (defined $mount{'/check-project'} && opendir my $dir, $mount{'/check-project'}) {
			$count = grep { !/\A\.\.?\z/ } readdir $dir;
		}
		print defined $out && length $out ? $out : $count, "\n";
		exit 0;
	}
	print $out if defined $out;
	print STDERR $err if defined $err;
	kill 'TERM', $$ if $status eq 'TERM';
	exit $status;
}
exit 0;
FAKE

my $fake_docker = write_file('docker.pl', $FAKE_DOCKER);

# Run $code with the fake answering by @$rules ([pattern, status, out, err]);
# returns the log: { argv => [ [args], ... ], env => { NAME => VALUE } }.
sub with_docker {
	my ($rules, $code) = @_;

	my $dir = tempdir(CLEANUP => 1);
	my $rules_file = write_file('rules', join('', map { join("\t", map { defined ? $_ : '' } @{$_}) . "\n" } @{$rules}), $dir);
	local $ENV{UNIT_DOCKER_RULES} = $rules_file;
	local $ENV{UNIT_DOCKER_LOG} = File::Spec->catfile($dir, 'log');
	$code->();

	my %log = (argv => [], env => {});
	open my $in, '<', $ENV{UNIT_DOCKER_LOG} or return \%log;
	while (my $line = <$in>) {
		chomp $line;
		my ($kind, @fields) = split /\t/, $line, -1;
		push @{ $log{argv} }, \@fields if $kind eq 'ARGV';
		$log{env}{$1} = $2 if $kind eq 'ENV' && $fields[0] =~ /\A([^=]+)=(.*)\z/s;
	}
	close $in;
	show_state(docker_log => \%log);
	return \%log;
}

sub docker {
	return App::Actions::Docker->new(bin => $fake_docker, @_);
}

subtest 'App::Actions::Docker' => sub {
	subtest 'new and its accessors' => sub {
		my $docker = docker();
		isa_ok($docker, 'App::Actions::Docker');
		is($docker->bin, $fake_docker, 'bin');
		for my $flag (qw(dry_run explain verbose quiet)) {
			is($docker->$flag, 0, "$flag is 0 by default");
			returns_ok(docker($flag => 'yes')->$flag, { type => 'integer', memberof => [ 1 ] }, "$flag is 1 when asked for");
		}
		{
			local $ENV{DOCKER} = '/opt/docker';
			is(App::Actions::Docker->new->bin, '/opt/docker', 'bin defaults to DOCKER');
			local $ENV{DOCKER} = '';
			is(App::Actions::Docker->new->bin, 'docker', 'then to docker');
		}
		is_deeply([ $docker->platform_args ], [], 'no platform, no platform arguments');
		is_deeply([ docker(platform => 'linux/arm64')->platform_args ], [ '--platform', 'linux/arm64' ], 'a platform');
		is_deeply([ docker(platform => '')->platform_args ], [], 'an empty platform is none');
		keeps_globals(sub { docker(secrets => { A => 'b' })->bin }, 'new');
	};

	subtest 'Perl wrappers' => sub {
		# A #! perl script without the executable bit still runs.
		my $script = write_file('docker', "#!/usr/bin/perl\nprint qq{wrapped\\n};\n");
		chmod 0644, $script;
		my ($output, $status) = App::Actions::Docker->new(bin => $script)->capture('version');
		is_deeply([ $output, $status ], [ "wrapped\n", 0 ], 'a #! perl script is run with this Perl');
	};

	subtest 'check' => sub {
		is(App::Actions::Docker->new(bin => File::Spec->catfile(tempdir(CLEANUP => 1), 'none'), dry_run => 1)->check, 1,
			'a dry run checks nothing');
		my $result;
		my $log = with_docker([], sub { $result = docker()->check });
		is($result, 1, 'a working docker is 1');
		is_deeply([ map { $_->[0] } @{ $log->{argv} } ], [ '--version', 'info' ], 'it asks for the version, then the daemon');

		my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'none');
		throws_ok { App::Actions::Docker->new(bin => $missing)->check }
			qr/\ADocker executable '\Q$missing\E' was not found or is not usable at /, 'no docker program';
		with_docker([ [ '^--version', 1 ] ], sub {
			throws_ok { docker()->check } qr/\ADocker executable '.*' was not found or is not usable at /, 'a docker that fails';
		});
		settle("text Docker: Docker executable 'BIN' was not found or is not usable");

		my $said;
		with_docker([ [ '^info', 1, '', "daemon down\\n" ] ], sub {
			$said = output_of(stderr => sub {
				throws_ok { docker()->check }
					qr/\ACannot connect to the Docker daemon\. Is Docker running, and can this user access it\? at /,
					'no daemon';
			});
		});
		like($said, qr/daemon down/, "docker's own reason is shown");
		with_docker([ [ '^info', 1, '', "daemon down\\n" ] ], sub {
			$said = output_of(stderr => sub { eval { docker(quiet => 1)->check } });
		});
		is($said, '', 'but not when quiet');
		settle('text Docker: Cannot connect to the Docker daemon');

		with_docker([ [ '^--version', 0, "Docker version 99\\n" ] ], sub {
			is(output_of(stdout => sub { docker(verbose => 1)->check }), "+ $fake_docker --version\nDocker version 99\n"
				. "+ $fake_docker info --format '{{.ServerVersion}}'\n", 'verbose shows the commands and the version');
		});
		with_docker([], sub { keeps_globals(sub { docker()->check }, 'check', io => 1) });
	};

	subtest 'images' => sub {
		with_docker([ [ 'inspect --format \{\{\.Id\}\} there', 0 ], [ 'inspect', 1 ] ], sub {
			is(docker()->image_exists('there'), 1, 'an image that is here');
			is(docker()->image_exists('gone'), 0, 'one that is not');
		});
		is(docker(dry_run => 1)->image_exists('gone'), 1, 'a dry run says yes');

		with_docker([ [ 'Size\}\} big', 0, "1234\\r\\n" ], [ 'Size\}\} odd', 0, 'lots' ], [ 'Size', 1 ] ], sub {
			is(docker()->image_size('big'), 1234, 'the size in bytes');
			is(docker()->image_size('odd'), undef, 'undef when docker says something else');
			is(docker()->image_size('gone'), undef, 'undef for a missing image');
		});
		is(docker(dry_run => 1)->image_size('big'), undef, 'undef in a dry run');

		my $log = with_docker([ [ '^pull', 0, "pulled\\n" ] ], sub {
			is(output_of(stdout => sub { is(docker(platform => 'linux/amd64')->pull('perl:5.40'), 1, 'pull is 1') }),
				"pulled\n", "docker's progress is shown");
		});
		is_deeply($log->{argv}, [ [ 'pull', '--platform', 'linux/amd64', 'perl:5.40' ] ], 'with the platform');
		with_docker([ [ '^pull', 3 ] ], sub {
			throws_ok { docker()->pull('nope') } qr/\AFailed to pull Docker image 'nope' \(exit 3\)\n\z/,
				'a failed pull dies with advice, not a line number';
			ok($@->is('runner.image.pull_failed'), 'as runner.image.pull_failed');
		});

		my $results;
		$log = with_docker([ [ 'pull bad', 2 ] ], sub {
			$results = docker()->pull_many([ 'good', 'bad', 'fine' ], concurrency => 2);
		});
		returns_ok($results, { type => 'hashref' }, 'pull_many: a hash reference');
		is_deeply($results, { good => 0, bad => 2, fine => 0 }, 'the status of each pull');
		is(scalar @{ $log->{argv} }, 3, 'one pull each');
		with_docker([ [ 'pull', 0, "noise\\n", "more\\n" ] ], sub {
			is(output_of(stderr => sub { is(output_of(stdout => sub { docker()->pull_many([ 'a' ], quiet => 1) }), '',
				'quiet: no output') }), '', 'and no error output');
			is(output_of(stdout => sub { docker(verbose => 1)->pull_many([ 'a', 'b' ], quiet => 1) }), '', 'even when verbose');
			like(output_of(stdout => sub { docker(verbose => 1)->pull_many([ 'a', 'b' ]) }),
				qr/\A\+ \Q$fake_docker\E pull a\n\+ \Q$fake_docker\E pull b\n/, 'verbose: the commands first');
		});
		is(output_of(stdout => sub { $results = docker(dry_run => 1, platform => 'x/y')->pull_many([ 'a', 'b' ]) }),
			"[dry-run] $fake_docker pull --platform x/y a\n[dry-run] $fake_docker pull --platform x/y b\n",
			'a dry run prints the pulls');
		is_deeply($results, { a => 0, b => 0 }, 'and says they worked');
		is(output_of(stdout => sub { docker(dry_run => 1, explain => 1)->pull_many([ 'a' ]) }), '', 'unless it is explaining');
		throws_ok { docker()->pull_many($_) } qr/\ANo images given at /, 'pull_many refuses ' . shown($_)
			for undef, [], 'perl', { perl => 1 };
		settle('text Docker: No images given');

		$log = with_docker([ [ 'image rm', 1, 'out', 'err' ] ], sub {
			is(output_of(stdout => sub { is(docker()->image_remove('old'), 1, 'image_remove: the status') }), '',
				'and nothing is shown');
		});
		is_deeply($log->{argv}, [ [ qw(image rm -f old) ] ], 'it forces the removal');
		is(docker(dry_run => 1, quiet => 1)->image_remove('old'), 0, '0 in a dry run');
	};

	subtest 'networks and containers' => sub {
		my $log = with_docker([ [ '^network create', 0 ], [ '^network rm', 4 ] ], sub {
			is(docker()->network_create('net'), 0, 'network_create');
			is(docker()->network_remove('net'), 4, 'network_remove: the status');
		});
		is_deeply($log->{argv}, [ [ qw(network create net) ], [ qw(network rm net) ] ], 'the network commands');

		$log = with_docker([ [ 'run -d bad', 125, '', "port is already allocated\\n" ], [ '^run', 0, "abc123\\n" ] ], sub {
			is(output_of(stdout => sub { is(docker()->container_start('--name', 'j', 'img'), 0, 'container_start') }), '',
				'shows nothing');
			is_deeply([ docker()->container_start_captured('bad') ], [ "port is already allocated\n", 125 ],
				'container_start_captured: why it failed, and the status');
			is_deeply([ docker()->container_start_captured('img') ], [ "abc123\n", 0 ], 'and the id when it worked');
		});
		is_deeply($log->{argv}[0], [ qw(run -d --name j img) ], 'run -d');

		with_docker([ [ '^exec', 6, "from inside\\n" ] ], sub {
			my $status;
			is(output_of(stdout => sub { $status = docker()->container_exec('j', 'sh', '-c', 'exit 6') }), "from inside\n",
				'container_exec shows the output');
			is($status, 6, 'and returns the status');
		});

		with_docker([ [ 'Running\}\} up', 0, "true\\n" ], [ 'Running\}\} down', 0, "false\\n" ], [ 'Running', 1 ] ], sub {
			is(docker()->container_running('up'), 1, 'container_running: running');
			is(docker()->container_running('down'), 0, 'stopped');
			is(docker()->container_running('gone'), 0, 'gone');
		});
		is(docker(dry_run => 1, quiet => 1)->container_running('gone'), 1, 'a dry run says yes');

		$log = with_docker([ [ '^logs', 0, "line\\n", "error line\\n" ] ], sub {
			is(output_of(stdout => sub { is(docker()->container_logs('j'), 0, 'container_logs: the status') }), "line\n",
				'shows the lines');
			docker()->container_logs('j', 5);
			is(docker()->container_log_text('j'), "line\nerror line\n", 'container_log_text: both streams');
			docker()->container_log_text('j', 3);
		});
		is_deeply([ map { $_->[2] } @{ $log->{argv} } ], [ 200, 5, 10, 3 ], 'the default numbers of lines are 200 and 10');
		is(docker(dry_run => 1, quiet => 1)->container_log_text('j'), '', 'empty in a dry run');

		with_docker([
			[ 'ExitCode\}\} three', 0, "3\\r\\n" ], [ 'ExitCode\}\} negative', 0, "-1\\n" ], [ 'ExitCode\}\} odd', 0, "none\\n" ],
			[ 'Status\}\} db', 0, "restarting\\n" ], [ 'Status\}\} blank', 0, "\\n" ],
			[ 'RestartCount\}\} db', 0, "2\\n" ], [ 'RestartCount\}\} odd', 0, "-1\\n" ],
			[ 'inspect', 1 ],
		], sub {
			is(docker()->container_exit_code('three'), 3, 'container_exit_code');
			is(docker()->container_exit_code('negative'), -1, 'which may be negative');
			is(docker()->container_exit_code('odd'), undef, 'undef when it is not a number');
			is(docker()->container_exit_code('gone'), undef, 'undef when docker cannot say');
			is(docker()->container_status('db'), 'restarting', 'container_status');
			is(docker()->container_status('blank'), undef, 'undef when empty');
			is(docker()->container_status('gone'), undef, 'undef when docker cannot say');
			is(docker()->container_restart_count('db'), 2, 'container_restart_count');
			is(docker()->container_restart_count('odd'), undef, 'undef when not a count');
			is(docker()->container_restart_count('gone'), undef, 'undef when docker cannot say');
		});
		my $dry = docker(dry_run => 1, quiet => 1);
		is_deeply([ $dry->container_exit_code('x'), $dry->container_status('x'), $dry->container_restart_count('x') ],
			[ 0, 'running', 0 ], 'a dry run: exit 0, running, never restarted');

		$log = with_docker([ [ '^rm', 1 ] ], sub { is(docker()->container_remove('j'), 1, 'container_remove: the status') });
		is_deeply($log->{argv}, [ [ qw(rm -f j) ] ], 'rm -f');
	};

	subtest 'run, run_silent and the captures' => sub {
		with_docker([ [ '^ps', 0, "out\\r\\n", "err\\n" ], [ '^die', 'TERM' ] ], sub {
			my ($status, $error);
			is(output_of(stdout => sub { $error = output_of(stderr => sub { $status = docker()->run('ps') }) }), "out\r\n",
				'run shows the output as it is');
			is($error, "err\n", 'and the error output');
			is($status, 0, 'and returns the status');
			is(docker()->run('die'), 128 + 15, 'a signal is 128 plus its number');
			is(output_of(stdout => sub { $error = output_of(stderr => sub { $status = docker()->run_silent('ps') }) }), '',
				'run_silent shows nothing');
			is($error, '', 'not even errors');

			my ($output);
			$error = output_of(stderr => sub { ($output, $status) = docker()->capture('ps') });
			is_deeply([ $output, $status ], [ "out\n", 0 ], 'capture: the output, CRLF made LF, and the status');
			is($error, "err\n", 'the error output goes to the terminal');
			$error = output_of(stderr => sub { ($output) = docker()->capture_silent('ps') });
			is_deeply([ $output, $error ], [ "out\n", '' ], 'capture_silent throws the error output away');
			($output) = docker()->capture_merged('ps');
			is($output, "out\nerr\n", 'capture_merged includes it');
		});
		for my $method (qw(capture capture_silent capture_merged)) {
			is_deeply([ docker(dry_run => 1, quiet => 1)->$method('ps') ], [ '', 0 ], "$method: ('', 0) in a dry run");
		}
		is(docker(dry_run => 1, quiet => 1)->run('ps'), 0, 'run: 0 in a dry run');

		# What is printed: [dry-run] or +, quoted so it could be pasted, with
		# the secrets hidden.
		my $docker = docker(dry_run => 1, secrets => { TOKEN => 'hunter2', EMPTY => '' });
		is(output_of(stdout => sub { $docker->run('run', '-e', 'TOKEN=anything', '-e', 'X=hunter2 too', "it's", '', 'a=b') }),
			qq{[dry-run] $fake_docker run -e 'TOKEN=***' -e 'X=*** too' 'it'\\''s' '' a=b\n},
			'a dry run prints the command, quoted, with secrets hidden');
		is(output_of(stdout => sub { docker(dry_run => 1, quiet => 1)->run('ps') }), '', 'quiet prints nothing');
		is(output_of(stdout => sub { docker(dry_run => 1, explain => 1)->run('ps') }), '', 'nor does explain');
		with_docker([], sub {
			is(output_of(stdout => sub { docker(verbose => 1, secrets => { T => 'pw' })->run_silent('login', '-p', 'pw') }),
				"+ $fake_docker login -p '***'\n", 'verbose prints the command with +');
			is(output_of(stdout => sub { docker(verbose => 1, quiet => 1)->run_silent('ps') }), '', 'quiet wins over verbose');
		});
		with_docker([], sub { keeps_globals(sub { docker()->run_silent('ps') }, 'run_silent', io => 1) });
	};

	subtest 'job variables' => sub {
		# A variable after -e is kept off the command line, unless hiding it
		# would change what the command does.
		my $variable = sub { App::Actions::Docker::Variable->new(@_) };
		my $log = with_docker([], sub {
			docker()->run('run',
				'-e', $variable->('TOKEN', 's3cret'),
				'-e', $variable->('INPUT_GITHUB-TOKEN', 'dashed'),
				'-e', $variable->('DOCKER_HOST', 'tcp://x'),
				'-e', $variable->('https_proxy', 'http://p'),
				'-e', $variable->('Mixed', 'one'),
				'-e', $variable->('MIXED', 'two'),
				'-e', $variable->('NUL', "a\0b"),
				'-e', $variable->('1BAD', 'bad'),
				'-e', 'PLAIN=visible',
				'img');
		});
		is_deeply($log->{argv}, [ [ 'run',
			'-e', 'TOKEN', '-e', 'INPUT_GITHUB-TOKEN', '-e', 'DOCKER_HOST=tcp://x', '-e', 'https_proxy=http://p',
			'-e', 'Mixed=one', '-e', 'MIXED=two', '-e', 'NUL=a', '-e', '1BAD=bad', '-e', 'PLAIN=visible', 'img' ] ],
			'only the variables it is safe to hide are hidden (an argument, like an environment, ends at a NUL)');
		is_deeply($log->{env}, { TOKEN => 's3cret', 'INPUT_GITHUB-TOKEN' => 'dashed' }, 'the client reads them from its environment');
		ok(!exists $ENV{TOKEN}, 'which is put back afterwards');

		my $docker = docker(dry_run => 1, secrets => { TOKEN => 's3cret' });
		is(output_of(stdout => sub { $docker->capture('run', '-e', $variable->('TOKEN', 's3cret'), '-e', $variable->('V', 'v')) }),
			"[dry-run] $fake_docker run -e 'TOKEN=***' -e V=v\n", 'what is printed is NAME=VALUE, with secrets hidden');
	};

	subtest 'redact' => sub {
		my $docker = docker(secrets => { SHORT => 'abc', LONG => 'abcdef', EMPTY => '', NONE => undef });
		is($docker->redact('abcdef and abc'), '*** and ***', 'the longer secret first, so none of it is left');
		is($docker->redact('nothing secret'), 'nothing secret', 'other text is left alone');
		is($docker->redact(undef), undef, 'undef stays undef');
		is($docker->redact(''), '', 'an empty secret is never redacted');
		is($docker->redact('a.c'), 'a.c', 'a secret is text, not a pattern');
		returns_ok($docker->redact('x'), { type => 'string' }, 'a string');
		keeps_globals(sub { $docker->redact('abc') }, 'redact');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Expression
# ---------------------------------------------------------------------------

subtest 'App::Actions::Expression' => sub {
	my $expression = App::Actions::Expression->new;
	my $list = [ 'a', 'b', 'c' ];
	my %context = (
		matrix => { perl => '5.40', empty => '' },
		env => { HOME => '/home/me' },
		list => $list,
		steps => { build => { outputs => { path => 'out/x' } } },
		text => 'has ${{ matrix.perl }} inside',
	);
	my $evaluate = sub { $expression->evaluate($_[0], \%context, $_[1]) };

	subtest 'new' => sub {
		returns_ok($expression, { type => 'object', isa => 'App::Actions::Expression' }, 'an evaluator');
		keeps_globals(sub { App::Actions::Expression->new }, 'new');
	};

	subtest 'evaluate: values and lookups' => sub {
		is($evaluate->(q{'it''s'}), q{it's}, 'a string, with a doubled quote');
		is($evaluate->('42'), 42, 'a number');
		is($evaluate->('-1.5'), -1.5, 'a negative number');
		is($evaluate->('1e3'), 1000, 'an exponent');
		is($evaluate->('.5'), 0.5, 'a number may start with a dot');
		ok($evaluate->('(.5 == 0.5) == true'), 'also after a bracket or an operator');
		ok(JSON::PP::is_bool($evaluate->('true')) && $evaluate->('true'), 'true is a boolean');
		ok(JSON::PP::is_bool($evaluate->('false')) && !$evaluate->('false'), 'false is a boolean');
		is($evaluate->('null'), undef, 'null is undef');
		is($evaluate->('matrix.perl'), '5.40', 'a property');
		is($evaluate->(q{ENV['home']}), '/home/me', 'an index by name, without regard to case');
		is($evaluate->('steps.build.outputs.path'), 'out/x', 'a path');
		is($evaluate->('list[0]'), 'a', 'an array index');
		is($evaluate->('list[-1]'), 'c', 'a negative index counts from the end');
		is($evaluate->('list[3]'), undef, 'past the end is null');
		is($evaluate->('list[-4]'), undef, 'before the start is null');
		is($evaluate->('matrix.pearl'), undef, 'a missing name is null, not an error');
		is($evaluate->('list'), $list, 'the context is not copied');
		is($expression->evaluate('matrix'), undef, 'no context, nothing found');
	};

	subtest 'evaluate: operators and comparisons' => sub {
		my %cases = (
			q{matrix.empty || 'default'} => 'default',
			q{matrix.perl || 'default'} => '5.40',
			q{matrix.perl && 'yes'} => 'yes',
			q{matrix.empty && 'yes'} => '',
			q{'ABC' == 'abc'} => 1,
			q{'1.0' == 1} => 1,
			q{'1.0' == '1'} => 1,
			q{true == 1} => 1,
			q{false == 0} => 1,
			q{'a' != 'b'} => 1,
			'10 > 9' => 1,
			'2 <= 2' => 1,
			q{'a' < 'B'} => 1,
			'1 >= 2' => 0,
			'!null' => 1,
			q{!(1 == 1)} => 0,
			q{1 == 1 || 0 && 0} => 1,
		);
		for my $text (sort keys %cases) {
			my $value = $evaluate->($text);
			is(0 + (ref $value || !defined $value || $value eq '' ? ($value ? 1 : 0) : ($value =~ /\A\d/ ? $value : 1)),
				0 + $cases{$text}, $text) if $cases{$text} =~ /\A[01]\z/;
			is($value, $cases{$text}, "$text is an operand") unless $cases{$text} =~ /\A[01]\z/;
		}
		ok(JSON::PP::is_bool($evaluate->(q{1 == 1})), 'a comparison gives a boolean');
		ok(JSON::PP::is_bool($evaluate->('!1')), 'so does !');
	};

	subtest 'evaluate: functions' => sub {
		ok($evaluate->(q{contains(list, 'B')}), 'contains: an array, without regard to case');
		ok(!$evaluate->(q{contains(list, 'z')}), 'not in the array');
		ok($evaluate->(q{contains('Hello', 'LL')}), 'contains: text');
		ok($evaluate->(q{startsWith('Hello', 'he')}) && $evaluate->(q{endsWith('Hello', 'LO')}), 'startsWith and endsWith');
		ok(!$evaluate->(q{endsWith('lo', 'hello')}), 'a longer ending does not end it');
		is($evaluate->(q{format('{0}-{{x}}-{1}-{2}', 'a', true)}), 'a-{x}-true-', 'format');
		is($evaluate->(q<format('{0}}}', 'a')>), 'a}', 'format reads left to right');
		is($evaluate->(q{join(list, '+')}), 'a+b+c', 'join');
		is($evaluate->('toJSON(matrix)'), '{"empty":"","perl":"5.40"}', 'toJSON, in a stable order');
		is_deeply($evaluate->(q{fromJSON('[1, {"a": null}]')}), [ 1, { a => undef } ], 'fromJSON');
		is($evaluate->(q{fromJSON('null')}), undef, 'fromJSON of null');
		ok($evaluate->(q{ALWAYS()}), 'always(), in any case');
		my %status = (success => 1, cancelled => 1);
		ok($evaluate->('success()', \%status) && $evaluate->('Cancelled()', \%status) && !$evaluate->('failure()', \%status),
			'the status functions answer from the status hash');
		ok(!$evaluate->('success()'), 'without it they are false');
		ok(JSON::PP::is_bool($evaluate->('success()')), 'and they give a boolean');
		keeps_globals(sub { $evaluate->(q{fromJSON('[1]')}) }, 'fromJSON');
	};

	subtest 'evaluate: errors' => sub {
		my @errors = (
			[ undef, 'Cannot evaluate an undefined expression', 'text Expression: Cannot evaluate an undefined expression' ],
			[ " \t", 'Cannot evaluate an empty expression', 'text Expression: Cannot evaluate an empty expression' ],
			[ q{'abc}, q{Unterminated string in expression ''abc'}, 'text Expression: Unterminated string' ],
			[ 'a + b', q{Unexpected character '+' in expression 'a + b'}, 'text Expression: Unexpected character' ],
			[ 'a b', q{Unexpected 'b' in expression 'a b'}, 'text Expression: Unexpected X' ],
			[ ')', q{Unexpected ')' in expression}, 'text Expression: Unexpected X' ],
			[ 'a ==', 'Unexpected end of expression', 'text Expression: Unexpected end of expression' ],
			[ '(a', q{Expected ')' in expression}, q{text Expression: Expected 'X' in expression} ],
			[ 'list[0', q{Expected ']' in expression}, q{text Expression: Expected 'X' in expression} ],
			[ 'a.', 'Expected a property name after dot', 'text Expression: Expected a property name after dot' ],
			[ 'a.1', 'Expected a property name after dot', 'text Expression: Expected a property name after dot' ],
			[ q{contains('a')}, 'contains() expects two arguments', 'text Expression: F() expects N argument(s)' ],
			[ q{startsWith('a')}, 'startsWith() expects two arguments', 'text Expression: F() expects N argument(s)' ],
			[ 'format()', 'format() expects at least one argument', 'text Expression: F() expects N argument(s)' ],
			[ q{join('a')}, 'join() expects two arguments', 'text Expression: F() expects N argument(s)' ],
			[ 'toJSON()', 'toJSON() expects one argument', 'text Expression: F() expects N argument(s)' ],
			[ 'fromJSON(1, 2)', 'fromJSON() expects one argument', 'text Expression: F() expects N argument(s)' ],
			[ q{join('a', ',')}, 'join() first argument must be an array', 'text Expression: join() first argument must be an array' ],
			[ q{hashFiles('x')}, 'hashFiles() is not supported by local action-run', 'text Expression: hashFiles() is not supported' ],
			[ 'nope(1)', q{Unknown function 'nope()' in expression}, 'text Expression: Unknown function' ],
		);
		for my $case (@errors) {
			my ($text, $message, $entry) = @{$case};
			throws_ok { $evaluate->($text) } qr/\A\Q$message\E at .+ line \d+\.$/, shown($text) . " is refused: $message";
			settle($entry);
		}
		throws_ok { $evaluate->(q<fromJSON('{')>) } qr/\AfromJSON\(\) failed: [^\n]+ at \Q$0\E line \d+\.$/,
			'invalid JSON is refused, with the reason and only the caller named';
		settle('text Expression: fromJSON() failed');
	};

	subtest 'interpolate' => sub {
		my $interpolate = sub { $expression->interpolate($_[0], \%context, $_[1]) };
		is($interpolate->('perl ${{ matrix.perl }} in ${{env.HOME}}'), 'perl 5.40 in /home/me', 'each expression is replaced');
		is($interpolate->(q<${{ '}}' }}>), '}}', 'a }} in a string is text');
		is($interpolate->('[${{ matrix.nope }}][${{ null }}]'), '[][]', 'null and missing names are empty');
		is($interpolate->('${{ 1 == 1 }} ${{ 1 == 2 }}'), 'true false', 'booleans are true and false');
		is($interpolate->('${{ list }}'), '["a","b","c"]', 'an array is JSON');
		is($interpolate->('${{ text }}'), 'has ${{ matrix.perl }} inside', 'text from a value is not searched again');
		is($interpolate->('no expressions'), 'no expressions', 'other text is unchanged');
		is($interpolate->(undef), undef, 'undef is returned');
		is($interpolate->($list), $list, 'so is a reference');
		throws_ok { $interpolate->('x ${{ a ') } qr/\AUnclosed expression in 'x \$\{\{ a ' at /, 'an unclosed expression';
		throws_ok { $interpolate->(q{${{ 'a }}}) } qr/\AUnclosed expression in /, 'one whose string never closes';
		settle(q{text Expression: Unclosed expression in 'T'});
		throws_ok { $interpolate->('${{ + }}') } qr/\AUnexpected character '\+'/, 'and any error of evaluate';
		returns_ok($interpolate->('${{ 1 }}'), { type => 'string' }, 'a string');
		keeps_globals(sub { $interpolate->('${{ matrix.perl }}') }, 'interpolate');
	};

	subtest 'interpolate_strict' => sub {
		is($expression->interpolate_strict('${{ matrix.perl }}', \%context), '5.40', 'what exists is replaced');
		is($expression->interpolate_strict('[${{ matrix.empty }}]', \%context), '[]', 'an empty value is not an error');
		throws_ok { $expression->interpolate_strict('img:${{  matrix.nope  }}', \%context) }
			qr/\Aunable to resolve '\$\{\{ matrix\.nope \}\}' from the values available at /, 'a missing name is';
		settle('text Expression: unable to resolve');
		is($expression->interpolate('${{ matrix.nope }}', \%context), '', 'and interpolate is not left strict afterwards');
		is($expression->interpolate_strict(undef), undef, 'undef is returned');
		keeps_globals(sub { $expression->interpolate_strict('${{ 1 }}') }, 'interpolate_strict');
	};

	subtest 'interpolate_known' => sub {
		is($expression->interpolate_known('${{ matrix.perl }}/${{ secrets.TOKEN }}/${{matrix.empty}}.', \%context),
			'5.40/${{ secrets.TOKEN }}/.', 'what is missing is left exactly as written');
		is($expression->interpolate_known('${{ secrets.A }}${{ secrets.B }}', {}), '${{ secrets.A }}${{ secrets.B }}',
			'all of it, if need be');
		throws_ok { $expression->interpolate_known('${{ x', {}) } qr/\AUnclosed expression in /, 'an unclosed expression';
		is($expression->interpolate_known($list), $list, 'a reference is returned');
		keeps_globals(sub { $expression->interpolate_known('${{ a }}') }, 'interpolate_known');
	};

	subtest 'condition' => sub {
		my $condition = sub { $expression->condition($_[0], \%context, $_[1]) };
		my %cases = (
			'' => 1, '   ' => 1, 'false' => 0, '${{ false }}' => 0, ' ${{ true }} ' => 1, 'null' => 0, q{''} => 0,
			'0' => 0, q{'0'} => 0, q{'false'} => 1, q{fromJSON('[]')} => 1, q{fromJSON('{}')} => 1,
			q{matrix.perl == '5.40'} => 1, '${{ matrix.empty }}' => 0, 'success()' => 0,
		);
		for my $if (sort keys %cases) {
			is_returned($condition->($if), { type => 'integer', memberof => [ 0, 1 ] }, $cases{$if}, "if: $if");
		}
		is($condition->(undef), 1, 'no condition runs');
		is($condition->(JSON::PP::false), 0, 'a YAML false is used as it is');
		is($condition->(JSON::PP::true), 1, 'and a true');
		is($condition->('${{ success() }}', { success => 1 }), 1, 'the status is used');
		throws_ok { $condition->('${{ a b }}') } qr/\AUnexpected 'b'/, 'and an invalid one is refused';
		keeps_globals(sub { $condition->('success()') }, 'condition');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Action
# ---------------------------------------------------------------------------

subtest 'App::Actions::Action' => sub {
	# Each case is a metadata file written to a fresh directory, so the
	# messages can be checked with the real path in them.
	my $action_file = sub {
		my ($yaml, $name) = @_;
		return write_file(defined $name ? $name : 'action.yml', $yaml);
	};
	my $composite = "runs:\n  using: composite\n  steps:\n    - run: echo hi\n      shell: bash\n";

	subtest 'load_from_dir' => sub {
		my $dir = tempdir(CLEANUP => 1);
		write_file('action.yaml', "runs:\n  using: docker\n  image: Dockerfile\n", $dir);
		my $action = App::Actions::Action->load_from_dir($dir);
		returns_ok($action, { type => 'object', isa => 'App::Actions::Action' }, 'an action');
		is($action->file, File::Spec->catfile($dir, 'action.yaml'), 'action.yaml is found');
		write_file('action.yml', $composite, $dir);
		is(App::Actions::Action->load_from_dir($dir)->file, File::Spec->catfile($dir, 'action.yml'), 'action.yml comes first');

		throws_code(sub { App::Actions::Action->load_from_dir($_->[0]) }, 'action.dir_required', 'No action directory given',
			'no directory: ' . shown($_->[0])) for [ undef ], [ '' ];
		my $missing = File::Spec->catfile($dir, 'missing');
		throws_code(sub { App::Actions::Action->load_from_dir($missing) }, 'action.dir_missing',
			"Action directory '$missing' does not exist", 'a directory that does not exist');
		my $empty = tempdir(CLEANUP => 1);
		throws_code(sub { App::Actions::Action->load_from_dir($empty) }, 'action.no_metadata',
			"No action.yml or action.yaml found in '$empty'", 'a directory with no metadata');
		mkdir File::Spec->catdir($empty, 'action.yml');
		throws_code(sub { App::Actions::Action->load_from_dir($empty) }, 'action.no_metadata', undef,
			'a directory called action.yml is not metadata');
		keeps_globals(sub { App::Actions::Action->load_from_dir($dir) }, 'load_from_dir', io => 1);
	};

	subtest 'load: what is refused' => sub {
		throws_code(sub { App::Actions::Action->load($_->[0]) }, 'action.file_required', 'No action metadata file given',
			'no file: ' . shown($_->[0])) for [ undef ], [ '' ];
		my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'action.yml');
		throws_code(sub { App::Actions::Action->load($missing) }, 'action.file_missing',
			"Action metadata file '$missing' does not exist", 'a file that does not exist');

		my $file = $action_file->("runs: [unclosed\n");
		my $error = throws_code(sub { App::Actions::Action->load($file) }, 'action.parse_failed', undef, 'malformed YAML');
		like($error->message, qr/\AUnable to parse action metadata '\Q$file\E': \S/, 'the message names the file and the reason');

		my @cases = (
			[ '', 'action.empty', "Action metadata '%s' is empty" ],
			[ "- a\n- b\n", 'action.not_mapping', "Action metadata '%s' must contain a YAML mapping" ],
			[ "name: x\n", 'action.no_runs', "Action metadata '%s' has no 'runs' mapping" ],
			[ "runs: composite\n", 'action.no_runs', "Action metadata '%s' has no 'runs' mapping" ],
			[ "runs:\n  main: x.js\n", 'action.no_using', "Action metadata '%s' has no 'runs.using'" ],
			[ "runs:\n  using: ''\n", 'action.no_using', "Action metadata '%s' has no 'runs.using'" ],
			[ "runs:\n  using: composite\n", 'action.no_steps', "Composite action '%s' has no 'runs.steps' list" ],
			[ "runs:\n  using: composite\n  steps: echo\n", 'action.no_steps', "Composite action '%s' has no 'runs.steps' list" ],
			[ "runs:\n  using: node20\n", 'action.no_main', "JavaScript action '%s' has no 'runs.main'" ],
			[ "runs:\n  using: node20\n  main: [a]\n", 'action.no_main', "JavaScript action '%s' has no 'runs.main'" ],
			[ "inputs: [a]\n$composite", 'action.inputs_invalid', "The 'inputs' of '%s' must be a mapping" ],
			[ "inputs:\n  who: [a]\n$composite", 'action.input_invalid', "Input 'who' of '%s' must be a mapping" ],
			[ "outputs: x\n$composite", 'action.outputs_invalid', "The 'outputs' of '%s' must be a mapping" ],
			[ "outputs:\n  out: [a]\n$composite", 'action.output_invalid', "Output 'out' of '%s' must be a mapping" ],
		);
		for my $case (@cases) {
			my ($yaml, $code, $message) = @{$case};
			my $path = $action_file->($yaml);
			throws_code(sub { App::Actions::Action->load($path) }, $code, ($message =~ /%s/ ? sprintf($message, $path) : $message), "$code: " . shown($yaml));
		}
		throws_code(sub { App::Actions::Action->load($action_file->("runs:\n  using: composite\n  steps:\n    - 7\n")) },
			'step.not_mapping', undef, 'a composite step is checked as a workflow step is');
	};

	subtest 'load: the parts' => sub {
		my $action = App::Actions::Action->load($action_file->(<<'YAML'));
name: Greet
inputs:
  who:
    description: whom to greet
    required: TRUE
    default: 3
  loud:
    required: on
    default: true
  quiet: world
  bare:
  yes-word: { required: yes }
  one: { required: 1 }
outputs:
  said: { description: the greeting, value: hello }
  short: done
runs:
  using: Composite
  steps:
    - run: echo hi
      shell: bash
YAML
		is($action->name, 'Greet', 'name');
		is($action->description, '', 'a missing description is empty');
		is($action->using, 'composite', 'using, in lower case');
		is($action->kind, 'composite', 'kind');
		is_deeply($action->inputs, {
			who => { description => 'whom to greet', required => 1, default => '3' },
			loud => { description => undef, required => 0, default => 'true' },
			quiet => { default => 'world', required => 0 },
			bare => { default => '', required => 0 },
			'yes-word' => { description => undef, required => 1, default => '' },
			one => { description => undef, required => 1, default => '' },
		}, 'inputs: required only for true, yes and 1; defaults are strings; a plain value is a default');
		is_deeply($action->outputs, {
			said => { description => 'the greeting', value => 'hello' },
			short => { value => 'done' },
		}, 'outputs: a plain value is the value');
		is($action->runs->{using}, 'Composite', 'runs as written');
		is(scalar @{ $action->steps }, 1, 'one step');
		is($action->steps->[0]{run}, 'echo hi', 'which is the step');
		is($action->is_composite, 1, 'is_composite');
		is($action->is_javascript, 0, 'is not JavaScript');
		for my $method (qw(file dir name description using kind)) {
			returns_ok($action->$method, { type => 'string' }, "$method is a string");
		}
		returns_ok($action->$_, { type => 'hashref' }, "$_ is a hash reference") for qw(inputs outputs runs);
		returns_ok($action->steps, { type => 'arrayref' }, 'steps is an array reference');
		returns_ok($action->is_composite, { type => 'integer', memberof => [ 0, 1 ] }, 'is_composite is 0 or 1');

		my %kinds = (node16 => 'javascript', node20 => 'javascript', docker => 'docker', 'Future-Thing' => 'future-thing');
		for my $using (sort keys %kinds) {
			my $other = App::Actions::Action->load($action_file->("runs:\n  using: $using\n  main: index.js\n"));
			is($other->kind, $kinds{$using}, "runs.using $using is $kinds{$using}");
			is_deeply($other->steps, [], 'and has no steps');
			is($other->is_composite, 0, 'and is not composite');
			is($other->is_javascript, $kinds{$using} eq 'javascript' ? 1 : 0, 'is_javascript');
			is_deeply([ $other->inputs, $other->outputs ], [ {}, {} ], 'no inputs or outputs');
		}

		# A bare file name is in the current directory.
		my $cwd = Cwd::getcwd();
		my $dir = tempdir(CLEANUP => 1);
		write_file('action.yml', $composite, $dir);
		chdir $dir or die $!;
		my $here = eval { App::Actions::Action->load('action.yml') };
		chdir $cwd or die $!;
		is($here && $here->dir, '.', 'the directory of a bare file name is .');
		keeps_globals(sub { App::Actions::Action->load($action->file) }, 'load', io => 1);
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Workflow
# ---------------------------------------------------------------------------

subtest 'App::Actions::Workflow' => sub {
	my $steps = "    steps:\n      - run: echo hi\n";
	my $workflow_file = sub { write_file($_[1] // 'ci.yml', $_[0]) };
	my $load = sub { App::Actions::Workflow->load($workflow_file->(@_)) };

	subtest 'load: what is refused' => sub {
		throws_code(sub { App::Actions::Workflow->load($_->[0]) }, 'workflow.file_required', 'No workflow file given',
			'no file: ' . shown($_->[0])) for [ undef ], [ '' ];
		my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'ci.yml');
		throws_code(sub { App::Actions::Workflow->load($missing) }, 'workflow.file_missing',
			"Workflow file '$missing' does not exist", 'a file that does not exist');
		my $file = $workflow_file->("jobs: [\n");
		my $error = throws_code(sub { App::Actions::Workflow->load($file) }, 'workflow.parse_failed', undef, 'malformed YAML');
		like($error->message, qr/\AUnable to parse workflow '\Q$file\E': \S/, 'the message names the file and the reason');

		my @cases = (
			[ '', 'workflow.empty', "Workflow '%s' is empty" ],
			[ "- a\n", 'workflow.not_mapping', "Workflow '%s' must contain a YAML mapping" ],
			[ "name: x\n", 'workflow.no_jobs', "Workflow '%s' has no 'jobs' mapping" ],
			[ "jobs: [a]\n", 'workflow.no_jobs', "Workflow '%s' has no 'jobs' mapping" ],
			[ "jobs:\n  test: run\n", 'workflow.job_not_mapping', "Job 'test' must be a mapping" ],
			[ "jobs:\n  test:\n    runs-on: x\n", 'workflow.job_no_steps', "Job 'test' has no 'steps' list" ],
			[ "jobs:\n  test:\n    container: [a]\n$steps", 'workflow.container_invalid', "Job 'test' container must be a mapping or a string" ],
			[ "jobs:\n  test:\n    services: [db]\n$steps", 'workflow.services_invalid', "Job 'test' services must be a mapping" ],
			[ "env: [A]\njobs:\n  test:\n$steps", 'mapping.invalid', 'workflow env must be a mapping' ],
			[ "defaults: x\njobs:\n  test:\n$steps", 'mapping.invalid', 'workflow defaults must be a mapping' ],
			[ "jobs:\n  test:\n    env: x\n$steps", 'mapping.invalid', "env of job 'test' must be a mapping" ],
			[ "jobs:\n  test:\n    defaults: [x]\n$steps", 'mapping.invalid', "defaults of job 'test' must be a mapping" ],
			[ "jobs:\n  test:\n    strategy: x\n$steps", 'mapping.invalid', "strategy of job 'test' must be a mapping" ],
			[ "defaults:\n  run: bash\njobs:\n  test:\n$steps", 'workflow.defaults_run_invalid', 'workflow defaults run must be a mapping' ],
			[ "jobs:\n  test:\n    defaults: { run: [a] }\n$steps", 'workflow.defaults_run_invalid', "defaults of job 'test' run must be a mapping" ],
			[ "jobs:\n  test:\n    steps:\n      - 7\n", 'step.not_mapping', "A step in job 'test' is not a mapping" ],
		);
		for my $case (@cases) {
			my ($yaml, $code, $message) = @{$case};
			my $path = $workflow_file->($yaml);
			throws_code(sub { App::Actions::Workflow->load($path) }, $code, ($message =~ /%s/ ? sprintf($message, $path) : $message), "$code: " . shown($yaml));
		}
	};

	subtest 'load and the accessors' => sub {
		my @ids = map { "job$_" } reverse 'a' .. 'p';
		my $yaml = "name: CI\nenv: { A: 1 }\ndefaults: { run: { shell: bash } }\njobs:\n"
			. join('', map { "  $_:\n$steps" } @ids)
			. "  last:\n    needs: joba\n    container: perl:5.40\n$steps";
		my $workflow = $load->($yaml);
		returns_ok($workflow, { type => 'object', isa => 'App::Actions::Workflow' }, 'a workflow');
		like($workflow->file, qr/ci\.yml\z/, 'file');
		is($workflow->name, 'CI', 'name');
		is_deeply($workflow->env, { A => 1 }, 'env');
		is_deeply($workflow->defaults, { run => { shell => 'bash' } }, 'defaults');
		is_deeply([ map { $_->{id} } @{ $workflow->jobs } ], [ @ids, 'last' ], 'jobs, in the order of the file');
		is($workflow->raw->{name}, 'CI', 'raw is the document');
		returns_ok($workflow->$_, { type => 'hashref' }, "$_ is a hash reference") for qw(env defaults raw);
		returns_ok($workflow->jobs, { type => 'arrayref' }, 'jobs is an array reference');
		returns_ok($workflow->$_, { type => 'string' }, "$_ is a string") for qw(file name);

		my $last = $workflow->job_by_id('last');
		is_deeply($last->{needs}, [ 'joba' ], 'needs: as a list');
		is_deeply($last->{container}, { image => 'perl:5.40' }, 'container: as a mapping');
		is_deeply($last->{services}, {}, 'no services is an empty mapping');
		is($workflow->job_by_id('nope'), undef, 'job_by_id: undef for no such job');
		is_deeply([ $workflow->job_by_id('nope') ], [ undef ], 'also in list context');
		returns_ok($last, { type => 'hashref' }, 'a job is a hash reference');
		throws_code(sub { $workflow->job_by_id($_->[0]) }, 'actions.invalid_arguments', undef, 'job_by_id refuses ' . shown($_->[0]))
			for [ undef ], [ [ 'last' ] ];

		is($load->("jobs:\n  a:\n$steps", 'my-flow.yaml')->name, 'my-flow.yaml', 'without a name: the file name');
		keeps_globals(sub { App::Actions::Workflow->load($workflow->file) }, 'load', io => 1);
		keeps_globals(sub { $workflow->job_by_id('last') }, 'job_by_id');
	};

	subtest 'expand_jobs' => sub {
		my $workflow = $load->(<<'YAML');
jobs:
  plain:
    steps:
      - run: echo
  grid:
    name: Grid ${{ matrix.os }}/${{ matrix.perl }}
    strategy:
      matrix:
        perl: ['5.38', '5.40']
        os: [linux, bsd]
        exclude:
          - { os: bsd, perl: '5.38' }
        include:
          - { os: linux, extra: yes }
          - { os: solaris, perl: '5.36' }
    steps:
      - uses: shogo82148/actions-setup-perl@v1
        with:
          perl-version: ${{ matrix.perl }}
      - uses: perl-actions/setup-perl@v1
        with:
          perl-version: '5.10'
  only:
    strategy:
      matrix:
        include:
          - { a: 1 }
          - { a: 2 }
    steps:
      - run: echo
  single:
    strategy:
      matrix:
        tool: make
    steps:
      - run: echo
YAML
		my $instances = $workflow->expand_jobs;
		returns_ok($instances, { type => 'arrayref' }, 'an array reference');
		is_deeply([ map { $_->{display_name} } @{$instances} ], [
			'plain',
			'Grid linux/5.38', 'Grid linux/5.40', 'Grid bsd/5.40', 'Grid solaris/5.36',
			'only (a=1)', 'only (a=2)',
			'single (tool=make)',
		], 'one instance per combination, in job order, named; the matrix keys are taken in sorted order');
		my @grid = grep { $_->{base_id} eq 'grid' } @{$instances};
		is_deeply([ map { $_->{matrix} } @grid ], [
			{ os => 'linux', perl => '5.38', extra => 'yes' },
			{ os => 'linux', perl => '5.40', extra => 'yes' },
			{ os => 'bsd', perl => '5.40' },
			{ os => 'solaris', perl => '5.36' },
		], 'exclude removes, include extends what it fits and adds what it does not');
		is_deeply([ map { [ $_->{matrix_index}, $_->{matrix_total} ] } @grid ], [ [ 0, 4 ], [ 1, 4 ], [ 2, 4 ], [ 3, 4 ] ],
			'index and total');
		is_deeply([ map { $_->{setup_perl_version} } @grid ], [ '5.38', '5.40', '5.40', '5.36' ],
			'the first setup-perl step chooses the version');
		is_deeply([ @{ $instances->[0] }{qw(id base_id matrix matrix_index matrix_total setup_perl_version)} ],
			[ 'plain', 'plain', {}, 0, 1, undef ], 'no matrix is one instance');
		push @{ $grid[0]{steps} }, { run => 'extra' };
		is(scalar @{ $grid[1]{steps} }, 2, 'each instance is a copy of its own');
		is(scalar @{ $workflow->job_by_id('grid')->{steps} }, 2, 'and not the job');

		my @errors = (
			[ "matrix: [a]", 'workflow.matrix_not_mapping', 'strategy.matrix must be a mapping' ],
			[ "matrix: { perl: [] }", 'workflow.matrix_empty', "Matrix key 'perl' must be a list with at least one value" ],
			[ "matrix: { perl: [1], exclude: [x] }", 'workflow.exclude_invalid', 'Each matrix exclude entry must be a mapping' ],
			[ "matrix: { perl: [1], include: [x] }", 'workflow.include_invalid', 'Each matrix include entry must be a mapping' ],
		);
		for my $case (@errors) {
			my ($strategy, $code, $message) = @{$case};
			my $bad = $load->("jobs:\n  t:\n    strategy: { $strategy }\n$steps");
			throws_code(sub { $bad->expand_jobs }, $code, $message, "$code: $strategy");
		}
		keeps_globals(sub { $workflow->expand_jobs }, 'expand_jobs');
	};

	subtest 'runs_on_text and is_linux_runner' => sub {
		my $workflow = $load->("jobs:\n  t:\n$steps");
		is($workflow->runs_on_text('ubuntu-latest'), 'ubuntu-latest', 'a label');
		is($workflow->runs_on_text([ 'self-hosted', 'linux' ]), 'self-hosted linux', 'a list of labels');
		is($workflow->runs_on_text('${{ matrix.os }}', { os => 'ubuntu-22.04' }), 'ubuntu-22.04', 'with matrix values');
		is($workflow->runs_on_text(undef), '', 'none is empty');
		returns_ok($workflow->runs_on_text('x'), { type => 'string' }, 'a string');
		throws_code(sub { $workflow->runs_on_text({ group => 'big', labels => [ 'x' ] }) }, 'workflow.runs_on_invalid',
			q{'runs-on' must be a string or a list}, 'a runner group is refused');

		my %linux = ('ubuntu-latest' => 1, 'windows-latest' => 0, 'macos-14' => 0, 'self-hosted darwin' => 0,
			'self-hosted' => 1, 'mywindowsbox' => 1, 'Windows-2022' => 0, '' => 1);
		is_returned(App::Actions::Workflow->is_linux_runner($_), { type => 'integer', memberof => [ 0, 1 ] }, $linux{$_},
			'is_linux_runner: ' . shown($_)) for sort keys %linux;
		is(App::Actions::Workflow->is_linux_runner(undef), 1, 'no runner is Linux');
		keeps_globals(sub { $workflow->runs_on_text('${{ matrix.a }}', { a => 1 }) }, 'runs_on_text');
	};

	subtest 'images' => sub {
		my $class = 'App::Actions::Workflow';
		my %runner = ('ubuntu-22.04' => 'ubuntu:22.04', 'ubuntu-latest' => 'ubuntu:latest', 'Ubuntu-24.04-arm' => 'ubuntu:24.04',
			'self-hosted' => 'fallback:1', 'macos-14' => 'fallback:1');
		is($class->default_image_for_runner($_, 'fallback:1'), $runner{$_}, "default_image_for_runner: $_") for sort keys %runner;
		is($class->default_image_for_runner(undef, undef), undef, 'no fallback, nothing');

		my @perl = (
			[ [ '5.38' ], 'perl:5.38' ], [ [ 'v5.40' ], 'perl:5.40' ], [ [ undef ], 'perl:latest' ], [ [ '' ], 'perl:latest' ],
			[ [ 'dev' ], 'perl:latest' ], [ [ 'LATEST' ], 'perl:latest' ], [ [ '5.38', 'reg.io/perl' ], 'reg.io/perl:5.38' ],
			[ [ '5.38', 'img:%s-%s' ], 'img:5.38-5.38' ], [ [ '5.38', 'r%2Fp:%s' ], 'r%2Fp:5.38' ], [ [ '5.38', '' ], 'perl:5.38' ],
		);
		for my $case (@perl) {
			is_returned($class->perl_image_for_version(@{ $case->[0] }), { type => 'string', min => 1 }, $case->[1],
				'perl_image_for_version: ' . shown($case->[0]));
		}

		my $workflow = $load->("jobs:\n  t:\n$steps");
		is($workflow->container_image({ container => { image => 'perl:${{ matrix.v }}-${{ github.sha }}' }, matrix => { v => 5 } }),
			'perl:5-${{ github.sha }}', 'container_image: the container, with only the matrix resolved');
		is($workflow->container_image({ setup_perl_version => '5.36' }, 'ubuntu-latest', 'x', 'my/perl'), 'my/perl:5.36',
			'else the setup-perl version');
		is($workflow->container_image({}, 'ubuntu-22.04', 'x'), 'ubuntu:22.04', 'else the runner');
		is($workflow->container_image({ setup_perl_version => '' }, 'macos', 'fallback'), 'fallback', 'else the fallback');
		throws_code(sub { $workflow->container_image($_->[0]) }, 'actions.invalid_arguments', undef,
			'container_image refuses ' . shown($_->[0])) for [ undef ], [ [] ], [ 'job' ];
		keeps_globals(sub { $workflow->container_image({}, 'ubuntu-latest') }, 'container_image');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Cache
# ---------------------------------------------------------------------------

# A Docker that answers image_size and image_remove from tables, so a listing
# or a prune can be made to meet every case without a daemon.
{
	package Local::TableDocker;
	our @ISA = ('App::Actions::Docker');

	sub new {
		my ($class, %tables) = @_;
		my $self = App::Actions::Docker->new(bin => 'table-docker', quiet => 1);
		@{$self}{qw(sizes removals removed)} = ($tables{sizes} || {}, $tables{removals} || {}, []);
		return bless $self, $class;
	}
	sub image_size { return $_[0]{sizes}{ $_[1] } }
	sub image_remove {
		my ($self, $image) = @_;
		push @{ $self->{removed} }, $image;
		return $self->{removals}{$image} || 0;
	}
}

# A handle whose writes fail when it is closed, standing in for a disk that
# fills up while the record is written.
{
	package Local::FullTemp;
	our @ISA = ('IO::Handle');
	sub filename { return File::Spec->devnull }
}

subtest 'App::Actions::Cache' => sub {
	my $day = 24 * 60 * 60;
	my $now = 2_000_000_000;
	my $cache_at = sub {
		my ($images) = @_;
		my $file = File::Spec->catfile(tempdir(CLEANUP => 1), 'deep', 'cache.json');
		my $cache = App::Actions::Cache->new(file => $file);
		$cache->load->{images} = $images if $images;
		return $cache;
	};

	subtest 'base_directory and default_path' => sub {
		{
			local $^O = 'linux';
			local @ENV{qw(XDG_CACHE_HOME HOME)} = ('/xdg', '/home/me');
			is(App::Actions::Cache::base_directory(), '/xdg', 'XDG_CACHE_HOME');
			local $ENV{XDG_CACHE_HOME} = '';
			is(App::Actions::Cache::base_directory(), File::Spec->catdir('/home/me', '.cache'), 'then HOME/.cache');
			local $ENV{HOME} = '';
			is(App::Actions::Cache::base_directory(), File::Spec->catdir(File::Spec->curdir, '.cache'), 'then ./.cache');
		}
		{
			local $^O = 'MSWin32';
			local @ENV{qw(LOCALAPPDATA USERPROFILE)} = ('C:\\Local', 'C:\\Users\\me');
			is(App::Actions::Cache::base_directory(), 'C:\\Local', 'Windows: LOCALAPPDATA');
			local $ENV{LOCALAPPDATA} = '';
			is(App::Actions::Cache::base_directory(), File::Spec->catdir('C:\\Users\\me', 'AppData', 'Local'),
				'then USERPROFILE\\AppData\\Local');
			delete local $ENV{USERPROFILE};
			is(App::Actions::Cache::base_directory(), File::Spec->catdir(File::Spec->curdir, '.cache'), 'then .cache');
		}
		returns_ok(App::Actions::Cache::base_directory(), { type => 'string', min => 1 }, 'a directory');

		local $ENV{ACTION_RUN_CACHE_FILE} = '/somewhere/c.json';
		is(App::Actions::Cache::default_path(), '/somewhere/c.json', 'ACTION_RUN_CACHE_FILE');
		local $ENV{ACTION_RUN_CACHE_FILE} = '';
		is(App::Actions::Cache::default_path(), File::Spec->catfile(App::Actions::Cache::base_directory(), 'action-run', 'cache.json'),
			'an empty one is not set');
		is(App::Actions::Cache->new->file, App::Actions::Cache::default_path(), 'new: the default file');
		is(App::Actions::Cache->new(file => '')->file, App::Actions::Cache::default_path(), 'an empty file is the default');
		returns_ok(App::Actions::Cache->new(file => 'x.json'), { type => 'object', isa => 'App::Actions::Cache' }, 'new');
		keeps_globals(sub { App::Actions::Cache::default_path() }, 'default_path');
	};

	subtest 'load' => sub {
		my $missing = $cache_at->();
		is_deeply($missing->load, { version => 1, images => {} }, 'no file is no images');
		my $file = write_file('cache.json', 'not json');
		is_deeply(App::Actions::Cache->new(file => $file)->load->{images}, {}, 'a broken file is no images');
		write_file('cache.json', '[1]', File::Basename::dirname($file));
		is_deeply(App::Actions::Cache->new(file => $file)->load->{images}, {}, 'so is one of the wrong shape');
		write_file('cache.json', JSON::PP->new->encode({ images => {
			good => { pulls => 2, last_used => 5 },
			odd => { pulls => '1.5', last_used => [ 1 ] },
			bad => 'x',
		} }), File::Basename::dirname($file));
		my $cache = App::Actions::Cache->new(file => $file);
		is_deeply($cache->load->{images}, { good => { pulls => 2, last_used => 5 }, odd => { pulls => 0, last_used => undef } },
			'whole numbers are kept; anything else is dropped');
		returns_ok($cache->load, { type => 'hashref' }, 'a hash reference');
		write_file('cache.json', '{}', File::Basename::dirname($file));
		ok(exists $cache->load->{images}{good}, 'the file is read once');
		keeps_globals(sub { App::Actions::Cache->new(file => $file)->load }, 'load', io => 1);
	};

	subtest 'save, remember, entries and forget' => sub {
		my $cache = $cache_at->();
		is($cache->remember('a:1', undef, '', 'b:2', 'a:1'), 3, 'remember: the names recorded, without undef and empty');
		ok(-f $cache->file, 'and the record is written, with its directory');
		SKIP: {
			skip 'file modes are not Unix ones', 1 if $^O eq 'MSWin32';
			is((stat $cache->file)[2] & 07777, 0600, 'readable only by its owner');
		}
		my $again = App::Actions::Cache->new(file => $cache->file);
		my $entries = $again->entries;
		returns_ok($entries, { type => 'arrayref' }, 'entries: an array reference');
		is_deeply([ map { [ $_->{image}, $_->{pulls} ] } @{$entries} ], [ [ 'a:1', 2 ], [ 'b:2', 1 ] ], 'sorted, with the pulls');
		cmp_ok(abs($entries->[0]{last_used} - time), '<=', $config{time_limit}, 'last used now');
		is($again->forget('a:1', 'nope', undef), 1, 'forget: how many were in the record');
		is_deeply([ map { $_->{image} } @{ App::Actions::Cache->new(file => $cache->file)->entries } ], [ 'b:2' ], 'and saves');
		is($again->forget('b:2'), 1, 'the last one');
		ok(!-e $cache->file, 'and no images is no file');
		is($again->save, 1, 'save of nothing is 1');
		is($again->remember(), 0, 'nothing to remember');
		is($again->forget(), 0, 'or to forget');
		ok(!-e $cache->file, 'and nothing is written');
		my $kept = $cache_at->({ x => { pulls => 2, last_used => 1 } });
		returns_ok($kept->touch('x', 'mine', undef, ''), { type => 'integer', min => 0 }, 'touch: a count');
		is($kept->touch('x', 'mine'), 1, 'of the names the record holds');
		my $touched = App::Actions::Cache->new(file => $kept->file)->entries;
		is_deeply([ map { [ $_->{image}, $_->{pulls} ] } @{$touched} ], [ [ 'x', 2 ] ],
			'which keep their count, and no other name is added');
		cmp_ok(abs($touched->[0]{last_used} - time), '<=', $config{time_limit}, 'and saves their last use as now');
		my $untouched = $cache_at->();
		is($untouched->touch('mine'), 0, 'touching a name the record lacks is nothing');
		ok(!-e $untouched->file, 'and writes nothing');
		my $older = $cache_at->({ x => { pulls => 1 } });
		is_deeply($older->entries, [ { image => 'x', pulls => 1, last_used => undef } ], 'an unknown last use is undef');
		keeps_globals(sub { $cache_at->({ x => { pulls => 1 } })->save }, 'save', io => 1);
	};

	subtest 'save: what fails' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $cache = App::Actions::Cache->new(file => File::Spec->catfile($dir, 'cache.json'));
		$cache->load->{images} = { a => { pulls => 1, last_used => 1 } };
		SKIP: {
			skip 'a directory mode does not stop this user', 2 if $^O eq 'MSWin32' || $> == 0;
			chmod 0500, $dir;
			throws_ok { $cache->save } qr/\Acannot write a new cache file in '\Q$dir\E': \S/, 'a directory that cannot be written';
			my $below = File::Spec->catdir($dir, 'new');
			my $deeper = App::Actions::Cache->new(file => File::Spec->catfile($below, 'cache.json'));
			$deeper->load->{images} = { a => { pulls => 1 } };
			throws_ok { $deeper->save } qr/\Acannot write a new cache file in '\Q$below\E': [^\n]+ at \Q$0\E line \d+\.$/,
				'nor one that cannot be made, with only the caller named';
			chmod 0700, $dir;
		}
		settle('text Cache: cannot write a new cache file');

		my $taken = File::Spec->catdir($dir, 'taken');
		mkdir $taken;
		write_file('inside', 'x', $taken);
		my $blocked = App::Actions::Cache->new(file => $taken);
		$blocked->load->{images} = { a => { pulls => 1 } };
		throws_ok { $blocked->save } qr/\Acannot replace '\Q$taken\E': \S/, 'a record that is a directory';
		settle(q{text Cache: cannot replace 'FILE'});
		opendir my $listing, $dir or die $!;
		is_deeply([ grep { /\.tmp\z/ } readdir $listing ], [], 'and the temporary file is removed');

		SKIP: {
			skip 'no /dev/full', 1 unless -w '/dev/full';
			open my $full, '>', '/dev/full' or die $!;
			bless $full, 'Local::FullTemp';
			my $guard = Test::Mockingbird::mock_scoped('File::Temp::new' => sub { $full });
			throws_ok { $cache->save } qr/\Acannot write '\Q${\ File::Spec->devnull }\E': \S/, 'a disk that is full';
		}
		settle(q{text Cache: cannot write 'TEMP'});
	};

	subtest 'parse_duration, format_span, format_age and format_size' => sub {
		my %durations = ('30s' => 30, '15m' => 900, '12h' => 43_200, '7d' => 7 * $day, '2w' => 14 * $day, '3mo' => 90 * $day,
			'1y' => 365 * $day, ' 2 Days ' => 2 * $day, '1 HOUR' => 3600, '0s' => 0);
		is_returned(App::Actions::Cache::parse_duration($_), { type => 'integer', min => 0 }, $durations{$_}, "parse_duration: '$_'")
			for sort keys %durations;
		is(scalar App::Actions::Cache::parse_duration($_), undef, 'not understood: ' . shown($_))
			for undef, '', '30', 'd', '5 fortnights', '-1d', '1.5h', "1d\n2d";

		my %spans = (0 => '0 seconds', 1 => '1 second', 59 => '59 seconds', 60 => '1 minute', 90 * 60 => '1 hour',
			2 * 3600 => '2 hours', $day => '1 day', 40 * $day => '1 month', 60 * $day => '2 months', 365 * $day => '1 year',
			800 * $day => '2 years', -5 => '0 seconds');
		is_returned(App::Actions::Cache::format_span($_), { type => 'string', min => 1 }, $spans{$_}, "format_span: $_")
			for sort { $a <=> $b } keys %spans;
		is(App::Actions::Cache::format_span($_), '0 seconds', 'invalid is 0: ' . shown($_)) for undef, 'x', '1.5';

		is(App::Actions::Cache::format_age(59), 'just now', 'format_age: under a minute is just now');
		is(App::Actions::Cache::format_age(3 * 3600), '3 hours ago', 'then ago');
		is(App::Actions::Cache::format_age(-100), 'just now', 'the future is now');
		{
			local $ENV{ACTION_RUN_LANG} = 'fr';
			unlike(App::Actions::Cache::format_age(3 * 3600), qr/ago/, 'another language says it its own way');
		}

		my %sizes = (0 => '0 B', 500 => '500 B', 1023 => '1023 B', 1536 => '1.5 KB', 5 * 1024**2 => '5.0 MB',
			2.3 * 1024**3 => '2.3 GB', 3 * 1024**4 => '3.0 TB', 2048 * 1024**4 => '2048.0 TB', -1 => '0 B');
		is_returned(App::Actions::Cache::format_size($_), { type => 'string', min => 3 }, $sizes{$_}, "format_size: $_")
			for sort { $a <=> $b } keys %sizes;
		is(App::Actions::Cache::format_size(undef), '0 B', 'undef is 0 B');
		keeps_globals(sub { App::Actions::Cache::format_age(3600) }, 'format_age');
	};

	subtest 'report' => sub {
		my $images = {
			'alpine:3.20' => { pulls => 3, last_used => $now - 120 },
			'perl:5.38' => { pulls => 1, last_used => $now - 3 * $day },
			'old:1' => { pulls => 1, last_used => undef },
		};
		my $docker = Local::TableDocker->new(sizes => { 'alpine:3.20' => 2048, 'old:1' => 1024 });
		my $text = $cache_at->($images)->report(docker => $docker, now => $now);
		returns_ok($text, { type => 'string', min => 1 }, 'the text');
		like($text, qr/\ACache file: .+cache\.json\n\n  IMAGE\s+SIZE  LAST USED\s+AGE\n/, 'the file, then the headings');
		like($text, qr/^  alpine:3\.20  \s+2\.0 KB  \d{4}-\d\d-\d\d \d\d:\d\d  2 minutes ago$/m, 'a row: size, last use, age');
		like($text, qr/^  old:1 \s+1\.0 KB  -\s+unknown$/m, 'an unknown last use');
		like($text, qr/^  perl:5\.38 \s+missing  \S+ \S+  3 days ago$/m, 'an image Docker no longer has');
		like($text, qr/^3 images, 3\.0 KB on disk\.\n1 image is no longer on the daemon\.\nRemove them with "action-run cache --prune"\.\n\z/m,
			'the total, what is missing, and how to prune');

		$text = $cache_at->({ 'a:1' => { pulls => 1, last_used => $now } })->report(now => $now);
		like($text, qr/^  a:1\s+unknown  .*just now$/m, 'without Docker the size is unknown');
		like($text, qr/^1 image\.\nThe Docker daemon is not reachable, so the sizes are unknown\.\n\z/m, 'and it says why');
		unlike($text, qr/prune/, 'with no prune hint');

		$text = $cache_at->($images)->report(docker => $docker, now => $now, older_than => $day);
		like($text, qr/^Only images older than 1 day\.$/m, 'older_than says so');
		unlike($text, qr/alpine|old:1/, 'and leaves out the newer and the unknown');
		like($text, qr/^1 image\.\n1 image is no longer on the daemon\.\n\z/m, 'one image, and none of it sized');

		like($cache_at->($images)->report(now => $now, older_than => 30 * $day), qr/\n\QNo cached images are older than 1 month.\E\n\z/,
			'none old enough');
		like($cache_at->()->report(now => $now), qr/\ACache file: .*\nNo images have been cached yet\.\n\z/, 'none at all');
		like($cache_at->()->report(older_than => $day), qr/\nNo images have been cached yet\.\n\z/, 'none at all, with older_than');
		my $cache = $cache_at->($images);
		keeps_globals(sub { $cache->report(now => $now) }, 'report');
	};

	subtest 'prune' => sub {
		my $images = {
			'keep:1' => { pulls => 1, last_used => $now },
			'gone:1' => { pulls => 1, last_used => $now - 10 * $day },
			'busy:1' => { pulls => 1, last_used => $now - 10 * $day },
			'big:1' => { pulls => 1, last_used => $now - 10 * $day },
			'big:2' => { pulls => 1, last_used => $now - 10 * $day },
		};
		my $docker = Local::TableDocker->new(
			sizes => { 'busy:1' => 1, 'big:1' => 1024**3, 'big:2' => 1024**3, 'keep:1' => 5 },
			removals => { 'busy:1' => 1 },
		);
		my $cache = $cache_at->($images);
		my @result = $cache->prune(docker => $docker, older_than => $day, now => $now);
		returns_ok(\@result, { type => 'arrayref', min => 3, max => 3 }, 'three values');
		my ($text, $status, $data) = @result;
		is($status, 1, 'an image that could not be removed is status 1');
		is_deeply($data, { removed => 2, freed => 2 * 1024**3, forgotten => 1, failed => [ 'busy:1' ] }, 'what was done');
		is($text, "Cache file: ${\ $cache->file }\nRemoved 2 images, 2.0 GB freed.\nForgot 1 image no longer on the daemon.\n"
			. "Could not remove 1 image:\n  busy:1\n", 'and the text says so');
		is_deeply([ sort @{ $docker->{removed} } ], [ 'big:1', 'big:2', 'busy:1' ], 'only the old images were removed');
		is_deeply([ map { $_->{image} } @{ App::Actions::Cache->new(file => $cache->file)->entries } ], [ 'busy:1', 'keep:1' ],
			'the record keeps what is still there');

		$cache = $cache_at->({ 'a:1' => { pulls => 1, last_used => 1 } });
		($text, $status, $data) = $cache->prune(docker => Local::TableDocker->new(sizes => { 'a:1' => 10 }), now => $now);
		is_deeply([ $text, $status ], [ "Cache file: ${\ $cache->file }\nRemoved 1 image, 10 B freed.\n", 0 ], 'every image, status 0');
		ok(!-e $cache->file, 'and an empty record is no file');
		($text, $status, $data) = $cache->prune(docker => $docker);
		is_deeply([ $text, $status, $data ], [ "Cache file: ${\ $cache->file }\nNo images have been cached yet.\n", 0,
			{ removed => 0, freed => 0, forgotten => 0, failed => [] } ], 'nothing to prune');
		($text) = $cache_at->($images)->prune(docker => $docker, older_than => 100 * $day, now => $now);
		like($text, qr/\nNo cached images are older than 3 months\.\n\z/, 'nothing old enough');

		throws_ok { $cache->prune } qr/\Apruning the image cache needs a Docker command at /, 'Docker is needed';
		settle('text Cache: pruning the image cache needs a Docker command');
		keeps_globals(sub { $cache_at->()->prune(docker => $docker) }, 'prune');
	};

	subtest 'document, json_schema and json_schema_version' => sub {
		my $images = {
			'alpine:3.20' => { pulls => 3, last_used => $now - 120 },
			'perl:5.38' => { pulls => 1, last_used => $now + 50 },
			'old:1' => { pulls => 1, last_used => undef },
		};
		my $docker = Local::TableDocker->new(sizes => { 'alpine:3.20' => 2048, 'old:1' => 1024 });
		my $document = $cache_at->($images)->document(docker => $docker, reachable => 1, now => $now);
		returns_ok($document, { type => 'hashref' }, 'a hash reference');
		is($document->{schema_version}, App::Actions::Cache->json_schema_version, 'the schema version');
		is_deeply([ $document->{generated_at}, $document->{docker}{bin}, $document->{prune} ], [ $now, 'table-docker', undef ],
			"generated_at, Docker's own program, and no prune");
		ok($document->{docker}{reachable}, 'reachable');
		is_deeply([ map { [ @{$_}{qw(image age size)}, $_->{present} ? 1 : 0 ] } @{ $document->{images} } ],
			[ [ 'alpine:3.20', 120, 2048, 1 ], [ 'old:1', undef, 1024, 1 ], [ 'perl:5.38', 0, undef, 0 ] ],
			'each image: an unknown last use has no age, a future one is age 0');
		is_deeply($document->{totals}, { images => 3, size => 3072, present => 2, missing => 1 }, 'the totals');
		ok(!App::Actions::Schema::validate($document, App::Actions::Cache->json_schema), 'it matches its schema');

		$document = $cache_at->($images)->document(docker => $docker, docker_bin => 'podman', now => $now, older_than => 60);
		is($document->{docker}{bin}, 'podman', 'docker_bin');
		ok(!$document->{docker}{reachable}, 'not reachable');
		is_deeply([ map { [ $_->{size}, $_->{present} ] } @{ $document->{images} } ], [ [ undef, undef ] ],
			'then no sizes, and older_than selects');
		is_deeply($document->{totals}, { images => 1, size => undef, present => undef, missing => undef }, 'nor totals');
		is($cache_at->()->document->{docker}{bin}, 'docker', 'the default program');
		my $prune = { removed => 1, freed => 2, forgotten => 0, failed => [] };
		is_deeply($cache_at->()->document(prune => $prune)->{prune}, $prune, 'a prune is included');

		my $error = caught { $cache_at->()->document(prune => { removed => 'all' }) };
		isa_ok($error, 'App::Actions::Schema::Invalid', 'a document that does not match its schema');
		like("$error", qr/the action-run cache --json document does not match App::Actions::Cache->json_schema/, 'says so');
		settle('text Cache: the document does not match its schema');

		my $schema = App::Actions::Cache->json_schema;
		returns_ok($schema, { type => 'hashref' }, 'json_schema');
		$schema->{changed} = 1;
		ok(!exists App::Actions::Cache->json_schema->{changed}, 'a new one each time');
		returns_ok(App::Actions::Cache->json_schema_version, { type => 'integer', min => 1 }, 'json_schema_version');
		is($schema->{version}, App::Actions::Cache->json_schema_version, 'which is the schema version');
		keeps_globals(sub { $cache_at->()->document }, 'document');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Logs
# ---------------------------------------------------------------------------

subtest 'App::Actions::Logs' => sub {
	my $day = 24 * 60 * 60;
	my $now = 2_000_000_000;
	my ($old_run, $new_run) = ('20261020-101010-abc123', '20261021-121355-6ad8e4c30f83');

	# A log directory with an old run, a new run, and things this module
	# must never list or remove: a stray file, a folder named another way,
	# a symbolic link and a run with no logs.
	my $tree = sub {
		my $root = tempdir(CLEANUP => 1);
		for my $run ($old_run, $new_run, '20261022-000000-ffff') {
			mkdir File::Spec->catdir($root, $run) or die $!;
		}
		my $old = File::Spec->catdir($root, $old_run);
		my $new = File::Spec->catdir($root, $new_run);
		write_file('job-1-test.log', 'x' x 100, $old);
		write_file('job-2.log', 'y' x 50, $old);
		write_file('job-1-lint_n_one.log', 'z' x 1500, $new);
		write_file('notes.txt', 'keep me', $new);
		write_file('README', 'keep me', $root);
		mkdir File::Spec->catdir($root, 'other') or die $!;
		write_file('job-1.log', 'other', File::Spec->catdir($root, 'other'));
		utime $now - 10 * $day, $now - 10 * $day, map { File::Spec->catfile($old, $_) } 'job-1-test.log', 'job-2.log';
		utime $now - 60, $now - 60, File::Spec->catfile($new, 'job-1-lint_n_one.log');
		if ($^O ne 'MSWin32') {
			symlink $old, File::Spec->catdir($root, '20261023-000000-aaaa');
			symlink File::Spec->catfile($old, 'job-2.log'), File::Spec->catfile($new, 'job-9.log');
		}
		return App::Actions::Logs->new(directory => $root);
	};

	subtest 'default_directory, new and directory' => sub {
		local $ENV{ACTION_RUN_LOG_DIR} = '/var/logs/ar';
		is(App::Actions::Logs::default_directory(), '/var/logs/ar', 'ACTION_RUN_LOG_DIR');
		local $ENV{ACTION_RUN_LOG_DIR} = '';
		is(App::Actions::Logs::default_directory(),
			File::Spec->catdir(App::Actions::Cache::base_directory(), 'action-run', 'logs'), 'else in the cache directory');
		returns_ok(App::Actions::Logs::default_directory(), { type => 'string', min => 1 }, 'a path');
		is(App::Actions::Logs->new->directory, App::Actions::Logs::default_directory(), 'new: the default directory');
		is(App::Actions::Logs->new(directory => '')->directory, App::Actions::Logs::default_directory(), 'an empty one is the default');
		returns_ok(App::Actions::Logs->new(directory => '/x'), { type => 'object', isa => 'App::Actions::Logs' }, 'an object');
		is(App::Actions::Logs->new(directory => '/x')->directory, '/x', 'directory');
	};

	subtest 'entries' => sub {
		my $logs = $tree->();
		my $runs = $logs->entries;
		returns_ok($runs, { type => 'arrayref' }, 'an array reference');
		is_deeply([ map { $_->{name} } @{$runs} ], [ $new_run, $old_run ], 'runs with logs, newest first; nothing else');
		is_deeply([ map { $_->{name} } @{ $runs->[1]{logs} } ], [ 'job-1-test.log', 'job-2.log' ], 'each run its logs, by name');
		is_deeply([ map { $_->{name} } @{ $runs->[0]{logs} } ], [ 'job-1-lint_n_one.log' ], 'not a link, and not a note');
		my $log = $runs->[1]{logs}[0];
		is_deeply([ @{$log}{qw(size mtime)} ], [ 100, $now - 10 * $day ], 'the size and the time');
		is($log->{path}, File::Spec->catfile($runs->[1]{directory}, 'job-1-test.log'), 'and the path');
		is_deeply(App::Actions::Logs->new(directory => File::Spec->catdir(tempdir(CLEANUP => 1), 'none'))->entries, [],
			'no directory, no runs');
		SKIP: {
			skip 'a directory mode does not stop this user', 1 if $^O eq 'MSWin32' || $> == 0;
			my $root = tempdir(CLEANUP => 1);
			chmod 0000, $root;
			throws_ok { App::Actions::Logs->new(directory => $root)->entries }
				qr/\Acannot read the log directory '\Q$root\E': \S/, 'a directory that cannot be read';
			chmod 0700, $root;
		}
		settle('text Logs: cannot read the log directory');
		keeps_globals(sub { $logs->entries }, 'entries', io => 1);
	};

	subtest 'format_age' => sub {
		is(App::Actions::Logs::format_age(-5), 'just now', 'a clock ahead is just now');
		is(App::Actions::Logs::format_age(90 * 60), '1 hour ago', 'the largest whole unit');
		is(App::Actions::Logs::format_age(23 * 3600), '23 hours ago', '23 hours is still hours');
		is(App::Actions::Logs::format_age(400 * $day), '1 year ago', 'a year');
		returns_ok(App::Actions::Logs::format_age(1), { type => 'string', min => 1 }, 'words');
	};

	subtest 'report' => sub {
		my $logs = $tree->();
		my $text = $logs->report(now => $now);
		returns_ok($text, { type => 'string', min => 1 }, 'the text');
		my $root = $logs->directory;
		like($text, qr/\ALogs directory: \Q$root\E\n\n  RUN\s+LOG\s+SIZE  AGE\n/, 'the directory, then the headings');
		like($text, qr/^  \Q$new_run\E  job-1-lint_n_one\.log\s+1\.5 KB  1 minute ago$/m, 'a row');
		like($text, qr/^  \Q$old_run\E\s+job-2\.log\s+50 B  10 days ago$/m, 'another');
		like($text, qr/\n3 logs, 1.6 KB on disk\.\nRemove them with "action-run logs --prune"\.\n\z/, 'the total and how to prune');
		$text = $logs->report(now => $now, older_than => $day);
		like($text, qr/^Only job logs older than 1 day\.$/m, 'older_than says so');
		unlike($text, qr/lint/, 'and leaves out what is newer');
		like($text, qr/\n2 logs, 150 B on disk\./, 'and counts only what it lists');
		like($logs->report(now => $now, older_than => 30 * $day), qr/\nNo job logs are older than 1 month\.\n\z/, 'none old enough');
		like(App::Actions::Logs->new(directory => tempdir(CLEANUP => 1))->report, qr/\nNo job logs have been kept yet\.\n\z/,
			'none at all');
		like(App::Actions::Logs->new(directory => tempdir(CLEANUP => 1))->report(older_than => 5), qr/\nNo job logs have been kept yet\.\n\z/,
			'none at all, with older_than');
		my $single = App::Actions::Logs->new(directory => tempdir(CLEANUP => 1));
		mkdir File::Spec->catdir($single->directory, $new_run);
		write_file('job-1.log', 'x', File::Spec->catdir($single->directory, $new_run));
		like($single->report, qr/\n1 log, 1 B on disk\.\n/, 'one log');
		keeps_globals(sub { $logs->report(now => $now) }, 'report', io => 1);
	};

	subtest 'prune' => sub {
		my $logs = $tree->();
		my @result = $logs->prune(now => $now, older_than => $day);
		returns_ok(\@result, { type => 'arrayref', min => 3, max => 3 }, 'three values');
		my ($text, $status, $data) = @result;
		is($status, 0, 'status 0');
		is_deeply($data, { removed => 2, freed => 150, failed => [] }, 'what was removed');
		is($text, "Logs directory: ${\ $logs->directory }\nRemoved 2 logs, 150 B freed.\n", 'and the text');
		ok(!-e File::Spec->catdir($logs->directory, $old_run), 'an emptied run folder goes');
		ok(-e File::Spec->catfile($logs->directory, $new_run, 'job-1-lint_n_one.log'), 'the newer log stays');

		($text, $status, $data) = $logs->prune(now => $now);
		is_deeply([ $status, $data->{removed} ], [ 0, 1 ], 'without older_than every log goes');
		ok(-e File::Spec->catfile($logs->directory, $new_run, 'notes.txt'), 'but not a note beside it');
		ok(-e File::Spec->catfile($logs->directory, 'README'), 'nor a stray file');
		ok(-e File::Spec->catfile($logs->directory, 'other', 'job-1.log'), 'nor a folder named another way');

		($text, $status, $data) = $logs->prune;
		is_deeply([ $text, $status, $data ], [ "Logs directory: ${\ $logs->directory }\nNo job logs have been kept yet.\n", 0,
			{ removed => 0, freed => 0, failed => [] } ], 'nothing to prune');
		my $later = $tree->();
		($text) = $later->prune(now => $now, older_than => 100 * $day);
		like($text, qr/\nNo job logs are older than 3 months\.\n\z/, 'nothing old enough');

		SKIP: {
			skip 'a directory mode does not stop this user', 4 if $^O eq 'MSWin32' || $> == 0;
			my $stuck = $tree->();
			my $old = File::Spec->catdir($stuck->directory, $old_run);
			chmod 0500, $old;
			($text, $status, $data) = $stuck->prune(now => $now);
			chmod 0700, $old;
			is($status, 1, 'a log that cannot be removed is status 1');
			is_deeply([ $data->{removed}, map { $_->{run} } @{ $data->{failed} } ], [ 1, $old_run ], 'and the others still go');
			like($data->{failed}[0]{error}, qr/\Acannot remove '\Q$old\E.+\.log': \S/, 'with the reason');
			like($text, qr/\nRemoved 1 log, 1\.5 KB freed\.\nCould not remove 1 run:\n  \Q$old_run\E: cannot remove '/,
				'and the text says so');
		}
		settle(q{text Logs: cannot remove 'PATH'});
		keeps_globals(sub { $tree->()->prune(now => $now) }, 'prune', io => 1);
	};

	subtest 'document, json_schema and json_schema_version' => sub {
		my $logs = $tree->();
		my $document = $logs->document(now => $now);
		returns_ok($document, { type => 'hashref' }, 'a hash reference');
		is($document->{schema_version}, App::Actions::Logs->json_schema_version, 'the schema version');
		is_deeply([ @{$document}{qw(generated_at logs_directory prune)} ], [ $now, $logs->directory, undef ], 'the header');
		is_deeply([ map { [ @{$_}{qw(run name size age)} ] } @{ $document->{logs} } ], [
			[ $new_run, 'job-1-lint_n_one.log', 1500, 60 ],
			[ $old_run, 'job-1-test.log', 100, 10 * $day ],
			[ $old_run, 'job-2.log', 50, 10 * $day ],
		], 'the logs, newest run first');
		is_deeply($document->{totals}, { runs => 2, logs => 3, size => 1650 }, 'the totals');
		is_deeply($logs->document(now => $now, older_than => $day)->{totals}, { runs => 1, logs => 2, size => 150 },
			'older_than counts only the selected');
		is($logs->document(now => $now - 3600)->{logs}[0]{age}, 0, 'a log from the future is age 0');
		my $prune = { removed => 0, freed => 0, failed => [ { run => 'r', error => 'e' } ] };
		is_deeply($logs->document(prune => $prune)->{prune}, $prune, 'a prune is included');
		ok(!App::Actions::Schema::validate($document, App::Actions::Logs->json_schema), 'it matches its schema');

		my $error = caught { $logs->document(prune => { removed => -1 }) };
		isa_ok($error, 'App::Actions::Schema::Invalid', 'a document that does not match its schema');
		like("$error", qr/the action-run logs --json document does not match App::Actions::Logs->json_schema/, 'says so');
		settle('text Logs: the document does not match its schema');

		my $schema = App::Actions::Logs->json_schema;
		returns_ok($schema, { type => 'hashref' }, 'json_schema');
		$schema->{changed} = 1;
		ok(!exists App::Actions::Logs->json_schema->{changed}, 'a new one each time');
		returns_ok(App::Actions::Logs->json_schema_version, { type => 'integer', min => 1 }, 'json_schema_version');
		is($schema->{version}, App::Actions::Logs->json_schema_version, 'which is the schema version');
		keeps_globals(sub { $logs->document(now => $now) }, 'document', io => 1);
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Check
# ---------------------------------------------------------------------------

subtest 'App::Actions::Check' => sub {
	# Every check runs against the scripted Docker; a working one answers the
	# versions and the probe, and each problem is one rule placed before it.
	my @working = (
		[ 'version --format \{\{\.Client\.Version\}\}', 0, "29.0.1\\n" ],
		[ 'version --format \{\{\.Server\.Version\}\}', 0, "29.0.2\\n" ],
		[ 'info --format \{\{\.OSType\}\}', 0, "linux\\n" ],
		[ '^run --rm --network none', 'PROBE' ],
	);
	my $check = sub {
		my ($rules, %options) = @_;
		my $text = '';
		open my $output, '>', \$text or die $!;
		my $object = App::Actions::Check->new(docker_bin => $fake_docker, output => $output, %options);
		my $status;
		my $log = with_docker([ @{$rules}, @working ], sub { $status = $object->run });
		close $output;
		show_state(check => $text);
		return { status => $status, text => $text, object => $object, log => $log };
	};

	subtest 'new, image, host_info, json_schema and json_schema_version' => sub {
		my $object = App::Actions::Check->new;
		returns_ok($object, { type => 'object', isa => 'App::Actions::Check' }, 'new');
		is($object->image, 'alpine:3.20', 'the default image');
		is(App::Actions::Check->new(image => 'busybox')->image, 'busybox', 'or the one given');
		returns_ok($object->image, { type => 'string', min => 1 }, 'image is a name');

		my $host = App::Actions::Check->host_info;
		returns_ok($host, { type => 'hashref' }, 'host_info');
		is_deeply([ sort keys %{$host} ], [ qw(archname name os perl) ], 'with its four keys');
		is($host->{os}, $^O, "this computer's system");
		is($host->{perl}, sprintf('%vd', $^V), 'and Perl');
		my %names = (linux => 'Linux', darwin => 'macOS', MSWin32 => 'Windows', cygwin => 'Cygwin', msys => 'MSYS', plan9 => 'plan9');
		is(App::Actions::Check->host_info($_)->{name}, $names{$_}, "the name of $_") for sort keys %names;
		is(App::Actions::Check->new(os => 'darwin')->host_info->{os}, 'darwin', "an object's os");
		is(App::Actions::Check->new(os => 'darwin')->host_info('MSWin32')->{os}, 'MSWin32', 'an argument wins');

		my $schema = App::Actions::Check->json_schema;
		returns_ok($schema, { type => 'hashref' }, 'json_schema');
		$schema->{changed} = 1;
		ok(!exists App::Actions::Check->json_schema->{changed}, 'a new one each time');
		returns_ok(App::Actions::Check->json_schema_version, { type => 'integer', min => 1 }, 'json_schema_version');
		is($schema->{version}, App::Actions::Check->json_schema_version, 'which is the schema version');
		keeps_globals(sub { App::Actions::Check->host_info }, 'host_info');
	};

	subtest 'run: ready' => sub {
		my $project = tempdir(CLEANUP => 1);
		write_file($_, 'x', $project) for qw(a b .hidden);
		my $result = $check->([], directory => $project);
		is_returned($result->{status}, { type => 'integer', memberof => [ 0, 2 ] }, 0, 'ready is 0');
		settle('status Check: 0 ready');
		like($result->{text}, qr/\Aaction-run check\n  host      \S/, 'the title, then the host');
		like($result->{text}, qr/^  client    29\.0\.1\n  daemon    29\.0\.2, linux containers\n  image     alpine:3\.20$/m,
			'the versions and the image');
		like($result->{text}, qr/^  mount     .+ -> \/action-run-check: OK\n  mount     \Q$project\E -> \/check-project: OK \(3 entries\)$/m,
			'both folders are seen');
		like($result->{text}, qr/\n  schema    version \d+ \(action-run schema check\)\nResult: ready\n\z/, 'and the result');
		my ($probe) = grep { $_->[0] eq 'run' } @{ $result->{log}{argv} };
		is_deeply([ @{$probe}[0 .. 3] ], [ qw(run --rm --network none) ], 'the probe has no network');
		ok((grep { /:\/check-project:ro\z/ } @{$probe}), 'and sees the project read-only');

		my $summary = $result->{object}->summary(0);
		returns_ok($summary, { type => 'hashref' }, 'summary');
		is_deeply([ @{$summary}{qw(ready problems image)} ], [ 1, 0, 'alpine:3.20' ], 'ready, no problems, the image');
		is_deeply($summary->{docker}, { bin => $fake_docker, client => '29.0.1', daemon => '29.0.2', containers => 'linux' }, 'Docker');
		is_deeply([ map { [ $_->{container}, $_->{ok} ? 1 : 0, $_->{entries} ] } @{ $summary->{mounts} } ],
			[ [ '/action-run-check', 1, undef ], [ '/check-project', 1, 3 ] ], 'the mounts');

		my $one = tempdir(CLEANUP => 1);
		write_file('only', 'x', $one);
		like($check->([], directory => $one)->{text}, qr/OK \(1 entry\)$/m, 'one entry');

		$result = $check->([], title => '', summary => 0, schema_line => 0, platform => 'linux/arm64', image => 'busybox');
		like($result->{text}, qr/\A  host /, 'an empty title is left out');
		unlike($result->{text}, qr/Result:|schema    /, 'so are the result and the schema line, when asked');
		($probe) = grep { $_->[0] eq 'run' } @{ $result->{log}{argv} };
		is_deeply([ @{$probe}[4, 5] ], [ '--platform', 'linux/arm64' ], 'the platform is given to the probe');
		is($check->([], quiet => 1)->{text}, '', 'quiet prints nothing when ready');
		keeps_globals(sub { $check->([]) }, 'run', io => 1);
	};

	subtest 'run: each problem' => sub {
		my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'missing');
		my $count_dir = tempdir(CLEANUP => 1);
		my @problems = (
			[ [ [ 'Client', 1 ] ], {}, qr/the Docker command '\Q$fake_docker\E' could not be run/, qr/install Docker, or pass --docker/ ],
			[ [ [ 'Client', 0, "\\n" ] ], { os => 'MSWin32' }, qr/the Docker command .* could not be run/, qr/docker\.exe/ ],
			[ [ [ 'Server', 1 ] ], {}, qr/the daemon is not reachable; is Docker running and can this user access it\?/,
				qr/systemctl start docker.*\n.*DOCKER_HOST/ ],
			[ [ [ 'Server', 0, '' ] ], { os => 'cygwin' }, qr/the daemon is not reachable/, qr/wait until it is running.*\n.*wsl --shutdown/ ],
			[ [ [ 'OSType', 0, "windows\\n" ] ], {}, qr/the daemon runs 'windows' containers; action-run needs Linux containers/,
				qr/DOCKER_HOST at a daemon that runs Linux/ ],
			[ [ [ 'OSType', 1 ] ], { os => 'msys' }, qr/the daemon runs 'unknown' containers/, qr/Switch to Linux containers/ ],
			[ [], { directory => $missing }, qr/'\Q$missing\E' is not a directory/, qr/pass a directory that exists/ ],
			[ [ [ '^run', 3 ] ], {}, qr/the probe container failed \(exit 3\)/, qr/docker pull alpine:3\.20.*\n.*linux\/amd64/ ],
			[ [ [ '^run', 0, "something else\\n" ] ], {}, qr/the container could not read the mounted temporary directory/,
				qr/a bind mount needs a local daemon/ ],
			[ [ [ '^run', 0, "\\n" ] ], { os => 'MSWin32' }, qr/the container could not read/, qr/File sharing/ ],
			[ [ [ '^run', 'PROBE', 'many' ] ], { directory => $count_dir }, qr/could not count the entries in '\Q$count_dir\E'/, undef ],
			[ [ [ '^run', 'PROBE', '7' ] ], { directory => $count_dir }, qr/'\Q$count_dir\E' -> \/check-project sees 7 entries, the host has 0/,
				qr/choose a directory the daemon can see/ ],
			[ [ [ '^run', 'PROBE', '7' ] ], { directory => $count_dir, os => 'MSWin32' }, qr/.* sees 7 entries/, qr/File sharing/ ],
		);
		for my $case (@problems) {
			my ($rules, $options, $problem, $remedy) = @{$case};
			my $result = $check->($rules, %{$options});
			is($result->{status}, 2, "status 2: $problem");
			like($result->{text}, qr/^  problem   $problem/m, 'the problem is named');
			like($result->{text}, qr/^  problem   .*\n  remedy    .*$remedy/m, 'with its remedy') if defined $remedy;
			unlike($result->{text}, qr/^  remedy /m, 'with no remedy') unless defined $remedy;
			like($result->{text}, qr/\nResult: not ready \(1 problem\)\n\z/, 'and the result');
			is($result->{object}->summary(2)->{issues}[0]{problem} =~ $problem ? 1 : 0, 1, 'the summary has the issue');
		}
		settle('status Check: 2 not ready');
		settle("text Check: $_") for 'could not be run', 'not reachable', 'windows containers', 'is not a directory',
			'probe failed', 'could not read the mounted temporary directory', 'could not count the entries', 'sees N entries';

		SKIP: {
			skip 'a directory mode does not stop this user', 2 if $^O eq 'MSWin32' || $> == 0;
			my $locked = tempdir(CLEANUP => 1);
			chmod 0500, $locked;
			my $guard = Test::Mockingbird::mock_scoped('File::Temp::newdir' => sub { $locked });
			my $result = $check->([]);
			chmod 0700, $locked;
			is($result->{status}, 2, 'a temporary folder that cannot be written');
			like($result->{text}, qr/^  problem   cannot write '\Q$locked\E.+marker': \S.*\n  remedy    check the permissions/m,
				'is a problem');
		}
		settle(q{text Check: cannot write 'FILE'});

		my $two = $check->([ [ 'OSType', 0, "windows\\n" ] ], quiet => 1);
		like($two->{text}, qr/problem/, 'quiet still prints a problem');
		my $text = '';
		open my $output, '>', \$text or die $!;
		my $object = App::Actions::Check->new(docker_bin => $missing, output => $output, directory => $missing);
		$object->run;
		like($text, qr/could not be run/, 'a Docker that does not exist');
	};

	subtest 'run: json' => sub {
		my $result = $check->([], json => 1);
		is($result->{status}, 0, 'the same status');
		my $document = JSON::PP->new->decode($result->{text});
		ok(!App::Actions::Schema::validate($document, App::Actions::Check->json_schema), 'one document that matches its schema');
		ok($document->{ready}, 'ready is a JSON boolean');
		$result = $check->([ [ 'Server', 1 ] ], json => 1, quiet => 1);
		$document = JSON::PP->new->decode($result->{text});
		is_deeply([ $result->{status}, $document->{problems}, $document->{docker}{daemon}, $document->{image} ], [ 2, 1, undef, undef ],
			'a problem: what could not be found out is null');

		{
			my $guard = Test::Mockingbird::mock_scoped('App::Actions::Check::json_schema' => sub { { type => 'array' } });
			my $error = caught { $check->([], json => 1) };
			isa_ok($error, 'App::Actions::Schema::Invalid', 'a document that does not match its schema');
			like("$error", qr/the action-run check --json document does not match App::Actions::Check->json_schema/, 'says so');
		}
		settle('text Check: the document does not match its schema');

		{
			local $FAIL{open} = sub { ref $_[2] eq 'SCALAR' };
			throws_ok { App::Actions::Check->new(docker_bin => $fake_docker)->run } qr/\AUnable to buffer the check report: \S/,
				'a report that cannot be buffered';
		}
		settle('text Check: Unable to buffer the check report');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Support and App::Actions::Runner::Support::Env
# ---------------------------------------------------------------------------

subtest 'App::Actions::Runner::Support' => sub {
	my $expression = App::Actions::Expression->new;

	subtest 'status_flags, chomp_error, trim_error and has_status_function' => sub {
		returns_ok(App::Actions::Runner::Support::status_flags(0), { type => 'hashref' }, 'status_flags');
		is_deeply(App::Actions::Runner::Support::status_flags(0), { success => 1, failure => 0, cancelled => 0 }, 'not failed');
		is_deeply(App::Actions::Runner::Support::status_flags(1), { success => 0, failure => 1, cancelled => 0 }, 'failed');

		is(App::Actions::Runner::Support::chomp_error("boom at x line 3.\n\n"), 'boom at x line 3.', 'chomp_error keeps the location');
		is(App::Actions::Runner::Support::chomp_error(undef), '', 'and undef is empty');

		is(App::Actions::Runner::Support::trim_error("boom at lib/X.pm line 3.\n"), 'boom', 'trim_error drops the location');
		my $error = caught { App::Actions::Workflow->load('') };
		is(App::Actions::Runner::Support::trim_error($error), 'No workflow file given', 'and gives an error its message');
		is(App::Actions::Runner::Support::trim_error($_), undef, 'no error is undef: ' . shown($_)) for undef, '';

		my %status = ('success()' => 1, 'always ()' => 1, '${{ failure() }}' => 1, 'cancelled()' => 1, 'github.success' => 0,
			q{'success'} => 0, '' => 0);
		is_returned(App::Actions::Runner::Support::has_status_function($_), { type => 'boolean' }, $status{$_},
			'has_status_function: ' . shown($_)) for sort keys %status;
		is(App::Actions::Runner::Support::has_status_function(undef), 0, 'undef has none');
	};

	subtest 'default_logger and null_logger' => sub {
		my $logger = App::Actions::Runner::Support::default_logger();
		returns_ok($logger, { type => 'object', isa => 'Log::Abstraction' }, 'default_logger');
		is(output_of(stderr => sub { $logger->warn('the image cache could not be written') }),
			"the image cache could not be written\n", 'prints the message as written, on standard error');
		is(output_of(stderr => sub { $logger->error("two\nlines") }), "two\nlines\n", 'several lines as they are');
		is(output_of(stderr => sub { $logger->debug('detail') }), "detail\n", 'every level');
		is(output_of(stdout => sub { $logger->warn('x') }), '', 'nothing on standard output');
		my $null = App::Actions::Runner::Support::null_logger();
		returns_ok($null, { type => 'object', isa => 'Log::Abstraction' }, 'null_logger');
		is(output_of(stderr => sub { $null->error('gone') }), '', 'throws every message away');
		keeps_globals(sub { App::Actions::Runner::Support::default_logger() }, 'default_logger');
	};

	subtest 'resolve_env' => sub {
		my $context = { matrix => { perl => '5.40' }, github => { event => { message => 'see ${{ env.SECRET }}' } } };
		my $env = App::Actions::Runner::Support::resolve_env($expression, [
			{ A => 'workflow', B => 'b-${{ env.C }}', MESSAGE => '${{ github.event.message }}', SECRET => 'hidden' },
			'not a layer',
			{ A => 'job', C => 'c-${{ env.a }}-${{ matrix.perl }}' },
			undef,
			{ N => 3, T => JSON::PP::true },
		], $context);
		returns_ok($env, { type => 'hashref' }, 'a hash reference');
		is_deeply($env, {
			A => 'job', B => 'b-c-job-5.40', C => 'c-job-5.40', MESSAGE => 'see ${{ env.SECRET }}', SECRET => 'hidden', N => '3', T => 'true',
		}, 'later layers win, values refer to each other in any order, and text from a value is not evaluated');
		ok(!exists $context->{env}, "the caller's context is not changed");

		throws_code(sub { App::Actions::Runner::Support::resolve_env($expression, [ { A => '${{ env.B }}', B => 'x${{ env.A }}' } ], {}) },
			'runner.env_cycle', q{Environment variable 'A' refers to itself, directly or through other variables},
			'variables that refer to each other');
		throws_code(sub { App::Actions::Runner::Support::resolve_env($expression, [ { SELF => '${{ env.SELF }}' } ], {}) },
			'runner.env_cycle', undef, 'one that refers to itself');
		my $error = throws_code(sub { App::Actions::Runner::Support::resolve_env($expression, [ { BAD => '${{ 1 + }}' } ], {}) },
			'runner.env_failed', undef, 'a value that does not evaluate');
		like($error->message, qr/\AUnable to evaluate environment variable 'BAD': Unexpected character '\+'/, 'says which and why');
		$error = throws_code(sub { App::Actions::Runner::Support::resolve_env($expression, [ { USES => '${{ env.BAD }}', BAD => '${{ x( }}' } ], {}) },
			'runner.env_failed', undef, 'the first failure is the one raised');
		like($error->message, qr/variable 'BAD'/, 'the variable that failed, not the one that used it');
		is_deeply(App::Actions::Runner::Support::resolve_env($expression, [], {}), {}, 'no layers, no variables');
		keeps_globals(sub { App::Actions::Runner::Support::resolve_env($expression, [ { A => '${{ env.B }}', B => 1 } ], {}) },
			'resolve_env');
	};

	subtest 'App::Actions::Runner::Support::Env' => sub {
		my %raw = (A => 'a', B => 'b');
		my (%resolved, @asked);
		my $state = tie my %env, 'App::Actions::Runner::Support::Env', \%raw, \%resolved, sub { push @asked, $_[0]; return uc $raw{ $_[0] } };
		returns_ok($state, { type => 'object', isa => 'App::Actions::Runner::Support::Env' }, 'TIEHASH');
		ok(exists $env{A} && !exists $env{Z}, 'EXISTS sees the raw names');
		is_deeply([ sort keys %env ], [ 'A', 'B' ], 'and so do keys');
		is_deeply(\@asked, [], 'without working anything out');
		ok(scalar %env, 'SCALAR');
		is($env{A}, 'A', 'FETCH works a value out');
		is($env{A}, 'A', 'once');
		is_deeply([ \@asked, \%resolved ], [ [ 'A' ], { A => 'A' } ], 'and keeps it');
		is($env{Z}, undef, 'an unknown name is undef');
		is($state->failure, undef, 'no failure');
		keeps_globals(sub { $env{B} }, 'FETCH');

		my %looping = (L => 'x');
		my ($loop, %cycle);
		$loop = tie %cycle, 'App::Actions::Runner::Support::Env', \%looping, {}, sub { return $cycle{L} };
		throws_code(sub { $cycle{L} }, 'runner.env_cycle', undef, 'a value that needs itself');
		isa_ok($loop->failure, 'App::Actions::Error', 'the failure is kept');
		is($loop->failure->code, 'runner.env_cycle', 'with its code');
		undef $loop;
		untie %cycle;

		my $failing = tie my %bad, 'App::Actions::Runner::Support::Env', { F => 'f' }, {}, sub { die "no good\n" };
		my $error = throws_code(sub { $bad{F} }, 'runner.env_failed', q{Unable to evaluate environment variable 'F': no good},
			'a resolver that dies');
		is($failing->failure, $error, 'is the failure');
		my $fresh = tie my %other, 'App::Actions::Runner::Support::Env', {}, {}, sub { };
		throws_code(sub { $fresh->fail('runner.env_cycle', { name => 'Q' }) }, 'runner.env_cycle',
			q{Environment variable 'Q' refers to itself, directly or through other variables}, 'fail raises the message');
		is($fresh->failure->code, 'runner.env_cycle', 'and remembers it');
	};

	subtest 'boolean_value' => sub {
		my %words = (true => 1, YES => 1, 1 => 1, ' true ' => 1, false => 0, No => 0, 0 => 0, '' => 0,
			'${{ matrix.on }}' => 1, 'matrix.off' => 0, q{matrix.on == 'yes'} => 1, 'success()' => 1);
		my $context = { matrix => { on => 'yes', off => '' } };
		is_returned(App::Actions::Runner::Support::boolean_value($expression, $_, $context, { success => 1 }), { type => 'boolean' },
			$words{$_}, 'boolean_value: ' . shown($_)) for sort keys %words;
		is(App::Actions::Runner::Support::boolean_value($expression, JSON::PP::true, {}), 1, 'a YAML true');
		is(App::Actions::Runner::Support::boolean_value($expression, JSON::PP::false, {}), 0, 'a YAML false');
		is(App::Actions::Runner::Support::boolean_value($expression, undef, {}), 0, 'nothing is false');
		throws_ok { App::Actions::Runner::Support::boolean_value($expression, 'a +', {}) } qr/\AUnexpected character/,
			"and the expression's own errors";
	};

	subtest 'write_container_file' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'step-1.sh');
		is(App::Actions::Runner::Support::write_container_file($path, "#!/bin/sh\necho hi\n", 'the step script'), undef,
			'returns nothing');
		open my $in, '<:raw', $path or die $!;
		is(do { local $/; <$in> }, "#!/bin/sh\necho hi\n", 'the bytes, with LF line ends');
		close $in;
		SKIP: {
			skip 'file modes are not Unix ones', 1 if $^O eq 'MSWin32';
			is((stat $path)[2] & 07777, 0600, 'readable by its owner only');
		}
		App::Actions::Runner::Support::write_container_file($path, 'again', 'the step script');
		is(-s $path, 5, 'a file this run wrote is replaced');
		SKIP: {
			skip 'no symbolic links', 2 if $^O eq 'MSWin32';
			my $target = write_file('target', 'precious', $dir);
			my $link = File::Spec->catfile($dir, 'planted.sh');
			symlink $target, $link or die $!;
			App::Actions::Runner::Support::write_container_file($link, 'script', 'the step script');
			ok(!-l $link, 'a link at the name is replaced, not followed');
			open my $check, '<', $target or die $!;
			is(do { local $/; <$check> }, 'precious', 'and what it pointed at is untouched');
		}
		my $missing = File::Spec->catfile($dir, 'no', 'such', 'file');
		throws_code(sub { App::Actions::Runner::Support::write_container_file($missing, 'x', 'the sudo shim') }, 'runner.write_failed',
			"Unable to write the sudo shim: ${\ do { local $! = $config{errno}; qq{$!} } }", 'a file that cannot be created');
		keeps_globals(sub { App::Actions::Runner::Support::write_container_file($path, 'x', 'it') }, 'write_container_file', io => 1);
	};

	subtest 'local_action_path and local_action_dir' => sub {
		my %paths = ('./a/b/' => 'a/b', '/a/b' => 'a/b', 'a/b' => 'a/b', './.github/actions/x' => '.github/actions/x', './a/..b' => 'a/..b');
		is_returned(App::Actions::Runner::Support::local_action_path($_), { type => 'string', min => 1 }, $paths{$_},
			"local_action_path: $_") for sort keys %paths;
		throws_code(sub { App::Actions::Runner::Support::local_action_path($_) }, 'runner.local_action_empty',
			"Local action '$_' does not name a directory inside the project", "nothing named: '$_'") for './', '/', './/';
		throws_code(sub { App::Actions::Runner::Support::local_action_path($_) }, 'runner.local_action_escapes',
			"Local action '$_' must not escape the project directory", "escaping: '$_'") for '../x', './a/../../x', './..';

		my $project = tempdir(CLEANUP => 1);
		make_path(File::Spec->catdir($project, qw(actions inside)));
		my $location = App::Actions::Runner::Support::local_action_dir($project, './actions/inside');
		returns_ok($location, { type => 'hashref', schema => { relative => { type => 'string', min => 1 }, dir => { type => 'string', min => 1 } } },
			'local_action_dir');
		is_deeply($location, { relative => 'actions/inside', dir => File::Spec->catdir($project, 'actions', 'inside') }, 'where it is');
		is(App::Actions::Runner::Support::local_action_dir($project, './missing')->{dir}, File::Spec->catdir($project, 'missing'),
			'one that does not exist is returned for the caller to report');
		SKIP: {
			skip 'no symbolic links', 1 if $^O eq 'MSWin32';
			symlink tempdir(CLEANUP => 1), File::Spec->catdir($project, 'actions', 'out') or die $!;
			throws_code(sub { App::Actions::Runner::Support::local_action_dir($project, './actions/out') }, 'runner.local_action_escapes',
				q{Local action './actions/out' must not escape the project directory}, 'a link that leads out');
		}
		throws_code(sub { App::Actions::Runner::Support::local_action_dir($project, '../x') }, 'runner.local_action_escapes', undef,
			'and the textual check');
		keeps_globals(sub { App::Actions::Runner::Support::local_action_dir($project, './actions/inside') }, 'local_action_dir', io => 1);
	};

	subtest 'action_inputs' => sub {
		my $action = App::Actions::Action->load(write_file('action.yml', <<'YAML'));
inputs:
  who: { required: true }
  greeting: { default: 'hello ${{ matrix.lang }}' }
  extra: { default: '' }
  needed: { required: true, default: x }
runs:
  using: composite
  steps:
    - run: echo
YAML
		my $context = { matrix => { lang => 'en' } };
		my $inputs = App::Actions::Runner::Support::action_inputs($expression, $action,
			{ with => { who => '${{ matrix.lang }}-world', list => [ 1, 2 ], flag => JSON::PP::true } }, './greet', $context);
		returns_ok($inputs, { type => 'hashref' }, 'a hash reference');
		is_deeply($inputs, { who => 'en-world', greeting => 'hello en', extra => '', needed => 'x', list => '[1,2]', flag => 'true' },
			'defaults, replaced by with:, all as text');
		throws_code(sub { App::Actions::Runner::Support::action_inputs($expression, $action, {}, './greet', $context) },
			'runner.input_required', q{Action './greet' requires the input 'who'}, 'a required input nobody gave');
		throws_code(sub { App::Actions::Runner::Support::action_inputs($expression, $action, { with => { who => '' } }, './greet', $context) },
			'runner.input_required', undef, 'an empty one is not given');
	};

	subtest 'redact and env_args' => sub {
		my $docker = App::Actions::Docker->new(secrets => { T => 's3cret' });
		is(App::Actions::Runner::Support::redact($docker, 'token s3cret'), 'token ***', 'redact asks Docker');
		is(App::Actions::Runner::Support::redact(bless({}, 'Local::Plain'), 'token s3cret'), 'token s3cret',
			'a Docker that cannot redact leaves the text');
		is(App::Actions::Runner::Support::redact($docker, undef), undef, 'undef stays undef');

		my $args = App::Actions::Runner::Support::env_args({ B => 2, A => 'one', EMPTY => undef });
		returns_ok($args, { type => 'arrayref' }, 'env_args');
		is_deeply([ map { "$_" } @{$args} ], [ '-e', 'A=one', '-e', 'B=2', '-e', 'EMPTY=' ], 'sorted, each reading NAME=VALUE');
		isa_ok($args->[1], 'App::Actions::Docker::Variable', 'each variable');
		is_deeply(App::Actions::Runner::Support::env_args({}), [], 'none');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Report
# ---------------------------------------------------------------------------

# A Log::Abstraction logger that keeps each message, so a test can see what a
# runner part logged without reading standard error.
sub collecting_logger {
	my ($messages) = @_;

	return Log::Abstraction->new(
		logger => sub {
			my $message = $_[0]{message};
			push @{$messages}, ref $message eq 'ARRAY' ? join('', @{$message}) : $message;
		},
		level => 'debug',
		max_messages => 0,
	);
}

subtest 'App::Actions::Runner::Report' => sub {
	my $docker = App::Actions::Docker->new(secrets => { T => 's3cret' });
	my $report = sub { App::Actions::Runner::Report->new(docker => $docker, @_) };

	subtest 'new, record, fail and failed' => sub {
		my $object = $report->();
		returns_ok($object, { type => 'object', isa => 'App::Actions::Runner::Report' }, 'new');
		throws_code(sub { App::Actions::Runner::Report->new }, 'actions.invalid_arguments', undef, 'Docker is required');
		throws_code(sub { App::Actions::Runner::Report->new(docker => $docker, logger => 'NULL') }, 'actions.invalid_arguments',
			undef, 'a logger must be an object');
		is($object->record('test', 'success'), $object, 'record returns the object');
		is($object->failed, 0, 'not failed');
		returns_ok($object->failed, { type => 'boolean' }, 'failed is a boolean');
		is($object->fail, $object, 'fail returns the object');
		is($object->failed, 1, 'and it has failed');
		keeps_globals(sub { $report->()->record('a', 'skipped')->fail->failed }, 'record');
	};

	subtest 'print_summary' => sub {
		my $object = $report->()->record('build (token=s3cret)', 'success')->record('lint', 'skipped');
		my $text = output_of(stdout => sub { is($object->print_summary, $object, 'returns the object') });
		is($text, "\n=== Workflow summary ===\n  build (token=***)" . (' ' x 33) . " success\n  lint" . (' ' x 46) . " skipped\n"
			. "Workflow succeeded\n", 'one line per job, secrets hidden, and the result');
		$object->record('test', 'failure')->fail;
		like(output_of(stdout => sub { $object->print_summary }), qr/  test\s+failure\nWorkflow FAILED\n\z/, 'a failed workflow');
		is(output_of(stdout => sub { $report->()->print_summary }), "\n=== Workflow summary ===\n  No jobs were run.\nWorkflow succeeded\n",
			'no jobs');
		is(output_of(stdout => sub { $report->(quiet => 1)->record('x', 'success')->print_summary }), '', 'quiet prints nothing');
	};

	subtest 'report_images' => sub {
		my $object = $report->();
		my $text = output_of(stdout => sub {
			is($object->report_images([
				{ image => 'perl:5.40', source => "job 'test'", status => 'pulled' },
				{ image => 'alpine', source => '', status => 'present' },
				{ expression => 'img:${{ env.X }}', source => "job 'b'", status => 'deferred', error => 'env.X is not known yet' },
				{ status => 'skipped' },
				{ expression => 'x:${{ y }}', source => 's', status => 'deferred' },
			]), $object, 'returns the object');
		});
		my @lines = split /\n/, $text;
		is(scalar @lines, 6, 'one line per image, and the reason for a deferred one');
		like($lines[0], qr/perl:5\.40.*job 'test'.*pulled/, 'the image, what needs it and its status');
		like($lines[1], qr/alpine.*workflow.*present/, 'no source is the workflow');
		like($lines[2], qr/img:\$\{\{ env\.X \}\}.*deferred/, 'a deferred image is named by its expression');
		like($lines[3], qr/env\.X is not known yet/, 'and followed by the reason');
		like($lines[4], qr/skipped/, 'an image with no name');
		is(output_of(stdout => sub { $object->report_images([]) }), '', 'no images, no lines');
	};

	subtest 'keep_logs and print_kept_logs' => sub {
		my $work = tempdir(CLEANUP => 1);
		my $logs = [
			{ name => 'test (perl=5.40)', file => 'job-1-test.log', path => write_file('job-1-test.log', "ok\n", $work) },
			{ name => 'lint', file => 'job-2-lint.log', path => write_file('job-2-lint.log', "bad\n", $work) },
			{ name => 'gone', file => 'job-3.log', path => File::Spec->catfile($work, 'job-3.log') },
		];
		my $root = File::Spec->catdir(tempdir(CLEANUP => 1), 'logs');
		my @warnings;
		my $object = $report->(logger => collecting_logger(\@warnings));
		is($object->keep_logs($logs, $root, 'abc123'), $object, 'returns the object');
		opendir my $dir, $root or die "$root: $!";
		my ($kept) = grep { !/\A\./ } readdir $dir;
		like($kept, qr/\A\d{8}-\d{6}-abc123\z/, 'a directory named after the time and the run');
		my $kept_dir = File::Spec->catdir($root, $kept);
		ok(-f File::Spec->catfile($kept_dir, 'job-1-test.log') && -f File::Spec->catfile($kept_dir, 'job-2-lint.log'), 'the logs are copied');
		ok(!-e File::Spec->catfile($kept_dir, 'job-3.log'), 'a log that is not there is left out');
		SKIP: {
			skip 'file modes are not Unix ones', 1 if $^O eq 'MSWin32';
			is((stat File::Spec->catfile($kept_dir, 'job-1-test.log'))[2] & 077, 0, 'readable by their owner only');
		}
		is_deeply(\@warnings, [], 'with no warning');
		is(output_of(stdout => sub { $object->print_kept_logs }),
			"\nJob logs kept in $kept_dir\n  test (perl=5.40)  job-1-test.log\n  lint  job-2-lint.log\n", 'print_kept_logs says where');
		is(output_of(stdout => sub { $report->(quiet => 1)->keep_logs($logs, $root, 'q')->print_kept_logs }), '', 'unless quiet');
		is(output_of(stdout => sub { $report->()->print_kept_logs }), '', 'or there were none');

		for my $bad ([ '../escape', 'abc' ], [ 'job-1.log', '..' ], [ 'job-1.log', 'a/b' ]) {
			my ($file, $run) = @{$bad};
			my @said;
			my $logged = $report->(logger => collecting_logger(\@said));
			$logged->keep_logs([ { name => 'x', file => $file, path => $logs->[0]{path} } ], $root, $run);
			my $name = $file eq 'job-1.log' ? $run : $file;
			is_deeply(\@said, [ "action-run: could not keep the job logs: '$name' is not a plain file name" ],
				"a name that is not plain is refused: $name");
			is(output_of(stdout => sub { $logged->print_kept_logs }), '', 'and nothing is kept');
		}

		SKIP: {
			skip 'a directory mode does not stop this user', 2 if $^O eq 'MSWin32' || $> == 0;
			my $locked = tempdir(CLEANUP => 1);
			chmod 0500, $locked;
			my @said;
			$report->(logger => collecting_logger(\@said))->keep_logs($logs, File::Spec->catdir($locked, 'logs'), 'r1');
			chmod 0700, $locked;
			is(scalar @said, 1, 'a directory that cannot be made is one warning');
			like($said[0], qr/\Aaction-run: could not keep the job logs: cannot copy '\Q$logs->[0]{path}\E' to '\Q$locked\E.+r1': \S[^\n]*\z/,
				'naming the log, where it was going, and why, without a source line');
			my $stuck = tempdir(CLEANUP => 1);
			mkdir File::Spec->catdir($stuck, 'logs');
			@said = ();
			my $mock = Test::Mockingbird::mock_scoped('App::Actions::Runner::Report::copy' => sub { $! = $config{errno}; return 0 });
			$report->(logger => collecting_logger(\@said))->keep_logs($logs, File::Spec->catdir($stuck, 'logs'), 'r2');
			like($said[0] // '', qr/\Aaction-run: could not keep the job logs: cannot copy '\Q$logs->[0]{path}\E' to '.+job-1-test\.log': \S/,
				'a log that cannot be copied');
		}
		keeps_globals(sub { $report->()->keep_logs($logs, $root, 'g') }, 'keep_logs', io => 1);
	};

	subtest 'print_kept_resources' => sub {
		my $object = $report->();
		my $text = output_of(stdout => sub {
			is($object->print_kept_resources({ containers => [ 'c1', 'c2' ], networks => [ 'n1' ] }, '/tmp/run'), $object,
				'returns the object');
		});
		is($text, "Kept Docker resources:\n  container c1\n  container c2\n  network n1\n  temporary directory /tmp/run\n",
			'lists what is left');
		is(output_of(stdout => sub { $report->(quiet => 1)->print_kept_resources({ networks => [ 'n' ] }) }), "  network n\n",
			'even when quiet, without the heading');
		is(output_of(stdout => sub { $object->print_kept_resources({}) }), '', 'nothing left, nothing printed');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Parallel
# ---------------------------------------------------------------------------

subtest 'App::Actions::Runner::Parallel' => sub {
	# Each job prints what its plan says and reports the result its plan
	# names, so one run shows the output, the order and the results.
	my $plan = sub { my ($name, %more) = @_; return { display_name => $name, %more } };
	my $job = sub {
		my ($entry) = @_;
		my $plan = $entry->{plan};
		print $plan->{say} if defined $plan->{say};
		die $plan->{die} if defined $plan->{die};
		POSIX::_exit(9) if $plan->{vanish};
		return { result => $plan->{result} || 'success', name => $plan->{display_name} };
	};
	my $parallel = sub {
		return App::Actions::Runner::Parallel->new(capacity => 4, temp_path => tempdir(CLEANUP => 1), run_job => $job, @_);
	};
	my $read = sub { open my $in, '<', $_[0] or return undef; local $/; return scalar <$in> };

	subtest 'new and logs' => sub {
		my $object = $parallel->();
		returns_ok($object, { type => 'object', isa => 'App::Actions::Runner::Parallel' }, 'new');
		is_deeply($object->logs, [], 'no logs yet');
		returns_ok($object->logs, { type => 'arrayref' }, 'logs is an array reference');
		throws_code(sub { App::Actions::Runner::Parallel->new(%{$_}) }, 'actions.invalid_arguments', undef, 'refused: ' . join(',', sort keys %{$_}))
			for { temp_path => '/t', run_job => $job }, { capacity => 0, temp_path => '/t', run_job => $job },
				{ capacity => 2, run_job => $job }, { capacity => 2, temp_path => '/t', run_job => 'code' },
				{ capacity => 2, temp_path => '/t', run_job => $job, logger => 'NULL' };
	};

	subtest 'run: when it declines' => sub {
		is($parallel->()->run([ $plan->('one') ]), undef, 'a single job runs one at a time');
		is($parallel->()->run([]), undef, 'so does none');
		is($parallel->(capacity => 1)->run([ $plan->('a'), $plan->('b') ]), undef, 'a capacity of one');
		is($parallel->()->run([ $plan->('a', max_parallel => 1), $plan->('b') ]), undef, 'max-parallel of one');
		local $^O = 'MSWin32';
		is($parallel->()->run([ $plan->('a'), $plan->('b') ]), undef, 'a host without a reliable fork');
	};

	subtest 'run: jobs beside each other' => sub {
		my @seen;
		my $object = $parallel->(on_result => sub { push @seen, $_[0]{name} });
		my $outcomes;
		my $text = output_of(stdout => sub {
			$outcomes = $object->run([
				$plan->('test (n=one)', say => "first\r\n\nsecond\npartial"),
				$plan->('lint', say => "lint ok\n", result => 'failure'),
				$plan->('docs/x: y', say => ''),
			]);
		});
		returns_ok($outcomes, { type => 'arrayref' }, 'an array reference');
		is_deeply([ map { [ $_->{plan}{display_name}, $_->{started}, $_->{result}{result} ] } @{$outcomes} ],
			[ [ 'test (n=one)', 1, 'success' ], [ 'lint', 1, 'failure' ], [ 'docs/x: y', 1, 'success' ] ], 'one per plan, in plan order');
		is_deeply([ sort @seen ], [ 'docs/x: y', 'lint', 'test (n=one)' ], 'on_result sees each result');
		# The jobs run at once, so their lines may come in any order between
		# each other; each job's own lines keep theirs.
		my @own = grep { /\A\[test \(n=one\)\] / || !length } split /\n/, $text;
		is_deeply(\@own, [ '[test (n=one)] first', '', '[test (n=one)] second', '[test (n=one)] partial' ],
			'each line named, CR dropped, a blank line blank, and a last line without a newline shown');
		like($text, qr/^\[lint\] lint ok$/m, 'the other jobs too');
		my $logs = $object->logs;
		is_deeply([ map { $_->{file} } @{$logs} ], [ 'job-1-test_n_one.log', 'job-2-lint.log', 'job-3-docs_x_y.log' ],
			'logs, with names that say which job');
		is($read->($logs->[1]{path}), "lint ok\n", 'and the output in them');
		is(output_of(stdout => sub { $parallel->(quiet => 1)->run([ $plan->('a', say => "x\n"), $plan->('b', say => "y\n") ]) }), '',
			'quiet shows nothing');
		keeps_globals(sub { output_of(stdout => sub { $parallel->()->run([ $plan->('a'), $plan->('b') ]) }) }, 'run', io => 1);
	};

	subtest 'run: fail-fast and capacity' => sub {
		my $outcomes;
		output_of(stdout => sub {
			$outcomes = $parallel->(capacity => 2)->run([ $plan->('a', result => 'failure'), $plan->('b', result => 'failure'),
				$plan->('c'), $plan->('d') ], 1);
		});
		is_deeply([ map { $_->{started} } @{$outcomes} ], [ 1, 1, 0, 0 ], 'with fail-fast a failure starts no more');
		output_of(stdout => sub {
			$outcomes = $parallel->(capacity => 2)->run([ $plan->('a', result => 'failure'), map { $plan->($_) } 'b', 'c' ], 0);
		});
		is_deeply([ map { $_->{started} } @{$outcomes} ], [ 1, 1, 1 ], 'without it every job runs');
	};

	subtest 'run: a job that does not report' => sub {
		my $object = $parallel->();
		my $error;
		my $text = output_of(stdout => sub {
			$error = caught { $object->run([ $plan->('fine'), $plan->('broken', say => "trying\n", die => "it broke\n") ]) };
		});
		is($error, "job 'broken' did not run\n", 'the run dies, naming the job');
		my ($log) = grep { $_->{name} eq 'broken' } @{ $object->logs };
		is($read->($log->{path}), "trying\naction-run: it broke\n", "the job's log says why, through the logger");
		like($text, qr/^\[broken\] action-run: it broke$/m, 'and so does the output');
		settle('message runner.error');
		$error = caught { output_of(stdout => sub { $parallel->()->run([ $plan->('gone', vanish => 1), $plan->('b') ]) }) };
		is($error, "job 'gone' did not run\n", 'a job that vanished');
		settle('message runner.parallel.did_not_run');
	};

	subtest 'run: when fork fails' => sub {
		my $object = $parallel->();
		my $outcomes;
		{
			local $FAIL{fork} = 1;
			my $text = output_of(stdout => sub {
				$outcomes = $object->run([ $plan->('here', say => "local\n"), $plan->('also', result => 'failure') ]);
			});
			like($text, qr/^\[here\] local$/m, 'each job runs here, its output still named');
		}
		is_deeply([ map { $_->{result}{result} } @{$outcomes} ], [ 'success', 'failure' ], 'and its result collected');
		is($read->($object->logs->[0]{path}), "local\n", 'into its own log');
		is(output_of(stdout => sub { print "mine\n" }), "mine\n", 'standard output is put back');

		for my $stream (qw(STDOUT STDERR)) {
			my $handle = $stream eq 'STDOUT' ? \*STDOUT : \*STDERR;
			local $FAIL{fork} = 1;
			local $FAIL{open} = sub { !defined $_[0] && $_[1] eq '>&' && ref $_[2] && $_[2] == $handle };
			throws_code(sub { $parallel->()->run([ $plan->('a'), $plan->('b') ]) }, 'runner.parallel.dup_failed',
				"Unable to duplicate $stream", "a $stream that cannot be duplicated");
		}
		{
			local $FAIL{fork} = 1;
			local $FAIL{open} = sub { $_[1] eq '>' && defined $_[2] && $_[2] =~ /job-\d+\.log\z/ };
			my $error = throws_code(sub { $parallel->()->run([ $plan->('a'), $plan->('b') ]) }, 'runner.file_write_failed', undef,
				'a log that cannot be written');
			like($error->message, qr/\AUnable to write '.+job-1\.log': \S/, 'names it');
		}
		for my $stream (qw(STDOUT STDERR)) {
			open my $keep, '>&', ($stream eq 'STDOUT' ? \*STDOUT : \*STDERR) or die $!;
			my $error;
			{
				local $FAIL{fork} = 1;
				local $FAIL{open} = sub { defined $_[0] && !ref $_[0] && $_[0] eq $stream && $_[1] eq '>&'
					&& ref $_[2] && $_[2] != \*STDOUT && $_[2] != \*STDERR };
				$error = caught { output_of(stdout => sub { $parallel->()->run([ $plan->('a'), $plan->('b') ]) }) };
			}
			open(($stream eq 'STDOUT' ? \*STDOUT : \*STDERR), '>&', $keep) or die $!;
			isa_ok($error, 'App::Actions::Error', "a $stream that cannot be restored");
			is(ref $error && $error->code, 'runner.parallel.restore_failed', 'with its code');
			is(ref $error && $error->message, "Unable to restore $stream", 'and message');
		}
	};

	subtest 'run: results that cannot be read or written' => sub {
		{
			local $FAIL{open} = sub { $_[1] eq '<' && defined $_[2] && $_[2] =~ /job-\d+\.json\z/ };
			my $error;
			output_of(stdout => sub { $error = caught { $parallel->()->run([ $plan->('a'), $plan->('b') ]) } });
			isa_ok($error, 'App::Actions::Error', 'a result that cannot be read');
			is(ref $error && $error->code, 'runner.file_read_failed', 'with its code');
			like(ref $error && $error->message, qr/\AUnable to read '.+job-\d\.json': \S/, 'and names the file');
		}
		{
			# Only a's result is unwritable: the first job reaped without one is
			# the one named, and when both failed that was whichever finished
			# first.
			local $FAIL{open} = sub { $_[1] eq '>' && defined $_[2] && $_[2] =~ /job-1\.json\z/ };
			my $object = $parallel->();
			my $error;
			output_of(stdout => sub { $error = caught { $object->run([ $plan->('a'), $plan->('b') ]) } });
			is($error, "job 'a' did not run\n", 'a result that cannot be written is a job that did not run');
			like($read->($object->logs->[0]{path}), qr/\Aaction-run: Unable to write '.+job-1\.json': \S/, 'and its log says why');
			settle('message runner.file_write_failed');
		}
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Images
# ---------------------------------------------------------------------------

# A Docker object of the caller's needs only image_exists and pull.  This one
# knows which images are present, which pulls fail and with what, and keeps
# every pull it was asked for.
{
	package Local::ImageDocker;

	sub new {
		my ($class, %options) = @_;

		return bless { present => {}, fail => {}, pulls => [], %options }, $class;
	}

	sub image_exists { return $_[0]{present}{ $_[1] } ? 1 : 0 }

	sub pull {
		my ($self, $image) = @_;

		push @{ $self->{pulls} }, $image;
		die "$self->{fail}{$image}\n" if exists $self->{fail}{$image};
		$self->{present}{$image} = 1;
		return 1;
	}
}

# One that can pull several at once, as App::Actions::Docker can: it reports
# an exit status per image, and none at all for the images in "silent".
{
	package Local::ManyDocker;
	our @ISA = ('Local::ImageDocker');

	sub pull_many {
		my ($self, $images, %options) = @_;

		$self->{many} = { images => [ @{$images} ], options => \%options };
		return { map { ($_ => $self->{status}{$_} // 0) } grep { !$self->{silent}{$_} } @{$images} };
	}
}

subtest 'App::Actions::Runner::Images' => sub {
	# A project with a local composite action whose image comes from an
	# input, and which uses itself, so the walk must stop.
	my $project = tempdir(CLEANUP => 1);
	make_path(File::Spec->catdir($project, 'act'));
	write_file('action.yml', join("\n",
		'name: img',
		'inputs:',
		'  image:',
		'    default: busybox:1',
		'runs:',
		'  using: composite',
		'  steps:',
		'    - uses: docker://${{ inputs.image }}',
		'    - uses: ./act',
		''), File::Spec->catdir($project, 'act'));

	my $workflow = App::Actions::Workflow->load(write_file('ci.yml', "jobs:\n  test:\n    steps:\n      - run: true\n"));
	my $context = sub {
		return { env => { TAG => '3.20', EMPTY => '' }, github => { sha => 'abc' }, matrix => $_[0]{matrix} || {} };
	};
	my $images = sub {
		return App::Actions::Runner::Images->new(docker => Local::ImageDocker->new, expression => App::Actions::Expression->new,
			workflow => $workflow, project_dir => $project, context => $context, quiet => 1, @_);
	};

	my $later = 'busybox:${{ steps.a.outputs.t }}';
	my $unknown = q{unable to resolve '${{ steps.a.outputs.t }}' from the values available};
	my %job = (
		test => {
			base_id => 'test', display_name => 'test (v=5.40)', 'runs-on' => 'ubuntu-latest', matrix => { v => '5.40' },
			container => { image => 'perl:${{ matrix.v }}' },
			services => { db => { image => 'postgres:16' }, cache => 'redis:7', none => {} },
			steps => [
				{ uses => 'docker://alpine:${{ env.TAG }}' },
				{ uses => "docker://$later" },
				{ uses => './act' },
				{ uses => './missing' },
				{ uses => 'actions/checkout@v4' },
				{ run => 'true' },
			],
		},
		windows => { base_id => 'windows', 'runs-on' => 'windows-latest', container => { image => 'mcr.microsoft.com/x' }, steps => [] },
		again => {
			base_id => 'again', 'runs-on' => 'ubuntu-latest', container => { image => 'perl:5.40' },
			services => { db => 'postgres:16' }, steps => [ { uses => "docker://$later" } ],
		},
	);
	my $source = {
		job => "job 'test (v=5.40)'",
		cache => "service 'cache' of job 'test (v=5.40)'",
		db => "service 'db' of job 'test (v=5.40)'",
		alpine => q{action 'docker://alpine:${{ env.TAG }}' in job 'test (v=5.40)'},
		later => "action 'docker://$later' in job 'test (v=5.40)'",
		nested => q{action 'docker://${{ inputs.image }}' in local action './act' of job 'test (v=5.40)'},
	};

	subtest 'new and concurrency' => sub {
		my $object = $images->();
		returns_ok($object, { type => 'object', isa => 'App::Actions::Runner::Images' }, 'new');
		is_returned($object->concurrency, { type => 'integer', min => 1 }, 4, 'four pulls at once by default');
		is($images->(pull_concurrency => 2)->concurrency, 2, 'or as many as asked for');
		{
			local $^O = 'MSWin32';
			is($images->(pull_concurrency => 8)->concurrency, 1, 'but one at a time on Windows');
		}
		my %need = (docker => Local::ImageDocker->new, expression => App::Actions::Expression->new, workflow => $workflow,
			project_dir => $project, context => $context);
		for my $missing (sort keys %need) {
			my %given = %need;
			delete $given{$missing};
			throws_code(sub { App::Actions::Runner::Images->new(%given) }, 'actions.invalid_arguments', undef, "$missing is required");
		}
		throws_code(sub { App::Actions::Runner::Images->new(%need, %{$_}) }, 'actions.invalid_arguments', undef,
			'refused: ' . join(',', keys %{$_})) for { pull_concurrency => 0 }, { logger => 'NULL' }, { project_dir => '' },
				{ docker => bless({}, 'Local::Nothing') };
	};

	subtest 'job_expressions' => sub {
		my $entries = $images->()->job_expressions($job{test}, 'ubuntu-latest', $context->($job{test}));
		returns_ok($entries, { type => 'arrayref' }, 'an array reference');
		show_state(job_expressions => $entries);
		is_deeply($entries, [
			{ expression => 'perl:5.40', source => $source->{job}, kind => 'job' },
			{ expression => 'redis:7', source => $source->{cache}, kind => 'service:cache' },
			{ expression => 'postgres:16', source => $source->{db}, kind => 'service:db' },
			{ expression => 'alpine:3.20', source => $source->{alpine} },
			{ expression => $later, source => $source->{later} },
			{ expression => 'busybox:1', source => $source->{nested} },
		], 'the job, its services in order, then each action with what it knows resolved and the rest as written');
		my $with = $images->()->job_expressions({ base_id => 'w', steps => [ { uses => './act', with => { image => 'mine:2' } } ] },
			'ubuntu-latest', {});
		is($with->[-1]{expression}, 'mine:2', "a local action's image comes from the step's inputs");
		keeps_globals(sub { $images->()->job_expressions($job{test}, 'ubuntu-latest', $context->($job{test})) }, 'job_expressions');
	};

	subtest 'required' => sub {
		my $entries = $images->()->required([ $job{test}, $job{windows}, $job{again} ]);
		returns_ok($entries, { type => 'arrayref' }, 'an array reference');
		is_deeply($entries, [
			{ image => 'perl:5.40', source => $source->{job}, kind => 'job' },
			{ image => 'redis:7', source => $source->{cache}, kind => 'service:cache' },
			{ image => 'postgres:16', source => $source->{db}, kind => 'service:db' },
			{ image => 'alpine:3.20', source => $source->{alpine}, kind => undef },
			{ image => undef, expression => $later, source => $source->{later}, error => $unknown },
			{ image => 'busybox:1', source => $source->{nested}, kind => undef },
			{ image => undef, expression => $later, source => "action 'docker://$later' in job 'again'", error => $unknown },
		], 'each image once, a Windows job left out, and an unknown name once for each thing that needs it');
		my $empty = $images->()->required([ { base_id => 'e', 'runs-on' => 'ubuntu-latest', container => { image => '${{ env.EMPTY }}' },
			steps => [] } ]);
		is_deeply($empty, [ { image => undef, expression => '${{ env.EMPTY }}', source => "job 'e'",
			error => 'the image name is empty' } ], 'an empty name is not an image');
		is_deeply($images->()->required([]), [], 'no jobs, no images');
		keeps_globals(sub { $images->()->required([ values %job ]) }, 'required');
	};

	subtest 'prepare: one pull at a time' => sub {
		my $docker = Local::ImageDocker->new(present => { 'perl:5.40' => 1 }, fail => { 'redis:7' => 'no such image' });
		my $object = $images->(docker => $docker, quiet => 0);
		my $prepared;
		my $text = output_of(stdout => sub { $prepared = $object->prepare([ $job{test} ]) });
		returns_ok($prepared, { type => 'hashref' }, 'a hash reference');
		is_deeply($prepared->{records}, [
			{ image => 'perl:5.40', source => $source->{job}, status => 'present' },
			{ image => 'redis:7', source => $source->{cache}, status => 'failed', error => 'no such image' },
			{ image => 'postgres:16', source => $source->{db}, status => 'pulled' },
			{ image => 'alpine:3.20', source => $source->{alpine}, status => 'pulled' },
			{ image => undef, expression => $later, source => $source->{later}, status => 'deferred', error => $unknown },
			{ image => 'busybox:1', source => $source->{nested}, status => 'pulled' },
		], 'present, pulled, failed and deferred records');
		is_deeply($prepared->{failures}, [ $prepared->{records}[1] ], 'the failures, for the caller to judge');
		is($text, join('', map { "Pulling image $_...\n" } 'redis:7', 'postgres:16', 'alpine:3.20', 'busybox:1'),
			'each pull announced first');
		is_deeply($docker->{pulls}, [ 'redis:7', 'postgres:16', 'alpine:3.20', 'busybox:1' ], 'one pull each');
		is_returned($object->pulled, { type => 'arrayref' }, [ 'alpine:3.20', 'busybox:1', 'postgres:16' ],
			'pulled lists what arrived, sorted');
		keeps_globals(sub { $images->(docker => Local::ImageDocker->new(fail => { 'redis:7' => 'no' }))->prepare([ $job{test} ]) },
			'prepare');
	};

	subtest 'prepare: pulls together' => sub {
		my $docker = Local::ManyDocker->new(present => { 'perl:5.40' => 1 }, status => { 'postgres:16' => 1 },
			silent => { 'alpine:3.20' => 1 });
		my $object = $images->(docker => $docker, pull_concurrency => 3);
		my $prepared;
		my $text = output_of(stdout => sub { $prepared = $object->prepare([ $job{test} ], quiet => 1) });
		is($text, '', 'quiet prints nothing');
		is_deeply($docker->{many}, { images => [ 'redis:7', 'postgres:16', 'alpine:3.20', 'busybox:1' ],
			options => { concurrency => 3, quiet => 1 } }, 'every pending image in one call, with the concurrency, discarding output');
		my %status = map { ($_->{image} // '') => [ $_->{status}, $_->{error} ] } @{ $prepared->{records} };
		is_deeply($status{'postgres:16'}, [ 'failed', q{Failed to pull Docker image 'postgres:16' (exit 1)} ], 'a pull that failed');
		is_deeply($status{'alpine:3.20'}, [ 'failed', q{Failed to pull Docker image 'alpine:3.20' (exit -1)} ],
			'an image the Docker object said nothing about');
		is_deeply($status{'redis:7'}, [ 'pulled', undef ], 'one that arrived');
		is_deeply([ map { $_->{image} } @{ $prepared->{failures} } ], [ 'postgres:16', 'alpine:3.20' ], 'the failures');
		is_deeply($object->pulled, [ 'busybox:1', 'redis:7' ], 'and the arrivals are recorded for the cleanup');
	};

	subtest 'prepare: the options' => sub {
		my $docker = Local::ImageDocker->new(present => { 'perl:5.40' => 1 });
		my $text = output_of(stdout => sub {
			my $prepared = $images->(docker => $docker, no_pull => 1, quiet => 0)->prepare([ $job{again} ]);
			is_deeply($prepared->{failures}, [ { image => 'postgres:16', source => "service 'db' of job 'again'", status => 'failed',
				error => q{Docker image 'postgres:16' is not available locally (--no-pull)} } ], '--no-pull: an absent image fails');
		});
		is($text, '', 'and nothing is pulled');
		is_deeply($docker->{pulls}, [], 'not even what could be');

		my $object = $images->(docker => $docker, pull => 1);
		my $prepared = $object->prepare([ $job{again} ]);
		is_deeply([ map { $_->{status} } @{ $prepared->{records} } ], [ 'pulled', 'pulled', 'deferred' ], '--pull refreshes present images');
		is_deeply($object->pulled, [ 'postgres:16' ], 'but one that was there already is not new');

		$text = output_of(stdout => sub { $images->(docker => Local::ImageDocker->new, verbose => 1, quiet => 0)->prepare([ $job{again} ]) });
		like($text, qr/\A  image     perl:5\.40 \(job 'again'\)\n  image     postgres:16 \(service 'db' of job 'again'\)\n/,
			'verbose shows each check');
		is(output_of(stdout => sub { $images->(verbose => 1, quiet => 0)->prepare([ $job{again} ], quiet => 1) }), '',
			'unless the call is quiet');

		my $dry = Local::ImageDocker->new;
		$prepared = $images->(docker => $dry, dry_run => 1)->prepare([ $job{again} ]);
		is_deeply([ map { $_->{status} } @{ $prepared->{records} } ], [ 'present', 'present', 'deferred' ], 'a dry run takes them as present');
		is_deeply($dry->{pulls}, [], 'and pulls nothing');
		is_deeply($images->()->prepare([ $job{windows} ]), { records => [], failures => [] }, 'nothing to prepare');
		throws_code(sub { $images->()->prepare($_) }, 'actions.invalid_arguments', undef, 'instances must be a list: ' . ($_ // 'undef'))
			for 'jobs', undef;
	};

	subtest 'prepare_job' => sub {
		my $docker = Local::ImageDocker->new(present => { 'perl:5.40' => 1 });
		my $object = $images->(docker => $docker);
		my $job = { %{ $job{test} }, services => { db => 'postgres:16' },
			steps => [ { uses => 'docker://postgres:16' }, { uses => "docker://$later" } ] };
		my $result = $object->prepare_job($job, $context->($job));
		returns_ok($result, { type => 'hashref' }, 'a hash reference');
		is_deeply($result, { image => 'perl:5.40', deferred => [ { expression => $later, source => $source->{later}, error => $unknown } ] },
			"the job's image, and the images only a step can decide");
		is_deeply($docker->{pulls}, [ 'postgres:16' ], 'each image prepared once');
		my $resolved = $object->prepare_job({ %{$job}, steps => [ { uses => "docker://$later" } ] },
			{ %{ $context->($job) }, steps => { a => { outputs => { t => '2' } } } });
		is_deeply($resolved->{deferred}, [], 'with the step output known, nothing is deferred');
		is_deeply($docker->{pulls}, [ 'postgres:16', 'busybox:2' ], 'and its image is prepared');

		my $needs = q{perl:${{ needs.a.outputs.v }}};
		throws_code(sub { $object->prepare_job({ base_id => 'n', 'runs-on' => 'ubuntu-latest', container => { image => $needs },
			steps => [] }, {}) }, 'runner.image.unresolved',
			qq{cannot resolve the image '$needs', needed by job 'n': unable to resolve '\${{ needs.a.outputs.v }}' from the values available},
			'a job image that cannot be resolved');
		throws_code(sub { $object->prepare_job({ base_id => 'n', 'runs-on' => 'ubuntu-latest', services => { db => '${{ env.EMPTY }}' },
			steps => [] }, $context->({})) }, 'runner.image.unresolved',
			q{cannot resolve the image '${{ env.EMPTY }}', needed by service 'db' of job 'n': the image name is empty}, 'or a service image');
		my $failing = $images->(docker => Local::ImageDocker->new(fail => { 'redis:7' => 'no such image' }));
		throws_code(sub { $failing->prepare_job({ base_id => 'f', 'runs-on' => 'ubuntu-latest', services => { cache => 'redis:7' },
			steps => [] }, {}) }, 'runner.image.unprepared', q{cannot prepare the image 'redis:7', needed by service 'cache' of job 'f': no such image},
			'an image that cannot be prepared');
		keeps_globals(sub { $object->prepare_job($job, $context->($job)) }, 'prepare_job');
	};

	subtest 'probe' => sub {
		my $object = $images->();
		my $own = { base_id => 'o', 'runs-on' => 'ubuntu-latest', container => { image => 'perl:${{ github.sha }}' }, steps => [] };
		is_returned($object->probe([ $job{windows}, $own ]), { type => 'string', min => 1 }, 'perl:abc',
			'the image of the first job that runs here, resolved');
		is($object->probe([ { base_id => 'u', 'runs-on' => 'ubuntu-22.04', steps => [] } ]), 'ubuntu:22.04', "a job's runner image");
		my $unknown_job = { base_id => 'n', 'runs-on' => 'ubuntu-latest', container => { image => 'x:${{ needs.a.outputs.v }}' }, steps => [] };
		is($object->probe([ $unknown_job, $own ]), 'perl:abc', 'an image that cannot be named yet is passed over');
		is($object->probe([ $job{windows}, $unknown_job ]), 'alpine:3.20', 'with none, alpine:3.20');
		is($images->(image => 'debian:12')->probe([]), 'debian:12', 'or the configured image');
		keeps_globals(sub { $object->probe([ $unknown_job, $own ]) }, 'probe');
	};

	subtest 'ensure' => sub {
		my $docker = Local::ImageDocker->new(present => { 'perl:5.40' => 1 });
		my $object = $images->(docker => $docker, quiet => 0);
		is_returned($object->ensure('perl:5.40'), { type => 'boolean' }, 1, 'a present image');
		my $text = output_of(stdout => sub { is($object->ensure('alpine'), 1, 'an absent one') });
		is($text, "Pulling image alpine...\n", 'is pulled, saying so');
		$object->ensure('alpine');
		is_deeply($docker->{pulls}, [ 'alpine' ], 'once per run');
		is_deeply($object->pulled, [ 'alpine' ], 'and recorded');

		my $fresh = $images->(docker => $docker, pull => 1);
		$fresh->ensure('perl:5.40') for 1 .. 2;
		is_deeply($docker->{pulls}, [ 'alpine', 'perl:5.40' ], '--pull refreshes a present image once');
		is_deeply($fresh->pulled, [], 'which is not new');
		is($images->(docker => $docker, dry_run => 1)->ensure('never'), 1, 'a dry run pulls nothing');
		is_deeply($docker->{pulls}, [ 'alpine', 'perl:5.40' ], 'indeed');
		throws_code(sub { $images->(docker => $docker, no_pull => 1)->ensure('absent') }, 'runner.image.not_local',
			q{Docker image 'absent' is not available locally (--no-pull)}, '--no-pull and an absent image');
		ok($images->(docker => $docker, no_pull => 1)->ensure('perl:5.40'), '--no-pull and a present image');
		keeps_globals(sub { $images->(docker => Local::ImageDocker->new)->ensure('x') }, 'ensure');
	};

	subtest 'note_pulled, pulled and remember' => sub {
		my $object = $images->();
		is_returned($object->pulled, { type => 'arrayref' }, [], 'nothing pulled yet');
		is($object->note_pulled('b', undef, '', 'a'), $object, 'note_pulled returns the object');
		is_deeply($object->pulled, [ 'a', 'b' ], 'pulled lists what was noted, sorted, nothing empty');

		my $file = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
		is($object->remember($file), $object, 'remember returns the object');
		is_deeply([ map { [ $_->{image}, $_->{pulls} ] } @{ App::Actions::Cache->new(file => $file)->entries } ], [ [ 'a', 1 ], [ 'b', 1 ] ],
			'and records the pulls in the cache');
		my $other = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
		$images->()->remember($other);
		$images->(dry_run => 1)->note_pulled('x')->remember($other);
		ok(!-e $other, 'nothing pulled, or a dry run, writes nothing');

		my $using = $images->();
		is_returned($using->used, { type => 'arrayref' }, [], 'nothing used yet');
		is($using->note_used('b', undef, '', 'mine'), $using, 'note_used returns the object');
		is_deeply($using->used, [ 'b', 'mine' ], 'used lists what was noted, sorted, nothing empty');
		my $reused = App::Actions::Cache->new(file => File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json'));
		$reused->remember('b');
		$reused->load->{images}{b}{last_used} = 1;
		$reused->save;
		$using->remember($reused->file);
		my $after = App::Actions::Cache->new(file => $reused->file)->entries;
		is_deeply([ map { [ $_->{image}, $_->{pulls} ] } @{$after} ], [ [ 'b', 1 ] ],
			'remember: a recorded image used again keeps its count, and an unrecorded one stays out');
		cmp_ok(abs($after->[0]{last_used} - time), '<=', $config{time_limit}, 'but its last use is now');

		my $blocked = write_file('file', '');
		my $bad = File::Spec->catfile($blocked, 'cache.json');
		my @said;
		my $verbose = $images->(verbose => 1, logger => collecting_logger(\@said))->note_pulled('a');
		is($verbose->remember($bad), $verbose, 'a cache that cannot be written does not fail');
		is(scalar @said, 1, 'with verbose it is one warning');
		like($said[0] // '', qr/\Aaction-run: could not update the image cache: cannot write a new cache file in '\Q$blocked\E': \S[^\n]*\z/,
			'saying why, without a source line');
		@said = ();
		$images->(logger => collecting_logger(\@said))->note_pulled('a')->remember($bad);
		is_deeply(\@said, [], 'without verbose, nothing');
		keeps_globals(sub { $images->()->note_pulled('a')->remember($bad) }, 'remember', io => 1);
	};

	subtest 'failure_message' => sub {
		is_returned($images->()->failure_message({ image => 'x:1', source => "job 'a'", error => 'denied' }), { type => 'string' },
			q{cannot prepare the image 'x:1', needed by job 'a': denied}, 'the image, what needed it, and why');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Containers
# ---------------------------------------------------------------------------

# A Docker object that keeps every call and answers from a table: a value, a
# list (an array reference), or a code reference given the call's arguments.
# What the table leaves out gets the answer of a daemon where all is well.
{
	package Local::ContainerDocker;

	my %healthy = (
		network_create => 0, network_remove => 0, container_start => 0, container_start_captured => [ "id\n", 0 ],
		container_running => 1, container_status => 'running', container_restart_count => 0, container_log_text => '',
		container_exit_code => undef, container_remove => 0, capture_silent => [ '', 0 ], run => 0,
	);

	sub new {
		my ($class, %answer) = @_;

		return bless { calls => [], answer => { %healthy, %answer } }, $class;
	}

	for my $method (keys %healthy) {
		no strict 'refs';
		*{$method} = sub {
			my ($self, @args) = @_;

			push @{ $self->{calls} }, [ $method, @args ];
			my $answer = $self->{answer}{$method};
			return ref $answer eq 'CODE' ? $answer->(@args) : ref $answer eq 'ARRAY' ? @{$answer} : $answer;
		};
	}

	# The calls made to one method, without the method's name.
	sub calls_to {
		my ($self, $method) = @_;

		return [ map { [ @{$_}[ 1 .. $#{$_} ] ] } grep { $_->[0] eq $method } @{ $self->{calls} } ];
	}
}

subtest 'App::Actions::Runner::Containers' => sub {
	my $project = tempdir(CLEANUP => 1);
	my $containers = sub {
		my ($docker, @options) = @_;

		return App::Actions::Runner::Containers->new(docker => $docker || Local::ContainerDocker->new,
			expression => App::Actions::Expression->new, project_dir => $project, run_id => 'run-1234567890', @options);
	};
	my $context = { env => { V => '16', SECRET => 'pw' }, secrets => { PW => 'pw' } };
	my $job = { base_id => 'build', matrix_index => 1 };
	# A docker argument list as text: an environment variable reads as NAME=VALUE.
	my $words = sub { return [ map { "$_" } @{ $_[0] } ] };

	subtest 'new' => sub {
		returns_ok($containers->(), { type => 'object', isa => 'App::Actions::Runner::Containers' }, 'new');
		my %need = (docker => Local::ContainerDocker->new, expression => App::Actions::Expression->new, project_dir => $project,
			run_id => 'r');
		for my $missing (sort keys %need) {
			my %given = %need;
			delete $given{$missing};
			throws_code(sub { App::Actions::Runner::Containers->new(%given) }, 'actions.invalid_arguments', undef, "$missing is required");
		}
		throws_code(sub { App::Actions::Runner::Containers->new(%need, %{$_}) }, 'actions.invalid_arguments', undef,
			'refused: ' . join(',', keys %{$_})) for { run_id => '' }, { logger => 'NULL' }, { docker => bless({}, 'Local::Nothing') };
	};

	subtest 'name' => sub {
		my $object = $containers->();
		is_returned($object->name('svc', $job, 'pg'), { type => 'string', min => 1, max => 63 }, 'action-run-34567890-1-svc-build-1-pg',
			'run, counter, kind, job, index and suffix');
		is($object->name('net', { base_id => 'a/b c' }), 'action-run-34567890-2-net-a-b-c-0', 'unsafe characters replaced; no index is 0');
		my $long = $object->name('svc', { base_id => 'x' x 40, matrix_index => 3 }, 'y' x 40);
		is(length $long, 63, 'cut to 63 characters');
		like($long, qr/\Aaction-run-34567890-3-svc-x{20}-3-y+\z/, 'with the job id cut to 20');
		is($object->name('job', $job, ''), 'action-run-34567890-4-job-build-1', 'an empty suffix adds nothing');
		keeps_globals(sub { $object->name('svc', $job) }, 'name');
	};

	subtest 'create_network' => sub {
		my $docker = Local::ContainerDocker->new;
		my $object = $containers->($docker);
		my $network = $object->create_network($job);
		is_returned($network, { type => 'string', min => 1 }, 'action-run-34567890-1-net-build-1', 'the name');
		is_deeply($docker->calls_to('network_create'), [ [ $network ] ], 'is created');
		is_deeply($object->remaining, { containers => [], networks => [ $network ] }, 'and remembered');
		my $failing = $containers->(Local::ContainerDocker->new(network_create => 3));
		throws_code(sub { $failing->create_network($job) }, 'runner.network_failed',
			q{Failed to create Docker network 'action-run-34567890-1-net-build-1' (exit 3)}, 'a network that cannot be made');
		is_deeply($failing->remaining->{networks}, [], 'is not remembered');
	};

	subtest 'start_services' => sub {
		my $docker = Local::ContainerDocker->new;
		my @said;
		my $object = $containers->($docker, platform => 'linux/amd64', user => '1000', logger => collecting_logger(\@said));
		my $service_job = { %{$job}, services => {
			db => { image => 'postgres:${{ env.V }}', options => '--health-cmd "pg_isready -U x"', volumes => '/data:/var/lib/pg',
				ports => [ '5432:5432' ], env => { PASSWORD => '${{ secrets.PW }}' }, credentials => { username => 'u' } },
			cache => 'redis:7',
		} };
		my @started = ('earlier');
		my $services = $object->start_services($service_job, 'net', $context, \@started);
		returns_ok($services, { type => 'arrayref' }, 'an array reference');
		my ($cache, $db) = map { "action-run-34567890-$_-build-1-" } '1-svc', '2-svc';
		is_deeply($services, [ [ 'cache', "${cache}cache" ], [ 'db', "${db}db" ] ], 'id and container name, in id order');
		is_deeply(\@started, [ 'earlier', "${cache}cache", "${db}db" ], 'each added to the started list');
		is_deeply($object->remaining->{containers}, [ "${cache}cache", "${db}db" ], 'and remembered');
		my $starts = $docker->calls_to('container_start');
		is_deeply($words->($starts->[1]), [ '--platform', 'linux/amd64', '--health-cmd', 'pg_isready -U x', '--name', "${db}db",
			'--network', 'net', '--network-alias', 'db', '--user', '1000', '-v', '/data:/var/lib/pg', '-e', 'PASSWORD=pw',
			'-p', '5432:5432', 'postgres:16' ], 'the options, name, alias, user, volumes, environment, ports and image');
		is_deeply($words->($starts->[0]), [ '--platform', 'linux/amd64', '--name', "${cache}cache", '--network', 'net',
			'--network-alias', 'cache', '--user', '1000', 'redis:7' ], 'an image name alone is a service');
		is_deeply(\@said, [ q{action-run: service 'db' credentials are not supported; using the local Docker login} ],
			'credentials are warned about');
		@said = ();
		$containers->(undef, quiet => 1, logger => collecting_logger(\@said))->start_services($service_job, 'net', $context, []);
		is_deeply(\@said, [], 'unless quiet');
		is_deeply($containers->()->start_services({ %{$job} }, 'net', $context, []), [], 'no services');

		my $explained = output_of(stdout => sub {
			$containers->(undef, explain => 1)->start_services({ %{$job}, services => {
				a => { image => 'a:1', options => '--entrypoint=/bin/a --entrypoint /bin/later' },
				b => { image => 'b:1', options => '--entrypoint /bin/b' },
				c => { image => 'c:1' },
			} }, 'net', $context, []);
		});
		is($explained, join('', map {
			my ($id, $n, $entrypoint) = @{$_};
			"==> Service '$id' of job 'build'\n    container  action-run-34567890-$n-svc-build-1-$id\n    image      $id:1\n"
				. "    entrypoint $entrypoint\n    command    (the image's own)\n";
		} [ 'a', 1, '/bin/a' ], [ 'b', 2, '/bin/b' ], [ 'c', 3, "(the image's own)" ]), 'explain says what each service runs');
		keeps_globals(sub { $containers->()->start_services($service_job, 'net', $context, []) }, 'start_services');
	};

	subtest 'start_services: what fails' => sub {
		my $start = sub {
			my ($services, %answer) = @_;
			my $object = $containers->(Local::ContainerDocker->new(%answer));
			my @started;
			my $error = caught { $object->start_services({ %{$job}, services => $services }, 'net', $context, \@started) };
			return ($error, \@started, $object);
		};
		throws_code(sub { die +($start->({ db => [ 'postgres' ] }))[0] }, 'runner.service.not_mapping', q{Service 'db' must be a mapping},
			'a list is not a service');
		for my $case ([ 'a mapping without one', {} ], [ 'an empty name', { image => '' } ], [ 'nothing at all', undef ]) {
			throws_code(sub { die +($start->({ db => $case->[1] }))[0] }, 'runner.service.no_image', q{Service 'db' has no image},
				"no image: $case->[0]");
		}
		throws_code(sub { die +($start->({ db => { image => 'p', options => '--env "A=${{ env.SECRET }}' } }))[0] }, 'runner.options_invalid',
			q{Unable to read the container options '--env "A=${{ env.SECRET }}': a quote is not closed},
			'options with an unclosed quote, quoted as written');

		my ($error, $started, $object) = $start->({ db => 'postgres' }, container_start => 125);
		throws_code(sub { die $error }, 'runner.service.start_failed', q{Failed to start service 'db' (exit 125)},
			'a service the daemon will not start');
		is_deeply($started, [ 'action-run-34567890-1-svc-build-1-db' ], 'is still in the started list');
		is_deeply($object->remaining->{containers}, $started, 'and remembered for removal');

		($error) = $start->({ db => 'postgres' }, container_running => 0, container_exit_code => 1,
			container_log_text => "starting\r\nFATAL: no password\r\n\n  \n");
		my $stopped = throws_code(sub { die $error }, 'runner.container.stopped',
			"Service 'db' did not stay running (exit 1); its last output was:\n  starting\n  FATAL: no password",
			'a service that stopped, with its last output');
		is("$stopped", $stopped->message . "\n", 'which reads as its message, without a source line');
		($error) = $start->({ db => 'postgres' }, container_running => 0);
		throws_code(sub { die $error }, 'runner.container.stopped',
			q{Service 'db' did not stay running (its exit status could not be read); it printed nothing}, 'one that said nothing');
		($error) = $start->({ db => 'postgres' }, container_status => 'restarting', container_restart_count => 3, container_log_text => "oops\n");
		throws_code(sub { die $error }, 'runner.container.restarting',
			"Service 'db' is restarting (restart count 3); its last output was:\n  oops", 'a service that keeps restarting');
	};

	subtest 'check_services' => sub {
		my $check = sub { $containers->(Local::ContainerDocker->new(@_))->check_services([ [ 'db', 'c1' ] ]) };
		my $object = $containers->();
		is_returned($object->check_services([ [ 'db', 'c1' ] ]), { type => 'object', isa => 'App::Actions::Runner::Containers' }, $object,
			'services that stay up');
		ok($check->(container_status => undef, container_restart_count => undef), 'or say nothing');
		throws_code(sub { $check->(container_restart_count => 2) }, 'runner.container.restarting',
			q{Service 'db' is restarting (restart count 2); it printed nothing}, 'running, but restarted');
		throws_code(sub { $check->(container_status => 'dead', container_restart_count => undef, container_log_text => "gone\n") },
			'runner.container.restarting', "Service 'db' is dead (its restart count could not be read); its last output was:\n  gone",
			'dead, with no count');
		throws_code(sub { $check->(container_status => 'restarting') }, 'runner.container.restarting',
			q{Service 'db' is restarting; it printed nothing}, 'restarting, not yet counted');
		keeps_globals(sub { $object->check_services([ [ 'db', 'c1' ] ]) }, 'check_services');
	};

	subtest 'start_job' => sub {
		my $docker = Local::ContainerDocker->new;
		my $object = $containers->($docker, user => '0');
		my $spec_job = { base_id => '_my.job_', matrix_index => 0, container => { image => 'x', options => '--cpus 2',
			volumes => [ '/a:/a' ], ports => '8080:80' } };
		my $name = $object->start_job($spec_job, 'net', { A => '1' }, $context, 'perl:5.40', '/tmp/runner');
		is_returned($name, { type => 'string', min => 1 }, 'action-run-34567890-1-job-_my.job_-0', 'the container name');
		is_deeply($words->($docker->calls_to('container_start_captured')->[0]), [ '--cpus', '2', '--name', $name, '--network', 'net',
			'--hostname', 'my.job', '--user', '0', '-v', "$project:/github/workspace", '-v', '/tmp/runner:/github/actions-runner',
			'-v', '/a:/a', '-p', '8080:80', '-w', '/github/workspace', '-e', 'A=1', '--entrypoint', '/bin/sh', 'perl:5.40',
			'-c', 'while :; do sleep 3600; done' ], 'the project, runner directory, environment and an idle shell');
		is_deeply($docker->calls_to('container_remove'), [], 'a container that starts is kept');
		my $plain = $containers->()->start_job({ base_id => '--', matrix_index => 0 }, 'net', {}, $context, 'img', '/r');
		ok($plain, 'a job with no container mapping');

		my $explained = output_of(stdout => sub { $containers->(undef, explain => 1)->start_job($job, 'net', {}, $context, 'img', '/r') });
		is($explained, "==> Job 'build'\n    container  action-run-34567890-1-job-build-1\n    image      img\n    entrypoint /bin/sh\n"
			. "    command    -c 'while :; do sleep 3600; done'\n", 'explain says what the job container runs');
		keeps_globals(sub { $containers->()->start_job($job, 'net', {}, $context, 'img', '/r') }, 'start_job');
	};

	subtest 'start_job: what fails' => sub {
		my $container = 'action-run-34567890-1-job-build-1';
		my $refuse = sub {
			my (%answer) = @_;
			my $docker = Local::ContainerDocker->new(%answer);
			my $error = caught { $containers->($docker)->start_job($job, 'net', {}, $context, 'perl:5.40', '/r') };
			is_deeply($docker->calls_to('container_remove'), [ [ $container ] ], 'the container is removed');
			die $error;
		};
		my $start_failed = "Job container '$container' could not be started (exit 125)";
		for my $case (
			[ "Error: No such image: perl:5.40\n", "; at fault: the image 'perl:5.40'", 'an image the daemon cannot find' ],
			[ "Bind for 0.0.0.0:80 failed: port is already allocated\r\n", '; at fault: the published port', 'a port in use' ],
			[ qq{exec: "/bin/sh": stat /bin/sh: no such file or directory\n}, q{; at fault: the entrypoint '/bin/sh'},
				'an image without a shell' ],
			[ "something else\n", '', 'a complaint that names nothing' ],
		) {
			my ($said, $fault, $name) = @{$case};
			(my $quoted = $said) =~ s/\r?\n\z//;
			throws_code(sub { $refuse->(container_start_captured => [ $said, 125 ]) }, 'runner.container.start_failed',
				"$start_failed$fault; the daemon said:\n  $quoted", $name);
		}
		throws_code(sub { $refuse->(container_start_captured => [ '', 125 ]) }, 'runner.container.start_failed',
			"$start_failed; the daemon said nothing", 'a daemon that says nothing');
		throws_code(sub { $refuse->(container_running => 0, container_exit_code => 127, container_log_text => "sh: not found\n") },
			'runner.container.stopped', "Job container '$container' did not stay running (exit 127); its last output was:\n  sh: not found",
			'a container that stops at once');
		throws_code(sub { $containers->()->start_job({ %{$job}, container => { options => q{--label 'x} } }, 'net', {}, $context, 'i', '/r') },
			'runner.options_invalid', q{Unable to read the container options '--label 'x': a quote is not closed}, 'unreadable options');
	};

	subtest 'inspect' => sub {
		my $answers = sub {
			my (%has) = @_;
			return capture_silent => sub {
				return ($has{path}, defined $has{path} ? 0 : 1) if grep { /PATH/ } @_;
				return ('', $has{ $_[-1] } ? 0 : 1);
			};
		};
		my $facts = $containers->(Local::ContainerDocker->new($answers->(path => '/usr/bin', bash => 1)))->inspect('c1');
		returns_ok($facts, { type => 'hashref', schema => { path => { type => 'string', min => 1 }, has_bash => { type => 'boolean' },
			has_node => { type => 'boolean' } } }, 'the documented shape');
		is_deeply($facts, { path => '/github/actions-runner/bin:/github/actions-runner/aptbin:/usr/bin', has_bash => 1, has_node => 0 },
			'the shims in front of PATH, and which commands it has');
		is_deeply($containers->(Local::ContainerDocker->new($answers->(node => 1, sudo => 1)))->inspect('c1'), {
			path => '/github/actions-runner/aptbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', has_bash => 0,
			has_node => 1 }, 'a container that will not say its PATH, and has sudo of its own');
		is($containers->(Local::ContainerDocker->new($answers->(path => '/bin')), user => 'me')->inspect('c1')->{path},
			'/github/actions-runner/aptbin:/bin', 'a user other than root gets no sudo shim');
		keeps_globals(sub { $containers->()->inspect('c1') }, 'inspect');
	};

	subtest 'run_action' => sub {
		my $docker = Local::ContainerDocker->new(run => 3);
		my $object = $containers->($docker, platform => 'linux/arm64', user => 'me');
		my %args = (image => 'alpine:3', network => 'net', workdir => '/github/workspace', temp_path => '/r', env => { B => 2 },
			title => 'Action');
		is_returned($object->run_action(%args, entrypoint => '/bin/echo', arguments => [ 'a', 'b' ]), { type => 'integer' }, 3,
			"the container's exit status");
		is_deeply($words->($docker->calls_to('run')->[0]), [ 'run', '--rm', '--platform', 'linux/arm64', '--network', 'net',
			'-v', "$project:/github/workspace", '-v', '/r:/github/actions-runner', '-w', '/github/workspace', '--user', 'me',
			'--entrypoint', '/bin/echo', '-e', 'B=2', 'alpine:3', 'a', 'b' ], 'a container of its own, removed when it exits');
		$object->run_action(%args);
		is_deeply($words->($docker->calls_to('run')->[1]), [ 'run', '--rm', '--platform', 'linux/arm64', '--network', 'net',
			'-v', "$project:/github/workspace", '-v', '/r:/github/actions-runner', '-w', '/github/workspace', '--user', 'me',
			'-e', 'B=2', 'alpine:3' ], "without an entrypoint or arguments, the image's own");
		is(output_of(stdout => sub { $containers->(undef, explain => 1)->run_action(%args, arguments => [ 'x' ]) }),
			"==> Action\n    image      alpine:3\n    entrypoint (the image's own)\n    command    x\n", 'explain says what it runs');
		for my $missing (qw(image network workdir temp_path env title)) {
			my %given = %args;
			delete $given{$missing};
			throws_code(sub { $object->run_action(%given) }, 'actions.invalid_arguments', undef, "$missing is required");
		}
		keeps_globals(sub { $object->run_action(%args) }, 'run_action');
	};

	subtest 'cleanup_job, remaining and remove_all' => sub {
		my $docker = Local::ContainerDocker->new;
		my $object = $containers->($docker);
		my $network = $object->create_network($job);
		my @started;
		$object->start_services({ %{$job}, services => { a => 'a', b => 'b' } }, $network, $context, \@started);
		my $other = $object->create_network($job);
		$object->start_services({ %{$job}, services => { c => 'c' } }, $other, $context, []);
		my $remaining = $object->remaining;
		returns_ok($remaining, { type => 'hashref' }, 'remaining is a hash reference');
		is_deeply($remaining, { containers => [ @started, 'action-run-34567890-5-svc-build-1-c' ], networks => [ $network, $other ] },
			'every container and network not yet removed');
		push @{ $remaining->{containers} }, 'not mine';
		is(scalar @{ $object->remaining->{containers} }, 3, 'a copy');

		is_returned($object->cleanup_job($network, \@started), { type => 'object', isa => 'App::Actions::Runner::Containers' }, $object,
			'cleanup_job returns the object');
		is_deeply($docker->calls_to('container_remove'), [ [ $started[1] ], [ $started[0] ] ], 'its containers removed, newest first');
		is_deeply($docker->calls_to('network_remove'), [ [ $network ] ], 'then its network');
		is_deeply($object->remaining, { containers => [ 'action-run-34567890-5-svc-build-1-c' ], networks => [ $other ] },
			'and forgotten');

		is($object->remove_all, $object, 'remove_all returns the object');
		is_deeply([ (map { $_->[1] } grep { $_->[0] =~ /remove/ } @{ $docker->{calls} })[ 3, 4 ] ],
			[ 'action-run-34567890-5-svc-build-1-c', $other ], 'it removes the rest');
		is_deeply($object->remaining, { containers => [], networks => [] }, 'leaving nothing');

		my $keeper_docker = Local::ContainerDocker->new;
		my $keeper = $containers->($keeper_docker, keep => 1);
		my $kept = $keeper->create_network($job);
		$keeper->cleanup_job($kept, []);
		is_deeply($keeper->remaining->{networks}, [ $kept ], 'a run that keeps its resources removes nothing when a job ends');
		is_deeply($keeper_docker->calls_to('network_remove'), [], 'indeed');
		keeps_globals(sub { $containers->()->remove_all }, 'remove_all');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner::Steps
# ---------------------------------------------------------------------------

# A job container that runs a tiny language instead of a shell, so a step can
# do what a real one does to its step files.  Each line of a script (or of a
# JavaScript action's file) is one command:
#   out K=V | env K=V | state K=V   append the line to GITHUB_OUTPUT/ENV/STATE
#   raw TEXT                        append TEXT to GITHUB_OUTPUT as it is
#   path DIR | summary TEXT         append to GITHUB_PATH / GITHUB_STEP_SUMMARY
#   say TEXT                        print TEXT
#   exit N                          stop with status N
#   die TEXT                        fail the docker call itself
# Every call is kept, with its working directory, environment and command.
{
	package Local::StepDocker;

	sub new {
		my ($class, %options) = @_;

		return bless { execs => [], %options }, $class;
	}

	sub redact {
		my ($self, $text) = @_;

		$text =~ s/s3cret/***/g;
		return $text;
	}

	# Where a path inside the container is on the host.
	sub host {
		my ($self, $path) = @_;

		$path =~ s{\A/github/actions-runner}{$self->{temp}};
		$path =~ s{\A/github/workspace}{$self->{project}};
		return $path;
	}

	sub container_exec {
		my ($self, @args) = @_;

		my %exec = (env => {});
		(undef, $exec{workdir}) = splice @args, 0, 2;
		while (@args && $args[0] eq '-e') {
			my $variable = $args[1];
			$exec{env}{ $variable->name } = $variable->value;
			splice @args, 0, 2;
		}
		$exec{container} = shift @args;
		$exec{command} = [ @args ];
		push @{ $self->{execs} }, \%exec;

		my $program = $args[0] eq 'node' ? $args[1] : ($args[2] =~ m{'(/github/actions-runner/scripts/[^']+)'})[0];
		open my $in, '<', $self->host($program) or die "cannot read $program: $!";
		my @lines = <$in>;
		close $in;
		my %file = (out => 'GITHUB_OUTPUT', raw => 'GITHUB_OUTPUT', env => 'GITHUB_ENV', state => 'GITHUB_STATE',
			path => 'GITHUB_PATH', summary => 'GITHUB_STEP_SUMMARY');
		for my $line (@lines) {
			chomp $line;
			my ($verb, $rest) = split / /, $line, 2;
			$rest = '' unless defined $rest;
			return $rest + 0 if $verb eq 'exit';
			die "$rest\n" if $verb eq 'die';
			print "$rest\n" if $verb eq 'say';
			next unless $file{$verb};
			open my $out, '>>', $self->host($exec{env}{ $file{$verb} }) or die "cannot append: $!";
			print {$out} "$rest\n";
			close $out;
		}
		return 0;
	}
}

# The collaborators a step hands its work to: the image preparer, the
# container manager and the workflow's defaults.
{
	package Local::StepImages;

	sub new { return bless { ensured => [] }, $_[0] }
	sub ensure { push @{ $_[0]{ensured} }, $_[1]; return 1 }

	package Local::StepContainers;

	sub new { my ($class, %options) = @_; return bless { runs => [], status => 0, %options }, $class }
	sub run_action { my ($self, %args) = @_; push @{ $self->{runs} }, \%args; return $self->{status} }

	package Local::StepWorkflow;

	sub new { my ($class, $defaults) = @_; return bless { defaults => $defaults || {} }, $class }
	sub defaults { return $_[0]{defaults} }
}

subtest 'App::Actions::Runner::Steps' => sub {
	# A project with the local actions the steps use.
	my $project = tempdir(CLEANUP => 1);
	my $action = sub {
		my ($dir, $yaml, %files) = @_;
		my $path = File::Spec->catdir($project, $dir);
		make_path($path);
		write_file('action.yml', $yaml, $path);
		write_file($_, $files{$_}, $path) for keys %files;
	};
	$action->('greet', <<'YAML');
name: greet
inputs:
  who:
    default: world
outputs:
  greeting:
    value: ${{ steps.g.outputs.text }}
runs:
  using: composite
  steps:
    - id: g
      run: |
        out text=hello ${{ inputs.who }}
        env FROM_ACTION=1
YAML
	$action->('broken', "name: broken\nruns:\n  using: composite\n  steps:\n    - run: exit 4\n");
	$action->('loop', "name: loop\nruns:\n  using: composite\n  steps:\n    - uses: ./loop\n");
	$action->('image', "name: image\nruns:\n  using: docker\n  image: Dockerfile\n");
	my $js_yaml = <<'YAML';
name: js
inputs:
  perl-version:
    default: '5.40'
runs:
  using: node20
  pre: pre.js
  main: main.js
  post: post.js
YAML
	$action->('js', $js_yaml, 'pre.js' => "state seen=pre\nsay pre ran\n", 'main.js' => "say main ran\nout result=done\n",
		'post.js' => "say post ran\n", 'bad.js' => "exit 6\n", 'boom.js' => "die it blew up\n");

	my %job_env = (JOB => 'job');
	my $harness = sub {
		my (%options) = @_;
		my $steps = delete $options{steps};
		my $defaults = delete $options{defaults};
		my $temp = tempdir(CLEANUP => 1);
		make_path(map { File::Spec->catdir($temp, $_) } grep { !$options{"no_$_"} } qw(scripts env output path summary));
		delete @options{qw(no_scripts no_env)};
		my $docker = Local::StepDocker->new(temp => $temp, project => $project);
		my @logged;
		my $object = App::Actions::Runner::Steps->new(
			expression => App::Actions::Expression->new, docker => $docker, images => Local::StepImages->new,
			containers => Local::StepContainers->new(%{ delete $options{containers} || {} }),
			workflow => Local::StepWorkflow->new($defaults), project_dir => $project, temp_path => $temp,
			job => { base_id => 'build', steps => $steps, %{ delete $options{job} || {} } },
			container => 'job-container', network => 'net', facts => { path => '/usr/bin', has_bash => 1, has_node => 1 },
			job_env => { %job_env }, context => { github => { repository => 'o/r' }, secrets => { TOKEN => 's3cret' }, env => {} },
			logger => collecting_logger(\@logged), %options,
		);
		my $result;
		my $out = main::output_of(stdout => sub { $result = $object->run });
		return { result => $result, out => $out, logged => \@logged, docker => $docker, object => $object, temp => $temp };
	};

	subtest 'new' => sub {
		my $run = $harness->(steps => []);
		returns_ok($run->{object}, { type => 'object', isa => 'App::Actions::Runner::Steps' }, 'new');
		my %need = (expression => App::Actions::Expression->new, docker => Local::StepDocker->new, images => Local::StepImages->new,
			containers => Local::StepContainers->new, workflow => Local::StepWorkflow->new, project_dir => $project, temp_path => '/t',
			job => {}, container => 'c', network => 'n', facts => {}, job_env => {}, context => {});
		for my $missing (sort keys %need) {
			my %given = %need;
			delete $given{$missing};
			throws_code(sub { App::Actions::Runner::Steps->new(%given) }, 'actions.invalid_arguments', undef, "$missing is required");
		}
		throws_code(sub { App::Actions::Runner::Steps->new(%need, %{$_}) }, 'actions.invalid_arguments', undef,
			'refused: ' . join(',', keys %{$_})) for { container => '' }, { facts => [] }, { logger => 'NULL' }, { share_files => 'x' };
	};

	subtest 'run: steps that pass values on' => sub {
		my $run = $harness->(steps => [
			{ id => 'a', name => 'First ${{ env.GREETING }}', env => { GREETING => 'hello' },
				run => "out answer=42\nraw story<<EOT\nraw one\nraw two\nraw EOT\nenv EXPORTED=yes\npath /opt/tool\nsummary ## Done" },
			{ run => 'say ${{ steps.a.outputs.answer }} ${{ env.EXPORTED }}' },
			{ name => 'story', run => 'say ${{ toJSON(steps.a.outputs.story) }}' },
		]);
		my $result = $run->{result};
		returns_ok($result, { type => 'hashref', schema => { result => { type => 'string', memberof => [ 'success', 'failure' ] },
			env => { type => 'hashref' } } }, 'the documented shape');
		is_deeply($result, { result => 'success', env => { JOB => 'job', EXPORTED => 'yes' } }, 'success, and the exported variable');
		is($run->{out}, "--- Step: First hello\n--- Step summary ---\n## Done\n\n--- Step: say 42 yes\n42 yes\n--- Step: story\n\"one\\ntwo\"\n",
			'each step named, its summary shown, its output, and a multi-line output read whole');
		my ($first, $second) = @{ $run->{docker}{execs} };
		is($first->{workdir}, '/github/workspace', 'a step runs in the workspace');
		is_deeply($first->{command}, [ 'sh', '-c', q{bash -e '/github/actions-runner/scripts/step-1.sh'} ], 'with bash -e by default');
		is($first->{container}, 'job-container', 'in the job container');
		is_deeply([ @{ $first->{env} }{qw(JOB GREETING GITHUB_ACTION GITHUB_ACTION_PATH PATH GITHUB_OUTPUT)} ],
			[ 'job', 'hello', 'a', '', '/usr/bin', '/github/actions-runner/output/step-1.out' ], 'with its environment and step files');
		is($second->{env}{PATH}, '/opt/tool:/usr/bin', 'a PATH addition reaches the next step');
		is($second->{env}{GITHUB_ACTION}, '__step_2', 'a step without an id has one of its own');
		SKIP: {
			skip 'file modes are not Unix ones', 1 if $^O eq 'MSWin32';
			is((stat File::Spec->catfile($run->{temp}, 'scripts', 'step-1.sh'))[2] & 07777, 0600, 'the script is private');
		}
		opendir my $dir, File::Spec->catdir($run->{temp}, 'output') or die $!;
		is_deeply([ grep { !/\A\./ } readdir $dir ], [], 'the step files are removed once read');
		is_deeply($run->{logged}, [], 'nothing logged');
		is(output_of(stdout => sub { $harness->(steps => [ { run => 'say hi' } ], quiet => 1) }), '', 'a quiet run prints no progress');
		keeps_globals(sub { $harness->(steps => [ { run => 'exit 1' }, { run => 'say x', if => '${{ (' } ]) }, 'run', io => 1);
	};

	subtest 'run: failures, conditions and continue-on-error' => sub {
		my $run = $harness->(steps => [
			{ id => 'f', run => 'exit 3' },
			{ id => 'next', run => 'say not run' },
			{ run => 'say failed: ${{ steps.f.outcome }}', if => 'failure()' },
			{ id => 'c', run => 'exit 1', if => 'always()', 'continue-on-error' => 'true' },
			{ run => 'say ${{ steps.c.outcome }}/${{ steps.c.conclusion }} ${{ steps.next.outcome }} ${{ job.status }}', if => 'always()' },
		]);
		is($run->{result}{result}, 'failure', 'a failed step fails the job');
		is_deeply($run->{logged}, [ '!! step exited with status 3' ], 'the failure is logged');
		like($run->{out}, qr/^--- Step: say not run \(skipped\)$/m, 'a later step without a status function is skipped');
		like($run->{out}, qr/^failed: failure$/m, 'failure() runs, and sees the outcome');
		like($run->{out}, qr/^!! Step failed but continue-on-error is set$/m, 'continue-on-error is announced');
		like($run->{out}, qr{^failure/success skipped failure$}m, 'its outcome is failure, its conclusion success');
		like($harness->(steps => [ { run => 'say x', if => !!0 }, { run => 'say y', if => JSON::PP::false() } ])->{out},
			qr/\A--- Step: say x \(skipped\)\n--- Step: say y \(skipped\)\n\z/, 'if: false, as YAML gives it, skips the step');

		$run = $harness->(steps => [ { id => 'e', run => 'say x', env => { BAD => q<${{ fromJSON('{') }}> } },
			{ run => 'say ${{ steps.e.outcome }}', if => 'always()' } ]);
		like($run->{logged}[0], qr/\Aaction-run: unable to evaluate environment for step 'e': Unable to evaluate environment variable 'BAD': fromJSON\(\) failed: /,
			'an environment that does not evaluate');
		unlike($run->{logged}[0], qr/ line \d+/, 'is a message about the workflow, without a source line');
		like($run->{out}, qr/^failure$/m, 'is a failed step');
		is($run->{result}{result}, 'failure', 'and a failed job');
		$run = $harness->(steps => [ { run => 'say x', if => '${{ ( }}' } ]);
		like($run->{logged}[0], qr/\Aaction-run: unable to evaluate if for step '__step_1': /, 'a condition that does not evaluate');
		is($run->{result}{result}, 'failure', 'fails the job');
		$run = $harness->(steps => [ { run => 'exit 2', 'continue-on-error' => '${{ ( }}' } ]);
		like($run->{logged}[0], qr/\Aaction-run: unable to evaluate continue-on-error: /, 'a continue-on-error that does not evaluate');
		is($run->{result}{result}, 'failure', 'does not keep the job going');
		$run = $harness->(steps => [ { run => 'exit 2' }, { run => 'say x', if => '${{ ( }}' } ], quiet => 1);
		is_deeply($run->{logged}, [], 'a quiet run logs nothing');
		is($run->{result}{result}, 'failure', 'but fails all the same');
		$run = $harness->(steps => [ { run => 'die the daemon went away' } ]);
		is_deeply($run->{logged}, [ 'action-run: the daemon went away', '!! the daemon went away' ], 'an error while running is the step failing');
		$run = $harness->(steps => [ { run => 'die' } ]);
		is($run->{logged}[-1], '!! step failed', 'one that says nothing is a step that failed');
	};

	subtest 'run: names, shells and directories' => sub {
		my $long = 'say ' . ('x' x 100);
		my $run = $harness->(steps => [ { run => $long }, { name => '', run => 'say y' }, { name => '${{ ( }}', run => 'say z' } ]);
		like($run->{out}, qr/^--- Step: say x{73}\.\.\.$/m, 'a long script is cut to 80 characters');
		like($run->{out}, qr/^--- Step: Step 2$/m, 'an empty name is the step number');
		like($run->{out}, qr/^--- Step: \$\{\{ \( \}\}$/m, 'a name that does not evaluate is shown as written');

		my $command = sub { return [ map { $_->{command}[2] } @{ $_[0]{docker}{execs} } ] };
		$run = $harness->(defaults => { run => { shell => 'sh', 'working-directory' => 'w' } }, job => { defaults => { run => { shell => 'perl' } } },
			steps => [ { run => 'say a' }, { run => 'say b', shell => 'python3 -u {0}', 'working-directory' => '/abs' },
				{ run => 'say c', shell => 'ruby' }, { run => 'say d', shell => 'pwsh' } ]);
		is_deeply($command->($run), [ q{perl '/github/actions-runner/scripts/step-1.pl'}, q{python3 -u '/github/actions-runner/scripts/step-2.sh'},
			q{ruby '/github/actions-runner/scripts/step-3.sh'}, q{pwsh -File '/github/actions-runner/scripts/step-4.ps1'} ],
			"the step's shell, else the job's default; a custom one with {0}, or with the script after it");
		is_deeply([ map { $_->{workdir} } @{ $run->{docker}{execs} } ], [ '/github/workspace/w', '/abs', '/github/workspace/w',
			'/github/workspace/w' ], "the workflow's working directory, under the workspace, or the step's own");
		$run = $harness->(facts => { path => '/bin', has_bash => 0 }, steps => [ { run => 'say a' }, { run => 'say b', shell => 'bash' } ]);
		is($command->($run)->[0], q{sh -e '/github/actions-runner/scripts/step-1.sh'}, 'sh -e where the image has no bash');
		is_deeply($run->{logged}, [ q{!! Shell 'bash' is not available in the container} ], 'and bash, asked for, is a failure');
		is($command->($harness->(defaults => { run => { shell => 'bash' } }, steps => [ { run => 'say a' } ]))->[0],
			q{bash --noprofile --norc -eo pipefail '/github/actions-runner/scripts/step-1.sh'}, 'bash named is bash as GitHub runs it');

		$run = $harness->(dry_run => 1, verbose => 1, steps => [ { run => 'say ${{ secrets.TOKEN }}' } ]);
		like($run->{out}, qr/^--- script ---\nsay \*\*\*\n--- end script ---$/m, 'a verbose dry run shows the script, secrets hidden');
	};

	subtest 'run: files that cannot be written' => sub {
		my $run = $harness->(no_scripts => 1, steps => [ { run => 'say a' } ]);
		like($run->{logged}[0], qr{\Aaction-run: Unable to write the step script '.+/scripts/step-1\.sh': \S}, 'a script');
		is($run->{result}{result}, 'failure', 'fails the step');
		$run = $harness->(no_env => 1, steps => [ { run => 'say a' } ]);
		like($run->{logged}[0], qr{\Aaction-run: Unable to write the step file '.+/env/step-1\.\w+': \S}, 'so does a step file');
	};

	subtest 'run: well-known and unsupported actions' => sub {
		my $run = $harness->(steps => [
			{ uses => 'actions/checkout@v4', with => { path => 'src', submodules => 'true', ref => 'main' } },
			{ uses => 'actions/checkout@v4', with => { submodules => 'false' } },
			{ uses => 'shogo82148/actions-setup-perl@v1', with => { 'perl-version' => q{5.${{ '40' }}} } },
			{ uses => 'perl-actions/setup-perl@v1' },
			{ uses => 'actions/cache@v4' },
			{ id => 'r', uses => 'someone/else@v1' },
			{ run => 'say ${{ steps.r.outcome }}' },
		]);
		is($run->{result}{result}, 'success', 'none of them fails the job');
		is_deeply($run->{logged}, [
			q{action-run: actions/checkout 'path' is ignored; the repository is mounted at /github/workspace},
			'action-run: actions/checkout submodules are not fetched; using the checkout as-is',
			'action-run: actions/checkout ref/repository is ignored; using the local checkout',
			q{action-run: action 'someone/else@v1' skipped: remote JavaScript and composite actions are not supported},
		], 'checkout says what it ignores, and a remote action that it is skipped');
		like($run->{out}, qr/^    \(repository already mounted at \/github\/workspace\)$/m, 'checkout is the mounted project');
		like($run->{out}, qr/^    \(using container image for Perl 5\.40\)\n.*\n    \(using container image for Perl\)$/m, 'setup-perl is the image');
		like($run->{out}, qr/^    \(caching, artifacts, and coverage uploads are not implemented\)$/m, 'the cache does nothing');
		like($run->{out}, qr/^    \(skipped: remote JavaScript and composite actions are not supported\)\n.*\nskipped$/m,
			'a remote action is skipped');
		$run = $harness->(strict_actions => 1, steps => [ { uses => 'someone/else@v1' } ]);
		is($run->{result}{result}, 'failure', 'or, with strict_actions, fails');
		$run = $harness->(strict_actions => 1, steps => [ { uses => './image' } ]);
		is($run->{logged}[-1], q{!! action './image' skipped: local actions that use 'docker' are not supported},
			'as does a local Docker action');
	};

	subtest 'run: docker:// actions' => sub {
		my $run = $harness->(containers => { status => 0 }, steps => [
			{ id => 'o', run => 'out tag=3.20' },
			{ id => 'd', uses => 'docker://alpine:${{ steps.o.outputs.tag }}', with => { args => q{echo "a b" ${{ secrets.TOKEN }}},
				entrypoint => '/bin/sh' }, 'working-directory' => 'sub' },
		]);
		is($run->{result}{result}, 'success', 'an action runs');
		is_deeply($run->{object}{images}{ensured}, [ 'alpine:3.20' ], 'its image prepared first, with the step output known');
		my $call = $run->{object}{containers}{runs}[0];
		is_deeply([ @{$call}{qw(image network workdir entrypoint title)}, $call->{arguments} ], [ 'alpine:3.20', 'net', '/github/workspace/sub',
			'/bin/sh', q{Action 'docker://alpine:${{ steps.o.outputs.tag }}' in job 'build'}, [ 'echo', 'a b', 's3cret' ] ],
			'in a container of its own, its args split as a shell would');
		is($call->{env}{GITHUB_ACTION}, 'd', 'with the step environment');

		my $failing = $harness->(containers => { status => 3 }, steps => [ { uses => 'docker://alpine' } ]);
		is_deeply($failing->{logged}, [ '!! docker action exited with status 3' ], 'its status is the step\'s');
		my %refused = (
			'no image name' => [ { uses => 'docker://${{ env.NOTHING }}' },
				q{Docker action 'docker://${{ env.NOTHING }}' in job 'build' has no image name; check the expression it uses} ],
			'an output that is not an image name' => [ { uses => 'docker://${{ steps.o.outputs.v }}' },
				q{Docker action 'docker://${{ steps.o.outputs.v }}' in job 'build' resolved to 'x:{{ y }}', which is not an image name; }
				. 'check the expression it uses' ],
			'args with an unclosed quote' => [ { uses => 'docker://alpine', with => { args => q{--token "${{ secrets.TOKEN }}} } },
				q{Unable to read the args of 'docker://alpine' ('--token "${{ secrets.TOKEN }}'): a quote is not closed} ],
		);
		for my $name (sort keys %refused) {
			my ($step, $message) = @{ $refused{$name} };
			my $refusal = $harness->(steps => [ { id => 'o', run => 'out v=x:{{ y }}' }, $step ]);
			is_deeply($refusal->{logged}, [ "action-run: $message", "!! $message" ], $name);
			is_deeply($refusal->{object}{containers}{runs}, [], 'and nothing runs');
		}
	};

	subtest 'run: local composite actions' => sub {
		my $run = $harness->(steps => [
			{ id => 'c', uses => './greet', with => { who => '${{ github.repository }}' } },
			{ run => 'say ${{ steps.c.outputs.greeting }} ${{ env.FROM_ACTION }}' },
			{ uses => './greet' , id => 'd' },
			{ run => 'say ${{ steps.d.outputs.greeting }}' },
		]);
		is($run->{result}{result}, 'success', 'a composite action runs');
		like($run->{out}, qr/^--- Step: \.\/greet\n  --- Step: out text=hello o\/r env FROM_ACTION=1\n/m,
			'its steps one level deeper');
		like($run->{out}, qr/^hello o\/r 1$/m, 'its outputs and exported variables reach the job');
		like($run->{out}, qr/^hello world$/m, 'an input it is not given has its default');
		is($run->{docker}{execs}[0]{env}{GITHUB_ACTION_PATH}, '/github/workspace/greet', 'its steps know where it is');
		is($run->{result}{env}{FROM_ACTION}, 1, 'and the job env has what it exported');

		$run = $harness->(steps => [ { uses => './broken' } ]);
		is_deeply($run->{logged}, [ '!! step exited with status 4', q{!! composite action './broken' failed} ], 'a failing composite action');
		is($run->{result}{result}, 'failure', 'fails the job');
		$run = $harness->(steps => [ { uses => './loop' } ], quiet => 1);
		is($run->{result}{result}, 'failure', 'an action that uses itself fails');
		$run = $harness->(steps => [ { uses => './loop' } ]);
		is($run->{logged}[0], q{action-run: Composite action './loop' is nested more than 10 levels deep}, 'when it is too deep');
		$run = $harness->(steps => [ { uses => './nowhere' } ]);
		like($run->{logged}[0], qr{\Aaction-run: Local action '\./nowhere' does not exist \(looked in .+nowhere\)\z}, 'a missing local action');
	};

	subtest 'run: local JavaScript actions' => sub {
		my $run = $harness->(steps => [ { id => 'j', uses => './js', with => { 'perl-version' => '5.38' } },
			{ run => 'say ${{ steps.j.outputs.result }}' } ]);
		is($run->{result}{result}, 'success', 'a JavaScript action runs');
		like($run->{out}, qr/\A--- Step: \.\/js\npre ran\nmain ran\n--- Step: say done\ndone\n--- Step: Post \.\/js\npost ran\n\z/,
			'pre, main, then the later steps, and post at the end of the job');
		my ($pre, $main, undef, $post) = @{ $run->{docker}{execs} };
		is_deeply($main->{command}, [ 'node', '/github/workspace/js/main.js' ], 'with node');
		is($main->{env}{'INPUT_PERL-VERSION'}, '5.38', 'its inputs named as GitHub names them');
		is($main->{env}{STATE_seen}, 'pre', 'the state pre saved reaches main');
		is($post->{env}{STATE_seen}, 'pre', 'and post');
		is($main->{env}{GITHUB_ACTION_PATH}, '/github/workspace/js', 'which know where the action is');

		my $js = sub {
			my ($runs, @more) = @_;
			$action->('js2', "name: js2\nruns:\n  using: node20\n$runs", 'main.js' => "say main\n", 'bad.js' => "exit 6\n",
				'boom.js' => "die it blew up\n");
			return $harness->(steps => [ { uses => './js2' } ], @more);
		};
		$run = $js->("  main: main.js\n", facts => { path => '/bin', has_bash => 1, has_node => 0 });
		is($run->{logged}[-1], q{!! JavaScript action './js2' needs Node.js, but 'node' was not found in the job container}, 'node is needed');
		$run = $js->("  main: bad.js\n");
		is_deeply($run->{logged}, [ q{!! JavaScript action './js2' exited with status 6} ], 'main that fails');
		$run = $js->("  pre: bad.js\n  main: main.js\n");
		is_deeply($run->{logged}, [ q{!! pre step of JavaScript action './js2' exited with status 6} ], 'pre that fails');
		unlike($run->{out}, qr/^main$/m, 'and main is not run');
		$run = $js->("  pre: bad.js\n  pre-if: \${{ ( }}\n  main: main.js\n");
		like($run->{logged}[0], qr/\Aaction-run: unable to evaluate pre-if for '\.\/js2': /, 'a pre-if that does not evaluate');
		is($run->{result}{result}, 'success', 'skips pre');
		$run = $js->("  pre: bad.js\n  pre-if: false\n  main: main.js\n");
		is_deeply($run->{logged}, [], 'a pre-if that is false skips pre');

		$run = $js->("  main: main.js\n  post: bad.js\n");
		is_deeply($run->{logged}, [ q{!! post step for './js2' exited with status 6} ], 'post that fails');
		is($run->{result}{result}, 'failure', 'fails the job');
		$run = $js->("  main: main.js\n  post: boom.js\n");
		is_deeply($run->{logged}, [ q{action-run: post step for './js2' failed: it blew up} ], 'post that cannot be run');
		$run = $js->("  main: main.js\n  post: main.js\n  post-if: \${{ ( }}\n");
		like($run->{logged}[0], qr/\Aaction-run: unable to evaluate the post condition for '\.\/js2': /, 'a post-if that does not evaluate');
		unlike($run->{out}, qr/Post/, 'skips post');
		$run = $js->("  main: main.js\n  post: main.js\n  post-if: failure()\n");
		unlike($run->{out}, qr/Post/, 'as does one that is false');
		$run = $js->("  main: main.js\n  post: bad.js\n", quiet => 1);
		is_deeply($run->{logged}, [], 'a quiet run logs nothing');
	};
};

# ---------------------------------------------------------------------------
# App::Actions::Runner
# ---------------------------------------------------------------------------

# The suite's fake Docker daemon: it keeps its state in a directory, runs a
# step script with the host's shell, and is told what to get wrong through
# FAKE_* variables.
Readonly::Scalar my $SUITE_DOCKER => File::Spec->rel2abs(File::Spec->catfile('t', 'bin', 'fake-docker'));

# A Docker client that receives a signal as the run creates a job's
# network, as a run interrupted at the keyboard would.
{
	package Local::SignalDocker;
	our @ISA = ('App::Actions::Docker');

	sub network_create {
		my ($self, @args) = @_;

		kill $self->{test_signal}, $$;
		return $self->SUPER::network_create(@args);
	}
}

subtest 'App::Actions::Runner' => sub {
	# A project holding one workflow, and a runner for it on the fake daemon.
	my $project = sub {
		my ($yaml) = @_;
		my $dir = tempdir(CLEANUP => 1);
		my $workflows = File::Spec->catdir($dir, '.github', 'workflows');
		make_path($workflows);
		return ($dir, write_file('ci.yml', $yaml, $workflows));
	};
	my $runner = sub {
		my ($yaml, %options) = @_;
		my ($dir, $file) = $project->($yaml);
		return App::Actions::Runner->new(workflow => App::Actions::Workflow->load($file), project_dir => $dir,
			docker_bin => $SUITE_DOCKER, image => 'ubuntu:latest', %options);
	};
	# Run code with the fake daemon in a state of its own, and with the
	# knobs given; return what it printed.
	my $daemon = sub {
		my ($knobs, $code) = @_;
		my $state = tempdir(CLEANUP => 1);
		local $ENV{FAKE_DOCKER_STATE} = $state;
		local $ENV{FAKE_DOCKER_LOG} = File::Spec->catfile($state, 'log');
		local @ENV{ keys %{$knobs} } = values %{$knobs};
		return output_of(stdout => $code);
	};
	# Run a workflow; return the exit status, what it printed and what it logged.
	my $run = sub {
		my ($yaml, %options) = @_;
		my $knobs = delete $options{knobs} || {};
		my @logged;
		my $object = $runner->($yaml, logger => collecting_logger(\@logged), %options);
		my $exit;
		my $out = $daemon->($knobs, sub { $exit = $object->run });
		show_state(run => { exit => $exit, out => $out, logged => \@logged });
		return { exit => $exit, out => $out, logged => \@logged };
	};
	my $one_job = "name: CI\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo built\n";

	subtest 'new' => sub {
		my $object = $runner->($one_job);
		returns_ok($object, { type => 'object', isa => 'App::Actions::Runner' }, 'new');
		is_returned($object->workflow, { type => 'object', isa => 'App::Actions::Workflow' }, $object->{workflow}, 'workflow');
		my ($dir, $file) = $project->($one_job);
		my $workflow = App::Actions::Workflow->load($file);
		throws_code(sub { App::Actions::Runner->new(project_dir => $dir) }, 'runner.workflow_required', 'A workflow is required',
			'no workflow');
		throws_code(sub { App::Actions::Runner->new(workflow => $workflow) }, 'runner.project_dir_required', 'A project directory is required',
			'no project directory');
		my $missing = File::Spec->catdir($dir, 'nowhere');
		throws_code(sub { App::Actions::Runner->new(workflow => $workflow, project_dir => $missing) }, 'runner.project_dir_missing',
			"Project directory '$missing' does not exist", 'a project directory that does not exist');
		for my $bad ('0', 'four', '-1', '1.5') {
			throws_code(sub { $runner->($one_job, pull_concurrency => $bad) }, 'runner.pull_concurrency_invalid',
				"pull concurrency must be a positive integer, not '$bad'", "pull_concurrency $bad");
		}
		{
			local $ENV{ACTION_RUN_PULL_CONCURRENCY} = 'lots';
			throws_code(sub { $runner->($one_job) }, 'runner.pull_concurrency_invalid', q{pull concurrency must be a positive integer, not 'lots'},
				'or in ACTION_RUN_PULL_CONCURRENCY');
			ok($runner->($one_job, pull_concurrency => 3), 'which the option overrides');
		}
		throws_code(sub { $runner->($one_job, pull => 1, no_pull => 1) }, 'runner.pull_conflict', '--pull and --no-pull cannot be used together',
			'--pull with --no-pull');
		throws_code(sub { $runner->($one_job, %{$_}) }, 'actions.invalid_arguments', undef, 'refused: ' . join(',', keys %{$_}))
			for { colour => 1 }, { jobs => 'build' }, { logger => 'NULL' };
		keeps_globals(sub { $runner->($one_job) }, 'new', io => 1);
	};

	subtest 'option_rules, json_schema and preflight_schema_version' => sub {
		my $rules = App::Actions::Runner->option_rules;
		returns_ok($rules, { type => 'hashref' }, 'option_rules is a hash reference');
		is_deeply([ sort keys %{$rules} ], [ sort qw(jobs image perl_image platform user env secrets dry_run explain verbose quiet keep
			keep_images log_dir cache_file pull no_pull strict_actions skip_check pull_concurrency parallel docker docker_bin logger) ],
			'one rule per documented option');
		$rules->{jobs}{type} = 'changed';
		is(App::Actions::Runner->option_rules->{jobs}{type}, 'arrayref', 'a copy, which the caller may change');
		my $schema = App::Actions::Runner->json_schema;
		returns_ok($schema, { type => 'hashref' }, 'json_schema is a hash reference');
		is_returned(App::Actions::Runner->preflight_schema_version, { type => 'integer', min => 1 }, $schema->{version},
			"preflight_schema_version is the schema's version");
		is($schema->{properties}{schema_version}{const}, $schema->{version}, 'and the document must carry it');
	};

	subtest 'list_jobs' => sub {
		my $matrix = "jobs:\n  test:\n    strategy:\n      matrix:\n        perl: ['5.38', '5.40']\n    steps:\n      - run: echo\n"
			. "  lint:\n    steps:\n      - run: echo\n";
		my $status;
		my $text = output_of(stdout => sub { $status = $runner->($matrix)->list_jobs });
		is_returned($status, { type => 'integer', memberof => [ 0 ] }, 0, 'returns 0');
		is($text, "test\ttest (perl=5.38)\ntest\ttest (perl=5.40)\nlint\tlint\n", 'id, tab, display name, in workflow order');
		is(output_of(stdout => sub { $runner->($matrix, jobs => [ 'lint', 'test (perl=5.40)' ])->list_jobs }), "test\ttest (perl=5.40)\nlint\tlint\n",
			'a filter by id or display name keeps the workflow order');
		throws_code(sub { $runner->($matrix, jobs => [ 'deploy' ])->list_jobs }, 'runner.no_job_matched', q{No job matched 'deploy'},
			'a filter that matches nothing');
	};

	subtest 'run: success and failure' => sub {
		my $result = $run->($one_job);
		is_returned($result->{exit}, { type => 'integer', memberof => [ 0, 1, 2 ] }, 0, 'a workflow that passes exits 0');
		settle('status Runner: run 0 success');
		like($result->{out}, qr/^==> Job: build\n    image: ubuntu:latest\n--- Step: echo built\n/m, 'the job, its image and its steps');
		like($result->{out}, qr/^built$/m, "and the step's output");
		like($result->{out}, qr/^Workflow succeeded$/m, 'then the summary');
		is_deeply($result->{logged}, [], 'with nothing logged');

		$result = $run->("jobs:\n  build:\n    steps:\n      - run: exit 1\n  after:\n    needs: build\n    steps:\n      - run: echo\n");
		is($result->{exit}, 1, 'a workflow that fails exits 1');
		settle('status Runner: run 1 workflow failure');
		like($result->{out}, qr/^==> Job: after \(skipped\)$/m, 'a job whose needs failed is skipped');

		$result = $run->($one_job, knobs => { FAKE_OS_TYPE => 'windows' });
		is($result->{exit}, 2, 'a host that is not ready exits 2');
		settle('status Runner: run 2 usage or Docker error');
		is($result->{logged}[-1], 'action-run: the environment is not ready; fix what the report above asks for, or pass --skip-check to run anyway',
			'saying why, without a source line');
		is($run->($one_job, quiet => 1, knobs => { FAKE_OS_TYPE => 'windows' })->{logged}[0], undef, 'a quiet run logs nothing');
		is($run->($one_job, skip_check => 1, knobs => { FAKE_OS_TYPE => 'windows' })->{exit}, 0, '--skip-check skips the probes');
		is($run->($one_job, skip_check => 1, knobs => { FAKE_NO_DAEMON => 1 })->{exit}, 2, 'but not the question whether Docker answers');

		$result = $run->("jobs:\n  build:\n    container: broken/image:1\n    steps:\n      - run: echo\n",
			knobs => { FAKE_PULL_FAILURE => 'broken/image:1' });
		is($result->{exit}, 2, 'an image that cannot be pulled exits 2');
		like($result->{logged}[-1], qr/\Aaction-run: cannot prepare the image 'broken\/image:1', needed by job 'build': /, 'naming it');
		keeps_globals(sub { $daemon->({}, sub { $runner->($one_job, quiet => 1)->run }) }, 'run', io => 1);
	};

	subtest 'run: which jobs run' => sub {
		# runner.unknown_job guards a private routine against a job id the
		# selection did not make; no workflow can reach it through run(), and
		# t/function.t calls the routine with one.
		settle('message runner.unknown_job');
		my $result = $run->("jobs:\n  a:\n    needs: b\n    steps:\n      - run: echo\n  b:\n    needs: a\n    steps:\n      - run: echo\n");
		is($result->{exit}, 2, 'jobs that need each other');
		like($result->{logged}[-1], qr/\Aaction-run: Dependency cycle involving job '[ab]'\z/, 'are a cycle');

		$result = $run->("jobs:\n  a:\n    steps:\n      - run: echo\n  b:\n    needs: a\n    steps:\n      - run: echo b\n", jobs => [ 'b' ]);
		is($result->{logged}[0], q{action-run: job 'b' needs 'a', which was not selected; assuming it succeeded}, 'a need left out');
		is($result->{exit}, 0, 'is taken to have passed');

		$result = $run->("jobs:\n  off:\n    if: false\n    steps:\n      - run: echo\n  mac:\n    runs-on: macos-latest\n    steps:\n"
			. "      - run: echo\n  bad:\n    if: \${{ ( }}\n    steps:\n      - run: echo\n");
		like($result->{out}, qr/^==> Job: off \(skipped\)$/m, 'if: false skips a job');
		like($result->{out}, qr/^==> Job: mac \(skipped: runs-on 'macos-latest' is not Linux\)$/m, 'so does a runner that is not Linux');
		like($result->{logged}[0], qr/\Aaction-run: unable to evaluate if for 'bad': /, 'a condition that does not evaluate');
		is($result->{exit}, 1, 'fails the workflow');

		my $matrix = "jobs:\n  t:\n    strategy:\n      max-parallel: 1\n%s      matrix:\n        n: [1, 2]\n    steps:\n      - run: exit 1\n";
		$result = $run->(sprintf($matrix, ''));
		like($result->{out}, qr/^==> Job: t \(n=2\) \(skipped by fail-fast\)$/m, 'fail-fast stops the rest of a matrix');
		$result = $run->(sprintf($matrix, "      fail-fast: false\n"));
		unlike($result->{out}, qr/fail-fast/, 'unless fail-fast is false');
		is(scalar(() = $result->{out} =~ /^--- Step: exit 1$/mg), 2, 'when every instance runs');

		$result = $run->("jobs:\n  t:\n    continue-on-error: true\n    steps:\n      - run: exit 1\n");
		like($result->{out}, qr/^!! Job failed but continue-on-error is set: t$/m, 'continue-on-error lets a job fail');
		is($result->{exit}, 0, 'and the workflow pass');
		$result = $run->("jobs:\n  t:\n    continue-on-error: \${{ ( }}\n    steps:\n      - run: exit 1\n");
		like($result->{logged}[-1], qr/\Aaction-run: unable to evaluate continue-on-error for 't': /, 'a continue-on-error that does not evaluate');
		is($result->{exit}, 1, 'does not');
	};

	subtest 'run: images, users and signals' => sub {
		my $result = $run->("jobs:\n  t:\n    steps:\n      - id: s\n        run: echo\n      - uses: docker://alpine:\${{ steps.s.outputs.tag }}\n");
		like($result->{out}, qr/^  deferred  alpine:\$\{\{ steps\.s\.outputs\.tag \}\} \(action 'docker:\/\/alpine:\$\{\{ steps\.s\.outputs\.tag \}\}' in job 't'\)$/m,
			'an image a step decides is shown as deferred');
		$result = $run->("jobs:\n  t:\n    container:\n      image: \"\${{ ' ' }}\"\n    steps:\n      - run: echo\n");
		is($result->{logged}[-1], q{action-run: Unable to determine a container image for job 't'}, 'an image name that is blank');
		is($result->{exit}, 2, 'stops the run');

		SKIP: {
			skip 'needs a user that is neither root nor this one', 1 if $^O eq 'MSWin32';
			$result = $run->($one_job, user => '4242');
			like($result->{logged}[0], qr/\Aaction-run: the job runs as '4242', so its runner directory .+ is open to every user of this host, /,
				'a container user other than root or this one opens the runner directory, and says so');
		}

		for my $signal ([ 'INT', 'Interrupted' ], [ 'TERM', 'Terminated' ]) {
			my @logged;
			my $docker = Local::SignalDocker->new(bin => $SUITE_DOCKER);
			$docker->{test_signal} = $signal->[0];
			my $object = $runner->($one_job, docker => $docker, logger => collecting_logger(\@logged), skip_check => 1);
			my $exit;
			$daemon->({}, sub { $exit = $object->run });
			is($exit, 2, "SIG$signal->[0] ends the run");
			is($logged[-1], "action-run: $signal->[1]", 'saying so');
		}
	};

	subtest 'preflight' => sub {
		my $two = "jobs:\n  t:\n    container: perl:5.40\n    steps:\n      - run: echo\n      - uses: docker://alpine:\${{ steps.x.outputs.v }}\n";
		my $result;
		my $text = $daemon->({}, sub { $result = $runner->($two)->preflight });
		returns_ok($result, { type => 'hashref', schema => { exit => { type => 'integer', memberof => [ 0, 2 ] },
			summary => { type => 'hashref' }, error => { type => 'string', optional => 1 } } }, 'the documented shape');
		is($result->{exit}, 0, 'a ready host and its images exit 0');
		settle('status Runner: preflight 0 ready');
		is($result->{error}, undef, 'with no error');
		is_deeply([ map { $_->{status} } @{ $result->{summary}{images} } ], [ 'pulled', 'deferred' ], 'the images, pulled or deferred');
		is($result->{summary}{schema_version}, App::Actions::Runner->preflight_schema_version, 'the document is versioned');
		like($text, qr/^  schema    version \d+ \(action-run schema preflight\)\n\z/m, 'and the report ends with the version');
		unlike($daemon->({}, sub { $runner->($two)->preflight(schema_line => 0) }), qr/schema    version/, 'unless asked not to');

		my $json = $daemon->({}, sub { $result = $runner->($two)->preflight(json => 1) });
		is($json, '', 'json prints nothing');
		ok(JSON::PP::is_bool($result->{summary}{ready}), 'and ready is a JSON boolean');

		$daemon->({ FAKE_PULL_FAILURE => 'perl:5.40' }, sub { $result = $runner->($two)->preflight(json => 1) });
		is($result->{exit}, 2, 'an image that cannot be pulled exits 2');
		settle('status Runner: preflight 2 not ready');
		like($result->{error}, qr/\Acannot prepare the image 'perl:5\.40', needed by job 't': /, 'with the reason');
		is_deeply($result->{summary}{issues}[-1]{remedies},
			[ 'check the image name, and that the registry is reachable and the Docker login is valid' ], 'and the remedy');

		$daemon->({ FAKE_OS_TYPE => 'windows' }, sub { $result = $runner->($two)->preflight(json => 1) });
		is($result->{error}, 'the environment is not ready; fix what the report above asks for, or pass --skip-check to run anyway',
			'a host that is not ready');
		is_deeply([ map { $_->{status} } @{ $result->{summary}{images} } ], [ 'skipped', 'skipped' ], 'pulls nothing');
		$daemon->({ FAKE_NO_DAEMON => 1 }, sub { $result = $runner->($two, skip_check => 1)->preflight(json => 1) });
		is($result->{exit}, 2, 'with --skip-check, a daemon that does not answer');
		like($result->{error}, qr/\ACannot connect to the Docker daemon/, 'is still reported');

		{
			local $FAIL{open} = sub { $_[1] eq '>' && ref $_[2] eq 'SCALAR' };
			throws_code(sub { $runner->($two)->preflight(json => 1) }, 'runner.preflight.buffer_failed', undef,
				'a report that cannot be buffered');
		}
		{
			my $mock = Test::Mockingbird::mock_scoped('App::Actions::Check::summary' => sub { return { stray => 1, ready => 1 } });
			my $error = caught { $daemon->({}, sub { $runner->($two)->preflight(json => 1) }) };
			isa_ok($error, 'App::Actions::Schema::Invalid', 'a document that does not match its schema');
			like(ref $error && $error->message, qr/\Athe action-run preflight --json document does not match App::Actions::Runner->json_schema: /,
				'says so');
		}
		keeps_globals(sub { $daemon->({}, sub { $runner->($two)->preflight(json => 1) }) }, 'preflight', io => 1);
	};
};

# ---------------------------------------------------------------------------
# App::Actions
# ---------------------------------------------------------------------------

subtest 'App::Actions' => sub {
	# A repository with a workflow in .github/workflows, which names its own
	# project directory.
	my $repository = sub {
		my ($yaml) = @_;
		my $dir = tempdir(CLEANUP => 1);
		my $workflows = File::Spec->catdir($dir, '.github', 'workflows');
		make_path($workflows);
		return ($dir, write_file('ci.yml', $yaml, $workflows));
	};
	my $yaml = "name: CI\njobs:\n  test:\n    strategy:\n      matrix:\n        n: [1, 2]\n    steps:\n      - run: echo test \${{ matrix.n }}\n"
		. "  fail:\n    steps:\n      - run: exit 1\n";
	my ($dir, $file) = $repository->($yaml);
	my $actions = sub { return App::Actions->new(workflow_file => $file, docker_bin => $SUITE_DOCKER, image => 'ubuntu:latest', @_) };
	my $daemon = sub {
		my ($code) = @_;
		my $state = tempdir(CLEANUP => 1);
		local $ENV{FAKE_DOCKER_STATE} = $state;
		local $ENV{FAKE_DOCKER_LOG} = File::Spec->catfile($state, 'log');
		return output_of(stdout => $code);
	};

	subtest 'new and the accessors' => sub {
		my $object = $actions->();
		returns_ok($object, { type => 'object', isa => 'App::Actions' }, 'new');
		is_returned($object->workflow_file, { type => 'string' }, Cwd::abs_path($file), 'workflow_file is absolute');
		is_returned($object->project_dir, { type => 'string' }, Cwd::abs_path($dir), 'project_dir is the repository the workflow is in');
		returns_ok($object->workflow, { type => 'object', isa => 'App::Actions::Workflow' }, 'workflow');
		is($object->workflow->name, 'CI', 'loaded from the file');
		my $elsewhere = tempdir(CLEANUP => 1);
		is(App::Actions->new(workflow_file => $file, project_dir => $elsewhere)->project_dir, Cwd::abs_path($elsewhere),
			'or the directory given');

		throws_code(sub { App::Actions->new }, 'actions.workflow_file_required', 'workflow_file is required', 'no workflow');
		my $missing = File::Spec->catfile($dir, 'missing.yml');
		throws_code(sub { App::Actions->new(workflow_file => $missing) }, 'actions.workflow_file_missing',
			"Workflow file '$missing' does not exist", 'a workflow that does not exist');
		my $loose = write_file('ci.yml', $yaml);
		throws_code(sub { App::Actions->new(workflow_file => $loose) }, 'actions.project_dir_required',
			'project_dir is required when the workflow is not inside .github/workflows', 'a workflow outside a repository');
		my $gone = File::Spec->catdir($dir, 'gone');
		throws_code(sub { App::Actions->new(workflow_file => $loose, project_dir => $gone) }, 'actions.project_dir_missing',
			"Project directory '$gone' does not exist", 'a project directory that does not exist');
		throws_code(sub { $actions->(%{$_}) }, 'actions.invalid_arguments', undef, 'refused: ' . join(',', keys %{$_}))
			for { colour => 'blue' }, { config_file => 'x' }, { jobs => 'test' }, { env => [] };
		throws_code(sub { App::Actions->new(workflow_file => write_file('ci.yml', "jobs: [\n"), project_dir => $dir) }, 'workflow.parse_failed', undef,
			"the workflow's own messages apply");
		keeps_globals(sub { $actions->() }, 'new', io => 1);
	};

	subtest 'new: loggers and configuration' => sub {
		my @messages;
		my $object = $actions->(logger => \@messages);
		isa_ok($object->{logger}, 'Log::Abstraction', 'an array reference');
		$object->{logger}->warn('collected');
		is(scalar(grep { ref $_ eq 'HASH' ? ($_->{message} // '') =~ /collected/ : /collected/ } @messages), 1, 'collects the messages');
		my $own = collecting_logger(\my @own);
		is($actions->(logger => $own)->{logger}, $own, 'a logger object is used as it is');
		isa_ok($actions->(logger => 'NULL')->{logger}, 'Log::Abstraction', "'NULL'");
		isa_ok($actions->(logger => { array => [] })->{logger}, 'Log::Abstraction', 'a hash of options');
		isa_ok($actions->()->{logger}, 'Log::Abstraction', 'and by default');

		my $config = tempdir(CLEANUP => 1);
		write_file('local.yaml', "---\nApp__Actions:\n  parallel: 3\n  quiet: 1\n", $config);
		local $ENV{CONFIG_DIR} = $config;
		my $configured = $actions->(parallel => 1);
		is($configured->{parallel}, 3, 'a configuration file wins over an argument');
		local $ENV{App__Actions__parallel} = 5;
		is($actions->(parallel => 1)->{parallel}, 5, 'and an environment variable over both');
	};

	subtest 'run' => sub {
		my $status;
		my $text = $daemon->(sub { $status = $actions->(jobs => [ 'test' ])->run });
		is_returned($status, { type => 'integer', memberof => [ 0, 1, 2 ] }, 0, 'a run that passes is 0');
		settle('status Actions: run 0 success');
		like($text, qr/^test 1$/m, 'the steps ran');
		like($text, qr/^test 2$/m, 'each instance');
		my @logged;
		$daemon->(sub { $status = $actions->(logger => collecting_logger(\@logged))->run });
		is($status, 1, 'a job that fails is 1');
		settle('status Actions: run 1 job failed');
		$text = $daemon->(sub { $status = $actions->()->run(jobs => [ 'test (n=2)' ], quiet => 1) });
		unlike($text, qr/^(?:==>|---) /m, 'an override applies to this run: quiet');
		like($text, qr/^test 2$/m, 'and the job it selects runs');
		unlike($text, qr/^test 1$/m, 'alone');
		is($status, 0, 'and passes');
		my $object = $actions->(logger => collecting_logger(\@logged));
		$daemon->(sub { $status = $object->run(docker_bin => File::Spec->catfile($dir, 'no-such-docker')) });
		is($status, 2, 'a Docker that cannot be run is 2');
		settle('status Actions: run 2 usage or Docker error');
		is($object->{docker_bin}, $SUITE_DOCKER, 'and the object keeps its own options');
		throws_code(sub { $actions->()->run(colour => 1) }, 'actions.invalid_arguments', undef, 'an unknown override');
		throws_code(sub { $actions->()->run(workflow_file => $file) }, 'actions.invalid_arguments', undef, 'or one only new takes');
		keeps_globals(sub { $daemon->(sub { $actions->(quiet => 1)->run }) }, 'run', io => 1);
	};

	subtest 'preflight' => sub {
		my $result;
		my $text = $daemon->(sub { $result = $actions->()->preflight(json => 1, jobs => [ 'fail' ]) });
		is($text, '', 'json prints nothing');
		returns_ok($result, { type => 'hashref' }, 'a hash reference');
		is_deeply([ @{$result}{qw(exit error)} ], [ 0, undef ], 'ready, with no error');
		is($result->{summary}{schema_version}, App::Actions::Runner->preflight_schema_version, 'and the versioned document');
		like($daemon->(sub { $actions->()->preflight }), qr/^  schema    version /m, 'a text report');
		throws_code(sub { $actions->()->preflight(colour => 1) }, 'actions.invalid_arguments', undef, 'an unknown option');
		keeps_globals(sub { $daemon->(sub { $actions->()->preflight(json => 1) }) }, 'preflight', io => 1);
	};

	subtest 'json_schema' => sub {
		my %owner = (check => 'App::Actions::Check', preflight => 'App::Actions::Runner', cache => 'App::Actions::Cache',
			logs => 'App::Actions::Logs');
		for my $name (sort keys %owner) {
			is_returned(App::Actions->json_schema($name), { type => 'hashref' }, $owner{$name}->json_schema, "$name is ${\ $owner{$name}}'s");
		}
		throws_code(sub { App::Actions->json_schema($_) }, 'actions.document_required', 'A document name is required',
			'no name: ' . ($_ // 'undef')) for undef, '';
		throws_code(sub { App::Actions->json_schema('runs') }, 'actions.document_unknown',
			q{Unknown document 'runs'; expected check, preflight, cache or logs}, 'an unknown name, with the names there are');
		keeps_globals(sub { App::Actions->json_schema('check') }, 'json_schema');
	};

	subtest 'list_jobs' => sub {
		my $status;
		my $text = output_of(stdout => sub { $status = $actions->()->list_jobs });
		is_returned($status, { type => 'integer', memberof => [ 0 ] }, 0, 'returns 0');
		is($text, "test\ttest (n=1)\ntest\ttest (n=2)\nfail\tfail\n", 'one line per job instance');
		is(output_of(stdout => sub { $actions->()->list_jobs(jobs => [ 'fail' ], quiet => 0, dry_run => 0) }), "fail\tfail\n",
			'an override selects, and listing is always quiet');
		throws_code(sub { $actions->()->list_jobs(jobs => [ 'nope' ]) }, 'runner.no_job_matched', q{No job matched 'nope'}, 'a filter that matches nothing');
		throws_code(sub { $actions->()->list_jobs(colour => 1) }, 'actions.invalid_arguments', undef, 'an unknown option');
		keeps_globals(sub { output_of(stdout => sub { $actions->()->list_jobs }) }, 'list_jobs', io => 1);
	};
};

# ---- end of sections ----

# Every documented message and status must have been reached.
is_deeply([ sort keys %ledger ], [], 'every documented message and status was triggered')
	or diag("not reached:\n" . join("\n", map { "  $_" } sort keys %ledger));

restore_all();
done_testing();
