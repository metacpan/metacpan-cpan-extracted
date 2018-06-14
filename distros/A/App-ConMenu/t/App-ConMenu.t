# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Code4Pay-Menu.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 4;
BEGIN { use_ok('App::ConMenu') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $menu = new_ok ('App::ConMenu');
$menu->{'fileName'}= './t/test_resources/testMenu.yml';
my $menuItems = $menu->loadMenuFile();
ok ($menuItems->[0]->{'Test Menu Item 1'}->{'working_dir'} eq '../../t');
my $commandStructure;

#Run a windows command if we are on windows
if ($^O eq 'MSWin32'){
     $commandStructure = $menuItems->[0]->{'Test Menu Item 2'};
} else {
    $commandStructure = $menuItems->[0]->{'Test Menu Item 1'};
}
ok ($menu->execute($commandStructure));



