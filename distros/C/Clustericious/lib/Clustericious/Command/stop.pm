package Clustericious::Command::stop;

use strict;
use warnings;
use 5.010001;
use Clustericious::Log;
use Clustericious::App;
use Mojo::URL;
use File::Basename qw( dirname );
use base 'Clustericious::Command';
use Clustericious;

# ABSTRACT: Clustericious command to stop a Clustericious application
our $VERSION = '1.27'; # VERSION


__PACKAGE__->attr(description => <<EOT);
Stop a running daemon.
EOT

__PACKAGE__->attr(usage => <<EOT);
usage $0: stop

Send a TERM signal to running daemon(s).
See Clustericious::Command::Stop.
EOT

sub _stop_pidfile
{
  my($pid_file, $signal) = @_;
  -e $pid_file or do { WARN "No pid file $pid_file\n"; return; };
  TRACE "pid_file : $pid_file";
  my $pid = Clustericious::_slurp_pid $pid_file; # dies automatically
  chomp $pid;
  TRACE "file $pid_file has pid $pid";
  _stop_pid($pid, $signal);
  -e $pid_file or return;
  unlink $pid_file or WARN "Could not remove $pid_file";
}

sub _stop_pid
{
  my($pid, $signal) = @_;
  $signal //= 'QUIT';
  unless ($pid && $pid=~/^\d+$/)
  {
    WARN "Bad pid '$pid'.  Not stopping process.";
    return;
  }
  kill 0, $pid or do { WARN "$pid is not running"; return; };
  INFO "Sending $signal to $pid";
  kill $signal, $pid;
  sleep 1;
  my $nap = 1;
  while (kill 0, $pid)
  {
    INFO "waiting for $pid";
    sleep $nap++;
    if($nap > 5)
    {
      INFO "pid $pid did not die on request, killing with signal 9";
      kill 9, $pid;
      last;
    }
  }
}

sub _stop_daemon
{
  my($listen) = @_;
  my $port = Mojo::URL->new($listen)->port;
  my @got = `lsof -n -FR -i:$port`;
  return unless @got && $got[0];
  # Only the first one; others may be child processes
  my ($pid) = $got[0] =~ /^p(\d+)$/;
  unless ($pid) 
  {
    WARN "could not find pid for daemon on port $port";
    return;
  }
  TRACE "Stopping pid $pid";
  _stop_pid($pid);
}

sub _stop_nginx
{
  my %conf = @_;
  my $prefix = $conf{'-p'};
  my $cnf = $conf{'-c'} || "";
  $cnf = "-c $cnf" if $cnf;
  INFO "stopping nginx in $prefix";
  system("nginx -p $prefix $cnf -s quit")==0 or WARN "could not stop nginx";
}

sub _stop_apache
{
  my %conf = @_;
  _stop_pidfile($conf{pid_file},'TERM');
}

sub run
{
  my($self, @args) = @_;
  exit 2 unless $self->app->sanity_check;

  $self->app->init_logging();

  my $exe = $0;
  for (reverse $self->app->config->start_mode) {
    DEBUG "Stopping $_ server";
    /hypnotoad/ and _stop_pidfile($self->app->config->hypnotoad->pid_file);
    /plackup/   and _stop_pidfile($self->app->config->plackup->pid_file);
    /lighttpd/  and _stop_pidfile($self->app->config->lighttpd->pid_file);
    /daemon/    and _stop_daemon($self->app->config->daemon->listen);
    /nginx/     and _stop_nginx($self->app->config->nginx);
    /apache/    and _stop_apache($self->app->config->apache);
  }

  1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::stop - Clustericious command to stop a Clustericious application

=head1 VERSION

version 1.27

=head1 SYNOPSIS

 % yourapp stop

=head1 DESCRIPTION

Stop a running daemon.

=head1 NOTES

The different methods of starting put their pid files in
different places in the config file.  

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
