#!/usr/bin/env perl

=head1 DESCRIPTION

Verify that the get_file_pattern() subroutine returns a pattern to match file names
against.

=cut

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;
use Test::Type;

use App::GitHooks::Plugin::Test::CustomReply;


# Require git.
test_requires_git( '1.7.4.1' );
plan( tests => 2 );

can_ok(
	'App::GitHooks::Plugin::Test::CustomReply',
	'get_file_pattern',
);

ok_regex(
	App::GitHooks::Plugin::Test::CustomReply->get_file_pattern(),
	name => 'The return value of get_file_pattern()',
);
