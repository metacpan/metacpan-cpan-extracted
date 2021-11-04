#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Exporter::MARC;
use Catmandu::Importer::MARC;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::MARC::MARCMaker';
    use_ok $pkg;
}

require_ok $pkg;

my $marcmaker = undef;

note("Exporting to MARCMaker");
{
    my $exporter = Catmandu::Exporter::MARC->new(file => \$marcmaker, type=> 'MARCMaker');

    ok $exporter , 'got an MARC/MARCMaker exporter';

    ok $exporter->add({
    _id => '1' ,
    record => [
                ['FMT', undef, undef, '_', 'BK'],
                ['001', undef, undef, '_', 'rec001'],
                ['100', ' ', ' ', 'a', 'Davis, Miles' , 'c' , 'Test'],
                ['245', ' ', ' ',
                    'a', 'Sketches in Blue' ,
                ],
                ['500', ' ', ' ', 'a', undef],
                ['501', ' ', ' ' ],
                ['502', ' ', ' ', 'a', undef, 'b' , 'ok'],
                ['503', ' ', ' ', 'a', ''],
                ['CAT', ' ', ' ', 'a', 'test'],
            ]
    }) , 'add';

    ok $exporter->commit , 'commit';
}

note("Roundtripping");
{
    my $importer = Catmandu::Importer::MARC->new(file => 't/oschrift_me.mrc', type=> 'ISO');

    ok $importer , 'got an MARC/MARCMaker importer';

    my $records = $importer->to_array;

    ok @$records == 1;

    my $marcmaker;

    my $exporter = Catmandu::Exporter::MARC->new(file => \$marcmaker, type=> 'MARCMaker');

    ok $exporter->add($records->[0]) , 'commit';

    ok $exporter->commit , 'commit';

    my $importer2 = Catmandu::Importer::MARC->new(file => \$marcmaker, type=> 'MARCMaker');

    ok $importer2 , 'got an MARC/MARCMaker importer';

    my $records2 = $importer2->to_array;

    ok @$records2 == 1;

    is_deeply $records->[0] , $records2->[0];
}

done_testing;
