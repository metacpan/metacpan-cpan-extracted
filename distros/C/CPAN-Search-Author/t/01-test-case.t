#!perl

use 5.006;
use strict; use warnings;
use Test::More;
use CPAN::Search::Author;

eval { CPAN::Search::Author->new->by_id('MANWAR'); };
plan skip_all => "It appears you don't have internet access."
    if ($@ =~ /ERROR\: Couldn\'t connect to search\.cpan\.org/);

is(CPAN::Search::Author->new->by_id('MANWAR'), 'Mohammad S Anwar');

eval { CPAN::Search::Author->new->where_id_starts_with('1'); };
like($@, qr/ERROR: Invalid letter \[1\]./);

done_testing();
