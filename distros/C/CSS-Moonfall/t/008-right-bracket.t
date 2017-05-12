use strict;
use warnings;
use Test::More tests => 1;

my $out = eval { local $^W = 0; Moonfall::SimplestExample->filter(<<'INPUT') };
#site_container {
    width: [$foo[0]];
    }
INPUT

TODO: { local $TODO = "[...] finder is really really dumb";
is($out, <<"EXPECTED", "code with nested brackets works");
#site_container {
    width: 1000px;
    }
EXPECTED
}

BEGIN
{
    package Moonfall::SimplestExample;
    use CSS::Moonfall;

    our @foo = [1000];
}


