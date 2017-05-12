#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests =>4;
use strict;
use warnings;
use lib qw(../lib lib);
use Data::Range::Compare qw(HELPER_CB );
use Data::Dumper;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %helper=HELPER_CB;
my $cmp=Data::Range::Compare->new(\%helper,0,1);

my $list=[ 
   Data::Range::Compare->new(\%helper,0,0)
   ,Data::Range::Compare->new(\%helper,2,3)
];
ok($cmp->grep_overlap($list)->[0] eq '0 - 0','test of grep_overlap');
ok($#{$cmp->grep_overlap($list)}==0,'should just have 1 range in this list');
ok($cmp->grep_nonoverlap($list)->[0] eq '2 - 3','test of grep_nonoverlap');
ok($#{$cmp->grep_nonoverlap($list)}==0,'should just have 1 range in this list');

### END OF THE UNIT TESTS
1;
__END__
