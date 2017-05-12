package CMTests::TestClass;

use strict;
use warnings;

use base qw(Test::Class);

INIT { Test::Class->runtests }

1;
