=begin
    
    File:	examples/ex_add2.pl
	Author: Rodin Porrata, <rodin@ursa.llnl.gov>
	Desc: 

		This script runs a test of the networks ability to add 
		and remember data sets, as well as testing the optimum "inc" to 
		learn and the optimum number of layers for a network.

=cut

	use AI::NeuralNet::Mesh;
	use Benchmark;
	use English;
	
	my $ofile = "addnet_data.txt";
	
	open( OUTFP, ">$ofile" ) or die "Could not open output file\n";
	
	my ( $layers, $inputs, $outputs, $top, $inc, $top, $runtime,
	$forgetfulness );
	my @answers;
	my @predictions;
	my @percent_diff;
	
	$inputs = 3;
	$outputs = 1;
	my ($maxinc,$maxtop,$incstep);
	select OUTFP; $OUTPUT_AUTOFLUSH = 1; select STDOUT;
	print OUTFP "layers inc top forgetfulness time \%diff1 \%diff2 \%diff3
	\%diff4\n\n";
	
	for( $layers = 1; $layers <= 3; $layers++ ){
	 if( $layers <= 2 ){
	  $incstep = 0.025;
	 }
	 else{
	  $incstep = 0.05;
	 }
	 for( $inc=0.025; $inc <= 0.4; $inc += $incstep ){
	  if( $inc > .3 ){
	   $maxtop = 3;
	  }
	  else{
	   $maxtop = 4;
	  }
	  for( $top=1; $top <=$maxtop; $top++ ){
	   addnet();
	   printf OUTFP "%d %.3f %d %g %s %f %f %f %f\n",
	   $layers, $inc, $top, $forgetfulness, timestr($runtime),
	$percent_diff[0],
	   $percent_diff[1], $percent_diff[2], $percent_diff[3];
	   print "layers inc top forgetfulness time \%diff1 \%diff2 \%diff3
	\%diff4\n";
	   printf "%d %.3f %d %g %s %f %f %f %f\n",
	   $layers, $inc, $top, $forgetfulness, timestr($runtime),
	$percent_diff[0],
	   $percent_diff[1], $percent_diff[2], $percent_diff[3];
	  }
	 }
	}
	
	#....................................................
	sub addnet
	{
	 print "\nCreate a new net with $layers layers, 3 inputs, and 1 output\n";
	 my $net = AI::NeuralNet::Mesh->new($layers,3,1);
	
	 # Disable debugging
	 $net->debug(0);
	
	
	 my @data = (
	  [   2633, 2665, 2685],  [ 2633 + 2665 + 2685 ],
	  [   2623, 2645, 2585],  [ 2623 + 2645 + 2585 ],
	  [  2627, 2633, 2579],  [ 2627 + 2633 + 2579 ],
	  [   2611, 2627, 2563],  [ 2611 + 2627 + 2563 ],
	  [  2640, 2637, 2592],  [ 2640 + 2637 + 2592 ]
	 );
	
	 print "Learning started, will cycle $top times with inc = $inc\n";
	
	  # Make it learn the whole dataset $top times
	  my @list;
	
	 my $t1=new Benchmark;
	 for my $a (1..$top)
	 {
	  print "Outer Loop: $a : ";
	
	  $forgetfulness = $net->learn_set( \@data,
	           inc  => $inc,
	           max  => 500,
	           error => -1);
	
	  print "Forgetfulness: $forgetfulness %\n";
	
	 }
	 my $t2=new Benchmark;
	
	 $runtime = timediff($t2,$t1);
	 print "run took ",timestr($runtime),"\n";
	
	
	 my @input = ( [ 2222, 3333, 3200 ],
	      [ 1111, 1222, 3211 ],
	      [ 2345, 2543, 3000 ],
	      [ 2654, 2234, 2534 ] );
	
	    test_net( $net, @input );
	}
	#.....................................................................
	 sub test_net {
	  my @set;
	  my $fb;
	  my $net = shift;
	  my @data = @_;
	  undef @percent_diff; #@answers; undef @predictions;
	
	  for( $i=0; defined( $data[$i] ); $i++ ){
	   @set = @{ $data[$i] };
	   $fb = $net->run(\@set)->[0];
	   # Print output
	   print "Test Factors: (",join(',',@set),")\n";
	   $answer = eval( join( '+',@set ));
	   push @percent_diff, 100.0 * abs( $answer - $fb )/ $answer;
	   print "Prediction : $fb      answer: $answer\n";
	  }
	 }
	
	
