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

my $cells = [];
$parser->add_row_event_handler(
    sub {
        my ($row) = @_;
        push @$cells, $row;
    }
);

$parser->sheet_by_rid("rId1");
is $cells->[0][0], 'value1';

$cells = [];
$parser->sheet_by_rid("rId2");
is $cells->[0][0], 'value2';

done_testing;
