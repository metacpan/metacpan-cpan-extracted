use strict;
use warnings;
use utf8;
use FindBin;

use Test::More;

use_ok 'Data::XLSX::Parser';

my $parser = Data::XLSX::Parser->new;
isa_ok $parser, 'Data::XLSX::Parser';

$parser->open("$FindBin::Bin/sample-data.xlsx");

my $workbook = $parser->workbook;
isa_ok $workbook, 'Data::XLSX::Parser::Workbook';

my @names = $workbook->names;
is scalar @names, 2, '2 workbook ok';

my $sheet_rid = $workbook->sheet_rid($names[0]);

done_testing;
