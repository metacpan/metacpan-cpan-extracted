package # hide from PAUSE
App::DBBrowser::DB;

use warnings;
use strict;
use 5.016;

our $VERSION = '2.438';

use Encode       qw( decode );
#use bytes;      # required
use Scalar::Util qw( looks_like_number );

use DBI::Const::GetInfoType;


sub new {
    my ( $class, $info, $opt ) = @_;
    my $db_module = "App::DBBrowser::DB::$info->{plugin}";
    eval "require $db_module" or die $@;
    my $plugin = $db_module->new( $info, $opt );
    bless { Plugin => $plugin }, $class;
}


sub get_db_driver {
    my ( $sf ) = @_;
    return $sf->{Plugin}->get_db_driver();
}


sub read_login_data {
    my ( $sf ) = @_;
    return [] if ! $sf->{Plugin}->can( 'read_login_data' );
    my $read_args = $sf->{Plugin}->read_login_data();
    return $read_args // [];
}


sub env_variables {
    my ( $sf ) = @_;
    return [] if ! $sf->{Plugin}->can( 'env_variables' );
    my $env_variables = $sf->{Plugin}->env_variables();
    return $env_variables // [];
}


sub read_attributes {
    my ( $sf ) = @_;
    return [] if ! $sf->{Plugin}->can( 'read_attributes' );
    my $read_attributes = $sf->{Plugin}->read_attributes();
    return $read_attributes // [];
}


sub set_attributes {
    my ( $sf ) = @_;
    return [] if ! $sf->{Plugin}->can( 'set_attributes' );
    my $set_attributes = $sf->{Plugin}->set_attributes();
    return $set_attributes // [];
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $dbh = $sf->{Plugin}->get_db_handle( $db );
    if ( $dbh->{Driver}{Name} eq 'SQLite' ) {
        $dbh->sqlite_create_function( 'regexp', 3, sub {
                my ( $regex, $string, $case_sensitive ) = @_;
                $string = '' if ! defined $string;
                return $string =~ m/$regex/sm if $case_sensitive;
                return $string =~ m/$regex/ism;
            }
        );
        $dbh->sqlite_create_function( 'trunc', -1, sub {
                my ( $number, $places ) = @_;
                return $number if ! looks_like_number( $number );
                $places //= 0;
                return int( $number * 10 ** $places ) / 10 ** $places;
            }
        );
        $dbh->sqlite_create_function( 'octet_length', 1, sub {
                require bytes;
                return if ! defined $_[0];
                return bytes::length $_[0];
            }
        );
    }
    return $dbh;
}


sub get_databases {
    my ( $sf ) = @_;
    my ( $user_db, $sys_db ) = $sf->{Plugin}->get_databases();
    return $user_db // [], $sys_db // [];
}


sub get_schemas {
    my ( $sf, $dbh, $db, $is_system_db ) = @_;
    my ( $user_schemas, $sys_schemas );
    my $driver = $dbh->{Driver}{Name}; #
    my $dbms = $sf->{Plugin}{i}{dbms};
    if ( $sf->{Plugin}->can( 'get_schemas' ) ) {
        ( $user_schemas, $sys_schemas ) = $sf->{Plugin}->get_schemas( $dbh, $db, $is_system_db );
    }
    else {
        if ( $dbms eq 'SQLite' ) {
            $user_schemas = [];
        }
        elsif( $dbms =~ /^(?:mysql|MariaDB)\z/ ) {
            # MySQL 8.0 Reference Manual / MySQL Glossary / Schema:
            # In MySQL, physically, a schema is synonymous with a database.
            # You can substitute the keyword SCHEMA instead of DATABASE in MySQL SQL syntax,
            $user_schemas = [ $db ];
        }
        elsif ( $dbms eq 'Firebird' ) {
            $user_schemas = [];
        }
        elsif ( $dbms eq 'Oracle' ) {
            # To separate system schemas from the user schemas.
            my ( $tmp_user_schemas, $tmp_sys_schemas ) = ( [], [] );
            for my $sch ( $dbh->selectall_array( "SELECT USERNAME, ORACLE_MAINTAINED FROM ALL_USERS" ) ) {
                if ( $sch->[1] =~ /^N/i ) {
                    push @$tmp_user_schemas, $sch->[0];
                }
                else {
                    push @$tmp_sys_schemas, $sch->[0];
                }
            }
            $user_schemas = [ sort @$tmp_user_schemas ];
            $sys_schemas = [ sort @$tmp_sys_schemas, 'PUBLIC' ];
        }
        else {
            my $table_schem;
            if ( $driver eq 'Pg' ) {
                # 'pg_schema' holds the unquoted name of the schema
                $table_schem = 'pg_schema';
            }
            elsif ( $driver eq 'Informix' ) {
                $table_schem = 'table_owner';
            }
            elsif ( $driver eq 'Sybase' ) {
                $table_schem = 'TABLE_OWNER';
            }
            else {
                $table_schem = 'TABLE_SCHEM';
            }
            my $sth;
            if ( $driver eq 'ODBC' ) {
                $sth = $dbh->table_info( undef, '%', undef, undef );
            }
            else {
                $sth = $dbh->table_info( undef, '%', '', '' );
            }
            my $info = $sth->fetchall_hashref( $table_schem );
            my $regex_sys;
            if ( $dbms eq 'Pg' ) {
                $regex_sys = qr/^(?:pg_|information_schema$)/i;
            }
            elsif ( $dbms eq 'DB2' ) {
                $regex_sys = qr/^(?:SYS|SQLJ$|NULLID$)/i;
            }
            elsif ( $dbms eq 'Informix' ) {
                $regex_sys = qr/^informix\s*\z/i;
            }
            elsif ( $dbms eq 'MSSQL' ) {
                $regex_sys = qr/^(?:sys|information_schema)\z/i;
            }

            for my $schema ( sort keys %$info ) {
                if ( defined $regex_sys && $schema =~ $regex_sys ) {
                    push @$sys_schemas, $schema;
                }
                else {
                    push @$user_schemas, $schema;
                }
            }
        }
    }
    $user_schemas //= [];
    $sys_schemas //= [];
    if ( $is_system_db ) {
        return [], [ @$user_schemas, @$sys_schemas ];
    }
    else {
        if ( $dbms eq 'Pg' && ! @$user_schemas ) {
            # 5.9.2. The Public Schema
            # In the previous sections we created tables without specifying any schema names. By default such tables
            # (and other objects) are automatically put into a schema named “public”. Every new database contains such a schema.
            $user_schemas = [ 'public' ];
            # add 'public' only if db is user-db
        }
        return $user_schemas, $sys_schemas;
    }
}


sub tables_info {
    my ( $sf, $dbh, $schema, $is_system_schema, $db_attached ) = @_;
    my $driver = $sf->get_db_driver();
    if ( $sf->{Plugin}->can( 'tables_info' ) ) {
        return $sf->{Plugin}->tables_info( $dbh, $schema, $is_system_schema, $db_attached );
    }
    my ( $table_cat, $table_schem, $table_name, $table_type );
    if ( $driver eq 'Pg' ) {
        $table_cat   = 'TABLE_CAT';
        $table_schem = 'pg_schema';
        $table_name  = 'pg_table';
        $table_type  = 'TABLE_TYPE';
        # DBD::Pg  3.16.0:
        # The TABLE_SCHEM and TABLE_NAME will be quoted via quote_ident().
        # Four additional fields specific to DBD::Pg are returned:
        # pg_schema: the unquoted name of the schema
        # pg_table: the unquoted name of the table
        # ...
    }
    elsif ( $driver eq 'Informix' ) {
        $table_cat   = 'table_qualifier';
        $table_schem = 'table_owner';
        $table_name  = 'table_name';
        $table_type  = 'table_type';
    }
    elsif ( $driver eq 'Sybase' ) {
        $table_cat   = 'TABLE_QUALIFIER';
        $table_schem = 'TABLE_OWNER';
        $table_name  = 'TABLE_NAME';
        $table_type  = 'TABLE_TYPE';
    }
    else {
        $table_cat   = 'TABLE_CAT';
        $table_schem = 'TABLE_SCHEM';
        $table_name  = 'TABLE_NAME';
        $table_type  = 'TABLE_TYPE';
    }
    my @keys = ( $table_cat, $table_schem, $table_name, $table_type );
    my $sth;
    if ( $driver =~ /^(?:Oracle|ODBC)\z/ ) {
        $sth = $dbh->table_info( undef, $schema, '%', undef );
    }
    else {
        $sth = $dbh->table_info( undef, $schema, '%', '' );
    }
    my $info_tables = $sth->fetchall_arrayref( { map { $_ => 1 } @keys } );
    my $dbms = $sf->{Plugin}{i}{dbms};
    my $db_odbc;
    if ( $driver eq 'ODBC' && $dbms eq 'MariaDB' ) {
        # `table_info` returns everything.
        $db_odbc = $dbh->get_info( $GetInfoType{SQL_DATABASE_NAME} );
        # ODBC: $db is the data source name and not the database name
    }
    my ( @user_table_keys, @sys_table_keys );
    my $tables_info = {};

    for my $info_table ( @$info_tables ) {
        if ( $driver =~ /^(?:Informix|Sybase)\z/ ) {
            if ( defined $schema && $schema ne $info_table->{$table_schem} ) {
                # `table_info` returns everything.
                next;
            }
            $info_table->{$table_type} =~ s/\s+\z// if $driver eq 'Informix';
        }
        if ( length $db_odbc && $db_odbc ne $info_table->{$table_cat} ) {
            next;
        }
        if ( $dbms eq 'SQLite') {
            if ( $info_table->{$table_type} =~ /^(?:INDEX|TRIGGER)\z/ ) {
                next;
            }
            if ( $info_table->{$table_name} eq 'sqlite_temp_master' ) {
                next; # no temp tables
            }
        }
        if ( $dbms eq 'Oracle' && $info_table->{$table_type} eq 'SEQUENCE' ) {
            next;
        }
        my $table_key;
        # The table name in $table_key is used in the tables-menu but not in SQL code.
        # To get the table names for SQL code it is used the 'quote_table' routine in Auxil.pm.
        if ( $db_attached ) {
            if ( $dbms eq 'SQLite' ) {
                if ( $info_table->{$table_schem} =~ /^main\z/i ) {
                    $table_key = sprintf "[%s] %s", "\x{001f}" . $info_table->{$table_schem}, $info_table->{$table_name};
                    # \x{001f} keeps the main tables on top of the tables menu.
                }
                else {
                    $table_key = sprintf "[%s] %s", $info_table->{$table_schem}, $info_table->{$table_name};
                }
            }
            elsif ( $dbms eq 'DuckDB' ) {
                $table_key = sprintf "[%s] %s", $info_table->{$table_cat}, $info_table->{$table_name};
            }
        }
        else {
            $table_key = $info_table->{$table_name};
        }
        if ( $is_system_schema ) {
            push @sys_table_keys, $table_key;
        }
        elsif ( $dbms eq 'SQLite' && $info_table->{$table_name} =~ /^sqlite_/i ) {
            push @sys_table_keys, $table_key;
        }
        elsif ( $info_table->{$table_type} =~ /^SYSTEM/i ) {
            push @sys_table_keys, $table_key;
        }
        else {
            push @user_table_keys, $table_key;
        }
        $tables_info->{$table_key} = [ @{$info_table}{@keys} ];
    }
    return $tables_info, [ sort @user_table_keys ], [ sort @sys_table_keys ];
}





1;


__END__

=pod

=encoding UTF-8

=head1 NAME

App::DBBrowser::DB - Database plugin documentation.

=head1 VERSION

Version 2.438

=head1 DESCRIPTION

A database plugin provides the database specific methods. C<App::DBBrowser> considers a module whose name matches
C</^App::DBBrowser::DB::[^:']+\z/> and which is located in one of the C<@INC> directories, as a database plugin.

The user can add an installed database plugin to the available plugins in the options menu (C<db-browser -h>) by
selecting I<Select plugins>.

A suitable database plugin provides the methods mentioned in this documentation.

=head1 METHODS

=head2 Required methods

=head3 new( $info, $opt )

The constructor method.

When C<db-browser> calls the plugin constructor it passes two arguments:

    sub new {
        my ( $class, $info, $opt ) = @_;
        my $self = {
            info => $info,
            opt  => $opt
        };
        return bless $self, $class;
    }

    # $info->{app_dir}        -> path to the configuration directoriy of the app
    # $info->{search}         -> true if C<db-browser> was called with the argument C<-s|--search>
    # $opt->{G}{metadata}     -> Options/Sql/System data

Returns the created object.

=head3 get_db_driver()

Returns the name of the C<DBI> database driver used by the plugin.

=head3 get_databases();

Returns two array references: the first reference refers to the array of user databases, the second to the array of the
system databases. The second array reference is optional.

If the option I<System data> is true, user databases and system databases are used, otherwise only the user databases
are used.

=head3 get_db_handle( $database )

Returns the database handle.

C<db-browser> expects a C<DBI> database handle with the attribute I<RaiseError> activated.

=head3 EXAMPLE

    package App::DBBrowser::DB::MyPlugin;
    use strict;
    use DBI;

    sub new {
        my ( $class ) = @_;
        return bless {}, $class;
    }

    sub get_db_driver {
        my ( $self ) = @_;
        return 'Pg';
    }

    sub get_db_handle {
        my ( $self, $db ) = @_;
        my $dbh = DBI->connect( "DBI:Pg:dbname=$db", 'user', 'password', {
            RaiseError => 1,
            PrintError => 0,
        });
        return $dbh;
    }

    sub get_databases {
        my ( $self ) = @_;
        return [ 'My_DB_1', 'My_DB_2' ];
    }

    1;

=head2 Optional methods

=head4 get_schemas( $dbh, $database, $is_system_db )

C<$dbh> is the database handle returned by the method C<db_hanlde> and C<$database> is the database name. If
C<is_system_db> is true, then the database is a system database.

Returns the user schemas as an array reference and the system schemas as an array reference (if any).

If the option I<System data> is true, user schemas and system schemas are used, otherwise only the user schemas are used.

=head4 tables_info( $dbh, $schema, $is_system_schema )

C<$dbh> is the database handle and C<$schema> is the schema name. If C<is_system_schema> is true, then the schema is a
system schema.

Returns three values:

The first value is a hash reference where the keys are the table keys (table names), and the values are array references
containing the following elements: table category, table schema, table name, and table type.

The second value is an array reference containing the list of user table keys.

The third value is an array reference containing the list of system table keys.

=head4 EXAMPLE

    sub tables_info {
        my ( $sf, $dbh, $schema, $is_system_schema ) = @_;
        my $sth = $dbh->table_info( undef, $schema, '%', '' );
        my $table_cat   = 'TABLE_CAT';
        my $table_schem = 'TABLE_SCHEM';
        my $table_name  = 'TABLE_NAME';
        my $table_type  = 'TABLE_TYPE';
        my @fields = ( $table_cat, $table_schem, $table_name, $table_type );
        my $info_tables = $sth->fetchall_arrayref( { map { $_ => 1 } @fields } );
        my ( @user_table_keys, @sys_table_keys );
        my $tables_info = {};

        for my $info_table ( @$info_tables ) {
            my $table_key = $info_table->{$table_name};
            if ( $is_system_schema ) {
                push @sys_table_keys, $table_key;
            }
            else {
                if ( $info_table->{$table_type} =~ /^SYSTEM/ ) {
                    push @sys_table_keys, $table_key;
                }
                else {
                    push @user_table_keys, $table_key;
                }
            }
            $tables_info->{$table_key} = [ @{$info_table}{@fields} ];
        }
        return $tables_info, [ sort @user_table_keys ], [ sort @sys_table_keys ];
    }

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2025 Matthäus Kiem.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
