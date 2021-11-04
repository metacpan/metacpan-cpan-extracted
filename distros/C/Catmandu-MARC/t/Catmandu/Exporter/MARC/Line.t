#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Exporter::MARC;
use Catmandu::Importer::MARC;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::MARC::Line';
    use_ok $pkg;
}

require_ok $pkg;

my $marcline = undef;

note('Exporting to MARC/Line');
{
    my $exporter = Catmandu::Exporter::MARC->new(file => \$marcline, type=> 'Line');

    ok $exporter , 'got an MARC/Line exporter';

    ok $exporter->add({
        '_id' => '987874829',
        'record' => [
                        [ 'LDR', ' ', ' ', '_', '00251nas a2200121 c 4500' ],
                        [ '001', ' ', ' ', '_', '987874829' ],
                        [ '007', ' ', ' ', '_', 'cr||||||||||||' ],
                        [ '022', ' ', ' ', 'a', '1940-5758' ],
                        [ '041', ' ', ' ', 'a', 'eng' ],
                        [ 245, '0', '0', 'a', 'Code4Lib journal', 'b', 'C4LJ' ],
                        [ 246, '3', ' ', 'a', 'C4LJ' ],
                        [ 362, '0', ' ', 'a', '1.2007 -' ],
                        [ 856, '4', ' ', 'u', 'http://journal.code4lib.org/' ]
                    ]}) , 'add';

    ok $exporter->commit , 'commit';

    my $expected = <<'EOF';
00251nas a2200121 c 4500
001 987874829
007 cr||||||||||||
022    $a 1940-5758
041    $a eng
245 00 $a Code4Lib journal $b C4LJ
246 3  $a C4LJ
362 0  $a 1.2007 -
856 4  $u http://journal.code4lib.org/

EOF


    is $marcline, $expected, 'got the expected result';

}


note('Roundtripping');
{
    my $importer_iso = Catmandu::Importer::MARC->new(file => 't/camel.mrc', type=> 'ISO');

    ok $importer_iso , 'got an MARC/ISO importer';

    my $records_iso = $importer_iso->to_array;

    ok @$records_iso == 10, 'got all records';

    my $marcline;

    my $exporter = Catmandu::Exporter::MARC->new(file => \$marcline, type=> 'Line');

    ok $exporter , 'got an MARC/Line exporter';

    ok $exporter->add_many($records_iso) , 'add records';

    ok $exporter->commit , 'commit';

    my $importer_line = Catmandu::Importer::MARC->new(file => \$marcline, type=> 'Line');

    ok $importer_line , 'got an MARC/Line importer';

    my $records_line = $importer_line->to_array;

    ok @$records_line == 10, 'got all records';

    is_deeply $records_iso, $records_line, 'got expected result';
}

done_testing;
