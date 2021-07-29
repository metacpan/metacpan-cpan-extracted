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

App::Phoebe::Spartan - implement the Spartan protocol for Phoebe

=head1 DESCRIPTION

This extension serves your Gemini pages via the Spartan protocol and generates a
few automatic pages for you, such as the main page.

B<Warning!> If you install this code, anybody can write to your site using the
Spartan protocol. There is no token being checked.

To configure, you need to specify the Spartan port(s) in your Phoebe config
file. The default port is 300. This is a priviledge port. Thus, you either need
to grant Perl the permission to listen on a priviledged port, or you need to run
Phoebe as a super user. Both are potential security risk, but the first option
is much less of a problem, I think.

If you want to try this, run the following as root:

    setcap 'cap_net_bind_service=+ep' $(which perl)

Verify it:

    getcap $(which perl)

If you want to undo this:

    setcap -r $(which perl)

Once you do that, no further configuration is necessary. Just add the following
to your F<config> file:

    use App::Phoebe::Spartan;

The alternative is to use a port number above 1024. Here's a way to do that:

    package App::Phoebe::Spartan;
    our $spartan_port = 7000; # listen on port 7000
    use App::Phoebe::Spartan;

If you don't do any of the above, you'll get a permission error on startup:
"Mojo::Reactor::Poll: Timer failed: Can't create listen socket: Permission
denied…"

=cut

package App::Phoebe::Spartan;
use App::Phoebe qw($server $log @main_menu get_ip_numbers space host_regex space_regex run_extensions
		   serve_index serve_page serve_raw serve_html serve_history serve_diff save_page
		   blog print_link text);
use Modern::Perl;
use URI::Escape;
use Encode qw(encode_utf8 decode_utf8 decode);
use Text::Wrapper;
use utf8;
no warnings 'redefine';

our $spartan_port ||= 300;

use Mojo::IOLoop;

# start the loop after configuration (so that the user can change $spartan_port)
Mojo::IOLoop->next_tick(\&spartan_startup);

sub spartan_startup {
  for my $host (keys %{$server->{host}}) {
    for my $address (get_ip_numbers($host)) {
      for my $port (ref $spartan_port ? @$spartan_port : $spartan_port) {
	$log->info("$host: listening on $address:$port (Spartan)");
	Mojo::IOLoop->server({
	  address => $address,
	  port => $port,
	} => sub {
	  my ($loop, $stream) = @_;
	  my $buffer;
	  my $request_host;
	  my $path;
	  my $length;
	  $stream->on(read => sub {
	    my ($stream, $bytes) = @_;
	    $log->debug("Received " . length($bytes) . " bytes via Spartan");
	    $buffer .= $bytes;
	    if (not $length and $buffer =~ /^(.*)\r\n/) {
	      my $request_line = $1;
	      if (($request_host, $path, $length) = $request_line =~ /^(\S+) (\S+) (\d+)/) {
		my $re = host_regex();
		if ($request_host !~ /^($re)$/) {
		  result($stream, "4", "We do not serve $request_host!");
		  $stream->close_gracefully();
		  return;
		}
		$buffer =~ s/^.*\r\n//; # strip request line
	      } else {
		result($stream, "4", "This request is garbage!");
		$stream->close_gracefully();
		return;
	      }
	    }
	    if (defined $length and $length == length($buffer)) {
	      serve_spartan($stream, $request_host, $path, $length, $buffer);
	    } else {
	      $log->debug("Waiting for more bytes...");
	    }
	  });
	});
      }
    }
  }
}

sub serve_spartan {
  my ($stream, $host, $path, $length, $buffer) = @_;
  eval {
    local $SIG{'ALRM'} = sub {
      $log->error("Timeout processing $host $path $length via Spartan");
    };
    alarm(10); # timeout
    my $spaces = space_regex();
    # note that path always starts with a slash!
    $log->info("Looking at $host $path $length via Spartan");
    my ($space, $id, $n);
    no warnings 'redefine';
    # we cannot import these subroutines and modify them, otherwise the
    # App::Phoebe code remains unchanged
    local *gemini_to_url = \&App::Phoebe::to_url;
    local *App::Phoebe::to_url = \&spartan_to_url;
    local *old_gemini_link = \&App::Phoebe::gemini_link;
    local *App::Phoebe::gemini_link = \&spartan_link;
    local *App::Phoebe::success = \&success;
    local *App::Phoebe::result = \&result;
    if (run_extensions($stream, $host, undef, $buffer, $path, $length)) {
      # config file goes first (note that $path and $length come at the end)
    } elsif (($space) = $path =~ m!^(?:/($spaces))?(?:/page)?/?$!) {
      # "up" from page/Alex gives us page or page/ → show main menu
      spartan_main_menu($stream, $host, space($stream, $host, $space));
    } elsif ($path eq "/do/source") {
      seek DATA, 0, 0;
      local $/ = undef; # slurp
      $stream->write(encode_utf8 <DATA>);
    } elsif ($length == 0 and ($space, $id, $n) = $path =~ m!^(?:/($spaces))?/page/([^/]+)(?:/(\d+))?$!) {
      $log->debug("Serving $id bytes via Spartan");
      serve_page($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
    } elsif ($length > 0 and ($space, $id, $n) = $path =~ m!^(?:/($spaces))?/page/([^/]+)$!) {
      $log->debug("Saving $length bytes via Spartan");
      save_page($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)),
		"text/plain", $buffer, $length);
    } elsif (($space, $id) = $path =~ m!^(?:/($spaces))?/raw/([^/]+)$!) {
      serve_raw($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)));
    } elsif (($space, $id) = $path =~ m!^(?:/($spaces))?/html/([^/]+)$!) {
      serve_html($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)));
    } elsif (($space, $id) = $path =~ m!^(?:/($spaces))?/history/([^/]+)$!) {
      serve_history($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), 10);
    } elsif (($space, $id, $n) = $path =~ m!^(?:/($spaces))?/diff/([^/]+)(?:/(\d+))?$!) {
      serve_diff($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
    } elsif (($space) = $path =~ m!^(?:/($spaces))?/do/index$!) {
      serve_index($stream, $host, space($stream, $host, $space));
    } else {
      $log->info("No handler for $host $path $length via spartan");
      result($stream, "5", "I do not know what to do with $host $path $length");
    }
    $log->debug("Done");
  };
  $log->error("Error: $@") if $@;
  alarm(0);
  $stream->close_gracefully();
}

sub success {
  my $stream = shift;
  my $type = shift || 'text/gemini; charset=UTF-8';
  $stream->write("2 $type\r\n");
}

sub result {
  my $stream = shift;
  my $code = substr(shift, 0, 1);
  my $meta = shift;
  $stream->write("$code $meta\r\n");
}

sub spartan_to_url {
  my ($stream, $host, $space, $id, $scheme) = @_;
  $scheme ||= "spartan";
  return gemini_to_url($stream, $host, $space, $id, $scheme);
}

sub spartan_link {
  my ($stream, $host, $space, $title, $id, $revision) = @_;
  return "" if $id and $id =~ m!^(?:do/blog|history)!;
  return old_gemini_link($stream, $host, $space, $title, $id, $revision);
}

sub spartan_main_menu {
  my $stream = shift;
  my $host = shift||"";
  my $space = shift||"";
  $log->info("Serving main menu");
  success($stream);
  my $page = $server->{wiki_main_page};
  if ($page) {
    $stream->write(encode_utf8 text($stream, $host, $space, $page) . "\n");
  } else {
    $stream->write("# Welcome to Phoebe!\n");
    $stream->write("\n");
  }
  blog($stream, $host, $space, 10);
  for my $id (@{$server->{wiki_page}}) {
    print_link($stream, $host, $space, $id);
  }
  for my $line (@main_menu) {
    $stream->write(encode_utf8 $line . "\n");
  }
  $stream->write("\n");
  print_link($stream, $host, $space, "Index of all pages", "do/index");
  # a requirement of the GNU Affero General Public License
  print_link($stream, $host, undef, "Source code", "do/source");
  $stream->write("\n");
}

1;
