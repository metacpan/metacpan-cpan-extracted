package CGI::Tiny::_Debug;

# This file is part of CGI::Tiny which is released under:
#   The Artistic License 2.0 (GPL Compatible)
# See the documentation for CGI::Tiny for full license details.

use strict;
use warnings;

our $VERSION = '1.003';

my %methods = (get => 1, head => 1, post => 1, put => 1, delete => 1);
sub debug_command {
  my ($cgi, $argv) = @_;
  return 1 unless @$argv;
  my $command = shift @$argv;
  if (exists $methods{$command}) {
    $cgi->{debug_method} = uc $command;
    $cgi->{debug_verbose} = 1 if uc($command) eq 'HEAD';

    require Getopt::Long;
    Getopt::Long::Configure('default', 'gnu_getopt', 'no_ignore_case');
    Getopt::Long::GetOptionsFromArray($argv,
      'content|c=s' => \my $content,
      'cookie|C=s' => \my @cookies,
      'header|H=s' => \my @headers,
      'verbose|v' => \$cgi->{debug_verbose},
    ) or die "Failed to parse debug command options\n";

    my ($path) = @$argv;

    if (defined $content) {
      open my $in_fh, '<', \$content or die "Failed to open in-memory handle to request content: $!\n";
      $cgi->set_input_handle($in_fh);
    }

    foreach my $header (@headers) {
      my ($name, $value) = split /\s*:\s*/, $header, 2;
      next unless defined $value;
      $name =~ tr/-/_/;
      if (defined $ENV{"HTTP_\U$name"}) {
        $ENV{"HTTP_\U$name"} .= ", $value";
      } else {
        $ENV{"HTTP_\U$name"} = $value;
      }
    }

    $ENV{HTTP_CONTENT_LENGTH} = length $content if defined $content;
    $ENV{HTTP_CONTENT_LENGTH} = '' unless defined $ENV{HTTP_CONTENT_LENGTH};
    $ENV{HTTP_CONTENT_TYPE} = 'application/octet-stream' if $ENV{HTTP_CONTENT_LENGTH} and !defined $ENV{HTTP_CONTENT_TYPE};
    $ENV{HTTP_COOKIE} = join '; ', @cookies if @cookies;

    my $query;
    ($path, $query) = split /\?/, $path, 2 if defined $path;
    $ENV{AUTH_TYPE} = '' unless defined $ENV{AUTH_TYPE};
    $ENV{CONTENT_LENGTH} = $ENV{HTTP_CONTENT_LENGTH};
    $ENV{CONTENT_TYPE} = $ENV{HTTP_CONTENT_TYPE};
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1' unless defined $ENV{GATEWAY_INTERFACE};
    $ENV{PATH_INFO} = defined $path ? $path : '';
    $ENV{PATH_TRANSLATED} = '' unless defined $ENV{PATH_TRANSLATED};
    $ENV{QUERY_STRING} = defined $query ? $query : '';
    $ENV{REMOTE_ADDR} = '127.0.0.1' unless defined $ENV{REMOTE_ADDR};
    $ENV{REMOTE_HOST} = do { require Sys::Hostname; Sys::Hostname::hostname() } unless defined $ENV{REMOTE_HOST};
    $ENV{REMOTE_IDENT} = '' unless defined $ENV{REMOTE_IDENT};
    $ENV{REMOTE_USER} = '' unless defined $ENV{REMOTE_USER};
    $ENV{REQUEST_METHOD} = uc $command;
    $ENV{SCRIPT_NAME} = do { require File::Basename; '/' . File::Basename::basename($0) } unless defined $ENV{SCRIPT_NAME};
    $ENV{SERVER_NAME} = do { require Sys::Hostname; Sys::Hostname::hostname() } unless defined $ENV{SERVER_NAME};
    $ENV{SERVER_PORT} = 80 unless defined $ENV{SERVER_PORT};
    $ENV{SERVER_PROTOCOL} = 'HTTP/1.0' unless defined $ENV{SERVER_PROTOCOL};
    $ENV{SERVER_SOFTWARE} = "CGI::Tiny/$VERSION" unless defined $ENV{SERVER_SOFTWARE};
  } else {
    die "Unknown debug command $command\n";
  }
  return 1;
}

1;

=for Pod::Coverage *EVERYTHING*

=cut
