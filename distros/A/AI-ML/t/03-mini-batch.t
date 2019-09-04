#!perl

use Math::Lapack::Matrix;
use Math::Lapack::Expr;
use AI::ML::Expr;

my $m = Math::Lapack::Matrix->random(50,1000);
my $nr_tests = 0;
my $axis = 0;
my $size = 200;
my $start = 0;

for my $v (0..4){
    my $a = mini_batch($m, $start, $size, $axis);
    is($a->rows, 50, "Right number of rows\n");
    is($a->columns, 200, "Right number of columns\n");
    $start += $size;    
}

my $m_1 = Math::Lapack::Matrix->random(1000,20);
$start = 0;
$axis = 1;
for my $i (0..4){
    my $b = mini_batch($m_1, $start, $size, $axis);
    is($b->rows, 200, "Right number of rows\n");
    is($b->columns, 20, "Right number of columns\n");
    $start += $size;    
}
    
print "1..$nr_tests\n";

sub float {
  $nr_tests++;
  my ($a, $b, $explanation) = @_;
  if (abs($a-$b) > 0.000001){
    print "not ";
    $explanation .= " ($a vs $b)";
  }
  print "ok $nr_tests - $explanation\n";
}

sub is {
  $nr_tests++;
  my ($a, $b, $explanation) = @_;
  if ($a != $b){
    print "not ";
    $explanation .= " ($a vs $b)";
  }
  print "ok $nr_tests - $explanation\n";
}

