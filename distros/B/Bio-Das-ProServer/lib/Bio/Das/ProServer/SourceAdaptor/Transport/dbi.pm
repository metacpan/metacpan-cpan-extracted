#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2003-05-20
# Last Modified: $Date: 2010-11-02 11:57:52 +0000 (Tue, 02 Nov 2010) $
# Id:            $Id: dbi.pm 688 2010-11-02 11:57:52Z zerojinx $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/Transport/dbi.pm $
#
# Transport layer for DBI
#
package Bio::Das::ProServer::SourceAdaptor::Transport::dbi;
use strict;
use warnings;
use base qw(Bio::Das::ProServer::SourceAdaptor::Transport::generic);
use DBI;
use Carp;
use English qw(-no_match_vars);
use Readonly;

our $VERSION = do { my ($v) = (q$Revision: 688 $ =~ /\d+/mxsg); $v; };
Readonly::Scalar our $CACHE_TIMEOUT => 30;
Readonly::Scalar our $QUERY_TIMEOUT => 30;

sub dbh {
  my $self     = shift;
  my $config   = $self->config();
  my $host     = $config->{dbhost}  || $config->{host}     || 'localhost';
  my $port     = $config->{dbport}  || $config->{port}     || '3306';
  my $dbname   = $config->{dbname};
  my $username = $config->{dbuser}  || $config->{username} || 'test';
  my $password = $config->{dbpass}  || $config->{password} || q();
  my $driver   = $config->{driver}  || 'mysql';
  my $dsn      = "DBI:$driver:database=$dbname;host=$host;port=$port";

  #########
  # DBI connect_cached is slightly smarter than us just caching here
  #
  eval {
    if (!$self->{dbh} || !$self->{dbh}->ping()) {
      $self->{dbh} = DBI->connect_cached($dsn, $username, $password, {RaiseError => 1});
    }
    1;

  } or do {
    croak "$dsn = $self->{dsn}\n$EVAL_ERROR";
  };

  return $self->{dbh};
}

sub query {
  my ($self,
      $query,
      @args)       = @_;
  my $ref          = [];
  my $debug        = $self->{debug};
  my $fetchall_arg = {};
  (@args and ref $args[0]) and $fetchall_arg = shift @args;

  local $SIG{ALRM} = sub { croak 'timeout'; };
  alarm $QUERY_TIMEOUT;
  eval {
    $debug and carp "Preparing query...\n";
    my $sth;
    if($query =~ /\?/mxs) {
      $sth = $self->dbh->prepare_cached($query);
    } else {
      $sth = $self->dbh->prepare($query);
    }

    $debug and carp "Executing query...\n";
    $sth->execute(@args);
    $debug and carp "Fetching results...\n";
    $ref    = $sth->fetchall_arrayref($fetchall_arg);
    $debug and carp "Finishing...\n";
    $sth->finish();
    alarm 0;
    1;

  } or do {
    alarm 0;
    croak "Error running query: $EVAL_ERROR\nArgs were: @{[join q( ), @_]}\n";
  };

  return $ref;
}

sub prepare {
  my ($self, @args) = @_;
  return $self->dbh->prepare(@args);
}

sub disconnect {
  my $self = shift;

  if(!exists $self->{dbh} || !$self->{dbh}) {
    return;
  }

  $self->{dbh}->disconnect();
  delete $self->{dbh};
  $self->{debug} and carp "$self performed dbh disconnect\n";
  return;
}

sub last_modified {
  my $self = shift;

  if($self->dbh->{Driver}->{Name} ne 'mysql') {
    return;
  }

  my $now      = time;
  #########
  # flush the timestamp cache *at most* once every $CACHE_TIMEOUT
  # This may need signal triggering to have immediate support
  #
  if($now > ($self->{'_lastmodified_timestamp'} || 0)+$CACHE_TIMEOUT) {
    $self->{'debug'} and carp qq(Flushing last-modified cache for $self->{'dsn'});
    $self->{'_lastmodified_timestamp'} = $now;
    my $server_text = [sort { $b cmp $a } ## no critic
                     map { $_->{Update_time}||0 }
                     @{ $self->query(q(SHOW TABLE STATUS),{Update_time=>1}) }
                    ]->[0]; # server local time
    my $server_unix = $self->query(q(SELECT UNIX_TIMESTAMP(?) as 'unix'), $server_text)->[0]{unix}; # sec since epoch
    $self->{'_lastmodified'} = $server_unix;
  }

  return $self->{'_lastmodified'};
}

sub DESTROY {
  my $self = shift;
  return $self->disconnect();
}

1;

__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::Transport::dbi - A DBI transport layer (actually customised for MySQL)

=head1 VERSION

$Revision: 688 $

=head1 SYNOPSIS

=head1 DESCRIPTION

Transport helper class for database access, acting as a wrapper for DBI.

=head1 SUBROUTINES/METHODS

=head2 dbh - Database handle (mysqlish by default)

  my $dbh = Bio::Das::ProServer::SourceAdaptor::Transport::dbi->dbh();

=head2 query - Execute a given query with given args

  my $arrayref = $dbitransport->query(qq(SELECT ... WHERE x = ? AND y = ?),
				      $x,
				      $y);

=head2 prepare - DBI pass-through of 'prepare'

  my $sth = $dbitransport->prepare($query);

=head2 disconnect - DBI pass-through of disconnect

  $dbitransport->disconnect();

=head2 last_modified - machine time of last data change

  Only knows how to do this for MySQL databases.

  $dbitransport->last_modified();

  This method is only implemented for mysql databases.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

  [mysource]
  transport      = dbi
  driver         = dbdmodule (default: mysql)
  dbhost         = myserver  (default: localhost)
  dbport         = myport    (default: 3306)
  dbuser         = me        (default: test)
  dbpass         = password
  dbname         = mydb
  autodisconnect = yes|no|#

=head1 DEPENDENCIES

=over

=item L<Bio::Das::ProServer::SourceAdaptor::Transport::generic|Bio::Das::ProServer::SourceAdaptor::Transport::generic>

=item L<DBI|DBI>

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
