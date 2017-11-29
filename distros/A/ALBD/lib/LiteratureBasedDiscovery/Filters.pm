# ALBD::Filters
#
# Perl module for applying Literature Based Discovery filters
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

package Filters;
use strict;
use warnings;

use UMLS::Interface;

# applies a semantic group filter to the matrix, by removing keys that 
# are not allowed semantic type. Eliminates both rows and columns, so
# is applied to the full explicit matrix
# input:  $matrixRef <- ref to a sparse matrix to be filtered
#         $acceptTypesRef <- a ref to a hash of accept type strings
#         $umls <- an instance of UMLS::Interface
# output: None, but $vectorRef is updated 
sub semanticTypeFilter_rowsAndColumns {
    my $matrixRef = shift;
    my $acceptTypesRef = shift;
    my $umls = shift;
 
=comment   
    #Count the number of keys before and after filtering (for debugging)
    my %termsHash = ();
    foreach my $key1 (keys %{$matrixRef}) {
	foreach my $key2 (keys %{${$matrixRef}{$key1}}) {
	    $termsHash{$key2} = 1;
	}
    }
    print "   number of keys before filtering = ".(scalar keys %termsHash)."\n";
=cut

    #eliminate values that are incorrect semantic groups
    #do each row at a time, remove column values that 
    #are the incorrect semantic type
    my %cuisChecked = ();
    #cuisChecked keeps track of cuis that have been checked 
    # for elimination. If the cui has been checked its key
    # will exist in the hash. Values of -1 indicate it should
    # be eliminated, values of 1 indicate it should stay.

    #eliminate cuis from rows
    foreach my $cui (keys %{$matrixRef}) {
	#update cui checked hash
	if (!exists $cuisChecked{$cui}) {
	    $cuisChecked{$cui} = -1;

	    my $typesRef = $umls->getSt($cui);
	    foreach my $type(@{$typesRef}) {
		my $abr = $umls->getStAbr($type);

		#check the cui for removal
		if (exists ${$acceptTypesRef}{$type}) {
		    $cuisChecked{$cui} = 1;
		    last;
		}
	    }
	}

	#eliminate if needed
	if ($cuisChecked{$cui} < 0) {
	    delete ${$matrixRef}{$cui};
	}
    }

    #eliminate cuis from columns
    foreach my $cui1 (keys %{$matrixRef}) {
	foreach my $cui2 (keys %{${$matrixRef}{$cui1}}) {
	    #update cui checked hash
	    if (!exists $cuisChecked{$cui2}) {
		$cuisChecked{$cui2} = -1;

		my $typesRef = $umls->getSt($cui2);
		foreach my $type(@{$typesRef}) {
		    my $abr = $umls->getStAbr($type);

		    #check the cui for removal
		    if (exists ${$acceptTypesRef}{$type}) {
			$cuisChecked{$cui2} = 1;
			last;
		    }
		}
	    }

	    #eliminate if needed
	    if ($cuisChecked{$cui2} < 0) {
		delete ${${$matrixRef}{$cui1}}{$cui2};
	    }
	}
    }


=comment
    #Count the number of keys after filtering (for debugging)
    %termsHash = ();
    foreach my $key1 (keys %{$matrixRef}) {
	foreach my $key2 (keys %{${$matrixRef}{$key1}}) {
	    $termsHash{$key2} = 1;
	}
    }
    print "   number of keys after filtering = ".(scalar keys %termsHash)."\n";
=cut
}


# applies a semantic group filter to the matrix, by removing keys that 
# are not allowed semantic type. Only removes types from rows, 
# so is applied for times slicing, before randomly selecting terms of 
# one semantic type
# input:  $matrixRef <- ref to a sparse matrix to be filtered
#         $acceptTypesRef <- a ref to a hash of accept type strings
#         $umls <- an instance of UMLS::Interface
# output: None, but $vectorRef is updated 
sub semanticTypeFilter_rows {
    my $matrixRef = shift;
    my $acceptTypesRef = shift;
    my $umls = shift;
    
=comment
    #Count the number of keys before and after filtering (for debugging)
    my %termsHash = ();
    foreach my $key1 (keys %{$matrixRef}) {
	foreach my $key2 (keys %{${$matrixRef}{$key1}}) {
	    $termsHash{$key2} = 1;
	}
    }
    print "   number of keys before filtering = ".(scalar keys %termsHash)."\n";
=cut

    #eliminate values that are incorrect semantic groups
    #do each row at a time, remove column values that 
    #are the incorrect semantic type
    my $keep = -1;
    #cuisChecked keeps track of cuis that have been checked 
    # for elimination. If the cui has been checked its key
    # will exist in the hash. Values of -1 indicate it should
    # be eliminated, values of 1 indicate it should stay.
    #eliminate cuis from columns
    foreach my $cui1 (keys %{$matrixRef}) {
	my $typesRef = $umls->getSt($cui1);
	foreach my $type(@{$typesRef}) {
	    my $abr = $umls->getStAbr($type);

	    #check the cui for removal
	    if (exists ${$acceptTypesRef}{$type}) {
		$keep = 1;
		last;
	    }
	}

	#eliminate if needed
	if ($keep < 0) {
	    delete ${$matrixRef}{$cui1};
	}
	$keep = -1;
    }

=comment
    #Count the number of keys after filtering (for debugging)
    %termsHash = ();
    foreach my $key1 (keys %{$matrixRef}) {
	foreach my $key2 (keys %{${$matrixRef}{$key1}}) {
	    $termsHash{$key2} = 1;
	}
    }
    print "   number of keys after filtering = ".(scalar keys %termsHash)."\n";
=cut
}


# applies a semantic group filter to the matrix, by removing keys that 
# are not allowed semantic type. Only removes types from columns, 
# so is applied to the implicit matrix (starting term rows with implicit
# columns).
# input:  $matrixRef <- ref to a sparse matrix to be filtered
#         $acceptTypesRef <- a ref to a hash of accept type strings
#         $umls <- an instance of UMLS::Interface
# output: None, but $vectorRef is updated 
sub semanticTypeFilter_columns {
    my $matrixRef = shift;
    my $acceptTypesRef = shift;
    my $umls = shift;
 
=comment   
    #Count the number of keys before and after filtering (for debugging)
    my %termsHash = ();
    foreach my $key1 (keys %{$matrixRef}) {
	foreach my $key2 (keys %{${$matrixRef}{$key1}}) {
	    $termsHash{$key2} = 1;
	}
    }
    print "   number of keys before filtering = ".(scalar keys %termsHash)."\n";
=cut

    #eliminate values that are incorrect semantic groups
    #do each row at a time, remove column values that 
    #are the incorrect semantic type
    my %cuisChecked = ();
    #cuisChecked keeps track of cuis that have been checked 
    # for elimination. If the cui has been checked its key
    # will exist in the hash. Values of -1 indicate it should
    # be eliminated, values of 1 indicate it should stay.
    #eliminate cuis from columns
    foreach my $cui1 (keys %{$matrixRef}) {
	foreach my $cui2 (keys %{${$matrixRef}{$cui1}}) {
	    #update cui checked hash
	    if (!exists $cuisChecked{$cui2}) {
		$cuisChecked{$cui2} = -1;

		my $typesRef = $umls->getSt($cui2);
		foreach my $type(@{$typesRef}) {
		    my $abr = $umls->getStAbr($type);

		    #check the cui for removal
		    if (exists ${$acceptTypesRef}{$type}) {
			$cuisChecked{$cui2} = 1;
			last;
		    }
		}
	    }

	    #eliminate if needed
	    if ($cuisChecked{$cui2} < 0) {
		delete ${${$matrixRef}{$cui1}}{$cui2};
	    }
	}
    }

=comment
    #Count the number of keys after filtering (for debugging)
    %termsHash = ();
    foreach my $key1 (keys %{$matrixRef}) {
	foreach my $key2 (keys %{${$matrixRef}{$key1}}) {
	    $termsHash{$key2} = 1;
	}
    }
    print "   number of keys after filtering = ".(scalar keys %termsHash)."\n";
=cut

}

# gets the semantic types of the group
# input:  $group <- a string specifying a semantic group
#         $umls <- an instance of UMLS::Interface
# output: a ref to a hash of TUIs
sub getTypesOfGroup {
    my $group = shift;
    my $umls = shift;

    #add each type of the group to the set of accept types
    my %acceptTuis = ();
    my @groupTypes = @{ $umls->getStsFromSg($group) };
    foreach my $abr(@groupTypes) {
	#check that it is defined (types that are no longer in 
	#the UMLS may be returned as part of the group)
	if (defined $abr) {
	    my $tui = uc $umls->getStTui($abr);
	    $acceptTuis{$tui} = 1;
	}
    }

    return \%acceptTuis;
}

# gets all semantic types of the UMLS
# input:  $umls <- an instance of UMLS::Interface
# output: a ref to an array of TUIs
sub getAllTypes {
    my $umls = shift;

    my $abrRef = $umls->getAllSts();
    my @tuis = ();
    foreach my $abr(@{$abrRef}) {
	push @tuis, uc $umls->getStTui($abr);
    }

    return \@tuis;
}

# gets all semantic groups of the UMLS
# input:  $umls <- an instance of UMLS::Interface
# output: a ref to a hash of semantic groups
sub getAllGroups {
    my $umls = shift;
    my $groupsRef = $umls->getAllSemanticGroups();
    return $groupsRef;
}

1;
