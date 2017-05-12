#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;
use Acme::CPANAuthors;

BEGIN {
    use_ok ('Acme::CPANAuthors::CPANTS::FiveOrMore') or
       BAIL_OUT ("Loading of 'Acme::CPANAuthors::CPANTS::FiveOrMores' failed");
}

ok defined $Acme::CPANAuthors::CPANTS::FiveOrMore::VERSION, "VERSION is set";


my $authors = Acme::CPANAuthors -> new ('CPANTS::FiveOrMore');

ok $authors, 'Got $authors';

ok $authors -> count, "There are authors";
my @ids = $authors -> id;
ok scalar @ids, "There are ids";
ok $authors -> name ("ABIGAIL"), "Find a name";

done_testing;
