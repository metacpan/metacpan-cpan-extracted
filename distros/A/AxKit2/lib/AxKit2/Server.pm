# Copyright 2001-2006 The Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package AxKit2::Server;

use strict;
use warnings;

use IO::Socket;
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use AxKit2::Connection;
use AxKit2::Constants;
use AxKit2::Client;

use constant ACCEPT_MAX => 1000;

our $ACCEPT_MAX = 1;

sub create {
    my $class    = shift;
    my $servconf = shift;
    
    my $PORT = $servconf->port;
    my $sock = IO::Socket::INET->new(
            LocalPort => $PORT,
            Proto     => 'tcp',
            Type      => SOCK_STREAM,
            Blocking  => 0,
            Reuse     => 1,
            Listen    => SOMAXCONN )
               or die "Error creating server on port $PORT : $@\n";

    IO::Handle::blocking($sock, 0);
    
    my $accept_handler = sub {
        for (1 .. $ACCEPT_MAX) {
            my $csock = $sock->accept;
            return unless $csock;
    
            IO::Handle::blocking($csock, 0);
            setsockopt($csock, IPPROTO_TCP, TCP_NODELAY, pack("l", 1)) or die;
    
            if (my $client = eval { AxKit2::Connection->new($csock, $servconf) }) {
                $client->watch_read(1);
            }
            else {
                die("Error creating new Connection: $@") if $@;
            }
        }
        
        # Accept more next time
        $ACCEPT_MAX *= 2;
        $ACCEPT_MAX = ACCEPT_MAX if $ACCEPT_MAX > ACCEPT_MAX;
    };

    Danga::Socket->AddOtherFds(fileno($sock) => $accept_handler);
}

1;
