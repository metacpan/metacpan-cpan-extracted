#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no warnings 'syntax';

use Test::More 0.88;
use Acme::CPANAuthors;

our $r = eval "require Test::NoWarnings; 1";

BEGIN {
    use_ok('Acme::CPANAuthors::DebianDev')
        or BAIL_OUT("Loading of 'Acme-CPANAuthors-DebianDev' failed");
}

ok defined $Acme::CPANAuthors::DebianDev::VERSION, "VERSION is set";

my $authors = Acme::CPANAuthors->new('DebianDev');

ok $authors, 'Got $authors';

ok $authors->count, "There are authors";
my @ids = $authors->id;
ok scalar @ids, "There are ids";
ok $authors->name("DDUMONT"), "Find a name";

Test::NoWarnings::had_no_warnings() if $r;

done_testing;
