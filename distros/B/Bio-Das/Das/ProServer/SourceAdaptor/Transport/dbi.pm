#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-05-20
# Last Modified: 2003-05-27
# Transport layer for DBI
#
package Bio::Das::ProServer::SourceAdaptor::Transport::dbi;

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
use DBI;

sub dbh {
  my $self     = shift;
  my $host     = $self->config->{'host'}     || "localhost";
  my $port     = $self->config->{'port'}     || "3306";
  my $dbname   = $self->config->{'dbname'};
  my $username = $self->config->{'username'} || "test";
  my $password = $self->config->{'password'} || "";
  my $driver   = $self->config->{'driver'}   || "mysql";
  my $dsn      = qq(DBI:$driver:database=$dbname;host=$host;port=$port);

  #########
  # DBI connect_cached is slightly smarter than us just caching here
  #
  eval {
    $self->{'dbh'} = DBI->connect_cached($dsn, $username, $password, {RaiseError => 1});
#  $self->{'dbh'} ||= DBI->connect($dsn, $username, $password, {RaiseError => 1});
  };
  if($@) {
    print STDERR "dsn = ", $self->{'dsn'},"\n";
    die $@;
  }
  return $self->{'dbh'};
}

sub query {
  my $self    = shift;
  my $ref     = [];
  my $retries = 5;

  while($retries > 0) {
    eval {
      my $sth  = $self->dbh->prepare(@_);
      $sth->execute();
      $ref  = $sth->fetchall_arrayref({});
      $sth->finish();
    };
    if($@) {
      warn $@;
      $retries --;

    } else {
      last;
    }
  }
  return $ref;
}

sub prepare {
  my $self = shift;
  return $self->dbh->prepare(@_);
}

1;
