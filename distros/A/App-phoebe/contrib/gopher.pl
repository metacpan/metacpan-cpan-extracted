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

=head1 Gopher

This extension serves your Gemini pages via Gopher and generates a few automatic
pages for you, such as the main page.

To configure, you need to specify the Gopher port(s) in your Phoebe config file.
The default port is 70. This is a priviledge port. Thus, you either need to
grant Perl the permission to listen on a priviledged port, or you need to run
Phoebe as a super user. Both are potential security risk, but the first option
is much less of a problem, I think.

If you want to try this, run the following as root:

    setcap 'cap_net_bind_service=+ep' $(which perl)

Verify it:

    getcap $(which perl)

If you want to undo this:

    setcap -r $(which perl)

The alternative is to use a port number above 1024.

You can set the normale Gopher and the encrypted Gopher ports by setting the
appropriate variables. These variables either be a single port, or an array of
ports.

    our $gopher_port = 7000; # listen on port 7000
    our $gopher_port = [70,79]; # listen on the finger port as well
    our $gophers_port = 7443; # listen on port 7443 using TLS
    our $gophers_port = [7070,7079]; # listen on port 7070 and 7079 using TLS

=cut

package App::Phoebe;
use Modern::Perl;
use Encode qw(encode_utf8 decode_utf8 decode);
our $gopher_header = "iBlog\n"; # must start with 'i'
our $gopher_port ||= 70;
our $gophers_port = [];
our ($server, $log, @main_menu);

use Mojo::IOLoop;

# start the loop after configuration (so that the user can change $gopher_port)
Mojo::IOLoop->next_tick(\&gopher_startup);

sub gopher_startup {
  for my $host (keys %{$server->{host}}) {
    for my $address (get_ip_numbers($host)) {
      my @ports = ref $gopher_port ? @$gopher_port : ($gopher_port);
      my %tls = map { push(@ports, $_); $_ => 1 } ref $gophers_port ? @$gophers_port : ($gophers_port);
      for my $port (@ports) {
	$log->info("Listening on $address:$port");
	Mojo::IOLoop->server({
	  address => $address,
	  port => $port,
	  tls => $tls{$port},
	  tls_cert => $server->{cert_file},
	  tls_key  => $server->{key_file},
        } => sub {
	  my ($loop, $stream) = @_;
	  my $buffer;
	  $stream->on(read => sub {
	    my ($stream, $bytes) = @_;
	    $log->debug("Received " . length($bytes) . " bytes via Gopher");
	    $buffer .= $bytes;
	    if ($buffer =~ /^(.*)\r\n/) {
	      $log->debug("Looking at $1");
	      serve_gopher($stream, $1);
	    } else {
	      $log->debug("Waiting for more bytes...");
	    }
	  });
        });
      }
    }
  }
}

sub serve_gopher {
  my ($stream, $selector) = @_;
  eval {
    local $SIG{'ALRM'} = sub {
      $log->error("Timeout processing $selector via Gopher");
    };
    alarm(10); # timeout
    my $port = port($stream);
    my $host = $server->{address}->{$stream->handle->sockhost};
    my $hosts = host_regex();
    my $spaces = space_regex();
    my $reserved = reserved_regex($stream);
    $log->debug("Serving ($hosts)(?::$port)?");
    $log->debug("Spaces $spaces");
    $log->info("Looking at $selector");
    my ($space, $id, $n, $style, $filter);
    if (($space) = $selector =~ m!^($spaces)?$!) {
      gopher_main_menu($stream, $host, space($stream, $host, $space));
    } elsif (($space, $n) = $selector =~ m!^(?:($spaces)/)?do/more(?:/(\d+))?$!) {
      gopher_serve_blog($stream, $host, space($stream, $host, $space), $n);
    } elsif (($space) = $selector =~ m!^(?:($spaces)/)?do/index$!) {
      gopher_serve_index($stream, $host, space($stream, $host, $space));
    # } elsif (($space) = $url =~ m!^(?:($spaces)/)?do/files$!) {
    #   serve_files($stream, $host, space($stream, $host, $space));
    # } elsif (($host) = $url =~ m!^(?:($spaces)/)?do/spaces$!) {
    #   serve_spaces($stream, $host, $port);
    # } elsif (($space) = $url =~ m!^(?:($spaces)/)?do/data$!) {
    #   serve_data($stream, $host, space($stream, $host, $space));
    } elsif ($selector =~ m!^do/source$!) {
      seek DATA, 0, 0;
      local $/ = undef; # slurp
      $stream->write(encode_utf8 <DATA>);
    # } elsif ($url =~ m!^(?:($spaces)/)?do/match$!) {
    #   $stream->write("10 Find page by name (Perl regex)\r\n");
    # } elsif ($query and ($space) = $url =~ m!^(?:($spaces)/)?do/match\?!) {
    #   serve_match($stream, $host, map {decode_utf8(uri_unescape($_))} $space, $query);
    # } elsif ($url =~ m!^(?:($spaces)/)?do/search$!) {
    #   $stream->write("10 Find page by content (Perl regex)\r\n");
    # } elsif ($query and ($space) = $url =~ m!^(?:($spaces)/)?do/search\?!) {
    #   serve_search($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($query))); # search terms include spaces
    # } elsif ($url =~ m!^(?:($spaces)/)?do/new$!) {
    #   $stream->write("10 New page\r\n");
    #   # no URI escaping required
    # } elsif ($query and ($space) = $url =~ m!^(?:($spaces)/)?do/new\?!) {
    #   if ($space) {
    # 	$stream->write("30 gemini://$host:$port/$space/raw/$query\r\n");
    #   } else {
    # 	$stream->write("30 gemini://$host:$port/raw/$query\r\n");
    #   }
    # } elsif (($space, $n, $style) = $url =~ m!^(?:($spaces)/)?do/changes(?:/(\d+))?(?:/(colour|fancy))?$!) {
    #   serve_changes($stream, $host, space($stream, $host, $space), $n||100, $style);
    # } elsif (($filter, $n, $style) = $url =~ m!^do/all(?:/(latest))?/changes(?:/(\d+))?(?:/(colour|fancy))?$!) {
    #   serve_all_changes($stream, $host, $n||100, $style||"", $filter||"");
    # } elsif (($space) = $url =~ m!^(?:($spaces)/)?do/rss$!) {
    #   serve_rss($stream, $host, space($stream, $host, $space));
    # } elsif (($space) = $url =~ m!^(?:($spaces)/)?do/atom$!) {
    #   serve_atom($stream, $host, space($stream, $host, $space));
    # } elsif (($space) = $url =~ m!^(?:($spaces)/)?do/all/atom$!) {
    #   serve_all_atom($stream, $host);
    # } elsif (($host) = $url =~ m!^/robots.txt(?:[#?].*)?$!) {
    #   serve_raw($stream, $host, undef, "robots");
    # } elsif (($space, $id, $n, $style) = $url =~ m!^(?:($spaces)/)?history/([^/]*)(?:/(\d+))?(?:/(colour|fancy))?$!) {
    #   serve_history($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n||10, $style);
    # } elsif (($space, $id, $n, $style) = $url =~ m!^(?:($spaces)/)?diff/([^/]*)(?:/(\d+))?(?:/(colour))?$!) {
    #   serve_diff($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n, $style);
    # } elsif (($space, $id, $n) = $url =~ m!^(?:($spaces)/)?raw/([^/]*)(?:/(\d+))?$!) {
    #   serve_raw($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
    # } elsif (($space, $id, $n) = $url =~ m!^(?:($spaces)/)?html/([^/]*)(?:/(\d+))?$!) {
    #   serve_html($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
    } elsif (($space, $id, $n) = $selector =~ m!^(?:($spaces)/)?page/([^/]+)(?:/(\d+))?$!) {
      gopher_serve_page($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
    # } elsif (($space, $id) = $url =~ m!^(?:($spaces)/)?file/([^/]+)?$!) {
    #   serve_file($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)));
    # } elsif (($host) = $url =~ m!^(/|$)!) {
    #   $log->info("Unknown path for $url\r");
    #   $stream->write("51 Path not found for $url\r\n");
    # } elsif ($authority) {
    #   $log->info("Unsupported proxy request for $url");
    #   $stream->write("53 Unsupported proxy request for $url\r\n");
    } else {
      $log->info("No handler for $selector via gopher");
      $stream->write("Don't know how to handle $selector\r\n");
    }
    $log->debug("Done");
  };
  $log->error("Error: $@") if $@;
  alarm(0);
  $stream->close_gracefully();
}

sub gopher_link {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $title = shift;
  my $id = shift || "page/$title";
  my $port = port($stream);
  $stream->write(encode_utf8 join("\t", "1" . $title, $id, $host, $port) . "\n");
}

sub gopher_menu_link {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $title = shift;
  my $selector = shift;
  my $port = port($stream);
  $stream->write(encode_utf8 join("\t", "0" . $title, $selector, $host, $port) . "\n");
}

sub gopher_main_menu {
  my $stream = shift;
  my $host = shift;
  my $space = shift||"";
  $log->info("Serving main menu via Gopher");
  my $page = $server->{wiki_main_page};
  if ($page) {
    $stream->write(encode_utf8 text($host, $space, $page) . "\n");
  } else {
    $stream->write("iWelcome to Phoebe!\n");
    $stream->write("i\n");
  }
  gopher_blog($stream, $host, $space, 10);
  for my $id (@{$server->{wiki_page}}) {
    gopher_link($stream, $host, $space, $id);
  }
  for my $line (@main_menu) {
    $stream->write(encode_utf8 $line . "\n");
  }
  # gopher_link($stream, $host, $space, "Changes", "do/changes");
  # gopher_link($stream, $host, $space, "Search matching page names", "do/match");
  # gopher_link($stream, $host, $space, "Search matching page content", "do/search");
  $stream->write("i\n");
  gopher_menu_link($stream, $host, $space, "Index of all pages", "do/index");
  # gopher_link($stream, $host, $space, "Index of all files", "do/files");
  # gopher_link($stream, $host, undef, "Index of all spaces", "do/spaces")
  #     if @{$server->{wiki_space}} or keys %{$server->{host}} > 1;
  # gopher_link($stream, $host, $space, "Download data", "do/data");
  # a requirement of the GNU Affero General Public License
  gopher_link($stream, $host, undef, "Source code", "do/source");
  $stream->write("i\n");
}

sub gopher_blog {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift || 10;
  my @blog = blog_pages($host, $space);
  return unless @blog;
  $stream->write("iBlog:\n");
  # we should check for pages marked for deletion!
  for my $id (@blog[0 .. min($#blog, $n - 1)]) {
    gopher_link($stream, $host, $space, $id);
  }
  gopher_link($stream, $host, $space, "More...", "do/more/" . ($n * 10)) if @blog > $n;
  $stream->write("i\n");
}

sub gopher_serve_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  $log->info("Serve Gopher page $id");
  $stream->write(encode_utf8 text($host, $space, $id, $revision));
}

sub gopher_serve_index {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving index of all pages via Gopher");
  my @pages = pages($host, $space);
  $stream->write("There are no pages.\n") unless @pages;
  for my $id (sort { newest_first($stream, $a, $b) } @pages) {
    gopher_link($stream, $host, $space, $id);
  }
}

sub gopher_serve_blog {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift;
  $log->info("Serving blog via Gopher");
  $stream->write($gopher_header);
  my @blog = blog_pages($host, $space);
  if (not @blog) {
    $stream->write("iThere are no blog pages.\n");
    return;
  }
  $stream->write("Serving up to $n entries.\n");
  for my $id (@blog[0 .. min($#blog, $n - 1)]) {
    gopher_link($stream, $host, $space, $id);
  }
  gopher_link($stream, $host, $space, "More...", "do/more/" . ($n * 10)) if @blog > $n;
}

1;
