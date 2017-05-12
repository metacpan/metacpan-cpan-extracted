#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2003-05-20
# Last Modified: 2003-05-27
# Id:            $Id: oracle.pm 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source$
#
# Transport layer for DBI
#
package Bio::Das::ProServer::SourceAdaptor::Transport::oracle;
use strict;
use warnings;
use base qw(Bio::Das::ProServer::SourceAdaptor::Transport::dbi);

our $VERSION = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

sub dbh {
  my $self     = shift;
  my $dbname   = $self->config->{dbname};
  my $host     = $self->config->{dbhost} || $self->config->{host}; # optional
  my $sid      = $self->config->{dbsid}  || $self->config->{sid};  # optional
  my $port     = $self->config->{dbport} || $self->config->{port}; # optional
  my $username = $self->config->{dbuser} || $self->config->{username};
  my $password = $self->config->{dbpass} || $self->config->{password};
  my $driver   = $self->config->{driver} || 'Oracle';
  my $dsn      = "DBI:$driver:";

  if ($host && $sid) {
    $dsn .= "host=$host;sid=$sid";
    if($port) {
      $dsn .= ";port=$port";
    }
  } else {
    $dsn .= $dbname;
  }

  if(!$self->{dbh} ||
     !$self->{dbh}->ping()) {
    $self->{dbh} = DBI->connect_cached($dsn, $username, $password, {RaiseError => 1});
  }

  return $self->{dbh};
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::Transport::oracle - Oracle/DBI transport layer

=head1 VERSION

$Revision: 687 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 dbh : Oracle database handle

  Overrides Transport::dbi::dbh method

  my $dbh = Bio::Das::ProServer::SourceAdaptor::Transport::oracle->dbh();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
