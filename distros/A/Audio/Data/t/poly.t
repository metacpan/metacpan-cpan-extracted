use Test::More (tests => 21);
use Math::Complex;
BEGIN { use_ok('Audio::Data','solve_polynomial') }

my @a = (15,-8,1);

my @roots = solve_polynomial(@a);
print "#@roots\n";
is(4,scalar(@roots),"Solved");
is($roots[1],0,"1st root is real");
is($roots[3],0,"2nd root is real");
@roots = sort(@roots);
is($roots[-2],3,"Smaller root is 3");
is($roots[-1],5,"Largest root is 5");

@roots = solve_polynomial(-1,0,0,0,0,1);
print "#@roots\n";
is(scalar(@roots),10,"Solved");


while (@roots)
 {
  my $n = Math::Complex->new(splice(@roots,0,2));
  ok(abs($n**5-1) < 1.0e-6,"Fifth root");
 }

my @poly = (1,-3.17771244049072,3.9795618057251,-1.72559440135956,-0.857469737529755,0.766406536102295,0.816600441932678,-1.16691339015961,0.416294276714325);

@roots = solve_polynomial(@poly);
print "#@roots\n";
is(scalar(@roots),16,"Solved");

while (@roots)
 {
  my $n = Math::Complex->new(splice(@roots,0,2));
  my $v = poly_complex_eval($n,@poly);
  print "# $n => $v\n";
  ok(abs($v) < 1.0e-6,"Is a solution");
 }


sub poly_complex_eval
{
 my ($n,@a) = @_;
 my $v = 0;
 while (@a)
  {
   $v = $v*$n + pop(@a);
  }
 return $v;
}

	     
	     
	     
	     
