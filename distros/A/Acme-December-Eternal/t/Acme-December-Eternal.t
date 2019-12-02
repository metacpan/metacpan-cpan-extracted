# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Acme-December-Eternal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('Acme::December::Eternal') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(eternaldecemberize('2019-01-01 10:28:00'), 'Tue, 123rd December 2018', 'Jan 01st');
is(eternaldecemberize('2019-08-01 10:28:00'), 'Thu, 1st August 2019', 'Aug 01st');
is(eternaldecemberize('2019-08-31 17:32:00'), 'Sat, 31st August 2019', 'Aug 31st');
is(eternaldecemberize('2019-09-01 17:32:00'), 'Sun, 1st December 2019', 'Sep 01st');
is(eternaldecemberize('2019-12-31 19:01:02'), 'Tue, 122nd December 2019', 'Dec 31st');
