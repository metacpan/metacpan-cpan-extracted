# -*- mode: perl -*-
# Copyright (C) 2017–2021  Alex Schroeder <alex@gnu.org>

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
use Devel::MAT::Dumper;

our @known_fingerprints = qw(
  sha256$54c0b95dd56aebac1432a3665107d3aec0d4e28fef905020ed6762db49e84ee1);

our (@extensions, $server, $log);

=head1 Heap Dumper

We want Phoebe to write a heap dump to its wiki data directory when visiting
/do/heap-dump.

See L<Devel::MAT::UserGuide>.

=cut

# order is important: we must be able to reset the stats for tests
push(@extensions, \&heap_dump);

sub heap_dump {
  my $stream = shift;
  my $url = shift;
  my $hosts = host_regex();
  my $port = port($stream);
  if ($url =~ m!^gemini://(?:$hosts)(?::$port)?/do/heap-dump$!) {
    with_heap_dump_fingerprint($stream, sub {
      success($stream);
      my $dir = $server->{wiki_dir};
      Devel::MAT::Dumper::dump("$dir/phoebe.pmat");
      $stream->write("# Heap Dump Saved\n");
      $stream->write("On the server, examine $dir/phoebe.pmat") });
    return 1;
  }
  return;
}

sub with_heap_dump_fingerprint {
  my $stream = shift;
  my $fun = shift;
  my $fingerprint = $stream->handle->get_fingerprint();
  if ($fingerprint and grep { $_ eq $fingerprint} @known_fingerprints) {
    $fun->();
  } elsif ($fingerprint) {
    $log->info("Unknown client certificate $fingerprint");
    $stream->write("61 Your client certificate is not authorised for heap dumping\r\n");
  } else {
    $log->info("Requested client certificate");
    $stream->write("60 You need an authorised client certificate to heap dump\r\n");
  }
}
