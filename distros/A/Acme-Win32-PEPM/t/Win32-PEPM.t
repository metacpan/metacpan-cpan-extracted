# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl PE-HW.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Config;

use Test::More tests => 2;
BEGIN { use_ok('Win32::PEPM') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $r = system('cd ex/mod && "'.$^X.'" makefile.pl && "'.$Config{make}.'" clean '
       .'&& "'.$^X.'" makefile.pl && "'.$Config{make}.'" all '
       .'&& "'.$^X.'" -Mblib -MWin32::PEPM::Test -e"Win32::PEPM::Test::hello_world(); exit 0;"');
is($r >> 8, 0, "test module built sucessfully");
