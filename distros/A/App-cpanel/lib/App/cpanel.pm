package App::cpanel;

use Exporter 'import';

our $VERSION = '0.006';
our @EXPORT_OK = qw(dispatch_cmd_print dispatch_cmd_raw_p dir_walk_p);

=head1 NAME

App::cpanel - CLI for cPanel UAPI and API 2

=begin markdown

# PROJECT STATUS

[![CPAN version](https://badge.fury.io/pl/App-cpanel.svg)](https://metacpan.org/pod/App::cpanel)

=end markdown

=head1 SYNOPSIS

  $ cpanel uapi Notifications get_notifications_count
  $ cpanel uapi ResourceUsage get_usages
  $ cpanel uapi Fileman list_files dir=public_html
  $ cpanel uapi Fileman get_file_content dir=public_html file=index.html
  $ cpanel download public_html/index.html
  $ cpanel api2 Fileman fileop op=chmod metadata=0755 sourcefiles=public_html/cgi-bin/hello-world
  $ cpanel api2 Fileman fileop op=unlink sourcefiles=public_html/cgi-bin/hello-world
  $ cpanel api2 Fileman mkdir path= name=new-dir-at-top

  # this one is one at a time but can overwrite files
  $ cpanel api2 Fileman savefile dir=public_html/cgi-bin filename=hello-world content="$(cat public_html/cgi-bin/hello-world)"
  # this is multiple files but refuses to overwrite
  $ cpanel upload public_html/cgi-bin hello-world

  # download
  $ cpanel mirror public_html public_html cpanel localfs
  # upload
  $ cpanel mirror public_html public_html localfs cpanel

=head1 DESCRIPTION

CLI for cPanel UAPI and also API 2, due to missing functionality in UAPI.

Stores session token in F<~/.cpanel-token>, a two-line file. First line
is the URL component that goes after C<cpsess>. Second is the C<cpsession>
cookie, which you can get from your browser's DevTools.

Stores relevant domain name in F<~/.cpanel-domain>.

=head1 FUNCTIONS

Exportable:

=head2 dispatch_cmd_print

Will print the return value, using L<Mojo::Util/dumper> except for
C<download>.

=head2 dispatch_cmd_raw_p

Returns a promise of the decoded JSON value or C<download>ed content.

=head2 dir_walk_p

Takes C<$from_dir>, C<$to_dir>, C<$from_map>, C<$to_map>. Copies the
information in the first directory to the second, using the respective
maps. Assumes UNIX-like semantics in filenames, i.e. C<$dir/$file>.

Returns a promise of completion.

The maps are hash-refs whose values are functions, and the keys are:

=head3 ls

Takes C<$dir>. Returns a promise of two hash-refs, of directories and of
files. Each has keys of relative filename, values are an array-ref
containing a string octal number representing UNIX permissions, and a
number giving the C<mtime>. Must reject if does not exist.

=head3 mkdir

Takes C<$dir>. Returns a promise of having created the directory.

=head3 read

Takes C<$dir>, C<$file>. Returns a promise of the file contents.

=head3 write

Takes C<$dir>, C<$file>. Returns a promise of having written the file
contents.

=head3 chmod

Takes C<$path>, C<$perms>. Returns a promise of having changed the
permissions.

=head1 SEE ALSO

L<https://documentation.cpanel.net/display/DD/Guide+to+UAPI>

L<https://documentation.cpanel.net/display/DD/Guide+to+cPanel+API+2>

=head1 AUTHOR

Ed J

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::File qw(path);
use Mojo::Util qw(dumper encode);

my %cmd2func = (
  uapi => [ \&uapi_p, 1 ],
  download => [ \&download_p, 0 ],
  upload => [ \&upload_p, 1 ],
  api2 => [ \&api2_p, 1 ],
  mirror => [ \&mirror_p, 1 ],
);
my $token_file = "$ENV{HOME}/.cpanel-token";
my $domain_file = "$ENV{HOME}/.cpanel-domain";
my %localfs_map = (
  ls => \&localfs_ls,
  mkdir => \&localfs_mkdir,
  read => \&localfs_read,
  write => \&localfs_write,
  chmod => \&localfs_chmod,
);
my %cpanel_map = (
  ls => \&cpanel_ls,
  mkdir => \&cpanel_mkdir,
  read => \&cpanel_read,
  write => \&cpanel_write,
  chmod => \&cpanel_chmod,
);
our %MAP2HASH = (
  localfs => \%localfs_map,
  cpanel => \%cpanel_map,
);

sub dispatch_cmd_print {
  my $cmd = shift;
  die "No command\n" unless $cmd;
  die "Unknown command '$cmd'\n" unless my $info = $cmd2func{$cmd};
  my $p = dispatch_cmd_raw_p($cmd, @_);
  $p = $p->then(\&dumper) if $info->[1];
  $p->then(sub { print @_ }, sub { warn encode 'UTF-8', join '', @_ })->wait;
}

sub dispatch_cmd_raw_p {
  my $cmd = shift;
  die "No command\n" unless $cmd;
  die "Unknown command '$cmd'\n" unless my $info = $cmd2func{$cmd};
  goto &{$info->[0]};
}

sub api_request {
  my ($method, $domain, $token, $parts, $args, @extra_args) = @_;
  my ($url_token, $cookie_token) = split /\s+/, $token;
  my $url = Mojo::URL->new("https://$domain:2083");
  $url->path(join '/', '', "cpsess$url_token", @$parts);
  $url->query(%$args) if $args;
  CORE::state $ua = Mojo::UserAgent->new; # state as needs to live long enough to complete request
  $ua->$method(
    $url->to_abs . "",
    { Cookie => "cpsession=$cookie_token" },
    @extra_args,
  );
}

sub read_file {
  my ($file) = @_;
  die "$file: $!\n" unless -f $file;
  die "$file: too readable\n" if (stat $file)[2] & 0044;
  local $/;
  open my $fh, $file or die "$file: $!\n";
  my $content = <$fh>;
  die "No content in '$file'\n" unless $content;
  $content =~ s/^\s*(.*?)\s*$/$1/g;
  $content;
}

sub read_token { read_file($token_file) }
sub read_domain { read_file($domain_file) }

sub _error_or_json {
  my $res = $_[0]->res;
  die $res->code . ": " . $res->message . "\n" if $res->code != 200;
  $res->json;
}

sub _uapi_error_or_json {
  my $json = $_[0];
  if (!$json->{status}) {
    die join '', "Failed:\n",
      map "$_\n", map @{ $json->{$_} || [] }, qw(errors warnings);
  }
  $json;
}

sub uapi_p {
  my ($module, $function, @args) = @_;
  die "No module\n" unless $module;
  die "No function\n" unless $function;
  my ($token, $domain) = (read_token(), read_domain());
  my $args_hash = ref($args[0]) eq 'HASH'
    ? $args[0]
    : { map split('=', $_, 2), @args }
    if @args;
  my $tx_p = api_request 'get_p', $domain, $token,
    [ 'execute', $module, $function ],
    $args_hash;
  $tx_p->then(\&_error_or_json)->then(\&_uapi_error_or_json);
}

sub download_p {
  my ($file) = @_;
  die "No file\n" unless $file;
  my ($token, $domain) = (read_token(), read_domain());
  my $tx_p = api_request 'get_p', $domain, $token,
    [ 'download' ],
    { skipencode => 1, file => $file };
  $tx_p->then(sub {
    my $res = $_[0]->res;
    die $res->code . ": " . $res->message . "\n" if $res->code != 200;
    $res->body;
  });
}

sub make_upload_form {
  my $dir = shift;
  my $counter = 0;
  +{
    dir => $dir,
    map {
      my $p = path $_;
      ('file-' . ++$counter => {
        filename => $p->basename,
        content => $p->slurp,
      });
    } @_,
  };
}

sub upload_p {
  my ($dir, @files) = @_;
  die "No dir\n" unless $dir;
  die "No files\n" unless @files;
  my ($token, $domain) = (read_token(), read_domain());
  my $tx_p = api_request 'post_p', $domain, $token,
    [ 'execute', 'Fileman', 'upload_files' ],
    undef,
    form => make_upload_form($dir, @files),
    ;
  $tx_p->then(\&_error_or_json)->then(\&_uapi_error_or_json);
}

sub _api2_error_or_json {
  my $json = $_[0];
  my $result = $json->{cpanelresult};
  if (!$result or !$result->{event}{result} or $result->{error}) {
    die join '', "Failed:\n",
      map "$_\n",
      ($result->{error} ? $result->{error} : ()),
      (map "$_->{src}: $_->{err}", grep !$_->{result}, @{$result->{data} || []}),
      ;
  }
  $json;
}

sub api2_p {
  my ($module, $function, @args) = @_;
  die "No module\n" unless $module;
  die "No function\n" unless $function;
  my ($token, $domain) = (read_token(), read_domain());
  my $args_hash = ref($args[0]) eq 'HASH'
    ? $args[0]
    : { map split('=', $_, 2), @args }
    if @args;
  my $tx_p = api_request 'post_p', $domain, $token,
    [ qw(json-api cpanel) ],
    {
      cpanel_jsonapi_module => $module,
      cpanel_jsonapi_func => $function,
      cpanel_jsonapi_apiversion => 2,
      %{ $args_hash || {} },
    };
  $tx_p->then(\&_error_or_json)->then(\&_api2_error_or_json);
}

sub dir_walk_p {
  my ($from_dir, $to_dir, $from_map, $to_map) = @_;
  my $from_dir_perms;
  $to_map->{ls}->($to_dir)->catch(sub {
    # only create if ls fails
    $to_map->{mkdir}->($to_dir)
  })->then(sub {
    $from_map->{ls}->(path($from_dir)->dirname)
  })->then(sub {
    my ($dirs, $files) = @_;
    $from_dir_perms = $dirs->{path($from_dir)->basename}[0] || '0755';
  })->then(sub {
    $to_map->{chmod}->($to_dir, $from_dir_perms)
  })->then(sub {
    $from_map->{ls}->($from_dir)
  })->then(sub {
    my ($dirs, $files) = @_;
    my @dir_create_p = map
      dir_walk_p("$from_dir/$_", "$to_dir/$_", $from_map, $to_map),
        sort keys %$dirs;
    my @file_create_p = map {
      my $this_file = $_;
      $from_map->{read}->($from_dir, $this_file)
        ->then(sub { $to_map->{write}->($to_dir, $this_file, $_[0]) })
        ->then(sub { $to_map->{chmod}->("$to_dir/$this_file", $files->{$this_file}[0]) })
    } sort keys %$files;
    return Mojo::Promise->resolve(1) unless @dir_create_p + @file_create_p;
    Mojo::Promise->all(@dir_create_p, @file_create_p);
  });
}

sub mirror_p {
  my ($from_dir, $to_dir, $from_map, $to_map) = @_;
  die "No from_dir\n" unless $from_dir;
  die "No to_dir\n" unless $to_dir;
  die "No from_map\n" unless $from_map;
  die "No to_map\n" unless $to_map;
  die "Invalid from_map\n" unless $from_map = $MAP2HASH{$from_map};
  die "Invalid to_map\n" unless $to_map = $MAP2HASH{$to_map};
  dir_walk_p $from_dir, $to_dir, $from_map, $to_map;
}

sub localfs_ls {
  my ($dir) = @_;
  my $dir_path = path($dir);
  my %files = map {
    ($_->basename => [ sprintf("%04o", $_->lstat->mode & 07777), $_->lstat->mtime ])
  } $dir_path->list({hidden => 1})->each;
  my %dirs = map {
    ($_->basename => [ sprintf("%04o", $_->lstat->mode & 07777), $_->lstat->mtime ])
  } $dir_path->list({dir => 1, hidden => 1})->grep(sub { !$files{$_->basename} })->each;
  Mojo::Promise->resolve(\%dirs, \%files);
}

sub localfs_mkdir {
  my ($dir) = @_;
  my $dir_path = path($dir);
  $dir_path->make_path;
  Mojo::Promise->resolve(1);
}

sub localfs_read {
  my ($dir, $file) = @_;
  my $path = path($dir)->child($file);
  Mojo::Promise->resolve($path->slurp);
}

sub localfs_write {
  my ($dir, $file, $content) = @_;
  my $path = path($dir)->child($file);
  $path->spurt($content);
  Mojo::Promise->resolve(1);
}

sub localfs_chmod {
  my ($path, $perms) = @_;
  $path = path($path);
  $path->chmod(oct $perms);
  Mojo::Promise->resolve(1);
}

sub cpanel_ls {
  my ($dir) = @_;
  uapi_p(qw(Fileman list_files), { dir => $dir })->then(sub {
    my (%dirs, %files);
    ($_->{type} eq 'dir' ? \%dirs : \%files)->{$_->{file}} =
      [ $_->{nicemode}, $_->{mtime} ]
      for @{ $_[0]->{data} };
    (\%dirs, \%files);
  });
}

sub cpanel_read {
  my ($dir, $file) = @_;
  download_p "$dir/$file";
}

sub cpanel_mkdir {
  my ($dir) = @_;
  $dir = path $dir;
  api2_p qw(Fileman mkdir), { path => $dir->dirname, name => $dir->basename };
}

sub cpanel_write {
  my ($dir, $file, $content) = @_;
  api2_p qw(Fileman savefile), {
    dir => $dir, filename => $file, content => $content,
  };
}

sub cpanel_chmod {
  my ($path, $perms) = @_;
  api2_p qw(Fileman fileop), {
    op => 'chmod', metadata => $perms, sourcefiles => $path,
  };
}

1;
