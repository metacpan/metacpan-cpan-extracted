# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Asterisk-Store-Queue.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('Asterisk::Store::Queue') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Asterisk::Store::Queue;
my $obj = Asterisk::Store::Queue->new(
        queue            => "kiwi",
	max              => 50,
        calls            => 48,
        abandoned        => 8,
        holdtime         => 23,
        completed        => 195,
        servicelevel     => 45,
        servicelevelperf => 90,
        weight           => 0,
        );
isa_ok ( $obj, Asterisk::Store::Queue, 'new method test' );

# use all the methods(read only)
my $queue = $obj->queue;
my $max = $obj->max;
my $calls = $obj->calls;
my $abandoned = $obj->abandoned;
my $holdtime = $obj->holdtime;
my $completed = $obj->completed;
my $servicelevel = $obj->servicelevel;
my $servicelevelperf = $obj->servicelevelperf;
my $weight = $obj->weight;

ok( $queue eq 'kiwi', 'queue method test');
ok( $max == 50, 'max method test');
ok( $calls == 48, 'calls method test');
ok( $abandoned == 8, 'abandoned method test');
ok( $holdtime == 23, 'holdtime method test');
ok( $completed == 195, 'completed method test');
ok( $servicelevel == 45, 'servicelevel method test');
ok( $servicelevelperf == 90, 'servicelevelperf method test');
ok( $weight == 0, 'weight method test');

# use all the methods that might need to be written to
$obj->calls(39);
$calls = $obj->calls;
ok( $calls == 39, 'calls method write test');

# test add_member method
use Asterisk::Store::Queue::Member;
my $memberobj = Asterisk::Store::Queue::Member->new(
        'queue' => "kiwi",
        'location'      => 'Local/5872@queuagents',
        'membership'    => "dynamic",
        'penalty'       => 1,
        'callstaken'    => 2,
        'paused'        => 0,
        'status'        => 4,
        'lastcall'      => 5
        );
my $memberobj2 = Asterisk::Store::Queue::Member->new(
        'queue' => "kiwi",
        'location'      => 'Local/5873@queuagents',
        'membership'    => "dynamic",
        'penalty'       => 1,
        'callstaken'    => 2,
        'paused'        => 0,
        'status'        => 4,
        'lastcall'      => 5
        );
$obj->add_member($memberobj);
$obj->add_member($memberobj2);


foreach my $tmp ( @{$obj->members} ) {
	isa_ok( $tmp, 'Asterisk::Store::Queue::Member' );
}
