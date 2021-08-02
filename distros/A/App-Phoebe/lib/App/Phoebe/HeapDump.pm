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

=head1 NAME

App::Phoebe::HeapDump - debugging Phoebe memory leaks

=head1 DESCRIPTION

Perhaps you find yourself in a desperate situation: your server is leaking
memory and you don't know where. This extension provides a way to use
L<Devel::MAT::Dumper> by allowing users identified with a known fingerprint of
their client certificate to initiate a dump.

You must set the fingerprints in your F<config> file.

    package App::Phoebe;
    our @known_fingerprints = qw(
      sha256$fce75346ccbcf0da647e887271c3d3666ef8c7b181f2a3b22e976ddc8fa38401);
    use App::Phoebe::HeapDump;

Once have restarted the server, L<gemini://localhost/do/heap-dump> will write a
heap dump to its wiki data directory. See L<Devel::MAT::UserGuide> for more.

=cut

package App::Phoebe::HeapDump;
use App::Phoebe qw(@extensions $server $log @known_fingerprints
		   port host_regex space_regex success result);
use Modern::Perl;
use Devel::MAT::Dumper;

our @known_fingerprints;

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
    result($stream, "61", "Your client certificate is not authorised for heap dumping");
  } else {
    $log->info("Requested client certificate");
    result($stream, "60", "You need an authorised client certificate to heap dump");
  }
}

1;
