package Dancer::Plugin::DynamicConfig;
use strict;
use warnings;
use Dancer ':syntax';
use Dancer::FileUtils qw(read_file_content);
use Dancer::ModuleLoader;
use Dancer::Plugin;
use Encode qw(encode);
use JSON::XS qw(decode_json);
use Time::HiRes;
use Try::Tiny;

our $VERSION = '0.07';

my @file_types = ({
  type => 'json',
  re => qr{\.json$},
  parser => sub {
    my ($filename) = @_;
    my $json;
    try {
      read_file_content($filename) =~ /(.*)/s; # untaint
      try {
        $json = decode_json(encode('UTF-8', $1));
      } catch {
        warning "couldn't parse json file ($filename): $_\n";
      };
    } catch {
      warning "couldn't find file to parse ($filename): $_\n";
    };
    return $json;
  },
});

my $dynamic_config;

register dynamic_config => sub {
  my ($file_key) = @_;

  initialize() unless $dynamic_config;

  if (my $fileinfo = $dynamic_config->{$file_key}) {
    my $mtime = (dc_stat($fileinfo->{path}))[9];

    if (not defined $fileinfo->{data} or $mtime > $fileinfo->{mtime}) {
      my $parsed = $fileinfo->{parser}->($fileinfo->{path});

      if (defined $parsed) {
        $fileinfo->{mtime}  = $mtime;
        $fileinfo->{data}   = $fileinfo->{rewrite_class} ? $fileinfo->{rewrite_class}->rewrite($parsed) : $parsed;
      } else {
        warning "could not parse $fileinfo->{path}";
        warning "$@" if $@;
      }
    }

    return $fileinfo->{data};
  } else {
    warning "unknown dynamic_config key [$file_key]";
  }

  return '';
};

sub reinitialize { undef $dynamic_config; initialize() }

sub initialize {
  SETTING: while (my ($file_key, $etc) = each %{ plugin_setting() }) {
    my ($path, $rewrite_class);
    if (ref $etc) {
      $path = $etc->{path};
      $rewrite_class = $etc->{rewrite_class};
    } else {
      $path = $etc;
    }

    foreach my $ft (@file_types) {
      if ($path =~ $ft->{re}) {
        $dynamic_config->{$file_key} = {
          path          => $path,
          mtime         => undef,
          data          => undef,
          type          => $ft->{type},
          parser        => $ft->{parser},
          rewrite_class => $rewrite_class,
        };

        if ($rewrite_class) {
          Dancer::ModuleLoader->load($rewrite_class) or die "Could not load $rewrite_class";
        }
        next SETTING;
      } else {
        warning "ignoring config key [$file_key]:  unknown filetype for [$path]";
        warn "ignoring config key [$file_key]:  unknown filetype for [$path]";
        # should this die? your config is so broken we can't start up
      }
    }
  }

  return;
}

sub dc_stat {
    my ($filething) = @_;

    if (defined &Time::HiRes::stat) {
        return Time::HiRes::stat($filething);
    } else {
        return stat($filething);
    }
}

register_plugin;

1;

__END__

=pod

=head1 NAME

Dancer::Plugin::DynamicConfig

=head1 SYNOPSIS

In your Dancer config.yml:

  plugins:
    DynamicConfig:
        active_sessions: "active_sessions.json"
        contacts:
          path: "etc/contact_info.json"
          rewrite_class: "ContactInfoRewriter"

In your Dancer application:

  use Dancer::Plugin::DynamicConfig;

  my $sessions = dynamic_config('active_sessions');
  my $contacts = dynamic_config('contacts');

  if (not $sessions->{$session_id}) {
    redirect $login_page;
    return;
  }

  my $user_id = $request->cookies->{user_id};
  if ($contacts->{$user_id}{is_platinum_user}) {
    $allow_platinum_features = 1;
  }

=head1 DESCRIPTION

B<Dancer::Plugin::DynamicConfig> provides a simple and efficient means to
read and decode the contents of a file which might change while your Dancer
application is running.

In your Dancer configuration, you declare a "tag" for the file, a path to the
file, and an (optional) rewrite_class. You can then call C<dynamic_config()>,
passing in your tag, and you will receive back a data structure that
represents the contents of the file on disk. C<dynamic_config()> will cache
the data, and only re-read it when the file's mtime has changed.

=head2 The rewrite_class

This class, if provided, must implement one class method, C<rewrite()>, which
takes the decoded data structure represented by the file's contents.
C<rewrite()> may then return any data structure it likes, and this structure
will be passed back as the return value of C<dynamic_config()>.

=head2 Filetypes

Currently, B<Dancer::Plugin::DynamicConfig> only supports JSON files, and requires
that the filename end in C<".json">. Generalizing this behavior is on the short
list of coming improvements.

=head2 KEYWORDS

=over 4

=item dynamic_config($config_key)

=back

=head2 METHODS

=over 4

=item reinitialize

Forces a cache flush and re-read of the Dancer configuration and all dynamic_config files.

=back

=head1 NOTES

This plugin uses C<Time::HiRes::stat()> to detect the mtimes of your
configuration files. Timestamp resolution is limited by not only your
operating system, but also the filesystem you are accessing. In
particular, Mac OS X HFS will usually have a timestamp resolution of
one second. On such filesystems, if the file is updated, e.g., twice
in one second, there is a potential race condition in which you will
cache the results of the first update and not realize that there has
been a second update.

=head1 AUTHOR

Kurt Starsinic <kstarsinic@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kurt Starsinic. It was originally
authored at and for Shutterstock, Inc., which has graciously allowed this
code to be made publicly available.

This module is free software; you can redistribute and/or modify it under the
same terms as perl 5.18.1.

=head1 SEE ALSO

L<Dancer>, L<Dancer::Plugin>, L<JSON::XS>, L<Time::HiRes>

=cut

