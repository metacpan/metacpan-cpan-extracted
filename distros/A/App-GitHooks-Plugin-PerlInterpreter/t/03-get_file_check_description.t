#!perl

use strict;
use warnings;

use App::GitHooks::Plugin::PerlInterpreter;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 3;
use Test::Type;


can_ok(
	'App::GitHooks::Plugin::PerlInterpreter',
	'get_file_check_description',
);

my $file_check_description;
lives_ok(
	sub
	{
		 $file_check_description = App::GitHooks::Plugin::PerlInterpreter->get_file_check_description();
	},
	'Retrieve the description.',
);

ok_string(
	$file_check_description,
	name        => 'The description',
	allow_empty => 0,
);
