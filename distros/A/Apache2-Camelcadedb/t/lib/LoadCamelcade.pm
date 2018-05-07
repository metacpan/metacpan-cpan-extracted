package LoadCamelcade;

use strict;
use warnings;

use File::Basename qw();

my ($DIR, $PORT, $ADDRESS);
BEGIN {
    $DIR = File::Basename::dirname($INC{'LoadCamelcade.pm'}) . "/../..";
    $PORT = 23456;
    # $PORT = 12345;
    $ADDRESS = "localhost:$PORT";
}

use blib $DIR;
use Apache2::Camelcadedb remote_host => $ADDRESS;

{
    open my $fh, '>', "$DIR/t/logs/camelcade_port.txt"
        or die "Error opening '$DIR/t/logs/camelcade_port.txt': $!";
    print $fh $ADDRESS;
}

1;
