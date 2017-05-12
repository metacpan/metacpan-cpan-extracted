
use strict;
use warnings;

use Test::More;

sub get_test_config  {
    my $type = shift;

    my $filename = $type . ".conf";

    foreach my $dir (qw( . t .. )) {
        my $path = "$dir/$filename";
        return $path if (-f $path);
    }

    return;
}


1;
