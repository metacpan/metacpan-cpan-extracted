#!perl -I../lib
use strict;
use warnings;
use Acme::CPANAuthors;
my $authors
    = Acme::CPANAuthors->new('Acme::CPANAuthors::Acme::CPANAuthors::Authors');
printf 'ACACA v%s contains %d authors and is brought to you by %s.',
    $Acme::CPANAuthors::Acme::CPANAuthors::Authors::VERSION, $authors->count,
    $authors->name('SANKO');
