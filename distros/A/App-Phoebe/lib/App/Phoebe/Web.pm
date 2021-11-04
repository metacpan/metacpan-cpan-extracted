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

App::Phoebe::Web - serve Phoebe wiki pages via the web

=head1 DESCRIPTION

Phoebe doesn’t have to live behind another web server like Apache or nginx. It
can be a (simple) web server, too!

This package gives web visitors read-only access to Phoebe. HTML is served via
HTTPS on the same port as everything else, i.e. 1965 by default.

There is no configuration. Simply add it to your F<config> file:

    use App::Phoebe::Web;

Beware: these days browser will refuse to connect to sites that have self-signed
certificates. You’ll have to click buttons and make exceptions and all of that,
or get your certificate from Let’s Encrypt or the like. That in turn is
aggravating for your Gemini visitors, since you are changing the certificate
every few months.

If you want to allow web visitors to comment on your pages, see
L<App::Phoebe::WebComments>; if you want to allow web visitors to edit pages,
see L<App::Phoebe::WebEdit>.

You can serve the wiki both on the standard Gemini port and on the standard
HTTPS port:

    phoebe --port=443 --port=1965

Note that 443 is a priviledge port. Thus, you either need to grant Perl the
permission to listen on a priviledged port, or you need to run Phoebe as a super
user. Both are potential security risk, but the first option is much less of a
problem, I think.

If you want to try this, run the following as root:

    setcap 'cap_net_bind_service=+ep' $(which perl)

Verify it:

    getcap $(which perl)

If you want to undo this:

    setcap -r $(which perl)

If you don't do any of the above, you'll get a permission error on startup:
"Mojo::Reactor::Poll: Timer failed: Can't create listen socket: Permission
denied…" You could, of course, always use a traditional web server like Apache
as a front-end, proxying all requests to your site on port 443 to port 1965.
This server config also needs access to the same certificates that Phoebe is
using, for port 443. The example below doesn’t rewrite C</.well-known> URLs
because these are used by Let’s Encrypt and others.

    <VirtualHost *:80>
	ServerName transjovian.org
	RewriteEngine on
	# Do not redirect /.well-known URL
	RewriteCond %{REQUEST_URI} !^/\.well-known/
	RewriteRule ^/(.*) https://%{HTTP_HOST}:1965/$1
    </VirtualHost>
    <VirtualHost *:443>
	ServerName transjovian.org
	RewriteEngine on
	# Do not redirect /.well-known URL
	RewriteCond %{REQUEST_URI} !^/\.well-known/
	RewriteRule ^/(.*) https://%{HTTP_HOST}:1965/$1
	SSLEngine on
	SSLCertificateFile      /var/lib/dehydrated/certs/transjovian.org/cert.pem
	SSLCertificateKeyFile   /var/lib/dehydrated/certs/transjovian.org/privkey.pem
	SSLCertificateChainFile /var/lib/dehydrated/certs/transjovian.org/chain.pem
	SSLVerifyClient None
    </VirtualHost>

Here’s an example where we wrap one the subroutines in App::Phoebe::Web in order
to change the default CSS that gets served. We keep a code reference to the
original, substitute our own, and when it gets called, it first calls the old
code to print some CSS, and then we append some CSS of our own. Also note how we
import C<$log>.

    # tested by t/example-dark-mode.t
    package App::Phoebe::DarkMode;
    use App::Phoebe qw($log);
    use App::Phoebe::Web;
    no warnings qw(redefine);

    # fully qualified because we're in a different package!
    *old_serve_css_via_http = \&App::Phoebe::Web::serve_css_via_http;
    *App::Phoebe::Web::serve_css_via_http = \&serve_css_via_http;

    sub serve_css_via_http {
      my $stream = shift;
      old_serve_css_via_http($stream);
      $log->info("Adding more CSS via HTTP (for dark mode)");
      $stream->write(<<'EOT');
    @media (prefers-color-scheme: dark) {
       body { color: #eeeee8; background-color: #333333; }
       a:link { color: #1e90ff }
       a:hover { color: #63b8ff }
       a:visited { color: #7a67ee }
    }
    EOT
    }

    1;

=cut

package App::Phoebe::Web;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(http_error handle_http_header);
use App::Phoebe qw(@request_handlers port space host_regex space_regex run_extensions text quote_html blog_pages
		   html_page to_html wiki_dir changes all_logs pages rss atom files $server $log @footer
		   space_links diff);
use File::Slurper qw(read_lines read_binary);
use Encode qw(encode_utf8 decode_utf8);
use List::Util qw(min);
use Modern::Perl;
use URI::Escape;
use utf8;

unshift(@request_handlers, '^GET .* HTTP/1\.[01]$' => \&handle_http_header);

sub handle_http_header {
  my $stream = shift;
  my $data = shift;
  # $log->debug("Reading HTTP headers");
  my @lines = split(/\r\n/, $data->{buffer}, -1); # including the empty line at the end
  foreach (@lines) {
    if (/^(\S+?): (.+?)\s*$/) {
      my $key = lc($1);
      $data->{headers}->{$key} = $2;
      my $data->{header_size} += length($_);
      # $log->debug("Header $key");
    } elsif ($_ eq "") {
      $data->{buffer} =~ s/^.*?\r\n\r\n//s; # possibly HTTP body
      # $log->debug("Handle HTTP request");
      $data->{headers}->{host} .= ":" . port($stream) if $data->{headers}->{host} and $data->{headers}->{host} !~ /:\d+$/;
      $log->debug("HTTP headers: " . join(", ", map { "$_ => '$data->{headers}->{$_}'" } keys %{$data->{headers}}));
      my $length = $data->{headers}->{'content-length'} || 0;
      return http_error($stream, "Content length invalid") if $length !~ /^\d+$/;
      return http_error($stream, "Content too long") if $length > $server->{wiki_page_size_limit};
      my $actual = length($data->{buffer});
      return http_error($stream, "Content longer than what the header says ($actual > $length):\n" . $data->{buffer}) if $actual > $length;
      if ($length == $actual) {
	# got the entire body as part of the first part
	process_http($stream, $data->{request}, $data->{headers}, $data->{buffer});
	$stream->close_gracefully();
	return;
      } elsif ($length) {
	# read body if it was sent in multiple parts
	$data->{handler} = \&handle_http_body;
	handle_http_body($stream, $data);
	return;
      }
      # otherwise wait for more header bytes
    }
    if ($data->{header_size} and $data->{header_size} > $server->{wiki_page_size_limit}) {
      $log->debug("This wiki does not allow more than $server->{wiki_page_size_limit} bytes of headers");
      result($stream, "400", "Bad request: headers too long");
      $stream->close_gracefully();
      return;
    }
  }
  # if we came here, the last line didn't match and needs more bytes
  $data->{buffer} = $lines[$#lines];
  $log->debug("Waiting for more HTTP headers ('$data->{buffer}')");
  return;
}

sub http_error {
  my $stream = shift;
  my $message = shift;
  $stream->write("HTTP/1.1 400 Bad Request\r\n");
  $stream->write("Content-Type: text/plain\r\n");
  $stream->write("\r\n");
  $stream->write("$message\n");
  $stream->close_gracefully();
  return 0;
}

sub handle_http_body {
  my $stream = shift;
  my $data = shift;
  $log->debug("Reading HTTP body");
  my $length = $data->{headers}->{'content-length'} || 0;
  my $actual = length($data->{buffer});
  if ($length == $actual) {
    # got the entire body
    process_http($stream, $data->{request}, $data->{headers}, $data->{buffer});
    $stream->close_gracefully();
    return;
  }
  $log->debug("Received $actual/$length bytes");
}

sub process_http {
  my $stream = shift;
  my $request = shift;
  my $headers = shift;
  my $buffer = shift;
  eval {
    local $SIG{'ALRM'} = sub {
      $log->error("Timeout processing $request");
    };
    alarm(10); # timeout
    my $hosts = host_regex();
    my $port = port($stream);
    my $spaces = space_regex();
    $log->info("Looking at $request");
    my ($host, $space, $id, $n, $filter);
    if (run_extensions($stream, $request, $headers, $buffer)) {
      # config file goes first
    } elsif ($request =~ m!^GET /default.css HTTP/1\.[01]$!
	and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_css_via_http($stream, $host);
    } elsif (($space) = $request =~ m!^GET (?:(?:/($spaces)/?)?|/) HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_main_menu_via_http($stream, $host, space($stream, $host, $space));
    } elsif (($space, $id, $n) = $request =~ m!^GET (?:/($spaces))?/page/([^/]*)(?:/(\d+))? HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_page_via_http($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
    } elsif (($space, $id, $n) = $request =~ m!^GET (?:/($spaces))?/file/([^/]*)(?:/(\d+))? HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_file_via_http($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
    } elsif (($space, $id, $n) = $request =~ m!^GET (?:/($spaces))?/history/([^/]*)(?:/(\d+))? HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_history_via_http($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n||10);
    } elsif (($space, $id, $n) = $request =~ m!^GET (?:/($spaces))?/diff/([^/]*)(?:/(\d+))? HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_diff_via_http($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n||10);
    } elsif (($space, $id, $n) = $request =~ m!^GET (?:/($spaces))?/raw/([^/]*)(?:/(\d+))? HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_raw_via_http($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
    } elsif ($request =~ m!^GET /robots.txt(?:[#?].*)? HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_raw_via_http($stream, $host, undef, 'robots');
    } elsif (($space, $id, $n) = $request =~ m!^GET (?:/($spaces))?/do/changes(?:/(\d+))? HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_changes_via_http($stream, $host, space($stream, $host, $space), $n||100);
    } elsif (($filter, $n) = $request =~ m!^GET /do/all(?:/(latest))?/changes(?:/(\d+))? HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_all_changes_via_http($stream, $host, $n||100, $filter||"");
    } elsif (($space, $id, $n) = $request =~ m!^GET (?:/($spaces))?/do/index HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_index_via_http($stream, $host, space($stream, $host, $space));
    } elsif (($space, $id, $n) = $request =~ m!^GET (?:/($spaces))?/do/files HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_files_via_http($stream, $host, space($stream, $host, $space));
    } elsif (($space, $id, $n) = $request =~ m!^GET (?:/($spaces))?/do/spaces HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_spaces_via_http($stream, $host, $port);
    } elsif (($space, $id, $n) = $request =~ m!^GET (?:/($spaces))?/do/rss HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_rss_via_http($stream, $host, space($stream, $host, $space));
    } elsif (($space, $id, $n) = $request =~ m!^GET (?:/($spaces))?/do/atom HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_atom_via_http($stream, $host, space($stream, $host, $space));
    } elsif (($space, $n) = $request =~ m!^GET /do/all/atom HTTP/1\.[01]$!
	     and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
      serve_all_atom_via_http($stream, $host);
    } else {
      $log->debug("No http handler for $request");
      http_error($stream, "Don't know how to handle $request");
    }
    $log->debug("Done");
  };
  $log->error("Error: $@") if $@;
  alarm(0);
  $stream->close_gracefully();
}

sub serve_main_menu_via_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving main menu via HTTP");
  my $page = $server->{wiki_main_page};
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/html\r\n");
  $stream->write("\r\n");
  $stream->write("<!DOCTYPE html>\n");
  $stream->write("<html>\n");
  $stream->write("<head>\n");
  $stream->write("<meta charset=\"utf-8\">\n");
  if ($page) {
    $stream->write(encode_utf8 "<title>" . quote_html($page) . "</title>\n");
  } else {
    $stream->write("<title>Phoebe</title>\n");
  }
  $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
  $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
  $stream->write("</head>\n");
  $stream->write("<body>\n");
  if ($page) {
    $stream->write(encode_utf8 to_html(text($stream, $host, $space, $page)) . "\n");
  } else {
    $stream->write("<h1>Welcome to Phoebe!</h1>\n");
  }
  blog_html($stream, $host, $space);
  $stream->write("<p>Important links:\n");
  $stream->write("<ul>\n");
  my @pages = @{$server->{wiki_page}};
  for my $id (@pages) {
    $stream->write(encode_utf8 "<li>" . link_html($stream, $host, $space, $id) . "\n");
  }
  $stream->write(encode_utf8 "<li>" . link_html($stream, $host, $space, "Changes", "do/changes") . "\n");
  $stream->write(encode_utf8 "<li>" . link_html($stream, $host, $space, "Index of all pages", "do/index") . "\n");
  $stream->write(encode_utf8 "<li>" . link_html($stream, $host, $space, "Index of all files", "do/files") . "\n")
      if @{$server->{wiki_mime_type}};
  $stream->write(encode_utf8 "<li>" . link_html($stream, $host, undef, "Index of all spaces", "do/spaces") . "\n")
      if @{$server->{wiki_space}} or keys %{$server->{host}} > 1;
  # a requirement of the GNU Affero General Public License
  $stream->write("<li><a href=\"https://metacpan.org/pod/App::Phoebe\">Source</a>\n");
  $stream->write("</ul>\n");
  $stream->write("</body>\n");
  $stream->write("</html>\n");
}

sub link_html {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $title = shift;
  my $id = shift;
  if (not $id) {
    $id = "page/$title";
  }
  my $port = port($stream);
  # don't encode the slash
  return "<a href=\"https://$host:$port/"
      . ($space && $space ne $host ? uri_escape_utf8($space) . "/" : "")
      . join("/", map { uri_escape_utf8($_) } split (/\//, $id))
      . "\">"
      . quote_html($title)
      . "</a>";
}

sub blog_html {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift || 10;
  my @blog = blog_pages($stream, $host, $space, $n);
  return unless @blog;
  $stream->write("<p>Blog:\n");
  $stream->write("<ul>\n");
  # we should check for pages marked for deletion!
  for my $id (@blog[0 .. min($#blog, $n - 1)]) {
    $stream->write(encode_utf8 "<li>" . link_html($stream, $host, $space, $id) . "\n");
  }
  $stream->write("</ul>\n");
}

sub serve_css_via_http {
  my $stream = shift;
  $log->info("Serving CSS via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/css\r\n");
  $stream->write("Cache-Control: public, max-age=86400, immutable\r\n"); # 24h
  $stream->write("\r\n");
  $stream->write("html { max-width: 70ch; padding: 2ch; margin: auto; color: #111; background: #ffe; }\n");
  $stream->write(".del { color: rgb(222,56,43); }\n"); # diff: deleted
  $stream->write(".ins { color: rgb(57,181,74); }\n"); # diff: inserted
}

sub serve_index_via_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving index of all pages via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/html\r\n");
  $stream->write("\r\n");
  $stream->write("<!DOCTYPE html>\n");
  $stream->write("<html>\n");
  $stream->write("<head>\n");
  $stream->write("<meta charset=\"utf-8\">\n");
  $stream->write("<title>All Pages</title>\n");
  $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
  $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
  $stream->write("</head>\n");
  $stream->write("<body>\n");
  $stream->write("<h1>All Pages</h1>\n");
  my @pages = pages($stream, $host, $space);
  if (@pages) {
    $stream->write("<ul>\n");
    for my $id (@pages) {
      $stream->write(encode_utf8 "<li>" . link_html($stream, $host, $space, $id) . "\n");
    }
    $stream->write("</ul>\n");
  } else {
    $stream->write("<p>The are no pages.\n");
  }
}

sub serve_files_via_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving all files via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/html\r\n");
  $stream->write("\r\n");
  $stream->write("<!DOCTYPE html>\n");
  $stream->write("<html>\n");
  $stream->write("<head>\n");
  $stream->write("<meta charset=\"utf-8\">\n");
  $stream->write("<title>All Files</title>\n");
  $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
  $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
  $stream->write("</head>\n");
  $stream->write("<body>\n");
  $stream->write("<h1>All Files</h1>\n");
  my @files = files($stream, $host, $space);
  if (@files) {
    $stream->write("<ul>\n");
    for my $id (sort @files) {
      $stream->write(encode_utf8 "<li>" . link_html($stream, $host, $space, $id, "file/$id") . "\n");
    }
    $stream->write("</ul>\n");
  } else {
    $stream->write("<p>The are no files.\n");
  }
}

sub serve_spaces_via_http {
  my $stream = shift;
  my $host = shift;
  my $port = shift;
  $log->info("Serving all spaces via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/html\r\n");
  $stream->write("\r\n");
  $stream->write("<!DOCTYPE html>\n");
  $stream->write("<html>\n");
  $stream->write("<head>\n");
  $stream->write("<meta charset=\"utf-8\">\n");
  $stream->write("<title>All Spaces</title>\n");
  $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
  $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
  $stream->write("</head>\n");
  $stream->write("<body>\n");
  $stream->write("<h1>All Spaces</h1>\n");
  $stream->write("<ul>\n");
  my $spaces = space_links($stream, "https", $host, $port);
  for my $url (sort keys %$spaces) {
    $stream->write(encode_utf8 "<li><a href=\"$url\">$spaces->{$url}</a>\n");
  }
  $stream->write("</ul>\n");
}

sub serve_changes_via_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift;
  $log->info("Serving $n changes via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/html\r\n");
  $stream->write("\r\n");
  $stream->write("<!DOCTYPE html>\n");
  $stream->write("<html>\n");
  $stream->write("<head>\n");
  $stream->write("<meta charset=\"utf-8\">\n");
  $stream->write("<title>Changes</title>\n");
  $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
  $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
  $stream->write("</head>\n");
  $stream->write("<body>\n");
  $stream->write("<h1>Changes</h1>\n");
  $stream->write("<ul>\n");
  $stream->write("<li>" . link_html($stream, $host, undef, "Changes for all spaces", "do/all/changes") . "\n")
      if @{$server->{wiki_space}};
  $stream->write("<li>" . link_html($stream, $host, $space, "Atom feed", "do/atom") . "\n");
  $stream->write("<li>" . link_html($stream, $host, $space, "RSS feed", "do/rss") . "\n");
  $stream->write("</ul>\n");
  my $dir = wiki_dir($host, $space);
  my $log = "$dir/changes.log";
  if (not -e $log) {
    $stream->write("<p>No changes.\n");
    return;
  }
  $stream->write("<p>Showing up to $n changes.\n");
  my $fh = File::ReadBackwards->new($log);
  my $more = changes($stream,
    $n,
    sub { $stream->write(encode_utf8 "<h2>" . shift . "</h2>\n") },
    sub { $stream->write("<p>" . shift . " by " . colourize_html($stream, shift) . "\n") },
    sub {
      my ($host, $space, $title, $id) = @_;
      $stream->write(encode_utf8 "<br> → " . link_html($stream, $host, $space, $title, $id) . "\n");
    },
    sub { $stream->write(encode_utf8 "<br> → $_[0]\n") },
    sub {
      return unless $_ = decode_utf8($fh->readline);
      chomp;
      split(/\x1f/), $host, $space, 0 });
  return unless $more;
  $stream->write("<p>" . link_html($stream, $host, $space, "More...", "do/changes/" . 10 * $n) . "\n");
}

sub serve_all_changes_via_http {
  my $stream = shift;
  my $host = shift;
  my $n = shift;
  my $filter = shift;
  $log->info($filter ? "Serving $n all $filter changes via HTTP" : "Serving $n all changes via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/html\r\n");
  $stream->write("\r\n");
  $stream->write("<!DOCTYPE html>\n");
  $stream->write("<html>\n");
  $stream->write("<head>\n");
  $stream->write("<meta charset=\"utf-8\">\n");
  $stream->write("<title>Changes for all spaces</title>\n");
  $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
  $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
  $stream->write("</head>\n");
  $stream->write("<body>\n");
  $stream->write("<h1>Changes for all spaces</h1>\n");
  $stream->write("<ul>\n");
  $stream->write("<li>" . link_html($stream, $host, undef, "Atom feed", "do/all/atom") . "\n");
  if ($filter) { $stream->write("<li>" . link_html($stream, $host, undef, "All changes", "do/all/changes/$n") . "\n") }
  else { $stream->write("<li>" . link_html($stream, $host, undef, "Latest changes", "do/all/latest/changes/$n") . "\n") }
  $stream->write("</ul>\n");
  my $log = all_logs($stream, $host, $n);
  if (not @$log) {
    $stream->write("<p>No changes.\n");
    return;
  }
  # taking the head of the @$log to get new log entries
  $stream->write("<p>Showing up to $n $filter changes.\n");
  my $more = changes($stream,
    $n,
    sub { $stream->write("<h2>" . shift . "</h2>\n") },
    sub { $stream->write("<p>" . shift . " by " . colourize_html($stream, shift) . "\n") },
    sub { $stream->write(encode_utf8 "<br> → " . link_html($stream, @_) . "\n") },
    sub { $stream->write(encode_utf8 "<br> → $_[0]\n") },
    sub { @{shift(@$log) }, 1 if @$log },
    undef,
    $filter);
  return unless $more;
  $stream->write("<p>" . link_html($stream, $host, undef, "More...", "do/all/changes/" . 10 * $n) . "\n");
}

# https://en.wikipedia.org/wiki/ANSI_escape_code#3/4_bit
sub colourize_html {
  my $stream = shift;
  my $code = shift;
  my %rgb = (
    0 => "0,0,0",
    1 => "222,56,43",
    2 => "57,181,74",
    3 => "255,199,6",
    4 => "0,111,184",
    5 => "118,38,113",
    6 => "44,181,233",
    7 => "204,204,204");
  $code = join("", map {
    "<span style=\"color: rgb($rgb{$_}); background-color: rgb($rgb{$_})\">$_</span>";
	       } split //, $code);
  return $code;
}

sub serve_rss_via_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving RSS via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: application/xml\r\n");
  $stream->write("\r\n");
  rss($stream, $host, $space, 'https');
}

sub serve_atom_via_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving Atom via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: application/xml\r\n");
  $stream->write("\r\n");
  my $dir = wiki_dir($host, $space);
  my $log = "$dir/changes.log";
  my $fh = File::ReadBackwards->new($log);
  atom($stream, sub {
    return unless $_ = decode_utf8($fh->readline);
    chomp;
    split(/\x1f/), $host, $space, 0
  }, $host, $space, 'https');
}

sub serve_all_atom_via_http {
  my $stream = shift;
  my $host = shift;
  $log->info("Serving Atom via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: application/xml\r\n");
  $stream->write("\r\n");
  my $log = all_logs($stream, $host, 30);
  atom($stream, sub { @{shift(@$log) }, 1 if @$log }, $host, undef, 'https');
}

sub serve_raw_via_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  $log->info("Serving raw $id via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/plain; charset=UTF-8\r\n");
  $stream->write("\r\n");
  $stream->write(encode_utf8 text($stream, $host, $space, $id, $revision));
}

sub serve_diff_via_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  $log->info("Serving the diff of $id via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/html\r\n");
  $stream->write("\r\n");
  $stream->write("<!DOCTYPE html>\n");
  $stream->write("<html>\n");
  $stream->write("<head>\n");
  $stream->write("<meta charset=\"utf-8\">\n");
  $stream->write(encode_utf8 "<title>Differences for " . quote_html($id) . "</title>\n");
  $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
  $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
  $stream->write("</head>\n");
  $stream->write("<body>\n");
  $stream->write(encode_utf8 "<h1>Differences for " . quote_html($id) . "</h1>\n");
  $stream->write("<p>Showing the differences between revision $revision and the current revision.\n");
  my $new = text($stream, $host, $space, $id);
  my $old = text($stream, $host, $space, $id, $revision);
  diff($old, $new,
       sub { $stream->write(encode_utf8 "<p>$_\n") for @_ },
       sub { $stream->write(encode_utf8 "<p class=\"del\">" . join("<br>", map { $_||"⏎" } @_) . "\n") },
       sub { $stream->write(encode_utf8 "<p class=\"ins\">" . join("<br>", map { $_||"⏎" } @_) . "\n") },
       sub { "<strong>$_</strong>" });
}

sub serve_page_via_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  $log->info("Serving $id as HTML via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/html\r\n");
  $stream->write("\r\n");
  html_page($stream, $host, $space, $id, $revision);
}

sub serve_history_via_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $n = shift;
  $log->info("Serve history for $id via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/html\r\n");
  $stream->write("\r\n");
  $stream->write("<!DOCTYPE html>\n");
  $stream->write("<html>\n");
  $stream->write("<head>\n");
  $stream->write("<meta charset=\"utf-8\">\n");
  $stream->write(encode_utf8 "<title>Page history for " . quote_html($id) . "</title>\n");
  $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
  $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
  $stream->write("</head>\n");
  $stream->write("<body>\n");
  $stream->write(encode_utf8 "<h1>Page history for " . quote_html($id) . "</h1>\n");
  my $dir = wiki_dir($host, $space);
  my $log = "$dir/changes.log";
  if (not -e $log) {
    $stream->write("<p>No changes.\n");
    return;
  }
  $stream->write("<p>Showing up to $n changes.\n");
  my $fh = File::ReadBackwards->new($log);
  my $first = 1;
  my $more = changes($stream,
    $n,
    sub { $stream->write(encode_utf8 "<h2>" . shift . "</h2>\n") },
    sub { $stream->write(encode_utf8 "<p>" . shift . " by " . colourize_html($stream, shift) . "\n") },
    sub {
      my ($host, $space, $title, $id) = @_;
      $stream->write(encode_utf8 "<br> → " . link_html($stream, $host, $space, $title, $id) . "\n");
    },
    sub { "<br> → $_[0]" },
    sub {
    READ:
      return unless $_ = decode_utf8($fh->readline);
      chomp;
      my ($ts, $id_log, $revision, $code) = split(/\x1f/);
      goto READ if $id_log ne $id;
      $ts, $id_log, $revision, $code, $host, $space, 0 });
  return unless $more;
  $stream->write("<p>" . link_html($stream, $host, $space, "More...", "history/" . uri_escape_utf8($id) . "/" . 10 * $n) . "\n");
}

sub serve_file_via_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  $log->info("Serve file $id");
  my $dir = wiki_dir($host, $space);
  my $file = "$dir/file/$id";
  my $meta = "$dir/meta/$id";
  if (not -f $file) {
    $stream->write("HTTP/1.1 404 Error\r\n");
    $stream->write("Content-Type: text/plain\r\n");
    $stream->write("\r\n");
    $stream->write("File not found\r\n");
    return;
  } elsif (not -f $meta) {
    $stream->write("HTTP/1.1 500 Error\r\n");
    $stream->write("Content-Type: text/plain\r\n");
    $stream->write("\r\n");
    $stream->write("Metadata not found\r\n");
    return;
  }
  my %meta = (map { split(/: /, $_, 2) } read_lines($meta));
  if (not $meta{'content-type'}) {
    $stream->write("HTTP/1.1 500 Error\r\n");
    $stream->write("Content-Type: text/plain\r\n");
    $stream->write("\r\n");
    $stream->write("Metadata corrupt\r\n");
    return;
  }
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: " . $meta{'content-type'} ."\r\n");
  $stream->write("\r\n");
  $stream->write(read_binary($file));
}
