package Algorithm::Bertsekas;

use strict;
use warnings FATAL => 'all';
use diagnostics;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( auction );
our $VERSION = '0.22';

#Variables global to the package	
my $maximize_total_benefit;
my $matrix_spaces;     # used to print messages on the screen
my $decimals;          # the number of digits after the decimal point
my $max_matrix_value;
my $inicial_price;
my $iter_count = 0;
my ( $size_array1, $size_array2, $min_size, $max_size );
my ( @assignment, @prices );
my ( %assignned_object, %assignned_person, %price_object );

sub auction { #                        => default values
   my %args = ( matrix_ref             => undef,     # reference to array: matrix N x M			                                     
                maximize_total_benefit => 0,         # 0: minimize_total_benefit ; 1: maximize_total_benefit
				stepsize               => 1,
				inicial_price          => 0,
				verbose                => 3,         # level of verbosity, 0: quiet; 1, 2, 3, 4, 9, 10: debug information.				
                @_,                                  # argument pair list goes here
	          );
       
   my @matrix_input = @{$args{matrix_ref}};          # Input: Reference to the input matrix (NxM)  
   
   $size_array1 = $#matrix_input + 1;
   $size_array2 = $#{$matrix_input[0]} + 1;
 
   $min_size = $size_array1 < $size_array2 ? $size_array1 : $size_array2 ; # square matrix --> $min_size = $max_size and $size_array1 = $size_array2
   $max_size = $size_array1 < $size_array2 ? $size_array2 : $size_array1 ;  
   
   $maximize_total_benefit = $args{maximize_total_benefit};
   
   my $optimal_benefit = 0;
   my %assignement_hash;  # assignement: a hash representing edges in the mapping, as in the Algorithm::Kuhn::Munkres.
   my @output_index;      # output_index: an array giving the number of the value assigned, as in the Algorithm::Munkres.
   
   if ( $max_size <= 1 ){ # matrix_input 1 x 1
      $assignement_hash{0} = 0;
      $output_index[0]     = 0;
	  $optimal_benefit     = $matrix_input[0]->[0];
   }
   
   my @matrix;
   foreach ( @matrix_input ){ # copy the orginal matrix
      push @matrix, [ @$_ ];
   }   

   get_matrix_info( \@matrix, $args{verbose} );

   for my $i ( 0 .. $max_size - 1 ) {
   for my $j ( 0 .. $max_size - 1 ) {
      next if ( defined $matrix_input[$i] and defined $matrix_input[$i]->[$j] );
      # convert rectangular to square matrix by padding zeroes.			
	  $matrix[$i]->[$j] = 0;
   }}	

   # epsilon is the stepsize and auction algorithm terminates with a feasible assignment if the problem data are integer and epsilon < 1/min(N,M).
   # There is a trade-off between runtime and the chosen stepsize. Using the largest possible increment accelerates the algorithm.
   
   $inicial_price = $args{inicial_price};
   my $epsilon = $args{stepsize};
   my $feasible_assignment_condition = 0;

   # The preceding observations suggest the idea of epsilon-scaling, which consists of applying the algorithm several times, 
   # starting with a large value of epsilon and successively reducing epsilon until it is less than some critical value.
   
   while( $epsilon >= 1/(1+$max_size) and $max_size >= 2 ){
   
	  %assignned_object = ();
      %assignned_person = ();

	  while ( (scalar keys %assignned_person) < $max_size ){ # while there is at least one element not assigned.

         $iter_count++;
         auctionRound( \@matrix, $epsilon, $args{verbose} );
		 
		 if ( $args{verbose} >= 9 ){
		    @assignment = ();
		    @prices = ();
            foreach my $per ( sort { $a <=> $b } keys %assignned_person){ push @assignment, $assignned_person{$per}; }
            foreach my $obj ( sort { $a <=> $b } keys %price_object    ){ push @prices, $price_object{$obj}; }
			my $assig_count = scalar @assignment;
		    print " *** \$iter_count = $iter_count ; \$assig_count = $assig_count ; \$epsilon = $epsilon ; \@assignment = (@assignment) ; \@prices = (@prices) \n\n";
         }		 
      }
	  $epsilon = $epsilon * (1/4);
	  
	  if ( not $feasible_assignment_condition and $epsilon < 1/$min_size ){
	     $epsilon = 1/(1+$max_size) ;
	  	 $feasible_assignment_condition = 1;
	  }	  
   }
   $epsilon = 4 * $epsilon;
   
   foreach my $i ( sort { $a <=> $b } keys %assignned_person ){
	  
	  my $j = $assignned_person{$i};
      $output_index[$i] = $j;
	  
	  next unless ( defined $matrix_input[$i] and defined $matrix_input[$i]->[$j] );
	  $assignement_hash{ $i } = $j;	  
	  $optimal_benefit += $matrix_input[$i]->[$j];
   }   
   
   if ( $args{verbose} >= 10 ){
      printf "\n\$optimal_benefit = $optimal_benefit ; \$iter_count = $iter_count ; \$epsilon = %.4g ; \@output_index = (@output_index) ; \@assignment = (@assignment) ; \@prices = (@prices) \n", $epsilon; 
   }   
   print_screen_messages( \@matrix, \@matrix_input, \@output_index, $optimal_benefit, $args{verbose}, $epsilon ) ;
       
   return ( $optimal_benefit, \%assignement_hash, \@output_index ) ;
}

sub print_screen_messages {

   my ( $matrix_ref, $matrix_input_ref, $output_index_ref, $optimal_benefit, $verbose, $epsilon ) = @_;
   my @matrix = @$matrix_ref;
   my @matrix_input = @$matrix_input_ref;
   my @output_index = @$output_index_ref;
   
   if ( $verbose >= 1 ){
      
      print "\nObjective: ";
      printf( $maximize_total_benefit ? "to Maximize the total benefit\n" : "to Minimize the total benefit\n" );
      printf(" Number of left nodes: %u\n",  $size_array1 );
      printf(" Number of right nodes: %u\n", $size_array2 );
      printf(" Number of edges: %u\n", $size_array1 * $size_array2 ); 
	  
	  print "\nSolution:\n";	  
	  printf(" Optimal assignment: sum of values = %.${decimals}f \n", $optimal_benefit );	  
	  printf(" Feasible assignment condition: stepsize = %.4g < 1/$min_size = %.4g \n", $epsilon, 1/$min_size ) if ( $verbose >= 1 and $max_size >= 2 );
	  printf(" Number of iterations: %u \n", $iter_count ) if ( $verbose >= 3 );
   
      print "\nMaximum index size    = [";
      for my $i ( 0 .. $#output_index ) {
         printf("%${matrix_spaces}d ", $i);
      }
      print "]\n";

      print "\@output_index indexes = [";
      for my $index (@output_index) {
         printf("%${matrix_spaces}d ", $index);
      }
      print "]\n";
	  
      print "\@output_index values  = [";
	  
      for my $i ( 0 .. $#matrix ){
         my $j = $output_index[$i];
         my $weight = ( defined $matrix_input[$i] and defined $matrix_input[$i]->[$j] ) ? sprintf( "%${matrix_spaces}.${decimals}f ", $matrix_input[$i]->[$j] ) : ' ' x ($matrix_spaces+1) ;
         print $weight;
      }
      print "]\n\n";
   }
   
   if ( $verbose >= 2 ){
   
      my $index_length = length($max_size);   

	  if ( $verbose >= 4 ){
      print " square matrix $max_size x $max_size with padding zeroes:\n";	  
      for my $i ( 0 .. $#matrix ) {
         print " [";
         for my $j ( 0 .. $#{$matrix[$i]} ) {
            printf(" %${matrix_spaces}.${decimals}f", $matrix[$i]->[$j] );
            if ( $j == $output_index[$i] ){ print "**"; } else{ print "  "; }
         }
         print "]\n";
      }
	  print "\n";
	  }
	  
	  print " original matrix $size_array1 x $size_array2 with solution:\n";

      for my $i ( 0 .. $#matrix_input ) {
         print " [";
         for my $j ( 0 .. $#{$matrix_input[$i]} ) {
            printf(" %${matrix_spaces}.${decimals}f", $matrix_input[$i]->[$j] );
            if ( $j == $output_index[$i] ){ print "**"; } else{ print "  "; }
         }
         print "]\n";
      }
	  
      my %orderly_solution;
      for my $i ( 0 .. $#matrix ){
         my $j = $output_index[$i];
         my $weight = $max_matrix_value;
         $weight = $matrix_input[$i]->[$j] if ( defined $matrix_input[$i] and defined $matrix_input[$i]->[$j] ); # condition for valid solution
   
         $orderly_solution{ $weight } { $i } { 'index_array1' } = $i;
         $orderly_solution{ $weight } { $i } { 'index_array2' } = $j; 
      }

      print "\n Pairs (in ascending order of weight function values):\n"; 

      my $sum_matrix_value = 0;
      foreach my $matrix_value ( sort { $a <=> $b }  keys %orderly_solution ){
      foreach my $k ( sort { $a <=> $b } keys %{$orderly_solution{$matrix_value}} ){
     
	     my $index_array1 = $orderly_solution{ $matrix_value } { $k } { 'index_array1' };
         my $index_array2 = $orderly_solution{ $matrix_value } { $k } { 'index_array2' };
	  
	     $sum_matrix_value += $matrix_value if ( defined $matrix_input[$index_array1] and defined $matrix_input[$index_array1]->[$index_array2] );
	  
	     my $weight = ( defined $matrix_input[$index_array1] and defined $matrix_input[$index_array1]->[$index_array2] ) ? sprintf( "%${matrix_spaces}.${decimals}f", $matrix_value ) : ' ' x $matrix_spaces ;
	  
         printf( "   indexes ( %${index_length}d, %${index_length}d ), weight value = $weight ; sum of values = %${matrix_spaces}.${decimals}f \n", $index_array1, $index_array2, $sum_matrix_value );
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
   
   my $gap = $max_matrix_value - $min_matrix_value;           # $gap >= 0
      $gap = 1 if ($gap == 0);
   
   if ( $verbose >= 5 ){
      print "\n min_matrix_value = $min_matrix_value ; max_matrix_value = $max_matrix_value ; gap = $gap ; matrix_spaces = $matrix_spaces ; decimals = $decimals \n";
   }
   
   if ( $maximize_total_benefit ){

      for my $i ( 0 .. $#matrix ) {
      for my $j ( 0 .. $#{$matrix[$i]} ) {
	     $matrix[$i]->[$j] = 99 * ( $matrix[$i]->[$j] - $min_matrix_value ) / $gap; # new scale: Min = 0 <---> Max = 99
      }}   
 	  
   } else {

      for my $i ( 0 .. $#matrix ) {
      for my $j ( 0 .. $#{$matrix[$i]} ) {   
	     
		 #$matrix[$i]->[$j] = ( $max_matrix_value - $matrix[$i]->[$j] );
		 
		 $matrix[$i]->[$j] = 99 * ( $max_matrix_value - $matrix[$i]->[$j] ) / $gap;
      }}	  
   }
}

sub auctionRound {
	my ( $matrix_ref, $epsilon, $verbose ) = @_;
	my @matrix = @$matrix_ref;
	my %info;

   if ( $verbose >= 10 ){
      print "\n Start: Matrix Size N x M: $max_size x $max_size ; Num Iterations: $iter_count ; epsilon: $epsilon \n";
	  foreach my $person ( sort { $a <=> $b } keys %assignned_person ){
	     print " \$assignned_person{$person} --> object $assignned_person{$person} \n";
	  }
	  foreach my $object ( sort { $a <=> $b } keys %price_object ){
	     print " \$price_object{$object} = $price_object{$object} \n";
	  }
	  print "\n";
   }

	for my $person ( 0 .. $#matrix )
	{   	    
		if ( not defined $assignned_person{$person} )
		{		
			##     ------> j          object 0   object 1   object 2   object 3 ...  object (M - 1)
			##  |  person 0          price_0_0  price_0_1  price_0_2  price_0_3      price_0_j
			##  |  person 1          price_1_0
			##  |  person 2          price_2_0
			##  |  ...
			##  i  person (N - 1)    price_i_0

			##	Need the best and second best value of each object to this personI

			my ( $optValForI, $secOptValForI, $optObjForI, $secOptObjForI );
			
			for my $object ( 0 .. $#matrix )
			{				
				$price_object{$object} = $inicial_price unless ( defined $price_object{$object} );				
				my $curVal = $matrix[$person]->[$object] - $price_object{$object};               					
				
				if ( (not defined $optValForI) || ($curVal > $optValForI) )
				{
					$secOptValForI = $optValForI;
					$secOptObjForI = $optObjForI;
					$optValForI = $curVal;
					$optObjForI = $object;
				}
				elsif ( (not defined $secOptValForI) || ($curVal > $secOptValForI) )
				{
					$secOptValForI = $curVal;
					$secOptObjForI = $object;
				}
				
				if ( $verbose >= 10 ){
			        printf " personI = %2s ; objectJ = %2s ; \$size_array1 = %2s ; \$size_array2 = %2s ; \$curVal %8.4f = \$matrix[%2s]->[%2s] %8.4f - \$price_object{%2s} %8.4f ;", $person, $object, $size_array1, $size_array2, $curVal, $person, $object, $matrix[$person]->[$object], $object, $price_object{$object};				
				    if ( defined $optValForI    ){ printf " \$optValForI = %8.4f ", $optValForI; }
				    if ( defined $secOptValForI ){ printf " \$secOptValForI = %8.4f \n", $secOptValForI; } else { print "\n"; }
                }
			}

			## Computes the highest reasonable bid for the best object for this person
			my $bidForI = $optValForI - $secOptValForI + $epsilon;			

			## Stores the bidding info for future use			
			$info{$optObjForI}{$bidForI}{$person}++ if ( not defined $info{$optObjForI}{$bidForI} ); # first person with this bid
			
			if ( $verbose >= 10 ){
			    printf "<> PersonI = %2s ; ObjectJ = %2s ; \$bidForI %3s = \$optValForI %3s - \$secOptValForI %3s + \$epsilon %.4f \n", $person, $optObjForI, $bidForI, $optValForI, $secOptValForI, $epsilon;
		    }
		}
	}
	
	my %seen_first_object;
	
	foreach my $object ( sort { $a <=> $b } keys %info ){                      # ascending order
	foreach my $bid    ( sort { $b <=> $a } keys %{$info{$object}} ){          # descending order!!!
	foreach my $person ( sort { $a <=> $b } keys %{$info{$object}{$bid}} ){    # ascending order	   
	   
	   next if ( $seen_first_object{$object}++ );  # choose only the highest Bid For ObjectJ, 
	   
	   if ( defined $assignned_object{$object} ) { # Find the other person who has object $j and make them unassigned	      
          
		  my $other_p = $assignned_object{$object};
		  
	      if ( $verbose >= 10 ){
			 print " ***--> PersonI $person was assigned objectJ $object. Before that, remove the objectJ $object from personI $other_p  --> delete \$assignned_person{$other_p} \n";
	      }
		  delete $assignned_person{$other_p};
	      delete $assignned_object{$object};
	   }
	   
	   $assignned_person{$person} = $object;
	   $assignned_object{$object} = $person;
	   
	   $price_object{$object} += $bid;
	   
	   if ( $verbose >= 10 ){
	      printf " --> Assigning to personI = $person the objectJ = $object with highestBidForJ = %8.4f and update the price vector ; \$assignned_person{$person} = $assignned_person{$person} ; \$price_object{$object} = $price_object{$object} \n", $bid;	
       }
    }}}	
	
   # Prints the %assignned_person and %price_object
   if ( $verbose >= 10 ){
      print "\n Final: Matrix Size N x M: $max_size x $max_size ; Num Iterations: $iter_count ; epsilon: $epsilon \n";
	  foreach my $person ( sort { $a <=> $b } keys %assignned_person ){
	     print " \$assignned_person{$person} --> object $assignned_person{$person} \n";
	  }
	  foreach my $object ( sort { $a <=> $b } keys %price_object ){
	     print " \$price_object{$object} = $price_object{$object} \n";
	  }
   }
   
}

1;  # don't forget to return a true value from the file

__END__

=head1 NAME

    Algorithm::Bertsekas - auction algorithm for the assignment problem.
	
	This is a perl implementation for the auction algorithm for the symmetric allocation problem.
	
	"Both, the auction algorithm and the Kuhn-Munkres algorithm have worst-case time complexity 
	of (roughly) O(N^3). However, the average-case time complexity of the auction algorithm is 
	much better. Thus, in practice, with respect to running time, the auction algorithm outperforms 
	the Kuhn-Munkres (or Hungarian) algorithm significantly."

=head1 DESCRIPTION
 
 The assignment problem in the general form can be stated as follows:

 "Given N jobs, M tasks and the effectiveness of each job for each task, the problem is to assign each job 
 to one and only one task in such a way that the measure of effectiveness is optimised (Maximised or Minimised)."
 
 "Each assignment problem has associated with a table or matrix. Generally, the rows contain the jobs or people 
 we wish to assign, and the columns comprise the tasks or things we want them assigned to. The numbers in the 
 table are the costs associated with each particular assignment."
 
 One application is to find the (nearest/more distant) neighbors. 
 The distance between neighbors can be represented by a matrix or a weight function, for example:
 1: f(i,j) = abs ($array1[i] - $array2[j])
 2: f(i,j) = ($array1[i] - $array2[j]) ** 2
 

=head1 SYNOPSIS

 use Algorithm::Bertsekas qw(auction);

 my @array1 = ( 64.68, 47.56,  7.36, 80.90, 96.71, 50.10, 44.16 );
 my @array2 = (  3.91, 88.77, 45.56, 79.28 );
 
 my $min = $#array1 < $#array2 ? $#array1 : $#array2;
 my $max = $#array1 < $#array2 ? $#array2 : $#array1;

 for my $i ( 0 .. $#array1 ){
   my @weight_function;		   
   for my $j ( 0 .. $#array2 ){
      my $weight = abs ($array1[$i] - $array2[$j]);
      #  $weight =     ($array1[$i] - $array2[$j]) ** 2;  # another option
      push @weight_function, $weight;
   }
   push @input_matrix, \@weight_function;
 } 
 
         3.91 88.77 45.56 79.28

 64.68 [ 60.77 24.09 19.12 14.60 ]
 47.56 [ 43.65 41.21  2.00 31.72 ]
  7.36 [  3.45 81.41 38.20 71.92 ]
 80.90 [ 76.99  7.87 35.34  1.62 ]
 96.71 [ 92.80  7.94 51.15 17.43 ]
 50.10 [ 46.19 38.67  4.54 29.18 ]
 44.16 [ 40.25 44.61  1.40 35.12 ]

 @input_matrix = (
 [ 60.77, 24.09, 19.12, 14.60 ],
 [ 43.65, 41.21,  2.00, 31.72 ],
 [  3.45, 81.41, 38.20, 71.92 ],
 [ 76.99,  7.87, 35.34,  1.62 ],
 [ 92.80,  7.94, 51.15, 17.43 ],
 [ 46.19, 38.67,  4.54, 29.18 ],
 [ 40.25, 44.61,  1.40, 35.12 ]
 );

 my ( $optimal, $assignement_ref, $output_index_ref ) = auction( matrix_ref => \@input_matrix, maximize_total_benefit => 0, verbose => 2 );

Objective: to Minimize the total benefit
 Number of left nodes: 7
 Number of right nodes: 4
 Number of edges: 28

Solution:
 Optimal assignment: sum of values = 14.41
 Feasible assignment condition: stepsize = 0.2 < 1/4 = 0.25

Maximum index size    = [    0     1     2     3     4     5     6 ]
@output_index indexes = [    6     5     0     3     1     4     2 ]
@output_index values  = [             3.45  1.62  7.94        1.40 ]

 original matrix 7 x 4 with solution:
 [ 60.77   24.09   19.12   14.60  ]
 [ 43.65   41.21    2.00   31.72  ]
 [  3.45** 81.41   38.20   71.92  ]
 [ 76.99    7.87   35.34    1.62**]
 [ 92.80    7.94** 51.15   17.43  ]
 [ 46.19   38.67    4.54   29.18  ]
 [ 40.25   44.61    1.40** 35.12  ]

 Pairs (in ascending order of weight function values):
   indexes ( 6, 2 ), weight value =  1.40 ; sum of values =  1.40
   indexes ( 3, 3 ), weight value =  1.62 ; sum of values =  3.02
   indexes ( 2, 0 ), weight value =  3.45 ; sum of values =  6.47
   indexes ( 4, 1 ), weight value =  7.94 ; sum of values = 14.41
   indexes ( 0, 6 ), weight value =       ; sum of values = 14.41
   indexes ( 1, 5 ), weight value =       ; sum of values = 14.41
   indexes ( 5, 4 ), weight value =       ; sum of values = 14.41


 Common use of the solution:
   
 foreach my $array1_index ( sort { $a <=> $b } keys %{$assignement_ref} ){     
   my $i = $array1_index;
   my $j = $assignement_ref->{$array1_index};   
   ...
 }
 
 for my $i (0 .. $max){
   my $j = $output_index_ref->[$i];
   ...
 }
 
 assignement hash --> $i =   2 e $value1 =  7.36; $j =   0 e $value2 =  3.91 ; difference =  3.45 ; sum =  3.45
 assignement hash --> $i =   3 e $value1 = 80.90; $j =   3 e $value2 = 79.28 ; difference =  1.62 ; sum =  5.07
 assignement hash --> $i =   4 e $value1 = 96.71; $j =   1 e $value2 = 88.77 ; difference =  7.94 ; sum = 13.01
 assignement hash --> $i =   6 e $value1 = 44.16; $j =   2 e $value2 = 45.56 ; difference =  1.40 ; sum = 14.41

 output_index array --> $i =   0 e $value1 = 64.68; $j =   6 e $value2 =       ; difference =       ; sum =  0.00
 output_index array --> $i =   1 e $value1 = 47.56; $j =   5 e $value2 =       ; difference =       ; sum =  0.00
 output_index array --> $i =   2 e $value1 =  7.36; $j =   0 e $value2 =  3.91 ; difference =  3.45 ; sum =  3.45
 output_index array --> $i =   3 e $value1 = 80.90; $j =   3 e $value2 = 79.28 ; difference =  1.62 ; sum =  5.07
 output_index array --> $i =   4 e $value1 = 96.71; $j =   1 e $value2 = 88.77 ; difference =  7.94 ; sum = 13.01
 output_index array --> $i =   5 e $value1 = 50.10; $j =   4 e $value2 =       ; difference =       ; sum = 13.01
 output_index array --> $i =   6 e $value1 = 44.16; $j =   2 e $value2 = 45.56 ; difference =  1.40 ; sum = 14.41

 
=head1 OPTIONS
 
 matrix_ref => \@input_matrix     reference to array: matrix N x M.
 maximize_total_benefit => 0      0: minimize the total benefit ; 1: maximize the total benefit.
 verbose  => 3                    print messages on the screen, level of verbosity, 0: quiet; 1, 2, 3, 4, 9, 10: debug information.

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
  
	1. Dimitri P. Bertsekas - Network Optimization: Continuous and Discrete Models.
	   http://web.mit.edu/dimitrib/www/netbook_Full_Book.pdf
	
	2. https://github.com/EvanOman/AuctionAlgorithmCPP/blob/master/auction.cpp
	   This Perl algorithm has been adapted from this implementation.
	      
	3. https://en.wikipedia.org/wiki/Assignment_problem


=head1 AUTHOR

    Claudio Fernandes de Souza Rodrigues
	February 2018
	Sao Paulo, Brasil
	claudiofsr@yahoo.com
	
=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Claudio Fernandes de Souza Rodrigues.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut