use strict;
use warnings;
use Test::More tests => 1;

my $out = Moonfall::NestedHash->filter(<<"INPUT");
foo
{
    [all_attrs]
}
INPUT

is($out, <<"EXPECTED", "nested hash example from moonfall.org works");
foo
{
    background-color: black;
    clear: both;
    color: red;
    float: left;
}
EXPECTED

BEGIN
{
    package Moonfall::NestedHash;
    use CSS::Moonfall;

    our $goth_theme = {
        color => "red",
        background_color => "black",
    };

    our $float_attrs = {
        float => "left",
        clear => "both",
    };

    our $all_attrs = {
        dummy1 => $goth_theme,
        dummy2 => $float_attrs,
    };
}

