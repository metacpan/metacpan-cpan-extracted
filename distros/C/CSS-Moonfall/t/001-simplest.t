use strict;
use warnings;
use Test::More tests => 1;

my $out = Moonfall::SimplestExample->filter(<<"INPUT");
#site_container {
    width: [page_width];
    min-width: [page_width];
    }

#top_container {
    width: [page_width];
    font-size: [medium_em];
    }
INPUT

is($out, <<"EXPECTED", "simplest example from moonfall.org works");
#site_container {
    width: 1000px;
    min-width: 1000px;
    }

#top_container {
    width: 1000px;
    font-size: 1.1em;
    }
EXPECTED

BEGIN
{
    package Moonfall::SimplestExample;
    use CSS::Moonfall;

    our $page_width = 1000;
    our $medium_em = "1.1em";
}

