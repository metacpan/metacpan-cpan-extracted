#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests =>2;
use strict;
use warnings;
use lib qw(../lib lib);
use Data::Range::Compare qw(HELPER_CB );
use Data::Dumper;

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

my $overlap=Data::Range::Compare->get_overlapping_range(\%helper,\@raw);
ok('0 - 5' eq $overlap,'get_overlapping_range');

@raw=map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) }
(
 [2,7]
 ,[4,5]
 ,[3,6]
);
my $common=Data::Range::Compare->get_common_range(\%helper,\@raw);
ok($common eq '4 - 5','get_common_range');

### END OF THE UNIT TESTS
1;
__END__
