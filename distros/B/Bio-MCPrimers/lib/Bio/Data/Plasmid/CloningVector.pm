package Bio::Data::Plasmid::CloningVector; 

our $VERSION = '2.5';

#
# Tim Wiggin, Stephen G. Lenk (C) 2006.
#
# This program is free software; you can redistribute it and/or 
# modify it under the same terms as Perl itself.
#
# Licensed under the Perl Artistic License.
#
# This software comes with no guarantee of usefulness. 
# Use at your own risk. Check any solutions you obtain. 
#
# Neither Stephen G. Lenk or Tim Wiggin assume responsibility 
# for the use of this software.
#
# Use: cloning_vector_data ( 
#          $vector_file_name,  # vector file name 
#          $re_ra,             # restriction enzyme site patterns
#          $re_name_rh,        # names of restriction enzymes
#          $ecut_loc_ra,       # absolute cut location in enzyme site
#          $vcut_loc_ra )      # frame cut location (0, 1, 2) in vector
#
# Returns: 0 = fails (file not found or bad data) 
#          1 = success
#
# File format: 
#
#    '#' at start of line is a comment
#    Blank lines with no characters (just <cr> are permitted)
#    Data lines are tab separated by item:
#
# Name  Sequence  Cut position in site sequence  Cut position in vector frame
#
# MCPRIMERS_DATA_DIR - if this environments variable is defined, 
#                      it is a file path prefix for the vector data file.

use strict;
use warnings;

sub cloning_vector_data {

    my ( $vector_file_name,  # vector file name 
         $re_ra,             # restriction enzyme site patterns
         $re_name_rh,        # names of restriction enzymes
         $ecut_loc_ra,       # absolute cut location in enzyme site 
         $vcut_loc_ra        # frame cut location (0, 1, 2) in vector 
       ) = @_;  

    # define name of text file
    if (defined $ENV{"MCPRIMERS_DATA_DIR"}) {

        if ($^O =~ /^MSW/) { 

            # Microsoft
            $vector_file_name = $ENV{"MCPRIMERS_DATA_DIR"} . "\\" . $vector_file_name;
        }
        else {

            # Other (OSX, Linux, Unix)
            $vector_file_name = $ENV{"MCPRIMERS_DATA_DIR"} . "/" . $vector_file_name;
        }
    } 

    # open text file
    open(IN_FILE, $vector_file_name) or return 0;
    my @fileArray = <IN_FILE>;
    close(IN_FILE);

    # extract data from file aray
    foreach my $row (@fileArray){
  
        if (substr($row,0,1) eq "#" or length $row == 1) {
        
            # skip coments and blank lines
            next;
        }
        elsif ($row =~ /(.+)\t([ATCGatcg]+)\t(\d+)\t(\d+)/) {
  
            # use valid data lines
            $re_name_rh->{$2} = $1;     # name keyed by base sequence
            push @{$re_ra}, $2;         # base sequence in site
            push @{$ecut_loc_ra}, $3;   # cut location in enzyme
            push @{$vcut_loc_ra}, $4;   # cut location
        }
        else {

            return 0;
        }

    }

    return 1;
}
