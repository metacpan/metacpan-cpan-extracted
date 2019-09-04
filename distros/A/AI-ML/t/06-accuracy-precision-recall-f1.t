#!perl

use Math::Lapack::Matrix;
use AI::ML::Expr;

my $nr_tests=0;
my $y = Math::Lapack::Matrix->new([
				[1],[0],[1],[1],[0],[0],[1],[1],[1],[1],[0],[0],[1],[0],[0]
		]);
my $yatt = Math::Lapack::Matrix->new([
				[1],[0],[0],[0],[1],[1],[0],[1],[1],[1],[1],[0],[0],[0],[0]
		]);

# True Positive = 4
# False Positive = 3
# False Negative = 4

my $acc = AI::ML::Expr::accuracy($y, $yatt);
float($acc, 0.5333333, "Right accuracy");

my $prec = AI::ML::Expr::precision($y, $yatt);
float($prec, 0.571428571, "Right Precision");

my $rec = AI::ML::Expr::recall($y, $yatt);
float($rec, 0.5, "Right recall");

my $f_1 = AI::ML::Expr::f1($y, $yatt);
float($f_1, 0.533333334, "Right f1");

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

