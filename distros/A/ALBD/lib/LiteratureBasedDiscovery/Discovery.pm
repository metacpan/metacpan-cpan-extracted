# ALBD::Disovery
#
# Perl module for performing Literature Based Discovery based using
# CUI associations as the primary linking and ranking method.
#
# Copyright (c) 2017
#
# Sam Henry
# henryst at vcu.edu
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to
#
# The Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330,
# Boston, MA  02111-1307, USA.

package Discovery;
use strict;
use warnings;
use DBI;

######################################################################
#                        MySQL Notes
######################################################################
#TODO I think some of these notes should be elsewhere
# A Note about the database structure expected
#   Each LBD database is expected to have:
#   PreCutoff_N11
#   PostCutoff_N11
#   PreCutoff_Implicit
#
# Both PreCutoff_N11 and PostCutoff_N11 should
# be generated manually using CUI_Collector
# PreCutoff_Implicit is generated using the tableToSparseMatrix
# function here, which exports a sparse matrix. That matrix 
# can then be imported into matlab, squared, and reloaded into
# a mysql database. With these 3 tables LBD can be performed


######################################################################
#                          Description
######################################################################
# Discovery.pm - provides matrix operations from  n11 counts from 
# UMLS::Association
#
#TODO I think some of these notes should be elsewhere
# 'B' term filtering may be applied by removing elements from the 
# explicit knowledge matrix before squaring. It is important to 
# replicate the original matrix before filtering so that explicit 
# knowledge can be removed from the implicit matrix.
# 'C' term filtering may be applied directly to the implicit
# knowledge matrix.
#
# A Typical workflow may look like:
# 1) load explicit knowledge from UMLS::Association
# 2) clone explicit knowledge (for removal from implicit)
# 3) apply filtering to explicit knowledge
# 4) square explicit knowledge to generate implicit knowledge
# 5) remove explicit knowledge from implicit knowledge
# 6) filter impicit knowledge
# 
# which has code as:
# TODO insert sample code

#NOTE: CUI merging/term expansion can also be easily done by adding
#   two or more explicit vectors, then generating explicit knowledge from
#   them.  BUT also interesting is that term expansion, etc... is 
#   unnecassary if we just rank against every term. We may however need 
#   to modify the ranking metrics to account for synonyms, etc.. (max value
#   of a set of synonyms or something)


######################################################################
#           Functions to perform Literature Based Discovery
######################################################################


# gets the rows of the cuis from the matrix
# input:  $cuisRef <- an array reference to a list of CUIs
#         $matrixRef <- a reference to a co-occurrence matrix
# output: a hash ref to a sparse matrix containing just the rows retrieved
sub getRows {
    my $cuisRef = shift;
    my $matrixRef = shift;

    my %rows = ();
    my $rowRef;
    #add each cui row to the starting matrix
    foreach my $cui(@{$cuisRef}) {
	#if there is a row for this cui
	if (exists ${$matrixRef}{$cui}) {
	    $rowRef = ${$matrixRef}{$cui};

	    #add each row value to the starting matrix
	    foreach my $key(keys %{$rowRef}) {
		${$rows{$cui}}{$key} = ${$rowRef}{$key};
	    }
	}
    }
    return \%rows;
}


#NOTE...this is calculating B*A ... but is that appropriate?  ... I think that it is, but the values are maybe not so appropriate    ... B*A is nice because it makes the implicit matrix not keep track of non-starting cui rows.   ...but the values are pretty much meaninigless when I do it that way...so If I care about the values I should multiply A*A  ... or maybe B*A ... its something I'd have to really think about  ...anyway If I do any method but this, I would want to eliminate rows after multiplication

# finds the implicit connections for all CUIs (based on squaring)
# It does this by multiplying $matrixB*$matrixA. If $matrix B is the starting
# matrix, and $matrixA is the explicitMatrix, this method works correctly and
# efficiently. $matrixA and $matrixB may also be the explicit matrix but
# this is more inefficient.
# input:  $matrixARef <- ref to a sparse matrix
#         $matrixBRef <- ref to a sparse matrix
# output: ref to a sparse matrix of the product of B*A
sub findImplicit {
    my $matrixARef = shift; 
    my $matrixBRef = shift;

    my %product = ();
    #loop over the rows of the B matrix
    foreach my $key0 (keys %{$matrixBRef}) {  

	#loop over row
	foreach my $key1 (keys %{$matrixARef}) {	

	    #loop over column
	    foreach my $key2 (keys %{${$matrixARef}{$key1}}) {
		#update values
		if (exists ${${$matrixBRef}{$key0}}{$key1}) {

		    #update
		    if (!exists ${$product{$key0}}{$key2}) {
			${$product{$key0}}{$key2} = 0;			
		    }
		    ${$product{$key0}}{$key2} += 
			${${$matrixBRef}{$key0}}{$key1} * 
			${${$matrixARef}{$key1}}{$key2};
		    
		}
	    }
	}
    }
    return \%product;
}


# removes explicit connections from the matrix of implicit connections by 
# removing keys (O(k), where k is the number of keys in the explicit matrix,
# we expect the explicit k to be smaller than the implicit k)
# input: $explicitMatrixRef <- reference to the explicit knowledge matrix
#        $implicitMatrixRef <- reference to the implicit knowledge matrix
# output: ref to the implicit matrix with explicit knowledge removed
sub removeExplicit {
    my $explicitMatrixRef = shift;
    my $implicitMatrixRef = shift;

    #Check each key of the explicit matrix to see if it exists
    # in the implicit matrix
    foreach my $key1(keys %{$explicitMatrixRef}) {
	if (exists ${$implicitMatrixRef}{$key1}) {
	    foreach my $key2(keys %{${$explicitMatrixRef}{$key1}}) {
		if (exists ${${$implicitMatrixRef}{$key1}}{$key2}) {
		    delete ${${$implicitMatrixRef}{$key1}}{$key2};
		}
	    }
	}
    }
    return $implicitMatrixRef;
}


# loads a tab seperated file as a sparse matrix (a hash of hashes)
#    each line of the file contains CUI1 <TAB> CUI2 <TAB> Count
# input:  the filename containing the data
# output: a hash ref to the sparse matrix (${$hash{$index1}}{$index2} = value)
sub fileToSparseMatrix {
    my $fileName = shift;

    open IN, $fileName or die ("unable to open file: $fileName\n");
    my %matrix = ();
    my ($cui1,$cui2,$val);
    while (my $line = <IN>) {
	chomp $line;
	($cui1,$cui2,$val) = split(/\t/,$line);
	
	if (!exists $matrix{$cui1}) {
	    my %hash = ();
	    $matrix{$cui1} = \%hash;
	}
	$matrix{$cui1}{$cui2} = $val;
    }
    close IN;
    return \%matrix;
}

# outputs the matrix to the output file in sparse matrix format, which
# is a file containing rowKey\tcolKey\tvalue
# input:  $outFile - a string specifying the output file
#         $matrixRef - a ref to the sparse matrix containing the data
# output: nothing, but the matrix is output to file
sub outputMatrixToFile {
    my $outFile = shift;
    my $matrixRef = shift;
    
    #open the output file and output fhe matrx
    open OUT, ">$outFile" or die ("Error opening matrix output file: $outFile\n");
    my $rowRef;
    foreach my $rowKey (keys %{$matrixRef}) {
	$rowRef = ${$matrixRef}{$rowKey};
	foreach my $colKey (keys %{$rowRef}) {
	    print OUT "$rowKey\t$colKey\t${$rowRef}{$colKey}\n";
	}
    }
}


#Note: Table to sparse is no longer used, but could be useful in the future
=comment
#  retreive a table from mysql and convert it to a sparse matrix (a hash of 
#     hashes)
#  input : $tableName <- the name of the table to output
#          #cuiFinder <- an instance of UMLS::Interface::CuiFinder
#  output: a hash ref to the sparse matrix (${$hash{$index1}}{$index2} = value)
sub tableToSparseMatrix {
    my $tableName = shift;
    my $cuiFinder = shift;

    # check tableName
    #TODO check that the table exists in the database
    # or die "Error: table does not exist: $tableName\n";

    #  set up database
    my $db = $cuiFinder->_getDB(); 
    
    # retreive the table as a nested hash where keys are CUI1, 
    # then CUI2, value is N11
     my @keyFields = ('cui_1', 'cui_2');
     my $matrixRef = $db->selectall_hashref(
	"select * from $tableName", \@keyFields);

    # set values of the loaded table to n_11
    # ...default is hash of hash of hash
    foreach my $key1(keys %{$matrixRef}) {
	foreach my $key2(keys %{${$matrixRef}{$key1}}) {
	    ${${$matrixRef}{$key1}}{$key2} = ${${${$matrixRef}{$key1}}{$key2}}{'n_11'};
	}
    }
    return $matrixRef;
}
=cut

1;
