package Catalyst::Model::DBI;

use strict;
use base 'Catalyst::Model';

use MRO::Compat;
use mro 'c3';
use DBIx::Connector;

use constant LOG_LEVEL_BASIC => 1;
use constant LOG_LEVEL_INTERMEDIATE => 2;
use constant LOG_LEVEL_FULL => 3;

our $VERSION = '0.32';

__PACKAGE__->mk_accessors( qw/_connection _dbh/ );

=head1 NAME

Catalyst::Model::DBI - DBI Model Class

=head1 SYNOPSIS

  # use the helper to create a model for example
  perl script/myapp_create.pl model MyModel DBI dsn username password

  # lib/MyApp/Model/DBI.pm
  package MyApp::Model::DBI;

  use base 'Catalyst::Model::DBI';

  __PACKAGE__->config(
    dsn           => 'DBI:Pg:dbname=mydb;host=localhost',
    username      => 'pgsql',
    password      => '',
    options       => { AutoCommit => 1 },
    loglevel      => 1
  );

  1;

  # or load settings from a config file via Config::General for example
  # in your myapp.conf you could have

  name MyApp

  <Model::MyModel>
    dsn "DBI:Pg:dbname=mydb;host=localhost"
    username pgsql
    password ""
    <options>
      AutoCommit 1
    </options>
    loglevel 1
  </Model>

  # note that config settings always override Model settings

  # do something with $dbh inside a controller ...
  my $dbh = $c->model('MyModel')->dbh;

  # do something with $dbh inside a model ...
  my $dbh = $self->dbh;

  #do something with DBIx::Connector connection inside a controller ...
  my $connection = $c->model('MyModel')->connection;

  #do something with DBIx::Connector connection inside a model ...
  my $connection = $self->connection;

=head1 DESCRIPTION

This is the C<DBI> model class. It has been rewritten to use L<DBIx::Connector> since it's internal code
that deals with connection maintenance has already been ported into there. You now have two options for 
doing custom models with Catalyst. Either by using this model and any related modules as needed
or by having your custom model decoupled from Catalyst and glued on using L<Catalyst::Model::Adaptor> 

Some general rules are as follows. If you do not wish to use L<DBIx::Connector> directly or DBI and setup 
connections in your custom models or have glue models, then use this model. If you however need models that 
can be re-used outside of your application or simply wish to maintain connection code yourself outside of
the Catalyst, then use L<Catalyst::Model::Adaptor> which allows you to glue outside models into your Catalyst app.

=head1 METHODS

=over 4

=item new

Initializes DBI connection

=cut

sub new {
  my $self = shift->next::method( @_ );
  my ( $c, $config ) = @_;

  $self->{dsn} ||= $config->{dsn};
  $self->{username} ||= $config->{username} || $config->{user};
  $self->{password} ||= $config->{password} || $config->{pass};
  $self->{options} ||= $config->{options};

  $self->{namespace} ||= ref $self;
  $self->{additional_base_classes} ||= ();
  $self->{log} = $c->log;
  $self->{debug} = $c->debug;
  $self->{loglevel} ||= LOG_LEVEL_BASIC;
  
  return $self;
}

=item $self->connection

Returns the current DBIx::Connector connection handle.

=cut

sub connection {
  return shift->connect( 0 ) ;
}

=item $self->dbh

Returns the current database handle.

=cut

sub dbh {
  return shift->connect( 1 );
}

=item $self->connect

Connects to the database and returns the handle.

=cut

sub connect {
  my ( $self, $want_dbh ) = @_;

  my $connection = $self->_connection;
  my $dbh = $self->_dbh;

  my $log = $self->{log};
  my $debug = $self->{debug};
  my $loglevel = $self->{loglevel};
  
  unless ( $connection ) {
    eval {
      $connection = DBIx::Connector->new(
        $self->{dsn},
        $self->{username} || $self->{user},
        $self->{password} || $self->{pass},
        $self->{options}
      );
      $dbh = $connection->dbh;
      $self->_dbh( $dbh );
      $self->_connection( $connection );
    };

    if ($@) {
      $log->debug(
        qq/Couldn't connect to the database via DBIx::Connector "$@"/
      ) if $debug && $loglevel >= LOG_LEVEL_BASIC;
    } else {
      $log->debug(
        'Connected to the database using DBIx::Connector via dsn:' . $self->{dsn}
      ) if $debug && $loglevel >= LOG_LEVEL_BASIC;
    }
  }

  my $handle = $want_dbh ? $dbh : $connection;
  return $handle;
}

=back

=head1 SEE ALSO

L<Catalyst>, L<DBI>, L<Catalyst::Model::Proxy>, L<Catalyst::Model::DBI::SQL::Library>

=head1 AUTHOR

Alex Pavlovic, C<alex.pavlovic@taskforce-1.com>

=head1 COPYRIGHT

Copyright (c) 2005 - 2012
the Catalyst::Model::DBI L</AUTHOR>
as listed above.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
