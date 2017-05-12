package DBIx::PgLink::Adapter::Pg;

use Moose;
use Data::Dumper;
use Memoize;

extends 'DBIx::PgLink::Adapter';


has '+are_transactions_supported' => (default=>1);
has '+are_routines_supported'     => (default=>1);
has '+routine_can_be_overloaded'  => (default=>1);
has '+require_parameter_type'     => (default=>0);


override 'quote' => sub {
  my $self = shift;
  my $q = super();
  if ($self->dbh->{pg_server_version} >= 80100 && defined $q && $q =~ /\\/) {
    return 'E' . $q; # work with any 'standard_conforming_strings' settings
  }
  return $q;
};


around qw/
    selectrow_array selectrow_arrayref selectrow_hashref
    selectall_arrayref selectall_hashref selectcol_arrayref
    prepare prepare_cached
/ => sub {
  my $next = shift;
  my $self = shift;
  my $query = shift;
  # DBD::Pg/libpq core dumps when execute empty query ('')
  # although prepare returns valid DBI::st
  # do() is immune, ' ' query is ok
  $query = ' ' if $query eq '';
  $next->($self, $query, @_);
};


sub is_transaction_active {
  my $self = shift;
  return $self->ping == 3; # Database is idle within a transaction (DBD::Pg extension)
};


# for Reconnect role
sub is_disconnected {
  my ($self, $exception) = @_;
  return 
     # WARNING: this doesn't work with localized libpq messages
     $exception =~ /server closed the connection unexpectedly/i 
  || $exception =~ /terminating connection/
  || $exception =~ /no connection to the server/
  # SQLSTATE code
  || $self->dbh->state =~ /^.8...$/; # Class 08 - Connection Exception (first char can be 'S' or '0')
}


has 'pg_column_type_id_sth' => (
  is  => 'ro',
  isa => 'Object',
  lazy => 1,
  default => sub {
    my $self = shift;
    return $self->prepare(<<'END_OF_SQL');
SELECT
  a.atttypid as pg_type_id
FROM 
  pg_catalog.pg_class c
  JOIN pg_catalog.pg_namespace ns on ns.oid = c.relnamespace
  JOIN pg_catalog.pg_attribute as a on a.attrelid = c.oid
WHERE ns.nspname = ?
  and c.relname = ?
  and a.attname = ?
END_OF_SQL
  },
);

has 'pg_type_sth' => (
  is  => 'ro',
  isa => 'Object',
  lazy => 1,
  default => sub {
    my $self = shift;
    return $self->prepare(<<'END_OF_SQL');
SELECT
  t.oid,
  t.typname,
  t.typtype,
  t.typrelid,
  t.typelem,
  t.typbasetype,
  t.typnotnull,
  ns.nspname as type_schema,
  pg_catalog.format_type(t.oid, NULL) as native_type_name
FROM pg_catalog.pg_type t
  JOIN pg_catalog.pg_namespace ns ON ns.oid = t.typnamespace
WHERE t.oid = ?
END_OF_SQL
  },
);

sub pg_type_by_id {
  my ($self, $type_id) = @_;
  $self->pg_type_sth->execute($type_id);
  return $self->pg_type_sth->fetchrow_hashref;
} 


sub pg_base_type {
  my ($self, $type_id) = @_;

  my $t = $self->pg_type_by_id($type_id);

  my $r = $t->{native_type_name};

  if ($t->{typtype} eq 'c') {
    $r = 'TEXT'; # coerce composite type to text
  } elsif ($t->{typtype} eq 'd') { # domain can be built on base type or another domain
    $r = $self->pg_base_type($t->{typbasetype});
  }

  return $r;
}

memoize 'pg_base_type';


sub current_database {
  my $self = shift;
  return $self->selectrow_array('SELECT current_database()');
}

memoize 'current_database'; # cannot change without disconnect 

around 'expand_table_info' => sub {
  my ($next, $self, $info) = @_;

  # bug: quoted identifier
  $info->{$_} = $self->unquote_identifier( $info->{$_} ) 
    for qw/TABLE_NAME TABLE_SCHEM/;

  $info->{TABLE_CAT} = $self->current_database;

  $next->($self, $info);
};

around 'expand_column_info' => sub {
  my ($next, $self, $info) = @_;

  $next->($self, $info) or return 0;

  # bug: quoted identifier
  $info->{$_} = $self->unquote_identifier( $info->{$_} ) 
    for qw/TABLE_NAME TABLE_SCHEM COLUMN_NAME/;

  # bug in DBD::Pg 1.49
  # for numeric column returns 'n,m' in COLUMN_SIZE and undef in DECIMAL_DIGITS
  if ($info->{TYPE_NAME} =~ /numeric|decimal/i 
  && $info->{COLUMN_SIZE} =~ /\d+,\d+/) {
    my ($m,$n) = $info->{pg_type} =~ /\((\d+),(\d+)\)/;
    $info->{COLUMN_SIZE}    = $m;
    $info->{DECIMAL_DIGITS} = $n;
  }

  if (!exists $info->{pg_type_id}) {
    # get column data type id
     my $sth = $self->pg_column_type_id_sth;
     $sth->execute(
       $info->{TABLE_SCHEM},
       $info->{TABLE_NAME},
       $info->{COLUMN_NAME},
     );
     $info->{pg_type_id} = $sth->fetchrow_array;
     $sth->finish;
  }

  # type name can be domain or composite type
  $info->{native_type_name} = $info->{pg_type};

  # always base type
  $info->{base_type_name} = $self->pg_base_type( $info->{pg_type_id} );

  # bug: invalid COLUMN_SIZE for bit type
  if ($info->{base_type_name} eq 'bit') {
    if ($info->{native_type_name} =~ /^bit\((\d+)\)$/) {
      $info->{COLUMN_SIZE} = $1;
    } else {
      $info->{COLUMN_SIZE} += 4;
    }
  }

  # bytea is the only type that need outout conversion in PL/Perl
  if ($info->{base_type_name} eq 'bytea') {
    $info->{conv_to_local} = 'to_pg_bytea';
  }


  1;
};


around 'expand_primary_key_info' => sub {
  my ($next, $self, $table) = @_;

  # bug: quoted identifier
  $table->{$_} = $self->unquote_identifier( $table->{$_} ) 
    for qw/TABLE_NAME TABLE_SCHEM COLUMN_NAME PK_NAME/;

  $next->($self, $table);
};


override 'routine_info' => sub { 
  my ($self, $catalog, $schema, $routine, $type) = @_;

  # catalog ignored, type can be only 'FUNCTION'
  $type =~ s/'//g;
  return unless grep { $_ eq 'FUNCTION' } split /,/, $type;

  # include only 'in' and 'inout' arguments to call signature
  # 'out' arguments goes to column_info
  my $sth = $self->prepare_cached(<<'END_OF_SQL');
SELECT
  current_database() as "SPECIFIC_CATALOG",
  n.nspname as "SPECIFIC_SCHEMA",
  pg_catalog.quote_ident(p.proname)
    || '('
    || coalesce(pg_catalog.array_to_string(ARRAY(
      SELECT
        p.proargnames[i+1] || ' '
        || pg_catalog.format_type(p.proargtypes[s.i], null)
      FROM pg_catalog.generate_series(0, pg_catalog.array_upper(p.proargtypes, 1)) AS s(i)
    ), ', '), '')
    || ')' as "SPECIFIC_NAME",
  current_database() as "ROUTINE_CATALOG",
  n.nspname as "ROUTINE_SCHEMA",
  p.proname as "ROUTINE_NAME",
  'FUNCTION' as "ROUTINE_TYPE",
  case
    when p.proretset then 'TABLE'
    when t.typname = 'record' then 'TABLE'
    when t.typtype = 'c' then 'TABLE'
    when t.typelem <> 0 then 'ARRAY'
    when t.typtype = 'b' then pg_catalog.format_type(t.oid, NULL)
    else 'USER-DEFINED'
  end as "DATA_TYPE",
  'GENERAL'::text as "PARAMETER_STYLE",
  case p.provolatile
    when 'i' then 'YES'
    else 'NO'
  end as "IS_DETERMINISTIC",
  case 
    when p.proisstrict then 'YES'
    else 'NO'
  end as "IS_NULL_CALL",
  ------------------
  p.oid         as pg_routine_id,
  p.proretset   as pg_return_set,
  p.prorettype  as pg_return_type_id,
  p.provolatile as pg_volatile
FROM pg_catalog.pg_proc p
  JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
  LEFT JOIN pg_catalog.pg_type t ON t.oid = p.prorettype
WHERE p.prorettype <> 'pg_catalog.cstring'::pg_catalog.regtype
  AND (p.proargtypes[0] IS NULL
    OR   p.proargtypes[0] <> 'pg_catalog.cstring'::pg_catalog.regtype)
  AND NOT p.proisagg
  AND n.nspname like ?
  AND p.proname like ?
ORDER BY 1, 2, 3;
END_OF_SQL

  $sth->execute($schema, $routine);
  return $sth;
};


override 'routine_argument_info_arrayref' => sub { 
  my ($self, $routine_info) = @_;

  my @result = ();

  my $sth = $self->prepare_cached(<<'END_OF_SQL');
SELECT
  p.proargnames[i+1] as "COLUMN_NAME",
  s.i + 1            as "ORDINAL_POSITION",
  pg_catalog.format_type(p.proargtypes[s.i], null) as native_type_name,
  p.proargtypes[s.i] as pg_type_id
FROM pg_catalog.pg_proc p
  -- can't pass join column to function
  CROSS JOIN pg_catalog.generate_series(0, (
      SELECT pg_catalog.array_upper(proargtypes, 1)
      FROM pg_catalog.pg_proc
      WHERE oid = ?
    )
  ) as s(i)
WHERE p.oid = ?
ORDER BY s.i
END_OF_SQL

  $sth->execute(
    $routine_info->{pg_routine_id},
    $routine_info->{pg_routine_id},
  );

  while (my $c = $sth->fetchrow_hashref) {
    $c->{base_type_name}   = $self->pg_base_type($c->{pg_type_id});
    push @result, $c;
  }

  return \@result;

};


around 'routine_column_info_arrayref' => sub { 
  my ($next, $self, $info) = @_;

  my @result = ();

  my $t = $self->pg_type_by_id( $info->{pg_return_type_id} );

  if ($t->{typtype} eq 'c') {
    # composite type

    # ...based on table/view 
    # DBD::Pg->column_info has restriction (relkind in ('r','v'))
    @result = @{ $self->column_info_arrayref('%', $t->{type_schema}, $t->{typname}, '%') };

    # composite type (relkind='c')
    unless (@result) {
      my $column_info = $self->selectall_arrayref(<<'END_OF_SQL', {Slice=>{}}, $t->{typrelid});
SELECT
  pg_catalog.current_database() as "TABLE_CAT",
  ns.nspname   as "TABLE_SCHEM",
  t.relname    as "TABLE_NAME",
  a.attname    as "COLUMN_NAME",
  null         as "DATA_TYPE",
  pg_catalog.format_type(a.atttypid, a.atttypmod) as "TYPE_NAME",
  null         as "COLUMN_SIZE",
  null         as "BUFFER_LENGTH",
  null         as "DECIMAL_DIGITS",
  null         as "NUM_PREC_RADIX",
  case when a.attnotnull then 'NO' else 'YES' end as "NULLABLE",
  null         as "REMARKS",
  null         as "COLUMN_DEF",
  null         as "SQL_DATA_TYPE",
  null         as "SQL_DATETIME_SUB",
  null         as "CHAR_OCTET_LENGTH",
  a.attnum     as "ORDINAL_POSITION",
  case when a.attnotnull then 'NO' else 'YES' end as "IS_NULLABLE",
  --
  a.atttypid   as pg_type_id,
  pg_catalog.format_type(a.atttypid, a.atttypmod) as native_type_name
FROM 
  pg_catalog.pg_class t
  JOIN pg_catalog.pg_namespace ns ON ns.oid = t.relnamespace
  JOIN pg_catalog.pg_attribute a ON a.attrelid = t.oid
WHERE t.oid = ?
  AND a.attnum > 0 AND NOT a.attisdropped
END_OF_SQL
      # don't need SQL type

      for my $ci (@{$column_info}) {
        $self->expand_column_info($ci)
        and push @result, $ci;
      }
    }

  } elsif ($t->{typname} eq 'record') { 
    # returns in+inout arguments
    my $sth = $self->prepare_cached(<<'END_OF_SQL');
SELECT
  p.proargnames[i] as "COLUMN_NAME",
  pg_catalog.format_type(p.proallargtypes[s.i], null) as native_type_name,
  p.proallargtypes[s.i] as pg_type_id
FROM pg_catalog.pg_proc p
  -- can't pass join column to function
  CROSS JOIN pg_catalog.generate_series(0, (
      SELECT pg_catalog.array_upper(proallargtypes, 1)
      FROM pg_catalog.pg_proc
      WHERE oid = ?
    )
  ) as s(i)
WHERE p.oid = ?
  AND p.proargmodes[i] in ('o','b')
ORDER BY s.i
END_OF_SQL

    $sth->execute(
      $info->{pg_routine_id},
      $info->{pg_routine_id},
    );

    my $index = 1;
    while (my $c = $sth->fetchrow_hashref) {
      $c->{base_type_name}   = $self->pg_base_type($c->{pg_type_id});
      $c->{TYPE_NAME}        = $c->{base_type_name};
      $c->{NULLABLE}         = 'YES';
      $c->{ORDINAL_POSITION} = $index++;
      push @result, $c;
    }

  } else {
    # base, domain or pseudo type
    push @result, {
      COLUMN_NAME      => 'RESULT',
      TYPE_NAME        => $t->{native_type_name},
      NULLABLE         => 'YES',
      ORDINAL_POSITION => 1,
      pg_type_id       => $t->{oid},
      native_type_name => $t->{native_type_name},
      base_type_name   => $self->pg_base_type($t->{oid}),
    };
  }
  return \@result;
};


override 'get_number_of_rows' => sub {
  my ($self, $catalog, $schema, $object, $type) = @_;

  if ($type eq 'TABLE') {
    # estimated row count, updated by VACUUM
    return $self->selectrow_array(<<'END_OF_SQL', {}, $schema, $object);
SELECT reltules
FROM 
  pg_catalog.pg_class t
  JOIN pg_catalog.pg_namespace ns ON ns.oid = t.relnamespace
WHERE ns.nspname = ?
  and c.relname = ?
  and c.relkind = 'r'
END_OF_SQL
  } else {
    return super();
  }
};


1;
