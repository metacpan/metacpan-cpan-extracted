package Clustericious::Command::start;

use strict;
use warnings;
use Clustericious::Log;
use File::Path qw( mkpath );
use File::Basename qw( dirname );
use Clustericious::App;
use Clustericious::Config;
use Mojo::Base 'Clustericious::Command';
use Text::ParseWords qw( shellwords );
use Carp ();
use Env qw( @PERL5LIB );

# ABSTRACT: Clustericious command to start a Clustericious application
our $VERSION = '1.29'; # VERSION 


has description => <<EOT;
Start a daemon using the config file.
EOT

has usage => <<EOT;
usage $0: start
Start a daemon using the start_mode in the config file.
See Clustericious::Config for the format of the config file.
See Clustericious::Command::Start for examples.
EOT

sub run {
  my($self, @args) = @_;
  exit 2 unless $self->app->sanity_check;
  my $app  = $ENV{MOJO_APP};
  my $conf     = $self->app->config;

  eval "use $app;";
  die $@ if $@;

  $self->app->init_logging;

  for my $mode ($self->app->config->start_mode)
  {
    INFO "Starting $mode";
    my %conf = $conf->$mode;
    if(my $autogen = delete $conf{autogen})
    {
      $autogen = [ $autogen ] if ref $autogen eq 'HASH';
      for my $i (@$autogen)
      {
        DEBUG "autowriting ".$i->{filename};
        mkpath(dirname($i->{filename}), 0, 0700);
        open my $fp, ">$i->{filename}" or LOGDIE "cannot write to $i->{filename} : $!";
        print $fp $i->{content};
        close $fp or LOGDIE $!;
      }
    }

    # env hash goes to the environment
    my $env = delete $conf{env} || {};
    @ENV{ keys %$env } = values %$env;
    if($env->{PERL5LIB})
    {
      # Do it now, in case we are not spawning a new process.
      push @INC, @PERL5LIB;
    }
    TRACE "Setting env vars : ".join ',', keys %$env;

    my @args;

    if(my $args = delete $conf{args})
    {
      @args = ref $args ne 'ARRAY' ? (shellwords $args) : @$args;
    }
    elsif(%conf)
    {
      die "arguments specified withouth 'args' option\n";
    }

    DEBUG "Sending args for $mode : @args";
    $ENV{MOJO_COMMANDS_DONE} = 0;
    Clustericious::Commands->start($mode,@args);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::start - Clustericious command to start a Clustericious application

=head1 VERSION

version 1.29

=head1 SYNOPSIS

In your MyApp.conf:

 ---
 start_mode: hypnotoad
 hypnotoad:
   pid: /tmp/restmd.pid
   [...]
   env:
     foo: bar

Then on the command line

 % myapp start

Which is equivalent to

 % foo=bar myapp hypnotoad --pid /tmp/restmd.pid [..]

=head1 DESCRIPTION

Start a daemon using the config file and the start_mode.

Keys and values in the configuration file become
options preceded by double dashes.

If a key has a single dash, it is sent as is (with no double dash).

The special value C<null> means don't send an argument to the
command line option.

The special label C<env> is an optional hash of environment variables
to set before starting the command.

=head1 NAME

Clustericious::Command::start - Clustericious command to start a Clustericious application

=head1 SEE ALSO

L<Clustericious>,
L<Clustericious::Command::hypnotoad>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
