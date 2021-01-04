use strict;
use warnings;
use Test::More;

use Catmandu::Exporter::XLS;
use Catmandu::Exporter::XLSX;
use Catmandu::Importer::XLS;
use Catmandu::Importer::XLSX;
use File::Temp qw(tempfile);
use IO::File;
use Encode qw(encode);

my @rows = (
    {'number' => '1', 'letter' => 'a'},
    {'number' => '2', 'letter' => 'b'},
    {'number' => '3', 'letter' => 'c'},
);

# XLS
# default
my ($fh, $filename) = tempfile();
my $exporter = Catmandu::Exporter::XLS->new(fh => $fh,);
isa_ok($exporter, 'Catmandu::Exporter::XLS');
can_ok($exporter, 'add');
can_ok($exporter, 'add_many');
can_ok($exporter, 'commit');

for my $row (@rows) {
    $exporter->add($row);
}
$exporter->commit();
close($fh);
my $rows = Catmandu::Importer::XLS->new(file => $filename)->to_array;
is_deeply($rows->[0], {number => 1, letter => 'a'}, 'XLS default');

# header
($fh, $filename) = tempfile();
$exporter = Catmandu::Exporter::XLS->new(fh => $fh, header => 0,);
$exporter->add_many(\@rows);
$exporter->commit();
close($fh);
$rows = Catmandu::Importer::XLS->new(file => $filename)->to_array;
is_deeply($rows->[0], {1 => '2', a => 'b'}, 'XLS option header');

($fh, $filename) = tempfile();
$exporter = Catmandu::Exporter::XLS->new(
    fh     => $fh,
    header => {letter => 'CHAR', number => 'NR'},
);
$exporter->add_many(\@rows);
$exporter->commit();
close($fh);
$rows = Catmandu::Importer::XLS->new(file => $filename)->to_array;
is_deeply(
    $rows->[0],
    {CHAR => 'a', NR => '1'},
    'XLS option header (backward compatibility)'
);

# fields
($fh, $filename) = tempfile();
$exporter = Catmandu::Exporter::XLS->new(fh => $fh, fields => 'letter',);
$exporter->add_many(\@rows);
$exporter->commit();
close($fh);
$rows = Catmandu::Importer::XLS->new(file => $filename)->to_array;
is_deeply($rows->[0], {letter => 'a'}, 'XLS option fields');

# colums
($fh, $filename) = tempfile();
$exporter = Catmandu::Exporter::XLS->new(
    fh      => $fh,
    fields  => 'number,letter',
    columns => 'NUMBER,LETTER',
);
$exporter->add_many(\@rows);
$exporter->commit();
close($fh);
$rows = Catmandu::Importer::XLS->new(file => $filename)->to_array;
is_deeply($rows->[0], {NUMBER => 1, LETTER => 'a'}, 'XLS option columns');

# XLSX
# default
($fh, $filename) = tempfile();
$exporter = Catmandu::Exporter::XLSX->new(fh => $fh,);
isa_ok($exporter, 'Catmandu::Exporter::XLSX');
can_ok($exporter, 'add');
can_ok($exporter, 'add_many');
can_ok($exporter, 'commit');

for my $row (@rows) {
    $exporter->add($row);
}
$exporter->commit();
close($fh);
$rows = Catmandu::Importer::XLSX->new(file => $filename)->to_array;
is_deeply($rows->[0], {number => 1, letter => 'a'}, 'XLSX default');

# header
($fh, $filename) = tempfile();
$exporter = Catmandu::Exporter::XLSX->new(fh => $fh, header => 0,);
$exporter->add_many(\@rows);
$exporter->commit();
close($fh);
$rows = Catmandu::Importer::XLSX->new(file => $filename)->to_array;
is_deeply($rows->[0], {1 => '2', a => 'b'}, 'XLSX option header');

($fh, $filename) = tempfile();
$exporter = Catmandu::Exporter::XLSX->new(
    fh     => $fh,
    header => {letter => 'CHAR', number => 'NR'},
);
$exporter->add_many(\@rows);
$exporter->commit();
close($fh);
$rows = Catmandu::Importer::XLSX->new(file => $filename)->to_array;
is_deeply(
    $rows->[0],
    {CHAR => 'a', NR => '1'},
    'XLS option header (backward compatibility)'
);

# fields
($fh, $filename) = tempfile();
$exporter = Catmandu::Exporter::XLSX->new(fh => $fh, fields => 'letter',);
$exporter->add_many(\@rows);
$exporter->commit();
close($fh);
$rows = Catmandu::Importer::XLSX->new(file => $filename)->to_array;
is_deeply($rows->[0], {letter => 'a'}, 'XLSX option fields');

# colums
($fh, $filename) = tempfile();
$exporter = Catmandu::Exporter::XLSX->new(
    fh      => $fh,
    fields  => 'number,letter',
    columns => 'NUMBER,LETTER',
);
$exporter->add_many(\@rows);
$exporter->commit();
close($fh);
$rows = Catmandu::Importer::XLSX->new(file => $filename)->to_array;
is_deeply($rows->[0], {NUMBER => 1, LETTER => 'a'}, 'XLSX option columns');

done_testing;
