#!/usr/bin/perl	

# $Id: BackProp.pm,v 0.89 2000/08/12 01:05:27 josiah Exp $
#
# Copyright (c) 2000  Josiah Bryan  USA
#
# See AUTHOR section in pod text below for usage and distribution rights.   
# See UPDATES section in pod text below for info on what has changed in this release.
#

BEGIN {
	$AI::NeuralNet::BackProp::VERSION = "0.89";
}

#
# name:   AI::NeuralNet::BackProp
#
# author: Josiah Bryan 
# date:   Tuesday August 15 2000
# desc:   A simple back-propagation, feed-foward neural network with
#		  learning implemented via a generalization of Dobbs rule and
#		  several principals of Hoppfield networks. 
# online: http://www.josiah.countystart.com/modules/AI/cgi-bin/rec.pl
#

package AI::NeuralNet::BackProp::neuron;
	
	use strict;
	
	# Dummy constructor
    sub new {
    	bless {}, shift
	}	
	
	# Rounds floats to ints
	sub intr  {
    	shift if(substr($_[0],0,4) eq 'AI::');
      	try   { return int(sprintf("%.0f",shift)) }
      	catch { return 0 }
	}
    
	
	# Receives input from other neurons. They must
	# be registered as a synapse of this neuron to effectively
	# input.
	sub input {
		my $self 	 =	shift;
		my $sid		 =	shift;
		my $value	 =	shift;
		
		# We simply weight the value sent by the neuron. The neuron identifies itself to us
		# using the code we gave it when it registered itself with us. The code is in $sid, 
		# (synapse ID) and we use that to track the weight of the connection.
		# This line simply multiplies the value by its weight and gets the integer from it.
		$self->{SYNAPSES}->{LIST}->[$sid]->{VALUE}	=	intr($value	*	$self->{SYNAPSES}->{LIST}->[$sid]->{WEIGHT});
		$self->{SYNAPSES}->{LIST}->[$sid]->{FIRED}	=	1;                                 
		$self->{SYNAPSES}->{LIST}->[$sid]->{INPUT}	=	$value;
		
		# Debugger
		AI::NeuralNet::BackProp::out1("\nRecieved input of $value, weighted to $self->{SYNAPSES}->{LIST}->[$sid]->{VALUE}, synapse weight is $self->{SYNAPSES}->{LIST}->[$sid]->{WEIGHT} (sid is $sid for $self).\n");
		AI::NeuralNet::BackProp::out1((($self->input_complete())?"All synapses have fired":"Not all synapses have fired"));
		AI::NeuralNet::BackProp::out1(" for $self.\n");
		
		# Check and see if all synapses have fired that are connected to this one.
		# If they have, then generate the output value for this synapse.
		$self->output() if($self->input_complete());
	}
	
	# Loops thru and outputs to every neuron that this
	# neuron is registered as synapse of.
	sub output {
		my $self	=	shift;
		my $size	=	$self->{OUTPUTS}->{SIZE} || 0;
		my $value	=	$self->get_output();
		for (0..$size-1) {
			AI::NeuralNet::BackProp::out1("Outputing to $self->{OUTPUTS}->{LIST}->[$_]->{PKG}, index $_, a value of $value with ID $self->{OUTPUTS}->{LIST}->[$_]->{ID}.\n");
			$self->{OUTPUTS}->{LIST}->[$_]->{PKG}->input($self->{OUTPUTS}->{LIST}->[$_]->{ID},$value);
		}
	}
	
	# Used internally by output().
	sub get_output {
		my $self		=	shift;
		my $size		=	$self->{SYNAPSES}->{SIZE} || 0;
		my $value		=	0;
		my $state		= 	0;
		my (@map,@weight);
	
	    # We loop through all the syanpses connected to this one and add the weighted
	    # valyes together, saving in a debugging list.
		for (0..$size-1) {
			$value	+=	$self->{SYNAPSES}->{LIST}->[$_]->{VALUE};
			$self->{SYNAPSES}->{LIST}->[$_]->{FIRED} = 0;
			
			$map[$_]=$self->{SYNAPSES}->{LIST}->[$_]->{VALUE};
			$weight[$_]=$self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT};
		}
		                                              
		# Debugger
		AI::NeuralNet::BackProp::join_cols(\@map,5) if(($AI::NeuralNet::BackProp::DEBUG eq 3) || ($AI::NeuralNet::BackProp::DEBUG eq 2));
		AI::NeuralNet::BackProp::out2("Weights: ".join(" ",@weight)."\n");
		
		# Simply average the values and get the integer of the average.
		$state	=	intr($value/$size);
		
		# Debugger
		AI::NeuralNet::BackProp::out1("From get_output, value is $value, so state is $state.\n");
		
		# Possible future exapnsion for self excitation. Not currently used.
		$self->{LAST_VALUE}	=	$value;
		
		# Just return the $state
		return $state;
	}
	
	# Used by input() to check if all registered synapses have fired.
	sub input_complete {
		my $self		=	shift;
		my $size		=	$self->{SYNAPSES}->{SIZE} || 0;
		my $retvalue	=	1;
		
		# Very simple loop. Doesn't need explaning.
		for (0..$size-1) {
			$retvalue = 0 if(!$self->{SYNAPSES}->{LIST}->[$_]->{FIRED});
		}
		return $retvalue;
	}
	
	# Used to recursively adjust the weights of synapse input channeles
	# to give a desired value. Designed to be called via 
	# AI::NeuralNet::BackProp::NeuralNetwork::learn().
	sub weight	{                
		my $self		=	shift;
		my $ammount		=	shift;
		my $what		=	shift;
		my $size		=	$self->{SYNAPSES}->{SIZE} || 0;
		my $value;
		AI::NeuralNet::BackProp::out1("Weight: ammount is $ammount, what is $what with size at $size.\n");
		      
		# Now this sub is the main cog in the learning wheel. It is called recursively on 
		# each neuron that has been bad (given incorrect output.)
		for my $i (0..$size-1) {
			$value		=	$self->{SYNAPSES}->{LIST}->[$i]->{VALUE};

if(0) {
       
       		# Formula by Steve Purkis
       		# Converges very fast for low-value inputs. Has trouble converging on high-value
       		# inputs. Feel free to play and try to get to work for high values.
			my $delta	=	$ammount * ($what - $value) * $self->{SYNAPSES}->{LIST}->[$i]->{INPUT};
			$self->{SYNAPSES}->{LIST}->[$i]->{WEIGHT}  +=  $delta;
			$self->{SYNAPSES}->{LIST}->[$i]->{PKG}->weight($ammount,$what);
}
			
			# This formula in use by default is original by me (Josiah Bryan) as far as I know.
			
			# If it is equal, then don't adjust
			#
			### Disabled because this soemtimes causes 
			### infinte loops when learning with range limits enabled
			#
			#next if($value eq $what);
			
			# Adjust increment by the weight of the synapse of 
			# this neuron & apply direction delta
			my $delta = 
					$ammount * 
						($value<$what?1:-1) * 
							$self->{SYNAPSES}->{LIST}->[$i]->{WEIGHT};
			
			#print "($value,$what) delta:$delta\n";
			
			# Recursivly apply
			$self->{SYNAPSES}->{LIST}->[$i]->{WEIGHT}  +=  $delta;
			$self->{SYNAPSES}->{LIST}->[$i]->{PKG}->weight($ammount,$what);
			    
		}
	}
	
	# Registers some neuron as a synapse of this neuron.           
	# This is called exclusively by connect(), except for
	# in initalize_group() to connect the _map() package.
	sub register_synapse {
		my $self	=	shift;
		my $synapse	=	shift;
		my $sid		=	$self->{SYNAPSES}->{SIZE} || 0;
		$self->{SYNAPSES}->{LIST}->[$sid]->{PKG}		=	$synapse;
		$self->{SYNAPSES}->{LIST}->[$sid]->{WEIGHT}		=	1.00		if(!$self->{SYNAPSES}->{LIST}->[$sid]->{WEIGHT});
		$self->{SYNAPSES}->{LIST}->[$sid]->{FIRED}		=	0;       
		AI::NeuralNet::BackProp::out1("$self: Registering sid $sid with weight $self->{SYNAPSES}->{LIST}->[$sid]->{WEIGHT}, package $self->{SYNAPSES}->{LIST}->[$sid]->{PKG}.\n");
		$self->{SYNAPSES}->{SIZE} = ++$sid;
		return ($sid-1);
	}
	
	# Called via AI::NeuralNet::BackProp::NeuralNetwork::initialize_group() to 
	# form the neuron grids.
	# This just registers another synapes as a synapse to output to from this one, and
	# then we ask that synapse to let us register as an input connection and we
	# save the sid that the ouput synapse returns.
	sub connect {
		my $self	=	shift;
		my $to		=	shift;
		my $oid		=	$self->{OUTPUTS}->{SIZE} || 0;
		AI::NeuralNet::BackProp::out1("Connecting $self to $to at $oid...\n");
		$self->{OUTPUTS}->{LIST}->[$oid]->{PKG}	=	$to;
 		$self->{OUTPUTS}->{LIST}->[$oid]->{ID}	=	$to->register_synapse($self);
		$self->{OUTPUTS}->{SIZE} = ++$oid;
		return $self->{OUTPUTS}->{LIST}->[$oid]->{ID};
	}
1;
			 
package AI::NeuralNet::BackProp;
	
	use Benchmark;          
	use strict;
	
	# Returns the number of elements in an array ref, undef on error
	sub _FETCHSIZE {
		my $a=$_[0];
		my ($b,$x);
		return undef if(substr($a,0,5) ne "ARRAY");
		foreach $b (@{$a}) { $x++ };
		return $x;
	}

	# Debugging subs
	$AI::NeuralNet::BackProp::DEBUG  = 0;
	sub whowasi { (caller(1))[3] . '()' }
	sub debug { shift; $AI::NeuralNet::BackProp::DEBUG = shift || 0; } 
	sub out1  { print  shift() if ($AI::NeuralNet::BackProp::DEBUG eq 1) }
	sub out2  { print  shift() if (($AI::NeuralNet::BackProp::DEBUG eq 1) || ($AI::NeuralNet::BackProp::DEBUG eq 2)) }
	sub out3  { print  shift() if ($AI::NeuralNet::BackProp::DEBUG) }
	sub out4  { print  shift() if ($AI::NeuralNet::BackProp::DEBUG eq 4) }
	
	# Rounds a floating-point to an integer with int() and sprintf()
	sub intr  {
    	shift if(substr($_[0],0,4) eq 'AI::');
      	try   { return int(sprintf("%.0f",shift)) }
      	catch { return 0 }
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
			print $str;
			$x++;
			if($x>$break-1) {
				print "\n";
				$x=0;
			}
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
		my $a1s	=	$#{$a1}; #AI::NeuralNet::BackProp::_FETCHSIZE($a1);
		my $a2s	=	$#{$a2}; #AI::NeuralNet::BackProp::_FETCHSIZE($a2);
		my ($a,$b,$diff,$t);
		$diff=0;
		#return undef if($a1s ne $a2s);	# must be same length
		for my $x (0..$a1s) {
			$a = $a1->[$x];
			$b = $a2->[$x];
			if($a!=$b) {
				if($a<$b){$t=$a;$a=$b;$b=$t;}
				$a=1 if(!$a);
				$diff+=(($a-$b)/$a)*100;
			}
		}
		$a1s = 1 if(!$a1s);
		return sprintf("%.10f",($diff/$a1s));
	}
	
	# Returns $fa as a percentage of $fb
	sub p {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my ($fa,$fb)=(shift,shift);
		sprintf("%.3f",((($fb-$fa)*((($fb-$fa)<0)?-1:1))/$fa)*100);
	}
	
	# This sub will take an array ref of a data set, which it expects in this format:
	#   my @data_set = (	[ ...inputs... ], [ ...outputs ... ],
	#				   				   ... rows ...
	#				   );
	#
	# This wil sub returns the percentage of 'forgetfullness' when the net learns all the
	# data in the set in order. Usage:
	#
	#	 learn_set(\@data,[ options ]);
	#
	# Options are options in hash form. They can be of any form that $net->learn takes.
	#
	# It returns a percentage string.
	#
	sub learn_set {
		my $self	=	shift if(substr($_[0],0,4) eq 'AI::'); 
		my $data	=	shift;
		my %args	=	@_;
		my $len		=	$#{$data}/2-1;
		my $inc		=	$args{inc};
		my $max		=	$args{max};
	    my $error	=	$args{error};
	    my $p		=	(defined $args{flag})	?$args{flag}	   :1;
	    my $row		=	(defined $args{pattern})?$args{pattern}*2+1:1;
	    my ($fa,$fb);
		for my $x (0..$len) {
			print "\nLearning index $x...\n" if($AI::NeuralNet::BackProp::DEBUG);
			my $str = $self->learn( $data->[$x*2],			# The list of data to input to the net
					  		  		$data->[$x*2+1], 		# The output desired
					    			inc=>$inc,				# The starting learning gradient
					    			max=>$max,				# The maximum num of loops allowed
					    			error=>$error);			# The maximum (%) error allowed
			print $str if($AI::NeuralNet::BackProp::DEBUG); 
		}
			
		
		my $res;
		$data->[$row] = $self->crunch($data->[$row]) if($data->[$row] == 0);
		
		if ($p) {
			$res=pdiff($data->[$row],$self->run($data->[$row-1]));
		} else {
			$res=$data->[$row]->[0]-$self->run($data->[$row-1])->[0];
		}
		return $res;
	}
	
	# This sub will take an array ref of a data set, which it expects in this format:
	#   my @data_set = (	[ ...inputs... ], [ ...outputs ... ],
	#				   				   ... rows ...
	#				   );
	#
	# This wil sub returns the percentage of 'forgetfullness' when the net learns all the
	# data in the set in RANDOM order. Usage:
	#
	#	 learn_set_rand(\@data,[ options ]);
	#
	# Options are options in hash form. They can be of any form that $net->learn takes.
	#
	# It returns a true value.
	#
	sub learn_set_rand {
		my $self	=	shift if(substr($_[0],0,4) eq 'AI::'); 
		my $data	=	shift;
		my %args	=	@_;
		my $len		=	$#{$data}/2-1;
		my $inc		=	$args{inc};
		my $max		=	$args{max};
	    my $error	=	$args{error};
	    my @learned;
		while(1) {
			_GET_X:
			my $x=$self->intr(rand()*$len);
			goto _GET_X if($learned[$x]);
			$learned[$x]=1;
			print "\nLearning index $x...\n" if($AI::NeuralNet::BackProp::DEBUG); 
			my $str =  $self->learn($data->[$x*2],			# The list of data to input to the net
					  		  		$data->[$x*2+1], 		# The output desired
					    			inc=>$inc,				# The starting learning gradient
			 		    			max=>$max,				# The maximum num of loops allowed
					    			error=>$error);			# The maximum (%) error allowed
			print $str if($AI::NeuralNet::BackProp::DEBUG); 
		}
			
		
		return 1; 
	}

	# Returns the index of the element in array REF passed with the highest comparative value
	sub high {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $ref1	=	shift;
		
		my ($el,$len,$tmp);
		foreach $el (@{$ref1}) {
			$len++;
		}
		$tmp=0;
		for my $x (0..$len-1) {
			$tmp = $x if((@{$ref1})[$x] > (@{$ref1})[$tmp]);
		}
		return $tmp;
	}
	
	# Returns the index of the element in array REF passed with the lowest comparative value
	sub low {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $ref1	=	shift;
		
		my ($el,$len,$tmp);
		foreach $el (@{$ref1}) {
			$len++;
		}
		$tmp=0;
		for my $x (0..$len-1) {
			$tmp = $x if((@{$ref1})[$x] < (@{$ref1})[$tmp]);
		}
		return $tmp;
	}  
	
	# Returns a pcx object
	sub load_pcx {
		my $self	=	shift;
		return AI::NeuralNet::BackProp::PCX->new($self,shift);
	}	
	
	# Crunch a string of words into a map
	sub crunch {
		my $self	=	shift;
		my (@map,$ic);
		my @ws 		=	split(/[\s\t]/,shift);
		for my $a (0..$#ws) {
			$ic=$self->crunched($ws[$a]);
			if(!defined $ic) {
				$self->{_CRUNCHED}->{LIST}->[$self->{_CRUNCHED}->{_LENGTH}++]=$ws[$a];
				@map[$a]=$self->{_CRUNCHED}->{_LENGTH};
			} else {
				@map[$a]=$ic;
            }
		}
		return \@map;
	}
	
	# Finds if a word has been crunched.
	# Returns undef on failure, word index for success.
	sub crunched {
		my $self	=	shift;
		for my $a (0..$self->{_CRUNCHED}->{_LENGTH}-1) {
			return $a+1 if($self->{_CRUNCHED}->{LIST}->[$a] eq $_[0]);
		}
		return undef;
	}
	
	# Alias for crunched(), above
	sub word { crunched(@_) }
	
	# Uncrunches a map (array ref) into an array of words (not an array ref) and returns array
	sub uncrunch {
		my $self	=	shift;
		my $map = shift;
		my ($c,$el,$x);
		foreach $el (@{$map}) {
			$c .= $self->{_CRUNCHED}->{LIST}->[$el-1].' ';
		}
		return $c;
	}
	
	# Sets/gets randomness facter in the network. Setting a value of 0 disables random factors.
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
	
	# Sets/Removes value ranging
	sub range {
		my $self	=	shift;
		my $ref		=	shift;
		my $b		=	shift;
		if(substr($ref,0,5) ne "ARRAY") {
			if(($ref == 0) && (!defined $b)) {
				$ref	= $self->crunch($ref);
				#print "\$ref is a string, crunching to ",join(',',@{$ref}),"\n";
			} else {
    			my $a	= $ref;
    			$a		= $self->crunch($a)->[0] if($a == 0);
				$b		= $self->crunch($b)->[0] if($b == 0);
				$_[++$#_] = $a;
    			$_[++$#_] = $b;
    			$ref	= \@_;
				#print "Found ranged definition, joined to ",join(',',@{$ref}),"\n";
			}
		}
		my $rA		=	0;
		my $rB		=	$#{$ref};
		my $rS		=	0; #shift;
		if(!$rA && !$rB) {
			$self->{rA}=$self->{rB}=-1;
			return undef;
		}
		if($rB<$rA){my $t=$rA;$rA=$rB;$rB=$t};
		$self->{rA}=$rA;
		$self->{rB}=$rB;
		$self->{rS}=$rS if($rS);
		$self->{rRef} = $ref;
		return $ref;
	}
	
	# Used internally to scale outputs to fit range
	sub _range {
		my $self	=	shift;  
		my $in		=	shift;
		my $rA		=	$self->{rA};
		my $rB		=	$self->{rB};
		my $rS		=	$self->{rS};
		my $r		=	$rB;#-$rA+1;
		return $in if(!$rA && !$rB);
		my $l		=	$self->{OUT}-1;
		my $out 	=	[];
		# Adjust for a maximum outside what we have seen so far
		for my $i (0..$l) {
			$rS=$in->[$i] if($in->[$i]>$rS);
		}
		#print "\$l:$l,\$rA:$rA,\$rB:$rB,\$rS:$rS,\$r:$r\n";
		# Loop through, convert values to percentage of maximum, then multiply
		# percentage by range and add to base of range to get finaly value
		for my $i (0..$l) {
			#print "\$i:$i,\$in:$in->[$i]\n";
			$rS=1 if(!$rS);
			my $t=intr((($rS-$in->[$i])/$rS)*$r+$rA);
			#print "t:$t,$self->{rRef}->[$t],i:$i\n";
			$out->[$i] = $self->{rRef}->[$t];
		}
		$self->{rS}=$rS;
		return $out;
	}
			
		
	# Initialzes the base for a new neural network.
	# It is recomended that you call learn() before run()ing a pattern.
	# See documentation above for usage.
	sub new {
    	no strict;
    	my $type	=	shift;
		my $self	=	{};
		my $layers	=	shift;
		my $size	=	shift;
		my $out		=	shift || $size;
		my $flag	=	shift || 0;
		
		bless $self, $type;
		
		# If $layers is a string, then it will be nummerically equal to 0, so try to load it
		# as a network file.
		if($layers == 0) {  
		    # We use a "1" flag as the second argument to indicate that we want load()
		    # to call the new constructor to make a network the same size as in the file
		    # and return a refrence to the network, instead of just creating the network from
		    # pre-exisiting refrence
			return $self->load($layers,1);
		}
				
		
		#print "Creating $size neurons in each layer for $layers layer(s)...\n";
		
		AI::NeuralNet::BackProp::out2 "Creating $size neurons in each layer for $layers layer(s)...\n";
		
		# Error checking
		return undef if($out>$size);
		
		# When this is called, they tell us howmany layers and neurons in each layer.
		# But really what we store is a long line of neurons that are only divided in theory
		# when connecting the outputs and inputs.
		my $div = $size;
		my $size = $layers * $size;
		
		AI::NeuralNet::BackProp::out2 "Creating RUN and MAP systems for network...\n";
		#print "Creating RUN and MAP systems for network...\n";
		
		# Create a new runner and mapper for the network.
		$self->{RUN} = new AI::NeuralNet::BackProp::_run($self);
		$self->{MAP} = new AI::NeuralNet::BackProp::_map($self);
		
		$self->{SIZE}	=	$size;
		$self->{DIV}	=	$div;
		$self->{OUT}	=	$out;
		$self->{FLAG}	=	$flag;
		$self->{col_width}= 5;
		$self->{random} = 0.001;
		
		$self->initialize_group();
		
		return $self;
	}	

	# Save entire network state to disk.
	sub save {
		my $self	=	shift;
		my $file	=	shift;
		my $size	=	$self->{SIZE};
		my $div		=	$self->{DIV};
		my $out		=	$self->{OUT};
		my $flag	=	$self->{FLAG};

	    open(FILE,">$file");
	    
	    print FILE "size=$size\n";
	    print FILE "div=$div\n";
	    print FILE "out=$out\n";
	    print FILE "flag=$flag\n";
	    print FILE "rand=$self->{random}\n";
	    print FILE "cw=$self->{col_width}\n";
		print FILE "crunch=$self->{_CRUNCHED}->{_LENGTH}\n";
		print FILE "rA=$self->{rA}\n";
		print FILE "rB=$self->{rB}\n";
		print FILE "rS=$self->{rS}\n";
		print FILE "rRef=",(($self->{rRef})?join(',',@{$self->{rRef}}):''),"\n";
			
		for my $a (0..$self->{_CRUNCHED}->{_LENGTH}-1) {
			print FILE "c$a=$self->{_CRUNCHED}->{LIST}->[$a]\n";
		}
		
		my $w;
		for my $a (0..$self->{SIZE}-1) {
			$w="";
			for my $b (0..$self->{DIV}-1) {
				$w .= "$self->{NET}->[$a]->{SYNAPSES}->{LIST}->[$b]->{WEIGHT},";
			}
			chop($w);
			print FILE "n$a=$w\n";
		}
	
	    close(FILE);
	    
	    return $self;
	}
        
	# Load entire network state from disk.
	sub load {
		my $self	=	shift;
		my $file	=	shift;
		my $load_flag = shift || 0;
	    
	    return undef if(!(-f $file));
	    
	    open(FILE,"$file");
	    my @lines=<FILE>;
	    close(FILE);
	    
	    my %db;
	    for my $line (@lines) {
	    	chomp($line);
	    	my ($a,$b) = split /=/, $line;
	    	$db{$a}=$b;
	    }
	    
	    return undef if(!$db{"size"});
	    
	    if($load_flag) {
		    undef $self;
	
			# Create new network
		    $self = AI::NeuralNet::BackProp->new(intr($db{"size"}/$db{"div"}),
		    								     $db{"div"},
		    								     $db{"out"},
		    								     $db{"flag"});
		} else {
			$self->{DIV}	=	$db{"div"};
			$self->{SIZE}	=	$db{"size"};
			$self->{OUT}	=	$db{"out"};
			$self->{FLAG}	=	$db{"flag"};
		}
		
	    # Load variables
	    $self->{col_width}	= $db{"cw"};
	    $self->{random}		= $db{"rand"};
        $self->{rA}			= $db{"rA"};
		$self->{rB}			= $db{"rB"};
		$self->{rS}			= $db{"rS"};
		my @tmp				= split /\,/, $db{"rRef"};
		$self->{rRef}		= \@tmp;
		
	   	$self->{_CRUNCHED}->{_LENGTH}	=	$db{"crunch"};
		
		for my $a (0..$self->{_CRUNCHED}->{_LENGTH}-1) {
			$self->{_CRUNCHED}->{LIST}->[$a] = $db{"c$a"}; 
		}
		
		$self->initialize_group();
	    
		my ($w,@l);
		for my $a (0..$self->{SIZE}-1) {
			$w=$db{"n$a"};
			@l=split /\,/, $w;
			for my $b (0..$self->{DIV}-1) {
				$self->{NET}->[$a]->{SYNAPSES}->{LIST}->[$b]->{WEIGHT}=$l[$b];
			}
		}
	
	    return $self;
	}

	# Dumps the complete weight matrix of the network to STDIO
	sub show {
		my $self	=	shift;
		for my $a (0..$self->{SIZE}-1) {
			print "Neuron $a: ";
			for my $b (0..$self->{DIV}-1) {
				print $self->{NET}->[$a]->{SYNAPSES}->{LIST}->[$b]->{WEIGHT},"\t";
			}
			print "\n";
		}
	}
	
	# Used internally by new() and learn().
	# This is the sub block that actually creats
	# the connections between the synapse chains and
	# also connects the run packages and the map packages
	# to the appropiate ends of the neuron grids.
	sub initialize_group() {
		my $self	=	shift;
		my $size	=	$self->{SIZE};
		my $div		=	$self->{DIV};
		my $out		=	$self->{OUT};
		my $flag	=	$self->{FLAG};
		my $x		=	0; 
		my $y		=	0;
		
		# Reset map and run synapse counters.
		$self->{RUN}->{REGISTRATION} = $self->{MAP}->{REGISTRATION} = 0;
		
		AI::NeuralNet::BackProp::out2 "There will be $size neurons in this network group, with a divison value of $div.\n";
		#print "There will be $size neurons in this network group, with a divison value of $div.\n";
		
		# Create initial neuron packages in one long array for the entire group
		for($y=0; $y<$size; $y++) {
			#print "Initalizing neuron $y...     \r";
			$self->{NET}->[$y]=new AI::NeuralNet::BackProp::neuron();
		}
		
		AI::NeuralNet::BackProp::out2 "Creating synapse grid...\n";
		
		my $z  = 0;    
		my $aa = 0;
		my ($n0,$n1,$n2);
		
		# Outer loop loops over every neuron in group, incrementing by the number
		# of neurons supposed to be in each layer
		
		for($y=0; $y<$size; $y+=$div) {
			if($y+$div>=$size) {
				last;
			}
			
			# Inner loop connects every neuron in this 'layer' to one input of every neuron in
			# the next 'layer'. Remeber, layers only exist in terms of where the connections
			# are divided. For example, if a person requested 2 layers and 3 neurons per layer,
			# then there would be 6 neurons in the {NET}->[] list, and $div would be set to
			# 3. So we would loop over and every 3 neurons we would connect each of those 3 
			# neurons to one input of every neuron in the next set of 3 neurons. Of course, this
			# is an example. 3 and 2 are set by the new() constructor.
			
			# Flag values:
			# 0 - (default) - 
			# 	My feed-foward style: Each neuron in layer X is connected to one input of every
			#	neuron in layer Y. The best and most proven flag style.
			#
			#   ^   ^   ^               
			#	O\  O\ /O       Layer Y
			#   ^\\/^/\/^
			#	| //|\/\|
			#   |/ \|/ \|		
			#	O   O   O       Layer X
			#   ^   ^   ^
			#
			# 1	-
			#	In addition to flag 0, each neuron in layer X is connected to every input of 
			#	the neurons ahead of itself in layer X.
			# 2 - ("L-U Style") - 
			#	No, its not "Learning-Unit" style. It gets its name from this: In a 2 layer, 3
			#	neuron network, the connections form a L-U pair, or a W, however you want to look
			#	at it.   
			#
			#   ^   ^   ^
			#	|	|	|
			#	O-->O-->O
			#   ^   ^   ^
			#	|	|   |
			#   |   |   |
			#	O-->O-->O
			#   ^   ^   ^
			#	|	|	|
			#
			#	As you can see, each neuron is connected to the next one in its layer, as well
			#	as the neuron directly above itself.
			
			for ($z=0; $z<$div; $z++) {
				if((!$flag) || ($flag == 1)) {
					for ($aa=0; $aa<$div; $aa++) {      
						$self->{NET}->[$y+$z]->connect($self->{NET}->[$y+$div+$aa]);
					}
				}
				if($flag == 1) {
					for ($aa=$z+1; $aa<$div; $aa++) {      
						$self->{NET}->[$y+$z]->connect($self->{NET}->[$y+$aa]);
					}
				}
				if($flag == 2) {
					$self->{NET}->[$y+$z]->connect($self->{NET}->[$y+$div+$z]);
					$self->{NET}->[$y+$z]->connect($self->{NET}->[$y+$z+1]) if($z<$div-1);
				}
				AI::NeuralNet::BackProp::out1 "\n";
			}
			AI::NeuralNet::BackProp::out1 "\n";             
		}
		
		# These next two loops connect the _run and _map packages (the IO interface) to 
		# the start and end 'layers', respectively. These are how we insert data into
		# the network and how we get data from the network. The _run and _map packages 
		# are connected to the neurons so that the neurons think that the IO packages are
		# just another neuron, sending data on. But the IO packs. are special packages designed
		# with the same methods as neurons, just meant for specific IO purposes. You will
		# never need to call any of the IO packs. directly. Instead, they are called whenever
		# you use the run(), map(), or learn() methods of your network.
        
    	AI::NeuralNet::BackProp::out2 "\nMapping I (_run package) connections to network...\n";
		
	    for($y=0; $y<$div; $y++) {
			$self->{_tmp_synapse} = $y;
			$self->{NET}->[$y]->register_synapse($self->{RUN});
			#$self->{NET}->[$y]->connect($self->{RUN});
		}
		
		AI::NeuralNet::BackProp::out2 "Mapping O (_map package) connections to network...\n\n";
		
		for($y=$size-$div; $y<$size; $y++) {
			$self->{_tmp_synapse} = $y;
			$self->{NET}->[$y]->connect($self->{MAP});
		}
		
		# And the group is done! 
	}
	

	# When called with an array refrence to a pattern, returns a refrence
	# to an array associated with that pattern. See usage in documentation.
	sub run {
		my $self	 =	  shift;
		my $map		 =	  shift;
		my $t0 		 =	new Benchmark;
        $self->{RUN}->run($map);
		$self->{LAST_TIME}=timestr(timediff(new Benchmark, $t0));
        return $self->map();
	}
    
    # This automatically uncrunches a response after running it
	sub run_uc {
    	$_[0]->uncrunch(run(@_));
    }

	# Returns benchmark and loop's ran or learned
	# for last run(), or learn()
	# operation preformed.
	#
	sub benchmarked {
		my $self	=	shift;
		return $self->{LAST_TIME};
	}
	    
	# Used to retrieve map from last internal run operation.
	sub map {
		my $self	 =	  shift;
		$self->{MAP}->map();
	}
	
	# Forces network to learn pattern passed and give desired
	# results. See usage in POD.
	sub learn {
		my $self	=	shift;
		my $omap	=	shift;
		my $res		=	shift;
		my %args    =   @_;
		my $inc 	=	$args{inc} || 0.20;
		my $max     =   $args{max} || 1024;
		my $_mx		=	intr($max/10);
		my $_mi		=	0;
		my $error   = 	($args{error}>-1 && defined $args{error}) ? $args{error} : -1;
  		my $div		=	$self->{DIV};
		my $size	=	$self->{SIZE};
		my $out		=	$self->{OUT};
		my $divide  =	AI::NeuralNet::BackProp->intr($div/$out);
		my ($a,$b,$y,$flag,$map,$loop,$diff,$pattern,$value);
		my ($t0,$it0);
		no strict 'refs';
		
		# Take care of crunching strings passed
		$omap = $self->crunch($omap) if($omap == 0);
		$res  = $self->crunch($res)  if($res  == 0);
		
		# Fill in empty spaces at end of results matrix with a 0
		if($#{$res}<$out) {
			for my $x ($#{$res}+1..$out) {
				#$res->[$x] = 0;
			}
		}
		
		# Debug
		AI::NeuralNet::BackProp::out1 "Num output neurons: $out, Input neurons: $size, Division: $divide\n";
		
		# Start benchmark timer and initalize a few variables
		$t0 	=	new Benchmark;
        $flag 	=	0; 
		$loop	=	0;   
		my $ldiff	=	0;
		my $dinc	=	0.0001;
		my $cdiff	=	0;
		$diff		=	100;
		$error 		= 	($error>-1)?$error:-1;
		
		# $flag only goes high when all neurons in output map compare exactly with
		# desired result map or $max loops is reached
		#	
		while(!$flag && ($max ? $loop<$max : 1)) {
			$it0 	=	new Benchmark;
			
			# Run the map
			$self->{RUN}->run($omap);
			
			# Retrieve last mapping  and initialize a few variables.
			$map	=	$self->map();
			$y		=	$size-$div;
			$flag	=	1;
			
			# Compare the result map we just ran with the desired result map.
			$diff 	=	pdiff($map,$res);
			
			# This adjusts the increment multiplier to decrease as the loops increase
			if($_mi > $_mx) {
				$dinc *= 0.1;
				$_mi   = 0;
			} 
			
			$_mi++;
				
			
			# We de-increment the loop ammount to prevent infinite learning loops.
			# In old versions of this module, if you used too high of an initial input
			# $inc, then the network would keep jumping back and forth over your desired 
			# results because the increment was too high...it would try to push close to
			# the desired result, only to fly over the other edge too far, therby trying
			# to come back, over shooting again. 
			# This simply adjusts the learning gradient proportionally to the ammount of
			# convergance left as the difference decreases.
           	$inc   -= ($dinc*$diff);
			$inc   = 0.0000000001 if($inc < 0.0000000001);
			
			# This prevents it from seeming to get stuck in one location
			# by attempting to boost the values out of the hole they seem to be in.
			if($diff eq $ldiff) {
				$cdiff++;
				$inc += ($dinc*$diff)+($dinc*$cdiff*10);
			} else {
				$cdiff=0;
			}
			
			# Save last $diff
			$ldiff = $diff;
			
			# This catches a max error argument and handles it
			if(!($error>-1 ? $diff>$error : 1)) {
				$flag=1;
				last;
			}
			
			# Debugging
			AI::NeuralNet::BackProp::out4 "Difference: $diff\%\t Increment: $inc\tMax Error: $error\%\n";
			AI::NeuralNet::BackProp::out1 "\n\nMapping results from $map:\n";
			
			# This loop compares each element of the output map with the desired result map.
			# If they don't match exactly, we call weight() on the offending output neuron 
			# and tell it what it should be aiming for, and then the offending neuron will
			# try to adjust the weights of its synapses to get closer to the desired output.
			# See comments in the weight() method of AI::NeuralNet::BackProp for how this works.
			my $l=$self->{NET};
			for my $i (0..$out-1) {
				$a = $map->[$i];
				$b = $res->[$i];
				
				AI::NeuralNet::BackProp::out1 "\nmap[$i] is $a\n";
				AI::NeuralNet::BackProp::out1 "res[$i] is $b\n";
					
				for my $j (0..$divide-1) {
					if($a!=$b) {
						AI::NeuralNet::BackProp::out1 "Punishing $self->{NET}->[($i*$divide)+$j] at ",(($i*$divide)+$j)," ($i with $a) by $inc.\n";
						$l->[$y+($i*$divide)+$j]->weight($inc,$b) if($l->[$y+($i*$divide)+$j]);
						$flag	=	0;
					}
				}
			}
			
			# This counter is just used in the benchmarking operations.
			$loop++;
			
			AI::NeuralNet::BackProp::out1 "\n\n";
			
			# Benchmark this loop.
			AI::NeuralNet::BackProp::out4 "Learning itetration $loop complete, timed at".timestr(timediff(new Benchmark, $it0),'noc','5.3f')."\n";
		
			# Map the results from this loop.
			AI::NeuralNet::BackProp::out4 "Map: \n";
			AI::NeuralNet::BackProp::join_cols($map,$self->{col_width}) if ($AI::NeuralNet::BackProp::DEBUG);
			AI::NeuralNet::BackProp::out4 "Res: \n";
			AI::NeuralNet::BackProp::join_cols($res,$self->{col_width}) if ($AI::NeuralNet::BackProp::DEBUG);
		}
		
		# Compile benchmarking info for entire learn() process and return it, save it, and
		# display it.
		$self->{LAST_TIME}="$loop loops and ".timestr(timediff(new Benchmark, $t0));
        my $str = "Learning took $loop loops and ".timestr(timediff(new Benchmark, $t0),'noc','5.3f');
        AI::NeuralNet::BackProp::out2 $str;
		return $str;
	}		
		
1;

# Internal input class. Not to be used directly.
package AI::NeuralNet::BackProp::_run;
	
	use strict;
	
	# Dummy constructor.
	sub new {
		bless { PARENT => $_[1] }, $_[0]
	}
	
	# This is so we comply with the neuron interface.
	sub weight {}
	sub input  {}
	
	# Again, compliance with neuron interface.
	sub register_synapse {
		my $self	=	shift;		
		my $sid		=	$self->{REGISTRATION} || 0;
		$self->{REGISTRATION}	=	++$sid;
		$self->{RMAP}->{$sid-1}	= 	$self->{PARENT}->{_tmp_synapse};
		return $sid-1;
	}
	
	# Here is the real meat of this package.
	# run() does one thing: It fires values
	# into the first layer of the network.
	sub run {
		my $self	=	shift;
		my $map		=	shift;
		my $x		=	0;
		$map = $self->{PARENT}->crunch($map) if($map == 0);
		return undef if(substr($map,0,5) ne "ARRAY");
		foreach my $el (@{$map}) {
			# Catch ourself if we try to run more inputs than neurons
			return $x if($x>$self->{PARENT}->{DIV}-1);
			
			# Here we add a small ammount of randomness to the network.
			# This is to keep the network from getting stuck on a 0 value internally.
			$self->{PARENT}->{NET}->[$x]->input(0,$el+(rand()*$self->{ramdom}));
			$x++;
		};
		# Incase we tried to run less inputs than neurons, run const 1 in extra neurons
		if($x<$self->{PARENT}->{DIV}) {
			for my $y ($x..$self->{PARENT}->{DIV}-1) {
				$self->{PARENT}->{NET}->[$y]->input(0,1);
			}
		}
		return $x;
	}
	
	
1;

# Internal output class. Not to be used directly.
package AI::NeuralNet::BackProp::_map;
	
	use strict;
	
	# Dummy constructor.
	sub new {
		bless { PARENT => $_[1] }, $_[0]
	}
	
	# Compliance with neuron interface
	sub weight {}
	
	# Compliance with neuron interface
	sub register_synapse {
		my $self	=	shift;		
		my $sid		=	$self->{REGISTRATION} || 0;
		$self->{REGISTRATION}	=	++$sid;
		$self->{RMAP}->{$sid-1} = 	$self->{PARENT}->{_tmp_synapse};
		return $sid-1;
	}
	
	# This acts just like a regular neuron by receiving
	# values from input synapes. Yet, unlike a regularr
	# neuron, it doesnt weight the values, just stores
	# them to be retrieved by a call to map().
	sub input  {
		no strict 'refs';             
		my $self	=	shift;
		my $sid		=	shift;
		my $value	=	shift;
		my $size	=	$self->{PARENT}->{DIV};
		my $flag	=	1;
		$self->{OUTPUT}->[$sid]->{VALUE}	=	$self->{PARENT}->intr($value);
		$self->{OUTPUT}->[$sid]->{FIRED}	=	1;
		
		AI::NeuralNet::BackProp::out1 "Received value $self->{OUTPUT}->[$sid]->{VALUE} and sid $sid, self $self.\n";
	}
	
	# Here we simply collect the value of every neuron connected to this
	# one from the layer below us and return an array ref to the final map..
	sub map {
		my $self	=	shift;
		my $size	=	$self->{PARENT}->{DIV};
		my $out		=	$self->{PARENT}->{OUT};
		my $divide  =	AI::NeuralNet::BackProp->intr($size/$out);
		my @map = ();
		my $value;
		AI::NeuralNet::BackProp::out1 "Num output neurons: $out, Input neurons: $size, Division: $divide\n";
		for(0..$out-1) {
			$value=0;
			for my $a (0..$divide-1) {
				$value += $self->{OUTPUT}->[($_*$divide)+$a]->{VALUE};
				AI::NeuralNet::BackProp::out1 "\$a is $a, index is ".(($_*$divide)+$a).", value is $self->{OUTPUT}->[($_*$divide)+$a]->{VALUE}\n";
			}
			$map[$_]	=	AI::NeuralNet::BackProp->intr($value/$divide);
			AI::NeuralNet::BackProp::out1 "Map position $_ is $map[$_] in @{[\@map]} with self set to $self.\n";
			$self->{OUTPUT}->[$_]->{FIRED}	=	0;
		}
		my $ret=\@map;
		return $self->{PARENT}->_range($ret);
	}
1;
			      
# load_pcx() wrapper package
package AI::NeuralNet::BackProp::PCX;

	# Called by load_pcx in AI::NeuralNet::BackProp;
	sub new {
		my $type	=	shift;
		my $self	=	{ 
			parent  => $_[0],
			file    => $_[1]
		};
		my (@a,@b)=load_pcx($_[1]);
		$self->{image}=\@a;
		$self->{palette}=\@b;
		bless \%{$self}, $type;
	}

	# Returns a rectangular block defined by an array ref in the form of
	# 		[$x1,$y1,$x2,$y2]
	# Return value is an array ref
	sub get_block {
		my $self	=	shift;
		my $ref		=	shift;
		my ($x1,$y1,$x2,$y2)	=	@{$ref};
		my @block	=	();
		my $count	=	0;
		for my $x ($x1..$x2-1) {
			for my $y ($y1..$y2-1) {
				$block[$count++]	=	$self->get($x,$y);
			}
		}
		return \@block;
	}
			
	# Returns pixel at $x,$y
	sub get {
		my $self	=	shift;
		my ($x,$y)  =	(shift,shift);
		return $self->{image}->[$y*320+$x];
	}
	
	# Returns array of (r,g,b) value from palette index passed
	sub rgb {
		my $self	=	shift;
		my $color	=	shift;
		return ($self->{palette}->[$color]->{red},$self->{palette}->[$color]->{green},$self->{palette}->[$color]->{blue});
	}
		
	# Returns mean of (rgb) value of palette index passed
	sub avg {
		my $self	=	shift;
		my $color	=	shift;
		return $self->{parent}->intr(($self->{palette}->[$color]->{red}+$self->{palette}->[$color]->{green}+$self->{palette}->[$color]->{blue})/3);
	}
	
	# Loads and decompresses a PCX-format 320x200, 8-bit image file and returns 
	# two arrays, first is a 64000-byte long array, each element contains a palette
	# index, and the second array is a 255-byte long array, each element is a hash
	# ref with the keys 'red', 'green', and 'blue', each key contains the respective color
	# component for that color index in the palette.
	sub load_pcx {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		
		# open the file
		open(FILE, "$_[0]");
		binmode(FILE);
		
		my $tmp;
		my @image;
		my @palette;
		my $data;
		
		# Read header
		read(FILE,$tmp,128);
		
		# load the data and decompress into buffer
		my $count=0;
		
		while($count<320*200) {
		     # get the first piece of data
		     read(FILE,$data,1);
	         $data=ord($data);
	         
		     # is this a rle?
		     if ($data>=192 && $data<=255) {
		        # how many bytes in run?
		        my $num_bytes = $data-192;
		
		        # get the actual $data for the run
		        read(FILE, $data, 1);
				$data=ord($data);
		        # replicate $data in buffer num_bytes times
		        while($num_bytes-->0) {
	            	$image[$count++] = $data;
		        } # end while
		     } else {
		        # actual $data, just copy it into buffer at next location
		        $image[$count++] = $data;
		     } # end else not rle
		}
		
		# move to end of file then back up 768 bytes i.e. to begining of palette
		seek(FILE,-768,2);
		
		# load the pallete into the palette
		for my $index (0..255) {
		    # get the red component
		    read(FILE,$tmp,1);
		    $palette[$index]->{red}   = ($tmp>>2);
		
		    # get the green component
		    read(FILE,$tmp,1);
			$palette[$index]->{green} = ($tmp>>2);
		
		    # get the blue component
		    read(FILE,$tmp,1);
			$palette[$index]->{blue}  = ($tmp>>2);
		
		}
		
		close(FILE);
		
		return @image,@palette;
	}

1;


__END__





=head1 NAME

AI::NeuralNet::BackProp - A simple back-prop neural net that uses Delta's and Hebbs' rule.

=head1 SYNOPSIS

use AI::NeuralNet::BackProp;
	
	# Create a new network with 1 layer, 5 inputs, and 5 outputs.
	my $net = new AI::NeuralNet::BackProp(1,5,5);
	
	# Add a small amount of randomness to the network
	$net->random(0.001);

	# Demonstrate a simple learn() call
	my @inputs = ( 0,0,1,1,1 );
	my @ouputs = ( 1,0,1,0,1 );
	
	print $net->learn(\@inputs, \@outputs),"\n";

	# Create a data set to learn
	my @set = (
		[ 2,2,3,4,1 ], [ 1,1,1,1,1 ],
		[ 1,1,1,1,1 ], [ 0,0,0,0,0 ],
		[ 1,1,1,0,0 ], [ 0,0,0,1,1 ]	
	);
	
	# Demo learn_set()
	my $f = $net->learn_set(\@set);
	print "Forgetfulness: $f unit\n";
	
	# Crunch a bunch of strings and return array refs
	my $phrase1 = $net->crunch("I love neural networks!");
	my $phrase2 = $net->crunch("Jay Lenno is wierd.");
	my $phrase3 = $net->crunch("The rain in spain...");
	my $phrase4 = $net->crunch("Tired of word crunching yet?");

	# Make a data set from the array refs
	my @phrases = (
		$phrase1, $phrase2,
		$phrase3, $phrase4
	);

	# Learn the data set	
	$net->learn_set(\@phrases);
	
	# Run a test phrase through the network
	my $test_phrase = $net->crunch("I love neural networking!");
	my $result = $net->run($test_phrase);
	
	# Get this, it prints "Jay Leno is  networking!" ...  LOL!
	print $net->uncrunch($result),"\n";



=head1 UPDATES

This is version 0.89. In this version I have included a new feature, output range limits, as
well as automatic crunching of run() and learn*() inputs. Included in the examples directory
are seven new practical-use example scripts. Also implemented in this version is a much cleaner 
learning function for individual neurons which is more accurate than previous verions and is 
based on the LMS rule. See range() for information on output range limits. I have also updated 
the load() and save() methods so that they do not depend on Storable anymore. In this version 
you also have the choice between three network topologies, two not as stable, and the third is 
the default which has been in use for the previous four versions.


=head1 DESCRIPTION

AI::NeuralNet::BackProp implements a nerual network similar to a feed-foward,
back-propagtion network; learning via a mix of a generalization
of the Delta rule and a disection of Hebbs rule. The actual 
neruons of the network are implemented via the AI::NeuralNet::BackProp::neuron package.
	
You constuct a new network via the new constructor:
	
	my $net = new AI::NeuralNet::BackProp(2,3,1);
		

The new() constructor accepts two arguments and one optional argument, $layers, $size, 
and $outputs is optional (in this example, $layers is 2, $size is 3, and $outputs is 1).

$layers specifies the number of layers, including the input
and the output layer, to use in each neural grouping. A new
neural grouping is created for each pattern learned. Layers
is typically set to 2. Each layer has $size neurons in it.
Each neuron's output is connected to one input of every neuron
in the layer below it. 
	
This diagram illustrates a simple network, created with a call
to "new AI::NeuralNet::BackProp(2,2,2)" (2 layers, 2 neurons/layer, 2 outputs).
	                             	
     input
     /  \
    O    O
    |\  /|
    | \/ |
    | /\ |
    |/  \|
    O    O
     \  /
    mapper

In this diagram, each neuron is connected to one input of every
neuron in the layer below it, but there are not connections
between neurons in the same layer. Weights of the connection
are controlled by the neuron it is connected to, not the connecting
neuron. (E.g. the connecting neuron has no idea how much weight
its output has when it sends it, it just sends its output and the
weighting is taken care of by the receiving neuron.) This is the 
method used to connect cells in every network built by this package.

Input is fed into the network via a call like this:

	use AI;
	my $net = new AI::NeuralNet::BackProp(2,2);
	
	my @map = (0,1);
	
	my $result = $net->run(\@map);
	

Now, this call would probably not give what you want, because
the network hasn't "learned" any patterns yet. But this
illustrates the call. Run now allows strings to be used as
input. See run() for more information.


Run returns a refrence with $size elements (Remember $size? $size
is what you passed as the second argument to the network
constructor.) This array contains the results of the mapping. If
you ran the example exactly as shown above, $result would probably 
contain (1,1) as its elements. 

To make the network learn a new pattern, you simply call the learn
method with a sample input and the desired result, both array
refrences of $size length. Example:

	use AI;
	my $net = new AI::NeuralNet::BackProp(2,2);
	
	my @map = (0,1);
	my @res = (1,0);
	
	$net->learn(\@map,\@res);
	
	my $result = $net->run(\@map);

Now $result will conain (1,0), effectivly flipping the input pattern
around. Obviously, the larger $size is, the longer it will take
to learn a pattern. Learn() returns a string in the form of

	Learning took X loops and X wallclock seconds (X.XXX usr + X.XXX sys = X.XXX CPU).

With the X's replaced by time or loop values for that loop call. So,
to view the learning stats for every learn call, you can just:
	
	print $net->learn(\@map,\@res);
	

If you call "$net->debug(4)" with $net being the 
refrence returned by the new() constructor, you will get benchmarking 
information for the learn function, as well as plenty of other information output. 
See notes on debug() in the METHODS section, below. 

If you do call $net->debug(1), it is a good 
idea to point STDIO of your script to a file, as a lot of information is output. I often
use this command line:

	$ perl some_script.pl > .out

Then I can simply go and use emacs or any other text editor and read the output at my leisure,
rather than have to wait or use some 'more' as it comes by on the screen.

=head2 METHODS

=over 4

=item new AI::NeuralNet::BackProp($layers, $size [, $outputs, $topology_flag])

Returns a newly created neural network from an C<AI::NeuralNet::BackProp>
object. The network will have C<$layers> number layers in it
and each layer will have C<$size> number of neurons in that layer.

There is an optional parameter of $outputs, which specifies the number
of output neurons to provide. If $outputs is not specified, $outputs
defaults to equal $size. $outputs may not exceed $size. If $outputs
exceeds $size, the new() constructor will return undef.

The optional parameter, $topology_flag, defaults to 0 when not used. There are
three valid topology flag values:

B<0> I<default>
My feed-foward style: Each neuron in layer X is connected to one input of every
neuron in layer Y. The best and most proven flag style.

	^   ^   ^               
	O\  O\ /O       Layer Y
	^\\/^/\/^
	| //|\/\|
	|/ \|/ \|		
	O   O   O       Layer X
	^   ^   ^


(Sorry about the bad art...I am no ASCII artist! :-)


B<1>
In addition to flag 0, each neuron in layer X is connected to every input of 
the neurons ahead of itself in layer X.

B<2> I<("L-U Style")>
No, its not "Learning-Unit" style. It gets its name from this: In a 2 layer, 3
neuron network, the connections form a L-U pair, or a W, however you want to look
at it.   


	^   ^   ^
	|   |   |
	O-->O-->O
	^   ^   ^
	|   |   |
	|   |   |
	O-->O-->O
	^   ^   ^
	|   |   |



As you can see, each neuron is connected to the next one in its layer, as well
as the neuron directly above itself.
	

Before you can really do anything useful with your new neural network
object, you need to teach it some patterns. See the learn() method, below.

=item $net->learn($input_map_ref, $desired_result_ref [, options ]);

This will 'teach' a network to associate an new input map with a desired resuly.
It will return a string containg benchmarking information. You can retrieve the
pattern index that the network stored the new input map in after learn() is complete
with the pattern() method, below.

UPDATED: You can now specify strings as inputs and ouputs to learn, and they will be crunched
automatically. Example:

	$net->learn('corn', 'cob');
	# Before update, you have had to do this:
	# $net->learn($net->crunch('corn'), $net->crunch('cob'));

Note, the old method of calling crunch on the values still works just as well.	

UPDATED: You can now learn inputs with a 0 value. Beware though, it may not learn() a 0 value 
in the input map if you have randomness disabled. See NOTES on using a 0 value with randomness
disabled.

The first two arguments may be array refs (or now, strings), and they may be of different lengths.

Options should be written on hash form. There are three options:
	 
	 inc	=>	$learning_gradient
	 max	=>	$maximum_iterations
	 error	=>	$maximum_allowable_percentage_of_error
	 

$learning_gradient is an optional value used to adjust the weights of the internal
connections. If $learning_gradient is ommitted, it defaults to 0.20.
 
$maximum_iterations is the maximum numbers of iteration the loop should do.
It defaults to 1024.  Set it to 0 if you never want the loop to quit before
the pattern is perfectly learned.

$maximum_allowable_percentage_of_error is the maximum allowable error to have. If 
this is set, then learn() will return when the perecentage difference between the
actual results and desired results falls below $maximum_allowable_percentage_of_error.
If you do not include 'error', or $maximum_allowable_percentage_of_error is set to -1,
then learn() will not return until it gets an exact match for the desired result OR it
reaches $maximum_iterations.


=item $net->learn_set(\@set, [ options ]);

UPDATE: Inputs and outputs in the dataset can now be strings. See information on auto-crunching
in learn()

This takes the same options as learn() and allows you to specify a set to learn, rather
than individual patterns. A dataset is an array refrence with at least two elements in the
array, each element being another array refrence (or now, a scalar string). For each pattern to
learn, you must specify an input array ref, and an ouput array ref as the next element. Example:
	
	my @set = (
		# inputs        outputs
		[ 1,2,3,4 ],  [ 1,3,5,6 ],
		[ 0,2,5,6 ],  [ 0,2,1,2 ]
	);


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

How the module measures forgetfulness is this: First, it learns all the patterns in the set provided,
then it will run the very first pattern (or whatever pattern is specified by the "row" option)
in the set after it has finished learning. It will compare the run() output with the desired output
as specified in the dataset. In a perfect world, the two should match exactly. What we measure is
how much that they don't match, thus the amount of forgetfulness the network has.

NOTE: In version 0.77 percentages were disabled because of a bug. Percentages are now enabled.

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
	my $f = learn_set(\@data, 
					  inc	=>	0.1,	
					  max	=>	500,
					  p		=>	1
					 );
			
	# Print it 
	print "Forgetfullness: $f%";

    
This is a snippet from the example script examples/ex_dow.pl, which demonstrates DOW average
prediction for the next month. A more simple set defenition would be as such:

	my @data = (
		[ 0,1 ], [ 1 ],
		[ 1,0 ], [ 0 ]
	);
	
	$net->learn_set(\@data);
	
Same effect as above, but not the same data (obviously).

=item $net->learn_set_rand(\@set, [ options ]);

UPDATE: Inputs and outputs in the dataset can now be strings. See information on auto-crunching
in learn()

This takes the same options as learn() and allows you to specify a set to learn, rather
than individual patterns. 

learn_set_rand() differs from learn_set() in that it learns the patterns in a random order,
each pattern once, rather than in the order that they are in the array. This returns a true
value (1) instead of a forgetfullnes factor.

Example:

	my @data = (
		[ 0,1 ], [ 1 ],
		[ 1,0 ], [ 0 ]
	);
	
	$net->learn_set_rand(\@data);
	


=item $net->run($input_map_ref);

UPDATE: run() will now I<automatically> crunch() a string given as the input.

This method will apply the given array ref at the input layer of the neural network, and
it will return an array ref to the output of the network.

Example:
	
	my $inputs  = [ 1,1,0,1 ];
	my $outputs = $net->run($inputs);

With the new update you can do this:

	my $outputs = $net->run('cloudy, wind is 5 MPH NW');
	# Old method:
	# my $outputs = $net->run($net->crunch('cloudy, wind is 5 MPH NW'));

See also run_uc() below.


=item $net->run_uc($input_map_ref);

This method does the same thing as this code:
	
	$net->uncrunch($net->run($input_map_ref));

All that run_uc() does is that it automatically calls uncrunch() on the output, regardless
of whether the input was crunch() -ed or not.
	


=item $net->range();

This allows you to limit the possible outputs to a specific set of values. There are several 
ways you can specify the set of values to limit the output to. Each method is shown below. 
When called without any arguements, it will disable output range limits. You will need to re-learn
any data previously learned after disabling ranging, as disabling range invalidates the current
weight matrix in the network.

range() automatically scales the networks outputs to fit inside the size of range you allow, and, therefore,
it keeps track of the maximum output it can expect to scale. Therefore, you will need to learn() 
the whole data set again after calling range() on a network.

Subsequent calls to range() invalidate any previous calls to range()

NOTE: It is recomended, you call range() before you call learn() or else you will get unexpected
results from any run() call after range() .


=item $net->range($bottom..$top);

This is a common form often used in a C<for my $x (0..20)> type of for() constructor. It works
the exact same way. It will allow all numbers from $bottom to $top, inclusive, to be given 
as outputs of the network. No other values will be possible, other than those between $bottom
and $top, inclusive.


=item $net->range(\@values);

This allows you to specify a range of values as an array refrence. As the ranges are stored internally
as a refrence, this is probably the most natural way. Any value specified by an element in @values
will be allows as an output, no other values will be allowed.


=item $net->range("string of values");

With this construct you can specify a string of values to be allowed as the outputs. This string
is simply taken an crunch() -ed internally and saved as an array ref. This has the same effect
as calling:

	$net->range($net->crunch("string of values"));


=item $net->range("first string","second string");

This is the same as calling:

	$net->range($net->crunch("first string"),$net->crunch("second string"));

Or:	

	@range = ($net->crunch("first string"),
			  $net->crunch("second string"));
	$net->range(\@range);


=item $net->range($value1,$value2);

This is the same as calling:

	$net->range([$value1,$value2]);

Or:
	
	@range = ($value1,$value2);
	$net->range(\@range);

The second example is the same as the first example.



=item $net->benchmarked();

UPDATE: bencmarked() now returns just the string from timestr() for the last run() or
loop() call. Exception: If the last call was a loop the string will be prefixed with "%d loops and ".

This returns a benchmark info string for the last learn() or the last run() call, 
whichever occured later. It is easily printed as a string,
as following:

	print $net->benchmarked() . "\n";





=item $net->debug($level)

Toggles debugging off if called with $level = 0 or no arguments. There are four levels
of debugging.

Level 0 ($level = 0) : Default, no debugging information printed. All printing is 
left to calling script.

Level 1 ($level = 1) : This causes ALL debugging information for the network to be dumped
as the network runs. In this mode, it is a good idea to pipe your STDIO to a file, especially
for large programs.

Level 2 ($level = 2) : A slightly-less verbose form of debugging, not as many internal 
data dumps.

Level 3 ($level = 3) : JUST prints weight mapping as weights change.

Level 4 ($level = 4) : JUST prints the benchmark info for EACH learn loop iteteration, not just
learning as a whole. Also prints the percentage difference for each loop between current network
results and desired results, as well as learning gradient ('incremenet').   

Level 4 is useful for seeing if you need to give a smaller learning incrememnt to learn() .
I used level 4 debugging quite often in creating the letters.pl example script and the small_1.pl
example script.

Toggles debuging off when called with no arguments. 



=item $net->save($filename);

This will save the complete state of the network to disk, including all weights and any
words crunched with crunch() . Also saves any output ranges set with range() .

This has now been modified to use a simple flat-file text storage format, and it does not
depend on any external modules now.



=item $net->load($filename);

This will load from disk any network saved by save() and completly restore the internal
state at the point it was save() was called at.




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



=item $net->pdiff($array_ref_A, $array_ref_B);

This function is used VERY heavily internally to calculate the difference in percent
between elements of the two array refs passed. It returns a %.10f (sprintf-format) 
percent sting.


=item $net->p($a,$b);

Returns a floating point number which represents $a as a percentage of $b.



=item $net->intr($float);

Rounds a floating-point number rounded to an integer using sprintf() and int() , Provides
better rounding than just calling int() on the float. Also used very heavily internally.



=item $net->high($array_ref);

Returns the index of the element in array REF passed with the highest comparative value.



=item $net->low($array_ref);

Returns the index of the element in array REF passed with the lowest comparative value.



=item $net->show();

This will dump a simple listing of all the weights of all the connections of every neuron
in the network to STDIO.




=item $net->crunch($string);

UPDATE: Now you can use a variabled instead of using qw(). Strings will be split internally.
Do not use qw() to pass strings to crunch.

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
uncrunch() the output of a run() call. Consider the below code (also in ./examples/ex_crunch.pl):
                           
	use AI::NeuralNet::BackProp;
	my $net = AI::NeuralNet::BackProp->new(2,3);
	
	for (0..3) {		# Note: The four learn() statements below could 
						# be replaced with learn_set() to do the same thing,
						# but use this form here for clarity.

		$net->learn($net->crunch("I love chips."),  $net->crunch("That's Junk Food!"));
		$net->learn($net->crunch("I love apples."), $net->crunch("Good, Healthy Food."));
		$net->learn($net->crunch("I love pop."),    $net->crunch("That's Junk Food!"));
		$net->learn($net->crunch("I love oranges."),$net->crunch("Good, Healthy Food."));
	}
	
	my $response = $net->run($net->crunch("I love corn."));
	
	print $net->uncrunch($response),"\n";


On my system, this responds with, "Good, Healthy Food." If you try to run crunch() with
"I love pop.", though, you will probably get "Food! apples. apples." (At least it returns
that on my system.) As you can see, the associations are not yet perfect, but it can make
for some interesting demos!



=item $net->crunched($word);

This will return undef if the word is not in the internal crunch list, or it will return the
index of the word if it exists in the crunch list. 


=item $net->col_width($width);

This is useful for formating the debugging output of Level 4 if you are learning simple 
bitmaps. This will set the debugger to automatically insert a line break after that many
elements in the map output when dumping the currently run map during a learn loop.

It will return the current width when called with a 0 or undef value.


=item $net->random($rand);

This will set the randomness factor from the network. Default is 0.001. When called 
with no arguments, or an undef value, it will return current randomness value. When
called with a 0 value, it will disable randomness in the network. See NOTES on learning 
a 0 value in the input map with randomness disabled.



=item $net->load_pcx($filename);

Oh heres a treat... this routine will load a PCX-format file (yah, I know ... ancient format ... but
it is the only one I could find specs for to write it in Perl. If anyone can get specs for
any other formats, or could write a loader for them, I would be very grateful!) Anyways, a PCX-format
file that is exactly 320x200 with 8 bits per pixel, with pure Perl. It returns a blessed refrence to 
a AI::NeuralNet::BackProp::PCX object, which supports the following routinges/members. See example 
files ex_pcxl.pl and ex_pcx.pl in the ./examples/ directory.



=item $pcx->{image}

This is an array refrence to the entire image. The array containes exactly 64000 elements, each
element contains a number corresponding into an index of the palette array, details below.



=item $pcx->{palette}

This is an array ref to an AoH (array of hashes). Each element has the following three keys:
	
	$pcx->{palette}->[0]->{red};
	$pcx->{palette}->[0]->{green};
	$pcx->{palette}->[0]->{blue};

Each is in the range of 0..63, corresponding to their named color component.



=item $pcx->get_block($array_ref);

Returns a rectangular block defined by an array ref in the form of:
	
	[$left,$top,$right,$bottom]

These must be in the range of 0..319 for $left and $right, and the range of 0..199 for
$top and $bottom. The block is returned as an array ref with horizontal lines in sequental order.
I.e. to get a pixel from [2,5] in the block, and $left-$right was 20, then the element in 
the array ref containing the contents of coordinates [2,5] would be found by [5*20+2] ($y*$width+$x).
    
	print (@{$pcx->get_block(0,0,20,50)})[5*20+2];

This would print the contents of the element at block coords [2,5].



=item $pcx->get($x,$y);

Returns the value of pixel at image coordinates $x,$y.
$x must be in the range of 0..319 and $y must be in the range of 0..199.



=item $pcx->rgb($index);

Returns a 3-element array (not array ref) with each element corresponding to the red, green, or
blue color components, respecitvely.



=item $pcx->avg($index);	

Returns the mean value of the red, green, and blue values at the palette index in $index.
	


=head1 NOTES

=item Learning 0s With Randomness Disabled

You can now use 0 values in any input maps. This is a good improvement over versions 0.40
and 0.42, where no 0s were allowed because the learning would never finish learning completly
with a 0 in the input. 

Yet with the allowance of 0s, it requires one of two factors to learn correctly. Either you
must enable randomness with $net->random(0.0001) (Any values work [other than 0], see random() ), 
or you must set an error-minimum with the 'error => 5' option (you can use some other error value 
as well). 

When randomness is enabled (that is, when you call random() with a value other than 0), it interjects
a bit of randomness into the output of every neuron in the network, except for the input and output
neurons. The randomness is interjected with rand()*$rand, where $rand is the value that was
passed to random() call. This assures the network that it will never have a pure 0 internally. It is
bad to have a pure 0 internally because the weights cannot change a 0 when multiplied by a 0, the
product stays a 0. Yet when a weight is multiplied by 0.00001, eventually with enough weight, it will
be able to learn. With a 0 value instead of 0.00001 or whatever, then it would never be able
to add enough weight to get anything other than a 0. 

The second option to allow for 0s is to enable a maximum error with the 'error' option in
learn() , learn_set() , and learn_set_rand() . This allows the network to not worry about
learning an output perfectly. 

For accuracy reasons, it is recomended that you work with 0s using the random() method.

If anyone has any thoughts/arguments/suggestions for using 0s in the network, let me know
at jdb@wcoil.com. 




=head1 OTHER INCLUDED PACKAGES

=item AI::NeuralNet::BackProp::neuron

AI::NeuralNet::BackProp::neuron is the worker package for AI::NeuralNet::BackProp.
It implements the actual neurons of the nerual network.
AI::NeuralNet::BackProp::neuron is not designed to be created directly, as
it is used internally by AI::NeuralNet::BackProp.

=item AI::NeuralNet::BackProp::_run

=item AI::NeuralNet::BackProp::_map

These two packages, _run and _map are used to insert data into
the network and used to get data from the network. The _run and _map packages 
are connected to the neurons so that the neurons think that the IO packages are
just another neuron, sending data on. But the IO packs. are special packages designed
with the same methods as neurons, just meant for specific IO purposes. You will
never need to call any of the IO packs. directly. Instead, they are called whenever
you use the run() or learn() methods of your network.
        



=head1 BUGS

This is an alpha release of C<AI::NeuralNet::BackProp>, and that holding true, I am sure 
there are probably bugs in here which I just have not found yet. If you find bugs in this module, I would 
appreciate it greatly if you could report them to me at F<E<lt>jdb@wcoil.comE<gt>>,
or, even better, try to patch them yourself and figure out why the bug is being buggy, and
send me the patched code, again at F<E<lt>jdb@wcoil.comE<gt>>. 



=head1 AUTHOR

Josiah Bryan F<E<lt>jdb@wcoil.comE<gt>>

Copyright (c) 2000 Josiah Bryan. All rights reserved. This program is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself.

The C<AI::NeuralNet::BackProp> and related modules are free software. THEY COME WITHOUT WARRANTY OF ANY KIND.

                                                             




=head1 THANKS

Below is a list of people that have helped, made suggestions, patches, etc. No particular order.

		Tobias Bronx, tobiasb@odin.funcom.com
		Pat Trainor, ptrainor@title14.com
		Steve Purkis, spurkis@epn.nu
		Rodin Porrata, rodin@ursa.llnl.gov
		Daniel Macks dmacks@sas.upenn.edu

Tobias was a great help with the initial releases, and helped with learning options and a great
many helpful suggestions. Rodin has gave me some great ideas for the new internals, as well
as disabling Storable. Steve is the author of AI::Perceptron, and gave some good suggestions for 
weighting the neurons. Daniel was a great help with early beta testing of the module and related 
ideas. Pat has been a great help for running the module through the works. Pat is the author of 
the new Inter game, a in-depth strategy game. He is using a group of neural networks internally 
which provides a good test bed for coming up with new ideas for the network. Thankyou for all of
your help, everybody.


=head1 DOWNLOAD

You can always download the latest copy of AI::NeuralNet::BackProp
from http://www.josiah.countystart.com/modules/AI/cgi-bin/rec.pl


=head1 MAILING LIST

A mailing list has been setup for AI::NeuralNet::BackProp for discussion of AI and 
neural net related topics as they pertain to AI::NeuralNet::BackProp. I will also 
announce in the group each time a new release of AI::NeuralNet::BackProp is available.

The list address is at: ai-neuralnet-backprop@egroups.com 

To subscribe, send a blank email to: ai-neuralnet-backprop-subscribe@egroups.com  


=cut
