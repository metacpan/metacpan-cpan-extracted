#!perl

use strict;
use warnings;

use Test::More 'no_plan';

use lib 'lib';
use App::Grepl;

#
# Test constructor
#

can_ok 'App::Grepl', 'new';

ok my $grepl = App::Grepl->new( { dir => 't/' } ),
  '... and calling it with valid arguments should succeed';
isa_ok $grepl, 'App::Grepl', '... and the object it returns';

#
# Test dir()
#

can_ok $grepl, 'dir';
is $grepl->dir, 't/',
  '... and it should return the value passed in the constructor';

ok $grepl->dir(undef), 'We should be able to unset dir()';
ok !defined $grepl->dir, '... and it will now return undef';

ok $grepl->dir('t/lib/quotes/'),
  'We should be able to set dir() to a new directory';
is $grepl->dir, 't/lib/quotes/', '... and have it return that directory';

#
# search()
#

can_ok $grepl, 'search';
ok my @search = $grepl->search, '... and it should return results';
is scalar @search, 1, '... but only one result object';

my $found = shift @search;
isa_ok $found, 'App::Grepl::Results';
is $found->file, 't/lib/quotes/quote1.pl',
  '... and it should tell us the file it found results in';

ok my $results = $found->next, 'We should be able to call next()';
is $results->token, 'quote', '... and quote elements were matched';
is $results->next, 'double quoted string',
  '... and we can get the first quote match';
is $results->next, 'single quoted string',
  '... and we can get the second quote match';
is $results->next, 'q{} quoted string',
  '... and we can get the third quote match';
is $results->next, 'qq{} quoted string',
  '... and we can get the last quote match';
ok !defined $results->next, '... and we should have no more results';

ok $results = $found->next, 'We should be able to call next()';
is $results->token, 'heredoc', '... and heredoc elements were matched';
is $results->next, "heredoc string\n   with two lines\n",
  '... and we can get the first herdoc match';
ok !defined $results->next, '... and we should have no more results';
ok !defined $found->next,   'found() should return undef when done';

$grepl->pattern('q+{');
ok @search = $grepl->search, 'We should be able to do a new search';

$found = shift @search;
isa_ok $found, 'App::Grepl::Results';
is $found->file, 't/lib/quotes/quote1.pl',
  '... and it should tell us the file it found results in';

ok $results = $found->next, 'We should be able to call next()';
is $results->token, 'quote', '... and quote elements were matched';
is $results->next, 'q{} quoted string',
  '... and we can get the first string match';
is $results->next, 'qq{} quoted string',
  '... and we can get the second string match';
ok !defined $results->next, '... and we should have no more results';

ok $grepl = App::Grepl->new,
  '... and calling it with no arguments should succeed';
is $grepl->dir, '.', '... and it should default to searching the current dir';
