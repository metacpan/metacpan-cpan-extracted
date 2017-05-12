use strict;
use warnings;
no warnings qw(redefine);
eval 'use Test::Pod';

all_pod_files_ok();

sub all_pod_files_ok {
    # This definition will be overwritten if Test::Pod is available
    print "1..1\nok 1 - Skipping POD tests - Test::Pod not available?\n";
}
