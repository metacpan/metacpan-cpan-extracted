#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-05-20
# Last Modified: 2003-05-27
# Pulls features over SRS socket-server
#
package Bio::Das::ProServer::SourceAdaptor::Transport::getzc;

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use strict;
use Bio::Das::ProServer::SourceAdaptor::Transport::generic;
use vars qw(@ISA);
@ISA = qw(Bio::Das::ProServer::SourceAdaptor::Transport::generic);
use IO::Socket;

sub query {
  my $self  = shift;
  my $sockh = IO::Socket::INET->new(
				    PeerAddr => $self->config->{'host'},
				    PeerPort => $self->config->{'port'},
 				    Type     => SOCK_STREAM,
				    Proto    => 'tcp',
				   ) or die "Socket could not be opened: $!\n";
  
  $sockh->autoflush(1);
  
  print $sockh join('___', @_) . "\n"; 
  
  local $/ = undef;

  my $result;
  $SIG{ALRM} = sub { die "timeout" };
  alarm(10);
  eval {
    $result = <$sockh>;
  };
  alarm(0);
  return $result || "";
}

1;
