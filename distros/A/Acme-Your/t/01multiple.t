#!perl -w
use warnings;
use strict;

use Test::More tests => 2;

use Acme::Your "Foo";

{
    your ($beer, $fault);

    $beer  = "foamy";
    $fault = "muttley";


    is($Foo::beer,  "foamy",   "first var okay");
    is($Foo::fault, "muttley", "second var okay");
}

