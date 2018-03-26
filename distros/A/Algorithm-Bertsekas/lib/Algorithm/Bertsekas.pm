package Algorithm::Bertsekas;

use strict;
use warnings FATAL => 'all';
use diagnostics;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( auction );
our $VERSION = '0.31';

#Variables global to the package	
my $maximize_total_benefit;
my $matrix_spaces;     # used to print messages on the screen
my $decimals;          # the number of digits after the decimal point
my $max_matrix_value;
my $need_transpose = 0;
my $inicial_price;
my $iter_count_global = 0;
my $iter_count_local  = 0;
my ( $array1_size, $array2_size, $min_size, $max_size, $original_max_size );
my ( %assignned_object, %assignned_person, %objects_desired_by_this, %price_object );
my %index_correlation;

sub auction { #                        => default values
	my %args = ( matrix_ref            => undef,     # reference to array: matrix N x M			                                     
				maximize_total_benefit => 0,         # 0: minimize_total_benefit ; 1: maximize_total_benefit
				inicial_stepsize       => undef,     # auction algorithm terminates with a feasible assignment if the problem data are integer and stepsize < 1/min(N,M)				
				inicial_price          => 0,
				verbose                => 3,         # level of verbosity, 0: quiet; 1, 2, 3, 4, 9, 10: debug information.				
				@_,                                  # argument pair list goes here
				);
       
	my @matrix_input = @{$args{matrix_ref}};         # Input: Reference to the input matrix (NxM) = $min_size x $max_size
   
	$array1_size = $#matrix_input + 1;
	$array2_size = $#{$matrix_input[0]} + 1;
 
	$min_size = $array1_size < $array2_size ? $array1_size : $array2_size ; # square matrix --> $min_size = $max_size and $array1_size = $array2_size
	$max_size = $array1_size < $array2_size ? $array2_size : $array1_size ;
	$original_max_size = $max_size;
   
	$maximize_total_benefit = $args{maximize_total_benefit};
   
	my $optimal_benefit = 0;
	my %assignement_hash;  # assignement: a hash representing edges in the mapping, as in the Algorithm::Kuhn::Munkres.
	my @output_index;      # output_index: an array giving the number of the value assigned, as in the Algorithm::Munkres.
   
	my @matrix;
	my @matrix_index;
	foreach ( @matrix_input ){ # copy the orginal matrix N x M
		push @matrix, [ @$_ ];
	}

	if ( $max_size <= 1 ){ # matrix_input 1 x 1
		$assignement_hash{0} = 0;
		$output_index[0] = 0;
		$matrix_index[0] = 0;	
		$optimal_benefit = $matrix_input[0]->[0];
	}

	$need_transpose = 1 if ( $array1_size > $array2_size ); # will always be chosen N <= M
   
	if ( $need_transpose ){
		my $transposed = transpose(\@matrix);
		@matrix = @$transposed;
	}
   
	get_matrix_info( \@matrix, $args{verbose} );
   
	delete_multiple_columns( \@matrix, $args{verbose} ) if ( $min_size >= 2 and $min_size != $max_size );
     
	# epsilon is the stepsize and auction algorithm terminates with a feasible assignment if the problem data are integer and epsilon < 1/min(N,M).
	# There is a trade-off between runtime and the chosen stepsize. Using the largest possible increment accelerates the algorithm.
   
	$inicial_price    = $args{inicial_price};
	$price_object{$_} = $inicial_price for ( 0 .. $max_size - 1 );
   
	# inicial epsilon value
	my $epsilon = ($max_matrix_value/2) * exp ( -1 * $max_size/$min_size );  # exp (1) = e = 2.71828182845905
	   $epsilon = $args{inicial_stepsize} if ( defined $args{inicial_stepsize} );
	   $epsilon = 1/(1+$min_size) if ($epsilon < 1/$min_size);
    
	my ( @assignment, @prices );
	my $feasible_assignment_condition = 0;

	# The preceding observations suggest the idea of epsilon-scaling, which consists of applying the algorithm several times, 
	# starting with a large value of epsilon and successively reducing epsilon until it is less than some critical value.
   
	while( $epsilon >= 1/(1+$min_size) and $max_size >= 2 ){
   
		%assignned_object = ();
		%assignned_person = ();
		$iter_count_local = 0;

		while ( (scalar keys %assignned_person) < $max_size ){ # while there is at least one element not assigned.
         
			$iter_count_global++;
			$iter_count_local++;		
			auctionRound( \@matrix, $epsilon, $args{verbose} );
		 
			if ( $args{verbose} >= 10 ){
				@assignment = ();
				@prices = ();
				foreach my $per ( sort { $a <=> $b } keys %assignned_person){ push @assignment, $assignned_person{$per}; }
				foreach my $obj ( sort { $a <=> $b } keys %price_object    ){ push @prices, $price_object{$obj}; }
				my $assig_count = scalar @assignment;
				print "\n *** \$iter_count_global = $iter_count_global ; \$assig_count = $assig_count ; \$epsilon = $epsilon ; \@assignment = (@assignment) ; \@prices = (@prices) \n\n";
			
				for my $i ( -1 .. $#matrix ) {
					if ($i >= 0){ printf " %2s  [", $i; } else{ printf "object"; }
					for my $j ( 0 .. $#{$matrix[$i]} ) {
						if ($i >= 0){ printf(" %${matrix_spaces}.${decimals}f", $matrix[$i]->[$j]); } else{ printf(" %${matrix_spaces}.0f", $j); }
						if ( defined $assignned_person{$i} and $j == $assignned_person{$i} ){ print "**"; } else{ print "  "; }
					}
					if ($i >= 0){ print "]\n"; } else{ print "\n\n"; }
				}
			}		 
		}
		
		$epsilon = $epsilon / 4 ; # (1/2): smooth convergence	  
	  
		if ( not $feasible_assignment_condition and $epsilon < 1/$min_size ){
			$epsilon = 1/(1+$min_size);
			$feasible_assignment_condition = 1;
		}
	}
	$epsilon = 4 * $epsilon; # correcting information for printing

	my %seeN;
	my %seeM;
	foreach my $person ( sort { $a <=> $b } keys %assignned_person ){
	  
		my $object = $assignned_person{$person};

		$matrix_index[$person] = $object;	  	 	  
		#print " \$need_transpose = $need_transpose ; \$matrix_index[$person] = $object ; \$index_i = $person ; \$index_j = $object --> $index_correlation{$object} ;";
	  
		my $index_i = $need_transpose ? $index_correlation{$object} // $object : $person;
		my $index_j = $need_transpose ? $person : $index_correlation{$object} // $object;

		$output_index[$index_i] = $index_j; 
		$seeN{$index_i}++;
		$seeM{$index_j}++;
		#print " \$output_index[$index_i] = $index_j \n"; 	  
	  
		next unless ( defined $matrix_input[$index_i] and defined $matrix_input[$index_i]->[$index_j] );
		$assignement_hash{ $index_i } = $index_j;	  
		$optimal_benefit += $matrix_input[$index_i]->[$index_j];
	}

	for my $i ( 0 .. $original_max_size - 1 ) {
	for my $j ( 0 .. $original_max_size - 1 ) {
      next if ($seeN{$i} or $seeM{$j});  
      $output_index[$i] = $j;
	  $seeN{$i}++;
	  $seeM{$j}++;
	  last;
	}}   
   
	if ( $args{verbose} >= 10 ){
		printf "\n\$optimal_benefit = $optimal_benefit ; \$iter_count_global = $iter_count_global ; \$epsilon = %.4g ; \@output_index = (@output_index) ; \@assignment = (@assignment) ; \@prices = (@prices) \n", $epsilon; 
	}   
	print_screen_messages( \@matrix, \@matrix_index, \@matrix_input, \@output_index, $optimal_benefit, $args{verbose}, $epsilon ) ;
       
	return ( $optimal_benefit, \%assignement_hash, \@output_index ) ;
}

sub transpose {
	my $matrix_ref = shift;
	my @transpose;

	for my $i ( 0 .. $#{$matrix_ref} ) {
		for my $j ( 0 .. $#{$matrix_ref->[$i]} ) {
			$transpose[$j]->[$i] = $matrix_ref->[$i]->[$j];
		}
	}   
	return \@transpose;
}

sub delete_multiple_columns { # if the column elements do not change the final result
   my ( $matrix_ref, $verbose ) = @_;
   my %lower_values;
   my %intersection_columns;
   my $number_of_columns_deleted = 0;	  
   
   for my $i ( 0 .. $#{$matrix_ref} ) {
      for my $j ( 0 .. $#{$matrix_ref->[$i]} ) {
	     $lower_values{ $i }{ $matrix_ref->[$i]->[$j] }{ $j }++;
      }
   } 
   
   # consider N rows < M columns
   # remove the matching columns whose elements are never among the N largest elements in each row
   
   foreach my $index_i ( sort { $a <=> $b } keys %lower_values ){
      my $num_higher_values = 0;
      foreach my $matrix_value ( sort { $b <=> $a } keys %{$lower_values{$index_i}} ){
	     foreach my $index_j ( sort { $b <=> $a } keys %{$lower_values{$index_i}{$matrix_value}} ){	     
		    $intersection_columns{$index_j}++ if ( $num_higher_values++ >= $min_size );
			$number_of_columns_deleted++ if ( defined $intersection_columns{$index_j} and $intersection_columns{$index_j} >= $min_size );
		 }
	  }
   }

   if ( $verbose >= 7 ){
      print "\n";
      for my $i ( 0 .. $#{$matrix_ref} ) {
         print " [";
         for my $j ( 0 .. $#{$matrix_ref->[$i]} ) {
            printf(" %2.0f", $matrix_ref->[$i]->[$j] );
			if ( defined $intersection_columns{$j} and $intersection_columns{$j} == $min_size ){ print "**"; } else{ print "  "; }
         }
         print "]\n";
      }
	  print "\n";
   }	  

   my $idx = 0;  
   for my $i ( 0 .. $#{$matrix_ref} ) {
      for my $j ( 0 .. $#{$matrix_ref->[$i]} ) {
	     undef ( $matrix_ref->[$i]->[$j] ) if ( defined $intersection_columns{$j} and $intersection_columns{$j} >= $min_size );
		 if ( $i == 0 and defined $intersection_columns{$j} and $intersection_columns{$j} >= $min_size ){
		    printf " N = $min_size ; M = $max_size ; j = %2s ; \$intersection_columns{$j} = $intersection_columns{$j} \n", $j if ( $verbose >= 7 );
		 }
		 if ( $i == 0 and ( not defined $intersection_columns{$j} or $intersection_columns{$j} < $min_size ) ){
		    $index_correlation{$idx} = $j;
		    printf " N = $min_size ; M = $max_size ; j = %2s ; \$index_correlation{$idx} = $index_correlation{$idx} \n", $j if ( $verbose >= 7 );
			$idx++;
		 }
      }
   }
   
   for my $i ( 0 .. $#{$matrix_ref} ) {
      @{$matrix_ref->[$i]} = grep { defined($_) } @{$matrix_ref->[$i]};
   }
  
   if ( $verbose >= 7 ){
      print "\n";
      for my $i ( 0 .. $#{$matrix_ref} ) {
         print " [";
         for my $j ( 0 .. $#{$matrix_ref->[$i]} ) {
            printf(" %2.0f  ", $matrix_ref->[$i]->[$j] );
         }
         print "]\n";
      }
	  print "\n";
   }
   
   $max_size = $max_size - $number_of_columns_deleted;
}

sub print_screen_messages {

   my ( $matrix_ref, $matrix_index_ref, $matrix_input_ref, $output_index_ref, $optimal_benefit, $verbose, $epsilon ) = @_;
   my @matrix = @$matrix_ref;
   my @matrix_index = @$matrix_index_ref;
   my @matrix_input = @$matrix_input_ref;
   my @output_index = @$output_index_ref;
   
   if ( $verbose >= 1 ){
      
      print "\nObjective: ";
      printf( $maximize_total_benefit ? "to Maximize the total benefit\n" : "to Minimize the total benefit\n" );
      printf(" Number of left nodes: %u\n",  $array1_size );
      printf(" Number of right nodes: %u\n", $array2_size );
      printf(" Number of edges: %u\n", $array1_size * $array2_size ); 
	  
	  print "\nSolution:\n";	  
	  printf(" Optimal assignment: sum of values = %.${decimals}f \n", $optimal_benefit );	  
	  printf(" Feasible assignment condition: stepsize = %.4g < 1/$min_size = %.4g \n", $epsilon, 1/$min_size ) if ( $verbose >= 1 and $max_size >= 2 );
	  printf(" Number of iterations: %u \n", $iter_count_global ) if ( $verbose >= 1 );
   
      print "\n row index    = [";
      for my $i ( 0 .. $#output_index ) {
         printf("%${matrix_spaces}d ", $i);
      }
      print "]\n";

      print " column index = [";
      for my $index (@output_index) {
         printf("%${matrix_spaces}d ", $index);
      }
      print "]\n";
	  
      print " matrix value = [";
	  
      for my $i ( 0 .. $#output_index ){
         my $j = $output_index[$i];
		 last if not defined $j;
		 my $weight;
		    $weight = ( defined $matrix_input[$i] and defined $matrix_input[$i]->[$j] ) ? sprintf( "%${matrix_spaces}.${decimals}f ", $matrix_input[$i]->[$j] ) : ' ' x ($matrix_spaces+1) ;	 
		 
         print $weight;
      }
      print "]\n\n";
   }
   
   if ( $verbose >= 2 ){
   
      my $index_length = length($original_max_size);   

	  if ( $verbose >= 4 ){
      printf " modified matrix %d x %d:\n", $#matrix + 1, $#{$matrix[0]} + 1;	  
      for my $i ( 0 .. $#matrix ) {
         print " [";
         for my $j ( 0 .. $#{$matrix[$i]} ) {
            printf(" %${matrix_spaces}.${decimals}f", $matrix[$i]->[$j] );
            if ( $j == $matrix_index[$i] ){ print "**"; } else{ print "  "; }
         }
         print "]\n";
      }
	  print "\n";
	  }
	  
	  print " original matrix $array1_size x $array2_size with solution:\n";

      for my $i ( 0 .. $#matrix_input ) {
         print " [";
         for my $j ( 0 .. $#{$matrix_input[$i]} ) {
            printf(" %${matrix_spaces}.${decimals}f", $matrix_input[$i]->[$j] );			
			if ( $j == $output_index[$i] ){ print "**"; } else{ print "  "; }		
         }
         print "]\n";
      }
	  
      my %orderly_solution;
      for my $i ( 0 .. $original_max_size - 1 ){
         my $j = $output_index[$i];
         my $weight = $max_matrix_value;
         $weight = $matrix_input[$i]->[$j] if ( defined $matrix_input[$i] and defined $matrix_input[$i]->[$j] ); # condition for valid solution
         
         $orderly_solution{ $weight } { $i } { 'index_array1' } = $i;
         $orderly_solution{ $weight } { $i } { 'index_array2' } = $j;		 
      }

      print "\n Pairs (in ascending order of matrix values):\n"; 

      my $sum_matrix_value = 0;
      foreach my $matrix_value ( sort { $a <=> $b }  keys %orderly_solution ){
      foreach my $k ( sort { $a <=> $b } keys %{$orderly_solution{$matrix_value}} ){
     
	     my $index_array1 = $orderly_solution{ $matrix_value } { $k } { 'index_array1' };
         my $index_array2 = $orderly_solution{ $matrix_value } { $k } { 'index_array2' };
	  
	     $sum_matrix_value += $matrix_value if ( defined $matrix_input[$index_array1] and defined $matrix_input[$index_array1]->[$index_array2] );
	  
	     my $weight = ( defined $matrix_input[$index_array1] and defined $matrix_input[$index_array1]->[$index_array2] ) ? sprintf( "%${matrix_spaces}.${decimals}f", $matrix_value ) : ' ' x $matrix_spaces ;
	  
         printf( "   indices ( %${index_length}d, %${index_length}d ), matrix value = $weight ; sum of values = %${matrix_spaces}.${decimals}f \n", $index_array1, $index_array2, $sum_matrix_value );
      }}	  
   }

}

sub get_matrix_info {
   my ( $matrix_ref, $verbose ) = @_;
   my @matrix = @$matrix_ref;
   my $min_matrix_value;
   
   for my $i ( 0 .. $#matrix ) {
   for my $j ( 0 .. $#{$matrix[$i]} ) {
      
	  my $char_number = length( $matrix[$i]->[$j] ); # count the number of characters
      $matrix_spaces = $char_number if ( (not defined $matrix_spaces) || ($char_number > $matrix_spaces) );
	  
      $max_matrix_value = $matrix[$i]->[$j] if ( (not defined $max_matrix_value) || ($matrix[$i]->[$j] > $max_matrix_value) );	  
	  $min_matrix_value = $matrix[$i]->[$j] if ( (not defined $min_matrix_value) || ($matrix[$i]->[$j] < $min_matrix_value) );
   }}
   
   $decimals = length(($max_matrix_value =~ /[,.](\d+)/)[0]); # counting the number of digits after the decimal point
   $decimals = 0 unless ( defined $decimals );                # for integers $decimals = 0
   
   my $range = $max_matrix_value - $min_matrix_value;         # $range >= 0
      $range = 1 if ($range == 0);
   
   if ( $verbose >= 6 ){
      print "\n min_matrix_value = $min_matrix_value ; max_matrix_value = $max_matrix_value ; range = $range ; matrix_spaces = $matrix_spaces ; decimals = $decimals \n";
   }
   
   if ( $maximize_total_benefit ){

      for my $i ( 0 .. $#matrix ) {
      for my $j ( 0 .. $#{$matrix[$i]} ) {
	     
		 $matrix[$i]->[$j] = $matrix[$i]->[$j] - $min_matrix_value ;
		 
	     #$matrix[$i]->[$j] = 99 * ( $matrix[$i]->[$j] - $min_matrix_value ) / $range; # new scale: Min = 0 <---> Max = 99

      }}   
 	  
   } else {

      for my $i ( 0 .. $#matrix ) {
      for my $j ( 0 .. $#{$matrix[$i]} ) {   
	     
		 $matrix[$i]->[$j] = $max_matrix_value - $matrix[$i]->[$j] ;
		 
		 #$matrix[$i]->[$j] = 99 * ( $max_matrix_value - $matrix[$i]->[$j] ) / $range;
      }}	  
   }
}

sub auctionRound {
	my ( $matrix_ref, $epsilon, $verbose ) = @_;
	my @matrix = @$matrix_ref;
	my %info;

	if ( $verbose >= 10 ){
		print "\n Start: Matrix Size N x M: $min_size x $max_size ; Num Iterations: $iter_count_global ; iter_count_local = $iter_count_local ; epsilon: $epsilon \n";
		foreach my $person ( sort { $a <=> $b } keys %assignned_person ){
			my $object = $assignned_person{$person};
			printf " \$assignned_person{%2s} --> object %2s --> \$price_object{%2s} = $price_object{$object} \n", $person, $object, $object;
		}
		foreach my $object ( sort { $a <=> $b } keys %price_object ){
			printf " \$price_object{%2s} = $price_object{$object} \n", $object;
		}
		print "\n";
	}
   
	my $seen_ghost;

	for my $person ( 0 .. $max_size - 1 )
	{		
		last if $seen_ghost; # don't need to fill the matrix with zeros, that is, don't need to convert rectangular N x M to square matrix by padding zeroes. Need just one more row: N+1 x M
		
		if ( not defined $assignned_person{$person} )
		{		
			##     ------> j          object 0   object 1   object 2   object 3 ...  object (M - 1)
			##  |  person 0          price_0_0  price_0_1  price_0_2  price_0_3      price_0_j
			##  |  person 1          price_1_0
			##  |  person 2          price_2_0
			##  |  ...
			##  i  person (N - 1)    price_i_0	
			
			my ( $optObjForPersonI, $SecOptObjForPersonI, $ThdOptObjForPersonI, $FthOptObjForPersonI );			
			my ( $optValForPersonI, $SecOptValForPersonI, $ThdOptValForPersonI, $FthOptValForPersonI ) = ( -1 * $max_matrix_value, -1 * $max_matrix_value, -1 * $max_matrix_value, -1 * $max_matrix_value );
            
			# "The set of objects to which each person i has been assigned in the last few assignments does not change much as the algorithm proceeds."
			# Each person is assigned to just a relatively small number of objects during the execution of the auctionRound.
			# My implementation is different from Libor Bus and Pavel Tvrdik: 'Towards auction algorithms for large dense assignment problems' (see reference 2).
			# My working sets @objects_with_greater_benefits are updated dynamically by %objects_desired_by_this hash.
			
			my @objects_with_greater_benefits = keys %{$objects_desired_by_this{$person}};
			my @not_assignned_objects = grep { not defined $assignned_object{$_} } @objects_with_greater_benefits;
			
			for my $object ( @not_assignned_objects > 1 ? @objects_with_greater_benefits : ( 0 .. $max_size - 1 ) )		
			#for my $object ( 0 .. $max_size - 1 )			
			{				
				$seen_ghost++ if ( not defined $matrix[$person] and $min_size < $max_size );
				
				my $matrix_value = $seen_ghost ? 0 : $matrix[$person]->[$object] ;
				
				my $curVal = $matrix_value - $price_object{$object};
				
				if ( $curVal > $optValForPersonI )
				{					
					$FthOptValForPersonI = $ThdOptValForPersonI;
					$FthOptObjForPersonI = $ThdOptObjForPersonI;
					$ThdOptValForPersonI = $SecOptValForPersonI;
					$ThdOptObjForPersonI = $SecOptObjForPersonI;
					$SecOptValForPersonI = $optValForPersonI;
					$SecOptObjForPersonI = $optObjForPersonI;
					$optValForPersonI = $curVal;
					$optObjForPersonI = $object;
				}
				elsif ( $curVal > $SecOptValForPersonI )
				{
					$FthOptValForPersonI = $ThdOptValForPersonI;
					$FthOptObjForPersonI = $ThdOptObjForPersonI;
					$ThdOptValForPersonI = $SecOptValForPersonI;
					$ThdOptObjForPersonI = $SecOptObjForPersonI;
					$SecOptValForPersonI = $curVal;
					$SecOptObjForPersonI = $object;
				}
				elsif ( $curVal > $ThdOptValForPersonI )
				{
					$FthOptValForPersonI = $ThdOptValForPersonI;
					$FthOptObjForPersonI = $ThdOptObjForPersonI;
					$ThdOptValForPersonI = $curVal;
					$ThdOptObjForPersonI = $object;
				}
				elsif ( $curVal > $FthOptValForPersonI )
				{
					$FthOptValForPersonI = $curVal;
					$FthOptObjForPersonI = $object;
				}
				
				if ( $verbose >= 10 ){
					printf " personI = %2s ; objectJ = %2s ; \$curVal %10.5f = \$matrix[%2s][%2s] %2.0f - \$price_object{%2s} %10.5f \n", $person, $object, $curVal, $person, $object, $matrix_value, $object, $price_object{$object};
				}				
			}
			
			my $bidForPersonI = $optValForPersonI - $SecOptValForPersonI + $epsilon;
			
			# Stores the bidding info for future use
			$info{$optObjForPersonI}{$bidForPersonI} = $person if ( not defined $info{$optObjForPersonI}{$bidForPersonI} ); # get only one person with this bid
			
			$objects_desired_by_this{$person}{$optObjForPersonI}    = 1; # information about the most desired objects
			$objects_desired_by_this{$person}{$SecOptObjForPersonI} = 1 if (defined $SecOptObjForPersonI);
			$objects_desired_by_this{$person}{$ThdOptObjForPersonI} = 1 if (defined $ThdOptObjForPersonI);
			$objects_desired_by_this{$person}{$FthOptObjForPersonI} = 1 if (defined $FthOptObjForPersonI);			
			
			if ( $verbose >= 10 ){
				my @array = sort { $a <=> $b } keys %{$objects_desired_by_this{$person}};				
				printf "<> PersonI = %2s ; \@objects_with_greater_benefits = (@objects_with_greater_benefits) ; object eligible to bid --> \@not_assignned_objects = (@not_assignned_objects) : %2s > 1 ? \n", $person, scalar @not_assignned_objects;
				printf "<> PersonI = %2s ; objects desired by this person = (@array) \n", $person;
				printf "<> PersonI = %2s chose ObjectJ = %2s ; \$bidForPersonI %.5f = \$optValForPersonI %.5f - \$SecOptValForPersonI %.5f + \$epsilon %.5f \n", $person, $optObjForPersonI, $bidForPersonI, $optValForPersonI, $SecOptValForPersonI, $epsilon;							    								
			}
		}
	}	
	
	foreach my $object ( keys %info ){                                 # for each object, choose only the first bid.
	foreach my $bid    ( sort { $b <=> $a } keys %{$info{$object}} ){  # descending order!!! --> the first bid is the highest bid.
	
		my $person       = $info{$object}{$bid};
		my $other_person = $assignned_object{$object}; # Find the other person who has objectJ and make them unassigned
	   	   	   
		if ( defined $other_person ) {
		  
			if ( $verbose >= 10 ){
				print " ***--> PersonI $person was assigned objectJ $object. Before that, remove the objectJ $object from personI $other_person  --> delete \$assignned_person{$other_person} \n";
			}
		  
			# The other person that was assigned to objectJ at the beginning of the iteration (if any) 
			# is now left without an object (and becomes eligible to bid at the next iteration).
	   
			delete $assignned_person{$other_person};
		}
	   
		# Each objectJ that receives one or more bids, determines the highest of these bids, increases the price_j 
		# to the highest bid, and gets assigned to the personI who submitted the highest bid.
	   
		$assignned_person{$person} = $object;
		$assignned_object{$object} = $person;
	   
		$price_object{$object} += $bid;	
	   
		if ( $verbose >= 10 ){
			printf " --> Assigning to personI = %2s the objectJ = %2s with highestBidForJ = %10.5f and update the price vector ; \$assignned_person{%2s} = %2s ; \$price_object{%2s} = %.5f \n", $person, $object, $bid, $person, $assignned_person{$person}, $object, $price_object{$object};	
		}
	   
		last;  # next object, choose only the highest bid for each object
	}}

	if ( $verbose >= 10 ){
		print "\n Final: Matrix Size N x M: $min_size x $max_size ; Num Iterations: $iter_count_global ; iter_count_local = $iter_count_local ; epsilon: $epsilon \n";
		foreach my $person ( sort { $a <=> $b } keys %assignned_person ){
			my $object = $assignned_person{$person};
			printf " \$assignned_person{%2s} --> object %2s --> \$price_object{%2s} = $price_object{$object} \n", $person, $object, $object;
		}
		foreach my $object ( sort { $a <=> $b } keys %price_object ){
			printf " \$price_object{%2s} = $price_object{$object} \n", $object;
		}
		print "\n";
	}

}

1;  # don't forget to return a true value from the file

__END__

=head1 NAME

	Algorithm::Bertsekas - auction algorithm for the assignment problem.
	
	This is a perl implementation for the auction algorithm for the asymmetric (N<=M) assignment problem.

=head1 DESCRIPTION
 
 The assignment problem in the general form can be stated as follows:

 "Given N jobs (or persons), M tasks (or objects) and the effectiveness of each job for each task, 
 the problem is to assign each job to one and only one task in such a way that the measure of 
 effectiveness is optimised (Maximised or Minimised)."
 
 "Each assignment problem has associated with a table or matrix. Generally, the rows contain the 
 jobs (or persons) we wish to assign, and the columns comprise the tasks (or objects) we want them 
 assigned to. The numbers in the table are the costs associated with each particular assignment."
 
 In Auction Algorithm (AA) the N persons iteratively submit the bids to M objects.
 The AA take cost Matrix N×M = [aij] as an input and produce assignment as an output.
 In the AA persons iteratively submit the bids to the objects which are then reassigned 
 to the bidders which offer them the best bid.
 
 Another application is to find the (nearest/more distant) neighbors. 
 The distance between neighbors can be represented by a matrix or a weight function, for example:
 1: f(i,j) = abs ($array1[i] - $array2[j])
 2: f(i,j) = ($array1[i] - $array2[j]) ** 2
 

=head1 SYNOPSIS

 use Algorithm::Bertsekas qw(auction);
 
 Example 1: Minimize the total benefit.
 my @array1 = ( 22, 15, 98,  1 );
 my @array2 = ( 72, 99, 29, 88, 12, 26, 41 );

 my @input_matrix;
 for my $i ( 0 .. $#array1 ){
   my @weight_function;		   
   for my $j ( 0 .. $#array2 ){
      my $weight = abs ($array1[$i] - $array2[$j]);
      #  $weight =     ($array1[$i] - $array2[$j]) ** 2;  # another option
      push @weight_function, $weight;
   }
   push @input_matrix, \@weight_function;
 }

      72 99 29 88 12 26 41

 22 [ 50 77  7 66 10  4 19 ]
 15 [ 57 84 14 73  3 11 26 ]
 98 [ 26  1 69 10 86 72 57 ]
  1 [ 71 98 28 87 11 25 40 ]
  
 my ( $optimal, $assignement_ref, $output_index_ref ) = auction( matrix_ref => \@input_matrix, maximize_total_benefit => 0, verbose => 5 );
  
 Objective: to Minimize the total benefit
 Number of left nodes: 4
 Number of right nodes: 7
 Number of edges: 28

 Solution:
 Optimal assignment: sum of values = 30
 Feasible assignment condition: stepsize = 0.2 < 1/4 = 0.25
 Number of iterations: 15

 row index    = [ 0  1  2  3  4  5  6 ]
 column index = [ 2  5  1  4  0  6  3 ]
 matrix value = [ 7 11  1 11          ]

 modified matrix 4 x 7:
 [ 48   21   91** 32   88   94   79  ]
 [ 41   14   84   25   95   87** 72  ]
 [ 72   97** 29   88   12   26   41  ]
 [ 27    0   70   11   87** 73   58  ]

 original matrix 4 x 7 with solution:
 [ 50   77    7** 66   10    4   19  ]
 [ 57   84   14   73    3   11** 26  ]
 [ 26    1** 69   10   86   72   57  ]
 [ 71   98   28   87   11** 25   40  ]

 Pairs (in ascending order of matrix values):
   indices ( 2, 1 ), matrix value =  1 ; sum of values =  1
   indices ( 0, 2 ), matrix value =  7 ; sum of values =  8
   indices ( 1, 5 ), matrix value = 11 ; sum of values = 19
   indices ( 3, 4 ), matrix value = 11 ; sum of values = 30
   indices ( 4, 0 ), matrix value =    ; sum of values = 30
   indices ( 5, 6 ), matrix value =    ; sum of values = 30
   indices ( 6, 3 ), matrix value =    ; sum of values = 30  
  
 Example 2: Maximize the total benefit.
 Alternatively, we can define the matrix with its elements:
 
 my $N = 10;
 my $M = 10;
 my $r = 100;
 
 my @input_matrix;
 for my $i ( 0 .. $N - 1 ){
   my @weight_function;		   
   for my $j ( 0 .. $M - 1 ){
	  my $weight = sprintf( "%.0f", rand($r) );
      push @weight_function, $weight;
   }
   push @input_matrix, \@weight_function;
 }

 my @input_matrix = ( 
 [  84,  94,  75,  56,  66,  95,  39,  53,  73,   4 ],
 [  76,  71,  56,  49,  29,   1,  40,  40,  72,  72 ],
 [  85, 100,  71,  23,  47,  18,  82,  70,  30,  71 ],
 [   2,  95,  71,  89,  73,  73,  48,  52,  90,  51 ],
 [  65,  28,  77,  73,  24,  28,  75,  48,   8,  81 ],
 [  25,  27,  35,  89,  98,  10,  99,   3,  27,   4 ],
 [  58,  15,  99,  37,  92,  55,  52,  82,  73,  96 ],
 [  11,  75,   2,   1,  88,  43,   8,  28,  98,  20 ],
 [  52,  95,  10,  38,  41,  64,  20,  75,   1,  47 ],
 [  50,  80,  31,  90,  10,  83,  51,  55,  57,  40 ]
 );

 my ( $optimal, $assignement_ref, $output_index_ref ) = auction( matrix_ref => \@input_matrix, maximize_total_benefit => 1, verbose => 3 );

 Objective: to Maximize the total benefit
 Number of left nodes: 10
 Number of right nodes: 10
 Number of edges: 100

 Solution:
 Optimal assignment: sum of values = 893
 Feasible assignment condition: stepsize = 0.09091 < 1/10 = 0.1
 Number of iterations: 27

 row index    = [  0   1   2   3   4   5   6   7   8   9 ]
 column index = [  5   0   1   8   9   6   2   4   7   3 ]
 matrix value = [ 95  76 100  90  81  99  99  88  75  90 ]

 original matrix 10 x 10 with solution:
 [  84    94    75    56    66    95**  39    53    73     4  ]
 [  76**  71    56    49    29     1    40    40    72    72  ]
 [  85   100**  71    23    47    18    82    70    30    71  ]
 [   2    95    71    89    73    73    48    52    90**  51  ]
 [  65    28    77    73    24    28    75    48     8    81**]
 [  25    27    35    89    98    10    99**   3    27     4  ]
 [  58    15    99**  37    92    55    52    82    73    96  ]
 [  11    75     2     1    88**  43     8    28    98    20  ]
 [  52    95    10    38    41    64    20    75**   1    47  ]
 [  50    80    31    90**  10    83    51    55    57    40  ]

 Pairs (in ascending order of matrix values):
   indices (  8,  7 ), matrix value =  75 ; sum of values =  75
   indices (  1,  0 ), matrix value =  76 ; sum of values = 151
   indices (  4,  9 ), matrix value =  81 ; sum of values = 232
   indices (  7,  4 ), matrix value =  88 ; sum of values = 320
   indices (  3,  8 ), matrix value =  90 ; sum of values = 410
   indices (  9,  3 ), matrix value =  90 ; sum of values = 500
   indices (  0,  5 ), matrix value =  95 ; sum of values = 595
   indices (  5,  6 ), matrix value =  99 ; sum of values = 694
   indices (  6,  2 ), matrix value =  99 ; sum of values = 793
   indices (  2,  1 ), matrix value = 100 ; sum of values = 893

 Common use of the solution:
   
 foreach my $i ( sort { $a <=> $b } keys %{$assignement_ref} ){     
   my $j = $assignement_ref->{$i};   
   ...
 }
 
 my $sum = 0;
 for my $i ( 0 .. $#{$output_index_ref} ){
	my $j = $output_index_ref->[$i];   
	my $value = $input_matrix[$i]->[$j];  
	$sum += $value;
	printf " Auction Algorithm, output index --> \$i = %3d ; \$j = %3d ; \$value = %5s ; \$sum = %5s \n", $i, $j, $value, $sum;
 }
 
=head1 OPTIONS
 
 matrix_ref => \@input_matrix,   reference to array: matrix N x M.
 maximize_total_benefit => 0,    0: minimize the total benefit ; 1: maximize the total benefit.
 inicial_stepsize       => 1,    auction algorithm terminates with a feasible assignment if the problem data are integer and stepsize < 1/min(N,M).
 inicial_price          => 0,			
 verbose                => 3,    print messages on the screen, level of verbosity, 0: quiet; 1, 2, 3, 4, 9, 10: debug information.

=head1 EXPORT

    "auction" function by default.

=head1 INPUT

    The input matrix should be in a two dimensional array (array of array) 
	and the 'auction' subroutine expects a reference to this array.

=head1 OUTPUT

    The $output_index_ref is the reference to the output_index array.
	The $assignement_ref  is the reference to the assignement hash.
	The $optimal is the total benefit which can be a minimum or maximum value.
	

=head1 SEE ALSO
  
	1. Network Optimization: Continuous and Discrete Models (1998).
	   Dimitri P. Bertsekas
	   http://web.mit.edu/dimitrib/www/netbook_Full_Book.pdf
	   
	2. Towards auction algorithms for large dense assignment problems (2008).
	   Libor Bus and Pavel Tvrdik
	   https://pdfs.semanticscholar.org/b759/b8fb205df73c810b483b5be2b1ded62309b4.pdf
	
	3. https://github.com/EvanOman/AuctionAlgorithmCPP/blob/master/auction.cpp
	   This Perl algorithm started from this C++ implementation.
	      
	4. https://en.wikipedia.org/wiki/Assignment_problem
	
	5. https://en.wikipedia.org/wiki/Auction_algorithm


=head1 AUTHOR

    Claudio Fernandes de Souza Rodrigues
	March 25, 2018
	Sao Paulo, Brasil
	claudiofsr@yahoo.com
	
=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2018 Claudio Fernandes de Souza Rodrigues.  All rights reserved.

 This program is free software; you can redistribute it and/or modify
 it under the same terms as Perl itself.

=cut