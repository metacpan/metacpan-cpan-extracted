package DBIx::PgLink::Accessor::Routine;

use Moose;
use MooseX::Method;
use DBIx::PgLink::Local;
use DBIx::PgLink::Logger;
use DBIx::PgLink::Accessor::RoutineColumns;
use Data::Dumper;

our $VERSION = '0.01';


extends 'DBIx::PgLink::Accessor::BaseAccessor';

# -------------------------------------------------------

# class method
sub _implement_build_accessors {
  my ($class, $p) = @_;

  unless ($p->{connector}->adapter->are_routines_supported) {
    trace_msg('NOTICE', 'Routines are not supported');
    return 0;
  }

  my $objects = $p->{connector}->adapter->routine_info_arrayref(
    $p->{remote_catalog},
    $p->{remote_schema},
    $p->{remote_object},
    $p->{remote_object_type},
  ) or return 0;

  my $cnt = 0;
  for my $obj (@{$objects}) {
    # ROUTINE_NAME  - base name of routine
    # SPECIFIC_NAME - unique routine name (include function prototype or object id)
    my $local_object = $p->{object_name_mapping}->{$obj->{ROUTINE_NAME}} 
                    || $obj->{ROUTINE_NAME};
    my $accessor = $class->new_from_remote_metadata({
       %{$p},
       %{$obj},
       local_object => $local_object,
    });
    $cnt += $accessor->build;
  }
  return $cnt;
};


# constructor
sub new_from_remote_metadata {
  my ($class, $meta) = @_;
  my $connector = delete $meta->{connector};
  return $class->new(
    %{$meta},
    connector           => $connector,
    remote_catalog      => $meta->{SPECIFIC_CATALOG},
    remote_schema       => $meta->{SPECIFIC_SCHEMA},
    remote_object       => $meta->{SPECIFIC_NAME},
    remote_object_type  => $meta->{ROUTINE_TYPE},
    remote_routine_name => $meta->{ROUTINE_NAME},
    defined $meta->{DATA_TYPE}
      ? $meta->{DATA_TYPE} eq 'TABLE' 
        ? (returns_set => 1) 
        : (returns_set => 0)
      : (),
    routine_info        => $meta,
  );
}


# -------------------------------------------------------

sub metadata_table { 'dbix_pglink.v_routines' }
sub metadata_table_attr { { boolean=>[qw/returns_set/]} } # attr for pg_dbh->prepare

with 'DBIx::PgLink::Accessor::HasColumns';

has '+columns_class' => (default=>'DBIx::PgLink::Accessor::RoutineColumns');

with 'DBIx::PgLink::Accessor::HasQueries';

has 'arguments' => (
  is         => 'rw',
  isa        => 'ArrayRef[HashRef]',
  auto_deref => 1,
  lazy       => 1,
  default    => sub { 
    my $self = shift;
    return $self->building_mode 
      ? $self->get_remote_arguments
      : $self->load_arguments
  },
);


has 'routine_info' => ( is=>'ro', isa=>'HashRef' ); # passed by build_accessors
has 'remote_routine_name' => (is=>'ro', isa=>'Str', required=>1 );
has 'returns_set' => (is=>'ro', isa=>'Bool', lazy=>1,
  default => sub {
    my $self = shift;
    return ($self->columns->metadata) ? 1 : 0; # has non-empty column list?
  }
);

my %name_attr = (is=>'ro', isa=>'Str', lazy=>1);

has 'local_object_quoted' => (%name_attr, default=>sub{ $_[0]->QLIS($_[0]->local_object) } );

# WARNING: function that returns single row (composite) treated as set-returning

# use object id to make unique rowtype name
has 'rowtype' => (%name_attr, 
  default=>sub{ 
    my $self = shift;
    if ($self->returns_set) {
      return "routine_" . $self->object_id . "_rowtype";
    } else { # scalar or void
      my $c = $self->columns->metadata->[0]; 
      return $c ? $c->{local_type} : 'void';
    }
  } 
);

has 'rowtype_quoted' => (%name_attr, 
  default=>sub{ 
    my $self = shift;
    if ($self->returns_set) {
      return $self->QLIS($self->rowtype);
    } else { # scalar or void
      return $self->rowtype;
    }
  } 
);

# argument part of function signature
has 'local_sign_arg' => (%name_attr,
  default=>sub {
    my $self= shift;
    return '(' . join(', ', map { $_->{local_type} } $self->arguments) . ')';
  }
);

# same, but with argument name (more informative for user)
has 'local_sign_arg_named' => (%name_attr,
  default=>sub {
    my $self= shift;
    return '(' . join(', ', map { 
      ( $_->{arg_name} ? $self->QLI($_->{arg_name}) . ' ' : '' )
      . $_->{local_type}
    } $self->arguments) . ')';
  }
);

has 'function_quoted_sign' => (%name_attr, 
  default=>sub {
    my $self= shift;
    return $self->local_object_quoted . $self->local_sign_arg_named;
  }
);


before 'build' => sub {
  my $self = shift;

  push @{$self->skip_on_errors}, 'Cannot detect resultset of stored procedure';
};


sub create_metadata {
  my $self = shift;

  $self->columns->require_quoted_names;

  $self->create_query( $self->_select_query );
}


sub _select_query {
  my $self = shift;

  my @params = map { { 
    column_name => $_->{arg_name} || $_->{arg_position}, 
    meta        => $_,
  } } $self->arguments;

  return {
    query_text => $self->adapter->format_routine_call(
      catalog      => $self->remote_catalog,
      schema       => $self->remote_schema,
      routine      => $self->remote_routine_name,
      routine_type => $self->remote_object_type,
      returns_set  => $self->returns_set,
      arguments    => scalar($self->arguments),
    ),
    action => 'S',
    params => \@params,
  };
}


sub get_remote_arguments {
  my $self = shift;

  my @result = ();

  my $info = $self->adapter->routine_argument_info_arrayref($self->routine_info);

  for my $i (@{$info}) {
    my $type = $self->connector->expanded_data_type_to_local($i);
    push @result, {
      arg_name     => $i->{COLUMN_NAME},
      arg_position => $i->{ORDINAL_POSITION},
       %{$type},
    };
  }

  return \@result;
}


before 'create_metadata' => sub {
  my $self = shift;
  return unless $self->old_accessor;
  $self->old_accessor->arguments; # force argument metadata load for previous accessor version
};


sub drop_local_objects {
  my $self = shift;

  pg_dbh->do( "DROP FUNCTION IF EXISTS " . $self->function_quoted_sign );

  if ($self->returns_set && $self->rowtype =~ /^routine_.*_rowtype$/) {
    pg_dbh->do( "DROP TYPE IF EXISTS " . $self->rowtype_quoted );
  }
}


sub create_local_objects { 
  my $self = shift;

  $self->create_rowtype if $self->returns_set; # by HasColumns role

  $self->create_function;
}


sub create_function {
  my $self = shift;

  pg_dbh->do(<<END_OF_SQL);
CREATE OR REPLACE FUNCTION @{[ $self->function_quoted_sign ]}
RETURNS @{[ ($self->returns_set ? 'SETOF ' : '') . $self->rowtype_quoted ]}
SECURITY DEFINER
LANGUAGE plperlu
AS \$method_body\$
  use DBIx::PgLink;
  DBIx::PgLink->connect(
    @{[ $self->perl_quote($self->conn_name) ]}
  )->remote_accessor_query(
    object_id    => @{[ $self->object_id ]},
    param_values => \\\@_,
  );
\$method_body\$
END_OF_SQL
  pg_dbh->do(<<END_OF_SQL);
REVOKE ALL ON FUNCTION @{[ $self->function_quoted_sign ]} FROM public;
END_OF_SQL
  $self->create_comment(
    type    => "FUNCTION",
    name    => $self->function_quoted_sign,
    comment => "Access function for remote " . $self->remote_object_type . " " . $self->remote_object_quoted,
  );
  trace_msg('INFO', "Created function " . $self->function_quoted_sign)
    if trace_level >= 1;
}


after 'save_metadata' => sub {
  my $self = shift;

  pg_dbh->do(<<'END_OF_SQL',
INSERT INTO dbix_pglink.routines (
  object_id,
  local_sign_arg,
  remote_routine_name,
  returns_set,
  rowtype
) VALUES ($1, $2, $3, $4, $5)
END_OF_SQL
     {types=>[qw/INT4 TEXT TEXT BOOL TEXT/]},
     $self->object_id,
     $self->local_sign_arg,
     $self->remote_routine_name,
     $self->returns_set,
     $self->rowtype,
  );

  $self->save_arguments_metadata;
};


has 'save_argument_sth' => (
  is      => 'ro',
  isa     => 'Object',
  lazy    => 1,
  default => sub {
    pg_dbh->prepare_cached(<<'END_OF_SQL',
INSERT INTO dbix_pglink.routine_arguments (
  object_id,      --1
  arg_position,   --2
  arg_name,       --3
  remote_type,    --4
  local_type,     --5
  conv_to_remote  --6
) VALUES ($1, $2, $3, $4, $5, $6)
END_OF_SQL
      { no_cursor=>1, types => [qw/INT4 INT4 TEXT TEXT TEXT TEXT/]}
      #                            1    2    3    4    5    6
    );
  },
);

sub save_arguments_metadata {
  my $self = shift;

  my $sth = $self->save_argument_sth;
  my $index = 1;
  for my $arg ($self->arguments) {
    $sth->execute(
      $self->object_id,       # 1
      $arg->{arg_position},   # 2
      $arg->{arg_name},       # 3
      $arg->{remote_type},    # 4
      $arg->{local_type},     # 5
      $arg->{conv_to_remote}, # 6
    );
  }
}


sub load_arguments {
  my $self = shift;
  my $result = pg_dbh->selectall_arrayref(<<'END_OF_SQL',
SELECT *
FROM dbix_pglink.routine_arguments
WHERE object_id = $1
ORDER BY arg_position
END_OF_SQL
    { Slice=>{}, no_cursor=>1, types => [qw/INT4/] },
    $self->object_id,
  );
  return $result;
}




__PACKAGE__->meta->make_immutable;


1;
