#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More tests => 6;
use Acme::CPANAuthors;

BEGIN {
    use_ok ('Acme::CPANAuthors::European');
}

ok defined $Acme::CPANAuthors::European::VERSION, "VERSION is set";


my $authors = Acme::CPANAuthors -> new ('European');

ok $authors, 'Got $authors';

ok $authors -> count, "There are authors";
my @ids = $authors -> id;
ok scalar @ids, "There are ids";
ok $authors -> name ("ABIGAIL"), "Find a name";
