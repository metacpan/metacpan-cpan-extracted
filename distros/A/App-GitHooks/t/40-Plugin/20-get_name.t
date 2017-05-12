#!perl

use strict;
use warnings;

use App::GitHooks::Plugin;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Require git.
test_requires_git( '1.7.4.1' );
plan( tests => 6 );

can_ok(
	'App::GitHooks::Plugin',
	'get_name',
);

throws_ok(
	sub
	{
		App::GitHooks::Plugin->get_name();
	},
	qr/\QNot a valid plugin class: >App::GitHooks::Plugin<\E/,
	'The base class does not have a name.',
);

throws_ok(
	sub
	{
		App::GitHooks::Plugin::get_name( undef );
	},
	qr/\QYou need to call this method on a class\E/,
	'Make sure the method is called on a class (1).',
);

throws_ok(
	sub
	{
		App::GitHooks::Plugin::get_name( '' );
	},
	qr/\QYou need to call this method on a class\E/,
	'Make sure the method is called on a class (2).',
);

subtest(
	'Test standard plugin.',
	sub
	{
		plan( tests => 2 );

		my $name;
		lives_ok(
			sub
			{
				$name = App::GitHooks::Plugin::Test->get_name();
			},
			'Retrieve the name of the plugin.',
		);

		is(
			$name,
			'Test',
			'The plugin name is correct.',
		);
	}
);

subtest(
	'Test a plugin in a second-level namespace.',
	sub
	{
		plan( tests => 3 );

		use_ok( 'App::GitHooks::Plugin::Test::PrintSTDERR' );

		my $name;
		lives_ok(
			sub
			{
				$name = App::GitHooks::Plugin::Test::PrintSTDERR->get_name();
			},
			'Retrieve the name of the plugin.',
		);

		is(
			$name,
			'Test::PrintSTDERR',
			'The plugin name is correct.',
		);
	}
);


package App::GitHooks::Plugin::Test;

use base 'App::GitHooks::Plugin';

1;
