# Copyright (C) 2021–2023  Alex Schroeder <alex@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Modern::Perl;
use Test::More;
use Net::NNTP;

our $port;

require './t/test.pl';

diag "Client connecting to $port...";

# verify that connection is possible
use IO::Socket::INET;
my $client = IO::Socket::INET->new(
  Domain => AF_INET,
  PeerAddr => "localhost:$port",
    ) or die "Cannot construct socket - $!\n";
diag "localhost is up";
my $line = <$client>;
diag "< $line";
$client->send("QUIT\r\n");
diag "> QUIT";
$line = <$client>;
diag "< $line";
like($line, qr/^205\b/, "QUIT");

done_testing;
