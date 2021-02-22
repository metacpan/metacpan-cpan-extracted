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

my (%col, $i);

$parser->add_row_event_handler(sub {
    my ($row) = @_;

    unless (%col) {
        $col{ $_ } = $i++ for @$row;
        return;
    }

    is $row->[ $col{A} ], 'a', 'a ok';
    is $row->[ $col{B} ], '', 'b is empty ok';
    is $row->[ $col{C} ], 'c', 'c ok';
});

my $name = ( $parser->workbook->names )[0];
my $rid  = $parser->workbook->sheet_rid( $name );
$parser->sheet_by_rid( $rid );

ok $i, 'callback running ok';

done_testing;
