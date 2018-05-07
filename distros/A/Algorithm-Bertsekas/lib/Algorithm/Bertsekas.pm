package Algorithm::Bertsekas;

use strict;
use warnings FATAL => 'all';
use diagnostics;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( auction );
our $VERSION = '0.84';

#Variables global to the package	
my $maximize_total_benefit;
my $matrix_spaces;     # used to print messages on the screen
my $decimals;          # the number of digits after the decimal point
my ( $array1_size, $array2_size, $min_size, $max_size, $original_max_size );
my ( $need_transpose, $inicial_price, $iter_count_global, $iter_count_local );
my ( $epsilon_scaling, $max_epsilon_scaling, $max_matrix_value, $target, $output );
my ( %index_correlation, %assignned_object, %assignned_person, %price_object );
my ( %objects_desired_by_this, %locked_list, %seen_person );

sub auction { #						=> default values
	my %args = ( matrix_ref				=> undef,     # reference to array: matrix N x M			                                     
				maximize_total_benefit  => 0,         # 0: minimize_total_benefit ; 1: maximize_total_benefit
				inicial_stepsize        => undef,     # auction algorithm terminates with a feasible assignment if the problem data are integer and stepsize < 1/min(N,M)				
				inicial_price           => 0,
				verbose                 => 3,         # level of verbosity, 0: quiet; 1, 2, 3, 4, 5, 8, 9, 10: debug information.
				@_,                                   # argument pair list goes here
				);
       
	$max_matrix_value = 0;
	$iter_count_global = 0;
	$epsilon_scaling = 0;
	$need_transpose = 0;
	%index_correlation = ();
	%assignned_object = ();
	%assignned_person = ();
	%price_object = ();
	%objects_desired_by_this = ();
	%locked_list = ();
	%seen_person = ();
	
	my @matrix_input = @{$args{matrix_ref}};          # Input: Reference to the input matrix (NxM) = $min_size x $max_size
   
	$array1_size = $#matrix_input + 1;
	$array2_size = $#{$matrix_input[0]} + 1;
 
	$min_size = $array1_size < $array2_size ? $array1_size : $array2_size ; # square matrix --> $min_size = $max_size and $array1_size = $array2_size
	$max_size = $array1_size < $array2_size ? $array2_size : $array1_size ;
	$original_max_size = $max_size;

	$target = 'auction-' . $array1_size . 'x' . $array2_size . '-output.txt' ;
	
	if ( $args{verbose} >= 8 ){ # print the verbose messages to $output file.
		print "\n verbose = $args{verbose} ---> print the verbose messages to <$target> file \n";
		if ( open ( $output, '>', $target ) ) {
			print "\n *** Open <$target> for writing. *** \n";
		} else {
			$args{verbose} = 7;
			warn "\n *** Could not open <$target> for writing: $! *** \n";			
		}
	}	
   
	$maximize_total_benefit = $args{maximize_total_benefit};
   
	my $optimal_benefit = 0;
	my %assignment_hash;   # assignment: a hash representing edges in the mapping, as in the Algorithm::Kuhn::Munkres.
	my @output_index;      # output_index: an array giving the number of the value assigned, as in the Algorithm::Munkres.
   
	my @matrix;
	my @matrix_index;
	foreach ( @matrix_input ){ # copy the orginal matrix N x M
		push @matrix, [ @$_ ];
	}

	if ( $max_size <= 1 ){ # matrix_input 1 x 1
		$assignment_hash{0} = 0;
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
	#$price_object{$_} = sprintf( "%.0f", rand($max_matrix_value) ) for ( 0 .. $max_size - 1 ); # random values for initial prices	
	
	# inicial epsilon value
	my $epsilon = int (($max_matrix_value/2) * exp ( -1 * $max_size/$min_size ));  # exp (1) = e = 2.71828182845905
	   $epsilon = $args{inicial_stepsize} if ( defined $args{inicial_stepsize} );
	   $epsilon = 1/(1+$min_size) if ($epsilon < 1/$min_size);
	   
	# (inicial epsilon value) / factor ** k = 1/$min_size --> epsilon * $min_size  = factor ** k
	# log(epsilon * $min_size)  = k * log(factor) --> log(factor) = (log(epsilon * $min_size)) / k --> factor = exp ( (log(epsilon * $min_size)) / k )
	
	#$max_epsilon_scaling = 20;
	#my $factor = exp ( (log( $epsilon * (1+$min_size) )) / ($max_epsilon_scaling-1) ); print "\n \$max_epsilon_scaling = $max_epsilon_scaling ; \$factor = $factor \n";
	
	my $factor = 4;
	$max_epsilon_scaling = 2 + int( log( (1+$min_size) * $epsilon )/log($factor) ); # print "\n \$max_epsilon_scaling = $max_epsilon_scaling \n";   
    
	my ( @assignment, @prices );
	my $feasible_assignment_condition = 0;

	# The preceding observations suggest the idea of epsilon-scaling, which consists of applying the algorithm several times, 
	# starting with a large value of epsilon and successively reducing epsilon until it is less than some critical value.
   
	while( $epsilon >= 1/(1+$min_size) and $max_size >= 2 ){
   
		$epsilon_scaling++;
		$iter_count_local = 0;
		
		%assignned_object = ();
		%assignned_person = ();
		%seen_person = ();		

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
				print $output " *** \$iter_count_global = $iter_count_global ; \$assig_count = $assig_count ; \$epsilon = $epsilon ; \@assignment = (@assignment) ; \@prices = (@prices) \n\n";
			
				for my $i ( -1 .. $#matrix ) {
					if ($i >= 0){ printf $output " %2s  [", $i; } else{ printf $output "object"; }
					for my $j ( 0 .. $#{$matrix[$i]} ) {
						if ($i >= 0){ printf $output (" %${matrix_spaces}.${decimals}f", $matrix[$i]->[$j]); } else{ printf $output (" %${matrix_spaces}.0f", $j); }
						if ( defined $assignned_person{$i} and $j == $assignned_person{$i} ){ print $output "**"; } else{ print $output "  "; }
					}
					if ($i >= 0){ print $output "]\n"; } else{ print $output "\n\n"; }
				}		
			}			
		}
		
		$epsilon = $epsilon / $factor ; # (1/2): smooth convergence	  
	  
		if ( not $feasible_assignment_condition and $epsilon < 1/$min_size ){
			$epsilon = 1/(1+$min_size);
			$feasible_assignment_condition = 1;
		}
	}
	$epsilon = $factor * $epsilon; # correcting information for printing

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
		$assignment_hash{ $index_i } = $index_j;	  
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
   
	if ( $args{verbose} >= 8 ){
		printf $output "\n\$optimal_benefit = $optimal_benefit ; \$iter_count_global = $iter_count_global ; \$epsilon = %.4g ; \@output_index = (@output_index) ; \@assignment = (@assignment) ; \@prices = (@prices) \n", $epsilon; 
	}   
	print_screen_messages( \@matrix, \@matrix_index, \@matrix_input, \@output_index, $optimal_benefit, $args{verbose}, $epsilon ) ;
       
	return ( $optimal_benefit, \%assignment_hash, \@output_index ) ;
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

   if ( $verbose >= 5 ){
      print "\n";
      for my $i ( 0 .. $#{$matrix_ref} ) {
         print " [";
         for my $j ( 0 .. $#{$matrix_ref->[$i]} ) {
            printf (" %${matrix_spaces}.${decimals}f", $matrix_ref->[$i]->[$j] );
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
		    printf " N = $min_size ; M = $max_size ; j = %2s ; \$intersection_columns{$j} = $intersection_columns{$j} \n", $j if ( $verbose >= 5 );
		 }
		 if ( $i == 0 and ( not defined $intersection_columns{$j} or $intersection_columns{$j} < $min_size ) ){
			$index_correlation{$idx} = $j;
			printf " N = $min_size ; M = $max_size ; j = %2s ; \$index_correlation{$idx} = $index_correlation{$idx} \n", $j if ( $verbose >= 5 );
			$idx++;
		 }
      }
   }
   
	for my $i ( 0 .. $#{$matrix_ref} ) {
		@{$matrix_ref->[$i]} = grep { defined($_) } @{$matrix_ref->[$i]};
	}
  
	if ( $verbose >= 5 ){
		print "\n";
		for my $i ( 0 .. $#{$matrix_ref} ) {
			print " [";
			for my $j ( 0 .. $#{$matrix_ref->[$i]} ) {
				printf (" %${matrix_spaces}.${decimals}f  ", $matrix_ref->[$i]->[$j] );
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

	  if ( $verbose >= 3 ){
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
	  my $sum_spaces = 2 * $matrix_spaces - 1;
      foreach my $matrix_value ( sort { $a <=> $b }  keys %orderly_solution ){
      foreach my $k ( sort { $a <=> $b } keys %{$orderly_solution{$matrix_value}} ){
     
		my $index_array1 = $orderly_solution{ $matrix_value } { $k } { 'index_array1' };
		my $index_array2 = $orderly_solution{ $matrix_value } { $k } { 'index_array2' };
	  
		$sum_matrix_value += $matrix_value if ( defined $matrix_input[$index_array1] and defined $matrix_input[$index_array1]->[$index_array2] );
	  
		my $weight = ( defined $matrix_input[$index_array1] and defined $matrix_input[$index_array1]->[$index_array2] ) ? sprintf( "%${matrix_spaces}.${decimals}f", $matrix_value ) : ' ' x $matrix_spaces ;
	  
		printf( "   indices ( %${index_length}d, %${index_length}d ), matrix value = $weight ; sum of values = %${sum_spaces}.${decimals}f \n", $index_array1, $index_array2, $sum_matrix_value );
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
   
   if ( $verbose >= 4 ){
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
		 
		#$matrix[$i]->[$j] = 99 * ( $max_matrix_value - $matrix[$i]->[$j] ) / $range; # new scale: Min = 0 <---> Max = 99
      }}	  
   }
}

sub auctionRound {
	my ( $matrix_ref, $epsilon, $verbose ) = @_;
	my @matrix = @$matrix_ref;
	my %this_person_can_choose_n_different_objects;
	my %choose_object;
	my %info;
	my %seen_object;
	my %count_object;

	if ( $verbose >= 8 ){
		print $output "\n Start: Matrix Size N x M: $min_size x $max_size ; Num Iterations: $iter_count_global ; epsilon_scaling = $epsilon_scaling ; iter_count_local = $iter_count_local ; epsilon: $epsilon \n";
		foreach my $person ( sort { $a <=> $b } keys %assignned_person ){
			my $object = $assignned_person{$person};
			printf $output " \$assignned_person{%3s} --> object %3s --> \$price_object{%3s} = $price_object{$object} \n", $person, $object, $object;
		}
		foreach my $object ( sort { $a <=> $b } keys %price_object ){
			printf $output " \$price_object{%3s} = $price_object{$object} \n", $object;
		}
		print $output "\n";
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

			my ( $Opt01ObjForPersonI, $Opt02ObjForPersonI, $Opt03ObjForPersonI );
			my ( $Opt01ValForPersonI, $Opt02ValForPersonI, $Opt03ValForPersonI ) = ( -10 * exp ($max_matrix_value), -10 * exp ($max_matrix_value), -10 * exp ($max_matrix_value) );
			
			my ( $Opt01ObjForPersonI_new_list, $Opt02ObjForPersonI_new_list, $Opt03ObjForPersonI_new_list );
			my ( $Opt01ValForPersonI_new_list, $Opt02ValForPersonI_new_list, $Opt03ValForPersonI_new_list ) = ( -10 * exp ($max_matrix_value), -10 * exp ($max_matrix_value), -10 * exp ($max_matrix_value) );

			my $Opt01ValForPersonI_old_list;
			my $bidForPersonI;
			my %current_value;			
			my @updated_price;			
			
			$seen_ghost++ if ( not defined $matrix[$person] and $min_size < $max_size );						

			# The @objects_with_greater_benefits list are updated dynamically by $objects_desired_by_this{$person} by considering the current price (or current value) of objects.		
			# For each person, the Current Value $current_value{$object} of the most desired objects contained in the @objects_with_greater_benefits list tends to converge to a specific value.
			
			my @objects_with_greater_benefits = keys %{$objects_desired_by_this{$person}}; # sort { $a <=> $b }
			
			# There is at least one object in the @objects_with_greater_benefits list whose price is updated ? use old list : generate new list;
			
			for my $object ( @objects_with_greater_benefits )  # use old list	
			{				
				my $matrix_value = $seen_ghost ? 0 : $matrix[$person]->[$object];
				$current_value{$object} = $matrix_value - $price_object{$object};
				
				push @updated_price, $object if ( $objects_desired_by_this{$person}{$object} == $current_value{$object} );				
				
				if ( $current_value{$object} > $Opt01ValForPersonI ) # search for the best 3 objects
				{
					$Opt03ValForPersonI = $Opt02ValForPersonI;
					$Opt03ObjForPersonI = $Opt02ObjForPersonI;
					$Opt02ValForPersonI = $Opt01ValForPersonI;
					$Opt02ObjForPersonI = $Opt01ObjForPersonI;
					$Opt01ValForPersonI = $current_value{$object};
					$Opt01ObjForPersonI = $object;
					
					$Opt01ValForPersonI_old_list = $Opt01ValForPersonI;
				}
				elsif ( $current_value{$object} > $Opt02ValForPersonI )
				{
					$Opt03ValForPersonI = $Opt02ValForPersonI;
					$Opt03ObjForPersonI = $Opt02ObjForPersonI;
					$Opt02ValForPersonI = $current_value{$object};
					$Opt02ObjForPersonI = $object;
				}
				elsif ( $current_value{$object} > $Opt03ValForPersonI )
				{
					$Opt03ValForPersonI = $current_value{$object};
					$Opt03ObjForPersonI = $object;
				}								
				
				if ( $verbose >= 8 ){
					printf $output " personI = %3s ; objectJ = %3s ; Current Value %20.5f = \$matrix[%3s][%3s] %3.0f - \$price_object{%3s} %10.5f <old list> Max01_CurVal = %12.5f (%3s), Max02_CurVal = %12.5f (%3s), Max03_CurVal = %12.5f (%3s)\n", 
					$person, $object, $current_value{$object}, $person, $object, $matrix_value, $object, $price_object{$object}, 
					$Opt01ValForPersonI, defined $Opt01ObjForPersonI ? $Opt01ObjForPersonI : '', 
					$Opt02ValForPersonI, defined $Opt02ObjForPersonI ? $Opt02ObjForPersonI : '', 
					$Opt03ValForPersonI, defined $Opt03ObjForPersonI ? $Opt03ObjForPersonI : '';
				}
			}
			
			if ( not @updated_price and not $locked_list{$person} ) # if all prices are outdated
			{
				for my $object ( 0 .. $max_size - 1 ) # generate new list
				{
					next if ( defined $current_value{$object} );
					
					my $matrix_value = $seen_ghost ? 0 : $matrix[$person]->[$object];				
					$current_value{$object} = $matrix_value - $price_object{$object};						
				
					if ( $current_value{$object} > $Opt01ValForPersonI_new_list ) # to find the best 3 objects in the complementary subset <new list>
					{
						$Opt03ValForPersonI_new_list = $Opt02ValForPersonI_new_list;
						$Opt03ObjForPersonI_new_list = $Opt02ObjForPersonI_new_list;
						$Opt02ValForPersonI_new_list = $Opt01ValForPersonI_new_list;
						$Opt02ObjForPersonI_new_list = $Opt01ObjForPersonI_new_list;
						$Opt01ValForPersonI_new_list = $current_value{$object};
						$Opt01ObjForPersonI_new_list = $object;
					}
					elsif ( $current_value{$object} > $Opt02ValForPersonI_new_list )
					{
						$Opt03ValForPersonI_new_list = $Opt02ValForPersonI_new_list;
						$Opt03ObjForPersonI_new_list = $Opt02ObjForPersonI_new_list;
						$Opt02ValForPersonI_new_list = $current_value{$object};
						$Opt02ObjForPersonI_new_list = $object;
					}
					elsif ( $current_value{$object} > $Opt03ValForPersonI_new_list )
					{
						$Opt03ValForPersonI_new_list = $current_value{$object};
						$Opt03ObjForPersonI_new_list = $object;
					}

					if ( $verbose >= 8 ){
						printf $output " personI = %3s ; objectJ = %3s ; Current Value %20.5f = \$matrix[%3s][%3s] %3.0f - \$price_object{%3s} %10.5f <new list> Max01_CurVal = %12.5f (%3s), Max02_CurVal = %12.5f (%3s), Max03_CurVal = %12.5f (%3s)\n", 
						$person, $object, $current_value{$object}, $person, $object, $matrix_value, $object, $price_object{$object}, 
						$Opt01ValForPersonI_new_list, defined $Opt01ObjForPersonI_new_list ? $Opt01ObjForPersonI_new_list : '', 
						$Opt02ValForPersonI_new_list, defined $Opt02ObjForPersonI_new_list ? $Opt02ObjForPersonI_new_list : '', 
						$Opt03ValForPersonI_new_list, defined $Opt03ObjForPersonI_new_list ? $Opt03ObjForPersonI_new_list : '';
					}				
				}			
				
				# to find the best 3 out of 6 objects

				if ( $Opt01ValForPersonI_new_list > $Opt01ValForPersonI )
				{
					$Opt03ValForPersonI = $Opt02ValForPersonI;
					$Opt03ObjForPersonI = $Opt02ObjForPersonI;
					$Opt02ValForPersonI = $Opt01ValForPersonI;
					$Opt02ObjForPersonI = $Opt01ObjForPersonI;
					$Opt01ValForPersonI = $Opt01ValForPersonI_new_list;
					$Opt01ObjForPersonI = $Opt01ObjForPersonI_new_list;
				}
				elsif ( $Opt01ValForPersonI_new_list > $Opt02ValForPersonI )
				{
					$Opt03ValForPersonI = $Opt02ValForPersonI;
					$Opt03ObjForPersonI = $Opt02ObjForPersonI;
					$Opt02ValForPersonI = $Opt01ValForPersonI_new_list;
					$Opt02ObjForPersonI = $Opt01ObjForPersonI_new_list;
				}
				elsif ( $Opt01ValForPersonI_new_list > $Opt03ValForPersonI )
				{
					$Opt03ValForPersonI = $Opt01ValForPersonI_new_list;
					$Opt03ObjForPersonI = $Opt01ObjForPersonI_new_list;
				}
 
				if ( $Opt02ValForPersonI_new_list > $Opt02ValForPersonI )
				{
					$Opt03ValForPersonI = $Opt02ValForPersonI;
					$Opt03ObjForPersonI = $Opt02ObjForPersonI;
					$Opt02ValForPersonI = $Opt02ValForPersonI_new_list;
					$Opt02ObjForPersonI = $Opt02ObjForPersonI_new_list;
				}
				elsif ( $Opt02ValForPersonI_new_list > $Opt03ValForPersonI )
				{
					$Opt03ValForPersonI = $Opt02ValForPersonI_new_list;
					$Opt03ObjForPersonI = $Opt02ObjForPersonI_new_list;
				}

				if ( $Opt03ValForPersonI_new_list > $Opt03ValForPersonI )
				{
					$Opt03ValForPersonI = $Opt03ValForPersonI_new_list;
					$Opt03ObjForPersonI = $Opt03ObjForPersonI_new_list;
				}				

			}
			
			$bidForPersonI = $Opt01ValForPersonI - $Opt02ValForPersonI + $epsilon;
			
			my @objects_with_same_values;
			
			if ( $Opt01ValForPersonI == $Opt02ValForPersonI ) # this person can choose different objects that have the same values = $Opt01ValForPersonI
			{
				@objects_with_same_values = grep { $current_value{$_} == $Opt01ValForPersonI } keys %current_value;
				$seen_object{$_}{$person} = $Opt01ValForPersonI for (@objects_with_same_values);
				$count_object{$_}++ for (@objects_with_same_values);
				
				if ( not @updated_price and defined $Opt01ValForPersonI_old_list ){
					for my $object ( @objects_with_same_values ){
						next unless ( $current_value{$object} > $Opt01ValForPersonI_old_list ); # objects in the new list that have values greater than the objects in the old list
						$objects_desired_by_this{$person}{$object} = $current_value{$object};   # add information about the most desired objects
					}
				}

			} else 
			{
				$choose_object{$Opt01ObjForPersonI}++;
			
				if ( (not defined $info{$Opt01ObjForPersonI}) || ($bidForPersonI > $info{$Opt01ObjForPersonI}{'bid'}) || ($bidForPersonI == $info{$Opt01ObjForPersonI}{'bid'} and $current_value{$Opt01ObjForPersonI} > $info{$Opt01ObjForPersonI}{'CurVal'}) )
				{			
					$info{$Opt01ObjForPersonI}{'bid'   } = $bidForPersonI; # Stores the bidding info for future use
					$info{$Opt01ObjForPersonI}{'person'} = $person;
					$info{$Opt01ObjForPersonI}{'CurVal'} = $current_value{$Opt01ObjForPersonI};
				
					#printf " object = %3s ; person = %3s ; bid = %12.5f ; CurVal = %12.5f \n", $Opt01ObjForPersonI, $info{$Opt01ObjForPersonI}{'person'}, $info{$Opt01ObjForPersonI}{'bid'}, $info{$Opt01ObjForPersonI}{'CurVal'}; sleep 1;
				}
			}
			
			if ( $epsilon_scaling >= 6 and $epsilon_scaling % 3 == 0 and not $seen_person{$person}++ ) # filter the old list
			{					
				for my $object ( @objects_with_greater_benefits ){ # frequently check the quality of objects in the old list
					next if ( $current_value{$object} >= $Opt03ValForPersonI );
					next unless ( ($Opt03ValForPersonI - $current_value{$object}) > $min_size * $epsilon ); # critical value ($min_size * $epsilon)
					delete $objects_desired_by_this{$person}{$object}; # delete objects of little benefit from the old list
					printf $output "<> PersonI = %3s ; *** delete the object %3s from the old list *** \n", $person, $object if ( $verbose >= 8 );
				}
			}
					
			if ( not @updated_price ) # if all prices are outdated
			{			
				for my $object ( @objects_with_greater_benefits ){
					next unless ( defined $objects_desired_by_this{$person}{$object} );
					$objects_desired_by_this{$person}{$object} = $current_value{$object}; # update current values for all objects in the old list	
				}
				
				$objects_desired_by_this{$person}{$Opt01ObjForPersonI} = $current_value{$Opt01ObjForPersonI}; # add information about the most desired objects
				$objects_desired_by_this{$person}{$Opt02ObjForPersonI} = $current_value{$Opt02ObjForPersonI} if (defined $Opt02ObjForPersonI);
				$objects_desired_by_this{$person}{$Opt03ObjForPersonI} = $current_value{$Opt03ObjForPersonI} if (defined $Opt03ObjForPersonI);				

				$locked_list{$person} = 1 if ( $epsilon_scaling > (1/5) * $max_epsilon_scaling and ($Opt03ValForPersonI - $Opt01ValForPersonI_new_list) > $min_size * $epsilon );
				$locked_list{$person} = 1 if ( $epsilon_scaling > (2/5) * $max_epsilon_scaling ); # Lock the old list. Is this the minimum value to find a possible solution?
				delete $locked_list{$person} if ( $epsilon == 1/(1+$min_size) ); # Otherwise unlock the person's old list in the last $epsilon_scaling round.
			}
			
			if ( $verbose >= 8 ){
				my @old_list = sort { $a <=> $b } @objects_with_greater_benefits;
				my @new_list = sort { $a <=> $b } keys %{$objects_desired_by_this{$person}};
				@updated_price = sort { $a <=> $b } @updated_price;
				my @best_3_objects = ( $Opt01ObjForPersonI, $Opt02ObjForPersonI, $Opt03ObjForPersonI );				
				my $msg = $locked_list{$person} ? '[locked list] ' : '';
				
				@objects_with_same_values = sort { $a <=> $b } @objects_with_same_values;
				$this_person_can_choose_n_different_objects{$person}{'objects'} = \@objects_with_same_values; #reference to an array								

				printf $output "<> PersonI = %3s ; %3s objects desired by this person (old list) = (@old_list) ; objects whose current values are still updated = (@updated_price) : %2s >= 1 ? \n", $person, scalar @old_list, scalar @updated_price;
				printf $output "<> PersonI = %3s ; %3s objects desired by this person (new list) = (@new_list) $msg; \@best_3_objects = (@best_3_objects) \n", $person, scalar @new_list if ( defined $Opt03ObjForPersonI );
				printf $output "<> PersonI = %3s chose ObjectJ = %3s ; \$bidForPersonI %10.5f = \$Opt01ValForPersonI %.5f - \$Opt02ValForPersonI %.5f + \$epsilon %.5f \n", $person, $Opt01ObjForPersonI, $bidForPersonI, $Opt01ValForPersonI, $Opt02ValForPersonI, $epsilon if (not @objects_with_same_values);
				printf $output "<> PersonI = %3s ; these objects (@objects_with_same_values) have the same values \$Opt01ValForPersonI = %10.5f ; \$Opt01ObjForPersonI = $Opt01ObjForPersonI ; *** equal values *** \n", $person, $Opt01ValForPersonI if (@objects_with_same_values);
			}
		}
	}
	
	my %choose_person;
	
	# first, choose objects that appear a few times
    foreach my $object ( sort { $count_object{$a} <=> $count_object{$b} } keys %seen_object ){	# || $price_object{$b} <=> $price_object{$a}
	foreach my $person ( sort { $seen_object{$object}{$a} <=> $seen_object{$object}{$b} } keys %{$seen_object{$object}} ){ # sort { $seen_object{$object}{$a} <=> $seen_object{$object}{$b} }
		
		next if ( $choose_object{$object} );
		next if ( $choose_person{$person} );
	
		my $CurVal = $seen_object{$object}{$person}; # $CurVal = $current_value{$object} = $Opt01ValForPersonI.
		my $Opt01ObjForPersonI = $object;
			
		$info{$Opt01ObjForPersonI}{'bid'   } = $epsilon;
		$info{$Opt01ObjForPersonI}{'person'} = $person;
			
		$objects_desired_by_this{$person}{$object} = $CurVal;								
		
		if ( $verbose >= 8 ){
		
			my @objects_with_same_values_full = sort { $a <=> $b } @{$this_person_can_choose_n_different_objects{$person}{'objects'}};
			my @objects_with_same_values_free = grep { not $choose_object{$_} } @objects_with_same_values_full;
			
			printf $output "<*** equal values ***> \$bidForPersonI = \$epsilon = %.5f ; PersonI = %3s chose ObjectJ = %3s between these (@objects_with_same_values_full) --> free (@objects_with_same_values_free) ; \$count_object{$object} = $count_object{$object} \n", $epsilon, $person, $Opt01ObjForPersonI ;		
		}
		
		$choose_object{$object}++;
		$choose_person{$person}++;		
	}}
	
	foreach my $object ( keys %info ) # sort { $a <=> $b } or sort { $info{$a}{'person'} <=> $info{$b}{'person'} }
	{
		my $bid    = $info{$object}{'bid'   };
		my $person = $info{$object}{'person'};
		
		my $other_person = $assignned_object{$object}; # Find the other person who has objectJ and make them unassigned
	   	   	   
		if ( defined $other_person ) {
		  
			if ( $verbose >= 8 ){
				print $output " ***--> PersonI $person was assigned objectJ $object. Before that, remove the objectJ $object from personI $other_person  --> delete \$assignned_person{$other_person} \n";
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
	   
		if ( $verbose >= 8 ){
			printf $output " --> Assigning to personI = %3s the objectJ = %3s with highestBidForJ = %10.5f and update the price vector ; \$assignned_person{%3s} = %3s ; \$price_object{%3s} = %.5f \n", $person, $object, $bid, $person, $assignned_person{$person}, $object, $price_object{$object};	
		}
	}
	
	if ( $verbose >= 9 ){
		print $output "\n Final: Matrix Size N x M: $min_size x $max_size ; Num Iterations: $iter_count_global ; epsilon_scaling = $epsilon_scaling ; iter_count_local = $iter_count_local ; epsilon: $epsilon \n";
		foreach my $person ( sort { $a <=> $b } keys %assignned_person ){
			my $object = $assignned_person{$person};
			printf $output " \$assignned_person{%3s} --> object %3s --> \$price_object{%3s} = $price_object{$object} \n", $person, $object, $object;
		}
		foreach my $object ( sort { $a <=> $b } keys %price_object ){
			printf $output " \$price_object{%3s} = $price_object{$object} \n", $object;
		}
		print $output "\n";
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
 
 Example 1: Find the nearest neighbor, Minimize the total benefit.

 my @array1 = ( 893, 401, 902, 576, 767, 917, 76, 464, 124, 207, 125, 530 );
 my @array2 = ( 161, 559, 247, 478, 456 );

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
  
       161 559 247 478 456

 893 [ 732 334 646 415 437 ]
 401 [ 240 158 154  77  55 ]
 902 [ 741 343 655 424 446 ]
 576 [ 415  17 329  98 120 ]
 767 [ 606 208 520 289 311 ]
 917 [ 756 358 670 439 461 ]
  76 [  85 483 171 402 380 ]
 464 [ 303  95 217  14   8 ]
 124 [  37 435 123 354 332 ]
 207 [  46 352  40 271 249 ]
 125 [  36 434 122 353 331 ]
 530 [ 369  29 283  52  74 ]
 
 my ( $optimal, $assignment_ref, $output_index_ref ) = auction( matrix_ref => \@input_matrix, maximize_total_benefit => 0, verbose => 5 );
  
 Objective: to Minimize the total benefit
 Number of left nodes: 12
 Number of right nodes: 5
 Number of edges: 60

 Solution:
 Optimal assignment: sum of values = 153
 Feasible assignment condition: stepsize = 0.1667 < 1/5 = 0.2
 Number of iterations: 50

 row index    = [  0   1   2   3   4   5   6   7   8   9  10  11 ]
 column index = [  9   8  10   1   5  11   7   4   6   2   0   3 ]
 matrix value = [             17               8      40  36  52 ]

 modified matrix 5 x 9:
 [ 516   341   150   671   453   719   710   720** 387  ]
 [ 598   739** 548   273   661   321   404   322   727  ]
 [ 602   427   236   585   539   633   716** 634   473  ]
 [ 679   658   467   354   742   402   485   403   704**]
 [ 701   636   445   376   748** 424   507   425   682  ]

 original matrix 12 x 5 with solution:
 [ 732   334   646   415   437  ]
 [ 240   158   154    77    55  ]
 [ 741   343   655   424   446  ]
 [ 415    17** 329    98   120  ]
 [ 606   208   520   289   311  ]
 [ 756   358   670   439   461  ]
 [  85   483   171   402   380  ]
 [ 303    95   217    14     8**]
 [  37   435   123   354   332  ]
 [  46   352    40** 271   249  ]
 [  36** 434   122   353   331  ]
 [ 369    29   283    52**  74  ]

 Pairs (in ascending order of matrix values):
   indices (  7,  4 ), matrix value =   8 ; sum of values =     8
   indices (  3,  1 ), matrix value =  17 ; sum of values =    25
   indices ( 10,  0 ), matrix value =  36 ; sum of values =    61
   indices (  9,  2 ), matrix value =  40 ; sum of values =   101
   indices ( 11,  3 ), matrix value =  52 ; sum of values =   153
   indices (  0,  9 ), matrix value =     ; sum of values =   153
   indices (  1,  8 ), matrix value =     ; sum of values =   153
   indices (  2, 10 ), matrix value =     ; sum of values =   153
   indices (  4,  5 ), matrix value =     ; sum of values =   153
   indices (  5, 11 ), matrix value =     ; sum of values =   153
   indices (  6,  7 ), matrix value =     ; sum of values =   153
   indices (  8,  6 ), matrix value =     ; sum of values =   153
  
 Example 2: Maximize the total benefit.
 
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
 
 Alternatively, we can define the matrix with its elements:

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

 my ( $optimal, $assignment_ref, $output_index_ref ) = auction( matrix_ref => \@input_matrix, maximize_total_benefit => 1, verbose => 3 );

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
   
 foreach my $i ( sort { $a <=> $b } keys %{$assignment_ref} ){     
   my $j = $assignment_ref->{$i};   
   ...
 }

 my $sum = 0;
 for my $i ( 0 .. $#{$output_index_ref} ){
	my $j = $output_index_ref->[$i];   
	my $value = $input_matrix[$i]->[$j];
	$sum += $value if (defined $value);
	
	$value = defined $value ? sprintf( "%6s", $value ) : ' ' x 6 ; # %6s  
	printf " Auction Algorithm, output index --> \$i = %3d ; \$j = %3d ; \$value = $value ; \$sum = %8s \n", $i, $j, $sum;
 }
 
=head1 OPTIONS
 
 matrix_ref => \@input_matrix,   reference to array: matrix N x M.
 maximize_total_benefit => 0,    0: minimize the total benefit ; 1: maximize the total benefit.
 inicial_stepsize       => 1,    auction algorithm terminates with a feasible assignment if the problem data are integer and stepsize < 1/min(N,M).
 inicial_price          => 0,			
 verbose                => 3,    print messages on the screen, level of verbosity, 0: quiet; 1, 2, 3, 4, 5, 8, 9, 10: debug information.

=head1 EXPORT

    "auction" function by default.

=head1 INPUT

    The input matrix should be in a two dimensional array (array of array) 
	and the 'auction' subroutine expects a reference to this array.

=head1 OUTPUT

    The $output_index_ref is the reference to the output_index array.
	The $assignment_ref  is the reference to the assignment hash.
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
	May 4, 2018
	Sao Paulo, Brasil
	claudiofsr@yahoo.com
	
=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2018 Claudio Fernandes de Souza Rodrigues.  All rights reserved.

 This program is free software; you can redistribute it and/or modify
 it under the same terms as Perl itself.

=cut