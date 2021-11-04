# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>
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

use App::Phoebe;
use Modern::Perl;
use Test::More;
use IO::Socket::SSL;
use utf8; # tests contain UTF-8 characters and it matters

our @use = qw(Iapetus);

our @config = (<<'EOT');
package App::Phoebe;
our @known_fingerprints = qw(
    sha256$0ba6ba61da1385890f611439590f2f0758760708d1375859b2184dcd8f855a00);
EOT

require './t/test.pl';

# variables set by test.pl
our $host;
our $base;
our $port;

# test page
my $page = query_gemini("$base/Haiku");
like($page, qr/^51 Path not found/m, "Test page does not exist");

# upload text
sub iapetus {
  my $request = shift;
  my $data = shift;
  my $socket = IO::Socket::SSL->new(
    PeerHost => $host, PeerPort => $port,
    # don't verify the server certificate
    SSL_verify_mode => SSL_VERIFY_NONE,
    SSL_cert_file => 't/cert.pem',
    SSL_key_file => 't/key.pem', );
  $socket->print($request);
  is(<$socket>, "10 Continue\r\n");
  $socket->print($data);
  undef $/; # slurp
  return <$socket>;
}

my $haiku = <<EOT;
Quiet keyboard tapping,
Tests are missing, and it's late,
My partner fast asleep.
EOT

$page = iapetus("iapetus://$host:$port/Haiku 82\r\n", $haiku);
like($page, qr/^30 $base\/page\/Haiku\r$/, "Iapetus Haiku");

$page = query_gemini("$base/page/Haiku");
like($page, qr/^20 text\/gemini; charset=UTF-8\r\n# Haiku\n$haiku/, "Haiku saved");

# plain text

$page = query_gemini("$base\/raw\/Haiku");
like($page, qr/$haiku/m, "Raw text");

done_testing();
