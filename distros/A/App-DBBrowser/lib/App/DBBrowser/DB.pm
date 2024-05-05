package # hide from PAUSE
App::DBBrowser::DB;

use warnings;
use strict;
use 5.014;

our $VERSION = '2.410';

#use bytes; # required
use Scalar::Util qw( looks_like_number );


sub new {
    my ( $class, $info, $opt ) = @_;
    my $db_module = $info->{plugin};
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
    my ( $sf, $dbh, $db, $is_system_db, $has_attached_db ) = @_;
    my ( $user_schemas, $sys_schemas );
    my $driver = $dbh->{Driver}{Name}; #
    if ( $sf->{Plugin}->can( 'get_schemas' ) ) {
        ( $user_schemas, $sys_schemas ) = $sf->{Plugin}->get_schemas( $dbh, $db, $is_system_db, $has_attached_db );
    }
    else {
        if ( $driver eq 'SQLite' ) {
            if ( $has_attached_db ) {
                # If a SQLite database has databases attached, set $schema to `undef`.
                # If $schema is `undef`, `$dbh->table_info( undef, $schema, '%', '' )` returns all schemas - main, temp and
                # aliases of attached databases with its tables.
                $user_schemas = [ undef ];
            }
            else {
                $user_schemas = [ 'main' ];
            }
        }
        elsif( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
            # MySQL 8.0 Reference Manual / MySQL Glossary / Schema:
            # In MySQL, physically, a schema is synonymous with a database.
            # You can substitute the keyword SCHEMA instead of DATABASE in MySQL SQL syntax,
            $user_schemas = [ $db ];
        }
        elsif ( $driver eq 'Firebird' ) {
            $user_schemas = [];
        }
        elsif ( $driver eq 'Oracle' ) {
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
            my $regex_sys;
            if ( $driver eq 'Pg' ) {
                $regex_sys = qr/^(?:pg_|information_schema$)/i;
            }
            elsif ( $driver eq 'DB2' ) {
                $regex_sys = qr/^(?:SYS|SQLJ$|NULLID$)/i;
            }
            elsif ( $driver eq 'Informix' ) {
                $regex_sys = qr/^informix\z/i;
            }
            my $sth;
            if ( $driver eq 'ODBC' ) {
                $sth = $dbh->table_info( undef, '%', undef, undef );
            }
            else {
                $sth = $dbh->table_info( undef, '%', '', '' );
            }
            my $info = $sth->fetchall_hashref( $table_schem );
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
        if ( $driver eq 'Pg' && ! @$user_schemas ) {
            # 5.9.2. The Public Schema
            # In the previous sections we created tables without specifying any schema names. By default such tables
            # (and other objects) are automatically put into a schema named “public”. Every new database contains such a schema.
            $user_schemas = [ 'public' ];
            # add 'public' only if db is user-db
        }
        return $user_schemas, $sys_schemas;
    }
}


sub tables_info { # not documented
    my ( $sf, $dbh, $schema, $is_system_schema ) = @_;
    my $driver = $sf->get_db_driver();
    if ( $sf->{Plugin}->can( 'tables_info' ) ) {
        return $sf->{Plugin}->tables_info( $dbh, $schema, $is_system_schema );
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
    my ( @user_table_keys, @sys_table_keys );
    my $tables_info = {};
    for my $info_table ( @$info_tables ) {
        if ( $driver =~ /^(?:Informix|Sybase)\z/ && defined $schema && $schema ne $info_table->{$table_schem} ) {
            # Informix: `table_info` returns everything.
            next;
        }
        if ( $driver eq 'SQLite' && $info_table->{$table_type} =~ /^(?:INDEX|TRIGGER)\z/ ) {
            next;
        }
        if ( $driver eq 'Oracle' && $info_table->{$table_type} eq 'SEQUENCE' ) {
            next;
        }
        # The table name in $table_key is used in the tables-menu but not in SQL code.
        # To get the table names for SQL code it is used the 'quote_table' routine in Auxil.pm.
        my $table_key;
        if ( $driver eq 'SQLite' && ! defined $schema ) {
            # attached databases, schema is undef
            if ( $info_table->{$table_name} eq 'sqlite_temp_master' ) {
                next; # no temp tables
            }
            if ( $info_table->{$table_schem} =~ /^main\z/i ) {
                $table_key = sprintf "[%s] %s", "\x{001f}" . $info_table->{$table_schem}, $info_table->{$table_name};
                # \x{001f} keeps the main tables on top of the tables menu.
            }
            else {
                $table_key = sprintf "[%s] %s", $info_table->{$table_schem}, $info_table->{$table_name};
            }
        }
        else {
            $table_key = $info_table->{$table_name};
        }
        if ( $is_system_schema ) {
            push @sys_table_keys, $table_key;
        }
        else {
            if ( $info_table->{$table_type} =~ /^SYSTEM/ || ( $driver eq 'SQLite' && $info_table->{$table_name} =~ /^sqlite_/ ) ) {
                push @sys_table_keys, $table_key;
            }
            else {
                push @user_table_keys, $table_key;
            }
        }
        $tables_info->{$table_key} = [ @{$info_table}{@keys} ];
    }
    return $tables_info, [ sort @user_table_keys ], [ sort @sys_table_keys ];
}



# Sybase untested

# Sysbase:
#   SET quoted_identifier ON




1;


__END__

=pod

=encoding UTF-8

=head1 NAME

App::DBBrowser::DB - Database plugin documentation.

=head1 VERSION

Version 2.410

=head1 DESCRIPTION

A database plugin provides the database specific methods. C<App::DBBrowser> considers a module whose name matches
C</^App::DBBrowser::DB::[^:']+\z/> and which is located in one of the C<@INC> directories, as a database plugin.

The user can add an installed database plugin to the available plugins in the options menu (C<db-browser -h>) by
selecting I<Plugins>.

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

=head2 Optional methods

=head4 get_schemas( $dbh, $database )

C<$dbh> is the database handle returned by the method C<db_hanlde>.

If the driver is C<SQLite>, a third argument is passed to C<get_schemas>; if the database has attached databases, the
third argument is true, otherwise it is false.

Returns the user schemas as an array reference and the system schemas as an array reference (if any).

If the option I<System data> is true, user schemas and system schemas are used, otherwise only the user schemas are used.

=begin comment

=head3 DB configuration methods

If the following methods are available, the C<db-browser> user can configure the different database settings in the
options menu.

If the database driver is C<SQLite>, only C<set_attributes> is used.

=head4 read_login_data()

Returns a reference to an array of hashes. The hashes have one or two key-value pairs:

    { name => 'string', secret => true/false }

C<name> holds the field name for example like "user" or "host".

If C<secret> is true, the user input should not be echoed to the terminal. Also the data is not stored in the plugin
configuration file if C<secret> is true.

An example C<read_login_data> method:

    sub read_login_data {
        my ( $self ) = @_;
        return [
            { name => 'host', secret => 0 },
            { name => 'port', secret => 0 },
            { name => 'user', secret => 0 },
            { name => 'pass', secret => 1 },
        ];
    }

The information returned by the method C<read_login_data> is used to build the I<DB Settings> menu entry I<Fields> and
I<Login Data>.

=head4 env_variables()

Returns a reference to an array of environment variables.

An example C<env_variables> method:

    sub env_variables {
        my ( $self ) = @_;
        return [ qw( DBI_HOST DBI_PORT DBI_USER DBI_PASS ) ];
    }

See the option I<ENV Variables> in I<DB Settings>.

=head4 set_attributes()

Returns a reference to an array of hashes. The hashes have two or three key-value pairs:

    { name => 'string', default => index, values => [ value_1, value_2, value_3, ... ] }

The value of C<name> is the name of the database connection attribute.

C<values> holds the available values for that attribute as an array reference.

The C<values> array entry of the index position C<default> is used as the default value.

Example from the plugin C<App::DBBrowser::DB::SQLite>:

    sub set_attributes {
        my ( $self ) = @_;
        return [
            { name => 'sqlite_unicode',             default => 1, values => [ 0, 1 ] },
            { name => 'sqlite_see_if_its_a_number', default => 1, values => [ 0, 1 ] },
        ];
    }

The information returned by the method C<set_attributes> is used to build the menu entry I<Set Attributes> in
L<db-browser/OPTIONS>.

=head4 read_attributes()

Returns a reference to an array of hashes. The hashes have one to two key-value pairs:

    { name => 'string', prompt => 'string' }

The value of C<name> is the name of the database connection attribute.

The value of C<default> is used as the default value. The C<default> entry is optional.

Example from the plugin C<App::DBBrowser::DB::Firebird>:

    sub read_attributes {
        my ( $sf ) = @_;
        return [
            { name => 'ib_dialect',                   },
            { name => 'ib_role',                      },
            { name => 'ib_charset', default => 'UTF8' },
        ];
    }

The information returned by the method C<read_attributes> is used to build the menu entry I<Read Attributes> in
L<db-browser/OPTIONS>.

The I<DB Options> can be accessd with the module C<App::DBBrowser::Opt::DBGet> as shown here in an example
for a C<mysql> database:

    use App::DBBrowser::Opt::DBGet;

    my $db_opt_get = App::DBBrowser::Opt::DBGet->new( $info, $opt );

    my $login_data  = $db_opt_get->login_data( $db );
    my $env_var_yes = $db_opt_get->enabled_env_vars( $db );
    my $attributes  = $db_opt_get->attributes( $db );

If C<$db> is defined, the settings for C<$db> are returned else the global plugin settings are returned.

The available C<$login_data> keys are the result of the I<Fields>* settings, the C<name> values are the result of the
I<Login Data>* settings:

    $login_data:
    {
        host => { name => 'localhost', secret => 0 },
        user => { name => 'user_name', secret => 0 },
        pass => { name => undef,       secret => 1 },
    }


The result of the I<ENV Variables>* settings:

    $env_var_yes:
    {
        DBI_HOST => 1,
        DBI_PORT => 1,
        DBI_USER => 0,
        DBI_PASS => 0,
    }

The result of the I<Attributes>* settings:

    $attributes:
    {
        mysql_enable_utf8        => 0,
        mysql_enable_utf8mb4     => 1,
        mysql_bind_type_guessing => 1,
    }

* OPTIONS/DB Options/DB Settings/$plugin

=end comment

=head1 EXAMPLE

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

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2024 Matthäus Kiem.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
