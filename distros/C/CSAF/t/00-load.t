#!perl

use strict;
use warnings;

use Test::More;

use_ok('CSAF');
use_ok('CSAF::Util');
use_ok('CSAF::Type');
use_ok('CSAF::Builder');
use_ok('CSAF::Validator');

done_testing();

diag("CSAF $CSAF::VERSION, Perl $], $^X");
