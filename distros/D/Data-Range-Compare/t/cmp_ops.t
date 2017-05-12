#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
use Test::More tests => 15;
use lib qw(../lib lib);
use Data::Range::Compare qw(:HELPER HELPER_CB);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my %helper=HELPER_CB;
ok(cmp_values(0,0)==0,'comparing 0 to 0 should return 0');
ok(cmp_values(1,0)==1,'comparing 1 to 0 should return 1');
ok(cmp_values(0,1)==-1,'comparing 0 to 1 should return -1');

ok(add_one(1)==2,'adding 1 to 1 should return 2');
ok(sub_one(3)==2,'subtracting 1 from 3 should return 2');

# a is contiugous with b and b is contiguous with c
my $cmp_a=Data::Range::Compare->new(\%helper,0,1);
my $cmp_b=Data::Range::Compare->new(\%helper,2,3);
my $cmp_c=Data::Range::Compare->new(\%helper,3,4);

ok($cmp_a->cmp_range_start($cmp_a)==0
  ,'$cmp_a->range_start == $cmp_a->range_start'
);
ok($cmp_a->cmp_range_start($cmp_b)!=0
  ,'$cmp_a->range_start != $cmp_b->range_start'
);
ok($cmp_a->cmp_range_start($cmp_b)==-1
  ,'$cmp_a->range_start < $cmp_b->range_start'
);
ok($cmp_b->cmp_range_start($cmp_a)==1
  ,'$cmp_b->range_start > $cmp_a->range_start'
);

ok($cmp_a->cmp_range_end($cmp_a)==0
  ,'$cmp_a->range_start == $cmp_a->range_start'
);
ok($cmp_a->cmp_range_end($cmp_b)!=0
  ,'$cmp_a->range_start != $cmp_b->range_start'
);
ok($cmp_a->cmp_range_end($cmp_b)==-1
  ,'$cmp_a->range_start < $cmp_b->range_start'
);
ok($cmp_b->cmp_range_end($cmp_a)==1
  ,'$cmp_b->range_start > $cmp_a->range_start'
);

ok(!$cmp_a->contiguous_check($cmp_a),'contiguous_check 1');
ok($cmp_a->contiguous_check($cmp_b),'contiguous_check 2');
