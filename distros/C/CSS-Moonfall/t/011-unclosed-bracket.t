use strict;
use warnings;
use Test::More tests => 1;

my $out = Moonfall::UnclosedBracket->filter(<<'INPUT');
#site_container {
    width: [$widths[1]
INPUT

is($out, <<'EXPECTED', "unclosed bracket works");
#site_container {
    width: [$widths[1]
EXPECTED

BEGIN
{
    package Moonfall::UnclosedBracket;
    use CSS::Moonfall;

    our @widths = (100, 200, 300, 2);
}


