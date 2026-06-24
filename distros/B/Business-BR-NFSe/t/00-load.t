use strict;
use warnings;
use Test::More tests => 2;

use Business::BR::NFSe;
pass 'Business::BR::NFSe loaded successfully';

can_ok 'Business::BR::NFSe', qw(new emitir danfse);
