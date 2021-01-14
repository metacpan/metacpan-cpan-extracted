# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sub-Auto.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('AutoReloader',qw(AUTOLOAD)) };

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
is(AutoReloader->auto(),'t/auto',"AutoReloader package path prefix is 't/auto'");
my $ret = getclass();
is($ret,'main','loaded function compiled into caller\'s class (main)');

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
$ret = getclass();
is($ret,'main','modified function not reloaded, global check = 0');
# set the global check flag
AutoReloader->check(1);

$ret = getclass();
is($ret,'Foo','modified function reloaded after check = 1');
my $check = *getclass{CODE}->checksub;
sleep 2;
# unset the per-sub check flag
*getclass{CODE}->check(0);
open O, '>', 't/auto/main/getclass.al' or die "open: $!\n";
print O <<EOH;
package Bar;
sub {
   return __PACKAGE__;
};
EOH
close O or die "close: $!\n";
$ret = getclass();
is($ret,'Foo', 'sub\'s check flag = 0 - not reloaded after change');
*getclass{CODE}->check(1);
is(getclass(),'Bar', 'sub\'s check flag = 1 - reloaded after change');
unlink 't/auto/main/getclass.al' or die "unlink t/auto/main/getclass.al: $!\n";
rmdir 't/auto/main' or die "rmdir t/auto/main: $!\n";
rmdir 't/auto' or die "rmdir t/auto: $!\n";

