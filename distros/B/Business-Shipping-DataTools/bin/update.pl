use strict;
use warnings;

use Business::Shipping::DataTools;
#Business::Shipping::Logging->log_level( 'debug' );

# Remember that it is normal to see a half-dozen "Failed on ..." messages.

my $dt = Business::Shipping::DataTools->new( 
    #download => 1,
    unzip => 1,
    convert => 1,
    pause => 0,
    data_dir => './data'
);

$dt->do_update;
