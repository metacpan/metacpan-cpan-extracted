#!perl

=head1 DESCRIPTION

Verify that the get_file_pattern() subroutine returns a pattern to match file names
against.

=cut

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;
use Test::Type;

use App::GitHooks::Plugin::PerlCritic;


can_ok(
	'App::GitHooks::Plugin::PerlCritic',
	'get_file_pattern',
);

ok_regex(
	App::GitHooks::Plugin::PerlCritic->get_file_pattern(),
	name => 'The return value of get_file_pattern()',
);
