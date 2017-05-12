#!perl
use warnings;
use strict;

use Test::More tests => 3;

use Acme::Your "Foo";

$Foo::willow = "geeky";
{
    your $willow = "cute";

    is($willow,       "cute",   "okay inside");
    is($Foo::willow,  "cute",   "okay qualified inside");
}

is($Foo::willow,  "geeky",   "okay qualified outside");


