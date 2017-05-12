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
plan( tests => 4 );

can_ok(
	'App::GitHooks::Terminal',
	'get_encoding',
);

ok(
	my $terminal = App::GitHooks::Terminal->new(),
	'Instantiate a new object.',
);

my $encoding;
lives_ok(
	sub
	{
		$encoding = $terminal->get_encoding();
	},
	'Retrieve the terminal encoding',
);

ok(
	defined( $encoding ) && ( $encoding ne '' ),
	'The terminal encoding is defined.',
);

note( "Current terminal encoding is $encoding." );
