# this test is borrowed from Archive::Any to secure compatibility

use strict;
use warnings;
use Archive::Any::Lite;
use Test::More tests => 1;

ok( !Archive::Any::Lite->new("im_not_really_a.zip") );
