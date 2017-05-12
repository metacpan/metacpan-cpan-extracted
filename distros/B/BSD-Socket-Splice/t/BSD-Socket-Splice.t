use strict;
use warnings;

use Test::More tests => 2;

use_ok('BSD::Socket::Splice');
use_ok('BSD::Socket::Splice', qw(setsplice getsplice geterror SO_SPLICE));
