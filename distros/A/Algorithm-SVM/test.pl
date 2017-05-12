# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };

use Algorithm::SVM::DataSet;
use Algorithm::SVM;

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

print("Creating new Algorithm::SVM\n");
my $svm = new Algorithm::SVM(Model => 'sample.model');
ok(ref($svm) ne "", 1);

print("Creating new Algorithm::SVM::DataSet objects\n");
my $ds1 = new Algorithm::SVM::DataSet(Label => 1);
my $ds2 = new Algorithm::SVM::DataSet(Label => 2);
my $ds3 = new Algorithm::SVM::DataSet(Label => 3);
ok(ref($ds1) ne "", 1);
ok(ref($ds2) ne "", 1);
ok(ref($ds3) ne "", 1);

print("Adding attributes to Algorithm::SVM::DataSet objects\n");
my @d1 = (0.0424107142857143, 0.0915178571428571, 0.0401785714285714,
	  0.0156250000000000, 0.0156250000000000, 0.0223214285714286,
	  0.0223214285714286, 0.0825892857142857, 0.1205357142857140,
	  0.0736607142857143, 0.0535714285714286, 0.0535714285714286,
	  0.0178571428571429, 0.0357142857142857, 0.1116071428571430,
	  0.0334821428571429, 0.0223214285714286, 0.0602678571428571,
	  0.0200892857142857, 0.0647321428571429);

my @d2 = (0.0673076923076923, 0.11538461538461500, 0.0480769230769231,
	  0.0480769230769231, 0.00961538461538462, 0.0192307692307692,
	  0.0000000000000000, 0.08653846153846150, 0.1634615384615380,
	  0.0865384615384615, 0.03846153846153850, 0.0288461538461538,
	  0.0192307692307692, 0.01923076923076920, 0.0000000000000000,
	  0.0961538461538462, 0.02884615384615380, 0.0673076923076923,
	  0.0288461538461538, 0.02884615384615380);

my @d3 = (0.0756756756756757, 0.0594594594594595, 0.0378378378378378,
	  0.0216216216216216, 0.0432432432432432, 0.0000000000000000,
	  0.0162162162162162, 0.0648648648648649, 0.1729729729729730,
	  0.0432432432432432, 0.0864864864864865, 0.1297297297297300,
	  0.0108108108108108, 0.0108108108108108, 0.0162162162162162,
	  0.0486486486486487, 0.0324324324324324, 0.0216216216216216,
	  0.0594594594594595, 0.0486486486486487);

$ds1->attribute($_, $d1[$_ - 1]) for(1..scalar(@d1));
$ds2->attribute($_, $d2[$_ - 1]) for(1..scalar(@d2));
$ds3->attribute($_, $d3[$_ - 1]) for(1..scalar(@d3));
ok(1);

print("Checking predictions on loaded model\n");
ok($svm->predict($ds1) == 10,1);
ok($svm->predict($ds2) == 0,1);
ok($svm->predict($ds3) == -10,1);

print("Saving model\n");
ok($svm->save('sample.model.1'), 1);

print("Loading saved model\n");
ok($svm->load('sample.model.1'), 1);

print("Checking NRClass\n");
ok($svm->getNRClass(), 3);

print("Checking model labels\n");
ok($svm->getLabels(), (10, 0, -10));

my $cnt=0;
for (my $i=1; $i<=@d1; $i++) {
  if ($ds1->attribute($i) == $d1[$i-1]) {
		$cnt++;
	}
}
ok($cnt,20);

print("Checking train\n");
my @tset=($ds1,$ds2,$ds3);
ok($svm->train(@tset));

$cnt=0;
for (my $i=1; $i<=@d1; $i++) {
  if ($ds1->attribute($i) == $d1[$i-1]) {
		$cnt++;
	}
}
ok($cnt,20);


print("Checking retrain\n");

my $p1 = $svm->predict($ds1);
my $p2 = $svm->predict($ds2);
my $p3 = $svm->predict($ds3);

ok($svm->retrain());

ok($svm->predict($ds1),$p1);
ok($svm->predict($ds2),$p2);
ok($svm->predict($ds3),$p3);

print("Checking retrain after DataSet changes\n");
# this tests whether reallocating memory after realign
# works ok.
$ds1->attribute(2,$ds1->attribute(2));
$ds2->attribute(2,$ds2->attribute(2));
$ds3->attribute(2,$ds3->attribute(2));

ok($svm->retrain());

ok($svm->predict($ds1),$p1);
ok($svm->predict($ds2),$p2);
ok($svm->predict($ds3),$p3);

print("Checking svm destructor\n");

$svm=undef; # destroy svm object (test destructor)
ok(1);

print("Checking attribute value changes\n");
$ds1->attribute($_, 1) for(1..scalar(@d1));
$cnt=0;
for ($i=1;$i<=scalar(@d1);$i++) {
  if ($ds1->attribute($i)==1) { $cnt++; } else { print $ds1->attribute($i),"::\n"; }
}
ok($cnt,20);

$ds2->attribute(3, -1.5);
$ds2->attribute(5, -1.5);
$ds2->attribute(4, -1.5);
$ds2->attribute(2, -1.5);
$ds2->attribute(1, -1.5);
$cnt=0;
for ($i=1;$i<=5;$i++) {
  if ($ds2->attribute($i)==-1.5) { $cnt++; }
}
for ($i=6;$i<=scalar(@d2);$i++) {
  if ($ds2->attribute($i)==$d2[$i-1]) { $cnt++; }
}
ok($cnt,20);

$ds3->attribute($_, 0) for(1..scalar(@d3));
$cnt=0;
for ($i=1;$i<=scalar(@d3);$i++) {
  if ($ds3->attribute($i)==0) { $cnt++; }
}
ok($cnt,20);

print("Checking asArray\n");

my @x = $ds2->asArray();
# note that this takes attr. 0 as first value, which has never
# been set and thus is equal to zero
$cnt=0;
if ($x[0]==0.0) { $cnt++; }
for ($i=1;$i<=5;$i++) {
  if ($x[$i]==-1.5) { $cnt++; }
}
for ($i=6;$i<=scalar(@d2);$i++) {
  if ($x[$i]==$d2[$i-1]) { $cnt++; }
}
ok($cnt,21);
