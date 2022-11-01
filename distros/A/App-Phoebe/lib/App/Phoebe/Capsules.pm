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

App::Phoebe::Capsules - provide every visitor with a writeable capsule

=head1 DESCRIPTION

By default, Phoebe creates a wiki editable by all. With this extension, the
C</capsule> space turns into a special site: if you have a client certificate,
you automatically get an editable capsule with an assigned fantasy name.

Simply add it to your F<config> file. If you are virtual hosting, name the host
or hosts for your capsules.

    package App::Phoebe::Capsules;
    use Modern::Perl;
    our @capsule_hosts = qw(transjovian.org);
    use App::Phoebe::Capsules;

Every client certificate gets assigned a capsule name.

You can provide a link with some documentation, if you want:

    our $capsule_help = '//transjovian.org/phoebe/page/Capsules';

=head1 NO MIME TYPES

When uploading to a capsule, the MIME type is ignored. Instead, it is determined
from the filename extension.

=head1 TROUBLESHOOTING

🔥 In the wiki directory, you can have a file called F<fingerprint_equivalents>.
Its main use is to allow people to add more fingerprints for their site, such as
from other devices or friends. The file format is line oriented, each line
containing two fingerprints, C<FROM> and C<TO>.

🔥 The capsule name I<login> is reserved.

🔥 The file names I<archive>, I<backup>, and I<upload> are reserved.

=head1 NO WIKI, ONLY CAPSULES

Here's how to disable all wiki functions of Phoebe and just use capsules. The
C<nothing_else> function comes right after C<capsules> as an extension and
always returns 1, so Phoebe considers this request handled. Therefore, the
regular request handlers won't get used. Make sure that any extensions you do
want to have are prepended to C<@extensions> after setting it (using
C<unshift>).

    # tested by t/example-capsules-only.t
    package App::Phoebe::Capsules;
    use Modern::Perl;
    use App::Phoebe qw($log @request_handlers @extensions);
    use App::Phoebe::Capsules;
    our $capsule_help = '//transjovian.org/phoebe/page/Capsules';
    our $capsule_space;
    @extensions = (\&capsules, \&nothing_else);
    sub nothing_else {
      my ($stream, $url) = @_;
      $log->info("No handler for $url: only capsules!");
      result($stream, "30", "/$capsule_space");
      1;
    }
    $log->info('Only capsules!');
    1;

=cut

package App::Phoebe::Capsules;
use App::Phoebe qw($server $log @extensions @request_handlers host_regex port success result print_link wiki_dir
		   valid_id valid_mime_type valid_size to_url);
use File::Slurper qw(read_dir read_binary write_binary);
use Net::IDN::Encode qw(domain_to_ascii);
use Encode qw(encode_utf8 decode_utf8);
use File::MimeInfo qw(globs);
use List::Util qw(sum first);
use Modern::Perl;
use URI::Escape;

push(@extensions, \&capsules);

our $capsule_space = "capsule";
our @capsule_hosts;
our $capsule_help;
our @capsule_tokens;
our %capsule_equivalent;

# load fingerprint equivalents on the next tick
Mojo::IOLoop->next_tick(sub {
  my $dir = $server->{wiki_dir};
  if (-f "$dir/fingerprint_equivalents") {
    my $bytes = read_binary("$dir/fingerprint_equivalents");
    %capsule_equivalent = split(' ', $bytes);
  } } );

sub capsules {
  my $stream = shift;
  my $url = shift;
  my $hosts = capsule_regex();
  my $port = port($stream);
  my ($host, $capsule, $id, $token);
  if ($url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/([^/]+)/upload$!) {
    return result($stream, "10", "Filename");
  } elsif (($host, $capsule, $id) = $url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/([^/]+)/upload\?([^/]+)$!) {
    $capsule = decode_utf8(uri_unescape($capsule));
    return result($stream, "30", "gemini://$host:$port/$capsule_space/$capsule/$id");
  } elsif (($host) = $url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/login$!) {
    return serve_capsule_login($stream, $host);
  } elsif (($host, $capsule) = $url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/([^/]+)/archive$!) {
    return serve_capsule_archive($stream, $host, decode_utf8(uri_unescape($capsule)));
  } elsif (($host, $capsule, $id) = $url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/([^/]+)/backup(?:/([^/]+))?$!) {
    return serve_capsule_backup($stream, $host, map { decode_utf8(uri_unescape($_)) } $capsule, $id||"");
  } elsif (($host, $capsule, $id) = $url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/([^/]+)/delete(?:/([^/]+))?$!) {
    return serve_capsule_delete($stream, $host, map { decode_utf8(uri_unescape($_)) } $capsule, $id||"");
  } elsif ($url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/([^/]+)/access$!) {
    return result($stream, "10", "Password");
  } elsif (($host, $capsule, $token) = $url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/([^/]+)/access\?(.+)$!) {
    return serve_capsule_access($stream, $host, decode_utf8(uri_unescape($capsule)), decode_utf8(uri_unescape($token)));
  } elsif (($host, $capsule) = $url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/([^/]+)/share$!) {
    return serve_capsule_sharing($stream, $host, decode_utf8(uri_unescape($capsule)));
  } elsif (($host, $capsule, $id) = $url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/([^/]+)/([^/]+)$!) {
    return serve_capsule_page($stream, $host, map { decode_utf8(uri_unescape($_)) } $capsule, $id);
  } elsif (($host, $capsule) = $url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/([^/]+)/?$!) {
    return serve_capsule_menu($stream, $host, decode_utf8(uri_unescape($capsule)));
  } elsif (($host) = $url =~ m!^gemini://($hosts)(?::$port)?/$capsule_space/?$!) {
    return serve_main_menu($stream, $host);
  }
  return;
}

sub serve_capsule_login {
  my ($stream, $host) = @_;
  my $name = capsule_name($stream);
  if ($name) {
    $log->info("Redirect to capsule");
    result($stream, "30", to_url($stream, $host, $capsule_space, ""));
  } else {
    $log->info("Requested client certificate for capsule");
    result($stream, "60", "You need a client certificate to access your capsule");
  }
  return 1;
}

sub serve_capsule_archive {
  my ($stream, $host, $capsule) = @_;
  my $name = capsule_name($stream);
  return 1 unless is_my_capsule($stream, $name, $capsule, 'archive');
  # use /bin/tar instead of Archive::Tar to save memory
  my $dir = wiki_dir($host, $capsule_space) . "/" . encode_utf8($capsule);
  my $file = "$dir/backup/data.tar.gz";
  if (-e $file and time() - modified($file) <= 300) { # data is valid for 5 minutes
    $log->info("Serving cached data archive for $capsule");
    success($stream, "application/tar");
    $stream->write(read_binary($file));
  } else {
    write_binary($file, ""); # truncate in order to avoid "file changed as we read it" warning
    my @command = ('/bin/tar', '--create', '--gzip',
		   '--file', $file,
		   '--exclude', "backup",
		   '--directory', "$dir/..",
		   encode_utf8($capsule));
    $log->debug("@command");
    if (system(@command) == 0) {
      $log->info("Serving new data archive for $capsule");
      success($stream, "application/tar");
      $stream->write(read_binary($file));
    } else {
      $log->error("Creation of data archive for $capsule failed");
      result($stream, "59", "Archive creation failed");
    }
  }
  return 1;
}

sub serve_capsule_backup {
  my ($stream, $host, $capsule, $id) = @_;
  my $name = capsule_name($stream);
  return 1 unless is_my_capsule($stream, $name, $capsule, 'view the backup of');
  my $dir = capsule_dir($host, $capsule) . "/backup";
  if ($id) {
    $log->info("Serving $capsule backup $id");
    # this works for text files, too!
    success($stream, mime_type($id));
    my $file = $dir . "/" . encode_utf8($id);
    $stream->write(read_binary($file));
  } else {
    $log->info("Backup for $capsule");
    success($stream);
    $stream->write("# " . ucfirst($capsule) . " backup\n");
    $stream->write("When editing a page, a backup is saved here as long as at least 10 minutes have passed.\n");
    my @files;
    @files = read_dir($dir) if -d $dir;
    if (not @files) {
      $stream->write("There are no backup files, yet.\n") unless @files;
    } else {
      $stream->write("Files:\n");
      for my $file (sort @files) {
	print_link($stream, $host, $capsule_space, $file, "$capsule/backup/$file");
      };
    }
  }
  return 1;
}

sub serve_capsule_delete {
  my ($stream, $host, $capsule, $id) = @_;
  my $name = capsule_name($stream);
  return 1 unless is_my_capsule($stream, $name, $capsule, 'delete a file in');
  my $dir = capsule_dir($host, $capsule);
  if ($id) {
    $log->info("Delete $id from $capsule");
    my $file = $dir . "/" . encode_utf8($id);
    my $backup_dir = "$dir/backup";
    my $backup_file = $backup_dir . "/" . encode_utf8($id);
    mkdir($backup_dir) unless -d $backup_dir;
    rename $file, $backup_file if -f $file;
    result($stream, "30", to_url($stream, $host, $capsule_space, $capsule));
  } else {
    $log->info("Delete for $capsule");
    success($stream);
    $stream->write("# Delete a file in " . ucfirst($capsule) . "\n");
    $stream->write("Deleting a file moves it to the backup.\n");
    my @files;
    @files = grep { $_ ne "backup" } read_dir($dir) if -d $dir;
    if (not @files) {
      $stream->write("There are no files to delete.\n") unless @files;
    } else {
      $stream->write("Files:\n");
      for my $file (sort @files) {
	print_link($stream, $host, $capsule_space, $file, "$capsule/delete/$file");
      };
    }
  }
  return 1;
}

sub serve_capsule_access {
  my ($stream, $host, $capsule, $token) = @_;
  my $fingerprint = $stream->handle->get_fingerprint();
  my $target = first { $_->[1] eq $token } @capsule_tokens;
  if (not $fingerprint) {
    $log->info("Attempt to access a capsule without client certificate");
    result($stream, "60", "You need a client certificate to access this capsule");
  } elsif ($target) {
    if ($fingerprint ne $target->[2]) {
      $log->info("Access to capsule granted");
      # if the user is testing it, then the two fingerprints are the same and no
      # equivalency needs to be saved
      $capsule_equivalent{$fingerprint} = $target->[2];
      my $dir = $server->{wiki_dir};
      write_binary("$dir/fingerprint_equivalents",
		   join("\n", map { $_ . " " . $capsule_equivalent{$_} }
			keys %capsule_equivalent));
    } else {
      $log->info("Access to capsule unnecessary for the owner");
    }
    result($stream, "30", to_url($stream, $host, $capsule_space, $capsule));
  } else {
    $log->info("Access to capsule denied");
    success($stream);
    $stream->write("This password is invalid\n");
  }
  return 1;
}

sub serve_capsule_sharing {
  my ($stream, $host, $capsule) = @_;
  my $name = capsule_name($stream);
  return 1 unless is_my_capsule($stream, $name, $capsule, 'share');
  $log->info("Share capsule");
  my $token = capsule_name(sprintf "-------%04X%04X%04X", rand(0xffff), rand(0xffff), rand(0xffff));
  push(@capsule_tokens, [time, $token, $stream->handle->get_fingerprint()]);
  # forget old access tokens in ten minutes
  Mojo::IOLoop->timer(601 => \&capsule_token_cleanup);
  success($stream);
  $stream->write("# Share access to " . ucfirst($capsule) . "\n");
  $stream->write("This password is valid for ten minutes: $token\n");
  return 1;
}

sub is_my_capsule {
  my ($stream, $name, $capsule, $verb) = @_;
  if (not $name) {
    $log->info("Attempt to $verb a capsule without client certificate");
    result($stream, "60", "You need a client certificate to $verb this capsule");
    return 0;
  } elsif ($capsule and $name ne $capsule) {
    $log->info("Attempt to $verb the wrong capsule");
    result($stream, "60", "You need a different client certificate to $verb this capsule");
    return 0;
  }
  return 1;
}

sub serve_capsule_page {
  my ($stream, $host, $capsule, $id) = @_;
  my $dir = capsule_dir($host, $capsule);
  my $file = $dir . "/" . encode_utf8($id);
  if (-f $file) {
    $log->info("Serving $file");
    # this works for text files, too!
    success($stream, mime_type($id));
    $stream->write(read_binary($file));
  } else {
    $log->info("Serving invitation to upload $file");
    success($stream);
    $stream->write("This file does not exist. Upload it using Titan!\n");
    $stream->write("=> gemini://transjovian.org/titan What is Titan?\n");
  }
  return 1;
}

sub serve_capsule_menu {
  my ($stream, $host, $capsule) = @_;
  my $name = capsule_name($stream);
  my $dir = capsule_dir($host, $capsule);
  my @files;
  @files = read_dir($dir) if -d $dir;
  my $has_backup = first { $_ eq "backup" } @files;
  @files = grep { $_ ne "backup" } @files if $has_backup;
  success($stream);
  $log->info("Serving $capsule");
  $stream->write("# " . ucfirst($capsule) . "\n");
  if ($name) {
    if ($name eq $capsule) {
      print_link($stream, $host, $capsule_space, "Specify file for upload", "$capsule/upload");
      print_link($stream, $host, $capsule_space, "Delete file", "$capsule/delete") if @files;
      print_link($stream, $host, $capsule_space, "Share access with other people or other devices", "$capsule/share");
      print_link($stream, $host, $capsule_space, "Access backup", "$capsule/backup") if $has_backup;
      print_link($stream, $host, $capsule_space, "Download archive", "$capsule/archive") if @files;
    } elsif (@capsule_tokens) {
      print_link($stream, $host, $capsule_space, "Access this capsule", "$capsule/access");
    }
  }
  if (@files) {
    $stream->write("Files:\n");
    for my $file (sort @files) {
      print_link($stream, $host, $capsule_space, $file, "$capsule/$file");
    }
  }
  return 1;
}

sub serve_main_menu {
  my ($stream, $host) = @_;
  success($stream);
  $log->info("Serving capsules");
  $stream->write("# Capsules\n");
  my $capsule = capsule_name($stream);
  if ($capsule) {
    $stream->write("This is your capsule:\n");
    print_link($stream, $host, $capsule_space, $capsule, $capsule); # must provide $id to avoid page/ prefix
  } else {
    $stream->write("Login if you are interested in a capsule:\n");
    print_link($stream, $host, $capsule_space, "login", "login"); # must provide $id to avoid page/ prefix
  }
  $stream->write("=> $capsule_help Help\n") if $capsule_help;
  my @capsules = read_dir(wiki_dir($host, $capsule_space));
  $stream->write("Capsules:\n") if @capsules;
  for my $dir (sort @capsules) {
    print_link($stream, $host, $capsule_space, $dir, $dir); # must provide $id to avoid page/ prefix
  };
  return 1;
}

# capsule is already decoded and gets encoded again
sub capsule_dir {
  my $host = shift;
  my $capsule = shift;
  my $dir = $server->{wiki_dir};
  if (keys %{$server->{host}} > 1) {
    $dir .= "/$host";
    mkdir($dir) unless -d $dir;
  }
  $dir .= "/$capsule_space";
  mkdir($dir) unless -d $dir;
  $dir .= "/" . encode_utf8($capsule);
  return $dir;
}

sub capsule_regex {
  return join("|", map { quotemeta domain_to_ascii $_ } @capsule_hosts) || host_regex();
}

# For 'sha256$5a4a0248b753' the name is tibedied (the first name for Elite names)
sub capsule_name {
  my $stream = shift;
  # $stream can be a fingerprint string
  my $fingerprint = ref $stream ? $stream->handle->get_fingerprint() : $stream;
  return unless $fingerprint;
  $fingerprint = $capsule_equivalent{$fingerprint} if $capsule_equivalent{$fingerprint};
  my @stack = map { hex } substr($fingerprint, 7, 12) =~ /(....)/g;
  my $digraphs = "..lexegezacebisousesarmaindirea.eratenberalavetiedorquanteisrion";
  my $longname = $stack[0] & 0x40;
  my $name;
  # say "@stack";
  for my $n (1 .. 4) {
    my $d = (($stack[2] >> 8) & 0x1f) << 1;
    push(@stack, sum(@stack) % 0x10000);
    shift(@stack);
    $name .= substr($digraphs, $d, 2)
	if $n <= 3 or $longname;
  }
  $name =~ s/\.//g;
  return $name;
}

sub mime_type {
  $_ = shift;
  my $mime = globs($_);
  return $mime if $mime;
  # fallback
  return 'text/gemini' if /\.gmi$/i;
  return 'text/plain' if /\.te?xt$/i;
  return 'text/markdown' if /\.md$/i;
  return 'text/html' if /\.html?$/i;
  return 'image/png' if /\.png$/i;
  return 'image/jpeg' if /\.jpe?g$/i;
  return 'image/gif' if /\.gif$/i;
  return 'application/octet-stream';
}

sub capsule_token_cleanup {
  # only keep tokens created in the last 10 minutes
  my $ts = time - 600;
  @capsule_tokens = grep { $_->[0] > $ts } @capsule_tokens;
}

unshift(@request_handlers, '^titan://(' . capsule_regex() . ')(?::\d+)?/' . $capsule_space . '/' => \&handle_titan);

# We need our own Titan handler because we want a different copy of is_upload;
# and once we're here we can run our extension directly.
sub handle_titan {
  my $stream = shift;
  my $data = shift;
  # extra processing of the request if we didn't do that, yet
  $data->{upload} ||= is_upload($stream, $data->{request}) or return;
  my $size = $data->{upload}->{params}->{size};
  my $actual = length($data->{buffer});
  if ($actual == $size) {
    save_file($stream, $data->{request}, $data->{upload}, $data->{buffer}, $size);
    $stream->close_gracefully();
    return;
  } elsif ($actual > $size) {
    $log->debug("Received more than the promised $size bytes");
    result($stream, "59", "Received more than the promised $size bytes");
    $stream->close_gracefully();
    return;
  }
  $log->debug("Waiting for " . ($size - $actual) . " more bytes");
}

# We need our own is_upload because the regular expression is different.
sub is_upload {
  my $stream = shift;
  my $request = shift;
  $log->info("Looking at capsule $request");
  my $hosts = capsule_regex();
  my $port = port($stream);
  if ($request =~ m!^titan://($hosts)(?::$port)?/$capsule_space/([^/?#;]+)/([^/?#;]+);([^?#]+)$!) {
    my $host = $1;
    my ($capsule, $id, %params) = map {decode_utf8(uri_unescape($_))} $2, $3, split(/[;=&]/, $4);
    if (valid_params($stream, $host, $capsule_space, $id, \%params)) {
      return {
	host => $host,
	space => $capsule_space,
	capsule => $capsule,
	id => $id,
	params => \%params,
      }
    }
    # valid_params printed a response and closed the stream
    return;
  }
  $log->debug("Capsule upload with malformed titan URL");
  if ($request =~ m!^titan://($hosts)(?::$port)?/$capsule_space/([^/?#;]+)/([^/?#;]+);([^?#]*)[?#]!) {
    result($stream, "59", "The titan URL must not have a query or a fragment at the end");
  } elsif ($request =~ m!^titan://($hosts)(?::$port)?/$capsule_space/([^/?#;]+)/([^/?#;]+)/!) {
    result($stream, "59", "These capsules do not allow uploads for subdirectories");
  } elsif ($request =~ m!^titan://($hosts)(?::$port)?/$capsule_space/([^/?#;]+)/([^/?#;]+)$!) {
    result($stream, "59", "The titan URL is missing the parameters after a semikolon $1 $2 $3 $4");
  } elsif ($request =~ m!^titan://($hosts)(?::$port)?/$capsule_space/([^/?#;]+)/?(;.*)$!) {
    result($stream, "59", "The titan URL is missing the file name");
  } elsif ($request =~ m!^titan://($hosts)(?::$port)?/$capsule_space/?$!) {
    result($stream, "59", "The titan URL is missing the capsule name and the file name");
  } else {
    result($stream, "59", "The titan URL is malformed");
  }
  $stream->close_gracefully();
  return;
}

# We need our own valid_params because we don't check the token but we do check
# the extension
sub valid_params {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $params = shift;
  return unless valid_id($stream, $host, $space, $id, $params);
  # return unless valid_token($stream, $host, $space, $id, $params);
  $params->{mime} = mime_type($id);
  return unless valid_mime_type($stream, $host, $space, $id, $params);
  return unless valid_size($stream, $host, $space, $id, $params);
  return 1;
}

sub save_file {
  my ($stream, $url, $upload, $buffer, $size) = @_;
  my $name = capsule_name($stream);
  my $capsule = $upload->{capsule} || "";
  if (not $name) {
    $log->debug("Missing certificate for capsule upload");
    return result($stream, "60", "Uploading files requires a client certificate");
  } elsif ($name ne $capsule) {
    $log->debug("Wrong certificate for capsule upload: $name vs $capsule");
    return result($stream, "61", "This is not your space: your certificate authorizes you for $name");
  }
  return result($stream, "50", "Titan upload failed")
      unless defined $buffer and defined $size and $upload->{id}
      and $upload->{space} and $upload->{space} eq "capsule";
  my $host = $upload->{host};
  my $dir = capsule_dir($host, $capsule);
  my $id = $upload->{id};
  my $file = $dir . "/" . encode_utf8($id);
  if ($size == 0) {
    return result($stream, "51", "This capsule does not exist") unless -d $dir;
    return result($stream, "51", "This file does not exist") unless -f $file;
    return result($stream, "40", "Cannot delete this file") unless unlink $file;
    $log->info("Deleted $file");
  } else {
    mkdir($dir) unless -d $dir;
    backup($dir, $id);
    write_binary($file, $buffer);
    $log->info("Wrote $file");
    return result($stream, "30", to_url($stream, $host, $capsule_space, $capsule));
  }
}

sub backup {
  my ($dir, $id) = @_;
  my $file = $dir . "/" . encode_utf8($id);
  my $backup_dir = "$dir/backup";
  my $backup_file = $backup_dir . "/" . encode_utf8($id);
  return unless -f $file and (time - (stat($file))[9]) > 600;
  # make a backup if the last edit was more than 10 minutes ago
  mkdir($backup_dir) unless -d $backup_dir;
  write_binary($backup_file, read_binary($file));
}

1;
