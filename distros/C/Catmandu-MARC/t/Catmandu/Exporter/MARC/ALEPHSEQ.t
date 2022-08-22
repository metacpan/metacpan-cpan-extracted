#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Exporter::MARC;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::MARC::ALEPHSEQ';
    use_ok $pkg;
}

require_ok $pkg;

note("catmandu marc export");
{
    my $alephseq = undef;

    my $record = {
        _id => '000000002',
        record => [
          [ 'FMT', ' ', ' ' , '_', 'BK' ] ,
          [ 'LDR', ' ', ' ' , '_', '00000nam a2200301 i 4500' ] ,
          [ '001', ' ', ' ' , '_', '000000002' ] ,
          [ '008', ' ', ' ' , '_', '050601s1921    xx |||||||||||||| ||dut  ' ],
          [ '245', '1', '0' , 'a', 'Catmandu Test' ] ,
          [ '650', ' ', '0' , 'a', 'Perl' ] ,
          [ '650', ' ', '0' , 'a', 'MARC' , '<' , 'MARC2' ] ,
          [ '650', ' ', '0' , 'a', '加德滿都' ] ,
        ]
    };

    my $expected =<<'EOF';
000000002 FMT   L BK
000000002 LDR   L 00000nam^a2200301^i^4500
000000002 001   L 000000002
000000002 008   L 050601s1921^^^^xx^||||||||||||||^||dut^^
000000002 24510 L $$aCatmandu Test
000000002 650 0 L $$aPerl
000000002 650 0 L $$aMARC$$<MARC2
000000002 650 0 L $$a加德滿都
EOF

    my $exporter = Catmandu::Exporter::MARC->new(file => \$alephseq, type=> 'ALEPHSEQ' , skip_empty_subfields => 1);

    ok $exporter , 'got an MARC/ALEPHSEQ exporter';

    ok $exporter->add($record) , 'add a record';

    ok $exporter->commit , 'commit';

    is_deeply $alephseq , $expected , 'got expected results';
}

note("marc-in-json export");
{
    my $alephseq ;


    my $exporter = Catmandu::Exporter::MARC->new(
                      file => \$alephseq,
                      type=> 'ALEPHSEQ',
                      record_format => 'MARC-in-JSON',
                      skip_empty_subfields => 1
    );

    ok($exporter, "create exporter ALEPHSEQ for MARC-in-JSON");

    my $record = {
        _id => '000000002',
        leader => "00000nam a2200301 i 4500" ,
        fields => [
            { '001'  => '000000002' } ,
            { '245'  => {
                    ind1 => '1' ,
                    ind2 => '0' ,
                    subfields => [
                        { a => 'Catmandu Test'}
                    ]
                }
            } ,
            { '650'  => {
                    ind1 => ' ' ,
                    ind2 => '0' ,
                    subfields => [
                        { a => 'Perl'}
                    ]
                }
            } ,
            { '650'  => {
                    ind1 => ' ' ,
                    ind2 => '0' ,
                    subfields => [
                        { a => 'MARC'} ,
                        { '<' => 'MARC2'}
                    ]
                }
            } ,
            { '650'  => {
                    ind1 => ' ' ,
                    ind2 => '0' ,
                    subfields => [
                        { a => '加德滿都'}
                    ]
                }
            } ,
        ]
    };

    my $expected =<<'EOF';
000000002 FMT   L BK
000000002 LDR   L 00000nam^a2200301^i^4500
000000002 001   L 000000002
000000002 24510 L $$aCatmandu Test
000000002 650 0 L $$aPerl
000000002 650 0 L $$aMARC$$<MARC2
000000002 650 0 L $$a加德滿都
EOF

    ok $exporter->add($record), 'add record';

    ok $exporter->commit() , 'commit';

    is_deeply $alephseq , $expected , 'got expected results';
}

done_testing;
