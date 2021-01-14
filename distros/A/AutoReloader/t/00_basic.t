# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sub-Auto.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('AutoReloader') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

! -d 't/auto' and mkdir 't/auto', 0755 or die "mkdir: $!\n";
! -d 't/auto/main' and mkdir 't/auto/main', 0755 or die "mkdir: $!\n";

open O, '>', 't/auto/main/getclass.al' or die "open: $!\n";

print O <<EOH;
sub {
    return __PACKAGE__;
};
EOH
close O or die "close: $!\n";
AutoReloader->auto('t/auto');
is(AutoReloader->auto(),'t/auto');
my $sub = AutoReloader->new('getclass');
is(ref($sub), 'AutoReloader');
my $ret = $sub->();
is($ret,'main');

sleep 1;
# let's change that sub during runtime
open O, '>', 't/auto/main/getclass.al' or die "open: $!\n";
print O <<EOH;
package Foo;
sub {
    return __PACKAGE__;
};
EOH
close O or die "close: $!\n";
$ret = $sub->();
is($ret,'main');
# set the check flag for the sub
$sub->check(1);
$ret = $sub->();
is($ret,'Foo');

# change checked value to size
my $check = sub { -s $_[0] };
$sub->checksub($check);
is($sub->(),'Foo'); # triggers reload
open O, '>', 't/auto/main/getclass.al' or die "open: $!\n";
print O <<EOH;
package Bar;
sub {
    return __PACKAGE__;
};
EOH
close O or die "close: $!\n";
$ret = $sub->(); 
is($ret,'Foo','size not changed');
open O, '>>', 't/auto/main/getclass.al'; print O "\n"; close O;
is($sub->(),'Bar','size of file changed');

unlink 't/auto/main/getclass.al' or die "unlink t/auto/main/getclass.al: $!\n";
rmdir 't/auto/main' or die "rmdir t/auto/main: $!\n";
rmdir 't/auto' or die "rmdir t/auto: $!\n";

