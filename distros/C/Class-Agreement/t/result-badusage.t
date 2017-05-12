use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

use Class::Agreement;

dies_ok {result} "can't use result outside of postcondition";

