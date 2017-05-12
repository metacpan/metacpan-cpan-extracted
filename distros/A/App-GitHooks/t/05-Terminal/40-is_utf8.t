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
	'is_utf8',
);

ok(
	my $terminal = App::GitHooks::Terminal->new(),
	'Instantiate a new object.',
);

my $is_utf8;
lives_ok(
	sub
	{
		$is_utf8 = $terminal->is_utf8();
	},
	'Test if the terminal supports utf8.',
);

note( 'Current terminal ' . ( $is_utf8 ? 'supports' : 'does not support' ) . ' utf8.' );
