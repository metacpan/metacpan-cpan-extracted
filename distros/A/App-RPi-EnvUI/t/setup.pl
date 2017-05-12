use warnings;
use strict;

use lib 't/';
use TestBase;

`touch t/testing.lck`;
config();
db_create();
