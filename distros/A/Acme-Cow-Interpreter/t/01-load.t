#!perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { use_ok('Acme::Cow::Interpreter'); }

diag("Testing Acme::Cow::Interpreter"
     . " $Acme::Cow::Interpreter::VERSION, Perl $], $^X");
