package BlankOnDev::Utils::file;
use strict;
use warnings FATAL => 'all';

# Use or Require Module :

# Version :
our $VERSION = '0.1005';;

# Create Subroutine for Just Read Files :
# ------------------------------------------------------------------------
sub read {
    # Define parameter module :
    my ($self, $loc_files) = @_;

    # Define scalar for result :
    my $data = '';

    # Open File :
    open(FH, '<', $loc_files) or die $! . " - " . $loc_files;

    # While Loop for read file :
    while (my $lines = <FH>)
    {
        # CLean white space in first and end :
#        chomp $lines;

        # Placing fill file into scalar $pre_data :
        $data .= $lines;
    }

    # CLose File :
    close (FH);

    # Return Result :
    return $data;
}
# End of Create Subroutine for Just Read Files.
# ===========================================================================================================

# Subroutine for Create New File :
# ------------------------------------------------------------
sub create {

    # Define scalar
    my ($self, $filename, $destination, $isi_file) = @_;

    # Define variable for FileHandle :
    my $loc_files = $destination . $filename;

    # Declare Hash for placing result create new file :
    # ----------------------------------------------------------------
    my %data;

    # Create New Files :
    open(FILE, '>', $loc_files) or die "File : $loc_files is not exists $!";
    print FILE $isi_file;
    close(FILE);

    # Chcck IF $loc_files is exists :
    if (-e $loc_files) {
        # Placing success result into hash "%data" :
        $data{'result'} = {
            'sukses' => 1,
            'data' => {
                'dirloc' => $destination,
                'filename' => $filename,
                'fileloc' => $loc_files
            }
        };
    } else {
        # Placing error result into hash "$data" :
        $data{'result'} = {
            'sukses' => 0,
            'data' => {
                'dirloc' => $destination,
                'filename' => $filename,
                'fileloc' => $loc_files
            }
        };
    }

    # Return result :
    return \%data;
}
# End of Subroutine for Create New File.
# ===========================================================================================================
1;