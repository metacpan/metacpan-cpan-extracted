=begin

	File:   examples/ex_pat.pl
	Author: Tobias Bronx, <tobiasb@odin.funcom.com>
	Desc:
	
		This demonstrates simply pattern learning.

=cut

	use AI::NeuralNet::Mesh;
	$net=AI::NeuralNet::Mesh->new(2,2,2);
	print $net->learn([2,2],[2,2],max=>3),"\n"; 
	for (0..1) {
		for my $a (1..2) { 
			for my $b (1..2) { 
				@a=($a,$b); 
				print join(",",@a),":",join(",",@{$net->run(\@a)}), "\n"; 
				$net->learn(\@a,\@a, max=>100,inc=>0.17);
				print join(",",@{$net->run(@a)}),"\n";
			}
		}
	}
	print "1,2:",join(",",@{$net->run([1,2])}),"\n";
