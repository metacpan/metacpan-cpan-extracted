#!/usr/bin/perl -w
    
use strict;
use warnings;

use EchoServer;
use EchoClient;
use Asyncore;

#  $server = EchoServer->new(port, family, type)
my $server = EchoServer->new(35000);

my $message = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Donecegestas, enim et consectetuer ullamcorper, lectus ligula rutrum leo, aelementum elit tortor eu quam. Duis tincidunt nisi ut ante. Nulla facilisi. Sed tristique eros eu libero.\n";

my $client = EchoClient->new("localhost", 35000, undef, undef, $message);

Asyncore::loop();

1;
