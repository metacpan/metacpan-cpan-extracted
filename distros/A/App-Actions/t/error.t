use strict;
use warnings;
use utf8;

use Test::Most;

use App::Actions;
use App::Actions::Access;
use App::Actions::Error;
use App::Actions::I18N qw(throw);
use App::Actions::Schema;

# The exception every catalogued failure is raised as, how a caller tells
# failures apart by code rather than by text, and the access control the
# modules put on their private routines.

subtest 'an error carries its code, message and location' => sub {
	my $error = App::Actions::Error->new(
		code => 'workflow.no_jobs',
		message => "Workflow 'ci.yml' has no 'jobs' mapping",
		args => { file => 'ci.yml' },
		location => " at lib/X.pm line 3.\n",
	);

	is($error->code, 'workflow.no_jobs', 'the code is the message key');
	is($error->message, "Workflow 'ci.yml' has no 'jobs' mapping", 'the message has no location');
	is($error->location, " at lib/X.pm line 3.\n", 'the location is kept apart');
	is($error->text, "Workflow 'ci.yml' has no 'jobs' mapping at lib/X.pm line 3.\n", 'the text is both');
	is("$error", $error->text, 'it stringifies to the text, as a croak would read');
	ok($error, 'it is true, so "if ($@)" still works');
	is_deeply($error->args, { file => 'ci.yml' }, 'the arguments are kept');

	my $args = $error->args;
	$args->{file} = 'changed';
	is($error->args->{file}, 'ci.yml', 'and handed out as a copy');

	is(App::Actions::Error->new(code => 'a.b', message => 'm')->location, "\n",
		'with no location the message ends in a newline, as die "...\n" did');
};

subtest 'is() matches a code or a family of codes' => sub {
	my $error = App::Actions::Error->new(code => 'runner.image.unprepared', message => 'm');

	ok($error->is('runner.image.unprepared'), 'the exact code');
	ok($error->is('runner.image.'), 'a family, named with a trailing dot');
	ok($error->is('runner.'), 'a wider family');
	ok(!$error->is('runner.image'), 'without the dot, a prefix is not a match');
	ok(!$error->is('runner.ima.'), 'a family must end at a dot');
	ok(!$error->is('workflow.'), 'another family does not match');
};

subtest 'new() refuses what is not an error' => sub {
	throws_ok { App::Actions::Error->new(message => 'm') }
		qr/^Invalid arguments to App::Actions::Error::new/, 'a code is required';
	throws_ok { App::Actions::Error->new(code => 'Not A Key', message => 'm') }
		qr/^Invalid arguments to App::Actions::Error::new/, 'the code is a dotted key';
	throws_ok { App::Actions::Error->new(code => 'nodot', message => 'm') }
		qr/^Invalid arguments/, 'with at least one dot';
	throws_ok { App::Actions::Error->new(code => 'a.b', message => 'm', colour => 'red') }
		qr/^Invalid arguments/, 'an unknown argument is refused';
};

subtest 'caught() and describe() accept errors and strings alike' => sub {
	my $error = App::Actions::Error->new(code => 'a.b', message => 'went wrong', location => " at f line 1.\n");

	is(App::Actions::Error->caught($error), $error, 'an error is caught');
	is(App::Actions::Error->caught("went wrong\n"), undef, 'a string is not');
	is(App::Actions::Error->caught(undef), undef, 'nor is nothing');
	is(App::Actions::Error->caught(bless {}, 'Some::Other'), undef, 'nor another class');

	is(App::Actions::Error->describe($error), 'went wrong', 'an error is described by its message');
	is(App::Actions::Error->describe("No job matched 'x' at lib/App/Actions.pm line 9.\n"), "No job matched 'x'",
		'a croak loses its location');
	is(App::Actions::Error->describe("bad JSON at character offset 9 at /a path/with spaces.pm line 12.\n"),
		'bad JSON at character offset 9', 'only the last location goes, even under a path with spaces');
	is(App::Actions::Error->describe("plain\n"), 'plain', 'a plain message loses its newline');
	is(App::Actions::Error->describe(undef), '', 'nothing is described as nothing');
};

subtest 'throw raises an error whose code is the key' => sub {
	my $error;
	eval { main->throw('runner.unknown_job', { job => 'build' }); 1 } or $error = $@;

	ok(App::Actions::Error->caught($error), 'the exception is an App::Actions::Error');
	ok($error->is('runner.unknown_job'), 'its code is the key');
	is($error->message, "Unknown job 'build'", 'its message is the English text');
	like($error->location, qr/ at .+ line \d+\.\n\z/, 'and it says where it was raised');

	eval { main->throw('runner.not_ready', { location => 0 }); 1 } or $error = $@;
	is($error->location, "\n", 'location => 0 leaves out the place, for advice');
	unlike("$error", qr/ line \d+/, 'so the text names no source line');
};

subtest 'a schema mismatch is an error with a code of its own' => sub {
	my $error;
	eval { App::Actions::Schema::assert_valid({ extra => 1 }, { type => 'object', properties => {} }, 'the document'); 1 }
		or $error = $@;

	isa_ok($error, 'App::Actions::Schema::Invalid');
	isa_ok($error, 'App::Actions::Error');
	ok($error->is('schema.invalid'), 'its code is schema.invalid');
	like("$error", qr/\Athe document: \$\.extra: unexpected key\n\z/, 'it reads as the message it always was');
	is($error->message, "$error", 'and its message is what it stringifies to');
	is(App::Actions::Error->describe($error), 'the document: $.extra: unexpected key', 'describe drops the newline');
};

subtest 'private routines are listed and enforced' => sub {
	# A module asks before its routines are wrapped, from a BEGIN block at
	# its end, so a package of its own stands in for one here.
	{
		package Local::Fixture;
		sub public { return 1 }
		sub _second { return 2 }
		sub _first { return 1 }
		sub _protected { return 3 }
	}
	no warnings 'once';
	*Local::Fixture::_borrowed = \&App::Actions::Error::is;

	is_deeply(App::Actions::Access->private_names('Local::Fixture'), [qw(_first _protected _second)],
		'the underscore routines the package defines, in order');
	is_deeply(App::Actions::Access->private_names('Local::Fixture', '_protected'), [qw(_first _second)],
		'a name can be excepted, as App::Actions does for its protected _runner');

	throws_ok { App::Actions::Access->private_names('not a package') }
		qr/^A package name is required/, 'a bad package name is refused';

	# Each module sets enforce mode only while it marks its own routines, so
	# loading the distribution leaves every other user of Sub::Private alone.
	TODO: {
		# Log::Abstraction 0.40 and earlier set the mode for the whole
		# process in a BEGIN block without local.  0.41, which the
		# distribution requires, sets it for its own package only; the TODO
		# covers a development machine that still has an older one.
		local $TODO = 'Log::Abstraction < 0.41 sets Sub::Private enforce mode process-wide'
			if $INC{'Log/Abstraction.pm'} && Log::Abstraction->VERSION < 0.41;
		is($Sub::Private::config{mode} || 'namespace', 'namespace', 'the process-wide mode is left as it was');
	}

	local $Sub::Private::config{harness_bypass} = 0;
	throws_ok { App::Actions::Runner::_truthy_scalar('yes') }
		qr/_truthy_scalar\(\) is a private subroutine of App::Actions::Runner/,
		'a runner helper cannot be called from outside';
	throws_ok { App::Actions::Runner::Support->can('chomp_error') && App::Actions::Runner::Containers::_hostname('x') }
		qr/_hostname\(\) is a private subroutine of App::Actions::Runner::Containers/,
		'nor can one of its parts\' helpers';

	local $Sub::Private::BYPASS = 1;
	is(App::Actions::Runner::_truthy_scalar('no'), 0, 'unless a white-box test asks to bypass the check');
};

done_testing();
