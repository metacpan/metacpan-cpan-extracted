package DBIx::DBSchema::DBD::Pg;
use base qw(DBIx::DBSchema::DBD);

use strict;
use DBD::Pg 1.41;

our $VERSION = '0.20';

our %typemap = (
  'BLOB'           => 'BYTEA',
  'LONG VARBINARY' => 'BYTEA',
  'TIMESTAMP'      => 'TIMESTAMP WITH TIME ZONE',
);

=head1 NAME

DBIx::DBSchema::DBD::Pg - PostgreSQL native driver for DBIx::DBSchema

=head1 SYNOPSIS

use DBI;
use DBIx::DBSchema;

$dbh = DBI->connect('dbi:Pg:dbname=database', 'user', 'pass');
$schema = new_native DBIx::DBSchema $dbh;

=head1 DESCRIPTION

This module implements a PostgreSQL-native driver for DBIx::DBSchema.

=cut

sub default_db_schema  { 'public'; }

sub columns {
  my($proto, $dbh, $table) = @_;
  my $sth = $dbh->prepare(<<END) or die $dbh->errstr;
    SELECT a.attname, t.typname, a.attlen, a.atttypmod, a.attnotnull,
           a.atthasdef, a.attnum
    FROM pg_class c, pg_attribute a, pg_type t
    WHERE c.relname = '$table'
      AND a.attnum > 0 AND a.attrelid = c.oid AND a.atttypid = t.oid
    ORDER BY a.attnum
END
  $sth->execute or die $sth->errstr;

  map {

    my $type = $_->{'typname'};
    $type = 'char' if $type eq 'bpchar';

    my $len = '';
    if ( $_->{attlen} == -1 && $_->{atttypmod} != -1 
         && $_->{typname} ne 'text'                  ) {
      $len = $_->{atttypmod} - 4;
      if ( $_->{typname} eq 'numeric' ) {
        $len = ($len >> 16). ','. ($len & 0xffff);
      }
    }

    my $default = '';
    if ( $_->{atthasdef} ) {
      my $attnum = $_->{attnum};
      my $d_sth = $dbh->prepare(<<END) or die $dbh->errstr;
        SELECT substring(d.adsrc for 128) FROM pg_attrdef d, pg_class c
        WHERE c.relname = '$table' AND c.oid = d.adrelid AND d.adnum = $attnum
END
      $d_sth->execute or die $d_sth->errstr;

      $default = $d_sth->fetchrow_arrayref->[0];

      if ( _type_needs_quoting($type) ) {
        $default =~ s/::([\w ]+)$//; #save typecast info?
        if ( $default =~ /^'(.*)'$/ ) {
          $default = $1;
          $default = \"''" if $default eq '';
        } else {
          my $value = $default;
          $default = \$value;
        }
      } elsif ( $default =~ /^[a-z]/i ) { #sloppy, but it'll do
        my $value = $default;
        $default = \$value;
      }

    }

    [
      $_->{'attname'},
      $type,
      ! $_->{'attnotnull'},
      $len,
      $default,
      ''  #local
    ];

  } @{ $sth->fetchall_arrayref({}) };
}

sub primary_key {
  my($proto, $dbh, $table) = @_;
  my $sth = $dbh->prepare(<<END) or die $dbh->errstr;
    SELECT a.attname, a.attnum
    FROM pg_class c, pg_attribute a, pg_type t
    WHERE c.relname = '${table}_pkey'
      AND a.attnum > 0 AND a.attrelid = c.oid AND a.atttypid = t.oid
END
  $sth->execute or die $sth->errstr;
  my $row = $sth->fetchrow_hashref or return '';
  $row->{'attname'};
}

sub unique {
  my($proto, $dbh, $table) = @_;
  my $gratuitous = { map { $_ => [ $proto->_index_fields($dbh, $_ ) ] }
      grep { $proto->_is_unique($dbh, $_ ) }
        $proto->_all_indices($dbh, $table)
  };
}

sub index {
  my($proto, $dbh, $table) = @_;
  my $gratuitous = { map { $_ => [ $proto->_index_fields($dbh, $_ ) ] }
      grep { ! $proto->_is_unique($dbh, $_ ) }
        $proto->_all_indices($dbh, $table)
  };
}

sub _all_indices {
  my($proto, $dbh, $table) = @_;
  my $sth = $dbh->prepare(<<END) or die $dbh->errstr;
    SELECT c2.relname
    FROM pg_class c, pg_class c2, pg_index i
    WHERE c.relname = '$table' AND c.oid = i.indrelid AND i.indexrelid = c2.oid
END
  $sth->execute or die $sth->errstr;
  map { $_->{'relname'} }
    grep { $_->{'relname'} !~ /_pkey$/ }
      @{ $sth->fetchall_arrayref({}) };
}

sub _index_fields {
  my($proto, $dbh, $index) = @_;
  my $sth = $dbh->prepare(<<END) or die $dbh->errstr;
    SELECT a.attname, a.attnum
    FROM pg_class c, pg_attribute a, pg_type t
    WHERE c.relname = '$index'
      AND a.attnum > 0 AND a.attrelid = c.oid AND a.atttypid = t.oid
    ORDER BY a.attnum
END
  $sth->execute or die $sth->errstr;
  map { $_->{'attname'} } @{ $sth->fetchall_arrayref({}) };
}

sub _is_unique {
  my($proto, $dbh, $index) = @_;
  my $sth = $dbh->prepare(<<END) or die $dbh->errstr;
    SELECT i.indisunique
    FROM pg_index i, pg_class c, pg_am a
    WHERE i.indexrelid = c.oid AND c.relname = '$index' AND c.relam = a.oid
END
  $sth->execute or die $sth->errstr;
  my $row = $sth->fetchrow_hashref or die 'guru meditation #420';
  $row->{'indisunique'};
}

#using this
#******** QUERY **********
#SELECT conname,
#  pg_catalog.pg_get_constraintdef(r.oid, true) as condef
#FROM pg_catalog.pg_constraint r
#WHERE r.conrelid = '16457' AND r.contype = 'f' ORDER BY 1;
#**************************

# what's this do?
#********* QUERY **********
#SELECT conname, conrelid::pg_catalog.regclass,
#  pg_catalog.pg_get_constraintdef(c.oid, true) as condef
#FROM pg_catalog.pg_constraint c
#WHERE c.confrelid = '16457' AND c.contype = 'f' ORDER BY 1;
#**************************

sub constraints {
  my($proto, $dbh, $table) = @_;
  my $sth = $dbh->prepare(<<END) or die $dbh->errstr;
    SELECT conname, pg_catalog.pg_get_constraintdef(r.oid, true) as condef
      FROM pg_catalog.pg_constraint r
        WHERE r.conrelid = ( SELECT oid FROM pg_class
                               WHERE relname = '$table'
                                 AND pg_catalog.pg_table_is_visible(oid)
                           )
          AND r.contype = 'f'
END
  $sth->execute;

  map { $_->{condef}
        =~ /^FOREIGN KEY \(([\w\, ]+)\) REFERENCES (\w+)\(([\w\, ]+)\)\s*(.*)$/i
            or die "unparsable constraint: ". $_->{condef};
        my($columns, $table, $references, $etc ) = ($1, $2, $3, $4);
        my $match = ( $etc =~ /MATCH (\w+)/i ) ? "MATCH $1" : '';
        my $on_delete = ( $etc =~ /ON DELETE ((NO |SET )?\w+)/i ) ? $1 : '';
        my $on_update = ( $etc =~ /ON UPDATE ((NO |SET )?\w+)/i ) ? $1 : '';
        +{ 'constraint' => $_->{conname},
           'columns'    => [ split(/,\s*/, $columns) ],
           'table'      => $table,
           'references' => [ split(/,\s*/, $references) ],
           'match'      => $match,
           'on_delete'  => $on_delete,
           'on_update'  => $on_update,
         };
      }
    grep $_->{condef} =~ /^\s*FOREIGN\s+KEY/,
      @{ $sth->fetchall_arrayref( {} ) };
}

sub add_column_callback {
  my( $proto, $dbh, $table, $column_obj ) = @_;
  my $name = $column_obj->name;

  my $pg_server_version = $dbh->{'pg_server_version'};
  my $warning = '';
  unless ( $pg_server_version =~ /\d/ ) {
    $warning = "WARNING: no pg_server_version!  Assuming >= 7.3\n";
    $pg_server_version = 70300;
  }

  my $hashref = { 'sql_after' => [], };

  if ( $column_obj->type =~ /^(\w*)SERIAL$/i ) {

    $hashref->{'effective_type'} = uc($1).'INT';

    #needs more work for old Pg?
      
    my $nextval;
    warn $warning if $warning;
    if ( $pg_server_version >= 70300 ) {
      my $db_schema  = default_db_schema();
      $nextval = "nextval('$db_schema.${table}_${name}_seq'::text)";
    } else {
      $nextval = "nextval('${table}_${name}_seq'::text)";
    }

    push @{ $hashref->{'sql_after'} }, 
      "ALTER TABLE $table ALTER COLUMN $name SET DEFAULT $nextval",
      "CREATE SEQUENCE ${table}_${name}_seq",
      "UPDATE $table SET $name = $nextval WHERE $name IS NULL",
    ;

  }

  if ( ! $column_obj->null ) {
    $hashref->{'effective_null'} = 'NULL';

    warn $warning if $warning;
    if ( $pg_server_version >= 70300 ) {

      push @{ $hashref->{'sql_after'} },
        "ALTER TABLE $table ALTER $name SET NOT NULL";

    } else {

      push @{ $hashref->{'sql_after'} },
        "UPDATE pg_attribute SET attnotnull = TRUE ".
        " WHERE attname = '$name' ".
        " AND attrelid = ( SELECT oid FROM pg_class WHERE relname = '$table' )";

    }

  }

  $hashref;

}

sub alter_column_callback {
  my( $proto, $dbh, $table, $old_column, $new_column ) = @_;
  my $name = $old_column->name;

  my %canonical = (
    'SMALLINT'         => 'INT2',
    'INT'              => 'INT4',
    'BIGINT'           => 'INT8',
    'SERIAL'           => 'INT4',
    'BIGSERIAL'        => 'INT8',
    'DECIMAL'          => 'NUMERIC',
    'REAL'             => 'FLOAT4',
    'DOUBLE PRECISION' => 'FLOAT8',
    'BLOB'             => 'BYTEA',
    'TIMESTAMP'        => 'TIMESTAMPTZ',
  );
  foreach ($old_column, $new_column) {
    $_->type($canonical{uc($_->type)}) if $canonical{uc($_->type)};
  }

  my $pg_server_version = $dbh->{'pg_server_version'};
  my $warning = '';
  unless ( $pg_server_version =~ /\d/ ) {
    $warning = "WARNING: no pg_server_version!  Assuming >= 7.3\n";
    $pg_server_version = 70300;
  }

  my $hashref = {};

  #change type
  if ( ( $canonical{uc($old_column->type)} || uc($old_column->type) )
         ne ( $canonical{uc($new_column->type)} || uc($new_column->type) )
       || $old_column->length ne $new_column->length
     )
  {

    warn $warning if $warning;
    if ( $pg_server_version >= 80000 ) {

      $hashref->{'sql_alter_type'} =
        "ALTER COLUMN ". $new_column->name.
        " TYPE ". $new_column->type.
        ( ( defined($new_column->length) && $new_column->length )
              ? '('.$new_column->length.')'
              : ''
        )

    } else {
      warn "WARNING: can't yet change column types for Pg < version 8\n";
    }

  }

  # change nullability from NOT NULL to NULL
  if ( ! $old_column->null && $new_column->null ) {

    warn $warning if $warning;
    if ( $pg_server_version < 70300 ) {
      $hashref->{'sql_alter_null'} =
        "UPDATE pg_attribute SET attnotnull = FALSE
          WHERE attname = '$name'
            AND attrelid = ( SELECT oid FROM pg_class
                               WHERE relname = '$table'
                           )";
    }

  }

  # change nullability from NULL to NOT NULL...
  # this one could be more complicated, need to set a DEFAULT value and update
  # the table first...
  if ( $old_column->null && ! $new_column->null ) {

    warn $warning if $warning;
    if ( $pg_server_version < 70300 ) {
      $hashref->{'sql_alter_null'} =
        "UPDATE pg_attribute SET attnotnull = TRUE
           WHERE attname = '$name'
             AND attrelid = ( SELECT oid FROM pg_class
                                WHERE relname = '$table'
                            )";
    }

  }

  $hashref;

}

sub column_value_needs_quoting {
  my($proto, $col) = @_;
  _type_needs_quoting($col->type);
}

sub _type_needs_quoting {
  my $type = shift;
  $type !~ m{^(
               int(?:2|4|8)?
             | smallint
             | integer
             | bigint
             | (?:numeric|decimal)(?:\(\d+(?:\s*\,\s*\d+\))?)?
             | real
             | double\s+precision
             | float(?:\(\d+\))?
             | serial(?:4|8)?
             | bigserial
             )$}ix;
}


=head1 AUTHOR

Ivan Kohler <ivan-dbix-dbschema@420.am>

=head1 COPYRIGHT

Copyright (c) 2000 Ivan Kohler
Copyright (c) 2000 Mail Abuse Prevention System LLC
Copyright (c) 2009-2013 Freeside Internet Services, Inc.
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

columns doesn't return column default information.

=head1 SEE ALSO

L<DBIx::DBSchema>, L<DBIx::DBSchema::DBD>, L<DBI>, L<DBI::DBD>

=cut 

1;

