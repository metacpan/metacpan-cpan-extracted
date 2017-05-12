package Alzabo::RDBMSRules::MySQL;

use strict;
use vars qw($VERSION);

use Alzabo::RDBMSRules;

use base qw(Alzabo::RDBMSRules);

$VERSION = 2.0;

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

    Alzabo::Exception::RDBMSRules->throw( error => "Schema name must be at least one character long" )
        unless length $name;

    # These are characters that are illegal in a dir name.  I'm trying
    # to accomodate both Win32 and UNIX here.
    foreach my $c ( qw( : \ / ) )
    {
        Alzabo::Exception::RDBMSRules->throw( error => "Schema name contains an illegal character ($c)" )
            if index($name, $c) != -1;
    }
}

# Note: These rules are valid for MySQL 3.22.x.  MySQL 3.23.x is
# actually less restrictive but this should be enough freedom.

sub validate_table_name
{
    my $self = shift;
    my $name = shift->name;

    Alzabo::Exception::RDBMSRules->throw( error => "Table name must be at least one character long" )
        unless length $name;
    Alzabo::Exception::RDBMSRules->throw( error => "Table name is too long.  Names must be 64 characters or less." )
        if length $name >= 64;
    Alzabo::Exception::RDBMSRules->throw( error => "Table name must only contain alphanumerics or underscore(_)." )
        if $name =~ /\W/;
}

sub validate_column_name
{
    my $self = shift;
    my $name = shift->name;

    Alzabo::Exception::RDBMSRules->throw( error => "Column name must be at least one character long" )
        unless length $name;
    Alzabo::Exception::RDBMSRules->throw( error => 'Name is too long.  Names must be 64 characters or less.' )
        if length $name >= 64;
    Alzabo::Exception::RDBMSRules->throw( error =>
                                          'Name contains characters that are not alphanumeric or the dollar sign ($).' )
        if $name =~ /[^\w\$]/;
    Alzabo::Exception::RDBMSRules->throw( error =>
                                          'Name contains only digits.  Names must contain at least one alpha character.' )
        unless $name =~ /[^\W\d]/;
}

sub validate_column_type
{
    my $self = shift;
    my $type = shift;

    $type = 'INTEGER' if uc $type eq 'INT';

    # Columns which take no modifiers.
    my %simple_types = map {$_ => 1} ( qw( DATE
                                           DATETIME
                                           TIME
                                           TINYBLOB
                                           TINYTEXT
                                           BLOB
                                           TEXT
                                           MEDIUMBLOB
                                           MEDIUMTEXT
                                           LONGBLOB
                                           LONGTEXT
                                           INTEGER
                                           TINYINT
                                           SMALLINT
                                           MEDIUMINT
                                           BIGINT
                                           FLOAT
                                           DOUBLE
                                           REAL
                                           DECIMAL
                                           NUMERIC
                                           TIMESTAMP
                                           CHAR
                                           VARCHAR
                                           YEAR
                                         ),
                                     );

    return uc $type if $simple_types{uc $type};

    return 'DOUBLE' if $type =~ /DOUBLE\s+PRECISION/i;

    return 'CHAR' if $type =~ /\A(?:NATIONAL\s+)?CHAR(?:ACTER)?/i;
    return 'VARCHAR' if $type =~ /\A(?:NATIONAL\s+)?(?:VARCHAR|CHARACTER VARYING)/i;

    my $t = $self->_capitalize_type($type);
    return $t if $t;

    Alzabo::Exception::RDBMSRules->throw( error => "Unrecognized type: $type" );
}

sub _capitalize_type
{
    my $self = shift;
    my $type = shift;

    if ( uc substr($type, 0, 4) eq 'ENUM' )
    {
        return 'ENUM' . substr($type, 4);
    }
    elsif ( uc substr($type, 0, 3) eq 'SET' )
    {
        return 'SET' . substr($type, 3);
    }
    else
    {
        return uc $type;
    }
}

sub validate_column_length
{
    my $self = shift;
    my $column = shift;

    # integer column
    if ( $column->type =~ /\A(?:(?:(?:TINY|SMALL|MEDIUM|BIG)?INT)|INTEGER)/i )
    {
        Alzabo::Exception::RDBMSRules->throw( error => "Max display value is too long.  Maximum allowed value is 255." )
            if defined $column->length && $column->length > 255;

        Alzabo::Exception::RDBMSRules->throw( error => $column->type . " columns cannot have a precision." )
            if defined $column->precision;
        return;
    }

    if ( $column->type =~ /\A(?:FLOAT|DOUBLE(?:\s+PRECISION)?|REAL)/i )
    {
        if (defined $column->length)
        {
            Alzabo::Exception::RDBMSRules->throw( error => "Max display value is too long.  Maximum allowed value is 255." )
                if $column->length > 255;

            Alzabo::Exception::RDBMSRules->throw( error => "Max display value specified without floating point precision." )
                unless defined $column->precision;

            Alzabo::Exception::RDBMSRules->throw( error =>
                                                  "Floating point precision is too high.  The maximum value is " .
                                                  "30 or the maximum display size - 2, whichever is smaller." )
                if $column->precision > 30 || $column->precision > ($column->length - $column->precision);
        }

        return;
    }

    if ( $column->type =~ /\A(?:DECIMAL|NUMERIC)\z/i )
    {
        Alzabo::Exception::RDBMSRules->throw( error => "Max display value is too long.  Maximum allowed value is 255." )
            if defined $column->length && $column->length > 255;
        Alzabo::Exception::RDBMSRules->throw( error =>
                                              "Floating point precision is too high.  The maximum value is " .
                                              "30 or the maximum display size - 2, whichever is smaller." )
            if defined $column->precision && ($column->precision > 30 || $column->precision > ($column->length - 2) );
        return;
    }

    if ( uc $column->type eq 'TIMESTAMP' )
    {
        Alzabo::Exception::RDBMSRules->throw( error => "Max display value is too long.  Maximum allowed value is 14." )
            if defined $column->length && $column->length > 14;
        Alzabo::Exception::RDBMSRules->throw( error => $column->type . " columns cannot have a precision." )
            if defined $column->precision;
        return;
    }

    if ( $column->type =~ /\A(?:(?:NATIONAL\s+)?VAR)?(?:CHAR|BINARY)/i )
    {
        Alzabo::Exception::RDBMSRules->throw( error => "(VAR)CHAR and (VAR)BINARY columns must have a length provided." )
            unless defined $column->length && $column->length > 0;
        Alzabo::Exception::RDBMSRules->throw( error => "Max display value is too long.  Maximum allowed value is 255." )
            if $column->length > 255;
        Alzabo::Exception::RDBMSRules->throw( error => $column->type . " columns cannot have a precision." )
            if defined $column->precision;
        return;
    }

    if ( uc $column->type eq 'YEAR' )
    {
        Alzabo::Exception::RDBMSRules->throw( error => "Valid values for the length specification are 2 or 4." )
            if defined $column->length && ($column->length != 2 && $column->length != 4);
        return;
    }

    Alzabo::Exception::RDBMSRules->throw( error => $column->type . " columns cannot have a length or precision." )
        if defined $column->length || defined $column->precision;
}

# placeholder in case we decide to try to do something better later
sub validate_table_attribute { 1 }

sub validate_column_attribute
{
    my $self = shift;
    my %p = @_;

    my $column = $p{column};
    my $a = uc $p{attribute};
    $a =~ s/\A\s//;
    $a =~ s/\s\z//;

    if ( $a eq 'UNSIGNED' || $a eq 'ZEROFILL' )
    {
        Alzabo::Exception::RDBMSRules->throw( error => "$a attribute can only be applied to numeric columns" )
            unless $column->is_numeric;
        return;
    }

    if ( $a eq 'AUTO_INCREMENT' )
    {
        Alzabo::Exception::RDBMSRules->throw( error => "$a attribute can only be applied to integer columns" )
            unless $column->is_integer;
        return;
    }

    if ($a eq 'BINARY')
    {
        Alzabo::Exception::RDBMSRules->throw( error => "$a attribute can only be applied to character columns" )
            unless $column->is_character;
        return;
    }

    return if $a =~ /\A(?:REFERENCES|UNIQUE\z)/i;

    Alzabo::Exception::RDBMSRules->throw( error => "Unrecognized attribute: $a" );
}

sub validate_primary_key
{
    my $self = shift;
    my $col = shift;

    Alzabo::Exception::RDBMSRules->throw( error => 'Blob columns cannot be part of a primary key' )
        if $col->type =~ /\A(?:TINY|MEDIUM|LONG)?(?:BLOB|TEXT)\z/i;
}

sub validate_sequenced_attribute
{
    my $self = shift;
    my $col = shift;

    Alzabo::Exception::RDBMSRules->throw( error => 'Non-integer columns cannot be sequenced' )
        unless $col->is_integer;

    Alzabo::Exception::RDBMSRules->throw( error => 'Only one sequenced column per table is allowed.' )
        if grep { $_ ne $col && $_->sequenced } $col->table->columns;
}

sub validate_index
{
    my $self = shift;
    my $index = shift;

    foreach my $c ( $index->columns )
    {
        my $prefix = $index->prefix($c);
        if (defined $prefix)
        {
            Alzabo::Exception::RDBMSRules->throw( error => "Invalid prefix specification ('$prefix')" )
                unless $prefix =~ /\d+/ && $prefix > 0;

            Alzabo::Exception::RDBMSRules->throw( error => 'Non-character/blob columns cannot have an index prefix' )
                unless $c->is_blob || $c->is_character || $c->type =~ /^(?:VAR)BINARY$/i;
        }

        if ( $c->is_blob )
        {
            Alzabo::Exception::RDBMSRules->throw( error => 'Blob columns must have an index prefix' )
                unless $prefix || $index->fulltext;
        }

        if ( $index->fulltext )
        {
            Alzabo::Exception::RDBMSRules->throw( error => 'A fulltext index can only include text or char columns' )
                unless $c->is_character;
        }
    }

    Alzabo::Exception::RDBMSRules->throw( error => 'An fulltext index cannot be unique' )
        if $index->unique && $index->fulltext;

    Alzabo::Exception::RDBMSRules->throw( error => 'MySQL does not support function indexes' )
        if defined $index->function;
}

sub type_is_integer
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type =~ /\A(?:(?:TINY|SMALL|MEDIUM|BIG)?INT|INTEGER)\z/;
}

sub type_is_floating_point
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type =~ /\A(?:DECIMAL|NUMERIC|FLOAT|DOUBLE|REAL)\z/;
}

sub type_is_char
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type =~ /(?:CHAR|TEXT)\z/;
}

sub type_is_date
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type =~ /\A(?:DATE|DATETIME|TIMESTAMP)\z/;
}

sub type_is_datetime
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    if ( $type eq 'TIMESTAMP' )
    {
        # default length is 14
        return 1 unless defined $col->length;
        return $col->length > 8;
    }

    return 1 if $type eq 'DATETIME';
}

sub type_is_time
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    if ( $type eq 'TIMESTAMP' )
    {
        return $col->length > 8;
    }

    return 1 if $type =~ /\A(?:DATETIME|TIME)\z/;
}

sub type_is_time_interval { 0 }

sub type_is_blob
{
    my $self = shift;
    my $col  = shift;
    my $type = uc $col->type;

    return 1 if $type =~ /BLOB\z/;
}

sub blob_type { return 'BLOB' }

sub column_types
{
    return qw( TINYINT
               SMALLINT
               MEDIUMINT
               INTEGER
               BIGINT

               FLOAT
               DOUBLE
               DECIMAL
               NUMERIC

               CHAR
               VARCHAR

               DATE
               DATETIME
               TIME
               TIMESTAMP
               YEAR

               TINYTEXT
               TEXT
               MEDIUMTEXT
               LONGTEXT

               TINYBLOB
               BLOB
               MEDIUMBLOB
               LONGBLOB
             );
}

my %features = map { $_ => 1 } qw ( extended_column_types
                                    index_prefix
                                    fulltext_index
                                    allows_raw_default
                                  );
sub feature
{
    shift;
    return $features{+shift};
}

sub schema_sql
{
    my $self = shift;
    my $schema = shift;

    my @sql;

    foreach my $t ( map { $self->_clean_table_name($_) } $schema->tables )
    {
        push @sql, $self->table_sql($t);
    }

    # This has to come at the end because we don't which tables
    # reference other tables.
    foreach my $t ( $schema->tables )
    {
        foreach my $fk ( $t->all_foreign_keys )
        {
            push @sql, $self->foreign_key_sql($fk);
        }
    }

    return @sql;
}

sub _clean_table_name
{
    if ( $_[1] =~ /(?:`\w+`\.)?`(\w+)`/ )
    {
        return $1;
    }

    return $_[1];
}

sub table_sql
{
    my $self = shift;
    my $table = shift;

    my $sql = "CREATE TABLE " . $table->name . " (\n  ";

    $sql .= join ",\n  ", map { $self->column_sql($_) } $table->columns;

    if (my @pk = $table->primary_key)
    {
        $sql .= ",\n";
        $sql .= '  PRIMARY KEY (';
        $sql .= join ', ', map {$_->name} @pk;
        $sql .= ")";

        $sql .= "\n";
    }
    $sql .= ")";

    if (my @att = $table->attributes)
    {
        $sql .= ' ';
        $sql .= join ' ', @att;
    }

    my @sql = ($sql);
    foreach my $i ( $table->indexes )
    {
        push @sql, $self->index_sql($i);
    }

    return @sql;
}

sub column_sql
{
    my $self = shift;
    my $col = shift;
    my $p = shift; # for skip_name

    # make sure each one only happens once
    my %attr = map { uc $_ => $_ } ( $col->attributes,
                                     ($col->nullable ? 'NULL' : 'NOT NULL'),
                                     ($col->sequenced ? 'AUTO_INCREMENT' : () ) );

    # unsigned attribute has to come right after type declaration,
    # same with binary.  No column could have both.
    my @unsigned = $attr{UNSIGNED} ? delete $attr{UNSIGNED} : ();
    my @binary   = $attr{BINARY} ? delete $attr{BINARY} : ();

    my @default;
    if ( defined $col->default )
    {
        my $def = $self->_default_for_column($col);

        @default = ( qq|DEFAULT $def| );
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

    my @name = $p->{skip_name} ? () : $col->name;
    my $sql .= join '  ', ( @name,
                            $type,
                            @unsigned,
                            @binary,
                            @default,
                            sort values %attr );

    return $sql;
}

sub index_sql
{
    my $self = shift;
    my $index = shift;

    return if $self->{state}{index_sql}{ $index->id };

    my $index_name = $self->_make_index_name( $index->id );

    my $sql = 'CREATE';
    $sql .= ' UNIQUE' if $index->unique;
    $sql .= ' FULLTEXT' if $index->fulltext;
    $sql .= " INDEX $index_name ON " . $index->table->name . ' ( ';

    $sql .= join ', ', ( map { my $sql = $_->name;
                               $sql .= '(' . $index->prefix($_) . ')' if $index->prefix($_);
                               $sql; } $index->columns );

    $sql .= ' )';

    return $sql;
}

sub _default_for_column
{
    my $self = shift;
    my $col = shift;

    return $col->default if $col->is_numeric || $col->default_is_raw;

    my $d = $col->default;
    $d =~ s/"/""/g;
    return qq|"$d"|;
}

sub _make_index_name
{
    shift;
    return substr(shift, 0, 64);
}

sub foreign_key_sql
{
    # Bah, no ON UPDATE SET DEFAULT
    return;

    my $self = shift;
    my $fk = shift;

    if ( grep { $_->is_primary_key } $fk->columns_from )
    {
        return unless $fk->from_is_dependent;
    }

    my @indexes;
    foreach my $part ( qw( from to ) )
    {
        my $found_index;

        my $col_meth = "columns_$part";
        my @cols = $fk->$col_meth();

        my $table_meth = "table_$part";

    INDEX:
        foreach my $i ( $fk->$table_meth()->indexes )
        {
            my @c = $i->columns;

            next unless @c == @cols;

            for ( 0..$#c )
            {
                next INDEX unless $c[$_]->name eq $cols[$_]->name;
            }

            $found_index = 1;
            last;
        }

        unless ($found_index)
        {
            push @indexes, $fk->$table_meth()->make_index( columns => [ @cols ] );
        }
    }

    my $sql = 'ALTER TABLE ';
    $sql .= $fk->table_from->name;
    $sql .= ' ADD FOREIGN KEY ( ';
    $sql .= join ', ', map { $_->name } $fk->columns_from;
    $sql .= ' ) REFERENCES `';
    $sql .= $fk->table_to->name;
    $sql .= '`( ';
    $sql .= join ', ', map { $_->name } $fk->columns_to;
    $sql .= ' ) ON DELETE ';

    if ( $fk->from_is_dependent )
    {
        $sql .= 'CASCADE';
    }
    else
    {
        my @to = $fk->columns_to;
        unless ( ( grep { $_->nullable } @to ) == @to )
        {
            $sql .= 'SET DEFAULT';
        }
        else
        {
            $sql .= 'SET NULL';
        }
    }

    $sql .= ' ON UPDATE CASCADE';

    return ( map { $self->index_sql($_) } @indexes ), $sql;
}

sub drop_column_sql
{
    my $self = shift;
    my %p = @_;

    return 'ALTER TABLE ' . $p{new_table}->name . ' DROP COLUMN ' . $p{old}->name;
}

sub drop_foreign_key_sql
{
    return;
}

sub drop_index_sql
{
    my $self = shift;
    my $index = shift;
    # table name may have changed.
    my $table_name = shift;

    return 'DROP INDEX ' . $self->_make_index_name( $index->id ) . " ON $table_name";
}

sub column_sql_add
{
    my $self = shift;
    my $col = shift;

    my $sequenced = 0;
    if ( ($sequenced = $col->sequenced) )
    {
        $col->set_sequenced(0);
    }

    my $new_sql = $self->column_sql($col);

    if ($sequenced)
    {
        $col->set_sequenced(1);
    }

    return 'ALTER TABLE ' . $col->table->name . ' ADD COLUMN ' . $new_sql;
}

sub column_sql_diff
{
    my $self = shift;
    my %p = @_;
    my $new = $p{new};
    my $old = $p{old};

    my $sequenced = 0;
    if ( ( $sequenced = $new->sequenced ) && ! $old->sequenced )
    {
        $new->set_sequenced(0);
    }

    my $new_default = $new->default;
    $new->set_default(undef)
        if $self->_can_ignore_default( uc $new->type, $new_default );

    my $new_sql = $self->column_sql( $new, { skip_name => 1 } );

    $new->set_sequenced(1) if $sequenced;
    $new->set_default($new_default) if defined $new_default;

    my $old_default = $old->default;
    $old->set_default(undef)
        if $self->_can_ignore_default( uc $old->type, $new_default );
    my $old_sql = $self->column_sql( $old, { skip_name => 1 } );
    $old->set_default($old_default) if defined $old_default;

    my @sql;
    if ( $new_sql ne $old_sql ||
         ( $new->sequenced && ! $old->sequenced ) )
    {
        my $sql =
            ( 'ALTER TABLE ' . $new->table->name . ' CHANGE COLUMN ' .
              $new->name . ' ' . $new->name . ' ' . $new_sql
            );

        # can't have more than 1 auto_increment column per table (dumb!)
        if ( ( $new->sequenced && ! $old->sequenced ) &&
             ! grep { $_ ne $new && $_->sequenced } $new->table->columns )
        {
            $sql .= ' AUTO_INCREMENT' if $new->sequenced && ! $old->sequenced;
        }

        push @sql, $sql;
    }

    return @sql;
}

sub alter_primary_key_sql
{
    my $self = shift;
    my %p = @_;

    my $new = $p{new};
    my $old = $p{old};

    my @sql;
    push @sql, 'ALTER TABLE ' . $new->name . ' DROP PRIMARY KEY'
        if $old->primary_key;

    if ( $new->primary_key )
    {
        my $sql = 'ALTER TABLE  ' . $new->name . ' ADD PRIMARY KEY ( ';
        $sql .= join ', ', map {$_->name} $new->primary_key;
        $sql .= ')';

        push @sql, $sql;
    }

    foreach ( $new->primary_key )
    {
        if ( $_->sequenced &&
             ! ( $old->has_column( $_->name ) &&
                 $old->column( $_->name )->is_primary_key ) )
        {
            my $sql = $self->column_sql($_);
            push @sql,
                'ALTER TABLE ' . $new->name . ' CHANGE COLUMN ' . $_->name . ' ' . $sql;
        }
    }

    return @sql;
}

sub alter_table_name_sql
{
    my $self = shift;
    my $table = shift;

    return 'RENAME TABLE ' . $table->former_name . ' TO ' . $table->name;
}

sub alter_table_attributes_sql
{
    my $self = shift;
    my %p = @_;

    # This doesn't work right if new table has no attributes
    return;

    return 'ALTER TABLE ' . $p{new}->name . ' ' . join ' ', $p{new}->attributes;
}

sub alter_column_name_sql
{
    my $self = shift;
    my $column = shift;

    return
        ( 'ALTER TABLE ' . $column->table->name . ' CHANGE COLUMN ' .
          $column->former_name . ' ' . $self->column_sql($column)
        );
}

sub reverse_engineer
{
    my $self = shift;
    my $schema = shift;

    my $driver = $schema->driver;

    my $has_table_types =
        $driver->one_row( sql  => 'SHOW VARIABLES LIKE ?',
                          bind => 'table_type' );

    foreach my $table ( $driver->tables )
    {
        my $table_name = $self->_clean_table_name($table);

        my $t = $schema->make_table( name => $table_name );

        foreach my $row ( $driver->rows( sql => "DESCRIBE $table" ) )
        {
            my ($type, @a);
            if ( $row->[1] =~ /\A(?:ENUM|SET)/i )
            {
                $type = $row->[1];
            }
            else
            {
                ($type, @a) = split /\s+/, $row->[1];
            }

            my $default = $row->[4] if defined $row->[4] && uc $row->[4] ne 'NULL';

            my $seq = 0;
            foreach my $a ( split /\s+/, $row->[5] )
            {
                if ( uc $a eq 'AUTO_INCREMENT' )
                {
                    $seq = 1;
                }
                else
                {
                    push @a, $a;
                }
            }

            my %p;
            if ( $type !~ /ENUM|SET/i
                 && $type =~ /(\w+)\((\d+)(?:\s*,\s*(\d+))?\)$/ )
            {
                $type = uc $1;
                $type = 'INTEGER' if $type eq 'INT';

                # skip defaults
                unless ( $type eq 'TINYINT' && ( $2 == 4 || $2 == 3 ) ||
                         $type eq 'SMALLINT' && ( $2 == 6 || $2 == 5 ) ||
                         $type eq 'MEDIUMINT' && ( $2 == 9 || $2 == 8 ) ||
                         $type eq 'INTEGER' && ( $2 == 11 || $2 == 10 )  ||
                         $type eq 'BIGINT' && ( $2 == 21 || $2 == 20 ) ||
                         $type eq 'YEAR' && $2 == 4 ||
                         $type eq 'TIMESTAMP' && $2 == 14
                       )
                {
                    $p{length} = $2;
                    $p{precision} = $3;
                }
            }

            $type = $self->_capitalize_type($type);

            $default = undef
                if $self->_can_ignore_default( $type, $default );

            my $c = $t->make_column( name => $row->[0],
                                     type => $type,
                                     nullable => $row->[2] eq 'YES',
                                     sequenced => $seq,
                                     default => $default,
                                     attributes => \@a,
                                     primary_key => $row->[3] eq 'PRI',
                                     %p,
                                   );
        }

        my %i;
        foreach my $row ( $driver->rows( sql => "SHOW INDEX FROM $table" ) )
        {
            next if $row->[2] eq 'PRIMARY';

            my $type_i = $driver->major_version >= 4 ? 10 : 9;
            $i{ $row->[2] }{fulltext} =
                $row->[$type_i] && $row->[$type_i] =~ /fulltext/i ? 1 : 0;

            $i{ $row->[2] }{cols}[ $row->[3] - 1 ]{column} = $t->column( $row->[4] );
            if ( defined $row->[7] )
            {
                # MySQL (at least 4.0.17) reports a sub_part of 1 for
                # the second column of a fulltext index.
                if ( ! $i{ $row->[2] }{fulltext} || $row->[7] > 1 )
                {
                    $i{ $row->[2] }{cols}[ $row->[3] - 1 ]{prefix} = $row->[7]
                }
            }

            $i{ $row->[2] }{unique} = $row->[1] ? 0 : 1;

        }

        foreach my $index (keys %i)
        {
            $t->make_index( columns  => $i{$index}{cols},
                            unique   => $i{$index}{unique},
                            fulltext => $i{$index}{fulltext} );
        }

        if ( $has_table_types )
        {
            my $table_type =
                ( $driver->one_row( sql  => 'SHOW TABLE STATUS LIKE ?',
                                    bind => $table_name ) )[1];

            $t->add_attribute( 'TYPE=' . uc $table_type );
        }
    }
}

my %ignored_defaults = ( DATETIME => '0000-00-00 00:00:00',
                         DATE => '0000-00-00',
                         YEAR => '0000',
                         CHAR => '',
                         VARCHAR => '',
                         TINTYTEXT => '',
                         SMALLTEXT => '',
                         MEDIUMTEXT => '',
                         TEXT => '',
                         LONGTEXT => '',
                       );

sub _can_ignore_default
{
    my $self = shift;
    my $type = shift;
    my $default = shift;

    return 1 unless defined $default;

    return 1
        if exists $ignored_defaults{$type} && $default eq $ignored_defaults{$type};

    if ( $type eq 'DECIMAL' )
    {
        return 1 if $default =~ /0\.0+/;
    }

    if ( $type =~ /INT/ )
    {
        return 1 unless $default;
    }

    return 0;
}

sub rules_id
{
    return 'MySQL';
}

1;

__END__

=head1 NAME

Alzabo::RDBMSRules::MySQL - MySQL specific database rules.

=head1 SYNOPSIS

  use Alzabo::RDBMSRules::MySQL;

=head1 DESCRIPTION

This module implements all the methods descibed in Alzabo::RDBMSRules
for the MySQL database.  The syntax rules follow the more restrictive
rules of version 3.22.

=head1 AUTHOR

Dave Rolsky, <dave@urth.org>

=cut
