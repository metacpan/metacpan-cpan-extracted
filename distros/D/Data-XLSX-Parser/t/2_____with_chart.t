use strict;
use warnings;
use utf8;

use FindBin;
use Test::More;

use Data::XLSX::Parser;

my $parser = Data::XLSX::Parser->new;

my $fn = __FILE__;
$fn =~ s{t$}{xlsx};

$parser->open($fn);

my @sheets = $parser->workbook->names;
is scalar @sheets, 4, '4 worksheets ok';

is $sheets[0], 'Tabelle1', 'sheet1 name ok';

my $cells = [];
$parser->add_row_event_handler(sub {
    my ($row) = @_;
    push @$cells, $row;
});

$parser->sheet($parser->workbook->sheet_id($sheets[0]));

is $cells->[0][0], 1, 'val 0,0 ok';
is $cells->[0][1], 10, 'val 0,1 ok';
is $cells->[1][0], 2, 'val 1,0 ok';
is $cells->[1][1], 20, 'val 1,1 ok';

done_testing;
    
