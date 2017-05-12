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

$parser->sheet(1);

ok $i, 'callback running ok';

done_testing;
