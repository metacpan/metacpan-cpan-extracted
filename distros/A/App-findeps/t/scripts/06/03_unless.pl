use strict;
use warnings;

use lib 't/lib';

unless (0) { require If::BeforeRequire }    # ignored
unless (1) { require If::BeforeRequire }    # ignored by parser

require Dummy;                              # does not exist anywhere

exit;
