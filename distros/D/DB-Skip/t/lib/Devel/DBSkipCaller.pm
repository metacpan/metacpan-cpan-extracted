use strict;
use warnings;

package DB;

sub DB {
    my @caller = ( caller, ( caller( 1 ) )[3] );
    print "@caller\n";
}

1;
