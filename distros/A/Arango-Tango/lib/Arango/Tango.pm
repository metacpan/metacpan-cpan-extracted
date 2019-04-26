# ABSTRACT: A simple interface to ArangoDB REST API
package Arango::Tango;
$Arango::Tango::VERSION = '0.007';
use base 'Arango::Tango::API';
use Arango::Tango::Database;
use Arango::Tango::Collection;

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use MIME::Base64 3.11 'encode_base64url';
use URI::Encode qw(uri_encode);
use JSON::Schema::Fit 0.04;

sub new {
    my ($package, %opts) = @_;
    my $self = bless { %opts } => $package;

    $self->{host} ||= $ENV{ARANGO_DB_HOST} || "localhost";
    $self->{port} ||= $ENV{ARANGO_DB_PORT} || 8529;

    $self->{username} ||= $ENV{ARANGO_DB_USERNAME} || "root";
    $self->{password} ||= $ENV{ARANGO_DB_PASSWORD} || "";

    $self->{headers} = {
        Authorization => $self->_auth
    };
    $self->{http} = HTTP::Tiny->new(default_headers => $self->{headers});

    return $self;
}


use Sub::Install qw(install_sub);
use Sub::Name qw(subname);
BEGIN {
    my $package = __PACKAGE__;
    for my $m (qw'server_id version status time statistics statistics_description target_version log log_level server_availability server_mode') {
        install_sub {
            code => subname(
                "${package}::$m",
                sub { my ($self, %opts) = @_; return $self->_api($m, \%opts) }
               ),
                 into => $package,
                 as => $m
             };
    }
}

sub _auth {
    my $self = shift;
    return "Basic " . encode_base64url( $self->{username} . ":" . $self->{password} );
}

sub list_collections {
    my ($self, $name) = @_;
    return $self->_api('list_collections', { database => $name })->{result};
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
    return  $self->_api('list_databases')->{result};
}

sub create_database {
    my ($self, $name) = @_;
    return $self->_api('create_database', { name => $name });
}

sub delete_database {
    my ($self, $name) = @_;
    return $self->_api('delete_database', { name => $name });
}

sub create_user {
    my ($self, $username, %opts) = @_;
    die "Arango::Tango | No username suplied" unless defined $username and length $username;
    return $self->_api('create_user', { %opts, user => $username });
}

sub delete_user {
    my ($self, $username) = @_;
    die "Arango::Tango | No username suplied" unless defined $username and length $username;
    return $self->_api('delete_user', { username => $username });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::Tango - A simple interface to ArangoDB REST API

=head1 VERSION

version 0.007

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

=head2 new

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

=head2 C<target_version>

    my $ans = $db->target_version;
    $target_version = $ans->{target_version};   # might change in the future...

Returns the database version that this server requires.
The version is returned in the version attribute of the result.

=head2 C<log>

    my $logs = $db-a>log(upto => "warning");

Returns fatal, error, warning or info log messages from the server’s global log.

=head2 C<log_level>

    my $log_levels = $db->log_level();

Returns the server’s current log level settings.

=head2 C<server_availability>

    my $info = $db->server_availability();

Return availability information about a server.

=head2 C<server_id>

    my $id = $db->server_id();

Returns the id of a server in a cluster. The request will fail if the server is not running in cluster mode.

=head2 C<server_mode>

    my $mode = $db->server_mode();

Return mode information about a server.

=head2 C<version>

    my $version_info = $db->version;
    my $detailed_info = $db->version( 'details' => 1 );

Returns a hash reference with basic server info. Detailed information can be requested with the C<details> option.

=head2 C<statistics>

   my $stats = $db->statistics;

Read the statistics of a server.

=head2 C<statistics_description>

   my $stats_desc = $db->statistics_description;

Statistics description

=head2 C<status>

   my $status = $db->status;

Return status information

=head2 C<time>

   my $time = $db->time;

Return system time

=head2 C<list_databases>

    my $databases = $db->list_databases;

Queries the server about available databases. Returns an array ref of database names.

=head2 C<create_database>

    my $new_db = $db->create_database("new_db");

Creates a new database, and returns a reference to a L<Arango::Tango::Database> representing it.

=head2 C<database>

    my $system_db = $db->database("_system");

Opens an existing database, and returns a reference to a L<Arango::Tango::Database> representing it.

=head2 C<delete_database>

    $db->delete_database("some_db");

Deletes an existing database.

=head2 C<list_collections>

    my $collections = $db->list_collections;

Lists collection details without specifying a specific database;

=head2 C<create_user>

    $db->create_user('username', passwd => "3432rfsdADF");

Creates an user. Optional parameters are C<passwd>, C<active> and C<extra>.

=head2 C<delete_user>

    $db->delete_user('username');

Deletes an user.

=head1 EXCEPTIONS

This module is written to die in any exception. Please use a try/catch module or eval, to detect them.

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
