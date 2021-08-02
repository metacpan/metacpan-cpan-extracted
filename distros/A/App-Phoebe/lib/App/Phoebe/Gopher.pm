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

=encoding utf8

=head1 NAME

App::Phoebe::Gopher - serving a Phoebe wiki via the Gopher protocol

=head1 DESCRIPTION

This extension serves your Gemini pages via Gopher and generates a few automatic
pages for you, such as the main page.

To configure, you need to specify the Gopher port(s) in your Phoebe F<config> file.
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

If you don't do any of the above, you'll get a permission error on startup:
"Mojo::Reactor::Poll: Timer failed: Can't create listen socket: Permission
denied…"

If you are virtual hosting note that the Gopher protocol is incapable of doing
that: the server does not know what hostname the client used to look up the IP
number it eventually contacted. This works for HTTP and Gemini because HTTP/1.0
and later added a Host header to pass this information along, and because Gemini
uses a URL including a hostname in its request. It does not work for Gopher.
This is why you need to specify the hostname via C<$gopher_host>.

You can set the normal Gopher via C<$gopher_port> and the encrypted Gopher ports
via C<$gophers_port> (note the extra s). The values either be a single port, or
an array of ports. See the example below.

In this example we first switch to the package namespace, set some variables,
and then we I<use> the package. At this point the ports are specified and the
server processes it starts go up, one for ever IP number serving the hostname.

    package App::Phoebe::Gopher;
    our $gopher_host = "alexschroeder.ch";
    our $gopher_port = [70,79]; # listen on the finger port as well
    our $gophers_port = 7443; # listen on port 7443 using TLS
    our $gopher_main_page = "Gopher_Welcome";
    use App::Phoebe::Gopher;

Note the C<finger> port in the example. This works, but it's awkward since you
have to finger C<page/alex> instead of C<alex>. In order to make that work, we
need some more code.

    package App::Phoebe::Gopher;
    use App::Phoebe qw(@extensions port $log);
    use Modern::Perl;
    our $gopher_host = "alexschroeder.ch";
    our $gopher_port = [70,79]; # listen on the finger port as well
    our $gophers_port = 7443; # listen on port 7443 using TLS
    our $gopher_main_page = "Gopher_Welcome";
    our @extensions;
    push(@extensions, \&finger);
    sub finger {
      my $stream = shift;
      my $selector = shift;
      my $port = port($stream);
      if ($port == 79 and $selector =~ m!^[^/]+$!) {
	$log->debug("Serving $selector via finger");
	gopher_serve_page($stream, $gopher_host, undef, decode_utf8(uri_unescape($selector)));
	return 1;
      }
      return 0;
    }
    use App::Phoebe::Gopher;

=cut

package App::Phoebe::Gopher;
use App::Phoebe qw(get_ip_numbers $log $server @extensions port space pages blog_pages
		   space_regex reserved_regex run_extensions text search);
use Modern::Perl;
use URI::Escape;
use List::Util qw(min);
use Encode qw(encode_utf8 decode_utf8);
use Text::Wrapper;
use utf8;

our $gopher_header = "iPhlog:\n"; # must start with 'i'
our $gopher_port ||= 70;
our $gophers_port = [];
our $gopher_host;
our $gopher_main_page;
our ($server, $log, @main_menu);

use Mojo::IOLoop;

# start the loop after configuration (so that the user can change $gopher_port)
Mojo::IOLoop->next_tick(\&gopher_startup);

sub gopher_startup {
  $gopher_host ||= (keys %{$server->{host}})[0];
  for my $address (get_ip_numbers($gopher_host)) {
    my @ports = ref $gopher_port ? @$gopher_port : ($gopher_port);
    my %tls = map { push(@ports, $_); $_ => 1 } ref $gophers_port ? @$gophers_port : ($gophers_port);
    for my $port (@ports) {
      $log->info("$gopher_host: listening on $address:$port (Gopher)");
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
	    $log->debug("Looking at " . ($1 || "an empty selector"));
	    serve_gopher($stream, $1);
	  } else {
	    $log->debug("Waiting for more bytes...");
	  }
	});
      });
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
    my $host = $gopher_host;
    my $spaces = space_regex();
    my $reserved = reserved_regex($stream);
    my $query;
    $log->debug("Serving Gopher on $host for spaces $spaces");
    $log->info("Looking at " . ($selector || "an empty selector"));
    my ($space, $id, $n, $style, $filter);
    if (run_extensions($stream, $selector)) {
      # config file goes first
    } elsif (($space) = $selector =~ m!^($spaces)?(?:/page)?/?$!) {
      # "up" from page/Alex gives us page or page/ → show main menu
      gopher_main_menu($stream, $host, space($stream, $host, $space));
    } elsif (($space, $n) = $selector =~ m!^(?:($spaces)/)?do/more(?:/(\d+))?$!) {
      gopher_serve_blog($stream, $host, space($stream, $host, $space), $n);
    } elsif (($space) = $selector =~ m!^(?:($spaces)/)?do/index$!) {
      gopher_serve_index($stream, $host, space($stream, $host, $space));
    } elsif ($selector =~ m!^do/source$!) {
      seek DATA, 0, 0;
      local $/ = undef; # slurp
      $stream->write(encode_utf8 <DATA>);
    } elsif (($space, $query) = $selector =~ m!^(?:($spaces)/)?do/match\t(.+)!) {
      gopher_serve_match($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($query)));
    } elsif (($space, $query) = $selector =~ m!^(?:($spaces)/)?do/search\t(.+)!) {
      gopher_serve_search($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($query)));
    } elsif (($space, $id, $n) = $selector =~ m!^(?:($spaces)/)?(?:page/)?([^/]+)(?:/(\d+))?$!) {
      # the /page is optional: makes finger possible
      gopher_serve_page($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
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
  my $type = shift || 0;
  my $port = port($stream);
  $stream->write(encode_utf8 join("\t", $type . $title, $id, $host, $port) . "\n");
}

sub gopher_menu_link {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $title = shift;
  my $selector = shift;
  my $port = port($stream);
  $stream->write(encode_utf8 join("\t", "1" . $title, $selector, $host, $port) . "\n");
}

sub gopher_main_menu {
  my $stream = shift;
  my $host = shift;
  my $space = shift||"";
  $log->info("Serving main menu via Gopher");
  my $page = $gopher_main_page || $server->{wiki_main_page};
  if ($page) {
    my $text = gopher_plain_text(text($stream, $host, $space, $page)) . "\n\n";
    $stream->write(encode_utf8 gopher_menu($text));
  } else {
    $stream->write("iWelcome to Phoebe!\n");
    $stream->write("i\n");
  }
  gopher_blog($stream, $host, $space, 10);
  for my $id (@{$server->{wiki_page}}) {
    gopher_link($stream, $host, $space, $id);
  }
  for my $line (@main_menu) {
    $stream->write(encode_utf8 join("\n", map { "i$_" } split(/\n/, gopher_plain_text($line))) . "\ni\n");
  }
  # gopher_link($stream, $host, $space, "Changes", "do/changes");
  gopher_link($stream, $host, $space, "Search matching page names", "do/match", "7");
  gopher_link($stream, $host, $space, "Search matching page content", "do/search", "7");
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
  my @blog = blog_pages($stream, $host, $space, $n + 1); # for More...
  return unless @blog;
  $stream->write($gopher_header);
  # we should check for pages marked for deletion!
  for my $id (@blog[0 .. min($#blog, $n - 1)]) {
    gopher_link($stream, $host, $space, $id);
  }
  gopher_menu_link($stream, $host, $space, "More...", "do/more/" . ($n * 10)) if @blog > $n;
  $stream->write("i\n");
  return @blog;
}

sub gopher_serve_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  $log->info("Serve Gopher page $id");
  $stream->write(encode_utf8 gopher_plain_text("# $id\n" . text($stream, $host, $space, $id, $revision)));
}

sub gopher_plain_text {
  $_ = shift;
  my $text_wrapper = Text::Wrapper->new;
  my $bullet_wrapper = Text::Wrapper->new(par_start => "• ", body_start => "  ");
  my $quote_wrapper = Text::Wrapper->new(par_start => "> ", body_start => "> ");
  s/^=> .*\n//gm;
  my @lines = grep { !/^```/ } split(/\n/);
  for (@lines) {
    next if /^\s*$/;
    next if s/^\* (.*)/$bullet_wrapper->wrap($1)/e;
    next if s/^> (.*)/$quote_wrapper->wrap($1)/e;
    next if s/^## (.*)/"$1\n" . '-' x length($1) . "\n\n"/e;
    next if s/^### (.*)/"$1\n" . '·' x length($1) . "\n\n"/e;
    next if s/^# (.*)/"$1\n" . '=' x length($1) . "\n\n"/e;
    $_ = $text_wrapper->wrap($_);
  }
  # drop trailing newlines added to paragraphs by the Text::Wrapper code, except for the last one
  my $text = join("\n", map { s/\n+$//; $_ } @lines) . "\n";
  # drop extra empty lines: one empty line is enough
  $text =~ s/\n\n\n+/\n\n/gm;
  return $text;
}

sub gopher_menu {
  my $text = shift;
  $text =~ s/^/i/gm;
  return $text;
}

sub gopher_serve_index {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving index of all pages via Gopher");
  my @pages = pages($stream, $host, $space);
  $stream->write("iThere are no pages.\n") unless @pages;
  for my $id (@pages) {
    gopher_link($stream, $host, $space, $id);
  }
}

sub gopher_serve_blog {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift;
  $log->info("Serving blog via Gopher");
  return if gopher_blog($stream, $host, $space, 10);
  $stream->write("iThere are no blog pages.\n");
}

sub gopher_serve_match {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $query = shift;
  $log->info("Serving index of all pages matching $query via Gopher");
  my @pages = pages($stream, $host, $space, $query);
  $stream->write("iThere are no pages matching $query.\n") unless @pages;
  for my $id (@pages) {
    gopher_link($stream, $host, $space, $id);
  }
}

sub gopher_serve_search {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $query = shift;
  $log->info("Serving search for $query via Gopher");
  my @pages = search($stream, $host, $space, $query, sub { gopher_link($stream, @_[0..2]) });
  $stream->write("iThere are no pages containing $query.\n") unless @pages;
}

1;
