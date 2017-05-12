package DBIx::PgLink::Adapter::MSSQL;

# tested on MSSQL2000 sp4

use Carp;
use Moose;
use MooseX::Method;
use Data::Dumper;

extends 'DBIx::PgLink::Adapter::SQLServer';


# for Reconnect role
sub is_disconnected {
  my ($self, $exception) = @_;
  return 
     $exception =~ /General network error/i 
  # SQLSTATE code
  || $self->dbh->state =~ /^.8...$/; # Class 08 - Connection Exception
}


# ---------------------------- data conversion
sub pg_bool_to_mssql_bit {
  $_[1] = defined $_[1] ? $_[1] eq 't' ? 1 : 0 : undef; # NULL allowed
}


around 'expand_table_info' => sub {
  my ($next, $self, $info) = @_;

  # bug: some system views in list
  return 0 if $info->{TABLE_NAME} =~ /^sys/ && $info->{TABLE_TYPE} eq 'VIEW'; # skip 
  $next->($self, $info);
};


sub routine_info {
  my ($self, $catalog, $schema, $routine, $type) = @_;

  if (!$catalog || $catalog eq '%') {
    $catalog = $self->current_database;
  }

  my $type_cond = do {
    if (!defined $type || $type eq '%') {
      ''
    } elsif ($type =~ /('\w+',)*('\w+')/) {
      "AND ROUTINE_TYPE IN ($type)"
    } else {
      "AND ROUTINE_TYPE IN ('" . join("','", split /,/, $type) . "')"
    }
  };

  my $sth = eval {
    $self->prepare(<<END_OF_SQL);
SELECT
  SPECIFIC_CATALOG,
  SPECIFIC_SCHEMA,
  SPECIFIC_NAME,
  ROUTINE_CATALOG,
  ROUTINE_SCHEMA,
  ROUTINE_NAME,
  ROUTINE_TYPE,
  DATA_TYPE
FROM $catalog.INFORMATION_SCHEMA.ROUTINES
WHERE SPECIFIC_CATALOG like ?
  AND SPECIFIC_SCHEMA like ?
  AND SPECIFIC_NAME like ?
  $type_cond
ORDER BY 1,2,3
END_OF_SQL
  };
  return undef if $@;
  $sth->execute($catalog, $schema, $routine);
  return $sth;
};


around 'routine_column_info_arrayref' => sub { 
  my ($next, $self, $info) = @_;

  if ($info->{ROUTINE_TYPE} eq 'FUNCTION'
   && $info->{DATA_TYPE} ne 'TABLE') { 
     # scalar-valued function
     my $ci = {
       COLUMN_NAME      => 'RESULT',
       ORDINAL_POSITION => 1,
       TYPE_NAME        => $info->{DATA_TYPE},
     };
     $self->expand_column_info($ci);

     return [ $ci ];

  } else { #
    # table-valued function has INFORMATION_SCHEMA.ROUTINE_COLUMNS
    # procedure resultset handled by parent SQLServer class
    return $next->($self, $info); 
  }
};


around 'expand_routine_info' => sub {
  my ($next, $self, $info) = @_;

  # skip Visual Studio VCS procedures
  return 0 if $info->{ROUTINE_NAME} =~ /^dt_/ && $info->{ROUTINE_TYPE} eq 'PROCEDURE'; # skip 
  $next->($self, $info);
};


around 'expand_column_info' => sub {
  my ($next, $self, $column) = @_;

  # convert INFORMATION_SCHEMA.xxx to DBI::column_info

  if (!exists $column->{COLUMN_SIZE}) {
    $column->{COLUMN_SIZE} = $column->{CHARACTER_MAXIMUM_LENGTH}
      || $column->{NUMERIC_PRECISION};
    $column->{DECIMAL_DIGITS} = $column->{NUMERIC_SCALE};
  }

  $next->($self, $column);
};

1;
