% my $class = shift;
use strict;
use warnings;
use Test::More tests => 2;

use_ok '<%= $class %>';
use_ok '<%= $class %>::Routes';
