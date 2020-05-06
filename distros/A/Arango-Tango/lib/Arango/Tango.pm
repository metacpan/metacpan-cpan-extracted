# ABSTRACT: A simple interface to ArangoDB REST API
package Arango::Tango;
$Arango::Tango::VERSION = '0.012';
use base 'Arango::Tango::API';
use Arango::Tango::Database;
use Arango::Tango::Collection;

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use MIME::Base64 3.11 'encode_base64url';
use URI::Encode qw(uri_encode);

BEGIN {
Arango::Tango::API::_install_methods "Arango::Tango" => {
    engine                  => { rest => [ get => '_api/engine' ] },
    cluster_endpoints       => { rest => [ get => '_api/cluster/endpoints' ] },
    server_id               => { rest => [ get => '_admin/server/id' ] },
    status                  => { rest => [ get => '_admin/status' ] },
    time                    => { rest => [ get => '_admin/time' ] },
    statistics              => { rest => [ get => '_admin/statistics' ] },
    statistics_description  => { rest => [ get => '_admin/statistics-description' ] },
    target_version          => { rest => [ get => '_admin/database/target-version' ] },
    log_level               => { rest => [ get => '_admin/log/level' ] },
    server_role             => { rest => [ get => '_admin/server/role' ] },
    server_mode             => { rest => [ get => '_admin/server/mode' ] },
    server_availability     => { rest => [ get => '_admin/server/availability' ] },
    list_users              => { rest => [ get => '_api/user' ] },
    current_database        => { rest => [ get => '_api/database/current' ] },

    version                 => { rest => [ get => '_api/version' ], schema => {  details => { type => 'boolean' } }},

    delete_database         => {
        signature => [ 'name' ],
        rest => [ delete => '_api/database/{name}' ]
    },

    delete_user             => {
        signature => [ 'username' ],
        rest => [ delete => '_api/user/{username}' ]
    },

    replace_user            => {
        signature => [ 'username' ],
        rest => [ put => '_api/user/{username}' ],
        schema => { password => { type => 'string'  },
                    active   => { type => 'boolean' },
                    extra    => { type => 'object', additionalProperties => 1 }}},

    user                    => {
        signature => [ 'username' ],
        rest => [ get => '_api/user/{username}' ] },

    update_user             => {
        signature => [ 'user' ],
        rest => [ patch => '_api/user/{user}' ],
        schema => { password => { type => 'string'  },
                    active   => { type => 'boolean' },
                    extra    => { type => 'object', additionalProperties => 1 }}},

    user_databases  => {
        signature => [ 'username' ],
        rest      => [ get => '_api/user/{username}/database' ],
        schema    => { full => {type => 'boolean' }}},

    get_access_level => {
        signature => ['username','database','?collection'],
        rest      => [ get => '_api/user/{username}/database/{database}/{collection}' ],
       },

    clear_access_level => {
        signature => ['username','database','?collection'],
        rest      => [ delete => '_api/user/{username}/database/{database}/{collection}' ],
       },

    set_access_level => {
        signature => ['username', 'grant', 'database', '?collection'],
        rest      => [ put => '_api/user/{username}/database/{database}/{collection}' ],
        schema    => { grant => { type => 'string', enum => [qw'rw ro none'], default => 'none' }},
    },

    create_database => {
        signature => [ 'name' ],
        rest => [ post => '_api/database' ],
        schema  => { name  => { type => 'string' },
                     users => {
                         type => 'array',
                         items => {
                             type => 'object',
                             additionalProperties => 0,
                             properties => {
                                 username => { type => 'string' },
                                 passwd   => { type => 'string'},
                                 active   => { type => 'boolean' },
                                 extra    => { type => 'object', additionalProperties => 1 }
                             }}}},
        builder => sub {
            my ($self, %params) = @_;
            return Arango::Tango::Database->_new(arango => $self, 'name' => $params{name});
        },
    },

    create_user => {
        signature => [ 'user' ],
        rest => [ post => '_api/user'],
        schema => {
            password => { type => 'string'  },
            active   => { type => 'boolean' },
            user     => { type => 'string'  },
            extra    => { type => 'object', additionalProperties => 1 },
        }
    },

    log => {
        rest => [ get => '_admin/log' ],
        schema => {
            upto   => { type => 'string', default => 'info', enum => [qw'fatal error warning info debug 0 1 2 3 4'] },
            level  => { type => 'string', default => 'info', enum => [qw'fatal error warning info debug'] },
            size   => { type => 'integer', minimum => 0 },
            offset => { type => 'integer', minimum => 0 },
            search => { type => 'string' },
            sort   => { type => 'string', default => 'asc', enum => [qw'asc desc'] }, # asc, desc
        }
    }
};

}

sub new {
    my ($package, %opts) = @_;
    my $self = bless { %opts } => $package;

    $self->{host} ||= $ENV{ARANGO_DB_HOST} || "localhost";
    $self->{port} ||= $ENV{ARANGO_DB_PORT} || 8529;

    $self->{username} ||= $ENV{ARANGO_DB_USERNAME} || "root";
    $self->{password} ||= $ENV{ARANGO_DB_PASSWORD} || "";

    $self->{headers} = {
        Authorization => $self->_auth,
        Accept => 'application/json',
    };
    $self->{http} = HTTP::Tiny->new(default_headers => $self->{headers});

    return $self;
}


sub _auth {
    my $self = shift;
    return "Basic " . encode_base64url( $self->{username} . ":" . $self->{password} );
}

sub database {
    my ($self, $name) = @_;
    my $databases = $self->list_databases;
    if (grep {$name eq $_} @$databases) {
        return Arango::Tango::Database->_new( arango => $self, name => $name);
    } else {
        die "Arango::Tango | Database not found."
    }
}

sub list_databases {
    my $self = shift;
    return  $self->_api('accessible_databases')->{result};
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::Tango - A simple interface to ArangoDB REST API

=head1 VERSION

version 0.012

=head1 SYNOPSYS

    use Arango::Tango;

    my $server = Arango::Tango->new( host     => '127.0.0.1',
                                     username => 'root',
                                     password => '123123123');

    my $new_database = $server->create_database("mydb");
    my $collection = $server->create_collection("mycollection");
    $collection->create_document( { 'Hello' => 'World'} );

=head1 DISCLAIMER

The module is B<VERY> incomplete. It is being written accordingly with my 
personal needs. While I tried L<ArangoDB2> it didn't work out of the box as I expected,
and decided to write a simple strightforward solution.

Patches and suggestions are B<VERY> welcome.

=head1 USAGE

The distribution is divided in different modules, namely:

=over 4

=item L<Arango::Tango>

This is the main module and hopefully the unique one you need to import in your code.
It performs basic operations with the server, and returns objects of different kinds when needed.

=item L<Arango::Tango::Database>

Represents a specific database. A simple object to keep track of the database you are working with,
so you do not need to specify it everytime.

=item L<Arango::Tango::Collection>

Represents a collection from a specific database. Again, it just keeps track of the collection name
and the database where it resided.

=back

=head1 METHODS

=head2 Constructor

=over 4

=item C<new>

      my $db = Arango::Tango->new( %options );

To start using the module you need a L<Arango::Tango> instance. Use the C<new> method to create one.
Supported options are:

=over 4

=item C<host>

Host name. Defaults to C<localhost>.

=item C<port>

ArangoDB Port. Defaults to C<8529>.

=item C<username>

Username to be used to connect to ArangoDB. Defaults to C<root>.

=item C<password>

Password to be used to connect to ArangoDB. Default to the empty string.

=back

=back

=head2 Database Manipulation

=over 4

=item C<list_databases>

    my $databases = $db->list_databases;

Retrieves the list of all databases the current user can access without
specifying a different username or password.

=item C<create_database>

    my $new_db = $db->create_database("new_db");

Creates a new database, and returns a reference to a L<Arango::Tango::Database> representing it.

=item C<database>

    my $system_db = $db->database("_system");

Opens an existing database, and returns a reference to a L<Arango::Tango::Database> representing it.

=item C<delete_database>

    $db->delete_database("some_db");

Deletes an existing database.

=item C<current_database>

    $db->current_database;

Returns information about the current database. At the moment, to obtain an object representing it, use the C<database> method.

=back

=head2 User Management

=over 4

=item C<create_user>

    $db->create_user('username', passwd => "3432rfsdADF");

Creates an user. Optional parameters are C<passwd>, C<active> and C<extra>.

=item C<update_user>

    $db->update_user('username', extra => { email => 'me@there.com' } );

Updates an existing user. Optional parameters are C<passwd>, C<active> and C<extra>.

=item C<replace_user>

    $db->replace_user('username', extra => { email => 'me@there.com' } );

Replace an existing user. Optional parameters are C<passwd>, C<active> and C<extra>.

=item C<delete_user>

    $db->delete_user('username');

Deletes an user.

=item C<list_users>

    $users = $db->list_users;

Fetches data about all users. You need the Administrate server access level
in order to execute this REST call. Otherwise, you will only get information
about yourself.

=item C<user>

    $user = $db->user("john");

Fetches data about the specified user. You can fetch information about
yourself or you need the Administrate server access level in order to
execute this REST call.

=item C<user_databases>

    $dbs = $db->user_databases("john", full => 1);

Fetch the list of databases available to the specified user. You need
Administrate for the server access level in order to execute this REST
call.

=item C<get_access_level>

    $perms = $db->get_access_level("john", "myDatabase");
    $perms = $db->get_access_level("john", "myDatabase", $collection );

Fetch the database or the collection access level for a specific user.

=item C<set_access_level>

    $perms = $db->set_access_level("john", "rw", "myDatabase");
    $perms = $db->set_access_level("john", "ro", "myDatabase", $collection);

Sets the database or the collection access level for a specific user.

=item C<clear_access_level>

    $db->clear_access_level("john", "myDatabase");
    $db->clear_access_level("john", "myDatabase", $collection);

Clears the database or the collection access level for a specific user.

=back

=head2 Querying Server Metadata

=over 4

=item C<target_version>

    my $ans = $db->target_version;
    $target_version = $ans->{target_version};   # might change in the future...

Returns the database version that this server requires.
The version is returned in the version attribute of the result.

=item C<log>

    my $logs = $db-a>log(upto => "warning");

Returns fatal, error, warning or info log messages from the server’s global log.

=item C<log_level>

    my $log_levels = $db->log_level();

Returns the server’s current log level settings.

=item C<server_availability>

    my $info = $db->server_availability();

Return availability information about a server.

=item C<server_id>

    my $id = $db->server_id();

Returns the id of a server in a cluster. The request will fail if the server is not running in cluster mode.

=item C<server_mode>

    my $mode = $db->server_mode();

Return mode information about a server.

=item C<server_role>

    my $mode = $db->server_role();

Returns the role of a server in a cluster.

=item C<cluster_endpoints>

    my $endpoints = $db->cluster_endpoints;

Returns an object with an attribute endpoints, which contains an array
of objects, which each have the attribute endpoint, whose value is a
string with the endpoint description. There is an entry for each
coordinator in the cluster. This method only works on coordinators in
cluster mode. In case of an error the error attribute is set to true.

=item C<version>

    my $version_info = $db->version;
    my $detailed_info = $db->version( 'details' => 1 );

Returns a hash reference with basic server info. Detailed information can be requested with the C<details> option.

=item C<engine>

   my $engine = $db->engine;

Returns the storage engine the server is configured to use.

=item C<statistics>

   my $stats = $db->statistics;

Read the statistics of a server.

=item C<statistics_description>

   my $stats_desc = $db->statistics_description;

Statistics description

=item C<status>

   my $status = $db->status;

Return status information

=item C<time>

   my $time = $db->time;

Return system time

=back

=head1 CAVEATS

=head2 Options Validation

Most optional options are validated and fitted using
C<JSON::Scheme::Fit>. This means that the module will try to remove
invalid options and adapt values from valid options to valid values.
While this can make some mistakes silently, it was preferred to dying
at any structure problem.

In future versions there might be an option to activate strict schema
check making the module to die on an invalid options.

=head2 Exceptions

This module is written to die in any exception. Please use a try/catch
module or eval, to detect them.

=head1 CONTRIBUTORS

=over 4

=item *

João Miguel Ferreira

=back

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2020 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
