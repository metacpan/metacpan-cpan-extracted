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
is scalar @sheets, 3, '3 worksheets ok';

is $sheets[0], 'POST_DSENDS', 'sheet1 name ok';

my $cells = [];
$parser->add_row_event_handler(sub {
    my ($row) = @_;
    push @$cells, $row;
});

$parser->sheet(1);

is $cells->[112][0], 'RCS Thrust Vector Uncertainties ', 'val ok';

done_testing;
    
