package Dancer::Session::DBIC;

=head1 NAME

Dancer::Session::DBIC - DBIx::Class session engine for Dancer

=head1 VERSION

0.006

=head1 DESCRIPTION

This module implements a session engine for Dancer by serializing the session,
and storing it in a database via L<DBIx::Class>. The default serialization method is L<JSON>,
though one can specify any serialization format you want. L<YAML> and L<Storable> are
viable alternatives.

JSON was chosen as the default serialization format, as it is fast, terse, and portable.

=head1 SYNOPSIS

Example configuration:

    session: "DBIC"
    session_options:
      dsn:      "DBI:mysql:database=testing;host=127.0.0.1;port=3306" # DBI Data Source Name
      schema_class:    "Interchange6::Schema"  # DBIx::Class schema
      user:     "user"      # Username used to connect to the database
      pass: "password"  # Password to connect to the database
      resultset: "MySession" # DBIx::Class resultset, defaults to Session
      id_column: "my_session_id" # defaults to sessions_id
      data_column: "my_session_data" # defaults to session_data

In conjunction with L<Dancer::Plugin::DBIC>, you can simply use the schema
object provided by this plugin in your application, either by
providing the name of the schema used by the plugin in the config:

    session_options:
        schema: default

Or by passing the schema object directly in the code:

    set session_options => {schema => schema};

Custom serializer / deserializer can be specified as follows:

    set 'session_options' => {
        schema       => schema,
        serializer   => sub { YAML::Dump(@_); },
        deserializer => sub { YAML::Load(@_); },
    };

=head1 SESSION EXPIRATION

A timestamp field that updates when a session is updated is recommended, so you can expire sessions server-side as well as client-side.

This session engine will not automagically remove expired sessions on the server, but with a timestamp field as above, you should be able to to do this manually.

=head1 RESULT CLASS EXAMPLE

This result class would work as-is with the default values of C<session_options>.
It uses L<DBIx::Class::TimeStamp> to auto-set the C<created>
and C<last_modified> timestamps.

    package MySchema::Result::Session;

    use strict;
    use warnings;

    use base 'DBIx::Class::Core';

    __PACKAGE__->load_components(qw(TimeStamp));

    __PACKAGE__->table('sessions');

    __PACKAGE__->add_columns(
        sessions_id => {
            data_type => 'varchar', size => 255
        },
        session_data => {
            data_type => 'text'
        },
        created => {
            data_type => 'datetime', set_on_create => 1
        },
        last_modified => {
            data_type => 'datetime', set_on_create => 1, set_on_update => 1
        },
    );

    __PACKAGE__->set_primary_key('sessions_id');

    1;

=cut

use strict;
use parent 'Dancer::Session::Abstract';

use Dancer qw(:syntax !load);
use DBIx::Class;
use Try::Tiny;
use Module::Load;
use Scalar::Util qw(blessed);

our $VERSION = '0.006';

my %dbic_handles;

=head1 METHODS

=head2 create()

Creates a new session. Returns the session object.

=cut

sub create {
    return Dancer::Session::DBIC->new->flush;
}


=head2 flush()

Write the session to the database. Returns the session object.

=cut

sub flush {
    my $self = shift;
    my $handle = $self->_dbic;

    my %session_data = ($handle->{id_column} => $self->id,
                        $handle->{data_column} => $self->_serialize,
                       );

    my $session = $self->_rset->update_or_create(\%session_data);

    return $self;
}

=head2 retrieve($id)

Look for a session with the given id.

Returns the session object if found, C<undef> if not. Logs a debug-level warning
if the session was found, but could not be deserialized.

=cut

sub retrieve {
    my ($self, $session_id) = @_;
    my $session_object;
    my $handle = $self->_dbic;
    my $data_column = $handle->{data_column};

    $session_object = $self->_rset->find($session_id);

    # Bail early if we know we have no session data at all
    if (!defined $session_object) {
        debug "Could not retrieve session ID: $session_id";
        return;
    }

    my $session_data = $session_object->$data_column;

    # No way to check that it's valid JSON other than trying to deserialize it
    my $session = try {
        $self->_deserialize($session_data);
    } catch {
        debug "Could not deserialize session ID: $session_id - $_";
        return;
    };

    bless $session, __PACKAGE__ if $session;
}


=head2 destroy()

Remove the current session object from the database.

=cut

sub destroy {
    my $self = shift;

    if (!defined $self->id) {
        debug "No session ID passed to destroy method";
        return;
    }

    $self->_rset->find($self->id)->delete;
}

# Creates and connects schema

sub _dbic {
    my $self = shift;

    # To be fork safe and thread safe, use a combination of the PID and TID (if
    # running with use threads) to make sure no two processes/threads share
    # handles.  Implementation based on DBIx::Connector by David E. Wheeler.
    my $pid_tid = $$;
    $pid_tid .= '_' . threads->tid if $INC{'threads.pm'};

    # OK, see if we have a matching handle
    my $handle = $dbic_handles{$pid_tid};

    if ($handle->{schema}) {
        return $handle;
    }

    my $settings = setting('session_options');

    # Prefer an active schema over a schema class.
    if ( my $schema = $settings->{schema}) {
        if (blessed $schema) {
            $handle->{schema} = $schema;
        }
        elsif( ref $schema ) {
            $handle->{schema} = $schema->();
        }
        else {
            die "can't use named schema: Dancer::Plugin::DBIC not loaded\n"
                unless $Dancer::Plugin::DBIC::VERSION;
            $handle->{schema} = Dancer::Plugin::DBIC::schema($schema);
        }
    }
    elsif (! defined $settings->{schema_class}) {
        die "No schema class defined.";
    }
    else {
        my $schema_class = $settings->{schema_class};

        $handle->{schema} = $self->_load_schema_class($schema_class,
                                                      $settings->{dsn},
                                                      $settings->{user},
                                                      $settings->{pass});
    }

    $handle->{resultset} = $settings->{resultset} || 'Session';
    $handle->{id_column} = $settings->{id_column} || 'sessions_id';
    $handle->{data_column} = $settings->{data_column} || 'session_data';

    $dbic_handles{$pid_tid} = $handle;

    return $handle;
}

# Returns specific resultset
sub _rset {
    my ($self, $name) = @_;

    my $handle = $self->_dbic;

    return $handle->{schema}->resultset($handle->{resultset});
}

# Loads schema class
sub _load_schema_class {
    my ($self, $schema_class, @conn_info) = @_;
    my ($schema_object);

    if ($schema_class) {
        $schema_class =~ s/-/::/g;
        eval { load $schema_class };
        die "Could not load schema_class $schema_class: $@" if $@;
        $schema_object = $schema_class->connect(@conn_info);
    } else {
        my $dbic_loader = 'DBIx::Class::Schema::Loader';
        eval { load $dbic_loader };
        die "You must provide a schema_class option or install $dbic_loader."
            if $@;
        $dbic_loader->naming('v7');
        $schema_object = DBIx::Class::Schema::Loader->connect(@conn_info);
    }

    return $schema_object;
}

# Default Serialize method
sub _serialize {
    my $self = shift;
    my $settings = setting('session_options');

    if (defined $settings->{serializer}) {
        return $settings->{serializer}->({%$self});
    }

    # A session is by definition ephemeral - Store it compactly
    # This is the Dancer function, not from JSON.pm
    return to_json({%$self}, { pretty => 0, convert_blessed => 1 });
}


# Default Deserialize method
sub _deserialize {
    my ($self, $json) = @_;
    my $settings = setting('session_options');

    if (defined $settings->{deserializer}) {
        return $settings->{deserializer}->($json);
    }

    # This is the Dancer function, not from JSON.pm
    return from_json($json, { utf8 => 0});
}

=head1 SEE ALSO

L<Dancer>, L<Dancer::Session>

=head1 AUTHOR

Stefan Hornburg (Racke) <racke@linuxia.de>

=head1 ACKNOWLEDGEMENTS

Based on code from L<Dancer::Session::DBI> written by James Aitken
and code from L<Dancer::Plugin::DBIC> written by Naveed Massjouni.

Enhancements provided by:

Yanick Champoux (GH #6, #7).
Peter Mottram (GH #5, #8).

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) Stefan Hornburg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


1;
