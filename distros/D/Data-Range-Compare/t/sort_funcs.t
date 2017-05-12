#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
use strict;
use warnings;
use lib qw(../lib lib);
use Data::Range::Compare qw(:SORT HELPER_CB);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %helper=HELPER_CB;
my @raw=map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) }
(
 [0,1]
 ,[0,4]
 ,[2,3]
 ,[4,5]
);

my ($largest_end_first)=sort sort_largest_range_end_first @raw;
ok($largest_end_first->range_end==5,'sort_largest_range_end_first');

my ($largest_range_start_first)=sort sort_largest_range_start_first @raw;
ok($largest_range_start_first->range_start==4,'sort_largest_range_start_first');

my ($smallest_range_start_first)=sort sort_smallest_range_start_first @raw;
ok($smallest_range_start_first->range_start==0
	,'sort_smallest_range_start_first');

my ($smallest_range_end_first)=sort sort_smallest_range_end_first @raw;
ok($smallest_range_end_first->range_end==1,'smallest_range_end_first');

my @sorted=sort sort_in_consolidate_order @raw;
ok('0 - 4' eq $sorted[0],'sort_in_consolidate_order 0');
ok('0 - 1' eq $sorted[1],'sort_in_consolidate_order 1');
ok('2 - 3' eq $sorted[2],'sort_in_consolidate_order 2');
ok('4 - 5' eq $sorted[3],'sort_in_consolidate_order 3');

my @presentation=sort sort_in_presentation_order @raw;
my $check='0 - 1 0 - 4 2 - 3 4 - 5';
ok($check eq join(' ',@presentation),'sort_in_presentation_order');
### END OF THE UNIT TESTS
1;
__END__
