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

ok(!$cmp->contains_value(-1),'should not contain -1');
ok(!$cmp->contains_value(2),'should not contain 2');
ok($cmp->contains_value(1),'should contain 1');
ok($cmp->contains_value(0),'should contain 0');

### END OF THE UNIT TESTS
1;
__END__
