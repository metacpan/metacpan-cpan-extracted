package DBIx::PgLink::Accessor::BaseColumns;

# represent collection of columns not used separately (hence plural name)

use Carp;
use Moose;
use MooseX::Method;
use DBIx::PgLink::Local;
use DBIx::PgLink::Logger;
use Data::Dumper;

our $VERSION = '0.01';

extends 'Moose::Object';

has 'parent' => ( is=>'ro', isa=>'DBIx::PgLink::Accessor::BaseAccessor', required=>1 );

has 'metadata' => (
  is  => 'rw',
  isa => 'ColumnsMetadata',
  auto_deref => 1,
  default => sub { [] },
);

sub adapter { (shift)->parent->adapter }
sub connector { (shift)->parent->connector }


method new_from_remote_metadata => named (
  parent => {isa=>'DBIx::PgLink::Accessor::BaseAccessor', required=>1},
) => sub {
  my ($class, $p) = @_;

  my $self = $class->new(
    parent => $p->{parent},
  );

  my $column_info = $self->get_remote_column_info;
  confess "Cannot get column information about " . $self->parent->remote_object_quoted
    unless defined $column_info; # empty array is ok (unknown set of record)

  for my $column (@{$column_info}) {
    my $c = $self->create_column_metadata($column);
    push @{$self->metadata}, $c;
  }

  return $self;
};


sub get_remote_column_info {
  confess "Abstract method called";
}


sub create_column_metadata {
  my ($self, $column) = @_;

  my $type = $self->connector->expanded_data_type_to_local($column); # by TypeMapper role

  my $local_type = $type->{local_type};

  # append data length modifier to type name
  if ($local_type !~ /\(\d+/ && $column->{COLUMN_SIZE}) {
    if ($local_type =~ /^(numeric|decimal)$/i) {
      my $dd = $column->{DECIMAL_DIGITS} || 0;
      $local_type .= "($column->{COLUMN_SIZE},$dd)";
    } elsif ($local_type =~ /char/i) {
      $local_type .= "($column->{COLUMN_SIZE})";
    } elsif ($local_type =~ /^bit$/i) {
      $local_type .= "($column->{COLUMN_SIZE})";
    }
  }

  return {
    column_name      => $column->{COLUMN_NAME}, # not quoted
    position         => $column->{ORDINAL_POSITION},
    remote_type      => $type->{remote_type},   # from mapping, not source type
    remote_size      => $column->{COLUMN_SIZE} || 0,
    remote_prec      => $column->{DECIMAL_DIGITS},
    local_type       => $local_type,            # with column size
    conv_to_local    => $type->{conv_to_local},
    conv_to_remote   => $type->{conv_to_remote},
    nullable         => defined $column->{NULLABLE} ? $column->{NULLABLE} : 1,
    primary_key      => 0,
    searchable       => 1,
    insertable       => exists $column->{insertable} ? $column->{insertable} 
                        : defined $type->{insertable} ? $type->{insertable} : 1,
    updatable        => exists $column->{updatable} ? $column->{updatable} 
                        : defined $type->{updatable} ? $type->{updatable} : 1,
  };
}


has '_names_are_quoted' => ( isa => 'Bool', default => 0 );

sub require_quoted_names {
  my $self = shift;

  return if $self->{_names_are_quoted};

  my $adapter = $self->parent->adapter;
  for my $c (@{$self->metadata}) {
    $c->{remote_column_quoted} = $adapter->quote_identifier($c->{column_name});
    $c->{local_column_quoted}  = pg_dbh->quote_identifier($c->{column_name});
    $c->{old_column_name}      = "old_$c->{column_name}";
    $c->{new_column_name}      = "new_$c->{column_name}";
    $c->{old_column_quoted}    = pg_dbh->quote_identifier($c->{old_column_name});
    $c->{new_column_quoted}    = pg_dbh->quote_identifier($c->{new_column_name});
  }

  $self->{_names_are_quoted} = 1;
}


has 'insert_columns_sth' => (
  is  => 'ro',
  isa => 'DBIx::PgLink::Local::st',
  lazy => 1,
  default => sub {
    my $self = shift;
    return pg_dbh->prepare_cached(<<'END_OF_SQL',
INSERT INTO dbix_pglink.columns (
  object_id,            --1
  column_name,          --2
  column_position,      --3
  remote_type,          --4
  remote_size,          --5
  remote_prec,          --6
  local_type,           --7
  primary_key,          --8
  searchable,           --9
  nullable,             --10
  insertable,           --11
  updatable,            --12
  conv_to_local,        --13
  conv_to_remote        --14
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
)
END_OF_SQL
      {
        types=>[qw/INT4 TEXT INT4 TEXT INT4 INT4 TEXT BOOL BOOL BOOL BOOL BOOL TEXT TEXT/],
                 # 1    2    3    4    5    6    7    8    9    10   11   12   13   14
        no_cursor=>1
      }
    );
  },
);


sub save {
  my $self = shift;

  for my $f ($self->metadata) {
    $self->insert_columns_sth->execute(
      $self->parent->object_id,    #  1
      $f->{column_name},           #  2
      $f->{position},              #  3
      $f->{remote_type},           #  4
      $f->{remote_size},           #  5
      $f->{remote_prec},           #  6
      $f->{local_type},            #  7
      $f->{primary_key},           #  8
      $f->{searchable},            #  9
      $f->{nullable},              # 10
      $f->{insertable},            # 11
      $f->{updatable},             # 12
      $f->{conv_to_local},         # 13
      $f->{conv_to_remote},        # 14
    );
  }
}


method load => named ( # constructor
  parent    => {isa=>'DBIx::PgLink::Accessor::BaseAccessor', required=>1 },
  object_id => {isa=>'Int', required=>1 },
) => sub {
  my ($class, $p) = @_;

  my $data = pg_dbh->selectall_arrayref(<<'END_OF_SQL', 
SELECT *
FROM dbix_pglink.columns
WHERE object_id = $1
ORDER BY column_position
END_OF_SQL
    {
      Slice     => {},
      no_cursor => 1, 
      types     => [qw/INT4/],
      boolean   => [qw/primary_key searchable insertable updatable deletable/],
    },
    $p->{object_id},
  );
  confess "Cannot load columns metadata for $p->{object_id}" unless @{$data};

  return $class->new(
    parent => $p->{parent}, 
    metadata=>$data,
  );
};

__PACKAGE__->meta->make_immutable;

1;
