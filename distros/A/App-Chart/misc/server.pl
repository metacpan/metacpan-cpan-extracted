#!/usr/bin/perl -w

# Copyright 2007, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use IO::File;
use strict;
use Socket;

my $port = 12345;

socket (LIST, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or die;
setsockopt (LIST, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) or die;
bind (LIST, sockaddr_in($port, INADDR_ANY)) or die;
listen (LIST, 5) or die;

for (;;) {
  my $paddr = accept (SOCK, LIST) or die;

  if (fork() == 0) {
    SOCK->autoflush(1);
    my $req;
    for (;;) {
      if (sysread (SOCK, $req, 1024) == 0) {
        last;
      }
      print $req;

      my $content = "req was: $req\n";
      print SOCK "HTTP/1.1 200 OK\r\n"
        . "Content-length: " . length($content) . "\r\n"
          . "\r\n"
            . $content;
      print "sent resp\n";
    }
    exit (0);
  }
  close SOCK;
}

exit 0;
