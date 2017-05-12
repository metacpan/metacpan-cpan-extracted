#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-05-20
# Last Modified: 2003-05-27
# Transport layer for DBI
#
package Bio::Das::ProServer::SourceAdaptor::Transport::oracle;

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use strict;
use Bio::Das::ProServer::SourceAdaptor::Transport::dbi;
use vars qw(@ISA);
@ISA = qw(Bio::Das::ProServer::SourceAdaptor::Transport::dbi);
use DBI;

sub dbh {
  my $self     = shift;
  my $dbname   = $self->config->{'dbname'};
  my $username = $self->config->{'username'};
  my $password = $self->config->{'password'};
  my $driver   = $self->config->{'driver'}   || "Oracle";
  my $dsn      = qq(DBI:$driver:);
  my $userstring = $username . "\@" . $dbname;
  $self->{'dbh'} ||= DBI->connect($dsn, $userstring, $password, {RaiseError => 1});
  return $self->{'dbh'};
}

1;
