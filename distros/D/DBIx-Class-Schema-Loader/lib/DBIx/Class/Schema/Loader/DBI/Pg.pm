package DBIx::Class::Schema::Loader::DBI::Pg;

use strict;
use warnings;
use base 'DBIx::Class::Schema::Loader::DBI::Component::QuotedDefault';
use mro 'c3';

our $VERSION = '0.07052';

=head1 NAME

DBIx::Class::Schema::Loader::DBI::Pg - DBIx::Class::Schema::Loader::DBI
PostgreSQL Implementation.

=head1 DESCRIPTION

See L<DBIx::Class::Schema::Loader> and L<DBIx::Class::Schema::Loader::Base>.

=cut

sub _setup {
  my $self = shift;

  $self->next::method(@_);

  $self->{db_schema} ||= ['public'];

  if ( not defined $self->preserve_case ) {
    $self->preserve_case(0);
  }
  elsif ( $self->preserve_case ) {
    $self->schema->storage->sql_maker->quote_char('"');
    $self->schema->storage->sql_maker->name_sep('.');
  }
}

sub _system_schemas {
  my $self = shift;

  return ( $self->next::method(@_), 'pg_catalog' );
}

my %pg_rules = (
  a => 'NO ACTION',
  r => 'RESTRICT',
  c => 'CASCADE',
  n => 'SET NULL',
  d => 'SET DEFAULT',
);

sub _table_fk_info {
  my ( $self, $table ) = @_;

  my $sth = $self->dbh->prepare_cached(<<"EOF");
      select constr.conname, to_ns.nspname, to_class.relname, from_col.attname, to_col.attname,
             constr.confdeltype, constr.confupdtype, constr.condeferrable
      from pg_catalog.pg_constraint constr
      join pg_catalog.pg_namespace from_ns on constr.connamespace = from_ns.oid
      join pg_catalog.pg_class from_class on constr.conrelid = from_class.oid and from_class.relnamespace = from_ns.oid
      join pg_catalog.pg_class to_class on constr.confrelid = to_class.oid
      join pg_catalog.pg_namespace to_ns on to_class.relnamespace = to_ns.oid
      -- can't do unnest() until 8.4, so join against a series table instead
      join pg_catalog.generate_series(1, pg_catalog.current_setting('max_index_keys')::integer) colnum(i)
           on colnum.i <= pg_catalog.array_upper(constr.conkey,1)
      join pg_catalog.pg_attribute to_col
           on to_col.attrelid = constr.confrelid
           and to_col.attnum = constr.confkey[colnum.i]
      join pg_catalog.pg_attribute from_col
           on from_col.attrelid = constr.conrelid
           and from_col.attnum = constr.conkey[colnum.i]
      where from_ns.nspname = ?
        and from_class.relname = ?
        and from_class.relkind = 'r'
        and constr.contype = 'f'
      order by constr.conname, colnum.i
EOF

  $sth->execute( $table->schema, $table->name );

  my %rels;

  while (
    my (
      $fk,         $remote_schema, $remote_table, $col,
      $remote_col, $delete_rule,   $update_rule,  $is_deferrable
    )
    = $sth->fetchrow_array
    )
  {
    push @{ $rels{$fk}{local_columns} },  $self->_lc($col);
    push @{ $rels{$fk}{remote_columns} }, $self->_lc($remote_col);

    $rels{$fk}{remote_table} = DBIx::Class::Schema::Loader::Table->new(
      loader => $self,
      name   => $remote_table,
      schema => $remote_schema,
    ) unless exists $rels{$fk}{remote_table};

    $rels{$fk}{attrs} ||= {
      on_delete     => $pg_rules{$delete_rule},
      on_update     => $pg_rules{$update_rule},
      is_deferrable => $is_deferrable,
    };
  }

  return [ map { $rels{$_} } sort keys %rels ];
}

sub _table_uniq_info {
  my ( $self, $table ) = @_;

  # Use the default support if available
  return $self->next::method($table)
    if $DBD::Pg::VERSION >= 1.50;

  my @uniqs;

  # Most of the SQL here is mostly based on
  #   Rose::DB::Object::Metadata::Auto::Pg, after some prodding from
  #   John Siracusa to use his superior SQL code :)

  my $attr_sth = $self->{_cache}->{pg_attr_sth} ||= $self->dbh->prepare(
    q{SELECT attname FROM pg_catalog.pg_attribute
        WHERE attrelid = ? AND attnum = ?}
  );

  my $uniq_sth = $self->{_cache}->{pg_uniq_sth} ||= $self->dbh->prepare(
    q{SELECT x.indrelid, i.relname, x.indkey
        FROM
          pg_catalog.pg_index x
          JOIN pg_catalog.pg_class c ON c.oid = x.indrelid
          JOIN pg_catalog.pg_class i ON i.oid = x.indexrelid
          JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE
          x.indisunique = 't' AND
          x.indpred     IS NULL AND
          c.relkind     = 'r' AND
          i.relkind     = 'i' AND
          n.nspname     = ? AND
          c.relname     = ?
        ORDER BY i.relname}
  );

  $uniq_sth->execute( $table->schema, $table->name );
  while ( my $row = $uniq_sth->fetchrow_arrayref ) {
    my ( $tableid, $indexname, $col_nums ) = @$row;
    $col_nums =~ s/^\s+//;
    my @col_nums = split( /\s+/, $col_nums );
    my @col_names;

    foreach (@col_nums) {
      $attr_sth->execute( $tableid, $_ );
      my $name_aref = $attr_sth->fetchrow_arrayref;
      push( @col_names, $self->_lc( $name_aref->[0] ) ) if $name_aref;
    }

    # skip indexes with missing column names (e.g. expression indexes)
    if ( @col_names == @col_nums ) {
      push( @uniqs, [ $indexname => \@col_names ] );
    }
  }

  return \@uniqs;
}

sub _table_comment {
  my $self = shift;
  my ($table) = @_;

  my $table_comment = $self->next::method(@_);

  return $table_comment if $table_comment;

  ($table_comment) =
    $self->dbh->selectrow_array( <<'EOF', {}, $table->name, $table->schema );
SELECT pg_catalog.obj_description(oid)
FROM pg_catalog.pg_class
WHERE relname=? AND relnamespace=(SELECT oid FROM pg_catalog.pg_namespace WHERE nspname=?)
EOF

  return $table_comment;
}

sub _column_comment {
  my $self = shift;
  my ( $table, $column_number, $column_name ) = @_;

  my $column_comment = $self->next::method(@_);

  return $column_comment if $column_comment;

  return $self->dbh->selectrow_array(
    <<'EOF', {}, $column_number, $table->name, $table->schema );
SELECT pg_catalog.col_description(oid, ?)
FROM pg_catalog.pg_class
WHERE relname=? AND relnamespace=(SELECT oid FROM pg_catalog.pg_namespace WHERE nspname=?)
EOF
}

# Make sure data_type's that don't need it don't have a 'size' column_info, and
# set the correct precision for datetime and varbit types.
sub _columns_info_for {
  my $self = shift;
  my ($table) = @_;

  my ( $result, $raw ) = $self->next::method(@_);
  my %pkeys;

  while ( my ( $col, $info ) = each %$result ) {
    my $data_type = $info->{data_type};

    # these types are fixed size
    # XXX should this be a negative match?
    if ( $data_type =~
/^(?:bigint|int8|bigserial|serial8|bool(?:ean)?|box|bytea|cidr|circle|date|double precision|float8|inet|integer|int|int4|line|lseg|macaddr|money|path|point|polygon|real|float4|smallint|int2|serial|serial4|text)\z/i
      )
    {
      delete $info->{size};
    }

    # for datetime types, check if it has a precision or not
    elsif ( $data_type =~ /^(?:interval|time|timestamp)\b/i ) {
      if ( lc($data_type) eq 'timestamp without time zone' ) {
        $info->{data_type} = 'timestamp';
      }
      elsif ( lc($data_type) eq 'time without time zone' ) {
        $info->{data_type} = 'time';
      }

      my ($precision) = $self->schema->storage->dbh->selectrow_array(
        <<EOF, {}, $table->name, $col );
SELECT datetime_precision
FROM information_schema.columns
WHERE table_name = ? and column_name = ?
EOF

      if ( $data_type =~ /^time\b/i ) {
        if ( ( not defined $precision ) || $precision !~ /^\d/ ) {
          delete $info->{size};
        }
        else {
          my ($integer_datetimes) =
            $self->dbh->selectrow_array('show integer_datetimes');

          my $max_precision = $integer_datetimes =~ /^on\z/i ? 6 : 10;

          if ( $precision == $max_precision ) {
            delete $info->{size};
          }
          else {
            $info->{size} = $precision;
          }
        }
      }
      elsif ( ( not defined $precision )
        || $precision !~ /^\d/
        || $precision == 6 )
      {
        delete $info->{size};
      }
      else {
        $info->{size} = $precision;
      }
    }
    elsif ( $data_type =~ /^(?:bit(?: varying)?|varbit)\z/i ) {
      $info->{data_type} = 'varbit' if $data_type =~ /var/i;

      my ($precision) =
        $self->dbh->selectrow_array( <<EOF, {}, $table->name, $col );
SELECT character_maximum_length
FROM information_schema.columns
WHERE table_name = ? and column_name = ?
EOF

      $info->{size} = $precision if $precision;

      $info->{size} = 1 if ( not $precision ) && lc($data_type) eq 'bit';
    }
    elsif ( $data_type =~ /^(?:numeric|decimal)\z/i
      && ( my $size = $info->{size} ) )
    {
      $size =~ s/\s*//g;

      my ( $scale, $precision ) = split /,/, $size;

      $info->{size} = [ $precision, $scale ];
    }
    elsif ( lc($data_type) eq 'character varying' ) {
      $info->{data_type} = 'varchar';

      if ( not $info->{size} ) {
        $info->{data_type} = 'text';
        $info->{original}{data_type} = 'varchar';
      }
    }
    elsif ( lc($data_type) eq 'character' ) {
      $info->{data_type} = 'char';
    }

    # DBD::Pg < 3.5.2 can get the order wrong on Pg >= 9.1.0
    elsif (
      (
           $DBD::Pg::VERSION >= 3.005002
        or $self->dbh->{pg_server_version} < 90100
      )
      and my $values = $raw->{$col}->{pg_enum_values}
      )
    {
      $info->{extra}{list} = $values;

      # Store its original name in extra for SQLT to pick up.
      $info->{extra}{custom_type_name} = $info->{data_type};

      $info->{data_type} = 'enum';

      delete $info->{size};
    }
    else {
      my ($typetype) =
        $self->schema->storage->dbh->selectrow_array( <<EOF, {}, $data_type );
SELECT typtype
FROM pg_catalog.pg_type
WHERE oid = ?::regtype
EOF
      if ( $typetype && $typetype eq 'e' ) {

        # The following will extract a list of allowed values for the enum.
        my $order_column =
          $self->dbh->{pg_server_version} >= 90100 ? 'enumsortorder' : 'oid';
        $info->{extra}{list} =
          $self->dbh->selectcol_arrayref( <<EOF, {}, $data_type );
SELECT e.enumlabel
FROM pg_catalog.pg_enum e
WHERE e.enumtypid = ?::regtype
ORDER BY e.$order_column
EOF

        # Store its original name in extra for SQLT to pick up.
        $info->{extra}{custom_type_name} = $data_type;

        $info->{data_type} = 'enum';

        delete $info->{size};
      }
    }

    if ( ref( $info->{default_value} ) eq 'SCALAR' ) {

      # process SERIAL columns
      if ( ${ $info->{default_value} } =~ /\bnextval\('([^:]+)'/i ) {
        $info->{is_auto_increment} = 1;
        $info->{sequence}          = $1;
        delete $info->{default_value};
      }

      # alias now() to current_timestamp for deploying to other DBs
      elsif ( lc ${ $info->{default_value} } eq 'now()' ) {

        # do not use a ref to a constant, that breaks Data::Dump output
        ${ $info->{default_value} } = 'current_timestamp';

        my $now = 'now()';
        $info->{original}{default_value} = \$now;
      }
      elsif ( ${ $info->{default_value} } =~ /\bCURRENT_TIMESTAMP\b/ ) {

        # PostgreSQL v10 upcases current_timestamp in default values
        ${ $info->{default_value} } =~ s/\b(CURRENT_TIMESTAMP)\b/lc $1/ge;
      }

  # if there's a default value + it's a primary key, set to retrieve the default
  # on insert even if it's not serial specifically
      if ( !$info->{is_auto_increment} ) {
        %pkeys = map { $_ => 1 } @{ $self->_table_pk_info($table) }
          unless %pkeys;

        if ( $pkeys{$col} ) {
          $info->{retrieve_on_insert} = 1;
        }
      }
    }

    # detect 0/1 for booleans and rewrite
    if ( $data_type =~ /^bool/i && exists $info->{default_value} ) {
      if ( $info->{default_value} eq '0' ) {
        my $false = 'false';
        $info->{default_value} = \$false;
      }
      elsif ( $info->{default_value} eq '1' ) {
        my $true = 'true';
        $info->{default_value} = \$true;
      }
    }
  }

  return $result;
}

sub _view_definition {
  my ( $self, $view ) = @_;

  my $def = $self->schema->storage->dbh->selectrow_array(
    <<'EOF', {}, $view->schema, $view->name );
SELECT pg_catalog.pg_get_viewdef(oid)
FROM pg_catalog.pg_class
WHERE relnamespace = (SELECT OID FROM pg_catalog.pg_namespace WHERE nspname = ?)
AND relname = ?
EOF

  # The definition is returned as a complete statement including the
  # trailing semicolon, but that's not allowed in CREATE VIEW, so
  # strip it out
  $def =~ s/\s*;\s*\z//;
  return $def;
}

=head1 SEE ALSO

L<DBIx::Class::Schema::Loader>, L<DBIx::Class::Schema::Loader::Base>,
L<DBIx::Class::Schema::Loader::DBI>

=head1 AUTHORS

See L<DBIx::Class::Schema::Loader/AUTHORS>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
