# ABSTRACT: A simple interface to ArangoDB REST API
package Arango::DB;
$Arango::DB::VERSION = '0.003';
use Arango::DB::Database;
use Arango::DB::Collection;

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use MIME::Base64 3.11 'encode_base64url';
use URI::Encode qw(uri_encode);

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

sub _auth {
    my $self = shift;
    return "Basic " . encode_base64url( $self->{username} . ":" . $self->{password} );
}

my %API = (
    'list_databases'  => {
        method => 'get',
        uri => '_api/database',
        'params' => { details => 'boolean' }
    },
    'create_database' => {
        method => 'post',
        uri => '_api/database',
        'builder' => sub { 
            my ($self, %params) = @_;
            return Arango::DB::Database->new(arango => $self, 'name' => $params{name});
        }
    },
    'create_document' => {
        method => 'post',
        uri => '{database}_api/document/{collection}'
    },
    'create_collection' => {
        method => 'post',
        uri => '{database}_api/collection',
        'builder' => sub {
            my ($self, %params) = @_;
            return Arango::DB::Collection->new(arango => $self, database => $params{database}, 'name' => $params{name});
        }
    },
    'delete_collection' => {
        method => 'delete',
        uri => '{database}_api/collection/{name}'
    },
    'delete_database' => {
        method => 'delete',
        uri => '_api/database/{name}'
    },
    'list_collections' => {
        method => 'get',
        uri => '{database}_api/collection'
    },
    'all_keys' => {
        method => 'put',
        uri => '{database}_api/simple/all-keys'
    },
    'version' => {
        method => 'get',
        uri => '_api/version'
    },
    'create_cursor' => {
        method => 'post',
        uri => '{database}_api/cursor'
    },
    
);


sub version {
    my ($self, %opts) = @_;
    return $self->_api('version', {}, \%opts);
}

sub list_collections {
    my ($self, $name) = @_;
    return $self->_api('list_collections', { database => $name });
}

sub database {
    my ($self, $name) = @_;
    my $databases = $self->list_databases;
    if (grep {$name eq $_} @$databases) {
        return Arango::DB::Database->new( arango => $self, name => $name);
    } else {
        die "Arango::DB | Database not found."
    }
}

sub list_databases {
    my $self = shift;
    return $self->_api('list_databases');
}

sub create_database {
    my ($self, $name) = @_;
    return $self->_api('create_database', { name => $name });
}

sub delete_database {
    my ($self, $name) = @_;
    return $self->_api('delete_database', { name => $name });
}

sub _check_options {
    my ($params, $schema) = @_;
    for my $key (keys %$params) {
        delete $params->{$key} unless exists $schema->{$key};
        if ($schema->{$key} eq "boolean" && $schema->{$key} !~ /^(true|false)$/) {
            $params->{$key} = $params->{$key} ? "true" : "false"
        }
    }
    return $params;
}

sub _api {
    my ($self, $action, $body, $uri_opts) = @_;
    
    my $uri = $API{$action}{uri};

    $uri =~ s!\{database\}! defined $body->{database} ? "_db/$body->{database}/" : "" !e;
    $uri =~ s/\{([^}]+)\}/$body->{$1}/g;
    
    my $url = "http://" . $self->{host} . ":" . $self->{port} . "/" . $uri;

    my $opts = {};
    if (ref($body) eq "HASH") {
        $opts = { content => exists $body->{body} ? encode_json $body->{body} : encode_json $body };
    }
    
    if (ref($uri_opts) eq "HASH" && %$uri_opts) {
        if (exists($API{$action}{params})) {
            $uri_opts = _check_options($uri_opts, $API{$action}{params});
        }
        $url .= "?" . join("&", map { "$_=" . uri_encode($uri_opts->{$_} )} keys %$uri_opts);
    }
    
    # print STDERR "\n -- $API{$action}{method} | $url\n";

    my $response = $self->{http}->request($API{$action}{method}, $url, $opts);

    if ($response->{success}) {
        my $ans = decode_json($response->{content});
        if ($ans->{error}) {
            return $ans;
        } elsif (exists($API{$action}{builder})) {
            return $API{$action}{builder}->( $self, %$body );
        } elsif (exists($ans->{result})) {
            return $ans->{result};
        } else {
            return $ans;
        }
    }
    else {
        die "Arango::DB | ($response->{status}) $response->{reason}";   
    }
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::DB - A simple interface to ArangoDB REST API

=head1 VERSION

version 0.003

=head1 SYNOPSYS

    use Arango::DB;

    my $server = Arango::DB->new( host => '127.0.0.1',
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

=item L<Arango::DB>

This is the main module and hopefully the unique one you need to import in your code.
It performs basic operations with the server, and returns objects of different kinds when needed.

=item L<Arango::DB::Database>

Represents a specific database. A simple object to keep track of the database you are working with,
so you do not need to specify it everytime.

=item L<Arango::DB::Collection>

Represents a collection from a specific database. Again, it just keeps track of the collection name
and the database where it resided.

=back

=head1 METHODS

=head2 new

      my $db = Arango::DB->new( %options );

To start using the module you need a L<Arango::DB> instance. Use the C<new> method to create one.
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

=head2 C<version>

    my $version_info = $db->version;
    my $detailed_info = $db->version( 'details' => 'true' );

Returns a hash reference with basic server info. Detailed information can be requested with the C<details> option. 

=head2 C<list_databases>

    my $databases = $db->list_databases;

Queries the server about available databases. Returns an array ref of database names.

=head2 C<create_database>

    my $new_db = $db->create_database("new_db");

Creates a new database, and returns a reference to a L<Arango::DB::Database> representing it.

=head2 C<database>

    my $system_db = $db->database("_system");

Opens an existing database, and returns a reference to a L<Arango::DB::Database> representing it.

=head2 C<delete_database>

    $db->delete_database("some_db");

Deletes an existing database.

=head2 C<list_collections>

    my $collections = $db->list_collections;

Lists collection details without specifying a specific database;

=head1 EXCEPTIONS

This module is written to die in any exception. Please use a try/catch module or eval, to detect them.

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
