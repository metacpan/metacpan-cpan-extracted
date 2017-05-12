package AERunTest;

use strict;

sub main {
    print "test\n";
}

sub stdin {
    while ( my $line = <STDIN> ) {
        print $line;
        last;
    }
}

1;