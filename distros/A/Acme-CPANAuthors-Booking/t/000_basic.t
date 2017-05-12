#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;
use Acme::CPANAuthors;

our $r = eval "require Test::NoWarnings; 1";

BEGIN {
    use_ok ('Acme::CPANAuthors::Booking') or
        BAIL_OUT ("Loading of 'Acme-CPANAuthors-Booking' failed");
}

ok defined $Acme::CPANAuthors::Booking::VERSION, "VERSION is set";

my $authors = Acme::CPANAuthors -> new ('Booking');

ok $authors, 'Got $authors';

ok $authors -> count, "There are authors";
my @ids = $authors -> id;
ok scalar @ids, "There are ids";
ok $authors -> name ("BOOK"), "Find a name";

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
