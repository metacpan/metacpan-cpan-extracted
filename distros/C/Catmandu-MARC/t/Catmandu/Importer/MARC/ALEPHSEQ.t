#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::MARC::ALEPHSEQ';
    use_ok $pkg;
}

require_ok $pkg;

my $record =<<'EOF';
000000002 FMT   L BK
000000002 LDR   L 00000nam^a2200301^i^4500
000000002 001   L 000000002
000000002 008   L 050601s1921^^^^xx^||||||||||||||^||dut^^
000000002 24510 L $$aCatmandu Test
000000002 650 0 L $$aPerl
000000002 650 0 L $$aMARC$$aMARC2
000000002 650 0 L $$a加德滿都
EOF

my $expected = {
    _id => '000000002',
    record => [
      [ 'FMT', ' ', ' ' , '_', 'BK' ] ,
      [ 'LDR', ' ', ' ' , '_', '00000nam a2200301 i 4500' ] ,
      [ '001', ' ', ' ' , '_', '000000002' ] ,
      [ '008', ' ', ' ' , '_', '050601s1921    xx |||||||||||||| ||dut  ' ],
      [ '245', '1', '0' , 'a', 'Catmandu Test' ] ,
      [ '650', ' ', '0' , 'a', 'Perl' ] ,
      [ '650', ' ', '0' , 'a', 'MARC' , 'a' , 'MARC2' ] ,
      [ '650', ' ', '0' , 'a', '加德滿都' ] ,
    ]
};

note("inline pasing");
{
    my $importer = Catmandu::Importer::MARC->new( file => \$record, type => "ALEPHSEQ" );

    ok $importer , 'got an MARC/ALEPHSEQ importer';

    my $result = $importer->first;

    ok $result , 'got a record';

    is_deeply $result , $expected , 'got the expected result';
}

note("file pasing");
{
    my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );

    ok $importer , 'got an MARC/ALEPHSEQ importer';

    my $results = $importer->to_array;

    ok @$results == 2 , 'got two records';

    is_deeply $results->[0] , $expected , 'got the expected result';
}

done_testing;
