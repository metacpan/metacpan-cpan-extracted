use strict;
use warnings;

use Test::More;
use Data::Random qw( rand_image );
use File::Temp;

# Try to load GD
eval q{ use GD };

SKIP: {

    # If the module cannot be loaded, skip tests
    skip('GD not installed', 1) if $@;

    my ($fh, $imagefile) = File::Temp::tempfile();

    # Test writing an image to a file
    {
        binmode($fh);
        print $fh rand_image( bgcolor => [ 0, 0, 0 ] );
        close($fh);

        ok( !( -z $imagefile ) );
    }
}

done_testing;
