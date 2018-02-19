package Algorithm::Bertsekas;

use strict;
use warnings FATAL => 'all';
use diagnostics;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( auction );
our $VERSION = '0.10';

#Variables global to the package	
my $maximize_total_benefit;
my $matrix_spaces;   # used to print messages on the screen
my $decimals;        # the number of digits after the decimal point
my $iter_count = 0;
my %g;

sub auction { #                        => default values
   my %args = ( matrix_ref             => undef,     # reference to array: matrix N x M
                stepsize               => undef,     # epsilon is the stepsize, by default epsilon = 1 / ( min(N,M) + 1 )				                                     
                maximize_total_benefit => 1,         # 0: minimize_total_benefit ; 1: maximize_total_benefit
				verbose                => 3,         # level of verbosity, 0: quiet; 1, 2, 3: full information.
                @_,                                  # argument pair list goes here
	          );
			  
   my @matrix = @{$args{matrix_ref}};                # Input: Reference to the input matrix (MxN)
   $maximize_total_benefit = $args{maximize_total_benefit};
   
   my %assignement;  # assignement: a hash representing edges in the mapping, as in the Algorithm::Kuhn::Munkres.
   my @output_index; # output_index: an array giving the number of the value assigned, as in the Algorithm::Munkres.
   my $optimal;
   
   get_edges( \@matrix );   
   mkbg( \%g );
   #print Dumper \%g;   

   my $size_array1 = $#matrix + 1;
   my $size_array2 = $#{$matrix[0]} + 1;
   
   my $min_size = $size_array1 < $size_array2 ? $size_array1 : $size_array2;
   my $max_size = $size_array1 > $size_array2 ? $size_array1 : $size_array2;
   
   my $max_matrix_value = $g{'max_matrix_value'};

   # epsilon is the stepsize and auction algorithm terminates with a feasible assignment if the problem data are 
   # integer and epsilon < 1/min(N,M). See page 256 in Network Optimization, Continuous and Discrete Models - Dimitri P Bertsekas.
   my $epsilon = 1 / ( $min_size + 1 ) ;
   
   $epsilon = $args{stepsize} if ( defined $args{stepsize} ); 
   
   # The preceding observations suggest the idea of epsilon-scaling, which consists of applying the algorithm several times, 
   # starting with a large value of epsilon and successively reducing epsilon until it is less than some critical value (for example, 1/n, when $matrix[$i]->[$j] are integer).  

   $optimal = bidding( \%g, $epsilon );

   my $total_benefit = $maximize_total_benefit ? $optimal : $min_size * $max_matrix_value - $optimal ;    
   
   my %seeN;
   my %seeM;
   for my $i ( 0 .. $#{$g{'edges'}} ) {  
   	  my $array1_index = $g{'b'} ? $g{'edges'}[$i]{'v'} : $g{'edges'}[$i]{'u'};	  
	  my $array2_index = $g{'b'} ? $g{'edges'}[$i]{'u'} : $g{'edges'}[$i]{'v'};
      my $weight = $g{'edges'}[$i]{'w'};
	    
      $output_index[$array1_index] = $array2_index;
	  $seeN{$array1_index}++;
	  $seeM{$array2_index}++;
   }
   for my $i ( 0 .. $max_size - 1 ) {
   for my $j ( 0 .. $max_size - 1 ) {
      next if ($seeN{$i} or $seeM{$j});  
      $output_index[$i] = $j;
	  $seeN{$i}++;
	  $seeM{$j}++;
	  last;
   }}
   
   for my $i ( 0 .. $#{$g{'edges'}} ) {
	  my $array1_index = $g{'b'} ? $g{'edges'}[$i]{'v'} : $g{'edges'}[$i]{'u'};	  
	  my $array2_index = $g{'b'} ? $g{'edges'}[$i]{'u'} : $g{'edges'}[$i]{'v'};
      my $weight = $g{'edges'}[$i]{'w'};
	  $assignement{ $array1_index } = $array2_index;
   }
   
   if ( $args{verbose} >= 1 ){
      
      print "\nObjective: ";
      printf( $maximize_total_benefit ? "to Maximize the total benefit\n" : "to Minimize the total benefit\n" );
      printf(" Number of left nodes: %u\n",  $size_array1 );
      printf(" Number of right nodes: %u\n", $size_array2 );
      printf(" Number of edges: %u\n", $size_array1 * $size_array2 ); 
	  
	  print "\nSolution:\n";	  
	  printf(" Optimal assignment: sum of values = %.${decimals}f \n", $total_benefit );	  
	  printf(" Feasible assignment condition: stepsize = %.4g < 1/$min_size = %.4g \n", $epsilon, 1/$min_size ) if ( $args{verbose} >= 3 );
	  printf(" Number of iterations: %u \n", $iter_count ) if ( $args{verbose} >= 3 );
   
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
	  
      for my $i ( 0 .. $max_size - 1 ){
         my $j = $output_index[$i];
         my $weight = ( defined $matrix[$i] and defined $matrix[$i]->[$j] ) ? sprintf( "%${matrix_spaces}.${decimals}f ", $matrix[$i]->[$j] ) : ' ' x ($matrix_spaces+1) ;
         print $weight;
      }
      print "]\n\n";
   }
   
   if ( $args{verbose} >= 2 ){
   
      my $index_length = length($max_size);   
	  			   			   
      for my $i ( 0 .. $#matrix ) {
         print " [";
         for my $j ( 0 .. $#{$matrix[$i]} ) {
            printf(" %${matrix_spaces}.${decimals}f", $matrix[$i]->[$j] );
            if ( $j == $output_index[$i] ){ print "**"; } else{ print "  "; }
         }
         print "]\n";
      }
	  
      my %orderly_solution;
      for my $i ( 0 .. $max_size - 1 ){
         my $j = $output_index[$i];
         my $weight = $max_matrix_value;
         $weight = $matrix[$i]->[$j] if ( defined $matrix[$i] and defined $matrix[$i]->[$j] ); # condition for valid solution
   
         $orderly_solution{ $weight } { $i } { 'index_array1' } = $i;
         $orderly_solution{ $weight } { $i } { 'index_array2' } = $j; 
      }

      print "\n Pairs (in ascending order of weight function values):\n"; 

      my $sum_matrix_value = 0;
      foreach my $matrix_value ( sort { $a <=> $b }  keys %orderly_solution ){
      foreach my $k ( sort { $a <=> $b } keys %{$orderly_solution{$matrix_value}} ){
     
	     my $index_array1 = $orderly_solution{ $matrix_value } { $k } { 'index_array1' };
         my $index_array2 = $orderly_solution{ $matrix_value } { $k } { 'index_array2' };
	  
	     $sum_matrix_value += $matrix_value if ( defined $matrix[$index_array1] and defined $matrix[$index_array1]->[$index_array2] );
	  
	     my $weight = ( defined $matrix[$index_array1] and defined $matrix[$index_array1]->[$index_array2] ) ? sprintf( "%${matrix_spaces}.${decimals}f", $matrix_value ) : ' ' x $matrix_spaces ;
	  
         printf( "   indexes ( %${index_length}d, %${index_length}d ), weight value = $weight ; sum of values = %${matrix_spaces}.${decimals}f \n", $index_array1, $index_array2, $sum_matrix_value );
      }}	  
   }  
   
   return ( $optimal, \%assignement, \@output_index ) ;
}

sub get_edges {
   my $matrix_ref = shift;
   my @matrix = @{$matrix_ref};
   my @edges;
   my $max_matrix_value; 
   my $min_matrix_value;    
   
   for my $i ( 0 .. $#matrix ) {
   for my $j ( 0 .. $#{$matrix[$i]} ) {
      $max_matrix_value = $matrix[$i]->[$j] if ( (not defined $max_matrix_value) || ($matrix[$i]->[$j] > $max_matrix_value) );	  
	  $min_matrix_value = $matrix[$i]->[$j] if ( (not defined $min_matrix_value) || ($matrix[$i]->[$j] < $min_matrix_value) );
   }}
   
   $matrix_spaces = maximum( length($min_matrix_value), length($max_matrix_value) );  # counting the number of digits + .
   
   $decimals = length(($max_matrix_value =~ /[,.](\d+)/)[0]); # counting the number of digits after the decimal point
   $decimals = 0 unless ( defined $decimals );                # for integers $decimals = 0     
      
   #print "\n min_matrix_value = $min_matrix_value ; max_matrix_value = $max_matrix_value ; matrix_spaces = $matrix_spaces ; decimals = $decimals \n";
   
   for my $i ( 0 .. $#matrix ) {
   for my $j ( 0 .. $#{$matrix[$i]} ) {
   
	  my $weight = $maximize_total_benefit ? $matrix[$i]->[$j] : $max_matrix_value - $matrix[$i]->[$j];
   
	  my %hash;
      $hash{'u'} = $i;  # u --> $i index
      $hash{'v'} = $j;  # v --> $j index
      $hash{'w'} = $weight;

      push @edges, \%hash;
   }}

   $g{'edges'} = \@edges; # $#edges + 1 : number of edges
   
   my $size_array1 = $#matrix + 1;
   my $size_array2 = $#{$matrix[0]} + 1;

   $g{'N'} = $size_array1 + 1; # N number of left  nodes + 1
   $g{'M'} = $size_array2 + 1; # M number of right nodes + 1
   $g{'max_matrix_value'} = $max_matrix_value;
   $g{'min_matrix_value'} = $min_matrix_value;
}

sub mkbg { # Building a special sparse graph structure
    my $hash_ref = shift;
	my @edges = @{$g{'edges'}};
	my @d;

	if ( $g{'N'} <= $g{'M'} ){	
	    $g{'b'} = 0;   # bool b; b=0 iff N < M		
		for my $i ( 0 .. $#edges ) {
			my $u = $g{'edges'}[$i]{'u'};
			$d[$u]++;
		}		
		$g{'cd'}[0]=0; # cd: cumulative degree: (start with 0) length=dim+1
		for my $i ( 1 .. $g{'N'} ) {		
		    $d[$i-1] = 0 if ( not defined $d[$i-1] );
			$g{'cd'}[$i] = $g{'cd'}[$i-1] + $d[$i-1];
			$d[$i-1] = 0;
		}
		for my $i ( 0 .. $#edges ) {
			my $u = $g{'edges'}[$i]{'u'};
			$g{'adj'}[ $g{'cd'}[$u] + $d[$u]   ] = $g{'edges'}[$i]{'v'}; # adj: list of neighbors
            $g{'w'  }[ $g{'cd'}[$u] + $d[$u]++ ] = $g{'edges'}[$i]{'w'}; # w:   weight of the edges
		}				
	}
    else{
		$g{'b'} = 1;  # bool b; b=1 iff N > M
		for my $i ( 0 .. $#edges ) {
			my $v = $g{'edges'}[$i]{'v'};
			$d[$v]++;
		}		
		$g{'cd'}[0]=0;
		for my $i ( 1 .. $g{'M'} ) {
		    $d[$i-1] = 0 if ( not defined $d[$i-1] );
			$g{'cd'}[$i] = $g{'cd'}[$i-1] + $d[$i-1];
			$d[$i-1] = 0;
		}
		for my $i ( 0 .. $#edges ) {
			my $u = $g{'edges'}[$i]{'v'};
			$g{'adj'}[ $g{'cd'}[$u] + $d[$u]   ] = $g{'edges'}[$i]{'u'};
            $g{'w'  }[ $g{'cd'}[$u] + $d[$u]++ ] = $g{'edges'}[$i]{'w'};		
		}		
		my $temp = $g{'N'};
		$g{'N'} = $g{'M'};
		$g{'M'} = $temp;
	}
}

sub bidding { # bidding towards convergence
    my ( $hash_ref, $eps ) = @_;
    my ( $u, $v, $w, $j, $k, $sum );
	my ( $max, $max2, $wmax );
	
	my @price;          # price[i] of object i
    my @assign_index;   # assign_index[target] = -1 if not assigned = source if assigned
    my @assign_weigth;  # assign_weigth[target]=  ? if not assigned = weigth of edge source-target if assigned

    for my $v ( 0 .. $g{'M'} - 1 ) {
	   $assign_index[$v] = -1;
    }
	
	my $n_set = $g{'N'};
	my @l_set;

	for my $u ( 0 .. $n_set - 1 ) {
       $l_set[$u] = $u;
    }
	
    $sum = 0;
	
	# se os preços antes e após as iterações não mudarem, teremos chegado a uma solução estável.
	# nesta situação, $max2 = 0 após as iterações.

    #print "\n 1 iter_count = $iter_count ; result = $sum ; eps = $eps ; max_matrix_value = $g{'max_matrix_value'} \n";	
	
	while ( $n_set > 0 ){
		$u   = $l_set[$n_set-1];		
		$max = 0;		
		$iter_count++;
		
		for my $i ( $g{'cd'}[$u] .. $g{'cd'}[$u+1] - 1 ){
			$v = $g{'adj'}[$i];
			$w = $g{'w'}[$i];
            $price[$v] = 0 if ( not defined $price[$v] );			
			if ( $w - $price[$v] > $max  ){
				$max  = $w - $price[$v];
				$wmax = $w;
				$k    = $v;  # $k is the best object value
			}			
		}
		
		if ( $max == 0 ){
			$n_set--;           
			next;
		}
				
		$max2 = 0;
		
		for my $i ( $g{'cd'}[$u] .. $g{'cd'}[$u+1] - 1 ){
			$v = $g{'adj'}[$i];			
			if ( $v != $k ){
				$w = $g{'w'}[$i];	#  $v is the second best object value			
				if ( $w - $price[$v] > $max2 ){
					$max2 = $w - $price[$v];
				}			
			}
		}

		$price[$k] += $max - $max2 + $eps;

		if ( $assign_index[$k] != -1 ){
			$l_set[$n_set-1] = $assign_index[$k];
			$sum -= $assign_weigth[$k];			
		}
		else{
			$n_set--;
		}

		$assign_index[$k]  = $u;
		$assign_weigth[$k] = $wmax;
		$sum += $wmax;
	}

	$j = 0;	# assignement count
	for my $i ( 0 .. $g{'M'} - 1 ) {
		if ( $assign_index[$i] != -1 ){
			$g{'edges'}[$j  ]{'u'} = $assign_index[$i];			
			$g{'edges'}[$j  ]{'v'} = $i;			
			$g{'edges'}[$j++]{'w'} = $assign_weigth[$i];
		}
	}
	
	$g{'N_assignment'} = 1 if ( $j == $g{'N'} - 1 );	
	$max2 = 'optional_prices' if ( not defined $max2 );	
	#print " 2 iter_count = $iter_count ; \$g{'N_assignment'} = $g{'N_assignment'} ; result = $sum ; eps = $eps ; max_matrix_value = $g{'max_matrix_value'} ; max = $max ; max2 = $max2 \n";

	splice @{$g{'edges'}}, $j if ( @{$g{'edges'}} > 1 );
	return $sum;
}

sub maximum {
  my ( $v1, $v2 ) = @_;
  my $max = $v1 > $v2 ? $v1 : $v2 ;
  return $max;
}

1;  # don't forget to return a true value from the file

__END__

=head1 NAME

    Algorithm::Bertsekas - auction algorithm for the assignment problem.
	
	This is an efficient perl implementation of the Auction algorithm 
	for the assignement problem such as detailed in: D.P. Bertsekas, A distributed algorithm 
	for the assignment problem, Laboratory for Information and Decision Systems Working 
	Paper (M.I.T., March 1979).
	
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

 my @array1 = ( 4.97, 8.87, 7.08, 8.34, 5.29, 6.23, 5.24 );
 my @array2 = ( 3.57, 8.01, 7.92, 2.31 );
 
 my $min_size = $#array1 < $#array2 ? $#array1 : $#array2;
 my $max_size = $#array1 > $#array2 ? $#array1 : $#array2;

 for my $i ( 0 .. $#array1 ){
   my @weight_function;		   
   for my $j ( 0 .. $#array2 ){
      my $weight = abs ($array1[$i] - $array2[$j]);
      #  $weight =     ($array1[$i] - $array2[$j]) ** 2;  # another option
      push @weight_function, $weight;
   }
   push @input_matrix, \@weight_function;
 } 
 
        3.57 8.01 7.92 2.31

 4.97 [ 1.40 3.04 2.95 2.66 ]
 8.87 [ 5.30 0.86 0.95 6.56 ]
 7.08 [ 3.51 0.93 0.84 4.77 ]
 8.34 [ 4.77 0.33 0.42 6.03 ]
 5.29 [ 1.72 2.72 2.63 2.98 ]
 6.23 [ 2.66 1.78 1.69 3.92 ]
 5.24 [ 1.67 2.77 2.68 2.93 ]

 @input_matrix = (
 [ 1.40, 3.04, 2.95, 2.66 ],
 [ 5.30, 0.86, 0.95, 6.56 ],
 [ 3.51, 0.93, 0.84, 4.77 ],
 [ 4.77, 0.33, 0.42, 6.03 ],
 [ 1.72, 2.72, 2.63, 2.98 ],
 [ 2.66, 1.78, 1.69, 3.92 ],
 [ 1.67, 2.77, 2.68, 2.93 ]
 );

#my ( $optimal, $assignement_ref, $output_index_ref ) = auction( matrix_ref => \@input_matrix, maximize_total_benefit => 1, verbose => 1, stepsize => 0.1 );
 my ( $optimal, $assignement_ref, $output_index_ref ) = auction( matrix_ref => \@input_matrix, maximize_total_benefit => 0, verbose => 3 );

Objective: to minimize the total benefit or to find the nearest neighbors
 Number of left nodes: 7
 Number of right nodes: 4
 Number of edges: 28

Solution:
 Optimal assignment: sum of values = 5.61

Maximum index size    = [   0    1    2    3    4    5    6 ]
@output_index indexes = [   3    1    4    2    5    6    0 ]
@output_index values  = [2.66 0.86      0.42           1.67 ]

 [ 1.40   3.04   2.95   2.66**]
 [ 5.30   0.86** 0.95   6.56  ]
 [ 3.51   0.93   0.84   4.77  ]
 [ 4.77   0.33   0.42** 6.03  ]
 [ 1.72   2.72   2.63   2.98  ]
 [ 2.66   1.78   1.69   3.92  ]
 [ 1.67** 2.77   2.68   2.93  ]

 Pairs (in ascending order of weight function values):
   indexes ( 3, 2 ), weight value = 0.42 ; sum of values = 0.42
   indexes ( 1, 1 ), weight value = 0.86 ; sum of values = 1.28
   indexes ( 6, 0 ), weight value = 1.67 ; sum of values = 2.95
   indexes ( 0, 3 ), weight value = 2.66 ; sum of values = 5.61
   indexes ( 2, 4 ), weight value =      ; sum of values = 5.61
   indexes ( 4, 5 ), weight value =      ; sum of values = 5.61
   indexes ( 5, 6 ), weight value =      ; sum of values = 5.61
   
 foreach my $array1_index ( sort { $a <=> $b } keys %{$assignement_ref} ){     
   my $i = $array1_index;
   my $j = $assignement_ref->{$array1_index};   
   ...
 }
 
 Auction Algorithm, assignement hash --> $i =   0 e $value1 = 4.97; $j =   3 e $value2 = 2.31 ; difference = 2.66 ; sum = 2.66
 Auction Algorithm, assignement hash --> $i =   1 e $value1 = 8.87; $j =   1 e $value2 = 8.01 ; difference = 0.86 ; sum = 3.52
 Auction Algorithm, assignement hash --> $i =   3 e $value1 = 8.34; $j =   2 e $value2 = 7.92 ; difference = 0.42 ; sum = 3.94
 Auction Algorithm, assignement hash --> $i =   6 e $value1 = 5.24; $j =   0 e $value2 = 3.57 ; difference = 1.67 ; sum = 5.61
 
 for my $i (0 .. $max_size){
   my $j = $output_index_ref->[$i];
   ...
 }
 
 Auction Algorithm, output_index array --> $i =   0 e $value1 = 4.97; $j =   3 e $value2 = 2.31 ; difference = 2.66 ; sum = 2.66
 Auction Algorithm, output_index array --> $i =   1 e $value1 = 8.87; $j =   1 e $value2 = 8.01 ; difference = 0.86 ; sum = 3.52
 Auction Algorithm, output_index array --> $i =   2 e $value1 = 7.08; $j =   4 e $value2 =      ; difference =      ; sum = 3.52
 Auction Algorithm, output_index array --> $i =   3 e $value1 = 8.34; $j =   2 e $value2 = 7.92 ; difference = 0.42 ; sum = 3.94
 Auction Algorithm, output_index array --> $i =   4 e $value1 = 5.29; $j =   5 e $value2 =      ; difference =      ; sum = 3.94
 Auction Algorithm, output_index array --> $i =   5 e $value1 = 6.23; $j =   6 e $value2 =      ; difference =      ; sum = 3.94
 Auction Algorithm, output_index array --> $i =   6 e $value1 = 5.24; $j =   0 e $value2 = 3.57 ; difference = 1.67 ; sum = 5.61
 
=head1 OPTIONS
 
 matrix_ref => \@input_matrix     reference to array: matrix N x M.
 stepsize => 0.1                  by default stepsize = 1 / ( min(N,M) + 1 ). 
                                  There is a trade-off between runtime and the chosen stepsize.
								  Using the largest possible increment accelerates the algorithm.
 maximize_total_benefit => 0      0: minimize the total benefit ; 1: maximize the total benefit.
 verbose  => 3                    print messages on the screen, level of verbosity, 0: quiet; 1, 2, 3: full information.

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

    1. Dimitri P. Bertsekas, A distributed algorithm for the assignment problem, 
	   Laboratory for Information and Decision Systems Working Paper (M.I.T., March 1979).
	   
	2. Dimitri P. Bertsekas, Auction algorithms for network flow problems: 
	   A tutorial introduction - Comput Optim Applic (1992). 
	   https://doi.org/10.1007/BF00247653
	
	3. Maximilien Danisch, Efficient C implementation of the auction algorithm.
	   https://github.com/maxdan94/auction
	   This perl algorithm was adapted from this C algorithm.
	      
	4. https://en.wikipedia.org/wiki/Assignment_problem


=head1 AUTHOR

    Claudio Fernandes de Souza Rodrigues
	February 2018
	Sao Paulo, Brasil
	claudiofsr@yahoo.com

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=cut