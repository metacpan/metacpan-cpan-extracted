#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More tests => 4;
use Acme::CPANAuthors;

BEGIN {
    use_ok ('Acme::CPANAuthors::Dutch');
}

ok defined $Acme::CPANAuthors::Dutch::VERSION, "VERSION is set";

my $authors = Acme::CPANAuthors -> new ('Dutch');

ok $authors;

is $authors -> count, 1, "Nobody home!";
