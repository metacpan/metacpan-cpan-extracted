#!/usr/bin/perl
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

App::Phoebe - a Gemini-based wiki

=head1 DESCRIPTION

This module contains the core of the Phoebe wiki. Import functions and variables
from this module to write extensions, or to run it some other way. Usually,
F<script/phoebe> is used to start a Phoebe server. This is why all the
documentation regarding server startup can be found there.

This section describes some hooks you can use to customize your wiki using the
F<config> file, or using a Perl file (ending in F<*.pl> or F<*.pm>) in the
F<conf.d> directory. Once you're happy with the changes you've made, restart the
server, or send a SIGHUP if you know the PID.

Here are the ways you can hook into Phoebe code:

C<@extensions> is a list of code references allowing you to handle additional
URLs; return 1 if you handle a URL; each code reference gets called with $stream
(L<Mojo::IOLoop::Stream>), the first line of the request (a Gemini URL, a Gopher
selector, a finger user, a HTTP request line), a hash reference (with the
headers of HTTP requests or the parameters of Titan requests), a buffer of bytes
(e.g. for Titan or HTTP PUT or POST requests), and (sometimes) size.

C<@main_menu> adds more lines to the main menu, possibly links that aren't
simply links to existing pages.

C<@footer> is a list of code references allowing you to add things like licenses
or contact information to every page; each code reference gets called with
$stream (L<Mojo::IOLoop::Stream>), $host, $space, $id, $revision, and $format
('gemini' or 'html') used to serve the page; return a gemtext string to append
at the end; the alternative is to overwrite the C<footer> or C<html_footer> subs
– the default implementation for Gemini adds History, Raw text and HTML link,
and C<@footer> to the bottom of every page; the default implementation for HTTP
just adds C<@footer> to the bottom of every page.

If you do hook into Phoebe's code, you probably want to make use of the
following variables:

C<$server> stores the command line options provided by the user.

C<$log> is how you log things.

A very simple example to add a contact mail at the bottom of every page; this
works for both Gemini and the web:

    # tested by t/example-footer.t
    use App::Phoebe::Web;
    use App::Phoebe qw(@footer);
    push(@footer, sub { '=> mailto:alex@alexschroeder.ch Mail' });

This prints a very simply footer instead of the usual footer for Gemini, as the
C<footer> function is redefined. At the same time, the C<@footer> array is still
used for the web:

    # tested by t/example-footer2.t
    package App::Phoebe;
    use App::Phoebe::Web;
    use Modern::Perl;
    our (@footer); # HTML only
    push(@footer, sub { '=> https://alexschroeder.ch/wiki/Contact Contact' });
    # footer sub is Gemini only
    no warnings qw(redefine);
    sub footer {
      return "\n" . '—' x 10 . "\n" . '=> mailto:alex@alexschroeder.ch Mail';
    }

This example shows you how to add a new route (a new path served by the wiki).
Instead of just writing "Test" to the page, you could of course run arbitrary
Perl code.

    # tested by t/example-route.t
    our @config = (<<'EOT');
    use App::Phoebe qw(@extensions @main_menu port host_regex success);
    use Modern::Perl;
    push(@main_menu, "=> /do/test Test");
    push(@extensions, \&serve_test);
    sub serve_test {
      my $stream = shift;
      my $url = shift;
      my $hosts = host_regex();
      my $port = port($stream);
      if ($url =~ m!^gemini://($hosts):$port/do/test$!) {
	success($stream, 'text/plain; charset=UTF-8');
	$stream->write("Test\n");
	return 1;
      }
      return;
    }
    EOT

This example also shows how to redefine existing code in your config file
without the warning "Subroutine … redefined".

Here's a more elaborate example to add a new action the main menu and a handler
for it, for Gemini only:

    # tested by t/example-new-action.t
    package App::Phoebe;
    use Modern::Perl;
    our (@extensions, @main_menu);
    push(@main_menu, "=> gemini://localhost/do/test Test");
    push(@extensions, \&serve_test);
    sub serve_test {
      my $stream = shift;
      my $url = shift;
      my $headers = shift;
      my $host = host_regex();
      my $port = port($stream);
      if ($url =~ m!^gemini://($host)(?::$port)?/do/test$!) {
	result($stream, "20", "text/plain");
	$stream->write("Test\n");
	return 1;
      }
      return;
    }
    1;

=cut

package App::Phoebe;
use Modern::Perl '2018';
use File::Slurper qw(read_text read_binary read_dir write_text write_binary);
use Encode qw(encode_utf8 decode_utf8);
use Net::IDN::Encode qw(domain_to_ascii);
use Socket qw(:addrinfo SOCK_RAW);
use List::Util qw(first min any);
use File::ReadBackwards;
use Algorithm::Diff;
use URI::Escape;
use Mojo::IOLoop;
use Mojo::Log;
use utf8;

our $VERSION = 4.04;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(@extensions @main_menu @footer $log $server $full_url_regex
		    space port host_regex space_regex reserved_regex success
		    result get_ip_numbers run_extensions pages blog blog_pages
		    text save_page serve_index serve_page serve_raw serve_html
		    serve_history serve_diff html_page to_html @request_handlers
		    handle_request process_titan process_gemini valid_params
		    valid_id valid_mime_type valid_size valid_token print_link
		    all_logs gemini_link colourize modified changes diff
		    bogus_hash quote_html write_page @known_fingerprints
		    with_lock wiki_dir to_url handle_titan footer atom rss files
		    space_links search decode_query);

# Phoebe variables you can set in the config file

our (@extensions, @main_menu, @footer);
our $log ||= Mojo::Log->new(level => 'warn');
our $server = {host => {}};

our $protocols = 'https?|ftp|afs|news|nntp|mid|cid|mailto|wais|prospero|telnet|gophers?|irc|feed|gemini|xmpp';
our $chars = '[-a-zA-Z0-9/@=+$_~*.,;:?!\'"()&#%]'; # see RFC 2396
our $full_url_regex = "((?:$protocols):$chars+)";

our @known_fingerprints; # only used by extensions

# Conventions:
# - a regular exression on the first line of the request
# - a handle_foo sub to do wait until you're ready (take $stream and $data,
#   where $data->{buffer} keeps growing with bytes)
# - a process_foo sub to finish the job and write stuff back to the $stream

our @request_handlers = (
  '^titan://' => \&handle_titan,
  '^gemini://' => \&handle_gemini,
  '^[^:/?#]+://([^/?#]*)([^?#]*)(?:\?([^#]*))?(?:#(.*))?$' => \&handle_url,
);

# Phoebe subroutines you might want to call in your extensions

sub port {
  my $stream = shift;
  return 1965 unless $stream; # if called in a test situation
  return $stream->handle->sockport; # the actual port
}

sub get_ip_numbers {
  my $hostname = shift;
  my $punycode = domain_to_ascii($hostname);
  my @addresses;
  my ($err, @res) = getaddrinfo($punycode, "", {socktype => SOCK_RAW});
  $log->error("Cannot determine the IP number of $punycode: $err") if $err;
  for my $ai (@res) {
    my ($err, $ipaddr) = getnameinfo($ai->{addr}, NI_NUMERICHOST, NIx_NOSERV);
    $log->error("Cannot get a readable IP number of $punycode: $err") if $err;
    push(@addresses, $ipaddr) if $ipaddr;
  }
  return @addresses;
}

# The hostnames we know we want to serve because they were specified via --host
# options.
sub host_regex {
  my $stream = shift;
  my $re = join("|", map { quotemeta domain_to_ascii $_ } keys %{$server->{host}});
  return qr($re)i; # case insensitive hostnames
}

# A regular expression matching wiki spaces in URLs. The tricky part is that we
# must strip the hostnames, as these aren't repeated: for a URL like
# gemini://localhost:1965/alex/ the regular expression must just match 'alex'
# and it's space($stream, 'localhost', 'alex') that will check whether 'alex' is a
# legal space for localhost.
sub space_regex {
  my @spaces;
  if (keys %{$server->{host}} > 1) {
    for (@{$server->{wiki_space}}) {
      my ($space) = /\/(.*)/;
      push(@spaces, $space);
    }
  } elsif (@{$server->{wiki_space}}) {
    @spaces = @{$server->{wiki_space}};
  }
  return join("|", map { quotemeta } @spaces);
}

# A regular expression matching parts of reserved paths in URLs. When looking at
# gemini://localhost:1965/page/test or gemini://localhost:1965/do/index and
# using a client that has an "up" command, you'd end up at
# gemini://localhost:1965/page – but what should happen in this case? We should
# redirect these requests to gemini://localhost:1965/, I think.
sub reserved_regex {
  return join("|", qw(do page raw file html history diff));
}


sub success {
  my $stream = shift;
  my $type = shift || 'text/gemini; charset=UTF-8';
  my $lang = shift;
  if ($lang) {
    result($stream, "20", "$type; lang=$lang");
  } else {
    result($stream, "20", "$type");
  }
}

sub result {
  my $stream = shift;
  my $code = shift;
  my $meta = shift;
  my $data = shift||"";
  $stream->write("$code $meta\r\n$data");
}

sub handle_titan {
  my $stream = shift;
  my $data = shift;
  # extra processing of the request if we didn't do that, yet
  $data->{upload} ||= is_upload($stream, $data->{request}) or return;
  my $size = $data->{upload}->{params}->{size};
  my $actual = length($data->{buffer});
  if ($actual == $size) {
    $log->debug("Handle Titan request");
    process_titan($stream, $data->{request}, $data->{upload}, $data->{buffer}, $size);
    # do not close in case we're waiting for the lock
    return;
  } elsif ($actual > $size) {
    $log->debug("Received more than the promised $size bytes");
    result($stream, "59", "Received more than the promised $size bytes");
    $stream->close_gracefully();
    return;
  }
  $log->debug("Waiting for " . ($size - $actual) . " more bytes");
}

sub process_titan {
  my ($stream, $request, $upload, $buffer, $size) = @_;
  eval {
    local $SIG{'ALRM'} = sub { $log->error("Timeout processing upload $request") };
    alarm(10); # timeout
    if (run_extensions($stream, $request, $upload, $buffer, $size)) {
      # config file goes first
    } else {
      save_page($stream, $upload->{host}, $upload->{space}, $upload->{id},
		$upload->{params}->{mime}, $buffer, $size);
    }
    alarm(0);
  };
  # save page might still be waiting for the lock so we must not close the
  # stream: save_page will close the stream
  return unless $@;
  $log->error("Error: $@");
  $stream->close_gracefully();
}

sub save_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $type = shift;
  my $data = shift;
  my $length = shift;
  # If the operation succeeds, we can close the stream; if the operation fails,
  # we can close the stream; but if the operation was rescheduled, we must not
  # close the stream!
  if ($type ne "text/plain") {
    if ($length == 0) {
      with_lock($stream, $host, $space,
		sub {
		  delete_file($stream, $host, $space, $id);
		  $stream->close_gracefully();
		});
    } else {
      with_lock($stream, $host, $space,
		sub {
		  write_file($stream, $host, $space, $id, $data, $type);
		  $stream->close_gracefully();
		});
    }
  } elsif ($length == 0) {
    with_lock($stream, $host, $space,
	      sub {
		delete_page($stream, $host, $space, $id);
		$stream->close_gracefully();
	      });
  } elsif (utf8::decode($data)) { # decodes in-place and returns success
    with_lock($stream, $host, $space,
	      sub {
		write_page($stream, $host, $space, $id, $data);
		$stream->close_gracefully();
	      });
  } else {
    $log->debug("The text is invalid UTF-8");
    result($stream, "59", "The text is invalid UTF-8");
    $stream->close_gracefully();
  }
}

# We can't use C<flock> because this defaults to C<fcntl> which means they are
# I<per process>
sub with_lock {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $code = shift;
  my $count = shift || 0;
  my $dir = wiki_dir($host, $space);
  my $lock = "$dir/locked";
  # remove stale locks
  if (-e $lock) {
    my $age = time() - modified($lock);
    $log->debug("lock is ${age}s old");
    rmdir $lock if -e $lock and $age > 5;
  }
  if (mkdir($lock)) {
    $log->debug("Running code with lock $lock");
    eval { $code->() }; # protect against exceptions
    if ($@) {
      $log->error("Unable to run code with locked $lock: $@");
      result($stream, "40", "An error occured, unfortunately");
      $stream->close_gracefully();
    }
    # in the successful case, with_lock doesn't close in case there is more code
    # that needs to run, or possibly $code has closed the stream.
    rmdir($lock);
  } elsif ($count > 25) {
    $log->error("Unable to unlock $lock");
    result($stream, "40", "The wiki is locked; try again in a few seconds");
    $stream->close_gracefully();
  } else {
    $log->debug("Waiting $count...");
    Mojo::IOLoop->timer(0.2 => sub {
      with_lock($stream, $host, $space, $code, $count + 1)});
    # don't close the stream
  }
}

sub write_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $text = shift;
  $log->info("Writing page $id");
  my $dir = wiki_dir($host, $space);
  my $file = "$dir/page/$id.gmi";
  my $revision = 0;
  if (-e $file) {
    my $old = read_text($file);
    if ($old eq $text) {
      $log->info("$id is unchanged");
      result($stream, "30", to_url($stream, $host, $space, "page/$id"));
      return;
    }
    mkdir "$dir/keep" unless -d "$dir/keep";
    if (-d "$dir/keep/$id") {
      foreach (read_dir("$dir/keep/$id")) {
	$revision = $1 if m/^(\d+)\.gmi$/ and $1 > $revision;
      }
      $revision++;
    } else {
      mkdir "$dir/keep/$id";
      $revision = 1;
    }
    rename $file, "$dir/keep/$id/$revision.gmi";
  } else {
    my $index = "$dir/index";
    if (not open(my $fh, ">>:encoding(UTF-8)", $index)) {
      $log->error("Cannot write index $index: $!");
      result($stream, "59", "Unable to write index");
      return;
    } else {
      say $fh $id;
      close($fh);
    }
  }
  my $changes = "$dir/changes.log";
  if (not open(my $fh, ">>:encoding(UTF-8)", $changes)) {
    $log->error("Cannot write log $changes: $!");
    result($stream, "59", "Unable to write log");
    return;
  } else {
    my $peerhost = $stream->handle->peerhost;
    say $fh join("\x1f", scalar(time), $id, $revision + 1, bogus_hash($peerhost));
    close($fh);
  }
  mkdir "$dir/page" unless -d "$dir/page";
  eval { write_text($file, $text) };
  if ($@) {
    $log->error("Unable to save $id: $@");
    result($stream, "59", "Unable to save $id");
  } else {
    $log->info("Wrote $id");
    result($stream, "30", to_url($stream, $host, $space, "page/$id"));
  }
}

sub delete_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  $log->info("Deleting page $id");
  my $dir = wiki_dir($host, $space);
  my $file = "$dir/page/$id.gmi";
  if (-e $file) {
    my $revision = 0;
    mkdir "$dir/keep" unless -d "$dir/keep";
    if (-d "$dir/keep/$id") {
      foreach (read_dir("$dir/keep/$id")) {
	$revision = $1 if m/^(\d+)\.gmi$/ and $1 > $revision;
      }
      $revision++;
    } else {
      mkdir "$dir/keep/$id";
      $revision = 1;
    }
    # effectively deleting the file
    rename $file, "$dir/keep/$id/$revision.gmi";
  }
  my $index = "$dir/index";
  if (-f $index) {
    # remove $id from the index
    my @pages = grep { $_ ne $id } split /\n/, read_text $index;
    write_text($index, join("\n", @pages, ""));
  }
  my $changes = "$dir/changes.log";
  if (not open(my $fh, ">>:encoding(UTF-8)", $changes)) {
    $log->error("Cannot write log $changes: $!");
    result($stream, "59", "Unable to write log");
    return;
  } else {
    my $peerhost = $stream->handle->peerhost;
    say $fh join("\x1f", scalar(time), $id, "🖹", bogus_hash($peerhost));
    close($fh);
  }
  $log->info("Deleted page $id");
  result($stream, "30", to_url($stream, $host, $space, "page/$id"));
}

sub handle_gemini {
  my $stream = shift;
  my $data = shift;
  $log->debug("Handle Gemini request");
  $log->debug("Discarding " . length($data->{buffer}) . " bytes")
      if $data->{buffer};
  process_gemini($stream, $data->{request});
}

sub process_gemini {
  my ($stream, $url) = @_;
  eval {
    local $SIG{'ALRM'} = sub {
      $log->error("Timeout processing $url");
    };
    alarm(10); # timeout
    my $hosts = host_regex();
    my $port = port($stream);
    my $spaces = space_regex();
    my $reserved = reserved_regex($stream);
    $log->debug("Serving ($hosts)(?::$port)?");
    $log->debug("Spaces $spaces");
    my($scheme, $authority, $path, $query, $fragment) =
	$url =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;
    $log->info("Looking at $url");
    my ($host, $space, $id, $n, $style, $filter);
    if (run_extensions($stream, $url)) {
      # config file goes first
    } elsif (not $url) {
      $log->debug("The URL is empty");
      result($stream, "59", "URL expected");
    } elsif (length($url) > 1024) {
      $log->debug("The URL is too long");
      result($stream, "59", "The URL is too long");
    } elsif (($host, $n, $space) = $url =~ m!^(?:gemini:)?//($hosts)(:$port)?(?:/($spaces))?/(?:$reserved)$!) {
      # redirect gemini://localhost:2020/do to gemini://localhost:2020/
      # redirect gemini://localhost:2020/space/do to gemini://localhost:2020/space
      $space = space($stream, $host, $space) || "";
      result($stream, "31", "gemini://$host" . ($n ? ":$port" : "") . "/$space"); # this supports "up"
    } elsif (($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/?$!) {
      serve_main_menu($stream, $host, space($stream, $host, $space));
    } elsif (($host, $space, $n) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/more(?:/(\d+))?$!) {
      serve_blog($stream, $host, space($stream, $host, $space), $n);
    } elsif (($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/index$!) {
      serve_index($stream, $host, space($stream, $host, $space));
    } elsif (($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/files$!) {
      serve_files($stream, $host, space($stream, $host, $space));
    } elsif (($host) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/spaces$!) {
      serve_spaces($stream, $host, $port);
    } elsif (($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/data$!) {
      serve_data($stream, $host, space($stream, $host, $space));
    } elsif ($url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/match$!) {
      result($stream, "10", "Find page by name (Perl regex)");
    } elsif ($query and ($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/match\?!) {
      serve_match($stream, $host, space($stream, $host, $space), decode_query($query));
    } elsif ($url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/search$!) {
      result($stream, "10", "Find page by content (Perl regex)");
    } elsif ($query and ($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/search\?!) {
      serve_search($stream, $host, space($stream, $host, $space), decode_query($query)); # search terms include spaces
    } elsif ($url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/new$!) {
      result($stream, "10", "New page");
      # no URI escaping required
    } elsif ($query and ($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/new\?!) {
      if ($space) {
	result($stream, "30", "gemini://$host:$port/$space/raw/$query");
      } else {
	result($stream, "30", "gemini://$host:$port/raw/$query");
      }
    } elsif (($host, $space, $n, $style) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/changes(?:/(\d+))?(?:/(colour|fancy))?$!) {
      serve_changes($stream, $host, space($stream, $host, $space), $n||100, $style);
    } elsif (($host, $filter, $n, $style) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?/do/all(?:/(latest))?/changes(?:/(\d+))?(?:/(colour|fancy))?$!) {
      serve_all_changes($stream, $host, $n||100, $style||"", $filter||"");
    } elsif (($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/rss$!) {
      serve_rss($stream, $host, space($stream, $host, $space));
    } elsif (($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/blog/rss$!) {
      serve_blog_rss($stream, $host, space($stream, $host, $space));
    } elsif (($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/atom$!) {
      serve_atom($stream, $host, space($stream, $host, $space));
    } elsif (($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/blog/atom$!) {
      serve_blog_atom($stream, $host);
    } elsif (($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/all/atom$!) {
      serve_all_atom($stream, $host);
    } elsif (($host) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?/robots.txt(?:[#?].*)?$!) {
      serve_raw($stream, $host, undef, "robots");
    } elsif (($host, $space, $id, $n, $style) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/history/([^/]*)(?:/(\d+))?(?:/(colour|fancy))?$!) {
      serve_history($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n||10, $style);
    } elsif (($host, $space, $id, $n, $style) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/diff/([^/]*)(?:/(\d+))?(?:/(colour))?$!) {
      serve_diff($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n, $style);
    } elsif (($host, $space, $id, $n) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/raw/([^/]*)(?:/(\d+))?$!) {
      serve_raw($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
    } elsif (($host, $space, $id, $n) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/html/([^/]*)(?:/(\d+))?$!) {
      serve_html($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
    } elsif (($host, $space, $id, $n) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/page/([^/]+)(?:/(\d+))?$!) {
      serve_page($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $n);
    } elsif (($host, $space, $id) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/file/([^/]+)?$!) {
      serve_file($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)));
    } elsif (($host) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(/|$)!) {
      $log->info("Unknown path for $url\r");
      result($stream, "51", "Path not found for $url");
    } elsif ($authority) {
      $log->info("Unsupported proxy request for $url");
      result($stream, "53", "Unsupported proxy request for $url");
    } else {
      $log->info("No handler for $url");
      result($stream, "59", "Don't know how to handle $url");
    }
    $log->debug("Done");
  };
  $log->error("Error: $@") if $@;
  alarm(0);
  $stream->close_gracefully();
}

sub decode_query {
  my $query = shift;
  return $query unless $query;
  $query = decode_utf8(uri_unescape($query));
  $query =~ s/\+/ /g;
  return $query;
}

sub run_extensions {
  foreach my $sub (@extensions) {
    return 1 if $sub->(@_);
  }
  return;
}

sub serve_main_menu {
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
  print_link($stream, $host, $space, "Changes", "do/changes");
  print_link($stream, $host, $space, "Search matching page names", "do/match");
  print_link($stream, $host, $space, "Search matching page content", "do/search");
  print_link($stream, $host, $space, "New page", "do/new");
  $stream->write("\n");
  print_link($stream, $host, $space, "Index of all pages", "do/index");
  print_link($stream, $host, $space, "Index of all files", "do/files");
  print_link($stream, $host, undef, "Index of all spaces", "do/spaces")
      if @{$server->{wiki_space}} or keys %{$server->{host}} > 1;
  print_link($stream, $host, $space, "Download data", "do/data");
  # a requirement of the GNU Affero General Public License
  $stream->write("=> https://metacpan.org/pod/App::Phoebe Source code\n");
  $stream->write("\n");
}

sub handle_request {
  my $stream = shift;
  my $data = shift;
  if ($data->{buffer} =~ /^(.*)\r\n/) {
    $data->{request} = $1;
    $data->{buffer} =~ s/.*\r\n//;
    $log->debug("Looking at $data->{request}");
    for (my $i = 0; $i < @request_handlers; $i += 2) {
      my $re = $request_handlers[$i];
      if ($data->{request} =~ m!$re!i) {
	$data->{handler} = $request_handlers[$i+1];
	# and call the handler
	$data->{handler}->($stream, $data);
	return;
      }
    }
    $log->debug("No handler found for $data->{request}");
    result($stream, "59", "Cannot handle this request");
    $stream->close_gracefully();
  } else {
    $log->debug("Waiting for more bytes...");
  }
}

# special generic URL error handling to satisfy gemini-diagnostics
sub handle_url {
  my $stream = shift;
  my $data = shift;
  $log->debug("Unhandled proxy request");
  $log->debug("Discarding " . length($data->{buffer}) . " bytes")
      if $data->{buffer};
  result($stream, "53", "No proxying for $data->{request}");
  $stream->close_gracefully();
}

# if you call this yourself, $id must look like "page/foo"
sub to_url {
  my $stream = shift;
  my $host = lc shift;
  my $space = shift;
  my $id = shift;
  my $scheme = shift || "gemini";
  my $port = port($stream);
  if ($space) {
    $space = "" if $space eq $host;
    $space =~ s/.*\///;
    $space = uri_escape_utf8($space);
  }
  # don't encode the slash
  return "$scheme://$host:$port/"
      . ($space ? "$space/" : "")
      . join("/", map { uri_escape_utf8($_) } split (/\//, $id));
}

sub gemini_link {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $title = shift;
  my $id = shift;
  if (not $id) {
    $id = "page/$title";
  }
  return "=> $id $title" if $id =~ /^$full_url_regex$/;
  my $url = to_url($stream, $host, $space, $id);
  return "=> $url $title";
}

sub print_link {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $title = shift;
  my $id = shift;
  $stream->write(encode_utf8 gemini_link($stream, $host, $space, $title, $id) . "\n");
}

sub newest_first {
  my ($date_a, $article_a) = $a =~ /^(\d\d\d\d-\d\d(?:-\d\d)? ?)?(.*)/;
  my ($date_b, $article_b) = $b =~ /^(\d\d\d\d-\d\d(?:-\d\d)? ?)?(.*)/;
  return (($date_b and $date_a and $date_b cmp $date_a)
	  || ($article_a cmp $article_b)
	  # this last one should be unnecessary
	  || ($a cmp $b));
}

sub pages {
  my $stream = shift; # used by contributions like oddmuse.pl
  my $host = shift;
  my $space = shift;
  my $re = shift;
  my $dir = wiki_dir($host, $space);
  my $index = "$dir/index";
  if (not -f $index) {
    return if not -d "$dir/page";
    my @pages = map { s/\.gmi$//; $_ } read_dir("$dir/page");
    write_text($index, join("\n", @pages, ""));
    return sort newest_first @pages;
  }
  my @lines = sort newest_first split /\n/, read_text $index;
  return grep /$re/i, @lines if $re;
  return @lines;
}

sub blog_pages {
  my $stream = shift; # used by contributions like oddmuse.pl
  my $host = shift;
  my $space = shift;
  my $n = shift; # used by contributions like oddmuse.pl
  return sort { $b cmp $a } pages($stream, $host, $space, '^\d\d\d\d-\d\d-\d\d');
}

sub blog {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift || 10;
  my @blog = blog_pages($stream, $host, $space, $n);
  return unless @blog;
  $stream->write("Blog:\n");
  # we should check for pages marked for deletion!
  for my $id (@blog[0 .. min($#blog, $n - 1)]) {
    print_link($stream, $host, $space, $id);
  }
  print_link($stream, $host, $space, "More...", "do/more/" . ($n * 10)) if @blog > $n;
  print_link($stream, $host, $space, "Atom Feed", "do/blog/atom") if $n == 10;
  print_link($stream, $host, $space, "RSS Feed", "do/blog/rss") if $n == 10;
  $stream->write("\n");
}

sub quote_html {
  my $html = shift;
  $html =~ s/&/&amp;/g;
  $html =~ s/</&lt;/g;
  $html =~ s/>/&gt;/g;
  $html =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f]/ /g; # legal xml: #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
  return $html;
}

sub serve_blog {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift;
  success($stream);
  $log->info("Serving blog");
  $stream->write("# Blog\n");
  my @blog = blog_pages($stream, $host, $space, $n);
  if (not @blog) {
    $stream->write("There are no blog pages.\n");
    return;
  }
  $stream->write("Serving up to $n entries.\n");
  for my $id (@blog[0 .. min($#blog, $n - 1)]) {
    print_link($stream, $host, $space, $id);
  }
  print_link($stream, $host, $space, "More...", "do/more/" . ($n * 10)) if @blog > $n;
}

sub serve_index {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  success($stream);
  $log->info("Serving index of all pages");
  $stream->write("# All Pages\n");
  my @pages = pages($stream, $host, $space);
  $stream->write("There are no pages.\n") unless @pages;
  for my $id (@pages) {
    print_link($stream, $host, $space, $id);
  }
}

sub files {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $re = shift;
  my $dir = wiki_dir($host, $space);
  $dir = "$dir/file";
  return if not -d $dir;
  my @files = map { decode_utf8($_) } read_dir($dir);
  return grep /$re/i, @files if $re;
  return @files;
}

sub serve_files {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  success($stream);
  $log->info("Serving index of all files");
  $stream->write("# All Files\n");
  my @files = files($stream, $host, $space);
  $stream->write("The are no files.\n") unless @files;
  for my $id (sort @files) {
    print_link($stream, $host, $space, $id, "file/$id");
  }
}

sub serve_spaces {
  my $stream = shift;
  my $host = shift;
  my $port = shift;
  success($stream);
  $log->info("Serving all spaces");
  $stream->write("# Spaces\n");
  my $spaces = space_links($stream, "gemini", $host, $port);
  for my $url (sort keys %$spaces) {
    $stream->write(encode_utf8 "=> $url $spaces->{$url}\n");
  }
}

sub serve_data {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  # use /bin/tar instead of Archive::Tar to save memory
  my $dir = wiki_dir($host, $space);
  my $file = "$dir/data.tar.gz";
  if (-e $file and time() - modified($file) <= 300) { # data is valid for 5 minutes
    $log->info("Serving cached data archive");
    success($stream, "application/tar");
    $stream->write(read_binary($file));
  } else {
    write_binary($file, ""); # truncate in order to avoid "file changed as we read it" warning
    my @command = ('/bin/tar', '--create', '--gzip',
		   '--file', $file,
		   '--exclude', "data.tar.gz",
		   '--directory', "$dir/..",
		   ((split(/\//,$dir))[-1]));
    $log->debug("@command");
    if (system(@command) == 0) {
      $log->info("Serving new data archive");
      success($stream, "application/tar");
      $stream->write(read_binary($file));
    } else {
      $log->error("Creation of data archive failed");
      result($stream, "59", "Archive creation failed");
    }
  }
}

sub serve_match {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $match = shift;
  if (not $match) {
    result($stream, "59", "Search term is missing");
    return;
  }
  success($stream);
  $log->info("Serving pages matching $match");
  $stream->write(encode_utf8 "# Search page titles for $match\n");
  $stream->write("Use a Perl regular expression to match page titles.\n");
  my @pages = pages($stream, $host, $space, $match);
  $stream->write("No matching page names found.\n") unless @pages;
  for my $id (@pages) {
    print_link($stream, $host, $space, $id);
  }
}

sub serve_search {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $str = shift;
  if (not $str) {
    result($stream, "59", "Search term is missing");
    return;
  }
  success($stream);
  $log->info("Serving search result for $str");
  $stream->write(encode_utf8 "# Search page content for $str\n");
  $stream->write("Use a Perl regular expression to match page titles and page content.\n");
  if (not search($stream, $host, $space, $str, sub { highlight($stream, @_) })) {
    $stream->write("Search term not found.\n");
  }
}

sub search {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $str = shift;
  my $func = shift;
  my @pages = pages($stream, $host, $space);
  return unless @pages;
  my $found = 0;
  for my $id (@pages) {
    my $text = text($stream, $host, $space, $id);
    if ($id =~ /$str/i or $text =~ /$str/i) {
      $func->($host, $space, $id, $text, $str);
      $found++;
    }
  }
  return $found;
}

sub highlight {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $text = shift;
  my $str = shift;
  my ($snippetlen, $maxsnippets) = (100, 4); #  these seem nice.
  # show a snippet from the beginning of the document
  my $j = index($text, ' ', $snippetlen); # end on word boundary
  my $t = substr($text, 0, $j);
  my $result = "## $id\n$t … ";
  $text = substr($text, $j);  # to avoid rematching
  my $jsnippet = 0 ;
  while ($jsnippet < $maxsnippets and $text =~ m/($str)/i) {
    $jsnippet++;
    if (($j = index($text, $1)) > -1 ) {
      # get substr containing (start of) match, ending on word boundaries
      my $start = index($text, ' ', $j - $snippetlen / 2);
      $start = 0 if $start == -1;
      my $end = index($text, ' ', $j + $snippetlen / 2);
      $end = length($text) if $end == -1;
      $t = substr($text, $start, $end - $start);
      $result .= $t . ' … ';
      # truncate text to avoid rematching the same string.
      $text = substr($text, $end);
    }
  }
  $stream->write(encode_utf8 $result . "\n");
  print_link($stream, $host, $space, $id);
}

sub serve_changes {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift;
  my $style = shift;
  $log->info("Serving $n changes");
  success($stream);
  $stream->write("# Changes\n");
  if (not $style) { print_link($stream, $host, $space, "Colour changes", "do/changes/$n/colour") }
  elsif ($style eq "colour") { print_link($stream, $host, $space, "Fancy changes", "do/changes/$n/fancy") }
  elsif ($style eq "fancy") { print_link($stream, $host, $space, "Normal changes", "do/changes/$n") }
  print_link($stream, $host, undef, "Changes for all spaces", "do/all/changes")
      if @{$server->{wiki_space}};
  print_link($stream, $host, $space, "Atom Feed", "do/atom");
  print_link($stream, $host, $space, "RSS Feed", "do/rss");
  my $dir = wiki_dir($host, $space);
  my $log = "$dir/changes.log";
  if (not -e $log) {
    $stream->write("No changes.\n");
    return;
  }
  $stream->write("Showing up to $n changes.\n");
  my $fh = File::ReadBackwards->new($log);
  return unless changes($stream,
    $n,
    sub { $stream->write(encode_utf8 "## " . shift . "\n") },
    sub { $stream->write(shift . " by " . colourize($stream, shift, $style) . "\n") },
    sub { print_link($stream, @_) },
    sub { $stream->write(encode_utf8 join("\n", @_, "")) },
    sub {
      return unless $_ = decode_utf8($fh->readline);
      chomp;
      split(/\x1f/), $host, $space, 0 },
    undef, #$kept
    undef, #$filter
    $style);
  $stream->write("\n");
  print_link($stream, $host, $space, "More...", "do/changes/" . 10 * $n . ($style ? "/$style" : ""));
}

sub serve_all_changes {
  my $stream = shift;
  my $host = shift;
  my $n = shift;
  my $style = shift;
  my $filter = shift;
  $log->info($filter ? "Serving $n all $filter changes" :  "Serving $n all changes");
  success($stream);
  $stream->write("# Changes for all spaces\n");
  # merge all logs
  my $log = all_logs($stream, $host, $n);
  if (not @$log) {
    $stream->write("No changes.\n");
    return;
  }
  my $filter_segment = $filter ? "/$filter" : "";
  my $style_segment = $style ? "/$style" : "";
  if (not $style) { print_link($stream, $host, undef, "Colour changes", "do/all$filter_segment/changes/$n/colour") }
  elsif ($style eq "colour") { print_link($stream, $host, undef, "Fancy changes", "do/all$filter_segment/changes/$n/fancy") }
  elsif ($style eq "fancy") { print_link($stream, $host, undef, "Normal changes", "do/all$filter_segment/changes/$n") }
  if ($filter) { print_link($stream, $host, undef, "All changes", "do/all/changes/$n$style_segment") }
  else { print_link($stream, $host, undef, "Latest changes", "do/all/latest/changes/$n$style_segment") }
  # taking the head of the @$log to get new log entries
  print_link($stream, $host, undef, "Atom Feed", "do/all/atom");
  my $filter_description = $filter ? " $filter" : "";
  $stream->write("Showing up to $n$filter_description changes.\n");
  return unless changes($stream,
    $n,
    sub { $stream->write("## " . shift . "\n") },
    sub { $stream->write(shift . " by " . colourize($stream, shift, $style) . "\n") },
    sub { print_link($stream, @_) },
    sub { $stream->write(encode_utf8 join("\n", @_, "")) },
    sub { @{shift(@$log) }, 1 if @$log },
    undef, # $kept
    $filter,
    $style);
  $stream->write("\n");
  print_link($stream, $host, undef, "More...", "do/all/changes/" . 10 * $n . ($style ? "/$style" : ""));
}

sub all_logs {
  my $stream = shift;
  my $host = shift;
  my $n = shift;
  my $filter = shift;
  # merge all logs
  my @log;
  my $dir = $server->{wiki_dir};
  my @spaces = space_dirs();
  for my $space (@spaces) {
    my $changes = $dir;
    $changes .= "/$space" if $space;
    $changes .= "/changes.log";
    next unless -f $changes;
    $log->debug("Reading $changes");
    next unless my $fh = File::ReadBackwards->new($changes);
    if (keys %{$server->{host}} > 1) {
      push(@log, @{read_log($stream, $fh, $n, split(/\//, $space, 2), $filter)});
    } else {
      push(@log, @{read_log($stream, $fh, $n, $host, $space, $filter)});
    }
  }
  @log = sort { $b->[0] <=> $a->[0] } @log;
  return \@log;
 }

sub read_log {
  my $stream = shift;
  my $fh = shift; # File::ReadBackwards
  my $n = shift;
  my $host = shift;
  my $space = shift;
  my $filter = shift;
  my @changes;
  for (1 .. $n) {
    $_ = decode_utf8($fh->readline);
    # $_ can be undefined or a newline (which won't split)
    last unless $_ and $_ ne "\n";
    next if $filter and not /$filter/;
    chomp;
    push(@changes, [split(/\x1f/), $host, $space]);
  }
  $log->debug("Read changes: " . @changes);
  return \@changes;
}

# $n is the number of changes to show. $header is a code reference that prints a
# header for the date (one argument). $change is a code reference that prints
# the time and code of the person making the change (two arguments). $link is a
# code reference that prints a link (four arguments). $nolink is a code reference
# that prints a name that isn't linked (one argument). $next is a code reference
# that returns the list of attributes for the next change, these attributes
# being: the timestamp (as returned by time); the page or file name; the page
# revision or zero if a file; the code to represent the person that made the
# change, represented as a string of octal digits that will be fed to the
# colourize sub; the host, and the spaces, if any; and a boolean if space and
# page or file name should both be shown (up to seven arguments). Finally, the
# optional argument $kept is a code reference to say whether an old revision
# actually exists. If not, there's no point in showing a diff link. The default
# implementation checks for the existence of the keep file. $filter describes
# how changes are to be filtered: 'latest' means that only the latest change
# will be shown, i.e. a link to current revision. The default is to show all
# changes. $style is "coloured" or "fancy" or undefined to indicate what sort of
# changes we are looking at.
sub changes {
  my $stream = shift;
  my $n = shift;
  my $header = shift;
  my $change = shift;
  my $link = shift;
  my $nolink = shift;
  my $next = shift;
  my $kept = shift || sub {
    my ($host, $space, $id, $revision) = @_;
    -e wiki_dir($host, $space) . "/keep/$id/$revision.gmi";
  };
  my $filter = shift||'';
  my $style = shift;
  my $last_day = '';
  my %seen;
  for (1 .. $n) {
    my ($ts, $id, $revision, $code, $host, $space, $show_space) = $next->();
    return unless $ts and $id;
    my $name = name($stream, $id, $host, $space, $show_space);
    next if $filter eq "latest" and $seen{$name};
    my $day = day($stream, $ts);
    if ($day ne $last_day) {
      $header->($day);
      $last_day = $day;
    }
    $change->(time_of_day($stream, $ts), $code);
    if ($revision eq "🖹") {
      # a deleted page
      $link->($host, $space, "$name (deleted)", "page/$id");
      $link->($host, $space, "History", "history/$id" . ($style ? "/10/$style" : ""));
      $seen{$name} = 1;
    } elsif ($revision eq "🖻") {
      # a deleted file
      $nolink->("$name (deleted file)");
      $seen{$name . "\x1c"} = 1;
    } elsif ($revision > 0) {
      # a page
      if ($seen{$name}) {
	$link->($host, $space, "$name ($revision)", "page/$id/$revision");
	# there is no fancy diff, just colour diff
	$link->($host, $space, "Differences", "diff/$id/$revision" . ($style ? "/colour" : ""))
	    if $kept->($host, $space, $id, $revision);
      } elsif ($filter eq "latest") {
	$link->($host, $space, "$name", "page/$id");
	$link->($host, $space, "History", "history/$id");
	$seen{$name} = 1;
      } else {
	$link->($host, $space, "$name (current)", "page/$id");
	$link->($host, $space, "History", "history/$id" . ($style ? "/10/$style" : ""));
	$seen{$name} = 1;
      }
    } else {
      # a file
      if ($seen{$name . "\x1c"}) {
	$nolink->("$name (file)");
      } else {
	$link->($host, $space, "$name (file)", "file/$id");
	$seen{$name . "\x1c"} = 1;
      }
    }
  }
  return () = $next->(); # return something, if there's more
}

sub name {
  my $stream = shift;
  my $id = shift;
  my $host = shift;
  my $space = shift;
  my $show_space = shift;
  if ($show_space) {
    if (keys %{$server->{host}} > 1) {
      if ($space) {
	return "[$host/$space] $id";
      } else {
	return "[$host] $id";
      }
    } elsif ($space) {
      return "[$space] $id";
    }
  }
  return $id;
}

sub colourize {
  my $stream = shift;
  my $code = shift;
  my $style = shift;
  my %rgb;
  return $code unless $style;
  if ($style eq "colour") {
    # 3/4 bit
    return join("", map { "\033[1;3${_};4${_}m${_}" } split //, $code) . "\033[0m ";
  } elsif ($style eq "fancy") {
    # 24 bit!
    %rgb = (
    0 => "0;0;0",
    1 => "222;56;43",
    2 => "57;181;74",
    3 => "255;199;6",
    4 => "0;111;184",
    5 => "118;38;113",
    6 => "44;181;233",
    7 => "204;204;204");
    return join("", map { "\033[38;2;$rgb{$_};48;2;$rgb{$_}m$_" } split //, $code) . "\033[0m ";
  }
  return $code;
}

sub serve_rss {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving Gemini RSS");
  success($stream, "application/rss+xml");
  rss($stream, $host, $space, 'gemini');
}

sub rss {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $scheme = shift;
  my $name = $server->{wiki_main_page} || "Phoebe";
  my $port = port($stream);
  $stream->write("<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n");
  $stream->write("<channel>\n");
  $stream->write(encode_utf8 "<title>" . quote_html($name) . "</title>\n");
  $stream->write("<description>Changes on this wiki.</description>\n");
  $stream->write("<link>$scheme://$host:$port/</link>\n");
  $stream->write("<atom:link rel=\"self\" type=\"application/rss+xml\" href=\"$scheme://$host:$port/do/rss\" />\n");
  $stream->write("<generator>Phoebe</generator>\n");
  $stream->write("<docs>http://blogs.law.harvard.edu/tech/rss</docs>\n");
  my $dir = wiki_dir($host, $space);
  my $log = "$dir/changes.log";
  if (-e $log and my $fh = File::ReadBackwards->new($log)) {
    my %seen;
    for (1 .. 100) {
      last unless $_ = decode_utf8($fh->readline);
      chomp;
      my ($ts, $id, $revision, $code) = split(/\x1f/);
      next if $seen{$id};
      $seen{$id} = 1;
      $stream->write("<item>\n");
      $stream->write(encode_utf8 "<title>" . quote_html($id) . "</title>\n");
      my $link = to_url($stream, $host, $space, "page/$id", $scheme);
      $stream->write("<link>$link</link>\n");
      $stream->write("<guid>$link</guid>\n");
      $stream->write(encode_utf8 "<description>" . quote_html(text($stream, $host, $space, $id)) . "</description>\n");
      my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($ts); # Sat, 07 Sep 2002 00:00:01 GMT
      $stream->write("<pubDate>"
		     . sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT", qw(Sun Mon Tue Wed Thu Fri Sat)[$wday], $mday,
			       qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$mon], $year + 1900, $hour, $min, $sec)
		     . "</pubDate>\n");
      $stream->write("</item>\n");
    }
  }
  $stream->write("</channel>\n");
  $stream->write("</rss>\n");
}

sub serve_blog_rss {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving Gemini Blog RSS");
  success($stream, "application/rss+xml");
  blog_rss($stream, $host, $space, 'gemini');
}

sub blog_rss {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $scheme = shift;
  my $name = $server->{wiki_main_page} || "Phoebe";
  my $port = port($stream);
  $stream->write("<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n");
  $stream->write("<channel>\n");
  $stream->write(encode_utf8 "<title>" . quote_html($name) . "</title>\n");
  $stream->write("<description>Blog pages on this wiki.</description>\n");
  $stream->write("<link>$scheme://$host:$port/</link>\n");
  $stream->write("<atom:link rel=\"self\" type=\"application/rss+xml\" href=\"$scheme://$host:$port/do/blog/rss\" />\n");
  $stream->write("<generator>Phoebe</generator>\n");
  $stream->write("<docs>http://blogs.law.harvard.edu/tech/rss</docs>\n");
  my $dir = wiki_dir($host, $space);
  my @blog = blog_pages($stream, $host, $space, 10);
  my $ts = changes_for($host, $space, @blog);
  # hard coded: 10 pages blog RSS, no pagination
  for my $id (@blog[0 .. min($#blog, 9)]) {
    $stream->write("<item>\n");
    $stream->write(encode_utf8 "<title>" . quote_html($id) . "</title>\n");
    my $link = to_url($stream, $host, $space, "page/$id", $scheme);
    $stream->write("<link>$link</link>\n");
    $stream->write("<guid>$link</guid>\n");
    $stream->write(encode_utf8 "<description>" . quote_html(text($stream, $host, $space, $id)) . "</description>\n");
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($ts->{$id}); # Sat, 07 Sep 2002 00:00:01 GMT
    $stream->write("<pubDate>"
		   . sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT", qw(Sun Mon Tue Wed Thu Fri Sat)[$wday], $mday,
			     qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$mon], $year + 1900, $hour, $min, $sec)
		   . "</pubDate>\n");
    $stream->write("</item>\n");
  }
  $stream->write("</channel>\n");
  $stream->write("</rss>\n");
}

sub changes_for {
  my $host = shift;
  my $space = shift;
  my @ids = @_;
  my %result;
  my $dir = wiki_dir($host, $space);
  my $log = "$dir/changes.log";
  if (-e $log and my $fh = File::ReadBackwards->new($log)) {
    while (@ids) {
      last unless $_ = decode_utf8($fh->readline);
      chomp;
      my ($ts, $id, $revision, $code) = split(/\x1f/);
      if (any { $_ eq $id } @ids) {
	@ids = grep { $_ ne $id } @ids;
	$result{$id} = $ts;
      }
    }
  }
  return \%result;
}

sub serve_atom {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving Gemini Atom");
  success($stream, "application/atom+xml");
  my $dir = wiki_dir($host, $space);
  my $log = "$dir/changes.log";
  my $fh = File::ReadBackwards->new($log);
  atom($stream, sub {
    return unless $_ = decode_utf8($fh->readline);
    chomp;
    split(/\x1f/), $host, $space, 0
  }, $host, $space, 'gemini');
}

sub serve_all_atom {
  my $stream = shift;
  my $host = shift;
  $log->info("Serving Gemini Atom");
  success($stream, "application/atom+xml");
  my $log = all_logs($stream, $host, 30);
  atom($stream, sub { @{shift(@$log) }, 1 if @$log }, $host, undef, 'gemini');
}

# $next is a code reference that returns the list of attributes for the next
# change, these attributes being: the timestamp (as returned by time); the page
# or file name; the page revision or zero if a file; the code to represent the
# person that made the change, represented as a string of octal digits that will
# be fed to the colourize sub; the host, and the spaces, if any; and a boolean
# if space and page or file name should both be shown (up to seven arguments).
# $scheme is either 'gemini' or 'https'.
sub atom {
  my $stream = shift;
  my $next = shift;
  my $host = shift;
  my $space = shift;
  my $scheme = shift;
  my $first_host = shift;
  my $name = $server->{wiki_main_page} || "Phoebe";
  my $port = port($stream);
  $stream->write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
  $stream->write("<feed xmlns=\"http://www.w3.org/2005/Atom\">\n");
  $stream->write(encode_utf8 "<title>" . quote_html($name) . "</title>\n");
  my $link = to_url($stream, $host, $space, "", $scheme);
  $stream->write("<link href=\"$link\"/>\n");
  $link = to_url($stream, $host, $space, "do/atom", $scheme);
  $stream->write("<link rel=\"self\" type=\"application/atom+xml\" href=\"$link\"/>\n");
  $stream->write("<id>$link</id>\n");
  my $feed_ts = "0001-01-01T00:00:00Z";
  $stream->write("<generator uri=\"https://alexschroeder.ch/cgit/phoebe/about/\" version=\"1.0\">Phoebe</generator>\n");
  my %seen;
  for (1 .. 100) {
    my ($ts, $id, $revision, $code, $host, $space, $show_space) = $next->();
    last unless $ts and $id;
    my $name = name($stream, $id, $host, $space, $show_space);
    if ($revision eq "🖹") {
      next if $seen{$name};
      # a deleted page
      $stream->write("<entry>\n");
      $stream->write(encode_utf8 "<title>" . quote_html($name) . " (deleted)</title>\n");
      $seen{$name} = 1;
    } elsif ($revision eq "🖻") {
      # a deleted file
      next if $seen{$name . "\x1c"};
      $stream->write("<entry>\n");
      $stream->write(encode_utf8 "<title>" . quote_html($name) . " (deleted file)</title>\n");
      $seen{$name . "\x1c"} = 1;
    } elsif ($revision > 0) {
      # a page
      next if $seen{$name};
      $stream->write("<entry>\n");
      $stream->write(encode_utf8 "<title>" . quote_html($name) . "</title>\n");
      my $link = to_url($stream, $host, $space, "page/$id", $scheme);
      $stream->write("<link href=\"$link\"/>\n");
      $stream->write("<id>$link</id>\n");
      $stream->write(encode_utf8 "<content type=\"text\">" . quote_html(text($stream, $host, $space, $id)) . "</content>\n");
      $seen{$name} = 1;
    } else {
      # a file
      next if $seen{$name . "\x1c"};
      $stream->write("<entry>\n");
      $stream->write(encode_utf8 "<title>" . quote_html($name) . " (file)</title>\n");
      my $link = to_url($stream, $host, $space, "file/$id", $scheme);
      $stream->write("<link href=\"$link\"/>\n");
      $stream->write("<id>$link</id>\n");
      $seen{$name . "\x1c"} = 1;
    }
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime($ts); # 2003-12-13T18:30:02Z
    $ts = sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
    $stream->write("<updated>$ts</updated>\n");
    $feed_ts = $ts if $ts gt $feed_ts;
    $stream->write("<author><name>$code</name></author>\n");
    $stream->write("</entry>\n");
  }
  $stream->write("<updated>$feed_ts</updated>\n");
  $stream->write("</feed>\n");
}

sub serve_blog_atom {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving Gemini Blog Atom");
  success($stream, "application/atom+xml");
  blog_atom($stream, $host, $space, 'gemini');
}

sub blog_atom {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $scheme = shift;
  my $name = $server->{wiki_main_page} || "Phoebe";
  my $port = port($stream);
  $stream->write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
  $stream->write("<feed xmlns=\"http://www.w3.org/2005/Atom\">\n");
  $stream->write(encode_utf8 "<title>" . quote_html($name) . "</title>\n");
  my $link = to_url($stream, $host, $space, "", $scheme);
  $stream->write("<link href=\"$link\"/>\n");
  $link = to_url($stream, $host, $space, "do/blog/atom", $scheme);
  $stream->write("<link rel=\"self\" type=\"application/atom+xml\" href=\"$link\"/>\n");
  $stream->write("<id>$link</id>\n");
  my $feed_ts = "0001-01-01T00:00:00Z";
  $stream->write("<generator uri=\"https://alexschroeder.ch/cgit/phoebe/about/\" version=\"1.0\">Phoebe</generator>\n");
  my $dir = wiki_dir($host, $space);
  my @blog = blog_pages($stream, $host, $space, 10);
  my $changes = changes_for($host, $space, @blog);
  # hard coded: 10 pages blog ATOM, no pagination
  for my $id (@blog[0 .. min($#blog, 9)]) {
    $stream->write("<entry>\n");
    $stream->write(encode_utf8 "<title>" . quote_html($id) . "</title>\n");
    my $link = to_url($stream, $host, $space, "page/$id", $scheme);
    $stream->write("<link href=\"$link\"/>\n");
    $stream->write("<id>$link</id>\n");
    $stream->write(encode_utf8 "<content type=\"text\">" . quote_html(text($stream, $host, $space, $id)) . "</content>\n");
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime($changes->{$id}); # 2003-12-13T18:30:02Z
    my $ts = sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
    $stream->write("<updated>$ts</updated>\n");
    $feed_ts = $ts if $ts gt $feed_ts;
    $stream->write("</entry>\n");
  }
  $stream->write("<updated>$feed_ts</updated>\n");
  $stream->write("</feed>\n");
}

sub serve_raw {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  $log->info("Serving raw $id");
  success($stream, 'text/plain; charset=UTF-8');
  $stream->write(encode_utf8 text($stream, $host, $space, $id, $revision));
}

sub serve_diff {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  my $style = shift;
  $log->info("Serving the diff of $id");
  success($stream);
  $stream->write(encode_utf8 "# Differences for $id\n");
  if (not $style) { print_link($stream, $host, $space, "Colour diff", "diff/$id/$revision/colour") }
  else { print_link($stream, $host, $space, "Normal diff", "diff/$id/$revision") }
  $stream->write("Showing the differences between revision $revision and the current revision.\n");
  my $new = text($stream, $host, $space, $id);
  my $old = text($stream, $host, $space, $id, $revision);
  if (not $style) {
    diff($old, $new,
	 sub { $stream->write(encode_utf8 "$_\n") for @_ },
	 sub { $stream->write(encode_utf8 "> $_\n") for map { $_||"⏎" } @_ },
	 sub { $stream->write(encode_utf8 "> $_\n") for map { $_||"⏎" } @_ },
	 sub { "｢$_[0]｣" });
  } else {
    diff($old, $new,
	 sub { $stream->write(encode_utf8 "$_\n") for @_ },
	 sub { $stream->write(encode_utf8 "> \033[31m$_\033[0m\n") for map { $_||"⏎" } @_ },
	 sub { $stream->write(encode_utf8 "> \033[32m$_\033[0m\n") for map { $_||"⏎" } @_ },
	 sub { "\033[1m$_[0]\033[22m" });
  }
}

# old text, new text, code reference to print a paragraph, print deleted text,
# print added text
sub diff {
  my @old = split(/\n/, shift);
  my @new = split(/\n/, shift);
  my $paragraph = shift;
  my $deleted = shift;
  my $added = shift;
  my $highlight = shift;
  $log->debug("Preparing a diff");
  my $diff = Algorithm::Diff->new(\@old, \@new);
  $diff->Base(1); # line numbers, not indices
  while($diff->Next()) {
    next if $diff->Same();
    my $sep = '';
    my ($min1, $max1, $min2, $max2) = $diff->Get(qw(min1 max1 min2 max2));
    if ($diff->Diff == 3) {
      my ($from, $to) = refine([$diff->Items(1)], [$diff->Items(2)], $highlight);
      $paragraph->($min1 == $max1 ? "Changed line $min1 from:" : "Changed lines $min1–$max1 from:");
      $deleted->(@$from);
      $paragraph->($min2 == $max2 ? "to:" : "to lines $min2–$max2:");
      $added->(@$to);
    } elsif ($diff->Diff == 2) {
      $paragraph->($min2 == $max2 ? "Added line $min2:" : "Added lines $min2–$max2:");
      $added->($diff->Items(2));
    } elsif ($diff->Diff == 1) {
      $paragraph->($min1 == $max1 ? "Deleted line $min1:" : "Deleted lines $min1–$max1:");
      $deleted->($diff->Items(1));
    }
  }
}

# $from_lines and $to_lines are references to lists of lines. The lines are
# concatenated and split by words.
sub refine {
  my $from_lines = shift;
  my $to_lines = shift;
  my $highlight = shift;
  my @from_words = split(/\b(?=\w)/, join("\n", @$from_lines));
  my @to_words = split(/\b(?=\w)/, join("\n", @$to_lines));
  my $diff = Algorithm::Diff->new(\@from_words, \@to_words);
  my ($from, $to);
  while($diff->Next()) {
    if (my @list = $diff->Same()) {
      $from .= join('', @list);
      $to .= join('', @list);
    } else {
      # reassemble the chunks, and highlight them per line, don't strip trailing newlines!
      $from .= join("\n", map { $_ ? $highlight->($_) : $_ } (split(/\n/, join('', $diff->Items(1)), -1)));
      $to   .= join("\n", map { $_ ? $highlight->($_) : $_ } (split(/\n/, join('', $diff->Items(2)), -1)));
    }
  }
  # return lines
  return [split(/\n/, $from)], [split(/\n/, $to)];
}

sub serve_html {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  success($stream, 'text/html');
  $log->info("Serving $id as HTML");
  html_page($stream, $host, $space, $id, $revision);
}

sub html_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  $stream->write("<!DOCTYPE html>\n");
  $stream->write("<html>\n");
  $stream->write("<head>\n");
  $stream->write("<meta charset=\"utf-8\">\n");
  $stream->write(encode_utf8 "<title>" . quote_html($id) . "</title>\n");
  $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
  $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
  $stream->write("</head>\n");
  $stream->write("<body>\n");
  $stream->write(encode_utf8 "<h1>" . quote_html($id) . "</h1>\n");
  $stream->write(encode_utf8 to_html(text($stream, $host, $space, $id, $revision)) . "\n");
  $stream->write(encode_utf8 to_html(html_footer($stream, $host, $space, $id, $revision)) . "\n");
  $stream->write("</body>\n");
  $stream->write("</html>\n");
}

# returns lines!
sub to_html {
  my $text = shift;
  my @lines;
  my $list;
  my $code;
  for (split /\n/, quote_html($text)) {
    if (/^```(?:type=([a-z]+))?/) {
      my $type = $1||"default";
      if ($code) {
	push @lines, "</pre>";
	$code = 0;
      } else {
	push @lines, "</ul>" if $list;
	$list = 0;
	push @lines, "<pre class=\"$type\">";
	$code = 1;
      }
    } elsif ($code) {
      push @lines, $_;
    } elsif (/^\* +(.*)/) {
      push @lines, "<ul>" unless $list;
      push @lines, "<li>$1";
      $list = 1;
    } elsif (my ($url, $text) = /^=&gt;\s*(\S+)\s*(.*)/) { # quoted HTML!
      push @lines, "<ul>" unless $list;
      $text ||= $url;
      push @lines, "<li><a href=\"$url\">$text</a>";
      $list = 1;
    } elsif (/^(#{1,6})\s*(.*)/) {
      push @lines, "</ul>" if $list;
      $list = 0;
      my $level = length($1);
      push @lines, "<h$level>$2</h$level>";
    } elsif (/^&gt;\s*(.*)/) { # quoted HTML!
      push @lines, "</ul>" if $list;
      $list = 0;
      push @lines, "<blockquote>$1</blockquote>";
    } else {
      push @lines, "</ul>" if $list;
      $list = 0;
      push @lines, "<p>$_";
    }
  }
  push @lines, "</pre>" if $code;
  push @lines, "</ul>" if $list;
  return join("\n", @lines);
}

sub html_footer {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift||"";
  my @links;
  push(@links, $_->($stream, $host, $space, $id, $revision, "html")) for @footer;
  my $html = join("\n", grep /\S/, @links);
  return "\n\nMore:\n$html" if $html =~ /\S/;
  return "";
}

sub day {
  my $stream = shift;
  my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(shift);
  return sprintf('%4d-%02d-%02d', $year + 1900, $mon + 1, $mday);
}

sub time_of_day {
  my $stream = shift;
  my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(shift);
  return sprintf('%02d:%02d UTC', $hour, $min);
}

sub modified {
  my $ts = (stat(shift))[9];
  return $ts;
}

sub serve_history {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $n = shift;
  my $style = shift;
  success($stream);
  $log->info("Serve history for $id");
  $stream->write(encode_utf8 "# Page history for $id\n");
  if (not $style) { print_link($stream, $host, $space, "Colour history", "history/$id/$n/colour") }
  elsif ($style eq "colour") { print_link($stream, $host, $space, "Fancy history", "history/$id/$n/fancy") }
  elsif ($style eq "fancy") { print_link($stream, $host, $space, "Normal history", "history/$id/$n") }
  my $dir = wiki_dir($host, $space);
  my $log = "$dir/changes.log";
  if (not -e $log) {
    $stream->write("No changes.\n");
    return;
  }
  $stream->write("Showing up to $n changes.\n");
  my $fh = File::ReadBackwards->new($log);
  return unless changes($stream,
    $n,
    sub { $stream->write("## " . shift . "\n") },
    sub { $stream->write(shift . " by " . colourize($stream, shift, $style) . "\n") },
    sub { print_link($stream, @_) },
    sub { $stream->write(join("\n", @_, "")) },
    sub {
    READ:
      return unless $_ = decode_utf8($fh->readline);
      chomp;
      my ($ts, $id_log, $revision, $code) = split(/\x1f/);
      goto READ if $id_log ne $id;
      $ts, $id_log, $revision, $code, $host, $space, 0 },
    undef, #$kept
    undef, #$filter
    $style);
  $stream->write("\n");
  print_link($stream, $host, $space, "More...", "history/" . uri_escape_utf8($id) . "/" . 10 * $n . ($style ? "/$style" : ""));
}

sub footer {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift||"";
  my @links;
  push(@links, gemini_link($stream, $host, $space, "History", "history/$id"));
  push(@links, gemini_link($stream, $host, $space, "Raw text", "raw/$id/$revision"));
  push(@links, gemini_link($stream, $host, $space, "HTML", "html/$id/$revision"));
  push(@links, $_->($stream, $host, $space, $id, $revision, "gemini")) for @footer;
  return join("\n", "\n\nMore:", (grep /\S/, @links), ""); # includes a trailing newline
}

sub serve_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  $log->info("Serve Gemini page $id");
  success($stream);
  $stream->write(encode_utf8 "# $id\n");
  $stream->write(encode_utf8 text($stream, $host, $space, $id, $revision));
  $stream->write(encode_utf8 footer($stream, $host, $space, $id, $revision));
}

sub text {
  my $stream = shift; # used by contributions like oddmuse.pl
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  my $dir = wiki_dir($host, $space);
  return read_text "$dir/keep/$id/$revision.gmi" if $revision and -f "$dir/keep/$id/$revision.gmi";
  return read_text "$dir/page/$id.gmi" if -f "$dir/page/$id.gmi";
  return robots() if $id eq "robots" and not $space;
  return "This this revision is no longer available." if $revision;
  return "This page does not yet exist.";
}

sub robots () {
  my $ban = << 'EOT';
User-agent: *
Disallow: /raw
Disallow: /html
Disallow: /diff
Disallow: /history
Disallow: /do/comment
Disallow: /do/changes
Disallow: /do/all/changes
Disallow: /do/all/latest/changes
Disallow: /do/rss
Disallow: /do/blog/rss
Disallow: /do/atom
Disallow: /do/blog/atom
Disallow: /do/all/atom
Disallow: /do/new
Disallow: /do/more
Disallow: /do/match
Disallow: /do/search
# allowing do/index!
Crawl-delay: 10
EOT
  my @disallows = $ban =~ /Disallow: (.*)/g;
  return $ban
      . join("\n",
	     map {
	       my $space = (split /\//)[-1];
	       join("\n", "# $space", map { "Disallow: /$space$_" } @disallows)
	     } @{$server->{wiki_space}}) . "\n";
}

sub serve_file {
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
    result($stream, "40", "File not found");
    return;
  } elsif (not -f $meta) {
    result($stream, "40", "Metadata not found");
    return;
  }
  my %meta = (map { split(/: /, $_, 2) } split /\n/, read_text $meta);
  if (not $meta{'content-type'}) {
    result($stream, "59", "Metadata corrupt");
    return;
  }
  success($stream, $meta{'content-type'});
  $stream->write(read_binary($file));
}

sub bogus_hash {
  my $str = shift;
  return "0000" unless $str;
  my $num = unpack("L",B::hash($str)); # 32-bit integer
  my $code = sprintf("%o", $num); # octal is 0-7
  return substr($code, 0, 4); # four numbers
}

sub write_file {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $data = shift;
  my $type = shift;
  $log->info("Writing file $id");
  my $dir = wiki_dir($host, $space);
  my $file = "$dir/file/$id";
  my $meta = "$dir/meta/$id";
  if (-e $file) {
    my $old = read_binary($file);
    if ($old eq $data) {
      $log->info("$id is unchanged");
      result($stream, "30", to_url($stream, $host, $space, "page/$id"));
      return;
    }
  }
  my $changes = "$dir/changes.log";
  if (not open(my $fh, ">>:encoding(UTF-8)", $changes)) {
    $log->error("Cannot log $changes: $!");
    result($stream, "59", "Unable to write log");
    return;
  } else {
    my $peerhost = $stream->handle->peerhost;
    say $fh join("\x1f", scalar(time), $id, 0, bogus_hash($peerhost));
    close($fh);
  }
  mkdir "$dir/file" unless -d "$dir/file";
  eval { write_binary($file, $data) };
  if ($@) {
    result($stream, "59", "Unable to save $id");
    return;
  }
  mkdir "$dir/meta" unless -d "$dir/meta";
  eval { write_text($meta, "content-type: $type\n") };
  if ($@) {
    result($stream, "59", "Unable to save metadata for $id");
    return;
  }
  $log->info("Wrote $id");
  result($stream, "30", to_url($stream, $host, $space, "file/$id"));
}

sub delete_file {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  $log->info("Deleting file $id");
  my $dir = wiki_dir($host, $space);
  unlink("$dir/file/$id", "$dir/meta/$id");
  my $changes = "$dir/changes.log";
  if (not open(my $fh, ">>:encoding(UTF-8)", $changes)) {
    $log->error("Cannot write log $changes: $!");
    result($stream, "59", "Unable to write log");
    return;
  } else {
    my $peerhost = $stream->handle->peerhost;
    say $fh join("\x1f", scalar(time), $id, "🖻", bogus_hash($peerhost));
    close($fh);
  }
  success($stream);
  $stream->write("# $id\n");
  $stream->write("The file was deleted.\n");
}

sub allow_deny_hook {
  my $stream = shift;
  my $client = shift;
  # consider adding rate limiting?
  return 1;
}

sub wiki_dir {
  my $host = shift;
  my $space = shift;
  my $dir = $server->{wiki_dir};
  if (keys %{$server->{host}} > 1) {
    $dir .= "/$host";
    mkdir($dir) unless -d $dir;
  }
  $dir .= "/$space" if $space;
  mkdir($dir) unless -d $dir;
  return $dir;
}

# If we are serving multiple hostnames, we need to check whether the space
# supplied in the URL matches a known hostname/space combo.
sub space {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $space = decode_utf8(uri_unescape($space)) if $space;
  if (keys %{$server->{host}} > 1) {
    return undef unless $space;
    return $space if grep { $_ eq "$host/$space" } @{$server->{wiki_space}};
    # else it's an error and we jump out to the eval {} in handle_url
    result($stream, "40", "$host doesn't know about $space");
    die "unknown space: $host/$space\n"; # is caught in the eval
  }
  # Without wildcards, just return the space. We already know that the space
  # matched the regular expression of spaces.
  return $space;
}

sub space_dirs {
  my @spaces;
  if (keys %{$server->{host}} > 1) {
    push @spaces, keys %{$server->{host}};
  } else {
    push @spaces, undef;
  }
  push @spaces, @{$server->{wiki_space}};
  return @spaces;
}

# A list of links to all the spaces we have. The tricky part here is that we
# want to create appropriate links if we're virtual hosting. Keys are URLs,
# values are names.
sub space_links {
  my $stream = shift;
  my $scheme = shift;
  my $host = shift;
  my $port = shift;
  my %spaces;
  if (keys %{$server->{host}} > 1) {
    for (keys %{$server->{host}}) {
      $spaces{"$scheme://$_:$port/"} = $_;
    }
    for my $space (@{$server->{wiki_space}}) {
      my ($ahost, $aspace) = split(/\//m, $space, 2);
      $spaces{"$scheme://$ahost:$port/$aspace/"} = $space;
    }
  } elsif (@{$server->{wiki_space}}) {
    $spaces{"$scheme://$host:$port/"} = "Main space";
    for (sort @{$server->{wiki_space}}) {
      $spaces{"$scheme://$host:$port/$_/"} = $_;
    }
  }
  return \%spaces;
}

sub is_upload {
  my $stream = shift;
  my $request = shift;
  $log->info("Looking at $request");
  my $hosts = host_regex();
  my $spaces_regex = space_regex();
  my $port = port($stream);
  if ($request =~ m!^titan://($hosts)(?::$port)?!) {
    my $host = $1;
    my($scheme, $authority, $path, $query, $fragment) =
	$request =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;
    if ($path =~ m!^(?:/($spaces_regex))?(?:/raw|/page)?/([^/;=&]+(?:;\w+=[^;=&]+)+)!) {
      my $space = $1;
      my ($id, @params) = split(/[;=&]/, $2);
      my $params = { map {decode_utf8(uri_unescape($_))} @params };
      if (valid_params($stream, $host, $space, $id, $params)) {
	return {
	  host => $host,
	  space => space($stream, $host, $space),
	  id => decode_utf8(uri_unescape($id)),
	  params => $params,
	}
      }
    } else {
      $log->debug("The path $path is malformed");
      result($stream, "59", "The path $path is malformed");
      $stream->close_gracefully();
    }
  }
  return 0;
}

sub valid_params {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $params = shift;
  return unless valid_id($stream, $host, $space, $id, $params);
  return unless valid_token($stream, $host, $space, $id, $params);
  return unless valid_mime_type($stream, $host, $space, $id, $params);
  return unless valid_size($stream, $host, $space, $id, $params);
  return 1;
}

sub valid_id {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  if (not $id) {
    $log->debug("The URL lacks a page name");
    result($stream, "59", "The URL lacks a page name");
    $stream->close_gracefully();
    return;
  } elsif ($id =~ /[[:cntrl:]]/) {
    $log->debug("Page names must not contain any control characters");
    result($stream, "59", "Page names must not contain any control characters");
    $stream->close_gracefully();
    return;
  }
  return 1;
}

sub valid_token {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $params = shift;
  my $token = quotemeta($params->{token}||"");
  my @tokens = @{$server->{wiki_token}};
  push(@tokens, @{$server->{wiki_space_token}->{$space}})
      if $space and $server->{wiki_space_token}->{$space};
  $log->debug("Valid tokens: @tokens");
  $log->debug("Spaces: " . join(", ", keys %{$server->{wiki_space_token}}));
  if (not $token and @tokens) {
    $log->debug("Uploads require a token");
    result($stream, "59", "Uploads require a token");
    $stream->close_gracefully();
    return;
  } elsif (not grep(/^$token$/, @tokens)) {
    $log->debug("Your token is the wrong token");
    result($stream, "59", "Your token is the wrong token");
    $stream->close_gracefully();
    return;
  }
  return 1;
}

sub valid_mime_type {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $params = shift;
  my $type = $params->{mime};
  my ($main_type) = split(/\//, $type, 1);
  my @types = @{$server->{wiki_mime_type}};
  @types = ("text/plain") unless @types;
  if ($type ne "text/plain" and not grep(/^$type$/, @types) and not grep(/^$main_type$/, @types)) {
    $log->debug("This wiki does not allow $type (@types)");
    result($stream, "59", "This wiki does not allow $type");
    $stream->close_gracefully();
    return;
  }
  return 1;
}

sub valid_size {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $params = shift;
  my $size = $params->{size};
  if ($size !~ /^\d+$/) {
    $log->debug("You need to send along the number of bytes, not '$size'");
    result($stream, "59", "You need to send along the number of bytes, not '$size'");
    $stream->close_gracefully();
    return;
  } elsif ($size > $server->{wiki_page_size_limit}) {
    $log->debug("This wiki does not allow more than $server->{wiki_page_size_limit} bytes per page");
    result($stream, "59", "This wiki does not allow more than $server->{wiki_page_size_limit} bytes per page");
    $stream->close_gracefully();
    return;
  }
  return 1;
}

1;

__DATA__
