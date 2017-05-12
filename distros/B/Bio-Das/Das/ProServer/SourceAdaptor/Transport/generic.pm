#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-06-13
# Last Modified: 2003-06-13
# generic transport layer
#
package Bio::Das::ProServer::SourceAdaptor::Transport::generic;

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use strict;

sub new {
  my ($class, $defs) = @_;
  my $self = {
	      'dsn'    => $defs->{'dsn'}    || "unknown",
              'config' => $defs->{'config'} || {},
             };
  bless $self, $class;

  $self->init() if ($self->can("init"));

  return $self;
}

sub config {
  my $self = shift;
  return $self->{'config'};
}

sub query {
  warn qq(Unimplemented Bio::Das::ProServer::SourceAdaptor::Transport::query\n);
}

1;
