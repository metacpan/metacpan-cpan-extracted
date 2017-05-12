#!perl
#
# Initial "does it load and perform basic operations" tests

use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok('Acme::EdError') }
ok( defined $Acme::EdError::VERSION, '$VERSION defined' );
