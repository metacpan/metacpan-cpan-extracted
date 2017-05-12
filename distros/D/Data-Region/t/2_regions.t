use Test::More tests => 2;
BEGIN{ use_ok('Data::Region'); }

use strict;

my $Data = {chix => 'poop', count => 0};

my $output = "TEST\n";

my $r = Data::Region->new(8.5,11, {data => $Data});
foreach my $c ( $r->subdivide(2.5,3) ) {
  my $a = $c->area(0.25,0.25, -0.25,-0.25);
  my($x1,$y1,$x2,$y2) = $a->coords();
  $a->action( sub {
		my $data = $_[0]->data();
		$data->{count}++;
		my $s = $data->{chix};
		$output .= "$data->{count}: box={($x1,$y1) - ($x2,$y2)} $s\n";
	      } );
}
$r->render(); # heirarchically perform all the actions

$output .= "conclusion: count=$Data->{count}\n";

#print $output;
open(IN, "t/2_regions.out") || die "can't find expected output file";
local $/=undef;
my $expected = <IN>;

ok($expected eq $output, "basic tests");


