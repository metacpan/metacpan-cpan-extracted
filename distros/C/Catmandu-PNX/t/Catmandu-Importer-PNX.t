#!perl

use strict;
use warnings;
use Test::More;

use Catmandu;
use XML::XPath;

use utf8;

BEGIN {
    use_ok 'Catmandu::Importer::PNX';
}

require_ok 'Catmandu::Importer::PNX';

my $xml = undef;

my $importer = Catmandu->importer('PNX', file => 't/test.pnx');

ok $importer , 'got a importer';

my $arr = $importer->to_array;

is int(@$arr) , 2 , 'imported 2 records';

my $record = $arr->[0];

is $record->{control}->{sourcerecordid}, '004400000' , 'got control.sourcerecordid';
is $record->{search}->{general}->[1], "UBM: P 45-3159" , 'got search.general.1';
is $record->{display}->{subject}->[2], "üåîø" , "got üåîø";

done_testing 7;
