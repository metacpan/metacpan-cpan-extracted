# -*- mode: perl -*-
# Copyright (C) 2017–2020  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

package App::Phoebe;
use Modern::Perl;

our (@extensions, $log);

# moku pona

our $moku_pona_dir = "/home/alex/.moku-pona";
our @known_fingerprints = qw(
  sha256$54c0b95dd56aebac1432a3665107d3aec0d4e28fef905020ed6762db49e84ee1);

push(@extensions, \&mokupona);

sub mokupona {
  my $stream = shift;
  my $url = shift;
  my $host = "alexschroeder.ch";
  my $port = port($stream);
  if ($url =~ m!^gemini://$host(?::$port)?/do/moku-pona$!) {
    $stream->write("31 gemini://$host/do/moku-pona/updates.txt\r\n");
    return 1;
  } elsif ($url =~ m!^gemini://$host(?::$port)?/do/moku-pona/add!) {
    with_known_fingerprint($stream, sub {
      $stream->write("10 Line to add to the subscription list\r\n") });
    return 1;
  } elsif ($url =~ m!^gemini://$host(?::$port)?/do/moku-pona/add?(.+)!) {
    with_known_fingerprint($stream, sub {
      moku_pona_add(decode_utf8(uri_unescape($1)));
      $stream->write("31 gemini://$host/do/moku-pona/sites.txt\r\n") });
    return 1;
  } elsif ($url =~ m!^gemini://$host(?::$port)?/do/moku-pona/([^/]+)$!) {
    my $file = decode_utf8(uri_unescape($1));
    if (-f "$moku_pona_dir/$file") {
      $stream->write("20 text/gemini\r\n");
      $stream->write(encode_utf8 read_text("$moku_pona_dir/$file"));
    } else {
      $stream->write("40 Cannot read $moku_pona_dir/$file\r\n");
    }
    return 1;
  }
  return 0;
}

sub with_known_fingerprint {
  my $stream = shift;
  my $fun = shift;
  my $fingerprint = $stream->handle->get_fingerprint();
  if ($fingerprint and grep { $_ eq $fingerprint} @known_fingerprints) {
    $fun->();
  } elsif ($fingerprint) {
    $log->info("Unknown client certificate $fingerprint");
    $stream->write("61 Your client certificate is not authorised for editing\r\n");
  } else {
    $log->info("Requested client certificate");
    $stream->write("60 You need an authorised client certificate to add to the moku pona list\r\n");
  }
}
