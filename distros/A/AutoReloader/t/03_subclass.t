# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AnonLoader.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package SubClass;
use Test::More qw(no_plan);
BEGIN { use_ok('AutoReloader', qw(AUTOLOAD)) };
@SubClass::ISA = qw(AutoReloader);
#########################
SubClass -> auto ('./t/auto');
package main;
undef *AUTOLOAD; # silence 'used only once'
*AUTOLOAD = *SubClass::AUTOLOAD;
! -d 't/auto' and mkdir 't/auto', 0755;
! -d 't/auto/main' and mkdir 't/auto/main', 0755;
open O, '>', 't/auto/main/get_package.al' or die "open: $!";
print O <<EOH;
package Foo; sub { __PACKAGE__ };
EOH
close O;
my $sub = SubClass -> new ('get_package');
my $package = $sub -> ();
SubClass::is ($package,'Foo');
get_package();
unlink 't/auto/main/get_package.al';
rmdir 't/auto/main';
rmdir 't/auto';
