# -*- mode: perl -*-
# Copyright (C) 2005–2021  Alex Schroeder <alex@gnu.org>

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

App::Phoebe::WebDAV - add WebDAV to Phoebe wiki

=head1 DESCRIPTION

This allows users to mount the wiki as a remote server using WebDAV. If you
start it locally, for example, you should be able to mount
L<davs://localhost:1965/> as a remote server using your file manager (i.e.
Files, Finder, Windows Explorer, whatever it is called). Alternatively, you can
use a dedicated WebDAV client such as C<cadaver>.

If you want to have write access, you need to provide a username and password if
Phoebe requires a token. By default, the token required by Phoebe is "hello".
The username you provide is ignored. The password must match one of the tokens.

If you use a client such as C<cadaver>, it'll ask you for a username and
password when you use the "put" command for the first time. If you use the Gnome
Text Editor to edit the file, this fails. The fix is to mount
L<davs://localhost:1965/> instead. This forces Gnome Files to ask you for a
username and password, and once you provide it, Gnome Text Editor can save
files.

=head1 SEE ALSO

L<RFC 4918|https://datatracker.ietf.org/doc/html/rfc4918> defines WebDAV
including the PROPFIND method.

L<RFC 2616|https://datatracker.ietf.org/doc/html/rfc2616> defines HTTP/1.1
including the OPTION and PUT methods.

L<RFC 2617|https://datatracker.ietf.org/doc/html/rfc2617> defines Basic
Authentication.

=cut

package App::Phoebe::WebDAV;
use App::Phoebe::Web qw(handle_http_header);
use App::Phoebe qw(@request_handlers @extensions run_extensions $server
		   $log host_regex space_regex space port wiki_dir pages files
		   with_lock bogus_hash);
use File::Slurper qw(read_text write_text read_binary write_binary read_dir read_lines);
use HTTP::Date qw(time2str time2isoz);
use Digest::MD5 qw(md5_base64);
use Encode qw(encode_utf8 decode_utf8);
use Mojo::Util qw(b64_decode);
use File::stat;
use Modern::Perl;
use File::MimeInfo::Magic;
use URI::Escape;
use XML::LibXML;
use IO::Scalar;
use utf8;

unshift(@request_handlers, '^(OPTIONS|PROPFIND|PUT|DELETE|COPY|MOVE) .* HTTP/1\.1$' => \&handle_http_header);

# note that the requests handled here must be protected in
# App::Phoebe::RegisteredEditorsOnly!
push(@extensions, \&process_webdav);

sub process_webdav {
  my ($stream, $request, $headers, $buffer) = @_;
  my $hosts = host_regex();
  my $port = port($stream);
  my $spaces = space_regex();
  my ($method, $host, $space, $path, $id);
  if (($space, $path, $id)
      = $request =~ m!^OPTIONS (?:/($spaces))?(/(?:login|(?:file|page|raw)(?:/([^/]*))?)?)? HTTP/1\.1$!
      and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
    return if $path eq "/login" and not authorize($stream, $host, space($stream, $host, $space), $headers);
    options($stream, map { decode_utf8(uri_unescape($_)) } $path, $id);
  } elsif (($space, $path, $id)
	   = $request =~ m!^PROPFIND (?:/($spaces))?(/(?:login/?|(?:file|page|raw)(?:/([^/]*))?)?)? HTTP/1\.1$!
	   and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
    propfind($stream, $host, space($stream, $host, $space), (map { decode_utf8(uri_unescape($_)) } $path, $id), $headers, $buffer);
  } elsif (($space, $path, $id)
	   = $request =~ m!^PUT (?:/($spaces))?(/(?:file|raw)/([^/]*)) HTTP/1\.1$!
	   and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
    put($stream, $host, space($stream, $host, $space), (map { decode_utf8(uri_unescape($_)) } $path, $id), $headers, $buffer);
  } elsif (($space, $path, $id)
	   = $request =~ m!^DELETE (?:/($spaces))?(/(?:file|raw)/([^/]*)) HTTP/1\.1$!
	   and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
    remove($stream, $host, space($stream, $host, $space), (map { decode_utf8(uri_unescape($_)) } $path, $id), $headers);
  } elsif (($space, $path, $id)
	   = $request =~ m!^COPY (?:/($spaces))?(/(?:file|raw)/([^/]*)) HTTP/1\.1$!
	   and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
    copy($stream, $host, space($stream, $host, $space), (map { decode_utf8(uri_unescape($_)) } $path, $id), $headers);
  } elsif (($space, $path, $id)
	   = $request =~ m!^MOVE (?:/($spaces))?(/(?:file|raw)/([^/]*)) HTTP/1\.1$!
	   and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
    move($stream, $host, space($stream, $host, $space), (map { decode_utf8(uri_unescape($_)) } $path, $id), $headers);
  } else {
    return 0;
  }
  return 1;
}

my %implemented = (
  options  => '*',
  propfind => '*',
  get      => 'r', # handled by App::Phoebe::Web
  put      => 'w',
  delete   => 'w',
  copy     => 'w',
  move     => 'w',
);

sub options {
  my ($stream, $path, $id) = @_;
  my $allow = join(',', map { uc }
		   grep { $implemented{$_} eq '*'
		       or $implemented{$_} eq 'r' and $id
		       or $implemented{$_} eq 'w' and $id and $path =~ m!^/(raw|file)/.! }
		   keys %implemented);
  $log->debug("OPTIONS: $allow");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("DAV: 1\r\n");
  $stream->write("Allow: $allow\r\n");
  $stream->write("\r\n");
}

sub propfind {
  my ($stream, $host, $space, $path, $id, $headers, $buffer) = @_;
  $path //= "/";
  my $depth = $headers->{depth} // "infinity";
  $log->debug("PROPFIND depth: $depth");
  $log->debug("PROPFIND content: $buffer");

  my $parser = XML::LibXML->new;
  my $req;
  eval { $req = $parser->parse_string($buffer); };
  if ($@) {
    webdav_error($stream, "Cannot parse the PROPFIND body");
    $log->warn("PROPFIND parse: $@");
    return;
  }

  # what properties do we need?
  my $reqinfo;
  my @reqprops;
  $reqinfo = $req->find('/*/*')->shift->localname;
  if ($reqinfo eq 'prop') {
    for my $node ($req->find('/*/*/*')->get_nodelist) {
      push @reqprops, [ $node->namespaceURI, $node->localname ];
    }
  }
  $log->debug("PROPFIND requested properties: " . join(", ", map {join "", @$_} @reqprops));

  my @resources;
  my $re = '^' . quotemeta($id) . '$' if $id;
  push(@resources, "/")
      if $path eq "/";
  push(@resources, map { "/$_/" } @{$server->{wiki_space}}) # all of them, but only at the top level
      if not $space and $path eq "/" and $depth ne "0";
  push(@resources, "/login/")
      if $path eq "/" and $depth ne "0"
      or $path =~ m!^/login/?$!;
  push(@resources, "/page/")
      if $path eq "/" and $depth ne "0"
      or $path =~ m!^/page/?$!;
  push(@resources, "/raw/")
      if $path eq "/" and $depth ne "0"
      or $path =~ m!^/raw/?$!;
  push(@resources, map { "/page/$_" } pages($stream, $host, $space))
      if $path eq "/" and $depth eq "infinity"
      or $path =~ m!^/page/?$! and $depth ne "0";
  push(@resources, map { "/raw/$_" } pages($stream, $host, $space))
      if $path eq "/" and $depth eq "infinity"
      or $path =~ m!^/raw/?$!;
  push(@resources, map { "/page/$_" } pages($stream, $host, $space, $re)) # only if it exists!
      if $id and $path eq "/page/$id";
  push(@resources, map { "/raw/$_" } pages($stream, $host, $space, $re)) # only if it exists!
      if $id and $path eq "/raw/$id";
  push(@resources, "/file/")
      if $path eq "/" and $depth ne "0"
      or $path =~ m!^/file/?$!;
  push(@resources, map { "/file/$_" } files($stream, $host, $space))
      if $path eq "/" and $depth eq "infinity"
      or $path =~ m!^/file/?$! and $depth ne "0";
  push(@resources, map { "/file/$_" } files($stream, $host, $space, $re))
      if $id and $path eq "/file/$id";

  my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
  my $multistat = $doc->createElement('D:multistatus');
  $multistat->setAttribute('xmlns:D', 'DAV:');
  $doc->setDocumentElement($multistat);

  my $dir = wiki_dir($host, $space);

  for my $resource (@resources) {
    # skip "hidden" files in the Unix world
    # and prevent path traversal using ..
    next if $resource =~ m!/\.!;
    # Names
    my $mime;
    my $is_dir;
    my $filename;
    if ($resource eq "/") {
      $filename = $dir;
      $is_dir = 1;
      $mime = "inode/directory";
    } elsif ($resource =~ m!/([^/]+)/$!) {
      # the raw directory is a "fake" and is actually the page directory
      $filename = $dir . ($1 eq "raw" ? "/page" : $resource);
      $is_dir = 1;
      $mime = "inode/directory";
    } elsif ($resource =~ m!/page/([^/]+)$!) {
      $filename = $dir . "/page/$1.gmi";
      $is_dir = 0;
      $mime = "text/html";
    } elsif ($resource =~ m!/raw/([^/]+)$!) {
      # the raw directory is a "fake" and is actually the page directory
      $filename = $dir . "/page/$1.gmi";
      $is_dir = 0;
      $mime = "text/plain";
    } elsif ($resource =~ m!/file/([^/]+)$!) {
      $filename = $dir . $resource;
      $is_dir = 0;
      if (-f "$dir/meta/$1") {
	# MIME-type for files requires opening the meta files! 😭
	my %meta = (map { split(/: /, $_, 2) } read_lines("$dir/meta/$1"));
	if ($meta{'content-type'}) {
	  $mime = $meta{'content-type'};
	}
      }
      $mime //= "application/octet-stream"; # fallback for binary files
    } else {
      $log->error("Requested $resource");
      next;
    }

    $log->debug("Processing $dir$resource");

    # A stat call for every file and every page! 😭
    my ($size, $mtime, $ctime, $sb) = (0, 0, 0);
    if ($resource eq "/login/") {
      $size = "";
      $mtime = $ctime = time;
    } elsif ($sb = stat($filename)) {
      $size = $sb->size;
      $mtime = $sb->mtime;
      $ctime = $sb->ctime;
    }

    # Modified time is stringified human readable HTTP::Date style
    $mtime = time2str($mtime);

    # Created time is ISO format: We need to tidy up the date format - isoz
    # isn't exactly what we want
    $ctime = time2isoz($ctime);
    $ctime =~ s/ /T/;
    $ctime =~ s/Z//;

    my $resp = $doc->createElement('D:response');
    $multistat->addChild($resp);
    my $href = $doc->createElement('D:href');
    $href->appendText(to_url($space, $resource));
    $resp->addChild($href);
    my $okprops = $doc->createElement('D:prop');
    my $nfprops = $doc->createElement('D:prop');
    my $prop;
    if ($reqinfo eq 'prop') {
      my %prefixes = ('DAV:' => 'D');
      my $i        = 0;
      for my $reqprop (@reqprops) {
        my ($ns, $name) = @$reqprop;
        if ($ns eq 'DAV:' && $name eq 'creationdate') {
          $prop = $doc->createElement('D:creationdate');
          $prop->appendText($ctime);
          $okprops->addChild($prop);
        } elsif ($ns eq 'DAV:' && $name eq 'getcontentlength') {
          $prop = $doc->createElement('D:getcontentlength');
          $prop->appendText($size);
          $okprops->addChild($prop);
        } elsif ($ns eq 'DAV:' && $name eq 'getcontenttype') {
          $prop = $doc->createElement('D:getcontenttype');
	  $prop->appendText($mime);
          $okprops->addChild($prop);
        } elsif ($ns eq 'DAV:' && $name eq 'getlastmodified') {
          $prop = $doc->createElement('D:getlastmodified');
          $prop->appendText($mtime);
          $okprops->addChild($prop);
        } elsif ($ns eq 'DAV:' && $name eq 'resourcetype') {
          $prop = $doc->createElement('D:resourcetype');
          if ($is_dir) {
            my $col = $doc->createElement('D:collection');
            $prop->addChild($col);
          }
          $okprops->addChild($prop);
        } else {
          my $prefix = $prefixes{$ns};
          if (!defined $prefix) {
            $prefix = 'i' . $i++;
	    # mod_dav sets <response> 'xmlns' attribute - whatever
            #$nfprops->setAttribute("xmlns:$prefix", $ns);
            $resp->setAttribute("xmlns:$prefix", $ns);
            $prefixes{$ns} = $prefix;
          }
          $prop = $doc->createElement("$prefix:$name");
          $nfprops->addChild($prop);
        }
      }
    } elsif ($reqinfo eq 'propname') {
      $prop = $doc->createElement('D:creationdate');
      $okprops->addChild($prop);
      $prop = $doc->createElement('D:getcontentlength');
      $okprops->addChild($prop);
      $prop = $doc->createElement('D:getcontenttype');
      $okprops->addChild($prop);
      $prop = $doc->createElement('D:getlastmodified');
      $okprops->addChild($prop);
      $prop = $doc->createElement('D:resourcetype');
      $okprops->addChild($prop);
    } else {
      $prop = $doc->createElement('D:creationdate');
      $prop->appendText($ctime);
      $okprops->addChild($prop);
      $prop = $doc->createElement('D:getcontentlength');
      $prop->appendText($size);
      $okprops->addChild($prop);
      $prop = $doc->createElement('D:getcontenttype');
      $prop->appendText($mime);
      $okprops->addChild($prop);
      $prop = $doc->createElement('D:getlastmodified');
      $prop->appendText($mtime);
      $okprops->addChild($prop);
      $prop = $doc->createElement('D:resourcetype');
      if ($is_dir) {
	my $col = $doc->createElement('D:collection');
	$prop->addChild($col);
      }
      $okprops->addChild($prop);
    }
    if ($okprops->hasChildNodes) {
      my $propstat = $doc->createElement('D:propstat');
      $propstat->addChild($okprops);
      my $stat = $doc->createElement('D:status');
      $stat->appendText('HTTP/1.1 200 OK');
      $propstat->addChild($stat);
      $resp->addChild($propstat);
    }
    if ($nfprops->hasChildNodes) {
      my $propstat = $doc->createElement('D:propstat');
      $propstat->addChild($nfprops);
      my $stat = $doc->createElement('D:status');
      $stat->appendText('HTTP/1.1 404 Not Found');
      $propstat->addChild($stat);
      $resp->addChild($propstat);
    }
  }
  my $str = $doc->toString(1);
  my $len = length($str);
  $log->debug("RESPONSE: 207\n" . $doc->toString(1));
  $stream->write("HTTP/1.1 207 Multi-Status\r\n");
  $stream->write("Content-Type: application/xml; charset=\"utf-8\"\r\n");
  $stream->write("Content-Length: $len\r\n");
  if ($path =~ m!/(page|raw|file|login)$!) {
    $stream->write("Content-Location: $path/\r\n");
  }
  $stream->write("\r\n");
  $stream->write($str);
}

sub to_url {
  my $space = shift;
  my $resource = shift;
  my $href;
  $href .= "/" . uri_escape_utf8($space) if $space;
  # split doesn't produce empty fields at the end
  my $d = substr($resource, -1) eq "/";
  $href .= join("/", map { uri_escape_utf8($_) } split (/\//, $resource));
  $href .= "/" if $d;
  return $href;
}

sub put {
  my ($stream, $host, $space, $path, $id, $headers, $buffer) = @_;
  return unless authorize($stream, $host, $space, $headers);
  return remove($stream, $host, $space, $path, $id, $headers) if length($buffer) == 0;
  my $mime = $headers->{"content-type"} // guess_mime_type(\$buffer);
  return webdav_error($stream, "Content type not known") unless $mime;
  return webdav_error($stream, "Page name is missing") unless $id;
  return webdav_error($stream, "Page names must not control characters") if $id =~ /[[:cntrl:]]/;
  if ($path eq "/file/$id") {
    with_lock($stream, $host, $space, sub { write_file($stream, $host, $space, $id, $buffer, $mime) } );
  } else {
    my $text = decode_utf8 $buffer // "";
    $text =~ s/\r\n/\n/g; # fix DOS EOL convention
    with_lock($stream, $host, $space, sub { write_page($stream, $host, $space, $id, $text) } );
  }
  return 1;
}

sub write_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $text = shift;
  my $dir = wiki_dir($host, $space);
  my $file = "$dir/page/$id.gmi";
  my $revision = 0;
  my $new = 0;
  if (-e $file) {
    my $old = read_text($file);
    if ($old eq $text) {
      $log->info("$id is unchanged");
      $stream->write("HTTP/1.1 200 OK\r\n");
      $stream->write("\r\n");
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
      return webdav_error($stream, "Unable to write index");
    } else {
      say $fh $id;
      close($fh);
    }
    $new = 1;
  }
  my $changes = "$dir/changes.log";
  if (not open(my $fh, ">>:encoding(UTF-8)", $changes)) {
    $log->error("Cannot write log $changes: $!");
    return webdav_error($stream, "Unable to write log");
  } else {
    my $peerhost = $stream->handle->peerhost;
    say $fh join("\x1f", scalar(time), $id, $revision + 1, bogus_hash($peerhost));
    close($fh);
  }
  mkdir "$dir/page" unless -d "$dir/page";
  eval { write_text($file, $text) };
  if ($@) {
    $log->error("Unable to save $id: $@");
    return webdav_error($stream, "Unable to save $id");
  } else {
    $log->info("Wrote $id");
    if ($new) {
      $stream->write("HTTP/1.1 201 Created\r\n");
    } else {
      $stream->write("HTTP/1.1 200 OK\r\n");
    }
    $stream->write("\r\n");
  }
}

sub write_file {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $data = shift;
  my $type = shift;
  my $dir = wiki_dir($host, $space);
  my $file = "$dir/file/$id";
  my $meta = "$dir/meta/$id";
  my $new = 0;
  if (-e $file) {
    my $old = read_binary($file);
    if ($old eq $data) {
      $log->info("$id is unchanged");
      $stream->write("HTTP/1.1 200 OK\r\n");
      $stream->write("\r\n");
      return;
    }
    $new = 1;
  }
  my $changes = "$dir/changes.log";
  if (not open(my $fh, ">>:encoding(UTF-8)", $changes)) {
    $log->error("Cannot write log $changes: $!");
    return webdav_error($stream, "Unable to write log");
  } else {
    my $peerhost = $stream->handle->peerhost;
    say $fh join("\x1f", scalar(time), $id, 0, bogus_hash($peerhost));
    close($fh);
  }
  mkdir "$dir/file" unless -d "$dir/file";
  eval { write_binary($file, $data) };
  if ($@) {
    $log->error("Unable to save $id: $@");
    return webdav_error($stream, "Unable to save $id");
  }
  mkdir "$dir/meta" unless -d "$dir/meta";
  eval { write_text($meta, "content-type: $type\n") };
  if ($@) {
    $log->error("Unable to save metadata for $id: $@");
    return webdav_error($stream, "Unable to save metadata for $id");
  }
  $log->info("Wrote $id");
  if ($new) {
    $stream->write("HTTP/1.1 201 Created\r\n");
  } else {
    $stream->write("HTTP/1.1 200 OK\r\n");
  }
  $stream->write("\r\n");
}

# Can't use "delete" as a name because that's a keyword...
sub remove {
  my ($stream, $host, $space, $path, $id, $headers) = @_;
  return unless authorize($stream, $host, $space, $headers);
  return webdav_error($stream, "Page name is missing") unless $id;
  return webdav_error($stream, "Page names must not control characters") if $id =~ /[[:cntrl:]]/;
  if ($path eq "/file/$id") {
    with_lock($stream, $host, $space, sub { delete_file($stream, $host, $space, $id) } );
  } else {
    with_lock($stream, $host, $space, sub { delete_page($stream, $host, $space, $id) } );
  }
}

sub delete_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
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
    my @pages = grep { $_ ne $id } read_lines $index;
    write_text($index, join("\n", @pages, ""));
  }
  my $changes = "$dir/changes.log";
  if (not open(my $fh, ">>:encoding(UTF-8)", $changes)) {
    $log->error("Cannot write log $changes: $!");
    return webdav_error($stream, "Unable to write log");
  } else {
    my $peerhost = $stream->handle->peerhost;
    say $fh join("\x1f", scalar(time), $id, "🖹", bogus_hash($peerhost));
    close($fh);
  }
  $log->info("Deleted page $id");
  $stream->write("HTTP/1.1 204 No Content\r\n");
  $stream->write("\r\n");
}

sub delete_file {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $dir = wiki_dir($host, $space);
  unlink("$dir/file/$id", "$dir/meta/$id");
  my $changes = "$dir/changes.log";
  if (not open(my $fh, ">>:encoding(UTF-8)", $changes)) {
    $log->error("Cannot write log $changes: $!");
    return webdav_error($stream, "Unable to write log");
  } else {
    my $peerhost = $stream->handle->peerhost;
    say $fh join("\x1f", scalar(time), $id, "🖻", bogus_hash($peerhost));
    close($fh);
  }
  $log->info("Deleted file $id");
  $stream->write("HTTP/1.1 204 No Content\r\n");
  $stream->write("\r\n");
}

sub copy {
  my ($stream, $host, $space, $path, $id, $headers) = @_;
  return unless authorize($stream, $host, $space, $headers);
  return webdav_error($stream, "Page name is missing") unless $id;
  return webdav_error($stream, "Page names must not control characters") if $id =~ /[[:cntrl:]]/;
  my $destination = $headers->{destination};
  return webdav_error($stream, "Destination is missing") unless $destination;
  my $dir = wiki_dir($host, $space);
  my $source;
  if ($path =~ m!^/raw/!) {
    $source = "$dir/page/$id.gmi";
  } else {
    $source = "$dir/file/$id";
  }
  $log->debug("Copying $source");
  return webdav_error($stream, "Resource is missing") unless -e $source;
  my $data = read_binary($source);
  # figure out the destination
  my $hosts = host_regex();
  my $port = port($stream);
  my $spaces = space_regex();
  my ($dest_host, $dest_space, $dest_path, $dest_id) =
      $destination =~ m!^https://($hosts)(?::$port)(?:/($spaces))?(/(?:file|raw)/([^/]*))!;
  if ($dest_id) {
    put($stream, $host, space($stream, $host, $dest_space), $dest_path, decode_utf8(uri_unescape($dest_id)), $headers, $data);
  } else {
    return webdav_error($stream, "Copying to remote servers not supported");
  }
}

sub move {
  remove(@_) if copy(@_);
}

sub webdav_error {
  my $stream = shift;
  my $message = shift || "Bad Request";
  $log->error($message);
  $stream->write("HTTP/1.1 400 $message\r\n");
  $stream->write("Content-Type: text/plain\r\n");
  $stream->write("\r\n");
  $stream->close_gracefully();
  return 0;
}

sub authorize {
  my ($stream, $host, $space, $headers) = @_;
  my @tokens = @{$server->{wiki_token}};
  push(@tokens, @{$server->{wiki_space_token}->{$space}})
      if $space and $server->{wiki_space_token}->{$space};
  return 1 unless  @tokens;
  my $auth = $headers->{"authorization"};
  if (not $auth or $auth !~ /^Basic (\S+)/) {
    $log->info("Missing authorization header");
    $stream->write("HTTP/1.1 401 Unauthorized\r\n");
    $stream->write("WWW-Authenticate: Basic realm=\"Phoebe\"\r\n");
    $stream->write("\r\n");
    return;
  }
  my $bytes = b64_decode $1;
  my ($userid, $token) = split(/:/, $bytes, 2);
  if (not $token) {
    $log->info("Token required (one of @tokens)");
    $stream->write("HTTP/1.1 401 Unauthorized\r\n");
    $stream->write("WWW-Authenticate: Basic realm=\"Phoebe\"\r\n");
    $stream->write("\r\n");
    return;
  }
  if (not grep(/^$token$/, @tokens)) {
    $log->info("Wrong token ($token)");
    $stream->write("HTTP/1.1 401 Unauthorized\r\n");
    $stream->write("WWW-Authenticate: Basic realm=\"Phoebe\"\r\n");
    $stream->write("\r\n");
    return;
  }
  return 1;
}

sub guess_mime_type {
  my $SH = new IO::Scalar shift;
  return mimetype($SH);
}

1;
