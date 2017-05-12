# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Date::Jalali') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use_ok('Date::Jalali');
my $t1 = new Date::Jalali (1977,12,9); #birthday
ok  ( defined($t1) , "Defined?");
is  ($t1->jal_day, 18 , "Haha! Day Error!");
is  ($t1->jal_month, 9 , "Haha! Month Error!");
is  ($t1->jal_year, 1356 , "Haha! Year Error!");

my $t2 = new Date::Jalali (2003,6,12); #today
is  ($t2->jal_day, 22 , "Haha! Day Error!");
is  ($t2->jal_month, 3 , "Haha! Month Error!");
is  ($t2->jal_year, 1382 , "Haha! Year Error!");
