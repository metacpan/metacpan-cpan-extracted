#!/usr/bin/perl

use strict;
use warnings;

use Catmandu::Importer::MARC;
use Test::Simple tests => 2;

my $importer = Catmandu::Importer::MARC->new( file => 't/sample1.lif', type => "MicroLIF" );

my @records;

my $n = $importer->each(
    sub {
        push( @records, $_[0] );
    }
);

ok(@records == 1);

ok($records[0]->{record}->[1]->[0] eq '008');

1;
