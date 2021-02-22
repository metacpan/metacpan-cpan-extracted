use strict;
use warnings;
use utf8;

use FindBin;
use Test::More;

use Data::XLSX::Parser;
use Data::Dumper;

my $parser = Data::XLSX::Parser->new;

my $fn = __FILE__;
$fn =~ s{t$}{xlsx};

$parser->open($fn);

my @sheets = $parser->workbook->names;
is scalar @sheets, 1, '1 worksheets ok';

is $sheets[0], 'Sheet1', 'sheet1 name ok';

my $cells = [];
$parser->add_row_event_handler(sub {
    my ($row,$rowDetails) = @_;
    push @$cells, $rowDetails;
});

$parser->sheet_by_id(1);
is $cells->[0][0]->{v}, 'DataCol1', 'val ok';
is $cells->[0][1]->{v}, 'DataCol2', 'val ok';
is $cells->[0][0]->{row}, 1, 'row ok';
is $cells->[0][1]->{row}, 1, 'row ok';
is $cells->[0][0]->{c}, 1, 'col ok';
is $cells->[0][1]->{c}, 2, 'col ok';
is $cells->[1][0]->{v}, '1', 'val ok';
is $cells->[1][1]->{v}, 'Data1', 'val ok';
is $cells->[1][0]->{c}, 1, 'col ok';
is $cells->[1][1]->{c}, 2, 'col ok';

done_testing;
    
