#!perl

use strict;
use warnings;

use Test::More 'no_plan';

use lib 'lib';
use App::Grepl::Results;

#
# Test constructor
#

can_ok 'App::Grepl::Results', 'new';

ok my $found = App::Grepl::Results->new( { file => 't/lib/quotes/quote1.pl' } ),
  '... and calling it with valid arguments should succeed';
isa_ok $found, 'App::Grepl::Results', '... and the object it returns';

is $found->file, 't/lib/quotes/quote1.pl',
    '... and it should return the correct file name';

can_ok $found, 'have_results';
ok ! $found->have_results, 
    '... and we should not have results yet';
can_ok $found, 'add_results';
ok $found->add_results('quote', [ 'string1', 'string2' ] ),
    '... and we should be able to add results';
ok $found->add_results('heredoc', ['only one result']),
    '... and now we add more results';
ok $found->have_results,
    '... and have_results() should return true';

can_ok $found, 'next';
ok my $result = $found->next, '... and calling it should succeed';
isa_ok $result, 'App::Grepl::Results::Token',
    '... and the object it returns';

can_ok $result, 'token';
is $result->token, 'quote', '... and it should identify the token type';

can_ok $result, 'next';
is $result->next, 'string1', '... and the first result should be correct';
is $result->next, 'string2', '... as should the second';
ok !defined $result->next, '... and we should be out of results';

ok $result = $found->next, 'Fetching the next result token should succeed';
is $result->token, 'heredoc', '... and it should identify its token type';
is $result->next, 'only one result', '... and we should get the next() string';
ok !defined $result->next, '... and have the correct number of results';


