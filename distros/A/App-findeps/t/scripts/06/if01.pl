use strict;
use warnings;

use lib 't/lib';

if (0) { require If::BeforeRequire }    # ignored
if (1) { require If::BeforeRequire }    # ignored by parser

require Dummy;                          # does not exist anywhere

exit;
