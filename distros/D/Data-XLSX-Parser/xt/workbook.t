use strict;
use warnings;
use Test::More;
use FindBin;

use_ok 'Data::XLSX::Parser';

my $parser = Data::XLSX::Parser->new;
isa_ok $parser, 'Data::XLSX::Parser';

$parser->open("$FindBin::Bin/sample-data.xlsx");

my $workbook = $parser->workbook;
isa_ok $workbook, 'Data::XLSX::Parser::Workbook';

my @names = $workbook->names;
is scalar @names, 2, '2 workbook ok';

is $workbook->sheet_id($names[0]), 2, 'sheet_id 1 ok';
is $workbook->sheet_id($names[1]), 3, 'sheet_id 2 ok';

done_testing;
