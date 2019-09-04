#!perl

use Math::Lapack::Matrix;
use Math::Lapack::Expr;
use AI::ML::Expr;

my $m_1 = Math::Lapack::Matrix->new([ [-2, 1, 2, 3] ]);
my $nr_tests = 0;

#Test d_relu
my $a = d_relu($m_1);

float($a->get_element(0,0), 0, "Element correct at 0,0");
float($a->get_element(0,1), 1, "Element correct at 0,1");
float($a->get_element(0,2), 1, "Element correct at 0,2");
float($a->get_element(0,3), 1, "Element correct at 0,3");

my $b = $a x $m_1->transpose;

float($b->get_element(0,0), 6, "Element correct at 0,0");

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

