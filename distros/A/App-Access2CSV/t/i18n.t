#!perl

# Tests for App::Access2CSV::I18N: lookup, sprintf interpolation,
# plural and context selection, language choice and access control

use strict;
use warnings;

use Test::Most;

use App::Access2CSV::I18N;

# A throw-away subclass, to exercise the protected helpers legitimately
{
	package Local::Sub;
	use parent -norequire, 'App::Access2CSV::I18N';
	sub new { my ($class, %args) = @_; return bless {%args}, $class }
	sub boom { my $self = shift; $self->_croak_i18n('output_exists', { params => ['x.csv'] }) }
	sub grumble { my $self = shift; return $self->_carp_i18n('no_row_counter') }
}

# Keep the environment from choosing a language behind our backs
local @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)} = (undef) x 4;

my $class = 'App::Access2CSV::I18N';

subtest 'plain lookup and sprintf interpolation' => sub {
	is($class->i18n('missing_database'), 'Missing database filename', 'no parameters');
	is(
		$class->i18n('program_failed', { params => ['mdb-export', 1, 'boom'] }),
		'mdb-export failed with exit status 1: boom',
		'parameters are interpolated in order',
	);
	is(
		$class->i18n({ key => 'program_missing', args => { params => ['mdb-tables'] } }),
		'Required program not found in PATH: mdb-tables',
		'hashref calling style',
	);
};

subtest 'literal % in a parameter is not reinterpreted' => sub {
	is($class->i18n('fatal', { params => ['100% done'] }), 'access2csv: 100% done');
};

subtest 'plural forms' => sub {
	is($class->i18n('summary', { params => [0, 0], count => 0 }), 'Processed 0 tables, 0 failed', 'zero');
	is($class->i18n('summary', { params => [1, 0], count => 1 }), 'Processed 1 table, 0 failed', 'one');
	is($class->i18n('summary', { params => [5, 2], count => 5 }), 'Processed 5 tables, 2 failed', 'many');
	is($class->i18n('summary', { params => [5, 2] }), 'Processed 5 tables, 2 failed', 'no count means "other"');
};

subtest 'context (gender) forms, with plural forms nested inside' => sub {
	local $App::Access2CSV::I18N::MESSAGES{en}{test_context} = {
		female => { one => 'She exported %d table', other => 'She exported %d tables' },
		male   => 'He exported %d tables',
		other  => 'They exported %d tables',
	};
	is($class->i18n('test_context', { params => [1], count => 1, context => 'female' }), 'She exported 1 table');
	is($class->i18n('test_context', { params => [2], count => 2, context => 'female' }), 'She exported 2 tables');
	is($class->i18n('test_context', { params => [2], count => 2, context => 'male' }), 'He exported 2 tables');
	is($class->i18n('test_context', { params => [2], context => 'neuter' }), 'They exported 2 tables', 'unknown context falls back');
};

subtest 'language selection' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { missing_database => 'Name der Datenbank fehlt' };

	{
		local $ENV{LANG} = 'de_DE.UTF-8';
		is($class->i18n('missing_database'), 'Name der Datenbank fehlt', 'LANG chooses German');
		is($class->i18n('dry_run_title'), 'DRY RUN', 'untranslated keys fall back to English');
	}
	{
		local $ENV{LANGUAGE} = 'fr:de';
		is($class->i18n('missing_database'), 'Missing database filename', 'only the first LANGUAGE entry is used');
	}
	{
		local $ENV{LC_ALL} = 'C';
		local $ENV{LANG} = 'de_DE.UTF-8';
		is($class->i18n('missing_database'), 'Name der Datenbank fehlt', 'C locale means "no preference"');
	}
	{
		local $ENV{LANG} = 'ja_JP.UTF-8';
		is($class->i18n('missing_database'), 'Missing database filename', 'unknown language falls back to English');
	}
	{
		local $ENV{LANG} = 'de_DE.UTF-8';
		my $obj = Local::Sub->new(language => 'en');
		is($obj->i18n('missing_database'), 'Missing database filename', 'object language beats the environment');
	}
};

subtest 'errors' => sub {
	throws_ok { $class->i18n('no_such_key') } qr/Unknown message key: no_such_key/, 'unknown key';
	throws_ok { $class->i18n() } qr/Required parameter 'key'|key.*missing/i, 'missing key';
	throws_ok { $class->i18n('summary', 'not a hash') } qr/args/, 'args must be a hashref';
	throws_ok { $class->i18n('summary', { bogus => 1 }) } qr/Unknown parameter 'bogus'/, 'unknown args field';
	throws_ok { $class->i18n('summary', { count => -1 }) } qr/count/, 'negative count';
	throws_ok { $class->i18n('summary', { params => 'x' }) } qr/params/, 'params must be an arrayref';
	is($class->i18n('summary', { params => [2, 0], count => undef }), 'Processed 2 tables, 0 failed', 'undef count means not given');
};

subtest 'a broken language choice cannot make i18n recurse' => sub {
	# Regression: the English fallback used to call i18n() again with an
	# object pinned to English, trusting _language() to answer "en".  A
	# mutation of _language that always returned "" made that recursion
	# endless (CI ran out of memory).  Whatever _language returns, a
	# template with no usable form must now fail at once.
	require Test::Mockingbird;
	local $App::Access2CSV::I18N::MESSAGES{en}{broken} = { one => 'x' };
	local $SIG{ALRM} = sub { die "i18n did not return: runaway recursion\n" };

	foreach my $answer ('', 'xx', 'en', undef) {
		my $guard = Test::Mockingbird::mock_scoped('App::Access2CSV::I18N::_language' => sub { $answer });
		alarm(10);
		throws_ok { $class->i18n('broken', { count => 2 }) } qr/\AUnknown message key: broken at /,
			'_language returning ' . (defined $answer ? "'$answer'" : 'undef') . ': fails at once';
		alarm(0);
		is($class->i18n('summary', { params => [2, 0], count => 2 }), 'Processed 2 tables, 0 failed', '... and complete templates still work');
	}
};

subtest 'protected helpers' => sub {
	my $obj = Local::Sub->new();

	throws_ok { $obj->boom() } qr/\AOutput file already exists: x\.csv .* at \S+ line \d+/, '_croak_i18n croaks with the message';
	throws_ok { $obj->boom() } qr/ at \Q${\ __FILE__ }\E line/, 'and blames the caller, not the wrapper';
	warning_like { is($obj->grumble(), $obj, '_carp_i18n returns $self') } qr/mdb-count not found/, '_carp_i18n warns';

	local $Sub::Protected::config{harness_bypass} = 0;
	local $Sub::Protected::BYPASS = 0;
	throws_ok { $obj->_croak_i18n('fatal', { params => ['x'] }) } qr/protected method/, 'cannot be called from outside';
};

done_testing();
