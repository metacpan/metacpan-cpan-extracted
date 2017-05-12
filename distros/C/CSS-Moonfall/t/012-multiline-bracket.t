use strict;
use warnings;
use Test::More tests => 1;

my $out = Moonfall::MultilineBracket->filter(<<'INPUT');
#site_container {
    width: [
        $widths[1]
    ];
    min-width: [



$widths[0]];
    }

#top_container {
    width: [
        $widths[
            $widths[
                3
            ]
        ]
    ];
    }
INPUT

is($out, <<"EXPECTED", "multiline brackets work");
#site_container {
    width: 200px;
    min-width: 100px;
    }

#top_container {
    width: 300px;
    }
EXPECTED

BEGIN
{
    package Moonfall::MultilineBracket;
    use CSS::Moonfall;

    our @widths = (100, 200, 300, 2);
}

