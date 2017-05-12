# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Crypt::Imail') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $cm = Crypt::Imail->new;

ok($cm->encrypt('bgannon','test'), 'D6CCD4E2');
ok($cm->decrypt('bgannon','D6CCD4E2'), 'test');

ok($cm->encrypt('mike','rocks'), 'DFD8CED0E0');
ok($cm->decrypt('mike','DFD8CED0E0'), 'rocks');
