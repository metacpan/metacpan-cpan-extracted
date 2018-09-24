package Dancer2::Session::DBIC;

use Dancer2::Core::Types;
use DBIx::Class;
use DBICx::Sugar;
use Scalar::Util 'blessed';
use Module::Runtime 'use_module';
use Try::Tiny;

our $_schema;

use Moo;
with 'Dancer2::Core::Role::SessionFactory';
use namespace::clean;

our $VERSION = '0.120';

=head1 NAME

Dancer2::Session::DBIC - DBIx::Class session engine for Dancer2

=head1 VERSION

0.120

=head1 DESCRIPTION

This module implements a session engine for Dancer2 by serializing the session,
and storing it in a database via L<DBIx::Class>.

JSON was chosen as the default serialization format, as it is fast, terse,
and portable.

=head1 SYNOPSIS

Example configuration:

    session: "DBIC"
    engines:
      session:
        DBIC:
          dsn:      "DBI:mysql:database=testing;host=127.0.0.1;port=3306" # DBI Data Source Name
          schema_class:    "Interchange6::Schema"  # DBIx::Class schema
          user:     "user"      # Username used to connect to the database
          password: "password"  # Password to connect to the database
          resultset: "MySession" # DBIx::Class resultset, defaults to Session
          id_column: "my_session_id" # defaults to sessions_id
          data_column: "my_session_data" # defaults to session_data
          serializer: "YAML"    # defaults to JSON

Or if you are already using L<Dancer2::Plugin::DBIC> and want to use its
existing configuration for a database section named 'default' with all else
set to default in this module then you could simply use:

    session: "DBIC"
    engines:
      session:
        DBIC:
          db_connection_name: default

=head1 SESSION EXPIRATION

A timestamp field that updates when a session is updated is recommended, so you can expire sessions server-side as well as client-side.

This session engine will not automagically remove expired sessions on the server, but with a timestamp field as above, you should be able to to do this manually.

=cut

=head1 ATTRIBUTES

=head2 schema_class

DBIx::Class schema class, e.g. L<Interchange6::Schema>.

=cut

has schema_class => (
    is => 'ro',
    isa => Str,
);

=head2 db_connection_name

The L<Dancer2::Plugin::DBIC> database connection name.

If this option is provided then L</schema_class>, L</dsn>, L</user> and
L</password> are all ignored.

=cut

has db_connection_name => (
    is  => 'ro',
    isa => Str,
);

=head2 resultset

DBIx::Class resultset, defaults to C<Session>.

=cut

has resultset => (
    is => 'ro',
    isa => Str,
    default => 'Session',
);

=head2 id_column

Column for session id, defaults to C<sessions_id>.

If this column is not the primary key of the table, it should have
a unique constraint added to it.  See L<DBIx::Class::ResultSource/add_unique_constraint>.

=cut

has id_column => (
    is => 'ro',
    isa => Str,
    default => 'sessions_id',
);

=head2 data_column

Column for session data, defaults to C<session_data>.

=cut

has data_column => (
    is => 'ro',
    isa => Str,
    default => 'session_data',
);

=head2 dsn

L<DBI> dsn to connect to the database.

=cut

has dsn => (
    is => 'ro',
    isa => Str,
);

=head2 user

Database username.

=cut

has user => (
    is => 'ro',
);

=head2 password

Database password.

=cut

has password => (
    is => 'ro',
);

=head2 schema

L<DBIx::Class> schema.

=cut

has schema => (
    is => 'ro',
);

=head2 serializer

Serializer to use, defaults to JSON.

L<Dancer2::Session::DBIC> provides the following serializer classes:

=over

=item JSON - L<Dancer2::Session::DBIC::Serializer::JSON>

=item Sereal - L<Dancer2::Session::DBIC::Serializer::Sereal>

=item YAML - L<Dancer2::Session::DBIC::Serializer::YAML>

=back

If you do not use the default JSON serializer then you might need to install
additional modules - see the specific serializer class for details.

You can also use your own serializer class by passing the fully-qualified class
name as argument to this option, e.g.: MyApp::Session::Serializer

=cut

has serializer => (
    is      => 'ro',
    isa     => Str,
    default => 'JSON',
);

=head2 serializer_object

Vivified L</serializer> object.

=cut

has serializer_object => (
    is  => 'lazy',
    isa => Object,
);

sub _build_serializer_object {
    my $self  = shift;
    my $class = $self->serializer;
    if ( $class !~ /::/ ) {
        $class = __PACKAGE__ . "::Serializer::$class";
    }

    my %args;

    $args{serialize_options} = $self->serialize_options
      if $self->serialize_options;

    $args{deserialize_options} = $self->deserialize_options
      if $self->deserialize_options;

    use_module($class)->new(%args);
}

=head2 serialize_options

Options to be passed to the constructor of the C<serializer> class
as a hash reference.

=cut

has serialize_options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

=head2 deserialize_options

Options to be passed to the constructor of the C<deserializer> class
as a hash reference.

=cut

has deserialize_options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

=head1 METHODS

=cut

sub _sessions { return [] };

=head2 _flush

Write the session to the database. Returns the session object.

=cut

sub _flush {
    my ($self, $id, $session) = @_;

    my %session_data = ($self->id_column => $id,
                        $self->data_column => $self->serializer_object->serialize($session),
                       );

    $self->_rset->update_or_create(\%session_data);

    return $self;
}

=head2 _retrieve($id)

Look for a session with the given id.

Returns the session object if found, C<undef> if not.
Dies if the session was found, but could not be deserialized.

=cut

sub _retrieve {
    my ($self, $session_id) = @_;
    my $session_object;

    $session_object = $self->_rset->find({ $self->id_column => $session_id });

    # Bail early if we know we have no session data at all
    if (!defined $session_object) {
        die "Could not retrieve session ID: $session_id";
        return;
    }

    my $data_column  = $self->data_column;
    my $session_data = $session_object->$data_column;

    # No way to check that it's valid JSON other than trying to deserialize it
    my $session = try {
        $self->serializer_object->deserialize($session_data);
    } catch {
        die "Could not deserialize session ID: $session_id - $_";
        return;
    };

    return $session;
}

=head2 _change_id( $old_id, $new_id )

Change ID of session with C<$old_id> to <$new_id>.

=cut

sub _change_id {
    my ( $self, $old_id, $new_id ) = @_;

    $self->_rset->search( { $self->id_column => $old_id } )
      ->update( { $self->id_column => $new_id } );
}

=head2 _destroy()

Remove the current session object from the database.

=cut

# as per doc: The _destroy method must be implemented. It must take
# $id as a single argument and destroy the underlying data.

sub _destroy {
    my ($self, $id) = @_;

    if (!defined $id) {
        die "No session ID passed to destroy method";
        return;
    }

    $self->_rset->find({ $self->id_column => $id})->delete;
}

# Creates and connects schema

sub _dbic {
    my $self = shift;

    return $_schema if $_schema;

    # Prefer an active schema over a schema class.
    my $schema = $self->schema;

    if (defined $schema) {
        if (blessed $schema) {
            $_schema = $schema;
        }
        else {
            $_schema = $schema->();
        }
    }
    elsif ( $self->db_connection_name ) {
        $_schema = DBICx::Sugar::schema($self->db_connection_name);
    }
    elsif (! defined $self->schema_class) {
        die "No schema class defined.";
    }
    else {
        $_schema = $self->_load_schema_class($self->schema_class,
                                                      $self->dsn,
                                                      $self->user,
                                                      $self->password);
    }

    return $_schema;
}

# Returns specific resultset
sub _rset {
    my ($self) = @_;

    return $self->_dbic->resultset($self->resultset);
}

# Loads schema class
sub _load_schema_class {
    my ($self, $schema_class, @conn_info) = @_;
    my ($schema_object);

    if ($schema_class) {
        $schema_class =~ s/-/::/g;
        try {
            use_module($schema_class);
        }
        catch {
            die "Could not load schema_class $schema_class: $_";
        };
        $schema_object = $schema_class->connect(@conn_info);
    } else {
        my $dbic_loader = 'DBIx::Class::Schema::Loader';
        try {
            use_module($dbic_loader);
        }
        catch {
            die
              "You must provide a schema_class option or install $dbic_loader.";
        };
        $dbic_loader->naming('v7');
        $schema_object = DBIx::Class::Schema::Loader->connect(@conn_info);
    }

    return $schema_object;
}

=head1 SEE ALSO

L<Dancer2>, L<Dancer2::Session>

=head1 AUTHOR

Stefan Hornburg (Racke) <racke@linuxia.de>

=head1 ACKNOWLEDGEMENTS

Based on code from L<Dancer::Session::DBI> written by James Aitken
and code from L<Dancer::Plugin::DBIC> written by Naveed Massjouni.

Peter Mottram, support for JSON, YAML, Sereal and custom
serializers, GH #8, #9, #11, #12. Also for adding _change_id
method and accompanying tests.

Rory Zweistra, GH #9.

Andy Jack, GH #2.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) Stefan Hornburg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


1;
