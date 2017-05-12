use strict;
use warnings;
use Test::More tests => 1;

my $out = Moonfall::SimpleExample->filter(<<"INPUT");
#example  a { [nav_link_attrs] }
#contact  a { [nav_link_attrs] }
#list     a { [nav_link_attrs] }
#download a { [nav_link_attrs] }
INPUT

# note: hash keys come out in arbitrary order, so we sort them.  use an array
# ref if you want to define your own order
is($out, <<"EXPECTED", "simple example from moonfall.org works");
#example  a { color: white; float: right; font-size: 1.1em; line-height: 40px; margin-right: 5px; }
#contact  a { color: white; float: right; font-size: 1.1em; line-height: 40px; margin-right: 5px; }
#list     a { color: white; float: right; font-size: 1.1em; line-height: 40px; margin-right: 5px; }
#download a { color: white; float: right; font-size: 1.1em; line-height: 40px; margin-right: 5px; }
EXPECTED

BEGIN
{
    package Moonfall::SimpleExample;
    use CSS::Moonfall;

    # from Moonfall::SimplestExample, this suggests we want inheritance
    our $page_width = 1000;
    our $medium_em = "1.1em";

    our $nav_link_attrs = [
        float => "right",
        line_height => 40,
        margin_right => 5,
        font_size => $medium_em,
        color => "white",
    ];
}

