#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2006-10-31
# Last Modified: $Date: 2015-09-21 10:19:13 +0100 (Mon, 21 Sep 2015) $
# Id:            $Id: mysql.pm 470 2015-09-21 09:19:13Z zerojinx $
# Source:        $Source$
# $HeadURL: svn+ssh://zerojinx@svn.code.sf.net/p/clearpress/code/trunk/lib/ClearPress/driver/mysql.pm $
#
package ClearPress::driver::mysql;
use strict;
use warnings;
use base qw(ClearPress::driver);
use English qw(-no_match_vars);
use Carp;
use Readonly;

our $VERSION = q[475.3.3];

Readonly::Scalar our $TYPES => {
				'primary key' => 'bigint unsigned not null auto_increment primary key',
			       };
sub dbh {
  my $self = shift;

  if($self->{dbh} && !$self->{dbh}->ping()) {
    $self->{dbh}->disconnect();
    delete $self->{dbh};
  }

  if(!$self->{dbh}) {
    my $dsn = sprintf q(DBI:mysql:database=%s;host=%s;port=%s),
		      $self->{dbname} || q[],
		      $self->{dbhost} || q[localhost],
		      $self->{dbport} || q[3306];

    eval {
      $self->{dbh} = DBI->connect($dsn,
				  $self->{dbuser} || q[],
				  $self->{dbpass},
				  {
				   RaiseError => 1,
				   AutoCommit => 0,
				   mysql_enable_utf8 => 1,
				  });

      # 2010-05-12 post-connect SET NAMES utf8 demonstrated to work a lot better than connect with mysql_enable_utf8 => 1
      #
      # Using test data: update run set payload='{"comment":"abc øéü"}' where id_run=2;
      #
      # this works on OSX MacPorts MySQL 5.1 but not on CentOS 5.4 MySQL 5.0
      # perl -MDBI -e 'my $dbh  = DBI->connect("DBI:mysql:host=localhost;dbname=ontrackt", "root", "", {RaiseError=>1});$dbh->do(q[update run set payload=? where id_run=2],{},q[abc øéµ]);print $dbh->selectall_arrayref(q[SELECT payload FROM run WHERE id_run=2])->[0]->[0],"\n";'
      #
      # this works on OSX and CentOS:
      # perl -MDBI -e 'my $dbh  = DBI->connect("DBI:mysql:host=localhost;dbname=ontrackt", "root", "", {RaiseError=>1});$dbh->do(q[SET NAMES utf8]);$dbh->do(q[update run set payload=? where id_run=2],{},q[abc øéµ]);print $dbh->selectall_arrayref(q[SELECT payload FROM run WHERE id_run=2])->[0]->[0],"\n";'
      #
      # this works on neither OSX nor CentOS
      # perl -MDBI -e 'my $dbh  = DBI->connect("DBI:mysql:host=localhost;dbname=ontrackt", "root", "", {RaiseError=>1,mysql_enable_utf8 =>1});$dbh->do(q[update run set payload=? where id_run=2],{},q[abc øéµ]);print $dbh->selectall_arrayref(q[SELECT payload FROM run WHERE id_run=2])->[0]->[0],"\n";'

      $self->{dbh}->do(q[SET NAMES utf8]);

    } or do {
      croak qq[Failed to connect to $dsn using @{[$self->{dbuser}||q['']]}\n$EVAL_ERROR];
    };

    #########
    # rollback any junk left behind if this is a cached handle
    #
    $self->{dbh}->rollback();
  }

  return $self->{dbh};
}

sub create {
  my ($self, $query, @args) = @_;
  my $dbh = $self->dbh();

  $dbh->do($query, {}, @args);
  my $idref = $dbh->selectall_arrayref('SELECT LAST_INSERT_ID()');

  return $idref->[0]->[0];
}

sub create_table {
  my ($self, $table_name, $ref) = @_;
  return $self->SUPER::create_table($table_name, $ref, { engine=>'InnoDB'});
}

sub types {
  return $TYPES;
}

sub bounded_select {
  my ($self, $query, $len, $start) = @_;

  if(defined $start && defined $len) {
    $query .= qq[ LIMIT $start, $len];
  } elsif(defined $len) {
    $query .= qq[ LIMIT $len];
  }

  return $query;
}

sub sth_has_warnings {
  my ($self, $sth) = @_;

  if($sth->{mysql_warning_count}) {
    return $self->{dbh}->selectall_arrayref(q[SHOW WARNINGS]);
  }

  return;
}


1;
__END__

=head1 NAME

ClearPress::driver::mysql - MySQL-specific implementation of the database abstraction layer

=head1 VERSION

$LastChangedRevision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 dbh - fetch a connected database handle

  my $oDBH = $oDriver->dbh();

=head2 create - run a create query and return this objects primary key

  my $iAssignedId = $oDriver->create($query)

=head2 create_table - mysql-specific create_table

=head2 types - the whole type map

=head2 bounded_select - select limited by number of rows and first-row position

  my $bounded_select = $driver->bounded_select($unbounded_select, $rows, $start_row);

=head2 sth_has_warnings - arrayref of warning messages from a statement handle, if present

  my $warnings = $driver->sth_has_warnings($sth);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item ClearPress::driver

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
