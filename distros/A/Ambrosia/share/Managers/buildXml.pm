package Managers::buildXml;
use strict;
use warnings;

use Cwd qw/abs_path/;

use Ambrosia::Config;
use Ambrosia::error::Exceptions;
use Ambrosia::DataProvider;
use Ambrosia::Context;

use Ambrosia::Meta;

class sealed
{
    extends => [qw/Ambrosia::BaseManager/],
    private => [qw/__tableIdInc/],
};

our $VERSION = 0.010;

sub _init
{
    $_[0]->__tableIdInc = 1;
}

sub prepare
{
    my $self = shift;
    Context->repository->set( schema_list => [] );
    storage->foreach(\&processDataSource, $self);

    my $path_to_app = config->ProjectPath;
    if ( $path_to_app )
    {
        $path_to_app =~ s{/[^/]+$}{};
    }
    else
    {
        $path_to_app = '';
    }

    my $projectName = config()->ID;
    my $message = <<MESSAGE;

#######################################################################
#
#   ADL file ${projectName}.xml has been created successfully.
#
#   Now you can additionally edit ${projectName}.xml and run:
#   ambrosia -c ${projectName}.conf -d ${projectName}.xml -a xml2app
#
#######################################################################

MESSAGE

    chomp(my $hostname = `hostname`);
    Context->repository->set( config => {
            name     => config->ID,
            label    => config->Label,
            charset  => lc(config->Charset || 'utf-8'),
            hostname => config->hostname || $hostname,

            ServerName => config->ServerName,
            ServerPort => config->ServerPort,

            ProjectPath => abs_path($path_to_app),
            PerlLibPath => join(' ', map {abs_path($_)} split /\s+/, config->PerlLibPath),
        } );
    Context->repository->set( Message => $message );
}

sub getDataSource
{
    my $t = shift;
    my $sn = shift;
    if ( ref config->data_source->{$t} eq 'ARRAY' )
    {
        foreach ( @{config->data_source->{$t}} )
        {
            return $_ if $_->{source_name} eq $sn;
        }
        throw Ambrosia::error::Exception::BadParams "Error: cannot find in config data_source source_name=$sn in type = $t";
    }
    elsif( config->data_source->{$t}->{source_name} eq $sn )
    {
        return config->data_source->{$t};
    }
    else
    {
        throw Ambrosia::error::Exception::BadParams "Error: cannot find in config data_source source_name=$sn in type = $t";
    }
}

sub processDataSource
{
    my $driver = shift;
    my $type = shift;
    my $source_name = shift;
    my $self = shift;

    my $schema_list = Context->repository->get( 'schema_list' );
    my $schema = {type => $type,
                  ($driver->catalog ? (catalog => $driver->catalog) : ()),
                  schema => $driver->schema,
                  tables => [],
                  config => {} };
    push @$schema_list, $schema;

    my $ds = getDataSource($type, $source_name);

    $schema->{config} = {
        db_engine   => $ds->{engine_name},
        db_source   => $source_name,
        db_params   => $ds->{engine_params},
        db_user     => $ds->{user},
        db_password => $ds->{password},
        db_charset  => (config->data_source_info->{$type}->{$source_name}->{charset} || 'utf8'),
    };

    my $tables = table_info($driver);
    my %hTables = ();

    my %foreign_keys = ();
    foreach ( @{foreign_key_info($driver)} )
    {
        push @{$foreign_keys{$_->{pktable_name}}}, {
            fktable_name => $_->{fktable_name},
            pkcolumn_name => $_->{pkcolumn_name},
            fkcolumn_name => $_->{fkcolumn_name},
            key_seq       => $_->{key_seq},
        };
    }

    foreach my $t ( @$tables )
    {
        my %primary_keys = ();
        foreach ( @{primary_key_info($driver, $t->{table_name})} )
        {
            $primary_keys{$_->{column_name}} = $_->{key_seq};
        }
        my $hasPK = scalar keys %primary_keys;

        my %table = (tId => $self->__tableIdInc++);
        $table{type} = uc $t->{table_type};
        $table{name} = $t->{table_name};
        if ( my $has_one = $foreign_keys{$table{name}} )
        {
            $table{has_one} = $has_one;
        }

        if ( $hasPK == 1 )
        {
            $table{AUTO_UNIQUE_VALUE} = scalar keys %primary_keys == 1;
            $table{KEY} = 1;
        }
        elsif( $hasPK )
        {
            $table{KEY} = 1;
        }
        elsif( $table{has_one} )
        {
            $table{KEY} = 1;
        }

        my $columns = column_info($driver, $t->{table_name});
        my $tablePK = 0;
        $table{column} = [ map {
                my $cn = $_->{column_name};
                my $h = {
                    Default => $_->{column_def}||'',
                    Size    => $_->{column_size}||'',
                    Name    => $_->{column_name}||'',
                    Remarks => $_->{remarks}||'',
                    DecimalDigits => $_->{decimal_digits}||'',
                    IsNullable    => $_->{is_nullable}||'',
                    Type     => $_->{type_name}||'',
                };
                if ($_->{sql}->[-3] && $_->{sql}->[-3] =~ /unsigned/ )
                {
                    $h->{Unsigned} = 'YES';
                }
                if ( my $seq = $primary_keys{$cn} )
                {
                    $tablePK = 1;
                    $h->{primary_key} = $seq;
                    $h->{Hidden} = "YES";
                }

                if ( !$tablePK && $table{has_one}
                    && ( my $i = (grep { $cn eq $_->{pkcolumn_name} } @{$table{has_one}})[0] ) )
                {
                    $h->{Hidden} = "YES";
                    $h->{foreign_key} = $i->{key_seq};
                }
                $h;
            } sort {
                ($primary_keys{$b->{column_name}} || 0) <=> ($primary_keys{$b->{column_name}} || 0)
                ||
                $a->{ordinal_position} <=> $b->{ordinal_position} } @$columns ];
        push @{$schema->{tables}}, \%table;
        $hTables{$t->{table_name}} = \%table;
    }

    foreach ( keys %foreign_keys)
    {
        foreach ( @{$foreign_keys{$_}} )
        {
            $_->{fId} = $hTables{$_->{fktable_name}}->{tId};
        }
    }
}

sub table_info
{
    my $driver = shift;

    my @tables = ();
    my $sth = $driver->table_info('');
    while ( my ($table_cat, $table_schem, $table_name, $table_type, $remarks,) = $sth->fetchrow_array )
    {
        my %h;
        @h{qw/table_cat table_schem table_name table_type remarks/} = (
            $table_cat, $table_schem, $table_name, $table_type, $remarks, );

        push @tables, \%h;
    }
    $sth->finish;
    return \@tables;
}

sub SQL_NO_NULLS()         { 0 }
sub SQL_NULLABLE()         { 1 }
sub SQL_NULLABLE_UNKNOWN() { 2 }


#=rem
#TABLE_CAT: The catalog identifier. This field is NULL (undef) if not applicable to the data source, which is often the case. This field is empty if not applicable to the table.
#TABLE_SCHEM: The schema identifier. This field is NULL (undef) if not applicable to the data source, and empty if not applicable to the table.
#TABLE_NAME: The table identifier. Note: A driver may provide column metadata not only for base tables, but also for derived objects like SYNONYMS etc.
#COLUMN_NAME: The column identifier.
#DATA_TYPE: The concise data type code.
#TYPE_NAME: A data source dependent data type name.
#COLUMN_SIZE: The column size. This is the maximum length in characters for character data types, the number of digits or bits for numeric data types or the length in the representation of temporal types. See the relevant specifications for detailed information.
#BUFFER_LENGTH: The length in bytes of transferred data.
#DECIMAL_DIGITS: The total number of significant digits to the right of the decimal point.
#NUM_PREC_RADIX: The radix for numeric precision. The value is 10 or 2 for numeric data types and NULL (undef) if not applicable.
#NULLABLE: Indicates if a column can accept NULLs. The following values are defined:
#  SQL_NO_NULLS          0
#  SQL_NULLABLE          1
#  SQL_NULLABLE_UNKNOWN  2
#REMARKS: A description of the column.
#COLUMN_DEF: The default value of the column, in a format that can be used directly in an SQL statement.
#Note that this may be an expression and not simply the text used for the default value in the original CREATE TABLE statement. For example, given:
#    col1 char(30) default current_user    -- a 'function'
#    col2 char(30) default 'string'        -- a string literal
#where "current_user" is the name of a function, the corresponding COLUMN_DEF values would be:
#    Database        col1                     col2
#    --------        ----                     ----
#    Oracle:         current_user             'string'
#    Postgres:       "current_user"()         'string'::text
#    MS SQL:         (user_name())            ('string')
#SQL_DATA_TYPE: The SQL data type.
#SQL_DATETIME_SUB: The subtype code for datetime and interval data types.
#CHAR_OCTET_LENGTH: The maximum length in bytes of a character or binary data type column.
#ORDINAL_POSITION: The column sequence number (starting with 1).
#IS_NULLABLE: Indicates if the column can accept NULLs. Possible values are: 'NO', 'YES' and ''.
#SQL/CLI defines the following additional columns:
#  CHAR_SET_CAT
#  CHAR_SET_SCHEM
#  CHAR_SET_NAME
#  COLLATION_CAT
#  COLLATION_SCHEM
#  COLLATION_NAME
#  UDT_CAT
#  UDT_SCHEM
#  UDT_NAME
#  DOMAIN_CAT
#  DOMAIN_SCHEM
#  DOMAIN_NAME
#  SCOPE_CAT
#  SCOPE_SCHEM
#  SCOPE_NAME
#  MAX_CARDINALITY
#  DTD_IDENTIFIER
#  IS_SELF_REF
#=cut

sub column_info
{
    my $driver = shift;
    my $table = shift;
    my $sth = $driver->column_info($table, '');
    my @columns = ();
    while ( my (
                $table_cat, $table_schem, $table_name, $column_name, $data_type,
                $type_name, $column_size, $buffer_length, $decimal_digits, $num_prec_radix,
                $nullable, $remarks, $column_def, $sql_data_type, $sql_datetime_sub,
                $char_octet_length, $ordinal_position, $is_nullable,@SQL
#SQL/CLI
                ) = $sth->fetchrow_array )
    {
        my %h;
        @h{qw/table_cat table_schem table_name column_name data_type
            type_name column_size buffer_length decimal_digits num_prec_radix
            nullable remarks column_def sql_data_type sql_datetime_sub
            char_octet_length ordinal_position is_nullable sql/} = (
            $table_cat, $table_schem, $table_name, $column_name, $data_type,
            $type_name, $column_size, $buffer_length, $decimal_digits, $num_prec_radix,
            $nullable, $remarks, $column_def, $sql_data_type, $sql_datetime_sub,
            $char_octet_length, $ordinal_position, $is_nullable, \@SQL );

        push @columns, \%h;
    }
    $sth->finish;
    return \@columns;
}

#=rem
#TABLE_CAT: The catalog identifier. This field is NULL (undef) if not applicable to the data source, which is often the case. This field is empty if not applicable to the table.
#TABLE_SCHEM: The schema identifier. This field is NULL (undef) if not applicable to the data source, and empty if not applicable to the table.
#TABLE_NAME: The table identifier.
#COLUMN_NAME: The column identifier.
#KEY_SEQ: The column sequence number (starting with 1). Note: This field is named ORDINAL_POSITION in SQL/CLI.
#PK_NAME: The primary key constraint identifier. This field is NULL (undef) if not applicable to the data source.
#=cut

sub primary_key_info
{
    my $driver = shift;
    my $table = shift;

    my $sth = $driver->primary_key_info($table);

    my @keys = ();
    while ( my ($table_cat, $table_schem, $table_name, $column_name, $key_seq, $pk_name,) = $sth->fetchrow_array )
    {
        my %h;
        @h{qw/table_cat table_schem table_name column_name key_seq pk_name/} = (
            $table_cat, $table_schem, $table_name, $column_name, $key_seq, $pk_name, );

        push @keys, \%h;
    }
    $sth->finish;
    return \@keys;
}

#=rem
#PKTABLE_CAT ( UK_TABLE_CAT ): The primary (unique) key table catalog identifier. This field is NULL (undef) if not applicable to the data source, which is often the case. This field is empty if not applicable to the table.
#PKTABLE_SCHEM ( UK_TABLE_SCHEM ): The primary (unique) key table schema identifier. This field is NULL (undef) if not applicable to the data source, and empty if not applicable to the table.
#PKTABLE_NAME ( UK_TABLE_NAME ): The primary (unique) key table identifier.
#PKCOLUMN_NAME (UK_COLUMN_NAME ): The primary (unique) key column identifier.
#FKTABLE_CAT ( FK_TABLE_CAT ): The foreign key table catalog identifier. This field is NULL (undef) if not applicable to the data source, which is often the case. This field is empty if not applicable to the table.
#FKTABLE_SCHEM ( FK_TABLE_SCHEM ): The foreign key table schema identifier. This field is NULL (undef) if not applicable to the data source, and empty if not applicable to the table.
#FKTABLE_NAME ( FK_TABLE_NAME ): The foreign key table identifier.
#FKCOLUMN_NAME ( FK_COLUMN_NAME ): The foreign key column identifier.
#KEY_SEQ ( ORDINAL_POSITION ): The column sequence number (starting with 1).
#UPDATE_RULE ( UPDATE_RULE ): The referential action for the UPDATE rule. The following codes are defined:
#  CASCADE              0
#  RESTRICT             1
#  SET NULL             2
#  NO ACTION            3
#  SET DEFAULT          4
#DELETE_RULE ( DELETE_RULE ): The referential action for the DELETE rule. The codes are the same as for UPDATE_RULE.
#FK_NAME ( FK_NAME ): The foreign key name.
#PK_NAME ( UK_NAME ): The primary (unique) key name.
#DEFERRABILITY ( DEFERABILITY ): The deferrability of the foreign key constraint. The following codes are defined:
#  INITIALLY DEFERRED   5
#  INITIALLY IMMEDIATE  6
#  NOT DEFERRABLE       7
#( UNIQUE_OR_PRIMARY ): This column is necessary if a driver includes all candidate (i.e. primary and alternate) keys in the result set (as specified by SQL/CLI). The value of this column is UNIQUE if the foreign key references an alternate key and PRIMARY if the foreign key references a primary key, or it may be undefined if the driver doesn't have access to the information.
#=cut

sub CASCADE     { 0 }
sub RESTRICT    { 1 }
sub SET_NULL    { 2 }
sub NO_ACTION   { 3 }
sub SET_DEFAULT { 4 }

sub INITIALLY_DEFERRED  { 5 }
sub INITIALLY_IMMEDIATE { 6 }
sub NOT_DEFERRABLE      { 7 }

sub foreign_key_info
{
    my $driver = shift;
    my $table = shift;
    my $sth = $driver->foreign_key_info($table, undef, undef, undef,);

    my @fkeys = ();
    while ( my ($pktable_cat, $pktable_schem, $pktable_name, $pkcolumn_name, $fktable_cat,
                $fktable_schem, $fktable_name, $fkcolumn_name, $key_seq, $update_rule,
                $delete_rule, $fk_name, $pk_name, $deferrability, $unique_or_primary,
                ) = $sth->fetchrow_array )
    {
        my %h;
        @h{qw/pktable_cat pktable_schem pktable_name pkcolumn_name fktable_cat
            fktable_schem fktable_name fkcolumn_name key_seq update_rule
            delete_rule fk_name pk_name deferrability unique_or_primary
            /} = (
            $pktable_cat, $pktable_schem, $pktable_name, $pkcolumn_name, $fktable_cat,
            $fktable_schem, $fktable_name, $fkcolumn_name, $key_seq, $update_rule,
            $delete_rule, $fk_name, $pk_name, $deferrability, $unique_or_primary,);
        push @fkeys, \%h;
    }
    $sth->finish;
    return \@fkeys;
}

1;
