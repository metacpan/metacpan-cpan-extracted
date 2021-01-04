# Copyright (C) 2020  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use Modern::Perl;
use Mojo::Server::Daemon;
use File::Slurper qw(write_binary);

do './script/jupiter';

$Jupiter::log->level('warn');

my $id;
my $port;
my $daemon;

sub init {
  $id = sprintf("%04d", int(rand(1000)));
  $port = 10000 + $id;
  mkdir("test-$id");
  return $id, $port;
}

sub save_opml {
  my $filename = shift;
  write_binary("test-$id/$filename", <<"EOT");
<opml version="2.0">
  <body>
    <outline title="Feed" xmlUrl="http://127.0.0.1:$port/"/>
  </body>
</opml>
EOT
}

sub start_daemon {
  my $rss = shift;
  $daemon = Mojo::Server::Daemon->new(listen => ["http://*:$port"]);
  $daemon->on(request => sub {
    my ($daemon, $tx) = @_;
    # Response
    $tx->res->code(200);
    $tx->res->headers->content_type('application/xml');
    $tx->res->body($rss);
    # Resume transaction
    $tx->resume;
  });
  $daemon->start;
}

sub stop_daemon {
  $daemon->stop;
}
