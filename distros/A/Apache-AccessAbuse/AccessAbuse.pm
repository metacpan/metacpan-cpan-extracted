package Apache::Access::Abuse;

use 5.006;
use strict;
use warnings;
use Apache::Constants qw/:common/;
use Apache::Log;
use IPC::Shareable;
use vars qw(%NETTABLE);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Apache::Access::Abuse ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.003';
our $MODNAME = 'Apache::Access::Abuse';

#
# Local Vars;
#

my $net;

#
# LogHandler
#
sub logger{
# get object request
  my $r = shift;
# check first request
  return DECLINED unless $r->is_initial_req;
# get log object
  my $log = $r->log;
#
  tied(%NETTABLE)->shlock;
#  $log->error(sprintf('[%s::logger] $NETTABLE=%d ', $MODNAME, $NETTABLE{$net}), $r->uri);
  delete $NETTABLE{$net} unless (--$NETTABLE{$net});
  tied(%NETTABLE)->shunlock;

  return DECLINED;
}

#
# AccessHandler:
#

sub handler {
# get object request
  my $r = shift;

# check first request
  return DECLINED unless $r->is_initial_req;

# get log object
  my $log = $r->log;

# get IP address from object request
  $net = $r->connection->remote_ip;
  $net =~ s/\d+$/0/;

# get AllowFrom
  my $allow = $r->dir_config('AllowFrom');
  foreach my $host (split(/\s/,$allow)) {
    next unless $host;
    return OK unless index($net, $host);
  }

# get MaxConnections
  my $maxconnections = int($r->dir_config('MaxConnections'));

  return SERVER_ERROR unless $maxconnections;
#
# Copied from Writting Apache Modules. sample module Apache::SpeedLimit, pg. 276
#
  tie %NETTABLE, 'IPC::Shareable', 'ApAc', {create =>1, mode => 0644} unless %NETTABLE;

# push logger handler
  $r->push_handlers(PerlLogHandler => \&logger);

  my $result = SERVER_ERROR;

  tied(%NETTABLE)->shlock;
  if(exists($NETTABLE{$net})) {
    $result = $NETTABLE{$net}++ < $maxconnections ? OK : FORBIDDEN;
    $log->error(sprintf('[%s::handler] $NETTABLE=%d ', $MODNAME, $NETTABLE{$net}), $r->uri) if $result == FORBIDDEN;
  }
  else {
    $NETTABLE{$net}=1;
    $result = OK;
  }
  tied(%NETTABLE)->shunlock;

  return $result;
}


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Apache::Access::Abuse - Perl extension for avoid access abuse to your web site

=head1 SYNOPSIS

  # /etc/httpd.conf
  Alias /pub/ /var/ftp/pub/
  <Directory /var/ftp/pub/>
     PerlAcessHandler Apache::Access::Abuse
     PerlSetVar AllowFrom "127. 172.16."
     PerlSetVar MaxConnections 1
  </Directory>

=head1 ABSTRACT

Limits the number of simultaneous connections from the same network to your web site.

=head1 DESCRIPTION

Apache::Access::Abuse limits the simultaneous connections from the same network to your web site. All networks are presumed to be Class B.

You can define one or more trusted networks, which have unlimited access, setting the perl var AllowFrom

  PerlSetVar AllowFrom "127. 172.16."

You probably want unlimited access to your loopback interface and your local network.

Apache::Access::Abuse works as follows:

First, it grants access if the connection is comming from your trusted networks.
Second, it ties a hash to a shared memory block named "ApAc", and it pushes a PerlLogHandler.
Later, it denies access if the number of connections from the given network has reached the max number of connections. Otherwise it grants access.
Finaly, when the request reaches the PerlLogHander, it decrements the counter and deletes the hash slice if needed.

=head1 TODO

There is only one shared memory block, so you can't select differens access rules for different directories
or locations in your web server filesystem space.

=head1 AUTHOR

'Aztec Eagle' Turbo, E<lt>turbo@cie.unam.mxE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003. Centro de Investigación en Energía, Universidad Nacional Autónoma de México.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<IPC::Shareable>

=cut
