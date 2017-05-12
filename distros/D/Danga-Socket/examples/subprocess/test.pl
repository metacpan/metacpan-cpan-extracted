#!/usr/bin/perl

# Autoflush somehow gets turned on for this handle, even when it's an
# AF_UNIX socketpair
$|++;

use strict;
use warnings;

while (1) {
    print( "[$$] Hello World\n" ) or die;
    sleep 1;
}
