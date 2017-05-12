#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

BEGIN {
    use_ok ('Acme::MetaSyntactic::Themes::Abigail') or
        BAIL_OUT ("Loading of 'Acme::MetaSyntactic::Themes::Abigail' failed");
}

ok defined $Acme::MetaSyntactic::Themes::Abigail::VERSION, "VERSION is set";

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
