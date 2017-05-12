#!perl -w

my $loaded;

use strict;

use constant num_one => 1;
use constant num_two => 2;
use constant txt_one => 'one';
use constant txt_two => 'two';

use Data::Compare;

$| = 1;
eval 'use Scalar::Properties';
print (($@) ? "1..0 # Skipping no Scalar::Properties found\n" : "1..17\n");
exit(0) if($@);

my $test = 0;
print "ok ".(++$test)." load module\n";

eval q{

use Scalar::Properties;

# test SP vs SP

my($sp1, $sp2) = (1, 1);
print 'not ' unless(Compare($sp1, $sp2));
print 'ok '.(++$test)." SPs with same value, no properties compare the same\n";
 
($sp1, $sp2) = (1, 2);
print 'not ' if(Compare($sp1, $sp2));
print 'ok '.(++$test)." SPs with different values, no properties compare different\n";
 
($sp1, $sp2) = (1->a('frob')->b(num_one), 1->a('frob')->b(num_one));
print 'not ' unless(Compare($sp1, $sp2));
print 'ok '.(++$test)." SPs with same value, same properties compare the same\n";
 
($sp1, $sp2) = (1->a('foo')->b(num_one), 1->a('frob')->b(num_one));
print 'not ' if(Compare($sp1, $sp2));
print 'ok '.(++$test)." SPs same value, different properties compare different\n";

($sp1, $sp2) = (1->a('frob')->b(num_one), 2->a('frob')->b(num_one));
print 'not ' if(Compare($sp1, $sp2));
print 'ok '.(++$test)." SPs different value, same properties compare different\n";
 
($sp1, $sp2) = (1->a('foo')->b(num_one), 2->a('frob')->b(num_one));
print 'not ' if(Compare($sp1, $sp2));
print 'ok '.(++$test)." SPs different value, different properties compare different\n";
 
($sp1, $sp2) = (1, 1->a('frob')->b(num_one));
print 'not ' if(Compare($sp1, $sp2));
print 'ok '.(++$test)." SPs with same value, one with extra properties compare different\n";
 
($sp1, $sp2) = (1->a('frob')->b(num_one), 1);
print 'not ' if(Compare($sp1, $sp2));
print 'ok '.(++$test)." (rev) SPs with same value, one with extra properties compare different\n";
 
# test scalar vs SP

$sp1 = 1;
my $scalar1 = num_one;
print 'not ' unless(Compare($scalar1, $sp1));
print 'ok '.(++$test)." scalar and S::P with same numeric value compare the same\n";

$sp1 = 2;
print 'not ' if(Compare($scalar1, $sp1));
print 'ok '.(++$test)." scalar and S::P with different numeric value compare different\n";

$sp1 = 'one';
$scalar1 = txt_one;
print 'not ' unless(Compare($scalar1, $sp1));
print 'ok '.(++$test)." scalar and S::P with same string value compare the same\n";

$sp1 = 'two';
print 'not ' if(Compare($scalar1, $sp1));
print 'ok '.(++$test)." scalar and S::P with different string value compare different\n";

# test SP vs scalar

$sp1 = 1;
$scalar1 = num_one;
print 'not ' unless(Compare($sp1, $scalar1));
print 'ok '.(++$test)." (rev) scalar and S::P with same numeric value compare the same\n";

$sp1 = 2;
print 'not ' if(Compare($sp1, $scalar1));
print 'ok '.(++$test)." (rev) scalar and S::P with different numeric value compare different\n";

$sp1 = 'one';
$scalar1 = txt_one;
print 'not ' unless(Compare($sp1, $scalar1));
print 'ok '.(++$test)." (rev) scalar and S::P with same string value compare the same\n";

$sp1 = 'two';
print 'not ' if(Compare($sp1, $scalar1));
print 'ok '.(++$test)." (rev) scalar and S::P with different string value compare different\n";

}
