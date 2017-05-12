package Algorithm::RandomMatrixGeneration;

use 5.006;
use strict;
use warnings;
use Math::BigFloat;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw( generateMatrix );

our $VERSION = '0.06';

# add check for type of marginal values
# modify output format to sparse.

sub generateMatrix
{
	my $ref_rmar = shift;
 	my $ref_cmar = shift;

	my $precision = shift;
	my $seed = shift;

	my @tmp_rmar = @$ref_rmar;
	my @tmp_cmar = @$ref_cmar;

	my $n = $#tmp_rmar;
	my $m = $#tmp_cmar;

	# error checks
	if(!$n)
	{
		print STDERR "No row marginals provided.\n";
		exit 1;
	}

	if(!$m)
	{
		print STDERR "No column marginals provided.\n";
		exit 1;
	}

	if(!$precision)
	{
		print STDERR "Precision not provided.\n";
		exit 1;
	}

	if(defined $seed)
	{
		srand($seed);
	}

	# find the type of marginals values: integers/real
	# assume integer and loop through row and col marginals.
	# check each value for decimal values.
	# break on first occurrence of real number.
	my $format = "integer";

	# also find if any of the marginal is negative
	# assume positive and then loop through to find a contradiction
	my $signValues = "positive";

	# for each row (0..n)
	for(my $i=0; $i<=$n; $i++)
	{
		if($tmp_rmar[$i] =~ /\.0*[1-9]+/)
		{
			$format = "real";
			if($signValues eq "negative")
			{
				last;
			}
		}
		if($tmp_rmar[$i] =~ /^-/)
		{
			$signValues = "negative";
			if($format eq "real")
			{
				last;
			}
		}
	}

	if($format eq "integer" || $signValues eq "positive")
	{
		# for each col (0..m)
		for(my $j=0; $j<=$m; $j++)
		{
			if($tmp_cmar[$j] =~ /\.0*[1-9]+/)
			{
				$format = "real";
				if($signValues eq "negative")
				{
					last;
				}
			}
			if($tmp_cmar[$j] =~ /^-/)
			{
				$signValues = "negative";
				if($format eq "real")
				{
					last;
				}
			}
		}
	}

	my $fmt_str;
	my $add_str;
	my $regex;

	if($format eq "real")
	{
		if($precision !~ /^[0-9]+$/)
		{
			print STDERR "Please specify integer value for precision.\n";
			exit 1;
		}

		# for precision
		$fmt_str = "%.$precision" . "f";
			
		$add_str = "0.";
		for(my $i=1; $i<$precision; $i++)
		{
			$add_str .= "0";
		}
		$add_str .= "1";
			
		$regex = "(\\d+\\.?\\d{0,$precision})"; 
	}

	# array to hold the generated matrix
	my @ref = ();

	my $rem_col_marg = 0;
	
	# for each cell C(i,j)
	# for each row (0..n)
	for(my $i=0; $i<=$n; $i++)
	{
		# for each col (0..m)
		for(my $j=0; $j<=$m; $j++)
		{
			# compute the min and max (range) for the cell value
			
			# max = MIN(row_marg[i], col_marg[j])
			my $max = $tmp_rmar[$i];
			if($tmp_cmar[$j] < $max)
			{
				$max = $tmp_cmar[$j];
			}
			
			# if max = 0 then min = 0
			# else assign min a value based on the remaining row_marginal and col_marginals to be satisfied
			my $min = 0;
			if($max != 0)
			{
				# sum-up the col_marginals for all the columns beyond the current column
				$rem_col_marg = 0;
				for(my $k=$j+1; $k<=$m; $k++)
				{
					$rem_col_marg = $rem_col_marg + $tmp_cmar[$k];
				}
				
				# based on the row_marg and the sum_of_col_marg decide the value for min
				$min = $tmp_rmar[$i] - $rem_col_marg;

				if($signValues eq "positive")
				{
					if($min < 0)
					{
						$min = 0;
					}
				}
			}
			else
			{
				$min = $max;
			}   
			
			if($format eq "real")
			{
				$min = sprintf($fmt_str, $min);
				$max = sprintf($fmt_str, $max);
			}

			if($signValues eq "negative")
			{
				if($min > $max)
				{
					my $tmp_min = $min;
					$min = $max;
					$max = $tmp_min;
				}
			}

			my $rand_num = 0;
			if($min != $max)
			{
				# generate a random number between the min and max (range)
				if($format eq "real")
				{
					my $rand_max = $max-$min+$add_str;
					$rand_num = rand($rand_max);

					my $bigfloat = Math::BigFloat->new($rand_num);
					my $rand_num_str = $bigfloat->bstr();
					
					$rand_num_str =~/$regex/;
					$rand_num = $1;					
				}
				else
				{
					my $rand_max = $max-$min+1;
					$rand_num = int(rand($rand_max));
				}

				$rand_num += $min;
			}
			else
			{
				$rand_num = $min;
			}			
			
			if($signValues eq "negative")
			{
				#last col of the row
				if($j == $m)
				{
					$rand_num = $tmp_rmar[$i];
				}
				
				#last row of the cols
				if($i == $n)
				{
					$rand_num = $tmp_cmar[$j];
				}
			}

			if($format eq "real")
			{
				my $val = sprintf($fmt_str,$rand_num);

				if($val !~ /^0\.?0*$/)
				{
					$ref[$i][$j] = $val;

					# adjust the marginals
					$tmp_rmar[$i] = sprintf($fmt_str, $tmp_rmar[$i] - $ref[$i][$j]);
					$tmp_cmar[$j] = sprintf($fmt_str, $tmp_cmar[$j] - $ref[$i][$j]);
				}
		
			}
			else
			{
				if($rand_num)
				{
					$ref[$i][$j] = $rand_num;
					
					# adjust the marginals
					$tmp_rmar[$i] = $tmp_rmar[$i] - $ref[$i][$j];
					$tmp_cmar[$j] = $tmp_cmar[$j] - $ref[$i][$j];
				}
			}
		}
	}

	return @ref;
}

1;
__END__

=head1 NAME

Algorithm::RandomMatrixGeneration - Generate internal cell values for a matrix given fixed marginal totals.  

=head1 SYNOPSIS

  use Algorithm::RandomMatrixGeneration;
  my @result = generateMatrix(\@row_marginals, \@col_marginals);

=head2 Example: Negative Integer Valued Marginals:

  use Algorithm::RandomMatrixGeneration;
  my @rmar = ('-5','5','-3');
  my @cmar = ('2','3','-2','-6');
  my @result = generateMatrix(\@rmargs, \@cmargs, "-");
	
  Output matrix could be:
  0 -1 1 3 2 -5 3 -2
  0 5
  0 -2 2 3 3 -4

=head2 Example: Positive Real Valued Marginals:

  use Algorithm::RandomMatrixGeneration;
  my @rmargs = (13.01,11,13,13,12,13);
  my @cmargs = (23.005,32.005,10,10);
  my @result = generateMatrix(\@rmargs, \@cmargs, 3);
	
  Output matrix could be:
  0 2.694  1 9.665  2 0.393  3 0.258
  0 6.539  1 0.910  2 2.209  3 1.342
  0 8.469  1 3.565  2 0.839  3 0.127
  0 2.719  1 2.748  2 0.604  3 6.929
  0 0.946  1 3.771  2 5.939  3 1.344
  0 1.638  1 11.346  2 0.016

=head1 INPUTS

The generateMatrix function can take 4 parameters:

=over 4

=item 1. Single dimensional array containing row marginals (Can be real valued or integers)
=item 2. Single dimensional array containing column marginals (Can be real valued or integers)
=item 3. Precision: For the integer valued marginal specifying "-". For real valued marginals specify the required precision for the generated matrix values. (Recommended Precision = 4)
=item 4. Seed: Seed for the random number generator (Default: None) (Optional parameter)
=back

=head1 OUTPUT

The generateMatrix function returns a two dimensional array containing the generated random matrix.
The generated matrix is stored in sparse format in this returned array. That is, only non-zero values 
are stored in this matrix. Thus to access the values in the returned matrix one can use: 

  for(my $row=0; $i<=$num_rows; $i++)
  {
	  for(my $col=0; $j<=$num_cols; $j++)
	  {
		  if(defined $returned_matrix[$row][$col])
		  {
			  print "$col $returned_matrix[$row][$col]  ";
		  }
	  }
	  print "\n";
  }	

=head1 DESCRIPTION

This module generates a random matrix given the row and column marginals in such a way that 
the row and column marginals of the resultant matrix are same as the given marginals.

If the given marginals are real valued then the generated cell values are real too. If the
given marginals are integer valued then the generated cell values are integers. If any of 
the marginals are negative then few/all of the generated cell values would be negative too.

=head1 FURTHER DETAILS

For example, given the following marginals this module would generate the appropriate 
values for "x"s such that the row and the column marginals are held fixed.

  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  ------------------------------
  2    2    2    2    2    |  10

The algorithm we have used here:
For each cell while traversing the matrix in in row-major interpretation.
    1. Generate random number using the steps given below.
    2. Reduce row and column marginals by value of generated value.
End for.
Done.

Random number generation algorithm:
for each cell C(i,j)
{
    # Find the range (min, max) for the random number generation
    max = MIN(row_marg[i], col_marg[j])

    # If max !=0 then decide the min.
    # To decide min value sum together the col_marginals for all
    # the columns past the current column - this sum gives the total
    # of the column marginals yet to be satisfied beyond the current col.
    # Subtract this sum from the current row_marginal to compute
    # the lower bound on the random number. We do this because if we
    # do not set this lower bound and thus a number smaller than this
    # bound is generated then we will have a situation where satisfying
    # both row_marginal and column marginals will be impossible.

    if(max != 0)
    {
        2_term = 0
        for each col k > j
        {
            2_term = 2_term + col_marg[k]
        }
        min = row_marg[i] - 2_term
		if(marginals positive)
		{
        	if(min < 0)
        	{
            	min = 0
        	}
		}
    }
    else
    {
        min = max = 0   # If max = 0 then min = 0
    }

    # Generate random number between the range   
    random_num = rand(min, max)
}

Example:

  Cell 0:
  max = MIN(3,2) = 2
  2_term = 2 + 2 + 2 + 2 = 8
  min = 3 - 8 = -5
  therefore: min = 0
  (min, max) = (0,2) = 0
  0    x    x    x    x    |  3
  x    x    x    x    x    |  2
  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  ----------------------------------------------
  2    2    2    2    2    |

  Cell 1:
  max = MIN(3,2) = 2
  2_term = 2 + 2 + 2 = 6
  min = 3 - 6 = -3
  therefore: min = 0
  (min, max) = (0,2) = 0
  0    0    x    x    x    |  3
  x    x    x    x    x    |  2
  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  ----------------------------------------------
  2    2    2    2    2    |

  Cell 2:
  max = MIN(3,2) = 2
  2_term = 2 + 2 = 4
  min = 3 - 4 = -1
  therefore: min = 0
  (min, max) = (0,2) = 0
  0    0    0    x    x    |  3
  x    x    x    x    x    |  2
  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  ----------------------------------------------
  2    2    2    2    2    |

  Cell 3:
  max = MIN(3,2) = 2
  2_term = 2
  min = 3 - 2 = 1
  (min, max) = (1,2) = 1
  0    0    0    1    x    |  2
  x    x    x    x    x    |  2
  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  ----------------------------------------------
  2    2    2    1    2    |

  Cell 4:
  max = MIN(2,2) = 2
  2_term = 0
  min = 2 - 0 = 2
  (min, max) = (2,2) = 2
  0    0    0    1    2    |  0
  x    x    x    x    x    |  2
  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  ----------------------------------------------
  2    2    2    1    0    |

  Cell 5:
  max = MIN(2,2) = 2
  2_term = 2 + 2 + 1 + 0 = 5
  min = 3 - 5 = -2
  therefore, min = 0
  (min, max) = (0,2) = 1
  0    0    0    1    2    |  0
  1    x    x    x    x    |  1
  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  ----------------------------------------------
  1    2    2    1    0    |

  Cell 6:
  max = MIN(1,2) = 1
  2_term = 2 + 1 + 0 = 3
  min = 1 - 3 = -2
  therefore, min = 0
  (min, max) = (0,1) = 0
  0    0    0    1    2    |  0
  1    0    x    x    x    |  1
  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  ----------------------------------------------
  1    2    2    1    0    |

  Cell 7:
  max = MIN(1,2) = 1
  2_term = 1 + 0 = 1
  min = 1 - 1 = 0
  (min, max) = (0,1) = 1
  0    0    0    1    2    |  0
  1    0    1    x    x    |  0
  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  ----------------------------------------------
  1    2    1    1    0    |

  Cell 8:
  max = MIN(0,1) = 0
  min = 0
  (min, max) = (0,0) = 0
  0    0    0    1    2    |  0
  1    0    1    0    x    |  0
  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  ----------------------------------------------
  1    2    1    1    0    |

  Cell 9:
  max = MIN(0,0) = 0
  min = 0
  (min, max) = (0,0) = 0
  0    0    0    1    2    |  0
  1    0    1    0    0    |  0
  x    x    x    x    x    |  3
  x    x    x    x    x    |  2
  ----------------------------------------------
  1    2    1    1    0    |

  Cell 10:
  max = MIN(3,1) = 1
  2_term = 2 + 1 + 1 + 0 = 4
  min = 3 - 4 = -1
  therefore, min = 0
  (min, max) = (0,1) = 1
  0    0    0    1    2    |  0
  1    0    1    0    0    |  0
  1    x    x    x    x    |  2
  x    x    x    x    x    |  2
  ----------------------------------------------
  0    2    1    1    0    |

  Cell 11:
  max = MIN(2,2) = 2
  2_term = 1 + 1 + 0 = 2
  min = 2 - 2 = 0
  (min, max) = (0,2) = 0
  0    0    0    1    2    |  0
  1    0    1    0    0    |  0
  1    0    x    x    x    |  2
  x    x    x    x    x    |  2
  ----------------------------------------------
  0    2    1    1    0    |

  Cell 12:
  max = MIN(2,1) = 1
  2_term = 1 + 0 = 1
  min = 2 - 1 = 1
  (min, max) = (1,1) = 1
  0    0    0    1    2    |  0
  1    0    1    0    0    |  0
  1    0    1    x    x    |  1
  x    x    x    x    x    |  2
  ----------------------------------------------
  0    2    0    1    0    |

  Cell 13:
  max = MIN(1,1) = 1
  2_term = 0 = 0
  min = 1 - 0 = 1
  (min, max) = (1,1) = 1
  0    0    0    1    2    |  0
  1    0    1    0    0    |  0
  1    0    1    1    x    |  0
  x    x    x    x    x    |  2
  ----------------------------------------------
  0    2    0    0    0    |

  Cell 14:
  max = MIN(0,0) = 0
  min = 0
  (min, max) = (0,0) = 0
  0    0    0    1    2    |  0
  1    0    1    0    0    |  0
  1    0    1    1    0    |  0
  x    x    x    x    x    |  2
  ----------------------------------------------
  0    2    0    0    0    |

  Cell 15:
  max = MIN(2,0) = 0
  min = 0
  (min, max) = (0,0) = 0
  0    0    0    1    2    |  0
  1    0    1    0    0    |  0
  1    0    1    1    0    |  0
  0    x    x    x    x    |  2
  ----------------------------------------------
  0    2    0    0    0    |

  Cell 16:
  max = MIN(2,2) = 2
  2_term = 0 + ... = 0
  min = 2 - 0 = 2
  (min, max) = (2,2) = 2
  0    0    0    1    2    |  0
  1    0    1    0    0    |  0
  1    0    1    1    0    |  0
  0    2    x    x    x    |  0
  ----------------------------------------------
  0    0    0    0    0    |

  Cell 17:
  max = MIN(0,0) = 0
  min = 0
  (min, max) = (0,0) = 0
  0    0    0    1    2    |  0
  1    0    1    0    0    |  0
  1    0    1    1    0    |  0
  0    2    0    x    x    |  0
  ----------------------------------------------
  0    0    0    0    0    |

  Cell 18:
  max = MIN(0,0) = 0
  min = 0
  (min, max) = (0,0) = 0
  0    0    0    1    2    |  0
  1    0    1    0    0    |  0
  1    0    1    1    0    |  0
  0    2    0    0    x    |  0
  ----------------------------------------------
  0    0    0    0    0    |

  Cell 19:
  max = MIN(0,0) = 0
  min = 0
  (min, max) = (0,0) = 0
  0    0    0    1    2    |  0
  1    0    1    0    0    |  0
  1    0    1    1    0    |  0
  0    2    0    0    0    |  0
  ----------------------------------------------
  0    0    0    0    0    |

  Done!!

=head2 EXPORT

generateMatrix

=head1 AUTHOR

 Anagha Kulkarni, Carnegie-Mellon University
 anaghak at cs.cmu.edu

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by Anagha Kulkarni, Ted Pedersen

This library is free software; you can redistribute it and/or
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
