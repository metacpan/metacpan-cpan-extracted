# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bit-Vector-Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 18;
BEGIN { use_ok('Bit::Vector::Array') };

#########################

# Insert your test code below, the Test::More module is 
# use()ed here so read its man page ( perldoc Test::More ) 
# for help writing this test script.


bva(my @arr1);
bva(my @arr2);
bva(my @arr3);

$#arr1=8;
my $val1 = $#arr1;
is($val1,8, "Store and Fetch using dollar-hash");


# here we use the arrays as normal numbers,
# we just have to always use $# sigil rather
# than the @ sigil.
$#arr1=7;
$#arr2=11;
$#arr3 = $#arr1 * $#arr2;
is($#arr3,77, "multiplication");


$#arr3=0;
$arr3[0]=1; is($#arr3,1, "set bit0");
$arr3[1]=1; is($#arr3,3, "set bit1");
$arr3[2]=1; is($#arr3,7, "set bit2");
$arr3[3]=1; is($#arr3,15, "set bit3");
$arr3[4]=1; is($#arr3,31, "set bit4");
$arr3[5]=1; is($#arr3,63, "set bit5");
$arr3[6]=1; is($#arr3,127, "set bit6");
$arr3[7]=1; is($#arr3,255, "set bit7");

$arr3[0]=0; is($#arr3,254, "clr bit0");
$arr3[1]=0; is($#arr3,252, "clr bit1");
$arr3[2]=0; is($#arr3,248, "clr bit2");
$arr3[3]=0; is($#arr3,240, "clr bit3");
$arr3[4]=0; is($#arr3,224, "clr bit4");
$arr3[5]=0; is($#arr3,192, "clr bit5");
$arr3[6]=0; is($#arr3,128, "clr bit6");
$arr3[7]=0; is($#arr3,0, "clr bit7");


