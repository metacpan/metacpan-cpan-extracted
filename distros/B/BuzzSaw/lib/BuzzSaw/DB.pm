package BuzzSaw::DB; # -*-perl-*-
use strict;
use warnings;

# $Id: DB.pm.in 22945 2013-03-29 10:38:33Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 22945 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/DB.pm.in $
# $Date: 2013-03-29 10:38:33 +0000 (Fri, 29 Mar 2013) $

our $VERSION = '0.12.0';

use English qw(-no_match_vars);
use BuzzSaw::DB::Schema;

use Moose;
use MooseX::Types::Moose qw(Int Maybe Str);

with 'MooseX::Log::Log4perl', 'MooseX::SimpleConfig';

has '+configfile' => (
  default => sub { return '/etc/buzzsaw/db.yaml' },
);

has 'name' => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  default  => 'buzzsaw',
  documentation => 'The name of the database',
);

has 'host' => (
  is        => 'ro',
  isa       => Str,
  predicate => 'has_host',
  documentation => 'The host name of the database server',
);

has 'port' => (
  is        => 'ro',
  isa       => Int,
  predicate => 'has_port',
  documentation => 'The port on which the database server is listening',
);

has 'user' => (
  is        => 'ro',
  isa       => Maybe[Str],
  default   => q{},
  documentation => 'The user name with which to connect to the database',
);

has 'pass' => (
  is        => 'ro',
  isa       => Maybe[Str],
  default   => q{},
  documentation => 'The password with which to connect to the database',
);

has 'schema' => (
  is       => 'ro',
  isa      => 'BuzzSaw::DB::Schema',
  lazy     => 1,
  init_arg => undef,
  builder  => '_connect',
  documentation => 'The DBIx::Class schema object',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub build_dsn {
  my ($self) = @_;

  my $dsn = 'dbi:Pg:dbname=' . $self->name;
  if ( $self->has_host ) {
    $dsn = $dsn . ';host=' . $self->host;
  }
  if ( $self->has_port ) {
    $dsn = $dsn . ';port=' . $self->port;
  }

  return $dsn;
}

sub _connect {
  my ($self) = @_;

  my $dsn  = $self->build_dsn;
  my $user = $self->user;
  my $pass = $self->pass;

  my %attrs = (
    AutoCommit => 1,
    RaiseError => 1
  );

  if ( $self->log->is_debug ) {
    $self->log->debug("Connecting to DB with DSN: $dsn");
  }

  my $schema = BuzzSaw::DB::Schema->connect( $dsn, $user, $pass, \%attrs );

  return $schema;
}

sub begin_transaction {
  my ($self) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug('Beginning transaction');
  }

  return $self->schema->txn_begin;
}

sub end_transaction {
  my ($self) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug('Ending transaction');
  }

  return $self->schema->txn_commit;
}

sub start_processing {
  my ( $self, $logname, $digest, $readall ) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug("Attempting to start processing '$logname'");
  }

  my $schema = $self->schema;

  # Break out the raw SQL for the easiest way to call the registration function

  my $dbh = $schema->storage->dbh();

  my $sql = q{SELECT * FROM register_current_processing(?,?,?)};

  my $sth = $dbh->prepare_cached($sql);

  eval {
    $sth->execute( $logname, $digest, $readall );
    $sth->finish;
  };

  my $result = $EVAL_ERROR ? 0 : 1;

  return $result;
}

sub end_processing {
  my ( $self, $logname ) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug("Ending processing of '$logname'");
  }

  my $schema = $self->schema;
  my $rs = $self->schema->resultset('CurrentProcessing')->search( { name => $logname } );

  eval { $rs->delete() };

  return;
}

sub register_event {
  my ( $self, $event ) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug("Registering new event");
  }

  my $schema = $self->schema;
  my $event_rs = $schema->resultset('Event');
  my $event_source = $event_rs->result_source;

  # Cannot just pass in the event hash as it may contain keys which
  # do not map onto column names.

  # To avoid an error being thrown by the database the values for the
  # following fields must be truncated if they are too long.
  my %truncate = map { $_ => 1 } qw/hostname raw message program userid/;

  my %event_in_db;
  for my $column ( $event_source->columns ) {
    if ( exists $event->{$column} && defined $event->{$column} ) {

      if ( $truncate{$column} ) {
        my $info = $event_source->column_info($column);
        $event->{$column} = substr( $event->{$column}, 0, $info->{size} )
          if length $event->{$column} > $info->{size};
      }

      $event_in_db{$column} = $event->{$column};
    }
  }

  if ( exists $event->{tags} && defined $event->{tags} ) {
    $event_in_db{tags} = [ map {  { name => $_ } } @{ $event->{tags} } ];
  }

  if ( exists $event->{extra_info} && defined $event->{extra_info} ) {
    $event_in_db{extra_info} = [ map {  { name => $_,
                                          val  => $event->{extra_info}{$_} } }
                                 keys %{ $event->{extra_info} } ];
  }

  my $new_event = $event_rs->new( \%event_in_db );
  $new_event->insert;

  return;
}

sub check_event_seen {
  my ( $self, $event ) = @_;

  my $digest = $event->{digest};

  my $schema = $self->schema;
  my $entry_rs = $schema->resultset('Event')->search( { digest => $digest } );
  my $count = $entry_rs->count;

  return $count > 0 ? 1 : 0;
}

sub register_log {
  my ( $self, $logname, $digest ) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug("Registering completion of processing for '$logname'");
  }

  my $schema = $self->schema;

  my $dbh = $schema->storage->dbh();

  my $find_sql   = q{SELECT id FROM log WHERE name = ? AND digest = ?};
  my $create_sql = q{INSERT INTO log (name, digest) VALUES (?,?)};

  my $find_sth = $dbh->prepare_cached($find_sql);
  $find_sth->execute( $logname, $digest );
  my $count = $find_sth->rows;

  $find_sth->finish;

  if ( $count == 0 ) {
    my $create_sth = $dbh->prepare_cached($create_sql);
    $create_sth->execute( $logname, $digest );
    $create_sth->finish;
  }

  return;
}

sub check_log_seen {
  my ( $self, $logname, $digest ) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug("Checking if log '$logname' has been previously seen");
  }

  my $schema = $self->schema;

  my $dbh = $schema->storage->dbh();

  my $sql = q{SELECT id FROM log WHERE name = ? AND digest = ?};

  my $sth = $dbh->prepare_cached($sql);
  $sth->execute( $logname, $digest );
  my $count = $sth->rows;

  $sth->finish;

  return $count > 0 ? 1 : 0;
}

1;
__END__

=head1 NAME

BuzzSaw::DB - The BuzzSaw database interface

=head1 VERSION

This documentation refers to BuzzSaw::DB version 0.12.0

=head1 SYNOPSIS

   use BuzzSaw::DB;

   my $db = BuzzSaw::DB->new( name => "logdb",
                              user => "fred",
                              pass => "letmein" );

   # or use a configuration file:

   my $db = BuzzSaw::DB->new_with_config();

   # Get the DBIx::Class schema:

   my $schema = $db->schema;

=head1 DESCRIPTION


The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

=over

=item configfile

This is the name of the configuration file which contains the settings
for the other attributes for the object. This only has an effect when
a new object is created using the C<new_with_config> method. A number
of file formats are supported (e.g. XML, YAML, JSON, Apache-style,
Windows INI), see the L<Config::Any> documentation for full
details. The default value is C</etc/buzzsaw/db.yaml> which is a YAML
format file.

=item name

This is the name of the database. This attribute MUST be specified,
the default value is C<buzzsaw>.

=item host

This is the host name for the database server. There is no default
value, this attribute is optional.

=item port

This is the number of the port on which the database server is
listening. There is no default value, this attribute is optional.

=item user

This is the name of the user to be used for accessing the
database. There is no default value, this attribute is optional.

=item pass

This is the password for the user to be used for accessing the
database. There is no default value, this attribute is optional.

=item schema

This gives access to the L<DBIx::Class::Schema> object.

=back

=head1 SUBROUTINES/METHODS

This class has the following methods:

=over

=item new()

Create a new instance of this class. Optionally a hash (or reference
to a hash) of attributes and their values can be specified.

=item new_with_config

Create a new instance of this class using the attribute values set in
a configuration file. By default, the C</etc/buzzsaw/db.yaml>
will be loaded, if it exists. The configuration file can be changed
by passing in a value for the C<configfile> attribute.

=item start_processing( $logname, $digest, $readall )

This method takes the name of the log and the computed SHA digest for
the file and attempts to register the start of processing into the
C<currentprocessing> database table. It does this using the
C<register_current_processing> SQL function.

If the log is currently being processed elsewhere then the method will
return false (zero). If it has already been processed and readall is
false then the method will return false (zero). If this is a new log,
or readall is set to true, and the start of processing is successfully
registered then the method will return true (one).

Do not call this method inside a transaction as this might lead to a
long-term lock being taken which blocks any other processes.

=item end_processing($logname)

When the processing of a log is completed this method should be used
to remove the associated entry from the C<currentprocessing> table.

Do not call this method inside a transaction as this might lead to a
long-term lock being taken which blocks any other processes.

=item begin_transaction

This is a simple wrapper to make it easier to start a new
transaction. Internally it calls the C<txn_begin> schema object
method.

=item end_transaction

This is a simple wrapper to make it easier to end a
transaction. Internally it calls the C<txn_commit> schema object
method.

=item register_log( $logname, $digest )

This method is used to register that processing of a log has been
completed. The SHA digest of the file contents is stored so that
processes can avoid reparsing a file that has not changed at some
later date.

=item check_log_seen( $logname, $digest )

This method will check if a log has already been processed based on
the contents of the SHA digest of its contents. It will return true
(one) if it has been previously seen or false (zero) otherwise.

=item register_event($event)

This takes a reference to a hash which contains values for all the
attributes which should be stored in the C<event> table for this log
entry.

The following attributes are required: C<raw>, C<digest>, C<logtime>,
C<hostname>, C<message>. The following attributes are optional:
C<program>, C<pid>, C<userid>. Further to this, a C<tags> entry can be
specified which will result in tags for this event being stored in the
C<tag> table. Values for any other hash keys will be ignored.

Note that the C<logtime> attribute must be a L<DateTime> object, that
will be automatically formatted correctly by L<DBIx::Class>.

=item check_event_seen($event)

This takes a reference to a hash which contains, at the very least, a
C<digest> key which refers to the SHA digest of the complete log
entry. It will return true (one) if it has been previously seen or
false (zero) otherwise.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The BuzzSaw database schema is only known to work with PostgreSQL,
reports of success with other database types (or patches to add the
necessary support) would be very welcome.

=head1 DEPENDENCIES

This module is powered by L<Moose>. You will also need
L<MooseX::Types>, L<MooseX::Log::Log4perl> and
L<MooseX::SimpleConfig>.

This module provides an interface to the BuzzSaw L<DBIx::Class> schema
class. You will also need a DBI driver module such as L<DBD::Pg>.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::DB::Schema>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux6

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2012 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
