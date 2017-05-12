=begin

	File:	examples/ex_aln.pl
	Author:	Josiah Bryan, jdb@wcoil.com
	Desc:
	
	This is a simple example of a _basic_ ALN implementation in
	under 210 lines of code. In this demo we make use of the 
	custom node connector as described in the POD. We also 
	insert our own method over the node's internal adjust_weight()
	method to make ALN learning a bit easire. This demo also adds
	a temporary method to the network to print the logical type of 
	each node, called print_aln();

	print_aln() prints simple diagram of the
	network similar to this (this is for a $net=Tree(8,1) with 
	$net->learn([1,1,0,1,0,1,1,1],[0]), and each line represents 
	a layer):
	
	L R L L L L L L
	OR OR OR OR
	OR OR
	AND
	
	All the standard methods that work on AI::NeuralNet::Mesh work
	on the object returned by Tree(). load() and save() will correctly
	preserve the gate structure and types of your network. learn_set()
	and everything else works pretty much as expected. Only thing
	that is useless is the crunch() method, as this only takes binary
	inputs. But...for those of you who couldnt live without integers
	in your network...I'm going to create a small package in the next 
	week, AI::NeuralNet::ALNTree, from this code. It will which includes 
	a integer-vectorizer (convert your integers into bit vectors), a bit 
	vector class to play with, as well as support for concating and 
	learning bit vectors. But, for now, enjoy this!
	
	This file contains just a simple, functional, ALN implementation. 
				
								Enjoy!
          
=cut
          	
	# Import all the little functions.
	use AI::NeuralNet::Mesh ':all';
	
	# Create a new ALN tree with 2 leaves and 1 root node.
	# Note: Our ALN trees can have more than one root node! Yippe! :-)
	# Just a little benefit of deriving our ALNs from 
	# AI::NeuralNet::Mesh.
	#
	my $net = Tree(8,1);
	
	# Use our nifty dot verbosity.
	$net->v(12);
	
	# Learn a pattern and print stats.
	if(!$net->load('aln.mesh')) {
		print "Learning";
		print "Done!\nLearning took ",$net->learn([1,1,0,1,0,1,1,1],[0]),"\n";
		$net->save('aln.mesh');
	}
		
	# Print logic gate types
	$net->print_aln();
	
	# Test it out
	print "\nPattern: [1,1,0,1,0,1,1,1]".
		  "\nResult: ",$net->run([1,1,1,1,1,1,1,1])->[0],"\n";




######################################################################
#-################ ALN Implementation Code  ########################-#
######################################################################
	
	# Build a basic ALN tree network (_very_ basic, only implements
	# the node types, and only two learning benefits from ALN theory are
	# realized.) Also adds a method to the neural network gates, print_aln().
	sub Tree {
		# Grab our leaves and roots
		my $leaves = shift;
		my $roots  = shift || $leaves;
	    
	    # Replace the load function with a new one to preserve the
	    # load activations. We have to add this up here because next
	    # thing we do is check if they passed a file name as $leaves,
	    # and we need to have our new load sub already in place before
	    # we try to load anything in $leaves.
	    *{'AI::NeuralNet::Mesh::load'} = sub {
	        my $self		=	shift;
			my $file		=	shift;  
			my $load_flag   =	shift;
			
		    if(!(-f $file)) {
		    	$self->{error} = "File \"$file\" does not exist.";
		    	return undef;
		    }
		    
		    open(FILE,"$file");
		    my @lines=<FILE>;
		    close(FILE);
		    
		    my %db;
		    for my $line (@lines) {
		    	chomp($line);
		    	my ($a,$b) = split /=/, $line;
		    	$db{$a}=$b;
		    }
		    
		    if(!$db{"header"}) {
		    	$self->{error} = "Invalid format.";
		    	return undef;
		    }
		    
		    return $self->load_old($file) if($self->version($db{"header"})<0.21);
		    
		    if($load_flag) {
			    undef $self;
		        $self = Tree($db{inputs},$db{outputs});
			} else {
				$self->{inputs}			= $db{inputs};
			    $self->{nodes}			= $db{nodes};
				$self->{outputs}		= $db{outputs};
				$self->{layers} 		= [split(',',$db{layers})];
				$self->{total_layers}	= $db{total_layers};
				$self->{total_nodes}	= $db{total_nodes};
			}
			
		    # Load variables
		    $self->{random}		= $db{"rand"};
		    $self->{const}		= $db{"const"};
	        $self->{col_width}	= $db{"cw"};
		    $self->{rA}			= $db{"rA"};
			$self->{rB}			= $db{"rB"};
			$self->{rS}			= $db{"rS"};
			$self->{rRef}		= [split /\,/, $db{"rRef"}];
			
		   	$self->{_crunched}->{_length}	=	$db{"crunch"};
			
			for my $a (0..$self->{_crunched}->{_length}-1) {
				$self->{_crunched}->{list}->[$a] = $db{"c$a"}; 
			}
			
			$self->_init();
		    
			my $n = 0;
			for my $x (0..$self->{total_layers}) {
				for my $y (0..$self->{layers}->[$x]-1) {
				    my @l = split /\,/, $db{"n$n"};
					for my $z (0..$self->{layers}->[$x-1]-1) {
						$self->{mesh}->[$n]->{_inputs}->[$z]->{weight} = $l[$z];
					}
					my $z = $self->{layers}->[$x-1];
					$self->{mesh}->[$n]->{activation} = $l[$z];
					$self->{mesh}->[$n]->{threshold}  = $l[$z+1];
					$self->{mesh}->[$n]->{mean}       = $l[$z+2];
					$n++;
				}
			}
			
	    	$self->extend($self->{_original_specs});
	
			return $self;
	    };
	    
		# If $leavesis a string, then it will be numerically equal to 0, so 
		# try to load it as a network file.
		if($leaves == 0) {  
		    # We use a "1" flag as the second argument to indicate that we 
		    # want load() to call the new constructor to make a network the
		    # same size as in the file and return a refrence to the network,
		    # instead of just creating the network from pre-exisiting refrence
			my $self = AI::NeuralNet::Mesh->new(1,1);
			return $self->load($leaves,1);
		}
		
		# Initalize our counter and our specs ref
		my $specs  = [];
		my $level  = 0;
		
		# Create our custom node activation
		my $act    = sub {
			shift; my $self = shift;
			my $b1 = intr($self->{_inputs}->[0]->{weight});
			my $b2 = intr($self->{_inputs}->[1]->{weight});
			my $x1 = intr($self->{_inputs}->[0]->{input});
			my $x2 = intr($self->{_inputs}->[1]->{input});
			# node type: $b1 $b2
			# OR       : 1   1
			# AND	   : 0   0
			# L        : 1   0
			# R        : 0   1
			# This is made possible by this little four-way 
			# forumla is from the ATREE 2.7 demo by 
			# M. Thomas, <monroe@cs.UAlberta.CA>
			$self->{_last_output} = ($b1+1)*$x1 + ($b2+1)*$x2 >= 2 ? 1 : 0;
			# We store the last output to use in our custom
			# weight adjustment function, below.
			return $self->{_last_output};
		};	
		
		# Adjust the leaves so it divides into a number divisible
		# evenly by two.
		__LEAF_IT:
        $leaves++ if($leaves%2 && $leaves!=1);
        $leaves++,goto __LEAF_IT if(($leaves/2)%2);
        # Create a layer spec array with every layer having half
        # the number of nodes of the layer before it
        while($leaves!=$roots) { 
			$specs->[$level++]={ nodes=>$leaves, activation=>$act };
	        $leaves/=2;
	        $leaves++ if($leaves%2 && $leaves!=$roots);
		}
		$specs->[$level++]={ nodes=>$roots, activation=>$act };
		
		# Add a method to the net to print out the node types
		*{'AI::NeuralNet::Mesh::print_aln'} = sub {
			my $self=shift;
			my ($c,$l)=(0,0);
			for(0..$self->{total_nodes}-1) {
				my $b1 = intr($self->{mesh}->[$_]->{_inputs}->[0]->{weight});
				my $b2 = intr($self->{mesh}->[$_]->{_inputs}->[1]->{weight});
			    print "OR "  if( $b1 &&  $b2);
				print "AND " if(!$b1 && !$b2);
				print "L "   if( $b1 && !$b2);
				print "R "   if(!$b1 &&  $b2);
				$c=0,$l++,print "\n" if++$c>=$self->{layers}->[$l];
			}
		};
		
		# Add a custom node weight adjuster to learn faster
		*{'AI::NeuralNet::Mesh::node::adjust_weight'} = sub {
			my ($self,$inc,$taget) = @_; 
			my $f;
			my $b1 = intr($self->{mesh}->[$_]->{_inputs}->[0]->{weight});
			my $b2 = intr($self->{mesh}->[$_]->{_inputs}->[1]->{weight});
			$f=1 if( $b1 &&  $b2);
			$f=2 if(!$b1 && !$b2);
			my $lo = $self->{_last_output};
			if($lo!=$target) {
				# Adjust right lead if $lo, else adjust left lead
				($target &&  $lo)?$self->{_inputs}->[0]->{weight}++:$self->{_inputs}->[0]->{weight}--;
				($target && !$lo)?$self->{_inputs}->[1]->{weight}++:$self->{_inputs}->[1]->{weight}--;
			}
			# Thanks to Rolf Mandersheidd for this set of nested conditions on one line
			# This determines heuristic error responsibilty on the children
			# and recurses the error up the tree.
			if($lo!=$target || $f!=($lo?1:2)) {
				$self->{_inputs}->[1]->{node}->adjust_weight($inc,$target) if($self->{_inputs}->[1]->{node});
			} else {
				$self->{_inputs}->[0]->{node}->adjust_weight($inc,$target) if($self->{_inputs}->[1]->{node});
			}
		};

	    # Set our custom node connector
		$AI::NeuralNet::Mesh::Connector = 'main::_c_tree'; 
		
		# Create a new network from our specs
		my $net = AI::NeuralNet::Mesh->new($specs);
		$net->{_original_specs} = $specs;
		
		# Return our new network
		return $net;
	}
	
	# Our custom node connector for the tree function, above.
	# This connects every two nodes from the first range
	# to one node of the second range. This is only meant
	# to be used in a factored layer mesh, such as one with a
	# [8,4,2,1] node specification array. You should never
	# worry about what the node spec array is, as that is
	# built by tree().
	sub _c_tree {
    	my ($self,$r1a,$r1b,$r2a,$r2b)=@_;
    	my $mesh = $self->{mesh};
    	my $z=$r2a;
    	for(my $y=0;$y<($r1b-$r1a);$y+=2) {
			$mesh->[$y]->add_output_node($mesh->[$z]);
			$mesh->[$y+1]->add_output_node($mesh->[$z]);
			$z++;
		}
	}
    
	