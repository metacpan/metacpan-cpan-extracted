#!/usr/bin/perl

use strict;
use Test::More tests => 1;

use Data::Phrasebook;

my $pb = Data::Phrasebook->new(
    file => 't/01phrases.txt',
    dict => 'Nonsense'
);

eval {$pb->fetch('foo')};
like ( $@, qr{^File \[t/01phrases.txt/Nonsense\] not accessible!}, 'fetch called data called dict and scalar was okay');