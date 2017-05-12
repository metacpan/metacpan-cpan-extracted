#!/usr/bin/perl

use strict;
use warnings;

use Catmandu::Importer::MARC;
use Test::Simple tests => 3;

my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );

my @records;

my $n = $importer->each(
    sub {
        push( @records, $_[0] );
    }
);

ok(@records == 1);

ok($records[0]->{record}->[1]->[0] eq 'LDR');

ok($records[0]->{record}->[1]->[-1] !~ /\^/);

1;
