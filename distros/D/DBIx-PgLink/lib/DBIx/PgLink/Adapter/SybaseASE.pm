package DBIx::PgLink::Adapter::SybaseASE;

# tested on Sybase ASE 12.5 with DBD::Sybase 0.95

use Carp;
use Moose;
use MooseX::Method;
use Data::Dumper;
use DBI qw/:sql_types/;

extends 'DBIx::PgLink::Adapter::SQLServer';

has '+require_parameter_type' => (default=>1);

override 'quote_identifier' => sub {
  my ($self, @id) = @_;

  for my $i (@id) {
    next unless defined $i;
    next if $i =~ /^\w+$/; # quote only when needed
    $i =~ s/"/""/g;
    $i = '"' . $i . '"';
  }
  my $quoted_id = join '.', grep { defined } @id;
  return $quoted_id;
};


# for Reconnect role
sub is_disconnected {
  my ($self, $exception) = @_;
  return 
     $exception =~ /Net-Library operation terminated due to disconnect/i 
  ;
}

# ---------------------------- data conversion

# PostgreSQL boolean to bit
sub pg_bool_to_syb_bit {
  $_[1] = defined $_[1] ? $_[1] eq 't' ? 1 : 0 : 0; # NULL is not allowed
}

# Sybase (var)?binary to bytea
sub syb_binary_to_pg_bytea {
  my ($self) = @_;
  $_[1] =~ s/^0x//;
  $_[1] = pack("H*", $_[1]);
  $self->to_pg_bytea($_[1]);
}


# catalog functions very picky about input

around 'table_info' => sub {
  my ($next, $self, $catalog, $schema, $table, $type) = @_;

  # catalog must be current database name
  if (!$catalog || $catalog eq '%') {
    $catalog = $self->current_database();
  }
  # type entries must be quoted
  if ($type !~ /'/) {
    $type = join ',', map { "'$_'" } split /,/, $type;
  }
  $next->($self, $catalog, $schema, $table, $type);
  # cannot fix column names here
};


around 'column_info' => sub {
  my ($next, $self, $catalog, $schema, $table, $column) = @_;

  # catalog must be current database name
  if (!$catalog || $catalog eq '%') {
    $catalog = $self->current_database();
  }
  $next->($self, $catalog, $schema, $table, $column);
};


sub _uppercase_hashref_keys {
  my $href = shift;
  my @keys = keys %{$href};
  for my $key (@keys) {
    $href->{uc $key} = delete $href->{$key};
  }
}


around 'expand_table_info' => sub {
  my ($next, $self, $table) = @_;

  _uppercase_hashref_keys($table);

  # bug: DBD::Sybase v0.95 return non-standard field name
  $table->{TABLE_CAT}   ||= $table->{TABLE_QUALIFIER};
  $table->{TABLE_SCHEM} ||= $table->{TABLE_OWNER};

  $next->($self, $table);
};


around 'expand_column_info', 'expand_primary_key_info' => sub {
  my ($next, $self, $info) = @_;

  _uppercase_hashref_keys($info);

  $next->($self, $info);
};


# DBD::Sybase has problem with placeholders in prepared SP call
for my $func (qw/
  prepare prepare_cached
/) {
  around $func => sub {
    my $next = shift;
    my $self = shift;
    my $statement = shift;
    my $attr = shift;

    if ($statement =~ /^EXEC.*\?/i && $self->dbh->{Driver}->{Name} eq 'Sybase') {
      return $self->new_statement(
        class     => 'DBIx::PgLink::Adapter::SybaseASE::PreparedProcedure',
        statement => $statement,
        parent    => $self,
        method    => $func,
        defined $attr ? %{$attr} : (),
      );
    } else {
      return $next->($self, $statement, $attr);
    }
  };
}

has 'quote_literal_types' => ( # initialize once for connection
  is=>'ro', isa=>'HashRef', lazy=>1, 
  default=>sub { 
    return {
      SQL_BINARY()    => undef,
      SQL_BLOB()      => undef,
      SQL_CHAR()      => undef,
      SQL_DATE()      => undef,
      SQL_VARBINARY() => undef,
      SQL_VARCHAR()   => undef,
  } },
);




around 'routine_info_arrayref' => sub { 
  my ($next, $self, $catalog, $schema, $routine, $type) = @_;

  # TODO: parse $type and add Java function support (very low priority)
  return $next->($self, $catalog, $schema, $routine, $type) unless $type =~ /PROCEDURE/;

  my @result = ();

  my $full_proc_name = $self->quote_identifier(
    $catalog,
    'dbo',
    'sp_stored_procedures'
  );
  my $sth = $self->prepare("exec $full_proc_name ?, ?, ?");
  $sth->execute( # name in reverse order
    $routine,
    $schema,
    $catalog,
  );

  while (my $sp = $sth->fetchrow_hashref) {
    my $proc_name = $sp->{procedure_name};
    $proc_name =~ s/;\d+$//; # obsolete procedure group number
    my $i = {
      SPECIFIC_CATALOG => $sp->{procedure_qualifier},
      SPECIFIC_SCHEMA  => $sp->{procedure_owner},
      SPECIFIC_NAME    => $proc_name,
      ROUTINE_CATALOG  => $sp->{procedure_qualifier},
      ROUTINE_SCHEMA   => $sp->{procedure_owner},
      ROUTINE_NAME     => $proc_name,
      ROUTINE_TYPE     => 'PROCEDURE',
      DATA_TYPE        => undef,
    };
    $self->expand_routine_info($i)
    and push @result, $i;
  }
  $sth->finish;

  return \@result;

};


around 'expand_routine_argument_info' => sub {
  my ($next, $self, $arg) = @_;

  _uppercase_hashref_keys($arg);

  $next->($self, $arg);
};


sub dummy_procedure_call_arguments {
  my ($self, $routine_info) = @_;
  # 'bit' type does not allow NULL
  return map { 
    $_->{DATA_TYPE} == SQL_BIT ? '0' : 'NULL'
  } @{$self->routine_argument_info_arrayref($routine_info)};
}


1;


# emulate prepared statement for DBD::Sybase

package DBIx::PgLink::Adapter::SybaseASE::PreparedProcedure;

use Moose;
use DBIx::PgLink::Adapter;
use DBIx::PgLink::Logger;
use DBI qw/:sql_types/;

extends 'DBIx::PgLink::Adapter::st';

has '+sth' => ( required=>0 );

has 'statement' => ( is=>'ro', isa=>'Str', required=>1 );

has 'method' => ( is=>'ro', isa=>'Str', required=>1 );

has 'param_values' => ( is=>'rw', isa=>'ArrayRef', default=>sub { [] } );

around 'finish' => sub {
  my $next = shift;
  my $self = shift;

  $self->param_values( [] );
  $self->sth->finish if $self->sth;
};


around 'bind_param' => sub {
  my $next = shift;
  my ($self, $p_num, $bind_value, $attr) = @_;

  my $type = ref $attr eq 'HASH' ? $attr->{TYPE} : $attr;

  if (exists $self->parent->quote_literal_types->{$type}) {
    $bind_value = $self->parent->quote($bind_value);
  }
  $self->param_values->[$p_num-1] = $bind_value;
  trace_msg('INFO', "Bind $p_num " . (defined $bind_value ? $bind_value : 'NULL'))
    if trace_level >= 4;
  return 1;
};


around 'execute' => sub {
  my $next = shift;
  my $self = shift;

  for my $i (0..$#_) {
    $self->bind_param($i+1, $_[$i], SQL_VARCHAR);
  }

  # naive replacement of ?-placeholders by literal value
  my $query = $self->statement;
  for my $p (@{$self->param_values}) {
    $query =~ s/\?/$p/;
  }

  $self->sth->finish if $self->sth;
  my $sth = $self->method eq 'prepare_cached' 
    ? $self->parent->dbh->prepare_cached($query)
    : $self->parent->dbh->prepare($query);
  $self->{sth} = $sth;
  return $sth->execute;
};


1;
