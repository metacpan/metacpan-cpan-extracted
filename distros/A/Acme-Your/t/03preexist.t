#!perl
use warnings;
use strict;

use Test::More tests => 2;

use Data::Dumper;
use Acme::Your "Data::Dumper";

your $Varname;

is($Data::Dumper::Varname, "VAR", "hasn't affected globals");
is($Varname,               "VAR", "preexisting is right");



