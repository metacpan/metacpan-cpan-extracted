#!perl

use strict;
use warnings FATAL => 'all';
use lib qw(t/lib lib);
use Test::More;

#########################

plan tests => 1;

no warnings 'all';
use_ok('Apache2::ModXml2') ;
use warnings;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

