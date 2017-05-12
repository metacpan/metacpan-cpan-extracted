package Clustericious::Command::status;

use strict;
use warnings;
use 5.010001;
use Clustericious::Log;
use Mojo::UserAgent;
use Clustericious::App;
use Clustericious::Config;
use File::Basename qw( dirname );
use base 'Clustericious::Command';

# ABSTRACT: Clustericious command to report status of Clustericious application
our $VERSION = '1.24'; # VERSION


__PACKAGE__->attr(description => <<'');
Report the status of a daemon.

__PACKAGE__->attr(usage => <<"");
usage: $0 status
Report the status of a clustericious daemon.

sub _check_pidfile
{
  my($filename) = @_;
  return ( state => 'error', message => 'missing pid filename' ) unless $filename;
  return ( state => 'down', message => 'no pid file' ) unless -e $filename;
  my $pid = Mojo::Asset::File->new(path => $filename)->slurp;
  return ( state => 'down', messasge => 'no pid in file' ) unless $pid;
  return ( state => 'ok' ) if kill 0, $pid;
  return ( state => 'down', message => "Pid $pid in file is not running." );
}

sub _check_database
{
  my($db_class) = @_;
  my $db = $db_class->new_or_cached;
  my ( $domain, $type ) = ( $db->default_domain, $db->default_type );
  my $dbh = $db->dbh;
  my ( $state, $message );
  if ($dbh)
  {
    $state = 'ok';
    ($message) = join ':', grep {defined && length} $dbh->selectrow_array('select current_database(), inet_server_addr(), inet_server_port()');
  }
  else
  {
    $state   = 'down';
    $message = $db_class->name;
  }
  return {
    name    => "database",
    state   => $state,
    message => "$domain:$type $message",
  };
}

sub run
{
  my($self, @args) = @_;
  exit 2 unless $self->app->sanity_check;
  my $app  = $ENV{MOJO_APP};
  my $conf = $self->app->config;

  eval "require $app";
  die $@ if $@;

  my @status; # array of { name =>.., state =>.., message =>.. } hashrefs.

  my $exe = $0;
  # webserver
  for ($self->app->config->start_mode)
  {
    push @status, { name => $_,
     (
       # THIS IS A MESS PLEASE CLEAN IT UP
       /hypnotoad/ ? _check_pidfile($conf->hypnotoad->pid_file(default => dirname($exe).'/hypnotoad.pid'))
     : /apache/ ? _check_pidfile($conf->apache->pid_file)
     : /plackup/   ? _check_pidfile($conf->plackup->pidfile) 
       # NB: see http://redmine.lighttpd.net/issues/2137
       # lighttpd's pid files disappear.  Time to switch to nginx?
     : /lighttpd/     ? _check_pidfile($conf->lighttpd->pid_file)
     : ( state => 'error', message => "Status for start_mode $_ is unimplemented." ))};
  }

  # Do a HEAD request if the webserver(s) are ok.
  if ((grep {$_->{state} eq 'ok'} @status)==@status)
  {
    my $res = Mojo::UserAgent->new->head($conf->url)->res;
    printf "%10s : %-10s (%s %s)\n", "url", $conf->url, $res->code || '?', $res->message || '';
  }

  # Database
  if ( $INC{'Rose/Planter/DB.pm'} )
  {
    if ( my $db_class = Rose::Planter::DB->registered_by($app) )
    {
        push @status, _check_database($db_class);
    }
  }

  my $ok;

  # Send as YAML if requested?
  for (@status)
  {
    $_->{message} &&= "($_->{message})";;
    $_->{message} ||= "";
    printf "%10s : %-10s %s\n", @$_{qw/name state message/};
    $ok //= 1 if $_->{state} eq 'ok';
    $ok   = 0 if $_->{state} ne 'ok';
  }
  
  exit($ok ? 0 : 2);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::status - Clustericious command to report status of Clustericious application

=head1 VERSION

version 1.24

=head1 SYNOPSIS

 % yourapp status

=head1 DESCRIPTION

Report the status of a running clustericious daemon, based on its start_mode.

=head1 SEE ALSO

L<Clustericious>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
