#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
use Test::More tests => 2;
use lib qw(../lib lib);
use Data::Range::Compare qw(HELPER_CB);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my %helper=HELPER_CB;
my $s=Data::Range::Compare->new(\%helper,3,4);
ok($s->previous_range_end==2,'$s->previous_range_end');
ok($s->next_range_start==5,'$s->next_range_start');
