=begin

	File:   examples/ex_wine.pl
	Author: Josiah Bryan, <jdb@wcoil.com>
    Desc:
		
		This demonstrates wine cultivar prediction using the
		AI::NeuralNet::Mesh module.
		
        This script uses the data that is the results of a chemical analysis 
        of wines grown in the same region in Italy but derived from three
	    different cultivars. The analysis determined the quantities 
	    of 13 constituents found in each of the three types of wines. 

		The inputs of the net represent 13 seperate attributes
		of the wine's chemical analysis, as follows:
		
		 	1)  Alcohol
		 	2)  Malic acid
		 	3)  Ash
			4)  Alcalinity of ash  
		 	5)  Magnesium
			6)  Total phenols
		 	7)  Flavanoids
		 	8)  Nonflavanoid phenols
		 	9)  Proanthocyanins
			10) Color intensity
		 	11) Hue
		 	12) OD280/OD315 of diluted wines
		 	13) Proline            
		
		There are 168 total examples, with the class distrubution
		as follows:
		
			class 1: 59 instances
			class 2: 71 instances
			class 3: 48 instances
			
		The datasets are stored in wine.dat, and the first
		column on every row is the class attribute for that
		row.

=cut

    use AI::NeuralNet::Mesh;
	use Benchmark;

	# Create a new net
    my $net = AI::NeuralNet::Mesh->new([13,45,1]);

	# Set activation on output node to contstrain values
	# to a specific range of values.    
    $net->activation(2,range(1..3));
	
	# Enable debugging
	$net->verbose(4);

	# Load the data set
	my $data = $net->load_set('wine.dat',0);
	
	# Seperate data based on class
	my $sets=[];
	for my $i (0..$#{$data}/2) {
		my $c = $data->[$i*2+1]->[0];
		print "Class of set $i: $c                                  \r";
		# inputs
		$sets->[$c]->[++$#{$sets->[$c]}] = $data->[$i*2];
		# class
		$sets->[$c]->[++$#{$sets->[$c]}] = $data->[$i*2+1];
	}                                  
	
			
	for(0..$#{$sets}) {
		next if(!defined $sets->[$_]->[0]);
		print "Size of set $_: ",$#{$sets->[$_]}/2,"\n";
	}
	
	# If we havnt saved the net already, do the learning
    if(!$net->load('wine.mesh')) {
		print "\nLearning started...\n";
		
		# Make it learn the whole dataset $top times
		my @list;
		my $top=5;
		for my $a (0..$top) {
			print "\n\nOuter Loop: $a\n";
			
			for(0..$#{$sets}) {
				next if(!defined $sets->[$_]->[0]);
				my $t1=new Benchmark;
				
				# Test fogetfullness
				my $f = $net->learn_set($sets->[$_],	inc		=>	0.2,	
														max		=>	2000,
														error	=>	0.01,
														leave	=>	2);
				
				# Print it 
				print "\n\nForgetfullness: $f%\n";
	
				my $t2=new Benchmark;
				my $td=timediff($t2,$t1);
				print "\nLoop [$a,$_] took ",timestr($td),"\n";
			}
			
			# Save net to disk				
            $net->save('wine.mesh');
		}
	}

	# Set activation on output node to contstrain values
	# to a specific range of values.    
    $net->activation(2,range(1..3));
	
	my @cnts;
	for(0..$#{$sets}) {
		next if(!defined $sets->[$_]->[0]);
		my $s=$#{$sets->[$_]}/2;
		my $cnt=0;
		print "Set: $_\n";
		my $results=$net->run_set($sets->[$_]);
		for my $x (0..$s-1) {
			$cnt++ if($results->[$x]->[0]==$_);
		}
		$cnts[$_]=$cnt;
	}
	
	for(0..$#{$sets}) {
		next if(!defined $sets->[$_]->[0]);
		my $s=$#{$sets->[$_]}/2;
		print "Class $_: $cnts[$_] correct out of $s (",$net->p($cnts[$_],$s),"%).\n";
	}
		