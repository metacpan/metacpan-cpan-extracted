#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use_ok('DNS::Unbound');

diag DNS::Unbound->unbound_version();

use File::Temp;

my $fh = File::Temp::tempfile();
syswrite($fh, 'strawberry');

for ( 0, 1 ) {
    my $dns = DNS::Unbound->new();

    $dns->debugout($fh);
}

sysseek($fh, 0, 0);
sysread($fh, my $buf, 10);
is($buf, 'strawberry', 'repeat create/destroy of contexts w/ debugout does not close debugout file descriptor');

done_testing();
