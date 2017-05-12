#!/usr/bin/perl	

# Copyright (c) 2000  Josiah Bryan  USA
#
# See AUTHOR section in pod text below for usage and distribution rights.   
#

BEGIN {
	 $AI::NeuralNet::Mesh::VERSION = "0.44";
	 $AI::NeuralNet::Mesh::ID = 
'$Id: AI::NeuralNet::Mesh.pm, v'.$AI::NeuralNet::Mesh::VERSION.' 2000/15/09 03:29:08 josiah Exp $';
}

package AI::NeuralNet::Mesh;
                                 
    require Exporter;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(range intr pdiff);
	%EXPORT_TAGS = ( 
		'default'    => [ qw ( range intr pdiff )],
		'all'        => [ qw ( p low high ramp and_gate or_gate range intr pdiff ) ],
		'p'          => [ qw ( p low high intr pdiff ) ],
		'acts'       => [ qw ( ramp and_gate or_gate range ) ],
	);
    @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} }, qw( p low high ramp and_gate or_gate ) );
    
    use strict;
    use Benchmark; 

   	# See POD for usage of this variable.
	$AI::NeuralNet::Mesh::Connector = '_c';
	
	# Debugging subs
	$AI::NeuralNet::Mesh::DEBUG  = 0;
	sub whowasi { (caller(1))[3] . '()' }
	sub debug { shift; $AI::NeuralNet::Mesh::DEBUG = shift || 0; } 
	sub d { shift if(substr($_[0],0,4) eq 'AI::'); my ($a,$b,$c)=(shift,shift,$AI::NeuralNet::Mesh::DEBUG); print $a if($c == $b); return $c }
	sub verbose {debug @_};
	sub verbosity {debug @_};
	sub v {debug @_};
	
	
	# Return version of ::ID string passed or current version of this
	# module if no string is passed. Used in load() to detect file versions.
	sub version {
		shift if(substr($_[0],0,4) eq 'AI::');
		substr((split(/\s/,(shift || $AI::NeuralNet::Mesh::ID)))[2],1);
	}                                  
	
	# Rounds a floating-point to an integer with int() and sprintf()
	sub intr  {
    	shift if(substr($_[0],0,4) eq 'AI::');
      	try   { return int(sprintf("%.0f",shift)) }
      	catch { return 0 }
	}
    
	# Package constructor
	sub new {
		no strict 'refs';
		my $type	=	shift;
		my $self	=	{};
		my $layers	=	shift;
		my $nodes	=	shift;
		my $outputs	=	shift || $nodes;
		my $inputs	=	shift || $nodes;
        
		bless $self, $type;
		                       
		# If $layers is a string, then it will be numerically equal to 0, so 
		# try to load it as a network file.
		if($layers == 0) {  
		    # We use a "1" flag as the second argument to indicate that we 
		    # want load() to call the new constructor to make a network the
		    # same size as in the file and return a refrence to the network,
		    # instead of just creating the network from pre-exisiting refrence
			return $self->load($layers,1);
		}
		
		# Looks like we got ourselves a layer specs array
		if(ref($layers) eq "ARRAY") { 
			if(ref($layers->[0]) eq "HASH") {
				$self->{total_nodes}	=	0;
				$self->{inputs}			=	$layers->[0]->{nodes};
				$self->{nodes}			=	$layers->[0]->{nodes};
				$self->{outputs}		=	$layers->[$#{$layers}]->{nodes};
				$self->{total_layers}	=	$#{$layers};
				for (0..$#{$layers}){$self->{layers}->[$_] = $layers->[$_]->{nodes}}
				for (0..$self->{total_layers}){$self->{total_nodes}+=$self->{layers}->[$_]}	
			} else {
				$self->{inputs}			= $layers->[0];
			    $self->{nodes}			= $layers->[0];
				$self->{outputs}		= $layers->[$#{$layers}];
				$self->{layers} 		= $layers;
				$self->{total_layers}	= $#{$self->{layers}};
				$self->{total_nodes}	= 0;
				for (0..$self->{total_layers}) {
					$self->{total_nodes}+=$self->{layers}->[$_];
				}
			}
		} else {
			$self->{total_nodes}	= $layers * $nodes + $outputs;
			$self->{total_layers}	= $layers;
			$self->{nodes}			= $nodes;
			$self->{inputs}			= $inputs;
			$self->{outputs}		= $outputs;
		}	
		
		# Initalize misc. variables
		$self->{col_width}		=	5;
		$self->{random}			=	0;
		$self->{const}			=	0.0001;
		$self->{connector}		=	$AI::NeuralNet::Mesh::Connector;
		
		# Build mesh
		$self->_init();	
		
		# Initalize activation, thresholds, etc, if provided
		if(ref($layers->[0]) eq "HASH") {
			for (0..$self->{total_layers}) {
				$self->activation($_,$layers->[$_]->{activation});
				$self->threshold($_,$layers->[$_]->{threshold});
				$self->mean($_,$layers->[$_]->{mean});
			}
		}
				
		# Done!
		return $self;
	}	
    

    # Internal usage
    # Connects one range of nodes to another range
    sub _c {
    	my $self	=	shift;
    	my $r1a		=	shift;
    	my $r1b		=	shift;
    	my $r2a		=	shift;
    	my $r2b		=	shift;
    	my $m1		=	shift || $self->{mesh};
    	my $m2		=	shift || $m1;
		for my $y ($r1a..$r1b-1) {
			for my $z ($r2a..$r2b-1) {
				$m1->[$y]->add_output_node($m2->[$z]);
			}
		}
	}
    
    # Internal usage
    # Creates the mesh of neurons
    sub _init {
    	my $self		=	shift;
    	my $nodes		=	$self->{nodes};
    	my $outputs		=	$self->{outputs} || $nodes;
    	my $inputs		=	$self->{inputs}  || $nodes;
    	my $layers		=	$self->{total_layers};
        my $tmp 		=	$self->{total_nodes} || ($layers * $nodes + $outputs);
    	my $layer_specs	=	$self->{layers};
    	my $connector	=	$self->{connector};
        my ($x,$y,$z);
        no strict 'refs';
        
        # Just to be safe.
        $self->{total_nodes} = $tmp;
        
        # If they didn't give layer specifications, then we derive our own specs.
        if(!(defined $self->{layers})) {
        	$layer_specs = [split(',',"$nodes," x $layers)];
        	$layer_specs->[$#{$layer_specs}+1]=$outputs;
        	$self->{layers}	= $layer_specs;
        }
        
        # First create the individual nodes
		for my $x (0..$tmp-1) {         
			$self->{mesh}->[$x] = AI::NeuralNet::Mesh::node->new($self);
        }              
        
        # Get an instance of an output (data collector) node
		$self->{output} = AI::NeuralNet::Mesh::output->new($self);
		
		# Connect the output layer to the data collector
        for $x (0..$outputs-1) {                    
			$self->{mesh}->[$tmp-$outputs+$x]->add_output_node($self->{output});
		}
		
		# Now we use the _c() method to connect the layers together.
        $y=0;
        my $c = $connector.'($self,$y,$y+$z,$y+$z,$y+$z+$layer_specs->[$x+1])';
        for $x (0..$layers-1) {
        	$z = $layer_specs->[$x];                         
        	d("layer $x size: $z (y:$y)\n,",1);
        	eval $c;
        	$y+=$z;
		}		
		
		# Get an instance of our cap node.
		$self->{input}->{cap} = AI::NeuralNet::Mesh::cap->new(); 

		# Add a cap to the bottom of the mesh to stop it from trying
		# to recursivly adjust_weight() where there are no more nodes.		
		for my $x (0..$inputs-1) {
			$self->{input}->{IDs}->[$x] = 
				$self->{mesh}->[$x]->add_input_node($self->{input}->{cap});
		}
	}
    
    # See POD for usage
    sub extend {
    	my $self	=	shift;
    	my $layers	=	shift;
    
    	# Looks like we got ourselves a layer specs array
		if(ref($layers) eq "ARRAY") { 
			if($self->{total_layers}!=$#{$layers}) {
				$self->{error} = "extend(): Cannot add new layers. Create a new network to add layers.\n";
				return undef;
			}
			if(ref($layers->[0]) eq "HASH") {
				$self->{total_nodes}	=	0;
				$self->{inputs}			=	$layers->[0]->{nodes};
				$self->{nodes}			=	$layers->[0]->{nodes};
				$self->{outputs}		=	$layers->[$#{$layers}]->{nodes};
				for (0..$#{$layers}){
					$self->extend_layer($_,$layers->[$_]);
					$self->{layers}->[$_] =$layers->[$_]->{nodes};
				}
				for (0..$self->{total_layers}){$self->{total_nodes}+=$self->{layers}->[$_]}	
			} else {
				$self->{inputs}			= $layers->[0];
			    $self->{nodes}			= $layers->[0];
				$self->{outputs}		= $layers->[$#{$layers}];
				$self->{total_nodes}	= 0;
				for (0..$self->{total_layers}){$self->extend_layer($_,$layers->[$_])}
				$self->{layers} 		= $layers;
				for (0..$self->{total_layers}){$self->{total_nodes}+= $self->{layers}->[$_]}
			}
		} else {
			$self->{error} = "extend(): Invalid argument type.\n";
			return undef;
		}
		return 1;
	}
    
    # See POD for usage
    sub extend_layer {
    	my $self	=	shift;
    	my $layer	=	shift || 0;
    	my $specs	=	shift;
    	if(!$specs) {
    		$self->{error} = "extend_layer(): You must provide specs to extend layer $layer with.\n";
    		return undef;
    	}
    	if(ref($specs) eq "HASH") {
    		$self->activation($layer,$specs->{activation}) if($specs->{activation});
    		$self->threshold($layer,$specs->{threshold})   if($specs->{threshold});
    		$self->mean($layer,$specs->{mean})             if($specs->{mean});
    		return $self->add_nodes($layer,$specs->{nodes});
    	} else { 
    		return $self->add_nodes($layer,$specs);
    	}
    	return 1;
    }
    
    # Pseudo-internal usage
    sub add_nodes {
    	no strict 'refs';
		my $self	=	shift;
    	my $layer	=	shift;
    	my $nodes	=	shift;
    	my $n		=	0;
		my $more	=	$nodes - $self->{layers}->[$layer] - 1;
        d("Checking on extending layer $layer to $nodes nodes (check:$self->{layers}->[$layer]).\n",9);
        return 1 if ($nodes == $self->{layers}->[$layer]);
        if ($self->{layers}->[$layer]>$nodes) {
        	$self->{error} = "add_nodes(): I cannot remove nodes from the network with this version of my module. You must create a new network to remove nodes.\n";
        	return undef;
        }
        d("Extending layer $layer by $more.\n",9);
        for (0..$more){$self->{mesh}->[$#{$self->{mesh}}+1]=AI::NeuralNet::Mesh::node->new($self)}
        for(0..$layer-2){$n+=$self->{layers}->[$_]}
		$self->_c($n,$n+$self->{layers}->[$layer-1],$#{$self->{mesh}}-$more+1,$#{$self->{mesh}});
		$self->_c($#{$self->{mesh}}-$more+1,$#{$self->{mesh}},$n+$self->{layers}->[$layer],$n+$self->{layers}->[$layer]+$self->{layers}->[$layer+1]);
    }
        
        
    # See POD for usage
    sub run {
    	my $self	=	shift;
    	my $inputs	=	shift;
    	my $const	=	$self->{const};
    	#my $start	=	new Benchmark;
    	$inputs		=	$self->crunch($inputs) if($inputs == 0);
    	no strict 'refs';
    	for my $x (0..$#{$inputs}) {
    		last if($x>$self->{inputs});
    		d("inputing $inputs->[$x] at index $x with ID $self->{input}->{IDs}->[$x].\n",1);
    		$self->{mesh}->[$x]->input($inputs->[$x]+$const,$self->{input}->{IDs}->[$x]);
    	}
    	if($#{$inputs}<$self->{inputs}-1) {
	    	for my $x ($#{$inputs}+1..$self->{inputs}-1) {
	 	    	d("inputing 1 at index $x with ID $self->{input}->{IDs}->[$x].\n",1);
	    		$self->{mesh}->[$x]->input(1,$self->{input}->{IDs}->[$x]);
	    	}
	    }
    	#$self->{benchmark} = timestr(timediff(new Benchmark, $start));
    	return $self->{output}->get_outputs();
    }    
    
    # See POD for usage
    sub run_uc {
    	$_[0]->uncrunch(run(@_));
    }

	# See POD for usage
	sub learn {
    	my $self	=	shift;					
    	my $inputs	=	shift;					# input set
    	my $outputs	=	shift;					# target outputs
    	my %args	=	@_;						# get args into hash
    	my $inc		=	$args{inc} || 0.002;	# learning gradient
    	my $max     =   $args{max} || 1024;     # max iteterations
    	my $degrade =   $args{degrade} || 0;    # enable gradient degrading
		my $error   = 	($args{error}>-1 && defined $args{error}) ? $args{error} : -1;
  		my $dinc	=	0.0002;					# amount to adjust gradient by
		my $diff	=	100;					# error magin between results
		my $start	=	new Benchmark;			
		$inputs		=	$self->crunch($inputs)  if($inputs == 0); 
		$outputs	=	$self->crunch($outputs) if($outputs == 0);
		my ($flag,$ldiff,$cdiff,$_mi,$loop,$y); 
		while(!$flag && ($max ? $loop<$max : 1)) {
    		my $b	=	new Benchmark;
    		my $got	=	$self->run($inputs);
    		$diff 	=	pdiff($got,$outputs);
		    $flag	=	1;
    		    		
		    if(($error>-1 ? $diff<$error : 0) || !$diff) {
				$flag=1;
				last;
			}
			
			if($degrade) {
				$inc   -= ($dinc*$diff);
				
				if($diff eq $ldiff) {
					$cdiff++;
					$inc += ($dinc*$diff)+($dinc*$cdiff*10);
				} else {
					$cdiff=0;
				}
				$ldiff = $diff;
			}
				
    		for my $x (0..$self->{outputs}-1) { 
    			my $a	=	$got->[$x];
    			my $b	=	$outputs->[$x];
    			d("got: $a, wanted: $b\n",2);
    			if ($a != 	$b) {
    				$flag	=	0;
    				$y 		=	$self->{total_nodes}-$self->{outputs}+$x;
    				$self->{mesh}->[$y]->adjust_weight(($a<$b?1:-1)*$inc,$b);
   				}
   			}
   			
   			$loop++;
   			
   			d("===============================Loop: [$loop]===================================\n",4);
   			d("Current Error: $diff\tCurrent Increment: $inc\n",4);
   			d("Benchmark: ".timestr(timediff(new Benchmark,$b))."\n",4);
   			d("============================Results, [$loop]===================================\n",4);
   			d("Actual: ",4);	
   			join_cols($got,($self->{col_width})?$self->{col_width}:5) if(d()==4);
   			d("Target: ",4);	
   			join_cols($outputs,($self->{col_width})?$self->{col_width}:5) if(d()==4);
   			d("\n",4);
   			d('.',12);
   			d('['.join(',',@{$got})."-".join(',',@{$outputs}).']',13);
   		}  
   		my $str = "Learning took $loop loops and ".timestr(timediff(new Benchmark,$start))."\n";
   		d($str,3); $self->{benchmark} = "$loop loops and ".timestr(timediff(new Benchmark,$start))."\n";
   		return $str;
   	}


	# See POD for usage
	sub learn_set {
		my $self	=	shift;
		my $data	=	shift;
		my %args	=	@_;
		my $len		=	$#{$data}/2;
		my $inc		=	$args{inc};
		my $max		=	$args{max};
	    my $error	=	$args{error};
	    my $degrade	=	$args{degrade};
	    my $p		=	(defined $args{flag}) ?$args{flag} :1;
	    my $row		=	(defined $args{row})  ?$args{row}+1:1;
	    my $leave	=	(defined $args{leave})?$args{leave}:0;
		for my $x (0..$len-$leave) {
			d("Learning set $x...\n",4);
			my $str = $self->learn( $data->[$x*2],
					  		  		$data->[$x*2+1],
					    			inc=>$inc,
					    			max=>$max,
					    			error=>$error,
					    			degrade=>$degrade);
		}
			
		if ($p) {
			return pdiff($data->[$row],$self->run($data->[$row-1]));
		} else {
			return $data->[$row]->[0]-$self->run($data->[$row-1])->[0];
		}
	}
	
	# See POD for usage
	sub run_set {
		my $self	=	shift;
		my $data	=	shift;
		my $len		=	$#{$data}/2;
		my (@results,$res);
		for my $x (0..$len) {
			$res = $self->run($data->[$x*2]);
			for(0..$#{$res}){$results[$x]->[$_]=$res->[$_]}
			d("Running set $x [$res->[0]]...\r",4);
		}
		return \@results;
	}
	
	#
	# Loads a CSV-like dataset from disk
	#
	# Usage:
	#	my $set = $set->load_set($file, $column, $seperator);
	#
	# Returns a data set of the same format as required by the
	# learn_set() method. $file is the disk file to load set from.
	# $column an optional variable specifying the column in the 
	# data set to use as the class attribute. $class defaults to 0.
	# $seperator is an optional variable specifying the seperator
	# character between values. $seperator defaults to ',' (a single comma). 
	# NOTE: This does not handle quoted fields, or any other record
	# seperator other than "\n".
	#
	sub load_set {
		my $self	=	shift;
		my $file	=	shift;
		my $attr	=	shift || 0;
		my $sep		=	shift || ',';
		my $data	=	[];
		open(FILE,	$file);
		my @lines	=	<FILE>;
		close(FILE);
		for my $x (0..$#lines) {
			chomp($lines[$x]);
			my @tmp	= split /$sep/, $lines[$x];
			my $c=0;
			for(0..$#tmp){ 
				$tmp[$_]=$self->crunch($tmp[$_])->[0] if($tmp[$_]=~/[AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz]/);
				if($_!=$attr){$data->[$x*2]->[$c]=$tmp[$c];$c++}
			};             
			d("Loaded line $x, [@tmp]                            \r",4);
			$data->[$x*2+1]=[$tmp[$attr]];
		}
		return $data;
	}
	
	# See POD for usage
	sub get_outs {
		my $self	=	shift;
		my $data	=	shift;
		my $len		=	$#{$data}/2;
		my $outs	=	[];
		for my $x (0..$len) {
			$outs->[$x] = $data->[$x*2+1];
		}
		return $outs;
	}
	
	# Save entire network state to disk.
	sub save {
		my $self	=	shift;
		my $file	=	shift;
		no strict 'refs';
		
		open(FILE,">$file");
	    
	    print FILE "header=$AI::NeuralNet::Mesh::ID\n";
	   	
		print FILE "total_layers=$self->{total_layers}\n";
		print FILE "total_nodes=$self->{total_nodes}\n";
	    print FILE "nodes=$self->{nodes}\n";
	    print FILE "inputs=$self->{inputs}\n";
	    print FILE "outputs=$self->{outputs}\n";
	    print FILE "layers=",(($self->{layers})?join(',',@{$self->{layers}}):''),"\n";
	    
	    print FILE "rand=$self->{random}\n";
	    print FILE "const=$self->{const}\n";
	    print FILE "cw=$self->{col_width}\n";
		print FILE "crunch=$self->{_crunched}->{_length}\n";
		print FILE "rA=$self->{rA}\n";
		print FILE "rB=$self->{rB}\n";
		print FILE "rS=$self->{rS}\n";
		print FILE "rRef=",(($self->{rRef})?join(',',@{$self->{rRef}}):''),"\n";
			
		for my $a (0..$self->{_crunched}->{_length}-1) {
			print FILE "c$a=$self->{_crunched}->{list}->[$a]\n";
		}
	
		my $n = 0;
		for my $x (0..$self->{total_layers}) {
			for my $y (0..$self->{layers}->[$x]-1) {
			    my $w='';
				for my $z (0..$self->{layers}->[$x-1]-1) {
					$w.="$self->{mesh}->[$n]->{_inputs}->[$z]->{weight},";
				}
				print FILE "n$n=$w$self->{mesh}->[$n]->{activation},$self->{mesh}->[$n]->{threshold},$self->{mesh}->[$n]->{mean}\n";
				$n++;
			}
		}
		
	    close(FILE);
	    
	    if(!(-f $file)) {
	    	$self->{error} = "Error writing to \"$file\".";
	    	return undef;
	    }
	    
	    return $self;
	}
        
	# Load entire network state from disk.
	sub load {
		my $self		=	shift;
		my $file		=	shift;  
		my $load_flag   =	shift;
		
	    my @lines;
	    
	    if(-f $file) {
		    open(FILE,"$file");
		    @lines=<FILE>;
	    	close(FILE);
	    } else {
	    	@lines=split /\n/, $file;
	    }
	    
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
	        $self = AI::NeuralNet::Mesh->new([split(',',$db{layers})]);
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
		
		return $self;
	}
	
	# Load entire network state from disk.
	sub load_old {
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
	    
	    if($load_flag) {
		    undef $self;
	
			# Create new network
			$self = AI::NeuralNet::Mesh->new($db{"layers"},
		    			 				 	 $db{"nodes"},
		    						      	 $db{"outputs"});
		} else {
			$self->{total_layers}	=	$db{"layers"};
			$self->{nodes}			=	$db{"nodes"};
			$self->{outputs}		=	$db{"outputs"};
			$self->{inputs}			=	$db{"nodes"};
			#$self->{total_nodes}	=	$db{"total"};
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
	    
	    my $nodes	=	$self->{nodes};
	   	my $outputs	=	$self->{outputs};
	   	my $tmp		=	$self->{total_nodes};
	   	my $div 	=	intr($nodes/$outputs);

		# Load input and hidden
		for my $a (0..$tmp-1) {
			my @l = split /\,/, $db{"n$a"};
			for my $b (0..$nodes-1) {
				$self->{mesh}->[$a]->{_inputs}->[$b]->{weight} = $l[$b];
			}                  
		}
	     
		# Load output layer
		for my $x (0..$outputs-1) {
			my @l = split /\,/, $db{"n".($tmp+$x)};
			for my $y (0..$div-1) {
				$self->{mesh}->[$tmp+$x]->{_inputs}->[$y]->{weight} = $l[$y];
		 	}
		} 
		
		return $self;
	}

	# Dumps the complete weight matrix of the network to STDIO
	sub show {
		my $self	=	shift;
		my $n 		=	0;    
		no strict 'refs';
		for my $x (0..$self->{total_layers}) {
			for my $y (0..$self->{layers}->[$x]-1) {
				for my $z (0..$self->{layers}->[$x-1]-1) {
					print "$self->{mesh}->[$n]->{_inputs}->[$z]->{weight},";
				}
				$n++;
			}
			print "\n";
		}
	}
	  
	# Set the activation type of a specific layer.
	# usage: $net->activation($layer,$type);
	# $type can be: "linear", "sigmoid", "sigmoid_2".
	# You can use "sigmoid_1" as a synonym to "sigmoid". 
	# Type can also be a CODE ref, ( ref($type) eq "CODE" ).
	# If $type is a CODE ref, then the function is called in this form:
	# 	$output	= &$type($sum_of_inputs,$self);
	# The code ref then has access to all the data in that node (thru the
	# blessed refrence $self) and is expected to return the value to be used
	# as the output for that node. The sum of all the inputs to that node
	# is already summed and passed as the first argument.
	sub activation {
		my $self	=	shift;
		my $layer	=	shift || 0;
		my $value	=	shift || 'linear';
		my $n 		=	0;    
		no strict 'refs';
		for(0..$layer-1){$n+=$self->{layers}->[$_]}
		for($n..$n+$self->{layers}->[$layer]-1) {
			$self->{mesh}->[$_]->{activation} = $value; 
		}
	}
	
	# Applies an activation type to a specific node
	sub node_activation {
		my $self	=	shift;
		my $layer	=	shift || 0;
		my $node	=	shift || 0;
		my $value	=	shift || 'linear';
		my $n 		=	0;    
		no strict 'refs';
		for(0..$layer-1){$n+=$self->{layers}->[$_]}
		$self->{mesh}->[$n+$node]->{activation} = $value; 
	}
	
	# Set the activation threshold for a specific layer.
	# Only applicable if that layer uses "sigmoid" or "sigmoid_2"
	# usage: $net->threshold($layer,$threshold);
	sub threshold {
		my $self	=	shift;
		my $layer	=	shift || 0;
		my $value	=	shift || 0.5; 
		my $n		=	0;
		no strict 'refs';
		for(0..$layer-1){$n+=$self->{layers}->[$_]}
		for($n..$n+$self->{layers}->[$layer]-1) {
			$self->{mesh}->[$_]->{threshold} = $value;
		}
	}
	
	# Applies a threshold to a specific node     
	sub node_threshold {
		my $self	=	shift;
		my $layer	=	shift || 0;
		my $node	=	shift || 0;
		my $value	=	shift || 0.5; 
		my $n		=	0;
		no strict 'refs';
		for(0..$layer-1){$n+=$self->{layers}->[$_]}
		$self->{mesh}->[$n+$node]->{threshold} = $value;
	}
	
	# Set mean (avg.) flag for a layer.
	# usage: $net->mean($layer,$flag);
	# If $flag is true, it enables finding the mean for that layer,
	# If $flag is false, disables mean.
	sub mean {
		my $self	=	shift;
		my $layer	=	shift || 0;
		my $value	=	shift || 0;
		my $n		=	0;
		no strict 'refs';
		for(0..$layer-1){$n+=$self->{layers}->[$_]}
		for($n..$n+$self->{layers}->[$layer]-1) {
			$self->{mesh}->[$_]->{mean} = $value;
		}
	}
	
	  
	# Returns a pcx object
	sub load_pcx {
		my $self	=	shift;
		my $file	=	shift;
		eval('use PCX::Loader');
		if(@_) {
			$self->{error}="Cannot load PCX::Loader module: @_";
			return undef;
		}
		return PCX::Loader->new($self,$file);
	}	
	
	# Crunch a string of words into a map
	sub crunch {
		my $self	=	shift;
		my @ws 		=	split(/[\s\t]/,shift);
		my (@map,$ic);
		for my $a (0..$#ws) {
			$ic=$self->crunched($ws[$a]);
			if(!defined $ic) {
				$self->{_crunched}->{list}->[$self->{_crunched}->{_length}++]=$ws[$a];
				$map[$a]=$self->{_crunched}->{_length};
			} else {
				$map[$a]=$ic;
            }
		}
		return \@map;
	}
	
	# Finds if a word has been crunched.
	# Returns undef on failure, word index for success.
	sub crunched {
		my $self	=	shift;
		for my $a (0..$self->{_crunched}->{_length}-1) {
			return $a+1 if($self->{_crunched}->{list}->[$a] eq $_[0]);
		}
		$self->{error} = "Word \"$_[0]\" not found.";
		return undef;
	}
	
	# Alias for crunched(), above
	sub word { crunched(@_) }
	
	# Uncrunches a map (array ref) into an array of words (not an array ref) 
	# and returns array
	sub uncrunch {
		my $self	=	shift;
		my $map = shift;
		my ($c,$el,$x);
		foreach $el (@{$map}) {
			$c .= $self->{_crunched}->{list}->[$el-1].' ';
		}
		return $c;
	}
	
	# Sets/gets randomness facter in the network. Setting a value of 0 
	# disables random factors.
	sub random {
		my $self	=	shift;
		my $rand	=	shift;
		return $self->{random}	if(!(defined $rand));
		$self->{random}	=	$rand;
	}
	
	# Sets/gets column width for printing lists in debug modes 1,3, and 4.
	sub col_width {
		my $self	=	shift;
		my $width	=	shift;
		return $self->{col_width}	if(!$width);
		$self->{col_width}	=	$width;
	} 

	# Sets/gets run const. facter in the network. Setting a value of 0 
	# disables run const. factor. 
	sub const {
		my $self	=	shift;
		my $const	=	shift;
		return $self->{const}	if(!(defined $const));
		$self->{const}	=	$const;
	}
	
	# Return benchmark time from last learn() operation.
	sub benchmark {
		shift->{benchmarked};
	}
	
	# Same as benchmark()
	sub benchmarked {
		benchmark(shift);
	}
	
	# Return the last error in the mesh, or undef if no error.
	sub error {
		my $self = shift;
		return undef if !$self->{error};
		chomp($self->{error});
		return $self->{error}."\n";
	}
	
	# Used to format array ref into columns
	# Usage: 
	#	join_cols(\@array,$row_length_in_elements,$high_state_character,$low_state_character);
	# Can also be called as method of your neural net.
	# If $high_state_character is null, prints actual numerical values of each element.
	sub join_cols {
		no strict 'refs';
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $map		=	shift;
		my $break   =	shift;
		my $a		=	shift;
		my $b		=	shift;
		my $x;
		foreach my $el (@{$map}) { 
			my $str = ((int($el))?$a:$b);
			$str=$el."\0" if(!$a);
			print $str;	$x++;
			if($x>$break-1) { print "\n"; $x=0;	}
		}
		print "\n";
	}
	
	# Returns percentage difference between all elements of two
	# array refs of exact same length (in elements).
	# Now calculates actual difference in numerical value.
	sub pdiff {
		no strict 'refs';
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $a1	=	shift;
		my $a2	=	shift;
		my $a1s	=	$#{$a1};
		my $a2s	=	$#{$a2};
		my ($a,$b,$diff,$t);
		$diff=0;
		for my $x (0..$a1s) {
			$a = $a1->[$x]; $b = $a2->[$x];
			if($a!=$b) {
				if($a<$b){$t=$a;$a=$b;$b=$t;}
				$a=1 if(!$a); $diff+=(($a-$b)/$a)*100;
			}
		}
		$a1s = 1 if(!$a1s);
		return sprintf("%.10f",($diff/$a1s));
	}
	
	# Returns $fa as a percentage of $fb
	sub p {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my ($fa,$fb)=(shift,shift); 
		sprintf("%.3f",$fa/$fb*100); #((($fb-$fa)*((($fb-$fa)<0)?-1:1))/$fa)*100
	}
	
	# Returns the index of the element in array REF passed with the highest 
	# comparative value
	sub high {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $ref1 = shift; my ($el,$len,$tmp); $tmp=0;
		foreach $el (@{$ref1}) { $len++ }
		for my $x (0..$len-1) { $tmp = $x if($ref1->[$x] > $ref1->[$tmp]) }
		return $tmp;
	}
	
	# Returns the index of the element in array REF passed with the lowest 
	# comparative value
	sub low {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $ref1 = shift; my ($el,$len,$tmp); $tmp=0;
		foreach $el (@{$ref1}) { $len++ }
		for my $x (0..$len-1) { $tmp = $x if($ref1->[$x] < $ref1->[$tmp]) }
		return $tmp;
	}  
	
	# Following is a collection of a few nifty custom activation functions.
	# range() is exported by default, the rest you can get with:
	#	use AI::NeuralNet::Mesh ':acts'
	# The ':all' tag also gets these into your namespace.
	 
	#
	# range() returns a closure limiting the output 
	# of that node to a specified set of values.
	# Good for output layers.
	#
	# usage example:
	#	$net->activation(4,range(0..5));
	# or:
	#	..
	#	{ 
	#		nodes		=>	1,
	#		activation	=>	range 5..2
	#	}
	#	..
	# You can also pass an array containing the range
	# values (not array ref), or you can pass a comma-
	# seperated list of values as parameters:
	#
	#	$net->activation(4,range(@numbers));
	#	$net->activation(4,range(6,15,26,106,28,3));
	#
	# Note: when using a range() activatior, train the
	# net TWICE on the data set, because the first time
	# the range() function searches for the top value in
	# the inputs, and therefore, results could flucuate.
	# The second learning cycle guarantees more accuracy.
	#	
	sub range {
		my @r=@_;
		sub{$_[1]->{t}=$_[0]if($_[0]>$_[1]->{t});$r[intr($_[0]/$_[1]->{t}*$#r)]}
	}
	
	#
	# ramp() preforms smooth ramp activation between 0 and 1 if $r is 1, 
	# or between -1 and 1 if $r is 2. $r defaults to 1, as you can see.	
	#
	# Note: when using a ramp() activatior, train the
	# net at least TWICE on the data set, because the first 
	# time the ramp() function searches for the top value in
	# the inputs, and therefore, results could flucuate.
	# The second learning cycle guarantees more accuracy.
	#
	sub ramp {
		my $r=shift||1;my $t=($r<2)?0:-1;
		sub{$_[1]->{t}=$_[0]if($_[0]>$_[1]->{t});$_[0]/$_[1]->{t}*$r-$b}
	}

	# Self explanitory, pretty much. $threshold is used to decide if an input 
	# is true or false (1 or 0). If an input is below $threshold, it is false.
	sub and_gate {
		my $threshold = shift || 0.5;
		sub {
			my $sum  = shift;
			my $self = shift;
			for my $x (0..$self->{_inputs_size}-1) { return $self->{_parent}->{const} if!$self->{_inputs}->[$x]->{value}<$threshold }
			return $sum/$self->{_inputs_size};
		}
	}
	
	# Self explanitory, $threshold is used same as above.
	sub or_gate {
		my $threshold = shift || 0.5;
		sub {
			my $sum  = shift;
			my $self = shift;
			for my $x (0..$self->{_inputs_size}-1) { return $sum/$self->{_inputs_size} if!$self->{_inputs}->[$x]->{value}<$threshold }
			return $self->{_parent}->{const};
		}
	}
	
1;

package AI::NeuralNet::Mesh::node;
	
	use strict;

	# Node constructor
	sub new {
		my $type		=	shift;
		my $self		={ 
			_parent		=>	shift,
			_inputs		=>	[],
			_outputs	=>	[]
		};
		bless $self, $type;
	}

	# Receive inputs from other nodes, and also send
	# outputs on.	
	sub input {
		my $self	=	shift;
		my $input	=	shift;
		my $from_id	=	shift;
		
		$self->{_inputs}->[$from_id]->{value} = $input * $self->{_inputs}->[$from_id]->{weight};
		$self->{_inputs}->[$from_id]->{input} = $input;
		$self->{_inputs}->[$from_id]->{fired} = 1;
		
		$self->{_parent}->d("got input $input from id $from_id, weighted to $self->{_inputs}->[$from_id]->{value}.\n",1);
		
		my $flag	=	1;
		for my $x (0..$self->{_inputs_size}-1) { $flag = 0 if(!$self->{_inputs}->[$x]->{fired}) }
		if ($flag) {
			$self->{_parent}->d("all inputs fired for $self.\n",1);
			my $output	=	0;   
			
			# Sum
			for my $i (@{$self->{_inputs}}) {                        
				$output += $i->{value};
			}
		
			# Handle activations, thresholds, and means
			$output	   /=  $self->{_inputs_size} if($self->{flag_mean});
			#$output    += (rand()*$self->{_parent}->{random});
			$output		= ($output>=$self->{threshold})?1:0 if(($self->{activation} eq "sigmoid") || ($self->{activation} eq "sigmoid_1"));
			if($self->{activation} eq "sigmoid_2") {
				$output =  1 if($output >$self->{threshold});
				$output = -1 if($output <$self->{threshold});
				$output =  0 if($output==$self->{threshold});
			}
			
			# Handle CODE refs
			$output = &{$self->{activation}}($output,$self) if(ref($self->{activation}) eq "CODE");
			
			# Send output
			for my $o (@{$self->{_outputs}}) { $o->{node}->input($output,$o->{from_id}) }
		} else {
			$self->{_parent}->d("all inputs have NOT fired for $self.\n",1);
		}
	}

	sub add_input_node {
		my $self	=	shift;
		my $node	=	shift;
		my $i		=	$self->{_inputs_size} || 0;
		$self->{_inputs}->[$i]->{node}	 = $node;
		$self->{_inputs}->[$i]->{value}	 = 0;
		$self->{_inputs}->[$i]->{weight} = 1; #rand()*1;
		$self->{_inputs}->[$i]->{fired}	 = 0;
		$self->{_inputs_size} = ++$i;
		return $i-1;
	}
	
	sub add_output_node {
		my $self	=	shift;
		my $node	=	shift;
		my $i		=	$self->{_outputs_size} || 0;
		$self->{_outputs}->[$i]->{node}		= $node;
		$self->{_outputs}->[$i]->{from_id}	= $node->add_input_node($self);
		$self->{_outputs_size} = ++$i;
		return $i-1;
	}     
	
	sub adjust_weight {
		my $self	=	shift;
		my $inc		=	shift;
		for my $i (@{$self->{_inputs}}) {
			$i->{weight} += $inc * $i->{weight};
			$i->{node}->adjust_weight($inc) if($i->{node});
		}
	}

1;	
	
# Internal usage, prevents recursion on empty nodes.
package AI::NeuralNet::Mesh::cap;
	sub new     { bless {}, shift }
	sub input           {}
	sub adjust_weight   {}
	sub add_output_node {}
	sub add_input_node  {}
1;

# Internal usage, collects data from output layer.
package AI::NeuralNet::Mesh::output;
	
	use strict;
	
	sub new {
		my $type		=	shift;
		my $self		={ 
			_parent		=>	shift,
			_inputs		=>	[],
		};
		bless $self, $type;
	}
	
	sub add_input_node {
		my $self	=	shift;
		return (++$self->{_inputs_size})-1;
	}
	
	sub input {
		my $self	=	shift;
		my $input	=	shift;
		my $from_id	=	shift;
		$self->{_parent}->d("GOT INPUT [$input] FROM [$from_id]\n",1);
		$self->{_inputs}->[$from_id] = $self->{_parent}->intr($input);
	}
	
	sub get_outputs {
		my $self	=	shift;
		return $self->{_inputs};
	}

1;
                                       
__END__

=head1 NAME

AI::NeuralNet::Mesh - An optimized, accurate neural network Mesh.

=head1 SYNOPSIS
    
	use AI::NeuralNet::Mesh;

    # Create a mesh with 2 layers, 2 nodes/layer, and one output node.
	my $net = new AI::NeuralNet::Mesh(2,2,1);
	
	# Teach the network the AND function
	$net->learn([0,0],[0]);
	$net->learn([0,1],[0]);
	$net->learn([1,0],[0]);
	$net->learn([1,1],[1]);
	
	# Present it with two test cases
	my $result_bit_1 = $net->run([0,1])->[0];
	my $result_bit_2 = $net->run([1,1])->[0];
	
	# Display the results
	print "AND test with inputs (0,1): $result_bit_1\n";
	print "AND test with inputs (1,1): $result_bit_2\n";
	

=head1 VERSION & UPDATES

This is version B<0.44>, an update release for version 0.43.

This fixed the usage conflict with perl 5.3.3.

With this version I have gone through and tuned up many area
of this module, including the descent algorithim in learn(),
as well as four custom activation functions, and several export 
tag sets. With this release, I have also included a few
new and more practical example scripts. (See ex_wine.pl) This release 
also includes a simple example of an ALN (Adaptive Logic Network) made
with this module. See ex_aln.pl. Also in this release is support for 
loading data sets from simple CSV-like files. See the load_set() method 
for details. This version also fixes a big bug that I never knew about 
until writing some demos for this version - that is, when trying to use 
more than one output node, the mesh would freeze in learning. But, that 
is fixed now, and you can have as many outputs as you want (how does 3 
inputs and 50 outputs sound? :-)


=head1 DESCRIPTION

AI::NeuralNet::Mesh is an optimized, accurate neural network Mesh.
It was designed with accruacy and speed in mind. 

This network model is very flexable. It will allow for clasic binary
operation or any range of integer or floating-point inputs you care
to provide. With this you can change activation types on a per node or
per layer basis (you can even include your own anonymous subs as 
activation types). You can add sigmoid transfer functions and control
the threshold. You can learn data sets in batch, and load CSV data
set files. You can do almost anything you need to with this module.
This code is deigned to be flexable. Any new ideas for this module?
See AUTHOR, below, for contact info.

This module is designed to also be a customizable, extensable 
neural network simulation toolkit. Through a combination of setting
the $Connection variable and using custom activation functions, as
well as basic package inheritance, you can simulate many different
types of neural network structures with very little new code written
by you.

In this module I have included a more accurate form of "learning" for the
mesh. This form preforms descent toward a local error minimum (0) on a 
directional delta, rather than the desired value for that node. This allows
for better, and more accurate results with larger datasets. This module also
uses a simpler recursion technique which, suprisingly, is more accurate than
the original technique that I've used in other ANNs.

=head1 EXPORTS

This module exports three functions by default:

	range
	intr
	pdiff
	
See range() intr() and pdiff() for description of their respective functions.

Also provided are several export tag sets for usage in the form of:

	use AI::NeuralNet::Mesh ':tag';
	
Tag sets are:

	:default 
	    - These functions are always exported.
		- Exports:
		range()
		intr()
		pdiff()
	
	:all
		- Exports:
		p()
		high()
		low()
		range()
		ramp()
		and_gate()
		or_gate()
	
	:p
		- Exports:
		p()
		high()
		low()
	
	:acts
		- Exports:
		ramp()
		and_gate()
		or_gate()

See the respective methods/functions for information about
each method/functions usage.


=head1 METHODS

=item AI::NeuralNet::Mesh->new();

There are four ways to construct a new network with new(). Each is detailed below.

P.S. Don't worry, the old C<new($layers, $nodes [, $outputs])> still works like always!

=item AI::NeuralNet::Mesh->new($layers, $nodes [, $outputs]);

Returns a newly created neural network from an C<AI::NeuralNet::Mesh>
object. The network will have C<$layers> number of layers in it
and it will have C<$nodes> number of nodes per layer.

There is an optional parameter of $outputs, which specifies the number
of output neurons to provide. If $outputs is not specified, $outputs
defaults to equal $size. 


=item AI::NeuralNet::Mesh->new($file);

This will automatically create a new network from the file C<$file>. It will
return undef if the file was of an incorrect format or non-existant. Otherwise,
it will return a blessed refrence to a network completly restored from C<$file>.

=item AI::NeuralNet::Mesh->new(\@layer_sizes);

This constructor will make a network with the number of layers corresponding to the length
in elements of the array ref passed. Each element in the array ref passed is expected
to contain an integer specifying the number of nodes (neurons) in that layer. The first
layer ($layer_sizes[0]) is to be the input layer, and the last layer in @layer_sizes is to be
the output layer.

Example:

	my $net = AI::NeuralNet::Mesh->new([2,3,1]);
	

Creates a network with 2 input nodes, 3 hidden nodes, and 1 output node.


=item AI::NeuralNet::Mesh->new(\@array_of_hashes);

Another dandy constructor...this is my favorite. It allows you to tailor the number of layers,
the size of the layers, the activation type (you can even add anonymous inline subs with this one),
and even the threshold, all with one array ref-ed constructor.

Example:

	my $net = AI::NeuralNet::Mesh->new([
	    {
		    nodes        => 2,
		    activation   => linear
		},
		{
		    nodes        => 3,
		    activation   => sub {
		        my $sum  =  shift;
		        return $sum + rand()*1;
		    }
		},
		{
		    nodes        => 1,
		    activation   => sigmoid,
		    threshold    => 0.75
		}
	]);
	
	
Interesting, eh? What you are basically passing is this:

	my @info = ( 
		{ },
		{ },
		{ },
		...
	);

You are passing an array ref who's each element is a hash refrence. Each
hash refrence, or more precisely, each element in the array refrence you are passing
to the constructor, represents a layer in the network. Like the constructor above,
the first element is the input layer, and the last is the output layer. The rest are
hidden layers.

Each hash refrence is expected to have AT LEAST the "nodes" key set to the number
of nodes (neurons) in that layer. The other two keys are optional. If "activation" is left
out, it defaults to "linear". If "threshold" is left out, it defaults to 0.50.

The "activation" key can be one of four values:

	linear                    ( simply use sum of inputs as output )
	sigmoid    [ sigmoid_1 ]  ( only positive sigmoid )
	sigmoid_2                 ( positive / 0 /negative sigmoid )
	\&code_ref;

"sigmoid_1" is an alias for "sigmoid". 

The code ref option allows you to have a custom activation function for that layer.
The code ref is called with this syntax:

	$output = &$code_ref($sum_of_inputs, $self);
	
The code ref is expected to return a value to be used as the output of the node.
The code ref also has access to all the data of that node through the second argument,
a blessed hash refrence to that node.

See CUSTOM ACTIVATION FUNCTIONS for information on several included activation functions
other than the ones listed above.

Three of the activation syntaxes are shown in the first constructor above, the "linear",
"sigmoid" and code ref types.

You can also set the activation and threshold values after network creation with the
activation() and threshold() methods. 

	



=item $net->learn($input_map_ref, $desired_result_ref [, options ]);

NOTE: learn_set() now has increment-degrading turned OFF by default. See note
on the degrade flag, below.

This will 'teach' a network to associate an new input map with a desired 
result. It will return a string containg benchmarking information. 

You can also specify strings as inputs and ouputs to learn, and they will be 
crunched automatically. Example:

	$net->learn('corn', 'cob');
	
	
Note, the old method of calling crunch on the values still works just as well.	

The first two arguments may be array refs (or now, strings), and they may be 
of different lengths.

Options should be written on hash form. There are three options:
	 
	 inc      =>    $learning_gradient
	 max      =>    $maximum_iterations
	 error    =>    $maximum_allowable_percentage_of_error
	 degrade  =>    $degrade_increment_flag
	 

$learning_gradient is an optional value used to adjust the weights of the internal
connections. If $learning_gradient is ommitted, it defaults to 0.002.
 
$maximum_iterations is the maximum numbers of iteration the loop should do.
It defaults to 1024.  Set it to 0 if you never want the loop to quit before
the pattern is perfectly learned.

$maximum_allowable_percentage_of_error is the maximum allowable error to have. If 
this is set, then learn() will return when the perecentage difference between the
actual results and desired results falls below $maximum_allowable_percentage_of_error.
If you do not include 'error', or $maximum_allowable_percentage_of_error is set to -1,
then learn() will not return until it gets an exact match for the desired result OR it
reaches $maximum_iterations.

$degrade_increment_flag is a simple flag used to allow/dissalow increment degrading
during learning based on a product of the error difference with several other factors.
$degrade_increment_flag is off by default. Setting $degrade_increment_flag to a true
value turns increment degrading on. 

In previous module releases $degrade_increment_flag was not used, as increment degrading
was always on. In this release I have looked at several other network types as well
as several texts and decided that it would be better to not use increment degrading. The
option is still there for those that feel the inclination to use it. I have found some areas
that do need the degrade flag to work at a faster speed. See test.pl for an example. If
the degrade flag wasn't in test.pl, it would take a very long time to learn.



=item $net->learn_set(\@set, [ options ]);

This takes the same options as learn() (learn_set() uses learn() internally) 
and allows you to specify a set to learn, rather than individual patterns. 
A dataset is an array refrence with at least two elements in the array, 
each element being another array refrence (or now, a scalar string). For 
each pattern to learn, you must specify an input array ref, and an ouput 
array ref as the next element. Example:
	
	my @set = (
		# inputs        outputs
		[ 1,2,3,4 ],  [ 1,3,5,6 ],
		[ 0,2,5,6 ],  [ 0,2,1,2 ]
	);


Inputs and outputs in the dataset can also be strings.

See the paragraph on measuring forgetfulness, below. There are 
two learn_set()-specific option tags available:

	flag     =>  $flag
	pattern  =>  $row

If "flag" is set to some TRUE value, as in "flag => 1" in the hash of options, or if the option "flag"
is not set, then it will return a percentage represting the amount of forgetfullness. Otherwise,
learn_set() will return an integer specifying the amount of forgetfulness when all the patterns 
are learned. 

If "pattern" is set, then learn_set() will use that pattern in the data set to measure forgetfulness by.
If "pattern" is omitted, it defaults to the first pattern in the set. Example:

	my @set = (
		[ 0,1,0,1 ],  [ 0 ],
		[ 0,0,1,0 ],  [ 1 ],
		[ 1,1,0,1 ],  [ 2 ],  #  <---
		[ 0,1,1,0 ],  [ 3 ]
	);
	
If you wish to measure forgetfulness as indicated by the line with the arrow, then you would
pass 2 as the "pattern" option, as in "pattern => 2".

Now why the heck would anyone want to measure forgetfulness, you ask? Maybe you wonder how I 
even measure that. Well, it is not a vital value that you have to know. I just put in a 
"forgetfulness measure" one day because I thought it would be neat to know. 

How the module measures forgetfulness is this: First, it learns all the patterns 
in the set provided, then it will run the very first pattern (or whatever pattern
is specified by the "row" option) in the set after it has finished learning. It 
will compare the run() output with the desired output as specified in the dataset. 
In a perfect world, the two should match exactly. What we measure is how much that 
they don't match, thus the amount of forgetfulness the network has.

Example (from examples/ex_dow.pl):

	# Data from 1989 (as far as I know..this is taken from example data on BrainMaker)
	my @data = ( 
		#	Mo  CPI  CPI-1 CPI-3 	Oil  Oil-1 Oil-3    Dow   Dow-1 Dow-3   Dow Ave (output)
		[	1, 	229, 220,  146, 	20.0, 21.9, 19.5, 	2645, 2652, 2597], 	[	2647  ],
		[	2, 	235, 226,  155, 	19.8, 20.0, 18.3, 	2633, 2645, 2585], 	[	2637  ],
		[	3, 	244, 235,  164, 	19.6, 19.8, 18.1, 	2627, 2633, 2579], 	[	2630  ],
		[	4, 	261, 244,  181, 	19.6, 19.6, 18.1, 	2611, 2627, 2563], 	[	2620  ],
		[	5, 	276, 261,  196, 	19.5, 19.6, 18.0, 	2630, 2611, 2582], 	[	2638  ],
		[	6, 	287, 276,  207, 	19.5, 19.5, 18.0, 	2637, 2630, 2589], 	[	2635  ],
		[	7, 	296, 287,  212, 	19.3, 19.5, 17.8, 	2640, 2637, 2592], 	[	2641  ] 		
	);
	
	# Learn the set
	my $f = $net->learn_set(\@data, 
					  inc	=>	0.1,	
					  max	=>	500,
					 );
			
	# Print it 
	print "Forgetfullness: $f%";

    
This is a snippet from the example script examples/finance.pl, which demonstrates DOW average
prediction for the next month. A more simple set defenition would be as such:

	my @data = (
		[ 0,1 ], [ 1 ],
		[ 1,0 ], [ 0 ]
	);
	
	$net->learn_set(\@data);
	
Same effect as above, but not the same data (obviously).


=item $net->run($input_map_ref);

This method will apply the given array ref at the input layer of the neural network, and
it will return an array ref to the output of the network. run() will now automatically crunch() 
a string given as an input (See the crunch() method for info on crunching).

Example Usage:
	
	my $inputs  = [ 1,1,0,1 ];
	my $outputs = $net->run($inputs);

You can also do this with a string:
                                                                                  
	my $outputs = $net->run('cloudy - wind is 5 MPH NW');
	

See also run_uc() and run_set() below.


=item $net->run_uc($input_map_ref);

This method does the same thing as this code:
	
	$net->uncrunch($net->run($input_map_ref));

All that run_uc() does is that it automatically calls uncrunch() on the output, regardless
of whether the input was crunch() -ed or not.
	

=item $net->run_set($set);
                                                                                    
This takes an array ref of the same structure as the learn_set() method, above. It returns
an array ref. Each element in the returned array ref represents the output for the corresponding
element in the dataset passed. Uses run() internally.


=item $net->get_outs($set);

Simple utility function which takes an array ref of the same structure as the learn_set() method,
above. It returns an array ref of the same type as run_set() wherein each element contains an
output value. The output values are the target values specified in the $set passed. Each element
in the returned array ref represents the output value for the corrseponding row in the dataset
passed. (A row is two elements of the dataset together, see learn_set() for dataset structure.)

=item $net->load_set($file,$column,$seperator);

Loads a CSV-like dataset from disk

Returns a data set of the same structure as required by the
learn_set() method. $file is the disk file to load set from.
$column an optional variable specifying the column in the 
data set to use as the class attribute. $class defaults to 0.
$seperator is an optional variable specifying the seperator
character between values. $seperator defaults to ',' (a single comma). 
NOTE: This does not handle quoted fields, or any other record
seperator other than "\n".

The returned array ref is suitable for passing directly to
learn_set() or get_outs().
	

=item $net->range();

See CUSTOM ACTIVATION FUNCTIONS for information on several included activation functions.


=item $net->benchmark();

=item $net->benchmarked();

This returns a benchmark info string for the last learn() call.
It is easily printed as a string, as following:

	print "Last learn() took ",$net->benchmark(),"\n";



=item $net->verbose($level);

=item $net->verbosity($level);

=item $net->v($level);

=item $net->debug($level)

Note: verbose(), verbosity(), and v() are all functional aliases for debug().

Toggles debugging off if called with $level = 0 or no arguments. There are several levels
of debugging. 

NOTE: Debugging verbosity has been toned down somewhat from AI::NeuralNet::BackProp,
but level 4 still prints the same amount of information as you were used to. The other
levels, however, are mostly for  advanced use. Not much explanation in the other
levels, but they are included for those of you that feel daring (or just plain bored.)

Level 0 ($level = 0) : Default, no debugging information printed. All printing is 
left to calling script.

Level 1 ($level = 1) : Displays the activity between nodes, prints what values were
received and what they were weighted to.

Level 2 ($level = 2) : Just prints info from the learn() loop, in the form of "got: X, wanted Y"
type of information. This is about the third most useful debugging level, after level 12 and
level 4.

Level 3 ($level = 3) : I don't think I included any level 3 debugs in this version.

Level 4 ($level = 4) : This level is the one I use most. It is only used during learning. It
displays the current error (difference between actual outputs and the target outputs you
asked for), as well as the current loop number and the benchmark time for the last learn cycle.
Also printed are the actual outputs and the target outputs below the benchmark times.

Level 12 ($level = 12) : Level 12 prints a dot (period) [.] after each learning loop is
complete. This is useful for letting the user know that stuff is happening, but without
having to display any of the internal variables. I use this in the ex_aln.pl demo,
as well as the ex_agents.pl demo.

Toggles debuging off when called with no arguments. 



=item $net->save($filename);

This will save the complete state of the network to disk, including all weights and any
words crunched with crunch() . Also saves the layer size and activations of the network.

NOTE: The only activation type NOT saved is the CODE ref type, which must be set again
after loading.

This uses a simple flat-file text storage format, and therefore the network files should
be fairly portable.

This method will return undef if there was a problem with writing the file. If there is an
error, it will set the internal error message, which you can retrive with the error() method,
below.

If there were no errors, it will return a refrence to $net.


=item $net->load($filename);

This will load from disk any network saved by save() and completly restore the internal
state at the point it was save() was called at.

If the file is of an invalid file type, then load() will
return undef. Use the error() method, below, to print the error message.

If there were no errors, it will return a refrence to $net.

UPDATE: $filename can now be a newline-seperated set of mesh data. This enables you
to do $net->load(join("\n",<DATA>)) and other fun things. I added this mainly
for a demo I'm writing but not qutie done with yet. So, Cheers!



=item $net->activation($layer,$type);

This sets the activation type for layer C<$layer>.

C<$type> can be one of four values:

	linear                    ( simply use sum of inputs as output )
	sigmoid    [ sigmoid_1 ]  ( only positive sigmoid )
	sigmoid_2                 ( positive / 0 /negative sigmoid )
	\&code_ref;

"sigmoid_1" is an alias for "sigmoid". 

The code ref option allows you to have a custom activation function for that layer.
The code ref is called with this syntax:

	$output = &$code_ref($sum_of_inputs, $self);
	
The code ref is expected to return a value to be used as the output of the node.
The code ref also has access to all the data of that node through the second argument,
a blessed hash refrence to that node.

See CUSTOM ACTIVATION FUNCTIONS for information on several included activation functions
other than the ones listed above.

The activation type for each layer is preserved across load/save calls. 

EXCEPTION: Due to the constraints of Perl, I cannot load/save the actual subs that the code
ref option points to. Therefore, you must re-apply any code ref activation types after a 
load() call.

=item $net->node_activation($layer,$node,$type);

This sets the activation function for a specific node in a layer. The same notes apply
here as to the activation() method above.


=item $net->threshold($layer,$value);

This sets the activation threshold for a specific layer. The threshold only is used
when activation is set to "sigmoid", "sigmoid_1", or "sigmoid_2". 


=item $net->node_threshold($layer,$node,$value);

This sets the activation threshold for a specific node in a layer. The threshold only is used
when activation is set to "sigmoid", "sigmoid_1", or "sigmoid_2".  

=item $net->join_cols($array_ref,$row_length_in_elements,$high_state_character,$low_state_character);

This is more of a utility function than any real necessary function of the package.
Instead of joining all the elements of the array together in one long string, like join() ,
it prints the elements of $array_ref to STDIO, adding a newline (\n) after every $row_length_in_elements
number of elements has passed. Additionally, if you include a $high_state_character and a $low_state_character,
it will print the $high_state_character (can be more than one character) for every element that
has a true value, and the $low_state_character for every element that has a false value. 
If you do not supply a $high_state_character, or the $high_state_character is a null or empty or 
undefined string, it join_cols() will just print the numerical value of each element seperated
by a null character (\0). join_cols() defaults to the latter behaviour.



=item $net->extend(\@array_of_hashes);

This allows you to re-apply any activations and thresholds with the same array ref which
you created a network with. This is useful for re-applying code ref activations after a load()
call without having to type the code ref twice.

You can also specify the extension in a simple array ref like this:

	$net->extend([2,3,1]);
	
Which will simply add more nodes if needed to set the number of nodes in each layer to their 
respective elements. This works just like the respective new() constructor, above.

NOTE: Your net will probably require re-training after adding nodes.


=item $net->extend_layer($layer,\%hash);

With this you can modify only one layer with its specifications in a hash refrence. This hash
refrence uses the same keys as for the last new() constructor form, above. 

You can also specify just the number of nodes for the layer in this form:

	$net->extend_layer(0,5);

Which will set the number of nodes in layer 0 to 5 nodes. This is the same as calling:
	
	$net->add_nodes(0,5);

Which does the exact same thing. See add_nodes() below.

NOTE: Your net will probably require re-training after adding nodes.


=item $net->add_nodes($layer,$total_nodes);

This method was created mainly to service the extend*() group of functions, but it 
can also be called independently. This will add nodes as needed to layer C<$layer> to 
make the nodes in layer equal to $total_nodes. 

NOTE: Your net will probably require re-training after adding nodes.



=item $net->p($a,$b);

Returns a floating point number which represents $a as a percentage of $b.



=item $net->intr($float);

Rounds a floating-point number rounded to an integer using sprintf() and int() , Provides
better rounding than just calling int() on the float. Also used very heavily internally.



=item $net->high($array_ref);

Returns the index of the element in array REF passed with the highest comparative value.



=item $net->low($array_ref);

Returns the index of the element in array REF passed with the lowest comparative value.



=item $net->pdiff($array_ref_A, $array_ref_B);

This function is used VERY heavily internally to calculate the difference in percent
between elements of the two array refs passed. It returns a %.20f (sprintf-format) 
percent sting.




=item $net->show();

This will dump a simple listing of all the weights of all the connections of every neuron
in the network to STDIO.




=item $net->crunch($string);

This splits a string passed with /[\s\t]/ into an array ref containing unique indexes
to the words. The words are stored in an intenal array and preserved across load() and save()
calls. This is designed to be used to generate unique maps sutible for passing to learn() and 
run() directly. It returns an array ref.

The words are not duplicated internally. For example:

	$net->crunch("How are you?");

Will probably return an array ref containing 1,2,3. A subsequent call of:

    $net->crunch("How is Jane?");

Will probably return an array ref containing 1,4,5. Notice, the first element stayed
the same. That is because it already stored the word "How". So, each word is stored
only once internally and the returned array ref reflects that.


=item $net->uncrunch($array_ref);

Uncrunches a map (array ref) into an scalar string of words seperated by ' ' and returns the 
string. This is ment to be used as a counterpart to the crunch() method, above, possibly to 
uncrunch() the output of a run() call. Consider the below code (also in ./examples/ex1.pl):
                           
	use AI::NeuralNet::Mesh;
	my $net = AI::NeuralNet::Mesh->new(2,3);
	
	for (0..3) {
		$net->learn_set([
			$net->crunch("I love chips."),  $net->crunch("That's Junk Food!")),
			$net->crunch("I love apples."), $net->crunch("Good, Healthy Food.")),
			$net->crunch("I love pop."),    $net->crunch("That's Junk Food!")),
			$net->crunch("I love oranges."),$net->crunch("Good, Healthy Food."))
		]);
	}
	
	print $net->run_uc("I love corn.")),"\n";


On my system, this responds with, "Good, Healthy Food." If you try to run crunch() with
"I love pop.", though, you will probably get "Food! apples. apples." (At least it returns
that on my system.) As you can see, the associations are not yet perfect, but it can make
for some interesting demos!



=item $net->crunched($word);

This will return undef if the word is not in the internal crunch list, or it will return the
index of the word if it exists in the crunch list. 

If the word is not in the list, it will set the internal error value with a text message
that you can retrive with the error() method, below.

=item $net->word($word);

A function alias for crunched().


=item $net->col_width($width);

This is useful for formating the debugging output of Level 4 if you are learning simple 
bitmaps. This will set the debugger to automatically insert a line break after that many
elements in the map output when dumping the currently run map during a learn loop.

It will return the current width when called with a 0 or undef value.

The column width is preserved across load() and save() calls.


=item $net->random($rand);

This will set the randomness factor from the network. Default is 0. When called 
with no arguments, or an undef value, it will return current randomness value. When
called with a 0 value, it will disable randomness in the network. The randomness factor
is preserved across load() and save() calls. 


=item $net->const($const);

This sets the run const. for the network. The run const. is a value that is added
to every input line when a set of inputs are run() or learn() -ed, to prevent the
network from hanging on a 0 value. When called with no arguments, it returns the current
const. value. It defaults to 0.0001 on a newly-created network. The run const. value
is preserved across load() and save() calls.


=item $net->error();

Returns the last error message which occured in the mesh, or undef if no errors have
occured.


=item $net->load_pcx($filename);

NOTE: To use this function, you must have PCX::Loader installed. If you do not have
PCX::Loader installed, it will return undef and store an error for you to retrive with 
the error() method, below.

This is a treat... this routine will load a PCX-format file (yah, I know ... ancient 
format ... but it is the only one I could find specs for to write it in Perl. If 
anyone can get specs for any other formats, or could write a loader for them, I 
would be very grateful!) Anyways, a PCX-format file that is exactly 320x200 with 8 bits 
per pixel, with pure Perl. It returns a blessed refrence to a PCX::Loader object, which 
supports the following routinges/members. See example files ex_pcx.pl and ex_pcxl.pl in 
the ./examples/ directory.

See C<perldoc PCX::Loader> for information on the methods of the object returned.

You can download PCX::Loader from 
	http://www.josiah.countystart.com/modules/get.pl?pcx-loader:mpod


=head1 CUSTOM ACTIVATION FUNCTIONS 

Included in this package are four custom activation functions meant to be used
as a guide to create your own, as well as to be useful to you in normal use of the
module. There is only one function exported by default into your namespace, which
is the range() functions. These are not meant to be used as methods, but as functions.
These functions return code refs to a Perl closure which does the actual work when
the time comes.


=item range(0..X);

=item range(@range);

=item range(A,B,C);

range() returns a closure limiting the output 
of that node to a specified set of values.
Good for use in output layers.

Usage example:
	$net->activation(4,range(0..5));
or (in the new() hash constructor form):
	..
	{ 
		nodes		=>	1,
		activation	=>	range 5..2
	}
	..
You can also pass an array containing the range
values (not array ref), or you can pass a comma-
seperated list of values as parameters:

	$net->activation(4,range(@numbers));
	$net->activation(4,range(6,15,26,106,28,3));

Note: when using a range() activatior, train the
net TWICE on the data set, because the first time
the range() function searches for the top value in
the inputs, and therefore, results could flucuate.
The second learning cycle guarantees more accuracy.

The actual code that implements the range closure is
a bit convulted, so I will expand on it here as a simple
tutorial for custom activation functions.

	= line 1 = 	sub {
	= line 2 =		my @values = ( 6..10 );
	= line 3 =		my $sum   = shift;
	= line 4 =		my $self  = shift;
	= line 5 =		$self->{top_value}=$sum if($sum>$self->{top_value});
	= line 6 =		my $index = intr($sum/$self->{top_value}*$#values);
	= line 7 =		return $values[$index];
	= line 8 =	}

Now, the actual function fits in one line of code, but I expanded it a bit
here. Line 1 creates our array of allowed output values. Lines two and
three grab our parameters off the stack which allow us access to the
internals of this node. Line 5 checks to see if the sum output of this
node is higher than any previously encountered, and, if so, it sets
the marker higher. This also shows that you can use the $self refrence
to maintain information across activations. This technique is also used
in the ramp() activator. Line 6 computes the index into the allowed
values array by first scaling the $sum to be between 0 and 1 and then
expanding it to fit smoothly inside the number of elements in the array. Then
we simply round to an integer and pluck that index from the array and
use it as the output value for that node. 

See? It's not that hard! Using custom activation functions, you could do
just about anything with the node that you want to, since you have
access to the node just as if you were a blessed member of that node's object.


=item ramp($r);

ramp() preforms smooth ramp activation between 0 and 1 if $r is 1, 
or between -1 and 1 if $r is 2. $r defaults to 1.	

You can get this into your namespace with the ':acts' export 
tag as so:
	
	use AI::NeuralNet::Mesh ':acts';

Note: when using a ramp() activatior, train the
net at least TWICE on the data set, because the first 
time the ramp() function searches for the top value in
the inputs, and therefore, results could flucuate.
The second learning cycle guarantees more accuracy.

No code to show here, as it is almost exactly the same as range().


=item and_gate($threshold);

Self explanitory, pretty much. This turns the node into a basic AND gate.
$threshold is used to decide if an input is true or false (1 or 0). If 
an input is below $threshold, it is false. $threshold defaults to 0.5.

You can get this into your namespace with the ':acts' export 
tag as so:
	
	use AI::NeuralNet::Mesh ':acts';

Let's look at the code real quick, as it shows how to get at the indivudal
input connections:

	= line 1 =	sub {
	= line 2 =		my $sum  = shift;
	= line 3 =		my $self = shift;
	= line 4 =		my $threshold = 0.50;
	= line 5 =		for my $x (0..$self->{_inputs_size}-1) { 
	= line 6 =			return 0.000001 if(!$self->{_inputs}->[$x]->{value}<$threshold)
	= line 7 =		}
	= line 8 =		return $sum/$self->{_inputs_size};
	= line 9 =	}

Line 2 and 3 pulls in our sum and self refrence. Line 5 opens a loop to go over
all the input lines into this node. Line 6 looks at each input line's value 
and comparse it to the threshold. If the value of that line is below threshold, then
we return 0.000001 to signify a 0 value. (We don't return a 0 value so that the network
doen't get hung trying to multiply a 0 by a huge weight during training [it just will
keep getting a 0 as the product, and it will never learn]). Line 8 returns the mean 
value of all the inputs if all inputs were above threshold. 

Very simple, eh? :)
	
=item or_gate($threshold)

Self explanitory. Turns the node into a basic OR gate, $threshold is used same as above.

You can get this into your namespace with the ':acts' export 
tag as so:
	
	use AI::NeuralNet::Mesh ':acts';


=head1 VARIABLES

=item $AI::NeuralNet::Mesh::Connector

This is an option is step up from average use of this module. This variable 
should hold the fully qualified name of the function used to make the actual connections
between the nodes in the network. This contains '_c' by default, but if you use
this variable, be sure to add the fully qualified name of the method. For example,
in the ALN example, I use a connector in the main package called tree() instead of
the default connector. Before I call the new() constructor, I use this line of code:

	$AI::NeuralNet::Mesh::Connector = 'main::tree'
	
The tree() function is called as a blessed method when it is used internally, providing
access to the bless refrence in the first argument. See notes on CUSTOM NETWORK CONNECTORS,
below, for more information on creating your own custom connector.


=item $AI::NeuralNet::Mesh::DEBUG

This variable controls the verbosity level. It will not hurt anything to set this 
directly, yet most people find it easier to set it using the debug() method, or 
any of its aliases.


=head1 CUSTOM NETWORK CONNECTORS

Creating custom network connectors is step up from average use of this module. 
However, it can be very useful in creating other styles of neural networks, other
than the default fully-connected feed-foward network. 

You create a custom connector by setting the variable $AI::NeuralNet::Mesh::Connector
to the fully qualified name of the function used to make the actual connections
between the nodes in the network. This variable contains '_c' by default, but if you use
this variable, be sure to add the fully qualified name of the method. For example,
in the ALN example, I use a connector in the main package called tree() instead of
the default connector. Before I call the new() constructor, I use this line of code:

	$AI::NeuralNet::Mesh::Connector = 'main::tree'
	
The tree() function is called as a blessed method when it is used internally, providing
access to the bless refrence in the first argument. 

Example connector:

	sub connect_three {
    	my $self	=	shift;
    	my $r1a		=	shift;
    	my $r1b		=	shift;
    	my $r2a		=	shift;
    	my $r2b		=	shift;
    	my $mesh	=	$self->{mesh};
    	     
	    for my $y (0..($r1b-$r1a)-1) {
			$mesh->[$y+$r1a]->add_output_node($mesh->[$y+$r2a-1]) if($y>0);
			$mesh->[$y+$r1a]->add_output_node($mesh->[$y+$r2a]) if($y<($r2b-$r2a));
			$mesh->[$y+$r1a]->add_output_node($mesh->[$y+$r2a+1]) if($y<($r2b-$r2a));
		}
	}
	
This is a very simple example. It feeds the outputs	of every node in the first layer
to the node directly above it, as well as the nodes on either side of the node directly
above it, checking for range sides, of course.

The network is stored internally as one long array of node objects. The goal here
is to connect one range of nodes in that array to another range of nodes. The calling
function has already calculated the indices into the array, and it passed it to you
as the four arguments after the $self refrence. The first two arguments we will call
$r1a and $r1b. These define the start and end indices of the first range, or "layer." Likewise,
the next two arguemnts, $r2a and $r2b, define the start and end indices of the second
layer. We also grab a refrence to the mesh array so we dont have to type the $self
refrence over and over.

The loop that folows the arguments in the above example is very simple. It opens
a for() loop over the range of numbers, calculating the size instead of just going
$r1a..$r1b because we use the loop index with the next layer up as well.

$y + $r1a give the index into the mesh array of the current node to connect the output FROM.
We need to connect this nodes output lines to the next layers input nodes. We do this
with a simple method of the outputing node (the node at $y+$r1a), called add_output_node().

add_output_node() takes one simple arguemnt: A blessed refrence to a node that it is supposed
to output its final value TO. We get this blessed refrence with more simple addition.

$y + $r2a gives us the node directly above the first node (supposedly...I'll get to the "supposedly"
part in a minute.) By adding or subtracting from this number we get the neighbor nodes.
In the above example you can see we check the $y index to see that we havn't come close to
any of the edges of the range.

Using $y+$r2a we get the index of the node to pass to add_output_node() on the first node at
$y+B<$r1a>. 

And that's all there is to it!

For the fun of it, we'll take a quick look at the default connector.
Below is the actual default connector code, albeit a bit cleaned up, as well as
line numbers added.

	= line 1  =	sub _c {
	= line 2  =    	my $self	=	shift;
	= line 3  =    	my $r1a		=	shift;
	= line 4  =    	my $r1b		=	shift;
	= line 5  =    	my $r2a		=	shift;
	= line 6  =    	my $r2b		=	shift;
	= line 7  =    	my $mesh	=	$self->{mesh};
	= line 8  =		for my $y ($r1a..$r1b-1) {
	= line 9  =			for my $z ($r2a..$r2b-1) {
	= line 10 =				$mesh->[$y]->add_output_node($mesh->[$z]);
	= line 11 =			}
	= line 12 =		}
	= line 12 =	}
    
Its that easy! The simplest connector (well almost anyways). It just connects each
node in the first layer defined by ($r1a..$r1b) to every node in the second layer as
defined by ($r2a..$r2b).

Those of you that are still reading, if you do come up with any new connection functions,
PLEASE SEND THEM TO ME. I would love to see what others are doing, as well as get new
network ideas. I will probably include any connectors you send over in future releases (with
propoer credit and permission, of course).

Anyways, happy coding!


=head1 WHAT CAN IT DO?

Rodin Porrata asked on the ai-neuralnet-backprop malining list,
"What can they [Neural Networks] do?". In regards to that questioin,
consider the following:

Neural Nets are formed by simulated neurons connected together much the same
way the brain's neurons are, neural networks are able to associate and
generalize without rules.  They have solved problems in pattern recognition,
robotics, speech processing, financial predicting and signal processing, to
name a few.

One of the first impressive neural networks was NetTalk, which read in ASCII
text and correctly pronounced the words (producing phonemes which drove a
speech chip), even those it had never seen before.  Designed by John Hopkins
biophysicist Terry Sejnowski and Charles Rosenberg of Princeton in 1986,
this application made the Backprogagation training algorithm famous.  Using
the same paradigm, a neural network has been trained to classify sonar
returns from an undersea mine and rock.  This classifier, designed by
Sejnowski and R.  Paul Gorman, performed better than a nearest-neighbor
classifier.

The kinds of problems best solved by neural networks are those that people
are good at such as association, evaluation and pattern recognition.
Problems that are difficult to compute and do not require perfect answers,
just very good answers, are also best done with neural networks.  A quick,
very good response is often more desirable than a more accurate answer which
takes longer to compute.  This is especially true in robotics or industrial
controller applications.  Predictions of behavior and general analysis of
data are also affairs for neural networks.  In the financial arena, consumer
loan analysis and financial forecasting make good applications.  New network
designers are working on weather forecasts by neural networks (Myself
included).  Currently, doctors are developing medical neural networks as an
aid in diagnosis.  Attorneys and insurance companies are also working on
neural networks to help estimate the value of claims.

Neural networks are poor at precise calculations and serial processing. They
are also unable to predict or recognize anything that does not inherently
contain some sort of pattern.  For example, they cannot predict the lottery,
since this is a random process.  It is unlikely that a neural network could
be built which has the capacity to think as well as a person does for two
reasons.  Neural networks are terrible at deduction, or logical thinking and
the human brain is just too complex to completely simulate.  Also, some
problems are too difficult for present technology.  Real vision, for
example, is a long way off.

In short, Neural Networks are poor at precise calculations, but good at
association, evaluation, and pattern recognition.


=head1 EXAMPLES

Included are several example files in the "examples" directory from the
distribution ZIP file. Each of the examples includes a short explanation 
at the top of the file. Each of these are ment to demonstrate simple, yet 
practical (for the most part :-) uses of this module.
	


=head1 OTHER INCLUDED PACKAGES

These packages are not designed to be called directly, they are for internal use. They are
listed here simply for your refrence.

=item AI::NeuralNet::Mesh::node

This is the worker package of the mesh. It implements all the individual nodes of the mesh.
It might be good to look at the source for this package (in the Mesh.pm file) if you
plan to do a lot of or extensive custom node activation types.

=item AI::NeuralNet::Mesh::cap

This is applied to the input layer of the mesh to prevent the mesh from trying to recursivly
adjust weights out throug the inputs.

=item AI::NeuralNet::Mesh::output

This is simply a data collector package clamped onto the output layer to record the data 
as it comes out of the mesh. 


=head1 BUGS

This is a beta release of C<AI::NeuralNet::Mesh>, and that holding true, I am sure 
there are probably bugs in here which I just have not found yet. If you find bugs in this module, I would 
appreciate it greatly if you could report them to me at F<E<lt>jdb@wcoil.comE<gt>>,
or, even better, try to patch them yourself and figure out why the bug is being buggy, and
send me the patched code, again at F<E<lt>jdb@wcoil.comE<gt>>. 



=head1 AUTHOR

Josiah Bryan F<E<lt>jdb@wcoil.comE<gt>>

Copyright (c) 2000 Josiah Bryan. All rights reserved. This program is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself.

The C<AI::NeuralNet::Mesh> and related modules are free software. THEY COME WITHOUT WARRANTY OF ANY KIND.

$Id: AI::NeuralNet::Mesh.pm, v0.44 2000/15/09 03:29:08 josiah Exp $


=head1 THANKS

Below are a list of the people that have contributed in some way to this module (no particular order):

	Rodin Porrata, rodin@ursa.llnl.gov
	Randal L. Schwartz, merlyn@stonehedge.com
	Michiel de Roo, michiel@geo.uu.nl
	
Thanks to Randal and Michiel for spoting some documentation and makefile bugs in the last release.
Thanks to Rodin for continual suggetions and questions about the module and more.

=head1 DOWNLOAD

You can always download the latest copy of AI::NeuralNet::Mesh
from http://www.josiah.countystart.com/modules/get.pl?mesh:pod


=head1 MAILING LIST

A mailing list has been setup for AI::NeuralNet::Mesh and AI::NeuralNet::BackProp. 
The list is for discussion of AI and neural net related topics as they pertain to 
AI::NeuralNet::BackProp and AI::NeuralNet::mesh. I will also announce in the group
each time a new release of AI::NeuralNet::Mesh is available.

The list address is at:
	 ai-neuralnet-backprop@egroups.com 
	 
To subscribe, send a blank email:
	ai-neuralnet-backprop-subscribe@egroups.com  


=cut













