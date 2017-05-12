# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
use strict;
use CIsam;
use eg::Person;
my $loaded = 1;
print "ok 1\n";

######################### End of black magic.



my $ps = new Person(IsamObjects::BUILD);

my $di; 
$di = $ps->{ISAM_OBJ}->isindexinfo(0);
print "di_nkeys    = " . $di->di_nkeys . "\n";
print "di_recsize  = " . $di->di_recsize . "\n";
print "di_idxsize  = " . $di->di_idxsize . "\n";
print "di_nrecords = " . $di->di_nrecords . "\n";


$ps->clear();
$ps->path("foo");

$ps->{last_name} = "chane";
$ps->{first_name} = "phil";
$ps->{phone} = 81857887;
$ps->{age} = 10;
$ps->{net_worth} = 5.78;
$ps->{account_balance} = -4090.45;

$ps->add();

printf ("Wrote to db:\n");
printf ("last_name = chane\n");
printf ("first_name = phil\n");
printf ("phone = 81857887\n");
printf ("age = 10\n");
printf ("net_worth = 5.78\n");
printf ("account_balance = -4090.45\n");

$ps->{last_name} = "chane you kaye";
$ps->{first_name} = "maria";
$ps->{phone} = 10928831;
$ps->{age} = 15;
$ps->{net_worth} = 17328105.00;
$ps->{account_balance} = 0.00;

$ps->add();

printf ("Wrote to db:\n");
printf ("last_name = chane you kaye\n");
printf ("first_name = maria\n");
printf ("phone = 10928831\n");
printf ("age = 15\n");
printf ("net_worth = 17328105.00\n");
printf ("account_balance = 0.00\n");


print "listing using index foo\n";
print "Make sure that the values written to db and values read from db match!\n";

$ps->path("foo");
$ps->get(&ISFIRST);
   printf("Last Name: %s\n", $ps->{last_name});
   printf("First Name: %s\n", $ps->{first_name});
   printf("Age: %d\n", $ps->{age});
   printf("Phone: %d\n", $ps->{phone});
   printf("Net Worth: %f\n", $ps->{net_worth});
   printf("Account Balance: %f\n\n\n", $ps->{account_balance});

while ($ps->get(&ISNEXT))
{
   printf("Last Name: %s\n", $ps->{last_name});
   printf("First Name: %s\n", $ps->{first_name});
   printf("Age: %d\n", $ps->{age});
   printf("Phone: %d\n", $ps->{phone});
   printf("Net Worth: %f\n", $ps->{net_worth});
   printf("Account Balance: %f\n\n\n", $ps->{account_balance});
}

print "listing using index bar\n";
print "Make sure that the values written to db and values read from db match!\n";

$ps->path("bar");

$ps->get(&ISFIRST);
   printf("Last Name: %s\n", $ps->{last_name});
   printf("First Name: %s\n", $ps->{first_name});
   printf("Age: %d\n", $ps->{age});
   printf("Phone: %d\n", $ps->{phone});
   printf("Net Worth: %f\n", $ps->{net_worth});
   printf("Account Balance: %f\n\n\n", $ps->{account_balance});

while ($ps->get(&ISNEXT))
{
   printf("Last Name: %s\n", $ps->{last_name});
   printf("First Name: %s\n", $ps->{first_name});
   printf("Age: %d\n", $ps->{age});
   printf("Phone: %d\n", $ps->{phone});
   printf("Net Worth: %f\n", $ps->{net_worth});
   printf("Account Balance: %f\n\n\n", $ps->{account_balance});
}

$ps->clear();
$ps->{last_name} = "chane you kaye";
$ps->{first_name} = "maria";

$ps->get(&ISEQUAL) or die "error" . "$ps->{ISAM_OBJ}->iserrno" . " isread ";

$ps->{phone} = 92212107;
$ps->{age} = 30;
$ps->{net_worth} = 890380.09;
$ps->{account_balance} = -90.67;

$ps->update();

printf ("Updated the db:\n");
printf ("last_name = chane you kaye\n");
printf ("first_name = maria\n");
printf ("phone = 92212107\n");
printf ("age = 30\n");
printf ("net_worth = 890380.09\n");
printf ("account_balance = -90.67\n");

print "listing using index bar\n";
print "Make sure that the values written to db and values read from db match!\n";
$ps->path("bar");

$ps->get(&ISFIRST);
   printf("Last Name: %s\n", $ps->{last_name});
   printf("First Name: %s\n", $ps->{first_name});
   printf("Age: %d\n", $ps->{age});
   printf("Phone: %d\n", $ps->{phone});
   printf("Net Worth: %f\n", $ps->{net_worth});
   printf("Account Balance: %f\n\n\n", $ps->{account_balance});

while ($ps->get(&ISNEXT))
{
   printf("Last Name: %s\n", $ps->{last_name});
   printf("First Name: %s\n", $ps->{first_name});
   printf("Age: %d\n", $ps->{age});
   printf("Phone: %d\n", $ps->{phone});
   printf("Net Worth: %f\n", $ps->{net_worth});
   printf("Account Balance: %f\n\n\n", $ps->{account_balance});
}

printf("Deleting test db ...\n");
$ps->{ISAM_OBJ}->iserase("person");

END {print "not ok 1\n" unless $loaded;}
