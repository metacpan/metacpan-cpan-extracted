#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
use lib qw(../lib lib);
use Data::Range::Compare qw(HELPER_CB);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my %helper=HELPER_CB;
my $obj=Data::Range::Compare->new(\%helper,0,1);
ok($obj->range_start==0,'range start should be 0');
ok($obj->range_end==1,'range end should be 1');
ok($obj->previous_range_end==-1,'previous_range_end should be -1');
ok($obj->next_range_start==2,'next range_start should be 2');
