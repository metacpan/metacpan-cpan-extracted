# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
}
use Test::More;
plan( tests => 3 );
use_ok('Data::RefQueue');
my $q = new Data::RefQueue;
ok($q, 'create Data::RefQueue object');
$q->set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

