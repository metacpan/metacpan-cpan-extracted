# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Asterisk-Store-Queue-Member.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('Asterisk::Store::Queue::Member') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Asterisk::Store::Queue::Member;
my $obj = Asterisk::Store::Queue::Member->new(
        'queue' => "kiwi",
        'location'      => 'Local/5872@queuagents',
        'membership'    => "dynamic",
        'penalty'       => 1,
        'callstaken'    => 2,
        'paused'        => 0,
        'status'        => 4,
        'lastcall'      => 5
        );
isa_ok ( $obj, Asterisk::Store::Queue::Member, 'new method test' );

# use all the methods(read only)
my $queue = $obj->queue;
my $location = $obj->location;
my $membership = $obj->membership;
my $penalty = $obj->penalty;
my $callstaken = $obj->callstaken;
my $paused = $obj->paused;
my $status = $obj->status;
my $lastcall = $obj->lastcall;

ok( $queue eq 'kiwi', 'queue method test');
ok( $location eq 'Local/5872@queuagents', 'location method test');
ok( $membership eq 'dynamic', 'membership method test');
ok( $penalty == 1, 'penalty method test');
ok( $callstaken == 2, 'callstaken method test');
ok( $paused == 0, 'paused method test');
ok( $status == 4, 'status method test');
ok( $lastcall == 5, 'lastcall method test');

# use all the methods that might need to be written to
$obj->callstaken(47);
$callstaken = $obj->callstaken;
ok( $callstaken == 47, 'callstaken method write test');
