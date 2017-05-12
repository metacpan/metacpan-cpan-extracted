use 5.10.0;
use strict;
use warnings;

use File::Basename;
use Path::Class;

sub LoadData {
    my $filename = shift;
    my $fh = file( dirname(__FILE__), '_data', $filename )->openr();
    $fh->binmode;
    return scalar( do { local $/; <$fh> } );
}

1;
