#!/usr/bin/perl -w
    
use strict;
use warnings;

use Asyncore;
use TimeServer;

# TimeServer->create_socket(port, family, type)
my $server = TimeServer->new(35000);

Asyncore::loop();

1;
