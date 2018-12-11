package # hide from PAUSE
App::DBBrowser::DB;

use warnings;
use strict;
use 5.008003;

our $VERSION = '2.033';

use Scalar::Util qw( looks_like_number );


sub new {
    my ( $class, $info, $opt ) = @_;
    my $db_module  = $info->{plugin};
    eval "require $db_module" or die $@;

    my $plugin = $db_module->new( {
        home_dir      => $info->{home_dir},
        app_dir       => $info->{app_dir},
        add_metadata  => $opt->{G}{meta},
        reset_search_cache => $info->{sqlite_search},
        file_find_warnings => $opt->{G}{file_find_warnings},
    } );
    bless { Plugin => $plugin }, $class;
}


sub message_method_undef_return {
    my ( $sf, $method ) = @_;
    return sprintf '%s method %s: no return value', ref $sf->{Plugin}, $method;
}


sub get_db_driver {
    my ( $sf ) = @_;
    ###
    if ( ! $sf->{Plugin}->can( 'get_db_driver' ) && $sf->{Plugin}->can( 'db_driver' ) ) {
        require Term::Choose;
        Term::Choose::choose( [ 'Close with ENTER' ], { prompt => 'Please update your database Plugin!' } );
        exit;
    }
    ###
    my $driver = $sf->{Plugin}->get_db_driver();
    die $sf->message_method_undef_return( 'get_db_driver' ) if ! defined $driver;
    return $driver;
}


sub read_arguments {
    my ( $sf ) = @_;
    return undef, [] if ! $sf->{Plugin}->can( 'read_arguments' );
    my $read_args = $sf->{Plugin}->read_arguments();
    return [] if ! defined $read_args;
    return $read_args;
}

sub env_variables {
    my ( $sf ) = @_;
    return [] if ! $sf->{Plugin}->can( 'env_variables' );
    my $env_variables = $sf->{Plugin}->env_variables();
    return [] if ! defined $env_variables;
    return $env_variables;
}

sub set_attributes {
    my ( $sf ) = @_;
    return [] if ! $sf->{Plugin}->can( 'set_attributes' );
    my $attributes = $sf->{Plugin}->set_attributes();
    return [] if ! defined $attributes;
    return $attributes;
}


sub get_databases {
    my ( $sf, $connect_parameter ) = @_;
    my ( $user_db, $sys_db ) = $sf->{Plugin}->get_databases( $connect_parameter );
    $user_db = [] if ! defined $user_db;
    $sys_db  = [] if ! defined $sys_db;
    return $user_db, $sys_db;
}


sub get_db_handle {
    my ( $sf, $db, $connect_parameter ) = @_;
    my $dbh = $sf->{Plugin}->get_db_handle( $db, $connect_parameter );
    die $sf->message_method_undef_return( 'get_db_handle' ) if ! defined $dbh;
    if ( $dbh->{Driver}{Name} eq 'SQLite' ) {
        if ( ! $sf->{Plugin}->can( 'regexp' ) ) {
            $dbh->sqlite_create_function( 'regexp', 3, sub {
                    my ( $regex, $string, $case_sensitive ) = @_;
                    $string = '' if ! defined $string;
                    return $string =~ m/$regex/sm if $case_sensitive;
                    return $string =~ m/$regex/ism;
                }
            );
        }
        if ( ! $sf->{Plugin}->can( 'truncate' ) ) {
            $dbh->sqlite_create_function( 'truncate', 2, sub {
                    my ( $number, $places ) = @_;
                    return if ! defined $number;
                    return $number if ! looks_like_number( $number );
                    return sprintf "%.*f", $places, int( $number * 10 ** $places ) / 10 ** $places;
                }
            );
        }
        if ( ! $sf->{Plugin}->can( 'bit_length' ) ) {
            $dbh->sqlite_create_function( 'bit_length', 1, sub {
                    use bytes;
                    return length $_[0];
                }
            );
        }
        if ( ! $sf->{Plugin}->can( 'char_length' ) ) {
            $dbh->sqlite_create_function( 'char_length', 1, sub {
                    return length $_[0];
                }
            );
        }
    }
    return $dbh;
}


sub get_schemas {
    my ( $sf, $dbh, $db ) = @_;
    my ( $user_schema, $sys_schema );
    if ( $sf->{Plugin}->can( 'schemas' ) ) {
        ( $user_schema, $sys_schema ) = $sf->{Plugin}->get_schemas( $dbh, $db );
    }
    else {
        my $driver = $dbh->{Driver}{Name}; #
        if ( $driver eq 'SQLite' ) {
            $user_schema = [ 'main' ]; # [ undef ];
        }
        elsif( $driver eq 'mysql' ) {
            # MySQL 5.7 Reference Manual  /  MySQL Glossary:
            # In MySQL, physically, a schema is synonymous with a database.
            # You can substitute the keyword SCHEMA instead of DATABASE in MySQL SQL syntax,
            $user_schema = [ $db ];
        }
        elsif( $driver eq 'Pg' ) {
            my $sth = $dbh->table_info( undef, '%', undef, undef );
            # DBD::Pg  3.7.0:
            # The TABLE_SCHEM and TABLE_NAME will be quoted via quote_ident().
            # pg_schema: the unquoted name of the schema
            my $info = $sth->fetchall_hashref( 'pg_schema' );
            my $qr = qr/^(?:pg_|information_schema$)/;
            for my $schema ( keys %$info ) {
                if ( $schema =~ /$qr/ ) {
                    push @$sys_schema, $schema;
                }
                else {
                    push @$user_schema, $schema;
                }
            }
        }
        else {
            my $sth = $dbh->table_info( undef, '%', undef, undef );
            my $info = $sth->fetchall_hashref( 'TABLE_SCHEM' );
            $user_schema = [ keys %$info ];
        }
    }
    $user_schema = [] if ! defined $user_schema;
    $sys_schema  = [] if ! defined $sys_schema;
    return $user_schema, $sys_schema;
}


#sub primary_key_auto {
#    my ( $sf ) = @_;
#    return if ! $sf->{Plugin}->can( 'primary_key_auto' ); #
#    return $sf->{Plugin}->primary_key_auto();
#}


sub regexp {
    my ( $sf, $col, $do_not_match, $case_sensitive ) = @_;
    if ( $sf->{Plugin}->can( 'sql_regexp' ) ) {
        my $sql_regexp = $sf->{Plugin}->sql_regexp( $col, $do_not_match, $case_sensitive );
        die $sf->message_method_undef_return( 'sql_regexp' ) if ! defined $sql_regexp;
        $sql_regexp = ' ' . $sql_regexp if $sql_regexp !~ /^\ /;
        return $sql_regexp;
    }
    elsif ( $sf->get_db_driver eq 'SQLite' ) {
        if ( $do_not_match ) {
            return sprintf ' NOT REGEXP(?,%s,%d)', $col, $case_sensitive;
        }
        else {
            return sprintf ' REGEXP(?,%s,%d)', $col, $case_sensitive;
        }
    }
    elsif ( $sf->get_db_driver eq 'mysql' ) {
        if ( $do_not_match ) {
            return ' '. $col . ' NOT REGEXP ?'        if ! $case_sensitive;
            return ' '. $col . ' NOT REGEXP BINARY ?' if   $case_sensitive;
        }
        else {
            return ' '. $col . ' REGEXP ?'            if ! $case_sensitive;
            return ' '. $col . ' REGEXP BINARY ?'     if   $case_sensitive;
        }
    }
    elsif ( $sf->get_db_driver eq 'Pg' ) {
        if ( $do_not_match ) {
            return ' '. $col . '::text' . ' !~* ?' if ! $case_sensitive;
            return ' '. $col . '::text' . ' !~ ?'  if   $case_sensitive;
        }
        else {
            return ' '. $col . '::text' . ' ~* ?'  if ! $case_sensitive;
            return ' '. $col . '::text' . ' ~ ?'   if   $case_sensitive;
        }
    }
}


sub concatenate {
    my ( $sf, $arg ) = @_;
    if ( $sf->{Plugin}->can( 'concatenate' ) ) {
        my $concatenated = $sf->{Plugin}->concatenate( $arg );
        die $sf->message_method_undef_return( 'concatenate' ) if ! defined $concatenated;
        return $concatenated;
    }
    return 'concat(' . join( ',', @$arg ) . ')'  if $sf->get_db_driver eq 'mysql';

    return join( ' || ', @$arg );
}


sub epoch_to_datetime {
    my ( $sf, $col, $interval ) = @_;

    return $sf->{Plugin}->epoch_to_datetime( $col, $interval )    if $sf->{Plugin}->can( 'epoch_to_datetime' );

    return "DATETIME($col/$interval,'unixepoch','localtime')"     if $sf->get_db_driver eq 'SQLite';

    # mysql: FROM_UNIXTIME doesn't work with negative timestamps
    return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d %H:%i:%s')"    if $sf->get_db_driver eq 'mysql';

    return "TO_TIMESTAMP(${col}::bigint/$interval)::timestamp"    if $sf->get_db_driver eq 'Pg';
}


sub epoch_to_date {
    my ( $sf, $col, $interval ) = @_;

    return $sf->{Plugin}->epoch_to_date( $col, $interval )   if $sf->{Plugin}->can( 'epoch_to_date' );

    return "DATE($col/$interval,'unixepoch','localtime')"    if $sf->get_db_driver eq 'SQLite';

    return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d')"        if $sf->get_db_driver eq 'mysql';

    return "TO_TIMESTAMP(${col}::bigint/$interval)::date"    if $sf->get_db_driver eq 'Pg';
}


sub truncate {
    my ( $sf, $col, $precision ) = @_;

    return $sf->{Plugin}->truncate( $col, $precision )  if $sf->{Plugin}->can( 'truncate' );

    return "TRUNC($col,$precision)"                     if $sf->get_db_driver eq 'Pg';

    return "TRUNCATE($col,$precision)";
}


sub bit_length {
    my ( $sf, $col ) = @_;

    return $sf->{Plugin}->bit_length( $col ) if $sf->{Plugin}->can( 'bit_length' );

    return "BIT_LENGTH($col)";
}


sub char_length {
    my ( $sf, $col ) = @_;

    return $sf->{Plugin}->char_length( $col ) if $sf->{Plugin}->can( 'char_length' );

    return "CHAR_LENGTH($col)";
}




1;


__END__

=pod

=encoding UTF-8

=head1 NAME

App::DBBrowser::DB - Database plugin documentation.

=head1 VERSION

Version 2.033

=head1 DESCRIPTION

This version introduces backwards incompatible changes.

A database plugin provides the database specific methods. C<App::DBBrowser> considers a module whose name matches
C</^App::DBBrowser::DB::[^:']+\z/> and which is located in one of the C<@INC> directories as a database plugin.
Plugins with the name C<App::DBBrowser::DB::$database_driver> should be for general use of C<$database_driver>
databases.

The user can add an installed database plugin to the available plugins in the options menu (C<db-browser -h>) by
selecting I<DB> and then I<DB Plugins>.

A suitable database plugin provides the methods named in this documentation.

=head1 METHODS

=head2 Required methods

=head3 new( \%info )

The constructor method.

When C<db-browser> calls the plugin constructor it passes a reference to a hash ($info):

    sub new {
        my ( $class, $info ) = @_;
        my $self = {
            app_dir       => $info->{app_dir},       # path to the application directoriy
            add_metadata  => $info->{add_metadata},  # true or false

            # for SQLite databases:
            reset_search_cache => $info->{reset_search_cache}, # true ore false
        };
        return bless $self, $class;
    }

C<reset_search_cache> is true if C<db-browser> is called with the argument C<-s|--search> - see
L<db-browser/SYNOPSIS>.

Returns the created object.

=head3 get_db_driver()

Returns the name of the C<DBI> database driver used by the plugin.

=head3 get_databases( \%connect_parameters );

If C<get_databases> uses the method C<get_db_handle>, C<\%connect_parameters> can be passed to C<get_db_handle> as the
second argument. See L</get_db_handle> for more info about the passed hash reference.

Returns two array references: the first reference refers to the array of user-databases the second refers to the array
of system-databases. The second array reference is optional.

If the option I<add_metadata> is true, user-databases and system-databases are used else only the user-databases are
used.

=head3 get_db_handle( $database_name, \%connect_parameters )

The data in C<\%connect_parameters> represents the settings from the option I<Database settings>. Which
I<Database settings> are available depends on the methods C<read_arguments>, C<env_variables> and C<set_attributes>.

For example the hash of hashes for a C<mysql> plugin could look like this:

    $connect_parameters = {
        use_env_var => {
            DBI_HOST => 1,
            DBI_USER => 0,
            DBI_PASS => 0,
        },
        arguments => {
            host => undef,
            pass => undef,
            user => 'db_user_name',
            port => undef
        },
        attributes => {
            mysql_enable_utf8 => 1
        },
        required => {
            port => 0,
            user => 1,
            pass => 1,
            host => 1
        },
        secret => {
            port => 0,
            host => 0,
            pass => 1,
            user => 0
        },
    };


C<db-browser> expects a database handle with the attribute I<RaiseError> enabled.

Returns the database handle.

=head2 Optional methods

=head3 DB configuration methods

If the following three methods are available, the C<db-brower> user can configure the different database settings in the
options menu. These configurations are then available in the C<get_db_handle> argument C<$connect_parameter>.

If the database driver is C<SQLite>, only C<set_attributes> is used.

=head4 read_arguments()

Returns a reference to an array of hashes. The hashes have two or three key-value pairs:

    { name => 'string', prompt => 'string', secret => true/false }

C<name> holds the field name for example like "user" or "host".

The value of C<prompt> is used as the prompt string, when the user is asked for the data. The C<prompt> entry is
optional. If C<prompt> doesn't exist, the value of C<name> is used instead.

If C<secret> is true, the user input should not be echoed to the terminal. Also the data is not stored in the
plugin configuration file if C<secret> is true.

An example C<read_arguments> method:

    sub read_arguments {
        my ( $self ) = @_;
        return [
            { name => 'host', prompt => "Host",     secret => 0 },
            { name => 'port', prompt => "Port",     secret => 0 },
            { name => 'user', prompt => "User",     secret => 0 },
            { name => 'pass', prompt => "Password", secret => 1 },
        ];
    }

The information returned by the method C<read_arguments> is used to build the C<db-browser> options menu entry I<Fields>
and I<Login Data>.

=head4 env_variables()

Returns a reference to an array of environment variables.

An example C<env_variables> method:

    sub env_variables {
        my ( $self ) = @_;
        return [ qw( DBI_DSN DBI_HOST DBI_PORT DBI_USER DBI_PASS ) ];
    }

See the C<db-browser -h> option I<ENV Variables>.

=head4 set_attributes()

Returns a reference to an array of hashes. The hashes have three or four key-value pairs:

    { name => 'string', prompt => 'string', default => index, values => [ value_1, value_2, value_3, ... ] }

The value of C<name> is the name of the database connection attribute.

The value of C<prompt> is used as the prompt string. The C<prompt> entry is optional. If C<prompt> doesn't exist, the
value of C<name> is used instead.

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

C<set_attributes> determines the database handle attributes offered in the C<db-browser> option
I<DB Options>.

=head3 SQL related methods

The following methods are already built in. These methods provided by the plugin overwrite the built in methods.

Whether passed column names are quoted or not depends on how C<db-browser> was configured.

=head4 get_schemas( $dbh, $database_name )

C<$dbh> is the database handle returned by the method C<db_hanlde>.

Returns the user-schemas as an array-reference and the system-schemas as an array-reference (if any).

If the option I<add_metadata> is true, user-schemas and system-schemas are used else only the user-schemas are used.

=head4 regexp( $column_name, $do_not_match, $case_sensitive )

C<$do_not_match> and C<$case_sensitive> are true or false.

Returns the SQL regexp substatement.

Use the appropriate placeholder instead of the string that should match or not match the regexp.

Example (C<mysql>):

    sub regexp {
        my ( $self, $col, $do_not_match, $case_sensitive ) = @_;
        if ( $do_not_match ) {
            return ' '. $col . ' NOT REGEXP ?'        if ! $case_sensitive;
            return ' '. $col . ' NOT REGEXP BINARY ?' if   $case_sensitive;
        }
        else {
            return ' '. $col . ' REGEXP ?'            if ! $case_sensitive;
            return ' '. $col . ' REGEXP BINARY ?'     if   $case_sensitive;
        }
    }

=head4 concatenate( \@strings )

Returns the SQL substatement which concatenates the passed strings.

Example (C<Pg>):

    sub concatenate {
        my ( $self, $arg ) = @_;
        return join( ' || ', @$arg );
    }

=head4 epoch_to_datetime( $column_name, $interval )

The interval is C<1> (seconds), C<1000> (milliseconds) or C<1000000> (microseconds).

Returns the SQL "epoch to datetime" substatement.

Example (C<mysql>):

    sub epoch_to_datetime {
        my ( $self, $col, $interval ) = @_;
        return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d %H:%i:%s')";
    }

=head4 epoch_to_date( $column_name, $interval )

The interval is C<1> (seconds), C<1000> (milliseconds) or C<1000000> (microseconds).

Returns the SQL "epoch to date" substatement.

Example (C<mysql>):

    sub epoch_to_date {
        my ( $self, $col, $interval ) = @_;
        return "FROM_UNIXTIME($col/$interval,'%Y-%m-%d')";
    }

=head4 truncate( $column_name, $precision )

C<$precision> is an integer value.

The SQL truncate substatement.

Example (C<mysql>):

    sub truncate {
        my ( $self, $col, $precision ) = @_;
        return "TRUNCATE($col,$precision)";
    }

=head4 bit_length( $column_name )

Returns the SQL bit length substatement.

Example (C<Pg>):

    sub bit_length {
        my ( $self, $col ) = @_;
        return "BIT_LENGTH($col)";
    }

=head4 char_length( $column_name )

Returns the SQL char length substatement.

Example (C<Pg>):

    sub char_length {
        my ( $self, $col ) = @_;
        return "CHAR_LENGTH($col)";
    }

=head1 EXAMPLE

A simple plugin which provides only the required methods:

    package App::DBBrowser::DB::MyPlugin;
    use strict;
    use DBI;

    sub new {
        my ( $class, $info ) = @_;  # no use for $info in this plugin
        my $self = {};
        return bless $self, $class;
    }

    sub get_db_driver {
        my ( $self ) = @_;
        return 'mysql';
    }

    sub get_db_handle {
        my ( $self, $db, $connect_parameter ) = @_;
        # "$connect_parameter" contains data if the plugin provides the methods "env_variables",
        # "read_arguments" and "set_attributes"
        my $dbh = DBI->connect( "DBI:mysql:dbname=$db", 'user', 'password', {
            RaiseError => 1,
            PrintError => 0,
        }) or die $DBI::errstr;
        return $dbh;
    }

    sub get_databases {
        my ( $self, $connect_parameter ) = @_;
        return [ 'My_DB_1', 'My_DB_2' ];
    }

    1;

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2018 Matthäus Kiem.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
