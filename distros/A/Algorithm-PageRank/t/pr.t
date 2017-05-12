use Test::More qw(no_plan);
use ExtUtils::testlib;

use Algorithm::PageRank;
ok(1);

$pr = new Algorithm::PageRank;
$Algorithm::PageRank::d_factor = 0;

$pr->graph([
	    qw(
	       0 1
	       0 2
	       0 3
	       0 4
	       0 6
	       
	       1 0
	       
	       2 0
	       2 1
		   
	       3 1
	       3 2
	       3 4
		   
	       4 0
	       4 2
	       4 3
	       4 5
	       
	       5 0
	       5 4
	       
	       6 4
	       )
	    ]);


$pr->iterate(100);

@r = $pr->result()->list;
@a = (
      '0.303514376996805',
      '0.166134185303515',
      '0.140575079872205',
      '0.105431309904153',
      '0.178913738019169',
      '0.0447284345047924',
      '0.0607028753993611'
      );
foreach (0..$#r){
    ok(abs($r[$_] - $a[$_]) < 0.000001, "Strongly-connected graph" );
}

    

__END__
