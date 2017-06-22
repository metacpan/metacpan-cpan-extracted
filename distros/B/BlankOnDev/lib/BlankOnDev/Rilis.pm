package BlankOnDev::Rilis;
use strict;
use warnings FATAL => 'all';

# Version :
our $VERSION = '0.1005';

# Subroutine for release :
# ------------------------------------------------------------------------
sub data {
    my %data = ();

    # Add data release :
    $data{'10'} = {
        'name' => 'Tambora',
        'code' => 'tambora'
    };
    $data{'11'} = {
        'name' => 'Uluwatu',
        'code' => 'uluwatu'
    };
    $data{'latest'} = $data{'10'};
    return \%data;
}
1;