#!perl

use strict;
use warnings;

use App::GitHooks::Terminal;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;
use Test::Type;


# Require git.
test_requires_git( '1.7.4.1' );
plan( tests => 3 );

can_ok(
	'App::GitHooks::Terminal',
	'new',
);

my $terminal;
lives_ok(
	sub
	{
		$terminal = App::GitHooks::Terminal->new();
	},
	'Instantiate a new object.',
);

ok_instance(
	$terminal,
	name  => 'Terminal object',
	class => 'App::GitHooks::Terminal',
);
