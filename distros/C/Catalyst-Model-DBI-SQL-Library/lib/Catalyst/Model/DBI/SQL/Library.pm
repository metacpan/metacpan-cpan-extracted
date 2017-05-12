package Catalyst::Model::DBI::SQL::Library;

use strict;
use base 'Catalyst::Model::DBI';

use NEXT;
use SQL::Library;
use File::Spec;

use constant DEFAULT_ROOT_PATH => 'root/sql';

our $VERSION = '0.19';

__PACKAGE__->mk_accessors('sql');

=head1 NAME

Catalyst::Model::DBI::SQL::Library - SQL::Library DBI Model Class

=head1 SYNOPSIS

  # use the helper
  create model DBI::SQL::Library DBI::SQL::Library dsn user password

  # lib/MyApp/Model/DBI/SQL/Library.pm
  package MyApp::Model::DBI::SQL::Library;

  use base 'Catalyst::Model::DBI::SQL::Library';

  # define configuration in package
  
  __PACKAGE__->config(
    dsn => 'dbi:Pg:dbname=myapp',
    username => 'postgres',
    password => '',
    options => { AutoCommit => 1 },
    sqldir => 'root/sql2' #optional, will default to $c->path_to( 'root/sql' ),
    sqlcache => 1 #can only be used when queries are loaded from file i.e. via scalar passed to load
    sqlcache_use_mtime => 1 #will use modification time of the file to determine when to refresh the cache, make sure sqlcache = 1
    loglevel = 1 #integer value to control log notifications between 1 and 3 with 3 being the most verbose, defaults to 1
  );

  1;
  
  # or define configuration in myapp.conf
  
  name MyApp

  <Model::DBI::SQL::Library>
    dsn "DBI:Pg:dbname=myapp"
    username pgsql
    password ""
    <options>
      AutoCommit 1
    </options>
    loglevel 1
    sqlcache 1
    sqlcache_use_mtime 1
  </Model>

  # then in controller / model code

  my $model = $c->model( 'DBI::SQL::Library' );
  
  my $sql = $model->load( 'something.sql' ) ;

  #or my $sql = $model->load( [ <FH> ] );
  #or my $sql = $model->load( [ $sql_query1, $sql_query2 ] ) )

  my $query = $sql->retr( 'some_sql_query' );

  #or my $query = $model->sql->retr( 'some_sql_query );

  $model->dbh->do( $query );

  #do something else with $sql ...
	
=head1 DESCRIPTION

This is the C<SQL::Library> model class. It provides access to C<SQL::Library>
via sql accessor. Additional caching options are provided for increased performance
via sqlcache and sqlcache_use_mtime, these options can only be used when sql strings are
stored within a file and loaded by using a scalar value passed to load. The load and parse
phase is then bypassed if cached version of the file is found.

The use of these options can result in more memory being used but faster access to query
data when running under persistent environment such as mod_perl or FastCGI. When sqlcache_use_mtime
is in use, last modification time of the file is being referenced upon every cache check.
If the modification time has changed only then query file is re-loaded. This should be much faster then
re-creating the SQL::Library instance on every load. Please refer to the C<SQL::Library> for more information.

=head1 METHODS

=over 4

=item new

Initializes database connection

=cut 

sub new {
  my ( $self, $c, @args ) = @_;
  $self = $self->NEXT::new( $c, @args );
  $self->{sqldir} ||= $c->path_to( DEFAULT_ROOT_PATH );
  return $self;
}

=item $self->load

Initializes C<SQL::Library> instance

=cut

sub load {
  my ( $self, $source ) = @_;
  $source = File::Spec->catfile( $self->{sqldir}, $source ) unless ref $source eq 'ARRAY';
  
  my $log = $self->{log};
  my $debug = $self->{debug};
  my $loglevel = $self->{loglevel};
  
  if ( ref $source ne 'ARRAY' && $self->{sqlcache} && exists $self->{obj_cache}->{$source} ) {
    my $source_cached = $self->{obj_cache}->{$source};
    if ( $self->{sqlcache_use_mtime} && exists $source_cached->{mtime} ) {
      my $mtime_current = $self->_extract_mtime( $source );
      if ( $mtime_current != $source_cached->{mtime} ) {
        $log->debug(
          qq/mtime changed for cached SQL::Library instance with path: "$source", reloading/
        ) if $debug && $loglevel >= $self->LOG_LEVEL_INTERMEDIATE;
        $self->_load_instance( $source );
      } else {
        $self->sql( $source_cached->{sql} );
        $log->debug(
          qq/cached SQL::Library instance with path: "$source" and mtime: "$mtime_current" found/
        ) if $debug && $loglevel == $self->LOG_LEVEL_FULL;
      }
    } else {
      $self->sql( $source_cached->{sql} );
      $log->debug(
        qq/cached SQL::Library instance with path: "$source" found/
      ) if $debug && $loglevel == $self->LOG_LEVEL_FULL;
    }
  } else {
    $self->_load_instance( $source );
  }
  return $self->sql;
}

sub _load_instance {
  my ( $self, $source ) = @_;
  
  my $log = $self->{log};
  my $debug = $self->{debug};
  my $loglevel = $self->{loglevel};
  
  eval { $self->sql( SQL::Library->new( { lib => $source } ) ); };
  if ( $@ ) {
    $log->debug(
      qq/couldn't create SQL::Library instance with path: "$source" error: "$@"/
    ) if $debug && $loglevel >= $self->LOG_LEVEL_BASIC;
  } else {
    $log->debug(
      qq/SQL::Library instance created with path: "$source"/
    ) if $debug && $loglevel >= $self->LOG_LEVEL_BASIC;
    if ( $self->{sqlcache} && ref $source ne 'ARRAY' ) {
      if ( $self->{sqlcache_use_mtime} ) {
        my $mtime = $self->_extract_mtime( $source );
        $self->{obj_cache}->{$source} = {
          sql => $self->sql,
          mtime => $mtime
        }; 
        $log->debug(
          qq/caching SQL::Library instance with path: "$source" and mtime: "$mtime"/
        ) if $debug && $loglevel >= $self->LOG_LEVEL_INTERMEDIATE;
      } else {
        $self->{obj_cache}->{$source} = { sql => $self->sql };
        $log->debug(
          qq/caching SQL::Library instance with path: "$source"/
        ) if $debug && $loglevel >= $self->LOG_LEVEL_INTERMEDIATE;
      }
    }
  }
}

sub _extract_mtime {
  my ( $self, $source ) = @_;
  
  my $mtime;
  if (-r $source) {
    $mtime = return (stat(_))[9];
  } else {
    $self->{log}->debug(
      qq/couldn't extract modification time for path: "$source"/
    ) if $self->{debug} && $self->{loglevel} >= $self->LOG_LEVEL_BASIC;
  }
  return $mtime;
}

=item $self->dbh

Returns the current database handle.

=item $self->sql

Returns the current C<SQL::Library> instance

=back

=head1 SEE ALSO

L<Catalyst>, L<DBI>

=head1 AUTHOR

Alex Pavlovic, C<alex.pavlovic@taskforce-1.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
