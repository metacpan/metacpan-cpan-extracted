package # hide from PAUSE
App::DBBrowser::DB;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '1.058';



=head1 NAME

App::DBBrowser::DB - Database plugin documentation.

=head1 VERSION

Version 1.058


=head1 DESCRIPTION

A database plugin provides the database specific methods. C<App::DBBrowser> considers a module whose name matches
C</^App::DBBrowser::DB::[^:']+\z/> and which is located in one of the C<@INC> directories as a database plugin.
Plugins with the name C<App::DBBrowser::DB::$database_driver> should be for general use of C<$database_driver>
databases.

The user can add an installed database plugin to the available plugins in the option menu (C<db-browser -h>) by
selecting I<DB> and then I<DB Plugins>.

A suitable database plugin provides the methods named in this documentation.

Column names passed as arguments to plugin methods are already quoted with the C<DBI> C<quote_identifier> method.


=head1 PLUGIN API VERSION

This documentation describes the plugin API version C<1.5>.

Supported plugin API version: C<1.5>.


=head1 METHODS


=head2 new

The constructor method.

=over

=item Arguments

A reference to a hash. The hash entries are:

        app_dir             # path to the application directoriy
        home_dir
        db_plugin           # name of the database plugin
        add_metadata        # true or false

        # SQLite only:
        sqlite_search       # if true, don't use cached database names
        db_cache_file       # path to the file with the cached database names

=item return

The object.

=back

=cut

sub new {
    my ( $class, $info, $opt ) = @_;
    my $db_module = 'App::DBBrowser::DB::' . $info->{db_plugin};
    eval "require $db_module" or die $@;

    my $plugin = $db_module->new( {
        app_dir             => $info->{app_dir},
        home_dir            => $info->{home_dir},
        db_plugin           => $info->{db_plugin},
        db_cache_file       => $info->{db_cache_file},
        sqlite_search       => $info->{sqlite_search},
        clear_screen        => $info->{clear_screen},
        add_metadata        => $opt->{G}{metadata},
    } );

    my $minimum_pav = 1.5;

    my $pav;
    $pav = $plugin->plugin_api_version() if $plugin->can( 'plugin_api_version' );
    if ( defined $pav && $pav < $minimum_pav ) {
        print "Database plugin \"$info->{db_plugin}\" complies to the plugin API version $pav.\n";
        print "Supported minimum plugin API version is $minimum_pav!\n";
        exit;
    }

    bless { Plugin => $plugin }, $class;
}


sub message_method_undef_return {
    my ( $self, $method ) = @_;
    return sprintf '%s method %s: no return value', ref $self->{Plugin}, $method;
}


sub debug {
    my ( $self, $dbh, $info, $opt, $db_opt ) = @_;
    return if ! $self->{Plugin}->can( 'debug' );
    $self->{Plugin}->debug( $dbh, $info, $opt, $db_opt );
}



=head2 plugin_api_version

=over

=item Arguments

none

=item return

The version of the plugin-API to which the plugin refers.

See L</PLUGIN API VERSION> for the plugin API version described by this documentation.

=back

=cut

sub plugin_api_version {
    my ( $self ) = @_;
    my $plugin_api_version = $self->{Plugin}->plugin_api_version();
    return $plugin_api_version;
}



=head2 db_driver

=over

=item Arguments

none

=item return

The name of the C<DBI> database driver used by the plugin.

=back

=cut

sub db_driver {
    my ( $self ) = @_;
    my $db_driver = $self->{Plugin}->db_driver();
    die $self->message_method_undef_return( 'db_driver' ) if ! defined $db_driver;
    return $db_driver;
}



=head2 driver_prefix

=over

=item Arguments

none

=item return

The driver-private prefix.

=back

Example for the database driver C<Pg>:

    sub driver_prefix {
        return 'pg';
    }

=cut

sub driver_prefix {
    my ( $self ) = @_;
    return if ! $self->{Plugin}->can( 'driver_prefix' );
    my $driver_prefix = $self->{Plugin}->driver_prefix();
    if ( defined $driver_prefix && $driver_prefix !~ /_\z/ ) {
        $driver_prefix .= '_';
    }
    return $driver_prefix;
}



=head2 read_arguments

=over

=item Arguments

none

=item return

A reference to an array of hashes. The hashes have two or three key-value pairs:

    { name => 'string', prompt => 'string', keep_secret => true/false }

C<name> holds the field name for example like "user" or "host".

The value of C<prompt> is used as the prompt string, when the user is asked for the data. The C<prompt> entry is
optional. If C<prompt> doesn't exist, the value of C<name> is used instead.

If C<keep_secret> is true, the user input should not be echoed to the terminal. Also the data is not stored in the
plugin configuration file if C<keep_secret> is true.

=back

An example C<read_arguments> method:

    sub read_arguments {
        my ( $self ) = @_;
        return [
            { name => 'host', prompt => "Host",     keep_secret => 0 },
            { name => 'port', prompt => "Port",     keep_secret => 0 },
            { name => 'user', prompt => "User",     keep_secret => 0 },
            { name => 'pass', prompt => "Password", keep_secret => 1 },
        ];
    }

The information returned by the method C<read_arguments> is used to build the entries of the C<db-browser> options
I<Fields> and I<Login Data>.

=cut

sub read_arguments {
    my ( $self ) = @_;
    return [] if ! $self->{Plugin}->can( 'read_arguments' );
    my $data = $self->{Plugin}->read_arguments();
    return [] if ! defined $data;
    return $data;
}



=head2 environment_variables

=over

=item Arguments

none

=item return

A reference to an array of environment variables.

=back

An example C<environment_variables> method:

    sub environment_variables {
        my ( $self ) = @_;
        return [ qw( DBI_DSN DBI_HOST DBI_PORT DBI_USER DBI_PASS ) ];
    }

See the C<db-browser> option I<ENV Variables>.

=cut

sub environment_variables {
    my ( $self ) = @_;
    return [] if ! $self->{Plugin}->can( 'environment_variables' );
    my $env_variables = $self->{Plugin}->environment_variables();
    return [] if ! defined $env_variables;
    return $env_variables;
}



=head2 choose_arguments

=over

=item Arguments

none

=item return

A reference to an array of hashes. The hashes have three or four key-value pairs:

    { name => 'string', prompt => 'string', default_index => index, avail_values => [ value_1, value_2, value_3, ... ] }

The value of C<name> is the name of the database connection attribute.

The value of C<prompt> is used as the prompt string. The C<prompt> entry is optional. If C<prompt> doesn't exist, the
value of C<name> is used instead.

C<avail_values> holds the available values for that attribute as an array reference.

The C<avail_values> array entry of the index position C<default_index> is used as the default value.

=back

Example form the plugin C<App::DBBrowser::DB::SQLite>:

    sub choose_arguments {
        my ( $self ) = @_;
        return [
            { name => 'sqlite_unicode',             default_index => 1, avail_values => [ 0, 1 ] },
            { name => 'sqlite_see_if_its_a_number', default_index => 1, avail_values => [ 0, 1 ] },
        ];
    }

C<choose_arguments> determines the database handle attributes with predefined values offered in the C<db-browser> option
I<DB Options>.

=cut

sub choose_arguments {
    my ( $self ) = @_;
    return [] if ! $self->{Plugin}->can( 'choose_arguments' );
    my $connect_attributes = $self->{Plugin}->choose_arguments();
    return [] if ! defined $connect_attributes;
    return $connect_attributes;
}



=head2 available_databases

=over

=item Arguments

A reference to a hash. If C<available_databases> uses the C<get_db_handle> method, the hash reference can be
passed to C<get_db_handle> as the second argument. See L</get_db_handle> for more info about the passed hash reference.

=item return

If the object attribute I<add_metadata> is true, C<available_databases> returns the "user-databases" as an
array-reference and the "system-databases" (if any) as an array-reference.

If I<add_metadata> is not true, C<available_databases> returns only the "user-databases" as an
array-reference.

=back

=cut

sub available_databases {
    my ( $self, $connect_parameter ) = @_;
    my ( $user_db, $system_db ) = $self->{Plugin}->available_databases( $connect_parameter );
    return $user_db, $system_db;
}



=head2 get_db_handle

=over

=item Arguments

The database name and a reference to a hash of hashes.

The hash of hashes provides the settings gathered from the option I<Database settings>.

    $connect_parameter = {
        use_env_var => {
            env_var => true or false,
            env_var => true or false,
            ...
        },
        chosen_arg => {
            attribute => chosen value,
            attribute => chosen value,
            ...
        },
        required => {
            name => true or false,
            name => true or false,
            ...
        },
        read_arg => {
            name => user input,
            name => user input,
            ...
        },
        keep_secret = {
            name => true or false,
            name => true or false,
            ...
        },
        dir_sqlite => [     # array reference with directories where to search for SQLite databases
            /path/dir,
            ...
        ]
    };

For example for the plugin C<mysql> the hash of hashes held by C<$connect_parameter> could look like this:

    $connect_parameter = {
        use_env_var => {
            DBI_HOST => 1,
            DBI_USER => 0,
            DBI_PASS => 0,
        },
        read_arg => {
            host => undef,
            pass => undef,
            user => 'db_user_name',
            port => undef
        },
        chosen_arg => {
            mysql_enable_utf8 => 1
        },
        required => {
            port => 0,
            user => 1,
            pass => 1,
            host => 1
        },
        keep_secret => {
            port => 0,
            host => 0,
            pass => 1,
            user => 0
        },
    };

=item return

Database handle.

=back

=cut

sub get_db_handle {
    my ( $self, $db, $connect_parameter ) = @_;
    my $dbh = $self->{Plugin}->get_db_handle( $db, $connect_parameter );
    die $self->message_method_undef_return( 'get_db_handle' ) if ! defined $dbh;
    return $dbh;
}



=head2 get_schema_names

=over

=item Arguments

The database handle and the database name.

=item return

If I<add_metadata> is true, C<get_schema_names> returns the "user-schemas" as an array-reference
and the "system-schemas" (if any) as an array-reference.

If I<add_metadata> is not true, C<get_schema_names> returns only the "user-schemas" as an
array-reference.

=back

=cut

sub get_schema_names {
    my ( $self, $dbh, $db ) = @_;
    return [] if ! $self->{Plugin}->can( 'get_schema_names' );
    my ( $user_schemas, $system_schemas ) = $self->{Plugin}->get_schema_names( $dbh, $db );
    return $user_schemas, $system_schemas;
}



=head2 get_table_names

=over

=item Arguments

The database handle and the schema name.

=item return

If I<add_metadata> is true, C<get_table_names> returns the "user-tables" as an array-reference and
the "system-tables" (if any) as an array-reference.

If I<add_metadata> is not true, C<get_table_names> returns only the "user-tables" as
an array-reference.

=back

=cut

sub get_table_names {
    my ( $self, $dbh, $schema ) = @_;
    my ( $user_tbl, $system_tbl ) = $self->{Plugin}->get_table_names( $dbh, $schema );
    return $user_tbl, $system_tbl;
}



=head2 primary_key_auto

=over

=item Arguments

none

=item return

The primary-key-autoincrement statement.

=back

Example for the database driver C<Pg>:

    sub primary_key_auto {
        return "SERIAL PRIMARY KEY";
    }

=cut

sub primary_key_auto {
    my ( $self ) = @_;
    return if ! $self->{Plugin}->can( 'primary_key_auto' ); #
    return $self->{Plugin}->primary_key_auto();
}



=head2 column_names_and_types

=over

=item Arguments

Database handle, database name, schema name, available tables as an array reference.

=item return

Two hash references - one for the column names and one for the column types:

    $col_names = {
        table_1 => [ column_1_name, column_2_name, ... ],
        table_2 => [ column_1_name, column_2_name, ... ],
        ...
    }

    $col_types = {
        table_1 => [ column_1_type, column_2_type, ... ],
        table_2 => [ column_1_type, column_2_type, ... ],
        ...
    }

=back

=cut

sub column_names_and_types {
    my ( $self, $dbh, $db, $schema, $tables ) = @_;
    my ( $col_names, $col_types ) = $self->{Plugin}->column_names_and_types( $dbh, $db, $schema, $tables );
    die $self->message_method_undef_return( 'column_names_and_types' ) if ! defined $col_names;
    $col_types = {} if ! defined $col_types;
    for my $table ( keys %$col_types ) {
        for ( @{$col_types->{$table}} ) {
            s/integer/int/i;
        }
    }
    return $col_names, $col_types;
}



=head2 primary_and_foreign_keys

The method C<primary_and_foreign_keys> is optional.

=over

=item Arguments

Database handle, database name, schema name, available tables as an array reference.

=item return

Two hash references - one for the primary keys and one for the foreign keys:

    $primary_keys = {
        table_1 => [ 'primary_key_col_1' [ , ... ] ],
        table_2 => [ 'primary_key_col_1' [ , ... ] ],
        ...
    };

    $foreign_keys = {
        table_1 => {
            fk_name_1 => {
                foreign_key_col   => [ 'foreign_key_col_1' [ , ... ] ],
                reference_table   => 'Reference_table',
                reference_key_col => [ 'reference_key_col_1' [ , ... ] ],
            fk_name_2 => {
                ...
            }
        table_2 => {
            ...
        }
    };

=back

=cut

sub primary_and_foreign_keys {
    my ( $self, $dbh, $db, $schema, $tables ) = @_;
    return if ! $self->{Plugin}->can( 'primary_and_foreign_keys' );
    my ( $pk_cols, $fks ) = $self->{Plugin}->primary_and_foreign_keys( $dbh, $db, $schema, $tables );
    return $pk_cols, $fks;
}



=head2 sql_regexp

=over

=item Arguments

Column name, C<$do_not_match_regexp> (true/false), C<$case_sensitive> (true/false).

Use the placeholder instead of the string which should match or not match the regexp.

=item return

The sql regexp substatement.

=back

Example form the plugin C<App::DBBrowser::DB::mysql>:

    sub sql_regexp {
        my ( $self, $col, $do_not_match_regexp, $case_sensitive ) = @_;
        if ( $do_not_match_regexp ) {
            return ' '. $col . ' NOT REGEXP ?'        if ! $case_sensitive;
            return ' '. $col . ' NOT REGEXP BINARY ?' if   $case_sensitive;
        }
        else {
            return ' '. $col . ' REGEXP ?'            if ! $case_sensitive;
            return ' '. $col . ' REGEXP BINARY ?'     if   $case_sensitive;
        }
    }

=cut

sub sql_regexp {
    my ( $self, $quote_col, $do_not_match_regexp, $case_sensitive ) = @_;
    my $sql_regexp = $self->{Plugin}->sql_regexp( $quote_col, $do_not_match_regexp, $case_sensitive );
    die $self->message_method_undef_return( 'sql_regexp' ) if ! defined $sql_regexp;
    $sql_regexp = ' ' . $sql_regexp if $sql_regexp !~ /^\ /;
    return $sql_regexp;
}



=head2 concatenate

=over

=item Arguments

A reference to an array of strings.

=item return

The sql substatement which concatenates the passed strings.

=back

Example form the plugin C<App::DBBrowser::DB::Pg>:

    sub concatenate {
        my ( $self, $arg ) = @_;
        return join( ' || ', @$arg );
    }

=cut

sub concatenate {
    my ( $self, $arg ) = @_;
    my $concatenated = $self->{Plugin}->concatenate( $arg );
    die $self->message_method_undef_return( 'concatenate' ) if ! defined $concatenated;
    return $concatenated;
}



# scalar functions


=head2 epoch_to_datetime

=over

=item Arguments

The column name and the interval.

The interval is 1 (seconds), 1000 (milliseconds) or 1000000 (microseconds).

=item return

The sql epoch to datetime substatement.

=back

Example form the plugin C<App::DBBrowser::DB::mysql>:

    sub epoch_to_datetime {
        my ( $self, $col, $interval ) = @_;
        return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d %H:%i:%s')";
    }

=cut

sub epoch_to_datetime {
    my ( $self, $quote_col, $interval ) = @_;
    my $quote_f = $self->{Plugin}->epoch_to_datetime( $quote_col, $interval );
    die $self->message_method_undef_return( 'epoch_to_datetime' ) if ! defined $quote_f;
    return $quote_f;
}



=head2 epoch_to_date

=over

=item Arguments

The column name and the interval.

The interval is 1 (seconds), 1000 (milliseconds) or 1000000 (microseconds).

=item return

The sql epoch to date substatement.

=back

Example form the plugin C<App::DBBrowser::DB::mysql>:

    sub epoch_to_date {
        my ( $self, $col, $interval ) = @_;
        return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d')";
    }

=cut

sub epoch_to_date {
    my ( $self, $quote_col, $interval ) = @_;
    my $quote_f = $self->{Plugin}->epoch_to_date( $quote_col, $interval );
    die $self->message_method_undef_return( 'epoch_to_date' ) if ! defined $quote_f;
    return $quote_f;
}



=head2 truncate

=over

=item Arguments

The column name and the precision (int).

=item return

The sql truncate substatement.

=back

Example form the plugin C<App::DBBrowser::DB::mysql>:

    sub truncate {
        my ( $self, $col, $precision ) = @_;
        return "TRUNCATE($col,$precision)";
    }

=cut

sub truncate {
    my ( $self, $quote_col, $precision ) = @_;
    my $quote_f = $self->{Plugin}->truncate( $quote_col, $precision );
    die $self->message_method_undef_return( 'truncate' ) if ! defined $quote_f;
    return $quote_f;
}



=head2 bit_length

=over

=item Arguments

The column name.

=item return

The sql bit length substatement.

=back

Example form the plugin C<App::DBBrowser::DB::Pg>:

The sql bit length substatement.

    sub bit_length {
        my ( $self, $col ) = @_;
        return "BIT_LENGTH($col)";
    }

=cut


sub bit_length {
    my ( $self, $quote_col ) = @_;
    my $quote_f = $self->{Plugin}->bit_length( $quote_col );
    die $self->message_method_undef_return( 'bit_length' ) if ! defined $quote_f;
    return $quote_f;
}



=head2 char_length

=over

=item Arguments

The column name.

=item return

The sql char length substatement.

=back

Example form the plugin C<App::DBBrowser::DB::Pg>:

    sub char_length {
        my ( $self, $col ) = @_;
        return "CHAR_LENGTH($col)";
    }


=cut

sub char_length {
    my ( $self, $quote_col ) = @_;
    my $quote_f = $self->{Plugin}->char_length( $quote_col );
    die $self->message_method_undef_return( 'char_length' ) if ! defined $quote_f;
    return $quote_f;
}




1;


__END__


=pod

=encoding UTF-8

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2018 Matthäus Kiem.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
