#########################

# change 'tests => 1' to 'tests => last_test_to_print';
package subclasstest;
use strict;
use warnings;
use Test::More tests => 3;
use lib qw(../lib lib);
use Data::Range::Compare qw(:HELPER :HELPER_CB);
use Data::Dumper;

our @ISA=qw(Data::Range::Compare );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my %HELPER_CB=HELPER_CB;

my $obj='subclasstest'->new({%HELPER_CB},qw(0 1));
ok($obj,'subclassing our instance should work');
$obj='subclasstest'->SUPER::new(\%HELPER_CB,qw(0 1));
ok($obj,'subclassing our instance should work');
$HELPER_CB{add_one}=sub { $_[0] + 2 };
$HELPER_CB{sub_one}=sub { $_[0] - 3 };
$HELPER_CB{cmp_values}=sub { $_[0] cmp $_[1] };
ok($obj->next_range_start==3,'oo super check');
1;
