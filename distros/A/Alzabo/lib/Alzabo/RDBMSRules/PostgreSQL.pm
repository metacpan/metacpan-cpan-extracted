package Alzabo::RDBMSRules::PostgreSQL;

use strict;
use vars qw($VERSION);

use Alzabo::Exceptions ( abbr => [ 'recreate_table_exception' ] );
use Alzabo::RDBMSRules;

use Digest::MD5;

use Text::Balanced ();

use base qw(Alzabo::RDBMSRules);

use Params::Validate qw( validate_pos );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );

$VERSION = 2.0;

1;

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    return bless {}, $class;
}

sub validate_schema_name
{
    my $self = shift;
    my $name = shift->name;

    $self->_check_name($name, 'schema');

    Alzabo::Exception::RDBMSRules->throw( error => "Schema name ($name) contains a single quote char (')" )
        if index($name, "'") != -1;
}

sub validate_table_name
{
    my $self = shift;

    $self->_check_name( shift->name, 'table' );
}

sub validate_column_name
{
    my $self = shift;

    $self->_check_name( shift->name, 'column' );
}

sub _check_name
{
    my $self = shift;
    my $name = shift;

    Alzabo::Exception::RDBMSRules->throw( error => "Name ($name) must be at least one character long" )
        unless length $name;
    Alzabo::Exception::RDBMSRules->throw( error => "Name ($name) is too long.  Names must be 31 characters or less." )
        if length $name > 31;
    Alzabo::Exception::RDBMSRules->throw( error => "Name ($name) must start with an alpha or underscore(_) and must contain only alphanumerics and underscores." )
        unless $name =~ /\A[a-zA-Z]\w*\z/;
}

sub validate_column_type
{
    my $self = shift;
    my $type = uc shift;
    my $table = shift;

    if ( $table->primary_key_size > 1 )
    {
        return 'INT4' if $type =~ /^SERIAL4?$/;
        return 'INT8' if $type eq 'BIGSERIAL' or $type eq 'SERIAL8';
    }

    my %simple_types = map { $_ => 1 } qw( ABSTIME
                                           BIT
                                           BIGINT
                                           BIGSERIAL
                                           BOOL
                                           BOOLEAN
                                           BOX
                                           BYTEA
                                           CHAR
                                           CHARACTER
                                           CIDR
                                           CIRCLE
                                           DATE
                                           DECIMAL
                                           FLOAT
                                           FLOAT4
                                           FLOAT8
                                           INET
                                           SMALLINT
                                           INT
                                           INTEGER
                                           INT2
                                           INT4
                                           INT8
                                           INTERVAL
                                           MACADDR
                                           MONEY
                                           NUMERIC
                                           OID
                                           RELTIME
                                           SERIAL
                                           SERIAL4
                                           SERIAL8
                                           TEXT
                                           TIME
                                           TIMESTAMP
                                           TIMESTAMPTZ
                                           TIMETZ
                                           VARBIT
                                           VARCHAR );

    return 'INTEGER' if $type eq 'INT' || $type eq 'INT4';
    return 'SERIAL' if $type eq 'SERIAL4';
    return 'INT8' if $type eq 'BIGINT';

    return $type if $simple_types{$type};

    return $type if $type =~ /BIT\s+VARYING/;

    return $type if $type =~ /CHARACTER\s+VARYING/;

    return $type if $type =~ /\ABOX|CIRCLE|LINE|LSEG|PATH|POINT|POLYGON/;

    Alzabo::Exception::RDBMSRules->throw( error => "Invalid column type: $type" );
}

sub validate_column_length
{
    my $self = shift;
    my $column = shift;

    if ( defined $column->length )
    {
        Alzabo::Exception::RDBMSRules->throw( error => "Length is not supported except for char, varchar, decimal, float, and numeric columns (" . $column->name . " column)" )
            unless $column->type =~ /\A(?:(?:VAR)?CHAR|CHARACTER|DECIMAL|FLOAT|NUMERIC|(?:VAR)?BIT|BIT VARYING)\z/i;
    }

    if ( defined $column->precision )
    {
        Alzabo::Exception::RDBMSRules->throw( error => "Precision is not supported except for decimal, float, and numeric columns" )
            unless $column->type =~ /\A(?:DECIMAL|FLOAT|NUMERIC)\z/i;
    }
}

# placeholder in case we decide to try to do something better later
sub validate_table_attribute { 1 }

sub validate_column_attribute
{
    my $self = shift;
    my %p = @_;

    my $column = $p{column};
    my $type = $column->type;
    my $a = uc $p{attribute};
    $a =~ s/\A\s//;
    $a =~ s/\s\z//;

    return if  $a =~ /\A(?:UNIQUE\z|CHECK|CONSTRAINT|REFERENCES)/i;

    Alzabo::Exception::RDBMSRules->throw( error => "Only column constraints are supported as column attributes" )
}

sub validate_primary_key
{
    my $self = shift;
    my $col = shift;

    my $serial_col = (grep { $_->type =~ /^(?:SERIAL(?:4|8)?|BIGSERIAL)$/ } $col->table->primary_key)[0];
    if ( defined $serial_col &&
         $serial_col->name ne $col->name )
    {
        $serial_col->set_type( $serial_col->type =~ /^SERIAL4?$/
                               ? 'INT4'
                               : 'INT8' );
    }
}

sub validate_sequenced_attribute
{
    my $self = shift;
    my $col = shift;

    Alzabo::Exception::RDBMSRules->throw( error => 'Non-number columns cannot be sequenced' )
        unless $col->is_integer || $col->is_floating_point;
}

sub validate_index
{
    my $self = shift;
    my $index = shift;

    foreach my $c ( $index->columns )
    {
        Alzabo::Exception::RDBMSRules->throw( error => "PostgreSQL does not support index prefixes" )
            if defined $index->prefix($c)
    }

    Alzabo::Exception::RDBMSRules->throw( error => "PostgreSQL does not support fulltext indexes" )
        if $index->fulltext;
}

sub type_is_integer
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type =~ /\A(?:
                             INT(?:2|4|8)?|
                             SMALLINT|
                             INTEGER|
                             OID|
                             SERIAL(?:4|8)?|
                             BIGSERIAL
                            )
                          \z
                         /x;
}

sub type_is_floating_point
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type =~ /\A(?:
                             DECIMAL|
                             FLOAT(?:4|8)?|
                             MONEY|
                             NUMERIC
                            )
                          \z
                         /x;
}

sub type_is_char
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type =~ /(?:CHAR|CHARACTER|TEXT)\z/;
}

sub type_is_date
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type eq 'DATE' || $self->type_is_datetime($col);
}

sub type_is_datetime
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type =~ /^TIMESTAMP/;
}

sub type_is_time
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type eq 'TIME';
}

sub type_is_time_interval
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type eq 'INTERVAL';
}

sub type_is_blob
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type =~ /\ABYTEA\z/;
}

sub blob_type { return 'BYTEA' }

sub column_types
{
    return ( qw( INTEGER
                 INT2
                 INT8
                 NUMERIC
                 FLOAT
                 FLOAT4

                 CHAR
                 VARCHAR
                 TEXT

                 BYTEA

                 DATE
                 TIME
                 TIMESTAMP
                 INTERVAL

                 SERIAL
                 BIGSERIAL

                 BOOLEAN

                 BIT
               ),
               'BIT VARYING',

             qw( INET
                 CIDR
                 MACADDR ) );
}

my %features = map { $_ => 1 } qw ( extended_column_types
                                    constraints
                                    functional_indexes
                                    allows_raw_default
                                  );
sub feature
{
    shift;
    return $features{+shift};
}

sub quote_identifiers { 1 }

sub quote_identifiers_character { '"' }

sub schema_sql
{
    my $self = shift;

    validate_pos( @_, { isa => 'Alzabo::Schema' } );

    my $schema = shift;

    my @sql = $self->SUPER::schema_sql($schema);

    # This has to come at the end because we don't know which tables
    # reference other tables.
    foreach my $t ( $schema->tables )
    {
        foreach my $con ( grep { /\s*(?:check|constraint)/i } $t->attributes )
        {
            push @sql, $self->table_constraint_sql($t);
        }


        foreach my $fk ( $t->all_foreign_keys )
        {
            push @sql, $self->foreign_key_sql($fk);
        }
    }

    return @sql;
}

sub table_sql
{
    my $self = shift;
    my $table = shift;

    my $create_sequence = shift;

    # Create table sequence by default
    $create_sequence = 1 unless defined $create_sequence;

    my $sql = qq|CREATE TABLE "| . $table->name . qq|" (\n  |;

    $sql .= join ",\n  ", map { $self->column_sql($_) } $table->columns;

    my @att = $table->attributes;

    if (my @pk = $table->primary_key)
    {
        $sql .= ",\n";
        $sql .= '  PRIMARY KEY (';
        $sql .= join ', ', map { '"' . $_->name . '"' } @pk;
        $sql .= ")\n";
    }

    $sql .= ")\n";

    my @sql = ($sql);

    foreach my $i ( $table->indexes )
    {
        push @sql, $self->index_sql($i);
    }

    if ($create_sequence)
    {
        foreach my $c ( grep { $_->sequenced } $table->columns )
        {
            push @sql, $self->_sequence_sql($c);
        }
    }

    if (@att)
    {
        $sql .= ' ';
        $sql .= join ' ', grep { ! /\s*(?:check|constraint)/i } @att;
    }

    $self->{state}{table_sql}{ $table->name } = 1;

    return @sql;
}

sub _sequence_sql
{
    my $self = shift;
    my $col = shift;

    return if $col->type =~ /^(?:SERIAL(?:4|8)?|BIGSERIAL)$/;

    my $seq_name = $self->_sequence_name($col);

    return qq|CREATE SEQUENCE "$seq_name";\n|;
}

sub _sequence_name
{
    my $self = shift;
    my $col = shift;

    return join '___', $col->table->name, $col->name;
}

sub column_sql
{
    my $self = shift;
    my $col = shift;
    my $p = shift;   # hashref for skip_nullable, skip_default, && skip_name

    my @default;
    if ( ! $p->{skip_default} && defined $col->default )
    {
        my $def = $self->_default_for_column($col);

        @default = ( "DEFAULT $def" );
    }

    my $type = $col->type;
    my @length;
    if ( defined $col->length )
    {
        my $length = '(' . $col->length;
        $length .= ', ' . $col->precision if defined $col->precision;
        $length .= ')';
        $type .= $length;
    }

    my @nullable;
    unless ( $p->{skip_nullable} )
    {
        @nullable = $col->nullable ? 'NULL' : 'NOT NULL';
    }

    my @name = $p->{skip_name} ? () : '"' . $col->name . '"';

    my $sql .= join '  ', ( @name,
                            $type,
                            @default,
                            @nullable,
                            $col->attributes );

    return $sql;
}

sub _default_for_column
{
    my $self = shift;
    my $col = shift;

    return unless defined $col->default;

    return $col->default if $col->is_numeric || $col->default_is_raw;

    my $d = $col->default;
    $d =~ s/'/''/g;
    qq|'$d'|;
}

sub foreign_key_sql
{
    my $self = shift;
    my $fk = shift;

    if ( grep { $_->is_primary_key } $fk->columns_from )
    {
        return unless $fk->from_is_dependent;
    }

    return () if $self->{state}{fk_sql}{ $fk->id };

    my $sql = 'ALTER TABLE "';
    $sql .= $fk->table_from->name;
    $sql .= '" ADD CONSTRAINT ';
    $sql .= $self->_fk_name($fk);
    $sql .= ' FOREIGN KEY ( ';
    $sql .= join ', ', map { '"' . $_->name . '"' } $fk->columns_from;
    $sql .= ' ) REFERENCES "';
    $sql .= $fk->table_to->name;
    $sql .= '" (';
    $sql .= join ', ', map { '"' . $_->name . '"' } $fk->columns_to;
    $sql .= ')';
    $sql .= ' ON DELETE ';

    if ( $fk->from_is_dependent )
    {
        $sql .= 'CASCADE';
    }
    else
    {
        my @from = $fk->columns_from;
        unless ( ( grep { $_->nullable } @from ) == @from )
        {
            $sql .= 'SET DEFAULT';
        }
        else
        {
            $sql .= 'SET NULL';
        }
    }

    $self->{state}{fk_sql}{ $fk->id } = 1;

    return $sql;
}

sub _fk_name
{
    my $id = $_[1]->id;

    return
        ( length $id > 63
          ? 'fk_' . Digest::MD5::md5_hex( $_[1]->id )
          : $id
        );
}

sub table_constraint_sql
{
    my $self = shift;
    my $table = shift;

    return map { 'ALTER TABLE "' . $table->name . '" ADD ' . $_ } $table->attributes;
}

sub drop_table_sql
{
    my $self = shift;
    my $table = shift;
    my $is_recreate = shift;

    my @sql;

    if ($is_recreate)
    {
        # We need to drop foreign keys referring to this table before
        # we drop it.
        foreach my $fk ( $table->all_foreign_keys )
        {
            push @sql, $self->drop_foreign_key_sql( $fk->reverse );
        }
    }

    push @sql, $self->SUPER::drop_table_sql($table);

    unless ($is_recreate)
    {
        foreach my $c ( $table->columns )
        {
            push @sql, $self->_drop_sequence_sql($c) if $c->sequenced;
        }
    }

    return @sql;
}

sub _drop_sequence_sql
{
    my $self = shift;
    my $col = shift;

    return if $col->type =~ /^(?:SERIAL(?:4|8)?|BIGSERIAL)$/;

    my $seq_name = $self->_sequence_name($col);

    return qq|DROP SEQUENCE "$seq_name";\n|;
}

sub drop_column_sql
{
    my $self = shift;
    my %p = @_;

    recreate_table_exception();
}

sub recreate_table_sql
{
    my $self = shift;
    my %p = @_;

    # This is a hack to prevent this SQL from being made multiple
    # times (which would be pointless)
    return () if $self->{state}{table_sql}{ $p{new}->name };

    push @{ $self->{state}{deferred_sql} },
        $self->_restore_foreign_key_sql( $p{new} );

    return ( $self->_temp_table_sql( $p{new}, $p{old} ),
             $self->drop_table_sql( $p{old}, 1 ),
             # the 0 param indicates that we should not create sequences
             $self->table_sql( $p{new}, 0 ),
             $self->_restore_table_data_sql( $p{new}, $p{old} ),
             $self->_drop_temp_table( $p{new} ),
           );

}

sub _temp_table_sql
{
    my $self = shift;
    my $new_table = shift;
    my $old_table = shift;

    my $temp_name = "TEMP" . $new_table->name;

    my $sql = "SELECT ";
    $sql .= join ', ', map { '"' . $_->name . '"' } $old_table->columns;
    $sql .= qq|\n INTO TEMPORARY "$temp_name" FROM "| . $old_table->name . '"';

    return $sql;
}

sub _restore_table_data_sql
{
    my $self = shift;
    my $new_table = shift;
    my $old_table = shift;

    my @cols;
    foreach my $column ( $new_table->columns )
    {
        my $old_name =
            defined $column->former_name ? $column->former_name : $column->name;

        push @cols, [ $column->name, $old_name ]
            if $old_table->has_column($old_name);
    }

    my $temp_name = "TEMP" . $new_table->name;

    my $sql = 'INSERT INTO "' . $new_table->name . '" (';
    $sql .= join ', ', map { qq|"$_->[0]"| } @cols;
    $sql .= " ) \n  SELECT ";
    $sql .= join ', ', map { qq|"$_->[1]"| } @cols;
    $sql .= qq| FROM "$temp_name"|;

    return $sql;
}

sub _drop_temp_table
{
    my $self = shift;
    my $table = shift;

    my $temp_name = "TEMP" . $table->name;

    return qq|DROP TABLE "$temp_name"|;
}

sub _restore_foreign_key_sql
{
    my $self = shift;
    my $table = shift;

    my @sql;
    foreach my $fk ( $table->all_foreign_keys )
    {
        push @sql, $self->foreign_key_sql($fk);
        push @sql, $self->foreign_key_sql( $fk->reverse );
    }

    return @sql;
}

sub rename_sequences
{
    my $self = shift;
    my %p = @_;

    return () if $self->{state}{rename_sequence_sql}{ $p{new}->name };

    my @sql;

    for my $old_col ( grep { $_->sequenced } $p{old}->columns )
    {
        my $new_col = $p{new}->column( $old_col->name )
            or next;

        my $old_seq = $self->_sequence_name($old_col);
        my $new_seq = $self->_sequence_name($new_col);

        push @sql,
            qq|ALTER TABLE "$old_seq" RENAME TO "$new_seq";\n|;
    }

    $self->{state}{rename_sequence_sql}{ $p{new}->name } = 1;

    return @sql;
}

sub drop_foreign_key_sql
{
    my $self = shift;
    my $fk = shift;

    if ( grep { $_->is_primary_key } $fk->columns_from )
    {
        return unless $fk->from_is_dependent;
    }

    return () if $self->{state}{drop_fk_sql}{ $fk->id };

    $self->{state}{drop_fk_sql}{ $fk->id } = 1;

    return 'ALTER TABLE "' . $fk->table_from->name . '" DROP CONSTRAINT '
           . $self->_fk_name($fk);
}

sub drop_index_sql
{
    my $self = shift;
    my $index = shift;

    return 'DROP INDEX "' . $index->id . '"';
}

sub column_sql_add
{
    my $self = shift;
    my $col = shift;

    return () if $self->{state}{table_sql}{ $col->table->name };

    # Skip default and not null while adding column
    my @sql = 'ALTER TABLE "' . $col->table->name . '" ADD COLUMN ' . $self->column_sql($col, { skip_default => 1, skip_nullable => 1 });

    my $def = $self->_default_for_column($col);
    if ($def)
    {
        push @sql,
            ( 'ALTER TABLE "' . $col->table->name . '" ALTER COLUMN "' .
              $col->name . qq|" SET DEFAULT $def| );
    }

    if ( ! $col->nullable )
    {
        push @sql,
            ( 'UPDATE "' . $col->table->name
              . '" SET "' . $col->name . qq|" = $def WHERE "|
              . $col->name . '" IS NULL'
            );

        push @sql,
            ( 'ALTER TABLE "' . $col->table->name
              . '" ADD CONSTRAINT "'
              . $col->table->name . '_' . $col->name . '_not_null" CHECK ( "'
              . $col->name . '" IS NOT NULL )'
            );
    }

    return @sql;
}

sub column_sql_diff
{
    my $self = shift;
    my %p = @_;

    return $self->drop_column_sql( new_table => $p{new}->table,
                                   old => $p{old} )
        unless $self->_columns_are_equivalent( $p{new}, $p{old} );

    return;
}

sub _columns_are_equivalent
{
    my $self = shift;
    my $new = shift;
    my $old = shift;

    return 0 unless $self->_types_are_equivalent( $new, $old );

    return 0 unless $self->_defaults_are_equivalent( $new, $old );

    return 0 unless $new->sequenced == $old->sequenced;

    my $new_att = join "\0", sort $new->attributes;
    $new_att ||= '';

    my $old_att = join "\0", sort $old->attributes;
    $old_att ||= '';

    return 0 unless $new_att eq $old_att;

    return 1;
}

{
    my %CanonicalTypes =
        ( BOOL    => 'BOOLEAN',
          INT     => 'INTEGER',
          INT4    => 'INTEGER',
          INT2    => 'SMALLINT',
          INT8    => 'BIGINT',
          VARBIT  => 'BIT VARYING',
          VARCHAR => 'CHARACTER VARYING',
          CHAR    => 'CHARACTER',
          FLOAT   => 'DOUBLE PRECISION',
          FLOAT8  => 'DOUBLE PRECISION',
          FLOAT4  => 'REAL',
          DECIMAL => 'NUMERIC',
        );

    sub _types_are_equivalent
    {
        shift;
        my $col1 = shift;
        my $col2 = shift;

        my $type1 = $col1->type;
        $type1 = $CanonicalTypes{ uc $type1 } if $CanonicalTypes{ uc $type1 };

        my $type2 = $col2->type;
        $type2 = $CanonicalTypes{ uc $type2 } if $CanonicalTypes{ uc $type2 };

        $type1 .= join '-', grep { defined && length } $col1->length, $col1->precision;
        $type2 .= join '-', grep { defined && length } $col1->length, $col1->precision;

        return 1 if $type1 eq $type2;
    }
}

sub _defaults_are_equivalent
{
    my $self = shift;
    my $col1 = shift;
    my $col2 = shift;

    return 1 if ! defined $col1->default && ! defined $col2->default;
    return 0 if defined $col1->default && ! defined $col2->default;
    return 0 if ! defined $col1->default && defined $col2->default;

    if ( $col1->type =~ /^bool/i )
    {
        return 1
            if lc substr( $col1->default, 0, 1 ) eq lc substr( $col2->default, 0, 1 );
        return 0;
    }
    elsif ( $col1->is_date
            && $col1->default_is_raw
            && $col2->default_is_raw )
    {
        my $d1 = $col1->default;
        my $d2 = $col2->default;

        my $re = qr/^(?:current_timestamp|localtime|localtimestamp|now\(\))$/i;
        return 1
            if $col1->default =~ /$re/
            && $col2->default =~ /$re/;
    }

    return 1 if
        $self->_default_for_column($col1) eq $self->_default_for_column($col2);
}

sub alter_primary_key_sql
{
    my $self = shift;
    my %p = @_;

    my @sql;
    push @sql, 'DROP INDEX "' . $p{old}->name . '_pkey"';

    if ( $p{new}->primary_key )
    {
        push @sql, ( 'CREATE UNIQUE INDEX "' . $p{new}->name . '_pkey" ON "' .
                     $p{new}->name . '" (' .
                     ( join ', ',
                       map { '"' . $_->name . '"' } $p{new}->primary_key ) . ')' );
    }

    return @sql;
}

# Actually, Postgres _can_ change table names, but it's inability to
# change most aspects of a column definition make it very difficult to
# properly change a table name and then change its column definitions,
# so its easier just to recreate the table
sub can_alter_table_name
{
    0;
}

# Not sure if this is possible
sub alter_table_attributes_sql
{
    my $self = shift;

    recreate_table_exception();
}

sub alter_column_name_sql
{
    my $self = shift;
    my $column = shift;

    return
        ( 'ALTER TABLE "' . $column->table->name . '" RENAME COLUMN ' .
          $column->former_name . ' TO ' . $column->name
        );
}

sub reverse_engineer
{
    my $self = shift;
    my $schema = shift;

    my $driver = $schema->driver;

    foreach my $table ( $driver->tables )
    {
        $table =~ s/^[^\.]+\.//;
        $table =~ s/^\"|\"$//g;

        print STDERR "Adding table $table to schema\n"
            if Alzabo::Debug::REVERSE_ENGINEER;

        my $t = $schema->make_table( name => $table );

        my $t_oid = $driver->one_row( sql => 'SELECT oid FROM pg_class WHERE relname = ?',
                                      bind => $table );

        my $sql = <<'EOF';
SELECT a.attname, a.attnotnull, t.typname, a.attnum, a.atthasdef, a.atttypmod
FROM pg_attribute a, pg_type t
WHERE a.attrelid = ?
AND a.atttypid = t.oid
AND a.attnum > 0
EOF

        $sql .= ' AND NOT a.attisdropped' if $driver->rdbms_version ge '7.3';

        $sql .= ' ORDER BY attnum';


        my %cols_by_number;
        foreach my $row ( $driver->rows( sql => $sql,
                                         bind => $t_oid ) )
        {
            my %p;

            $p{type} = $row->[2];

            # has default
            if ( $row->[4] )
            {
                $p{default} =
                    $driver->one_row
                        ( sql => 'SELECT adsrc FROM pg_attrdef WHERE adrelid = ? AND adnum = ?',
                          bind => [ $t_oid, $row->[3] ] );

                if ( $p{default} =~ /^nextval\(/ )
                {
                    $p{sequenced} = 1;
                    $p{type} =~ s/(?:int(?:eger)?|numeric)/serial/;
                }
                else
                {
                    # strip quotes (and type!) Postgres added
                    $p{default} =~ s/^'//; #'
                    if ( $driver->rdbms_version ge '7.4' )
                    {
                        # 'grotesque' becomes 'grotesque'::character
                        # varying. See
                        # src/backend/utils/adt/format_type.c

                        # This is from
                        # src/backend/util/adt/format_type.c
                        $p{default} =~ s/'(?:::[^']{3,})?$//;
                        $p{default} =~ s/\('(\w+)$/$1/;
                    }
                    else
                    {
                        $p{'default'} =~ s/'$//;
                    }

                    if ( $p{default} =~ /\([^\)]*\)/
                         || $p{default} =~ /^(?:current_timestamp|localtime|localtimestamp|now)$/i )
                    {
                        $p{default_is_raw} = 1;
                    }

                    $p{default} = 'now()' if $p{default} eq 'now';
                }
            }

            if ( $p{type} =~ /char/i )
            {
                # The real length is the value of: a.atttypmod - ((int32) sizeof(int32))
                #
                # Sure wish I knew how to figure this out in Perl.
                # Its provided as VARHDRSZ in postgres.h but I can't
                # really get at it.  On my linux machine this is 4.  A
                # better way of doing this would be welcome.
                $p{length} = $row->[5] - 4;
            }
            if ( lc $p{type} eq 'numeric' )
            {
                # see comment above.
                my $num = $row->[5] - 4;
                $p{length} = ($num >> 16) & 0xffff;
                $p{precision} = $num & 0xffff;
            }

            $p{type} = 'char' if lc $p{type} eq 'bpchar';

            print STDERR "Adding $row->[0] column to $table\n"
                if Alzabo::Debug::REVERSE_ENGINEER;

            my $col = $t->make_column( name => $row->[0],
                                       nullable => ! $row->[1],
                                       %p
                                     );

            if ( $col->is_integer )
            {
                if ( $self->_re_sequence_exists( $driver, $col ) )
                {
                    $col->set_sequenced(1);
                }
            }

            $cols_by_number{ $row->[3] } = $row->[0];
        }


        $sql = <<'EOF';
SELECT indkey
FROM pg_index
WHERE indisprimary
AND indrelid = ?
EOF

        foreach my $cols ( $driver->column( sql => $sql,
                                           bind => $t_oid ) )
        {
	    my @cols = @cols_by_number{ split ' ', $cols };
	    local $" = ", ";

	    print STDERR "Setting @cols as primary key for $table\n"
 		if Alzabo::Debug::REVERSE_ENGINEER;

	    $t->add_primary_key( $_ ) for $t->columns( @cols );
        }

	my %i;
	if ( $driver->rdbms_version ge '7.4' )
	{
            %i = $self->_74_indexes( $driver, $t, $t_oid, \%cols_by_number );
	}
        else
        {
            %i = $self->_pre_74_indexes( $driver, $t, $t_oid, \%cols_by_number );
 	}

	foreach my $idx (values %i)
 	{
	    my @c = map { { column => $_ } } @{ $idx->{cols} };

	    print STDERR "Adding index "
		. ( defined $idx->{'function'}
		    ? $idx->{'function'}
		    : join(', ', map $_->name, @{$idx->{'cols'}} ) )
		. " to $table\n"
		if Alzabo::Debug::REVERSE_ENGINEER;

 	    $t->make_index( columns  => \@c,
			    unique   => $idx->{unique},
                            function => $idx->{function},
                          );
        }

        $sql = <<'EOF';
SELECT consrc, array_to_string(conkey,' ')
FROM pg_constraint
WHERE conrelid = ?
AND contype = 'c'
EOF

        my @att;

        foreach my $row ( $driver->rows( sql => $sql,
                                         bind => $t_oid ) )
        {
            my ( $con, $cols ) = @$row;

            # this stuff is not needed
            $con =~ s/::(\w+)//g;

	    # If $cols ever covers more than one value then this will fail.
            if ( $cols =~ /^(\d+)$/ )
            {
                my $column = $cols_by_number{$1};

                print STDERR qq|Adding constraint "$con" to $table.$column\n|
                    if Alzabo::Debug::REVERSE_ENGINEER;

                $t->column($column)->add_attribute("CHECK $con");
            }
            else
            {
                print STDERR qq|Adding constraint "$con" to $table\n|
                    if Alzabo::Debug::REVERSE_ENGINEER;

                $t->add_attribute("CHECK $con");
            }
        }

    }

    # Foreign key info is available in PG 7.3.0 and higher (could fake
    # it from pg_triggers with extensive gymnastics in version 7.0 and
    # higher, but that's a little iffy)
    $self->_foreign_keys_to_relationships($schema)
        if $driver->rdbms_version ge '7.3';
}

sub _re_sequence_exists
{
    my $self = shift;
    my $driver = shift;
    my $col = shift;

    my $seq_name = $self->_sequence_name($col);

    my $sql = <<'EOF';
SELECT 1
  FROM pg_class
 WHERE relname = ?
   AND relkind = ?
EOF

    return $driver->one_row( sql  => $sql,
                             bind => [ $seq_name, 'S' ],
                           );
}

sub _74_indexes
{
    my $self   = shift;
    my $driver = shift;
    my $table  = shift;
    my $t_oid  = shift;
    my $cols_by_number  = shift;

    my $sql = <<'EOF';
SELECT indexrelid, indisunique, indkey, indnatts
FROM pg_index
WHERE indrelid = ?
AND NOT indisprimary
EOF

    my %i;
   INDEX:
    foreach my $row ( $driver->rows( sql => $sql,
                                     bind => $t_oid ) )
    {
        my $function;
        my @col_numbers;

        my $spi =
            $driver->one_row
                ( sql => "SELECT COALESCE(indexprs,'') FROM pg_index WHERE indexrelid = ?",
                  bind => $row->[0] );

        if ( $spi )
        {
          SPI_EXPRESSION:
            while ( my $spi_expr =
                    Text::Balanced::extract_bracketed( $spi, '{}', '[^{}]*' ) )
            {
                # A wanton lack of respect for boundaries. 'Parse' the
                # PostgreSQL internal SPI language to find out what
                # columns are being accessed.
                push( @col_numbers,
                      join( ' ',
                            $spi_expr =~ /:varattno (\d+)/g ) );
            }
        }

        if ( scalar( @col_numbers ) > 1 )
        {
            # Index objects are not prepared to handle functional
            # indexes that use more than one function.
            die "Alzabo " . Alzabo->VERSION . " does not support functional"
                . " indexes that are not strictly a single function."
                . "  There are multiple functions on an index on the "
                . $table->name() . " table.\n";
        }
        elsif ( scalar( @col_numbers ) == 1 )
        {
            my $func =
                $driver->one_row
                    ( sql => 'SELECT pg_catalog.pg_get_indexdef( ?, 1, true)',
                      bind => $row->[0] );

            # XXX - not sure if this is a good idea but it makes the
            # rev-eng tests pass
            $func =~ s/\b(\w+)::\w+\b/$1/g;
            my $col_in_func = $1;

            my @function;
            for my $num ( split / +/, $row->[2] )
            {
                if ( $num == 0 )
                {
                    push @function, $func;
                }
                else
                {
                    push @function, $cols_by_number->{$num};
                    push @col_numbers, $num;
                }
            }

            $function = join ', ', @function;
        }
        else
        {
            # A regular index!
            @col_numbers = split / +/, $row->[2];
        }

        push( @{ $i{ $row->[0] }{cols} },
              $table->columns( @{ $cols_by_number }{ @col_numbers } ) );

        $i{ $row->[0] }{function} = $function;
        $i{ $row->[0] }{unique} = $row->[1];
    }

    return %i;
}

sub _pre_74_indexes
{
    my $self   = shift;
    my $driver = shift;
    my $table  = shift;
    my $t_oid  = shift;
    my $cols_by_number  = shift;

    my $sql = <<'EOF';
SELECT c.oid, a.attname, i.indisunique, i.indproc, i.indkey
FROM pg_index i, pg_attribute a, pg_class c
WHERE i.indrelid = ?
AND NOT i.indisprimary
AND i.indexrelid = c.oid
AND c.oid = a.attrelid
AND a.attnum > 0
ORDER BY a.attnum
EOF

    my %i;
    foreach my $row ( $driver->rows( sql => $sql,
                                     bind => $t_oid ) )
    {
        my @col_names = @{ $cols_by_number }{ split ' ', $row->[4] };

        my $function;
        if ( $row->[3] && $row->[3] =~ /\w/ && $row->[3] ne '-' )
        {
            # some function names come out as "pg_catalog.foo"
            $row->[3] =~ s/\w+\.(\w+)/$1/;
            $function = uc $row->[3];
            $function .= '(';

            $function .= join ', ', @col_names;

            $function .= ')';
        }

        push( @{ $i{ $row->[0] }{cols} },
              $table->columns( @col_names ) );

        $i{ $row->[0] }{unique} = $row->[2];
        $i{ $row->[0] }{function} = $function;
    }

    return %i;
}

sub _foreign_keys_to_relationships
{
    my ($self, $schema) = @_;
    my $driver = $schema->driver;

    my $constraint_sql = <<'EOF';
SELECT conrelid, confrelid,
    array_to_string(conkey,' '),
    array_to_string(confkey,' ')
FROM pg_constraint
WHERE contype = 'f'
EOF

    my $table_sql = <<'EOF';
SELECT relname
FROM pg_class
WHERE oid = ?
EOF

    my $column_sql = <<'EOF';
SELECT attname
FROM pg_attribute
WHERE attrelid = ?
  AND attnum = ?
EOF

    foreach my $row ( $driver->rows( sql => $constraint_sql ) )
    {
        my $from_table = $driver->one_row( sql => $table_sql,
                                           bind => $row->[0] );
        my $to_table   = $driver->one_row( sql => $table_sql,
                                           bind => $row->[1] );

	# Column numbers are given as strings like "3 5"
	my @from_cols = split ' ', $row->[2]
 	    or die "Weird column specification $row->[2]";

	my @to_cols   = split ' ', $row->[3]
 	    or die "Weird column specification $row->[3]";

        # Convert column numbers to names
        foreach (@from_cols)
        {
            $_ = $driver->one_row( sql => $column_sql,
                                   bind => [$row->[0], $_] );
        }
        foreach (@to_cols)
        {
            $_ = $driver->one_row( sql => $column_sql,
                                   bind => [$row->[1], $_] );
        }

        print STDERR "Adding $from_table foreign key to $to_table\n"
            if Alzabo::Debug::REVERSE_ENGINEER;

        # Convert to Alzabo objects
        $from_table = $schema->table($from_table);
        $to_table   = $schema->table($to_table);
        @from_cols = map { $from_table->column($_) } @from_cols;
        @to_cols   = map {   $to_table->column($_) } @to_cols;

        # If there's a unique constraint on the "from" columns, treat
        # is as 1-to-1.  Otherwise treat it as n-to-1.
        my $from_unique = 0;

        # Only use PK as determination of uniqueness if the FK is from
        # the _whole_ PK to something else.  If the FK only includes
        # _part_ of the PK then it is not unique.
        $from_unique = 1
            if ( ( @from_cols == grep { $_->is_primary_key } @from_cols )
                 &&
                 ( @from_cols == $from_table->primary_key_size ) );

        $from_unique = 1
            if @from_cols == grep { $_->has_attribute( attribute => 'UNIQUE' ) } @from_cols;

      INDEX:
        foreach my $i ( grep { $_->unique } $from_table->indexes )
        {
            my @i_cols = $i->columns;

            next unless @i_cols == @from_cols;

            for ( my $x = 0; $x < @i_cols; $x++ )
            {
                next INDEX unless $i_cols[$x] eq $from_cols[$x];
            }

            $from_unique = 1;
        }

        my $from_cardinality = $from_unique ? '1' : 'n';

        my $from_is_dependent =
            ( grep { $_->nullable || defined $_->default } @from_cols ) ? 0 : 1;
        my $to_is_dependent =
            ( grep { $_->nullable || $_->is_primary_key } @to_cols ) ? 0 : 1;

        $schema->add_relationship( cardinality => [ $from_cardinality, '1' ],
                                   table_from => $from_table,
                                   table_to   => $to_table,
                                   columns_from => \@from_cols,
                                   columns_to   => \@to_cols,
                                   from_is_dependent => $from_is_dependent,
                                   to_is_dependent => $to_is_dependent,
                                 );
    }
}

sub rules_id
{
    return 'PostgreSQL';
}

__END__

=head1 NAME

Alzabo::RDBMSRules::PostgreSQL - PostgreSQL specific database rules

=head1 SYNOPSIS

  use Alzabo::RDBMSRules::PostgreSQL;

=head1 DESCRIPTION

This module implements all the methods descibed in Alzabo::RDBMSRules
for the PostgreSQL database.  The syntax rules follow those of the 7.0
releases.  Older versions may work but are not supported.

=head1 AUTHOR

Dave Rolsky, <dave@urth.org>

=cut
