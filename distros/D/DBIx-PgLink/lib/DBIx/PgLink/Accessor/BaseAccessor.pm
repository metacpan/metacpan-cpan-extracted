package DBIx::PgLink::Accessor::BaseAccessor;

# NOTE: accessor must be able to construct itself from local metadata 
#       even if remote connection is broken

use Carp;
use Moose;
use MooseX::Method;
use DBIx::PgLink::Local;
use DBIx::PgLink::Logger;

extends 'Moose::Object';

has 'connector' => (
  is  => 'ro',
  isa => 'DBIx::PgLink::Connector',
  required => 1,
  weak_ref => 1,
);

has 'building_mode' => (is=>'rw', isa=>'Bool', default=>0 );

has 'object_id' => ( 
  is       => 'ro', 
  isa      => 'Int', 
  required => 1,
  lazy     => 1,
  default  => sub { 
    my $self = shift;
    if ($self->building_mode) {
      return pg_dbh->selectrow_array(q/SELECT pg_catalog.nextval('dbix_pglink.object_id_sequence'::regclass)/);
    } else {
      confess 'Accessor metadata not loaded yet';
    }
  }
);

# class method
sub metadata_table { 'dbix_pglink.objects' }
sub metadata_table_attr { {} } # attr for pg_dbh->prepare

# shortcuts
sub adapter {
  (shift)->connector->adapter;
}

sub conn_name {
  (shift)->connector->conn_name;
}

# utility

sub perl_quote {
  my ($self, $str) = @_;
  $str =~ s/\\/\\\\/g;
  $str =~ s/'/\\'/g;
  return "'$str'";
};

sub abstract { confess "Abstract method called" }


# identifier quoting shortcuts

sub QRI { # quote remote identifier
  my $self = shift;
  return $self->adapter->quote_identifier(@_); 
}

sub QRIS { # quote remote identifier with schema (and catalog)
  my ($self, $name) = @_;
  if ($self->adapter->include_catalog_to_qualified_name) {
    return $self->adapter->quote_identifier($self->remote_catalog, $self->remote_schema, $name);
  } elsif ($self->adapter->include_schema_to_qualified_name) {
    return $self->adapter->quote_identifier($self->remote_schema, $name);
  } else {
    return $self->adapter->quote_identifier($name);
  }
}

sub QLI { # quote local identifier
  my $self = shift;
  return pg_dbh->quote_identifier(@_); 
}

sub QLIS { # quote local identifier with schema 
  my ($self, $name) = @_;
  return pg_dbh->quote_identifier($self->local_schema, $name);
}


# NAMES

has 'remote_object_type'  => (is=>'ro', isa=>'Str', required=>1);
has 'remote_catalog'      => (is=>'ro', isa=>'StrNull', required=>0);
has 'remote_schema'       => (is=>'ro', isa=>'StrNull', required=>0);
has 'remote_object'       => (is=>'ro', isa=>'Str', required=>1);

has 'local_schema'        => (is=>'ro', isa=>'Str', required=>1);
has 'local_object'        => (is=>'ro', isa=>'Str', required=>1);

# full qualified, double-quoted name
has 'local_schema_quoted'   => (is=>'rw', isa=>'Str', lazy=>1, default=>sub{ $_[0]->QLI($_[0]->local_schema) } );
has 'local_object_quoted'   => (is=>'rw', isa=>'Str', lazy=>1, default=>sub{ $_[0]->QLIS($_[0]->local_object) } );
has 'remote_object_quoted'  => (is=>'rw', isa=>'Str', lazy=>1, default=>sub{ $_[0]->QRIS($_[0]->remote_object) } );


has 'old_accessor' => (is=>'rw', isa=>'DBIx::PgLink::Accessor::BaseAccessor');

has 'skip_on_errors' => (is=>'ro', isa=>'ArrayRef', auto_deref=>1,
  default=>sub{ ['cannot drop .* because other objects depend on it']} 
);

# -------------------------------------------------------


method build => named (
  use_local_metadata  => { isa => 'Bool', default=> 0 },
) => sub {
  my ($self, $p) = @_;

  $self->building_mode(1);

  trace_msg('INFO', "Building accessor for " . $self->remote_object_type . " " . $self->remote_object_quoted)
    if trace_level >= 1;

  my $savepoint_name = 'build_' . $self->object_id; # unique
  pg_dbh->do("SAVEPOINT $savepoint_name");
  eval {

    $self->load_old_accessor;

    unless ($p->{use_local_metadata}) {
      $self->create_metadata;
      
      $self->delete_metadata_by_id( $self->old_accessor->object_id ) if $self->old_accessor;

      $self->save_metadata;
    }

    $self->create_local_schema;

    $self->old_accessor->drop_local_objects if $self->old_accessor;

    $self->create_local_objects;

  };
  if ($@) {
    my $err = $@;
    for my $skip ($self->skip_on_errors) {
      if ($err =~ /$skip/) {
        # do not raise exception, issue warning and skip this object
        pg_dbh->do("ROLLBACK TO SAVEPOINT $savepoint_name");
        trace_msg('WARNING', "Cannot create accessor for " 
          . $self->remote_object_type . " " . $self->remote_object_quoted
         . ". Error: " . $err);
        return 0;
      }
    }
    die $@;
  }
  pg_dbh->do("RELEASE SAVEPOINT $savepoint_name");

  return 1;
};


sub create_metadata { abstract() }
sub drop_local_objects { abstract() }
sub create_local_objects { abstract() }


sub load_old_accessor {
  my $self = shift;

  # load metadata for previous version of same remote object
  my $old_meta = $self->load_metadata_by_remote_name;
  $self->old_accessor( 
    $old_meta
    ? $self->new( %{$old_meta}, connector=>$self->connector ) 
    : undef 
  );
}


# constructor
method load => named ( 
  connector => { isa=>'DBIx::PgLink::Connector', required=>1},
  object_id => { isa=>'Int', required=>1},
) => sub {
  my ($class, $p) = @_;

  my $data = pg_dbh->selectrow_hashref(<<END_OF_SQL,
SELECT *
FROM @{[ $class->metadata_table ]}
WHERE object_id = \$1
END_OF_SQL
    { 
      %{$class->metadata_table_attr}, 
      Slice => {}, 
      no_cursor=>1, 
      types=>[qw/INT4/],
    },
    $p->{object_id},
  )
  or confess "Cannot load accessor metadata with id=$p->{object_id}";
  return $class->new( %{$data}, connector => $p->{connector} );
};


method delete_metadata_by_id => positional(
  {isa=>'Int', required=>1},
) => sub {
  my ($self, $object_id) = @_;

  # delete base row by id
  # foreign key cascade to child metadata (columns, queries, etc)
  pg_dbh->do(<<'END_OF_SQL',
DELETE FROM dbix_pglink.objects
WHERE object_id = $1
END_OF_SQL
    {types=>[qw/INT4/]},
    $object_id,
  );
};

sub load_metadata_by_local_name {
  my $self = shift;

  # load row by natural key
  return pg_dbh->selectrow_hashref(<<END_OF_SQL,
SELECT *
FROM @{[ $self->metadata_table ]}
WHERE conn_name = \$1
  and remote_object_type = \$2
  and local_schema = \$3
  and local_object = \$4
END_OF_SQL
    {
      %{$self->metadata_table_attr}, 
      no_cursor=>1, 
      types=>[qw/TEXT TEXT TEXT TEXT/],
    },
    $self->conn_name,
    $self->remote_object_type,
    $self->local_schema,
    $self->local_object,
  );
}


sub load_metadata_by_remote_name {
  my $self = shift;
  # find row by natural key (remote schema+name + local schema+name)
  # one remote table can have many accessors in different local schemas
  # compare object class instead type (remote TABLE can become VIEW)
  return pg_dbh->selectrow_hashref(<<END_OF_SQL,
SELECT *
FROM @{[ $self->metadata_table ]}
WHERE conn_name = \$1
  and dbix_pglink.object_type_class(remote_object_type) = dbix_pglink.object_type_class(\$2)
  and remote_catalog is not distinct from \$3
  and remote_schema is not distinct from \$4
  and remote_object = \$5
  and local_schema = \$6
  and local_object = \$7
END_OF_SQL
    {
      %{$self->metadata_table_attr}, 
      types=>[qw/TEXT TEXT TEXT TEXT TEXT TEXT TEXT/],
      #          1    2    3    4    5    6    7
    },
    $self->conn_name,          # 1
    $self->remote_object_type, # 2
    $self->remote_catalog,     # 3
    $self->remote_schema,      # 4
    $self->remote_object,      # 5
    $self->local_schema,       # 6
    $self->local_object,       # 7
  );
}


sub save_metadata {
  my $self = shift;

  # just base table, not $self->metadata_table
  pg_dbh->do(<<'END_OF_SQL',
INSERT INTO dbix_pglink.objects (
  object_id,             --1
  conn_name,             --2
  remote_object_type,    --3
  remote_catalog,        --4
  remote_schema,         --5
  remote_object,         --6
  local_schema,          --7
  local_object           --8
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
END_OF_SQL
    {types=>[qw/INT4 TEXT TEXT TEXT TEXT TEXT TEXT TEXT/]},
    #           1    2    3    4    5    6    7    8
    $self->object_id,          # 1
    $self->conn_name,          # 2
    $self->remote_object_type, # 3
    $self->remote_catalog,     # 4
    $self->remote_schema,      # 5
    $self->remote_object,      # 6
    $self->local_schema,       # 7
    $self->local_object,       # 8
  );
};


sub create_local_schema {
  my $self = shift;

  return if pg_dbh->selectrow_array(<<'END_OF_SQL', {}, $self->local_schema);
SELECT 1
FROM information_schema.schemata
WHERE schema_name = $1
END_OF_SQL

  my $local_schema_quoted = pg_dbh->quote_identifier($self->local_schema);
  pg_dbh->do("CREATE SCHEMA $local_schema_quoted");
  trace_msg("NOTICE", "Created schema $local_schema_quoted") 
    if trace_level >= 1;
};


method create_comment => named (
  type    => { isa => 'Str', required => 1},
  name    => { isa => 'Str', required => 1}, # quoted full name
  comment => { isa => 'Str', required => 1},
) => sub {
  my ($self, $p) = @_;
  #trim starting/ending newlines
  $p->{comment} =~ s/^\n+//;
  $p->{comment} =~ s/\n+$//;
  $p->{comment} .= " at " . $self->conn_name;
  pg_dbh->do("COMMENT ON $p->{type} $p->{name} IS " . pg_dbh->quote($p->{comment}));
};


# drop accessor object and metadata
sub drop {
  my $self = shift;
  $self->drop_local_objects;
  $self->delete_metadata(1);
}



# ------------ enumeration (class methods) ------------------------------------


# class method
sub get_accessor_type {
  my ($class, $object_id) = @_;
  return pg_dbh->selectrow_array(<<'END_OF_SQL',
SELECT remote_object_type
FROM dbix_pglink.objects
WHERE object_id = $1
END_OF_SQL
    { no_cursor=>1, types=>[qw/INT4/] },
    $object_id,
  );
}


# class method
# interface with params defaults and requirements
# (override/around/inner got raw params, not cooked by MooseX::Method)
method build_accessors => named (
  connector           => { isa => 'DBIx::PgLink::Connector', required => 1 },
  local_schema        => { isa => 'Str', required => 1 },
  remote_catalog      => { isa => 'StrNull', default => '%' },
  remote_schema       => { isa => 'StrNull', default => '%' },
  remote_object       => { isa => 'Str', default => '%' },
  remote_object_type  => { isa => 'Str', required => 1 },
  object_name_mapping => { isa => 'HashRef', required => 0 },
) => sub {
  my ($class, $p) = @_;

  my $cnt = $class->_implement_build_accessors($p);
  trace_msg('INFO', "Created $cnt accessor(s) for remote $p->{remote_object_type}") if trace_level >= 0;
  return $cnt;
};


# class method, no params check
sub _implement_build_accessors { abstract() }


# class method
method rebuild_accessors => named (
  connector           => { isa => 'DBIx::PgLink::Connector', required => 1 },
  remote_object_type  => { isa => 'Str', required => 1 },
  local_schema        => { isa => 'Str', required => 1 },
  local_object        => { isa => 'Str', default => '%' },
) => sub {
  my ($class, $p) = @_;

  my $cnt = $class->for_accessors(
    %{$p},
    coderef => sub {
      (shift)->build(
        use_local_metadata => 1
      );
    }
  );
  trace_msg('INFO', "Recreated $cnt accessor(s) $p->{remote_object_type}") if trace_level >= 0;
  return $cnt;
};


# class method
method for_accessors => named (
  connector           => { isa => 'DBIx::PgLink::Connector', required => 1 },
  remote_object_type  => { isa => 'Str', required => 1 },
  local_schema        => { isa => 'Str', default => '%' }, # like
  local_object        => { isa => 'Str', default => '%' }, # like
  coderef             => { isa => 'CodeRef', required => 1 },
) => sub {
  my ($class, $p) = @_;

  my $sth = pg_dbh->prepare_cached(<<'END_OF_SQL');
SELECT object_id
FROM dbix_pglink.objects
WHERE conn_name = $1
  and remote_object_type = $2
  and local_schema like $3
  and local_object like $4
END_OF_SQL

  $sth->execute(
    $p->{connector}->conn_name,
    $p->{remote_object_type},
    $p->{local_schema},
    $p->{local_object},
  );

  my $cnt = 0;
  while (my $row = $sth->fetchrow_hashref) {
    my $accessor = $class->load(
      connector => $p->{connector},
      object_id => $row->{object_id},
    );
    $p->{coderef}->($accessor);
    $cnt++;
  }
  return $cnt;
};

# -------------------------------------------------------


__PACKAGE__->meta->make_immutable;

1;
