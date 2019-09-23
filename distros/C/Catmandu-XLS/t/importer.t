use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Catmandu::Importer::XLS;
use Catmandu::Importer::XLSX;

# XLS

my $importer = Catmandu::Importer::XLS->new(file => './t/test.xls');
isa_ok($importer, 'Catmandu::Importer::XLS');
can_ok($importer, 'each');
my $rows = $importer->to_array();
is_deeply($rows->[0], {Column1 => 1, Column2 => 'a', Column3 => 0.01},
    'XLS default');
is_deeply($rows->[1], {Column1 => 2, Column2 => 'b', Column3 => 2.5},
    'XLS default');
is_deeply($rows->[5], {Column1 => 6, Column2 => 'f', Column3 => '01/01/90'},
    'XLS format');
is_deeply($rows->[-1], {Column1 => 27, Column3 => 'Ümlaut'}, 'XLS UTF-8');

$importer
    = Catmandu::Importer::XLS->new(file => './t/test.xls', fields => 'a,b,c');
$rows = $importer->to_array();
is_deeply($rows->[0], {a => 1, b => 'a', c => 0.01}, 'XLS option fields');
is_deeply($rows->[-1], {a => 27, c => 'Ümlaut'}, 'XLS option fields');

$importer
    = Catmandu::Importer::XLS->new(file => './t/test.xls', columns => 1);
$rows = $importer->to_array();
is_deeply($rows->[0], {A => 1, B => 'a', C => 0.01}, 'XLS option columns');
is_deeply($rows->[-1], {A => 27, C => 'Ümlaut'}, 'XLS option columns');

$importer = Catmandu::Importer::XLS->new(file => './t/test.xls', header => 0);
$rows     = $importer->to_array();
is_deeply(
    $rows->[0],
    {A => 'Column1', B => 'Column2', C => 'Column3'},
    'XLS option header'
);
is_deeply($rows->[-1], {A => 27, C => 'Ümlaut'}, 'XLS option header');

$importer = Catmandu::Importer::XLS->new(
    file      => './t/test.xls',
    header    => 0,
    worksheet => 1
);
$rows = $importer->to_array();
is_deeply($rows->[0], {A => 'a', B => '1'}, 'XLS option worksheet');

# XLSX

$importer = Catmandu::Importer::XLSX->new(file => './t/test.xlsx');
isa_ok($importer, 'Catmandu::Importer::XLSX');
can_ok($importer, 'each');
$rows = $importer->to_array();
is_deeply($rows->[0], {Column1 => 1, Column2 => 'a', Column3 => 0.01},
    'XLSX default');
is_deeply($rows->[1], {Column1 => 2, Column2 => 'b', Column3 => 2.5},
    'XLSX default');
is_deeply($rows->[5], {Column1 => 6, Column2 => 'f', Column3 => '01/01/90'},
    'XLSX format');
is_deeply($rows->[-1], {Column1 => 27, Column3 => 'Ümlaut'}, 'XLSX UTF-8');

$importer = Catmandu::Importer::XLSX->new(file => './t/test.xlsx',
    fields => 'a,b,c');
$rows = $importer->to_array();
is_deeply($rows->[0], {a => 1, b => 'a', c => 0.01}, 'XLSX option fields');
is_deeply($rows->[-1], {a => 27, c => 'Ümlaut'}, 'XLSX option fields');

$importer
    = Catmandu::Importer::XLSX->new(file => './t/test.xlsx', columns => 1);
$rows = $importer->to_array();
is_deeply($rows->[0], {A => 1, B => 'a', C => 0.01}, 'XLSX option columns');
is_deeply($rows->[-1], {A => 27, C => 'Ümlaut'}, 'XLSX option columns');

$importer
    = Catmandu::Importer::XLSX->new(file => './t/test.xlsx', header => 0);
$rows = $importer->to_array();
is_deeply(
    $rows->[0],
    {A => 'Column1', B => 'Column2', C => 'Column3'},
    'XLSX option header'
);
is_deeply($rows->[-1], {A => 27, C => 'Ümlaut'}, 'XLSX option header');

$importer = Catmandu::Importer::XLSX->new(
    file      => './t/test.xlsx',
    header    => 0,
    worksheet => 1
);
$rows = $importer->to_array();
is_deeply($rows->[0], {A => 'a', B => '1'}, 'XLSX option worksheet');

done_testing;
