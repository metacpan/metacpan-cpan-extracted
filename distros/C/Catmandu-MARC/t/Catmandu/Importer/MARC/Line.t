#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::MARC::Line';
    use_ok $pkg;
}

require_ok $pkg;

my $record =<<'EOF';
00251nas a2200121 c 4500
001 987874829
007 cr||||||||||||
022    $a 1940-5758
041    $a eng
245 00 $a Code4Lib journal $b C4LJ
246 3  $a C4LJ
362 0  $a 1.2007 -
856 4  $u http://journal.code4lib.org/
999    $= foo $< bar $$ baz

EOF

my $expected = {
    '_id'    => '987874829',
    'record' => [
        ['LDR', ' ', ' ', '_', '00251nas a2200121 c 4500'],
        ['001', ' ', ' ', '_', '987874829'],
        ['007', ' ', ' ', '_', 'cr||||||||||||'],
        ['022', ' ', ' ', 'a', '1940-5758'],
        ['041', ' ', ' ', 'a', 'eng'],
        [245,   '0', '0', 'a', 'Code4Lib journal', 'b', 'C4LJ'],
        [246,   '3', ' ', 'a', 'C4LJ'],
        [362,   '0', ' ', 'a', '1.2007 -'],
        [856,   '4', ' ', 'u', 'http://journal.code4lib.org/'],
        [999,   ' ', ' ', '=', 'foo', '<', 'bar', '$', 'baz']
    ]
};

note('Importing from MARC/Line inline');
{
    my $importer = Catmandu::Importer::MARC->new( file => \$record, type => 'Line' );

    ok $importer , 'got an MARC/Line importer';

    my $result = $importer->first;

    ok $result , 'got a record';

    is_deeply $result , $expected , 'got expected result';
}

note('Importing from MARC/Line file');
{
    my $importer = Catmandu::Importer::MARC->new( file => 't/code4lib.line', type => "Line" );

    ok $importer , 'got an MARC/Line importer';

    my $result = $importer->first;

    is_deeply $result, $expected , 'got expected result';
}

done_testing;
