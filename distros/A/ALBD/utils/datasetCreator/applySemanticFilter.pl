#applies a semantic filter to the matrix
use strict;
use warnings;

use LiteratureBasedDiscovery::Discovery;
use LiteratureBasedDiscovery::Evaluation;
use LiteratureBasedDiscovery::Rank;
use LiteratureBasedDiscovery::Filters;
use LiteratureBasedDiscovery;

use UMLS::Association;
use UMLS::Interface;

####### User input
my $matrixFileName = '/home/henryst/lbdData/groupedData/1975_1999_window8_noOrder_threshold5';
my $outputFileName = $matrixFileName.'_filtered';
my $acceptTypesString = ''; #leave blank if none are applied
my $acceptGroupsString = 'CHEM,DISO,GENE,PHYS,ANAT'; #for the explicit matrix
my $interfaceConfig = '/home/share/packages/ALBD/config/interface';

#apply the filter to rows and columns or columns only
# apply to just columns generally for the implicit matrix
#   ...if the rows are just the starting terms
# apply to rows and columns generally for the explicit matrix
my $columnsOnly = 0; #apply to columns only, or rows and columns

&applySemanticFilter($matrixFileName, $outputFileName, 
		     $acceptTypesString, $acceptGroupsString,



###################################################################
###################################################################

# Applies the semantic type filter
sub applySemanticFilter {
    #grab the input
    my $matrixFileName = shift;
    my $outputFileName = shift;
    my $acceptTypesString = shift;
    my $acceptGroupsString = shift;
    my $interfaceConfig = shift;
    my $columnsOnly = shift;

    print STDERR "Applying Semantic Filter to $matrixFileName\n";

    #load the matrix
    my $matrixRef = Discovery::fileToSparseMatrix($matrixFileName);

    #initialize the UMLS::Interface 
    my $componentOptions = 
	LiteratureBasedDiscovery::_readConfigFile('',$interfaceConfig);
    
    my $umls_interface = UMLS::Interface->new($componentOptions) 
	or die "Error: Unable to create UMLS::Interface object.\n";
    
    #get the acceptTypes
    my $acceptTypesRef = &getAcceptTypes(
	$umls_interface, $acceptTypesString, $acceptGroupsString);

    #apply semantic filter
    if ($columnsOnly) {
	Filters::semanticTypeFilter_columns(
	    $matrixRef, $acceptTypesRef, $umls_interface);
    } else {
	Filters::semanticTypeFilter_rowsAndColumns(
	    $matrixRef, $acceptTypesRef, $umls_interface);
    }

    #output the matrix
    Discovery::outputMatrixToFile($outputFileName, $matrixRef);

    #TODO re-enable this and then try to run again
    #disconnect from the database and return
    #$umls_interface->disconnect();
}


# transforms the string of accept types or groups into a hash of accept TUIs
# input:  a string specifying whether linking or target types are being defined
# output: a hash of acceptable TUIs
sub getAcceptTypes {
    my $umls_interface = shift;
    my $acceptTypesString = shift;
    my $acceptGroupsString = shift;

    #get the accept types 
    my %acceptTypes = ();

    #add all types for groups specified
    #accept groups were specified
    my @acceptGroups = split(',',$acceptGroupsString);

    #add all the types of each group
    foreach my $group(@acceptGroups) {
	my $typesRef = Filters::getTypesOfGroup($group, $umls_interface);
	foreach my $key(keys %{$typesRef}) {
	    $acceptTypes{$key} = 1;
	}
    }

    #add all types specified
    #convert each type to a tui and add
    my $tui;
    my @acceptTypes = split(',',$acceptTypesString);
    foreach my $abr(@acceptTypes) {
	$tui = uc $umls_interface->getStTui($abr);
	$acceptTypes{$tui} = 1;
    }
    
    return \%acceptTypes;
}


