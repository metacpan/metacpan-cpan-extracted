use strict;
use warnings;
use Test::More tests => 1;

my $out = Moonfall::Fill->filter(<<'INPUT');
#example {
    background-color: #996633;
    width: [$header_bottom_widths->{example}];
    height: 30px;
    }

#contact {
    background-color: #AF9256;
    width: [$header_bottom_widths->{contact}];
    height: 30px;
    }
INPUT

# note: hash keys come out in arbitrary order, so we sort them.  use an array
# ref if you want to define your own order
is($out, <<"EXPECTED", "fill example from moonfall.org works");
#example {
    background-color: #996633;
    width: 97px;
    height: 30px;
    }

#contact {
    background-color: #AF9256;
    width: 97px;
    height: 30px;
    }
EXPECTED

BEGIN
{
    package Moonfall::Fill;
    use CSS::Moonfall;

    our $logo_width = 300;

    # from Moonfall::SimplestExample, this suggests we want inheritance
    our $page_width = 1000;

    our $header_bottom_widths = fill {
        total => $page_width,
        borders_dummy => 10,
        logo => $logo_width,
        spacer => 300,
        example => undef,
        contact => undef,
        list => undef,
        download => undef,
    };
}

