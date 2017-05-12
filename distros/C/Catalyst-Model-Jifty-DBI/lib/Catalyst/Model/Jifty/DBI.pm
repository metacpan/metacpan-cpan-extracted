package Catalyst::Model::Jifty::DBI;

use strict;
use warnings;
use Carp;
use base qw( Catalyst::Model Class::Accessor::Fast );

our $VERSION = '0.06';

use MRO::Compat;
use mro 'c3';
use Jifty::DBI::Handle;
use Module::Find;

__PACKAGE__->mk_accessors(qw( handles connect_infos schema_base ));

sub new {
  my $self = shift->next::method(@_);

  my $class = ref $self;
  my $model_name = $class;
     $model_name =~ s/^[\w:]+::(?:Model|M):://;

  $self->schema_base($class) unless $self->schema_base;
  $self->connect_infos({});
  $self->handles({});

  # let's see connect_info; we may have several.
  if ( ref $self->{connect_info} eq 'HASH' ) {
    $self->connect_infos->{_} = $self->{connect_info};

    # if we have only one connect_info, then why don't we connect?
    my $handle = Jifty::DBI::Handle->new;
       $handle->connect( %{ $self->{connect_info} } );

    $self->handles->{_} = $handle;
  }
  elsif ( ref $self->{databases} eq 'ARRAY' ) {
    foreach my $database ( @{ $self->{databases} } ) {
      croak "connect_info should be a hash reference"
        unless ref $database->{connect_info} eq 'HASH';

      my $name = $database->{name}
              || $database->{connect_info}->{database};

      croak "database should have a unique name"
        if !$name || $self->connect_infos->{$name};

      $self->connect_infos->{$name} = $database->{connect_info};
    }
    # as we may have multiple connect_info, we should just prepare
    # and wait until we really need to connect.
  }

  no strict 'refs';
  my $schema_base = $self->schema_base;

  # prepare implicit collections before loading any records.
  # so as not for JDBI to fail to create relationships.
  my %collections;
  my @monikers = findsubmod $schema_base;
  foreach my $moniker ( @monikers ) {
    if ( $moniker =~ /Collection$/ ) {
      $collections{$moniker} = 1;
    }
    else {
      $collections{$moniker.'Collection'} = 0;
    }
  }
  foreach my $moniker ( keys %collections ) {
    next if $collections{$moniker};
    # perhaps you're too lazy to create Collection class.
    # now we should try creating default one!
    my $package_body = <<"EOT";
package $moniker;
use strict;
use base qw( Jifty::DBI::Collection );
1;
EOT
      eval $package_body;
      croak "Can't prepare $moniker: $@" if $@;
  }

  foreach my $moniker ( @monikers ) {
    eval "require $moniker" or croak $@;
    next if $moniker =~ /Collection$/;

    $moniker =~ s/^$schema_base\:://;
    *{"${class}::${moniker}::ACCEPT_CONTEXT"} = sub {
      shift;
      shift->model( $model_name )->record( $moniker );
    };

    my $collection_moniker = $moniker.'Collection';
    *{"${class}::${collection_moniker}::ACCEPT_CONTEXT"} = sub {
      shift;
      shift->model( $model_name )->collection( $collection_moniker );
    };
  }
  return $self;
}

sub _select_name {
  my ($self, %options) = @_;

  return $options{name} if $options{name};
  return $options{from} if $options{from};
  return $self->default_handle_name;
}

sub default_handle_name {
  my $self = shift;

  if ( @_ ) {
    my $new_handle = shift;
    unless ( $self->connect_infos->{$new_handle} ) {
      croak "$new_handle doesn't have connect_info";
    }
    $self->{default_handle} = $new_handle;
  }
  unless ( $self->{default_handle} ) {
    $self->{default_handle} = ( $self->databases )[0];
  }
  $self->{default_handle};
}

sub handle {
  my ($self, %options) = @_;

  my $name   = $self->_select_name(%options);
  my $handle = $self->handles->{$name};

  unless ( $handle and $handle->dbh and $handle->dbh->{Active} ) {
    my $connect_info = $self->connect_infos->{$name};
    croak "database $name doesn't have connect_info"
      unless ref $connect_info eq 'HASH';

    $handle = Jifty::DBI::Handle->new;
    $handle->connect( %$connect_info );
    $self->handles->{$name} = $handle;
  }
  $handle;
}

sub disconnect {
  my ($self, %options) = @_;

  my $name   = $self->_select_name(%options);
  my $handle = $self->handles->{$name};

  if ( $handle and $handle->dbh ) {
    $handle->disconnect if $handle->dbh->{Active};
  }
  else {
    carp "database $name doesn't exist or open";
  }
}

sub database {
  my ($self, %options) = @_;

  my $name = $self->_select_name(%options);

  if ( $self->connect_infos->{$name} ) {
    my $database = $self->connect_infos->{$name}->{database};
    return '' if $self->connect_infos->{$name}->{driver} eq 'SQLite'
              && $database eq ':memory:';
    return $database;
  }
  else {
    croak "database $name doesn't exist";
  }
}

sub databases {
  my $self = shift;
  return sort keys %{ $self->connect_infos };
}

sub setup_database {
  my $self = shift;

  my $handle = $self->handle( @_ );

  require Jifty::DBI::SchemaGenerator;
  my $generator = Jifty::DBI::SchemaGenerator->new( $handle );

  foreach my $schema ( findsubmod $self->schema_base ) {
    eval "require $schema" or croak "Can't load $schema: $@";
    $generator->add_model( $schema );
  }
  my @statements = $generator->create_table_sql_statements;
  $handle->begin_transaction;
  $handle->simple_query( $_ ) foreach @statements;
  $handle->commit;
}

sub record {
  my ($self, $moniker, %options) = @_;

  my $handle = $self->handle( %options );

  my $package = $self->schema_base.'::'.$moniker;
     $package->new( handle => $handle );
}

sub collection {
  my ($self, $moniker, %options) = @_;

  my $handle = $self->handle( %options );

  # XXX: this may be double-edged
  $moniker .= 'Collection' unless $moniker =~ /Collection$/;

  my $package = $self->schema_base.'::'.$moniker;
  $package->new( handle => $handle );
}

sub begin_transaction { shift->handle( @_ )->begin_transaction }
sub commit            { shift->handle( @_ )->commit }
sub rollback          { shift->handle( @_ )->rollback }

sub simple_query      { shift->handle->simple_query( @_ ) }
sub fetch_result      { shift->handle->fetch_result( @_ ) }

sub trace {
  my ($self, $code) = @_;

  if ( ref $code eq 'CODE' ) {
    $self->handle->log_sql_statements(1);
    $self->handle->log_sql_hook( trace => $code );
  }
  elsif ( $code ) {
    require Data::Dump;
    $self->handle->log_sql_statements(1);
    $self->handle->log_sql_hook(
      trace => sub { print STDERR Data::Dump::dump(@_) }
    );
  }
  else {
    $self->handle->log_sql_statements(0);
  }
}

1;

__END__

=head1 NAME

Catalyst::Model::Jifty::DBI - Jifty::DBI Model Class with some magic on top

=head1 SYNOPSIS

In your model class:

  package MyApp::Model:
  use strict;
  use base qw( Catalyst::Model::Jifty::DBI );
  __PACKAGE__->config({
      schema_base  => 'MyApp::Schema',
      connect_info => {
          driver   => 'SQLite',
          database => 'myapp.db',
      },
  });
  1;

Or you may want to have multiple databases (for partitioning):

  package MyApp::Model:
  use strict;
  use base qw( Catalyst::Model::Jifty::DBI );
  __PACKAGE__->config({
      schema_base => 'MyApp::Schema',
      databases   => [
          {
              name => 'database1',
              connect_info => {
                  driver   => 'SQLite',
                  database => 'myapp1.db',
              },
          },
          {
              name => 'database2',
              connect_info => {
                  driver   => 'SQLite',
                  database => 'myapp2.db',
              },
          },
      ],
  });
  1;

Then in a controller:

  my $record = $c->model('JDBI::Book');
     $record->load_by_cols( name => 'foo' );

  my $collection = $c->model('JDBI::BookCollection');
     $collection->limit( column => 'name', value => 'bar',
                         operator => 'MATCHES' );

Or, you may want to do more explicitly

  my $record = $c->model('JDBI')->record('Book');
     $record->load_by_cols( name => 'foo' );

  my $collection = $c->model('JDBI')->collection('BookCollection');
     $collection->limit( column => 'name', value => 'bar',
                         operator => 'MATCHES' );

If you want some partitioning:

  my $record_1 = $c->model('JDBI')
                   ->record('Book', from => 'database1');
  my $record_2 = $c->model('JDBI')
                   ->record('Book', from => 'database2');

  my $collection_1 = $c->model('JDBI')
                       ->collection('BookCollection',
                                    from => 'database1');
  my $collection_2 = $c->model('JDBI')
                       ->collection('BookCollection',
                                    from => 'database2');

You can also setup a database:

  my $database = $c->model('JDBI')->database;
  if ( $database && -f $database ) {
    $c->model('JDBI')->disconnect;
    unlink $database;
  }
  $c->model('JDBI')->setup_database;

You want more? or you don't want any more magic?

  my $handle = $c->model('JDBI')->handle;
  my $sth = $handle->simple_query( $sql_statement, @binds );

  # Also you can write like this if you use a default handle:
  my $sth = $c->model('JDBI')
              ->simple_query( $sql_statement, @binds );

When you want to debug (against the default handle):

  $c->model('JDBI')->trace(1);  # start logging
  $c->model('JDBI')->trace(0);  # stop logging

=head1 BACKWARD INCOMPATIBILITY

Current version of Catalyst::Model::Jifty::DBI was once called Catalyst::Model::JDBI::Schemas, which then replaced the original version written by Marcus Ramberg, by the request of Matt S. Trout (Catalyst Core team) to avoid future confusion. I wonder if anyone used the previous one, but note that APIs have been revamped and backward incompatible since 0.03.

=head1 DESCRIPTION

This is a Catalyst model for Jifty::DBI-based schemas, which may or may not be placed under your model class (if you don't want to place them under the model class, pass "schema_base" option to the model).  The model class automatically detect/load your schemas, like Catalyst::Model::DBIC::Schema does.

This model also provides several features for laziness. You don't have to create simple Collection classes (they'll be created on the fly a la Jifty). No more writing schema in other language just to set up databases; C::M::Jifty::DBI takes care of it, on the fly if you want (of course from the perl schemas you prepared; converting raw SQLs to a database to perl schemas is not our way). You may want to use multiple databases of the same schema, or, you may prefer bloody raw SQL statements to complicated object chains. Here you are. Have fun!

=head1 CONFIG

=head2 schema_base

The namespace to look for schema definitions in. All the schemas just below this namespace would be counted.

=head2 connect_info

A hash reference, which would be converted to a hash, then be passed to Jifty::DBI::Handle->new. See L<Jifty::DBI::Handle> for details.

=head2 databases

You may want to use multiple databases (for log rotation, load balancing etc). In this case you can provide multiple "connect_info" hash references under here, as shown in the SYNOPSIS. Actually, above "connect_info" hash reference would be moved in this "databases" array reference internally, with a default name "_" (underscore).

=head1 METHODS

=head2 new

creates a model. Database connection may or may not be prepared, according to the number of connect_info. See above for the configuration.

=head2 record

creates and returns a corresponding (new) Jifty::DBI::Record object. Note that this is just a Record, not a Collection or a RecordSet of DBIC. That means, this object holds one and only single record, and usually you shouldn't reuse this object to let it hold another record. See examples:

  # this works.
  my $record = $c->model('JDBI')->record('Book');
     $record->load_by_cols( id => 1 );
     $record->set_name( 'new name' );  # now inserted/updated

  # this may or may not work as you wish,
  # depending on what you really want to do.
  $c->model('JDBI')->record('Book')->load_by_cols( id => 1 );
  $c->model('JDBI')->record('Book')->set_name( 'new name' );

You can pass an optional hash, as shown in the SYNOPSIS.

  # this tries to fetch a record from a table named 'books'
  # in a database named 'database'.
  my $record = $c->model('JDBI')->record('Book', from => 'database');

You can omit "->record" when you fetch from a default database.

  # both do the same thing
  my $record = $c->model('JDBI')->record('Book');
  my $record = $c->model('JDBI::Book');

=head2 collection

creates and returns a corresponding (new) Jifty::DBI::Collection object. If you haven't created a Collection class but only a Schema/Record class, this model creates a plain Collection class on the fly. I recommend not to omit the obvious 'Collection' part of the class name, but if you prefer, you can spare that when you explicitly call model("Model")->collection("Schema") (you can't omit if you follow the model("Model::Schema") convention). Other general usage and caveats are the same as ->record.

  # this works.
  my $collection = $c->model('JDBI')->collection('BookCollection');
     $collection->unlimit;
     $collection->limit( column => 'name', value => 'bar',
                         operator => 'MATCHES' );

  # this may or may not work as you wish,
  # depending on what you really want to do.
  $c->model('JDBI')->collection('BookCollection')->limit;
  $c->model('JDBI')->collection('BookCollection')->first;

You can pass an optional hash, as shown in the SYNOPSIS.

  # this tries to fetch a collection from a table named 'books'
  # in a database named 'database'.
  my $collection = $c->model('JDBI')
                     ->collection('BookCollection',
                                  from => 'database');

You can omit "->collection" when you fetch from a default database.

  # both do the same thing
  my $collection = $c->model('JDBI')->collection('BookCollection');
  my $collection = $c->model('JDBI::BookCollection');

=head2 simple_query

When you want to do something irrelevant to a specific table, or something too complicated for Jifty::DBI, you can execute arbitrary statements with "simple_query", which is almost equivalent to DBI's $dbh->do or ->prepare. Note that this is supposed to use a default handle. If you want to use other handles, get the handle first with ->handle described below.

  # fetch something from "tables" table,
  # described in "(Your::Schema::)Table" schema/record class.
  my $statement = 'select * from tables where id = ?';
  my $sth = $c->model('JDBI')->simple_query( $statement, 1 );
  return $sth ? $sth->fetchrow : undef;

  # Above is equivalent to:
  my $handle = $c->model('JDBI')->handle;
  my $sth = $handle->simple_query( $statement, 1 );
  return $sth ? $sth->fetchrow : undef;

=head2 fetch_result

This is a lazier shortcut to realize the example just shown above.

  my $statement = 'select * from tables where id = ?';
  my $row = $c->model('JDBI')->fetch_result( $statement, 1 );

=head2 handle

C::M::Jifty::DBI may have multiple JDBI handles. You can choose one you want to use like this:

  my $handle = $c->model('JDBI')->handle( name => 'sample.db' );

You can use "from" instead of "name". Also, you can use an alias to the real database name (connect_info->{database}) if you set "name" option in the config.

  my $handle = $c->model('JDBI')->handle( from => 'alias' );

By default, this returns a default handle.

=head2 default_handle_name

returns (or sets) a default handle/database name.

=head2 databases

returns all the database names/aliases registered in the config.

  # See if all the registered SQLite databases have been set up.
  foreach my $name ( $c->model('JDBI')->databases ) {
    my $dbfile = $c->model('JDBI')->database( name => $name );
    warn "database $db does not exist" unless -f $dbfile;
    warn "database $db is blank" unless -s $dbfile;
  }

=head2 database

returns a database name (or an actual path to the database for SQLite). See above for an example. You can pass an optional hash to specify database alias explicitly.

  $c->model('JDBI')->database( name => 'alias' );

As of 0.06, this returns a blank string if the driver is SQLite and the atabase is ":memory:", which means the whole database is on the memory, and there's no real file to operate.

=head2 setup_database

You can set up database on the fly with your perl schema. You can pass an optional hash to specify target database.

  $c->model('JDBI')->setup_database( name => 'database' );

=head2 begin_transaction

=head2 commit

=head2 rollback

These three are shortcuts to ->handle->(method_name). You can pass an optional hash to specify target database.

=head2 disconnect

This also is a shortcut to ->handle->disconnect. You can pass an optional hash to specify target database.

=head2 trace

turns on and off the logging of sql statements. If this is set to true, C::M::Jifty::DBI spits the info to STDERR. If you want finer control, give it a code reference.

  $c->model('JDBI')->trace(sub {
    my ($time, $statement, $binding, $duration, $result) = @_;
    warn $statement, "\n", @$binding;
  });

See L<Jifty::DBI::Handle> for details (log_sql_hook / sql_statement_log).

=head1 SEE ALSO

L<Jifty::DBI>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

original version is written by Marcus Ramberg, E<lt>mramberg@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
