package Catalyst::Plugin::Session::Store::DBIC;

use strict;
use warnings;
use base qw/Catalyst::Plugin::Session::Store::Delegate/;
use Catalyst::Exception;
use Catalyst::Plugin::Session::Store::DBIC::Delegate;
use MIME::Base64 ();
use MRO::Compat;
use Storable ();

our $VERSION = '0.14';

=head1 NAME

Catalyst::Plugin::Session::Store::DBIC - Store your sessions via DBIx::Class

=head1 SYNOPSIS

    # Create a table in your database for sessions
    CREATE TABLE sessions (
        id           CHAR(72) PRIMARY KEY,
        session_data TEXT,
        expires      INTEGER
    );

    # Create the corresponding table class
    package MyApp::Schema::Session;

    use base qw/DBIx::Class/;

    __PACKAGE__->load_components(qw/Core/);
    __PACKAGE__->table('sessions');
    __PACKAGE__->add_columns(qw/id session_data expires/);
    __PACKAGE__->set_primary_key('id');

    1;

    # In your application
    use Catalyst qw/Session Session::Store::DBIC Session::State::Cookie/;

    __PACKAGE__->config(
        # ... other items ...
        'Plugin::Session' => {
            dbic_class => 'DBIC::Session',  # Assuming MyApp::Model::DBIC
            expires    => 3600,
        },
    );

    # Later, in a controller action
    $c->session->{foo} = 'bar';

=head1 DESCRIPTION

This L<Catalyst::Plugin::Session> storage module saves session data in
your database via L<DBIx::Class>.  It's actually just a wrapper around
L<Catalyst::Plugin::Session::Store::Delegate>; if you need complete
control over how your sessions are stored, you probably want to use
that instead.

=head1 METHODS

=head2 setup_finished

Hook into the configured session class.

=cut

sub setup_finished {
    my $c = shift;

    return $c->next::method unless @_;

    # Try to determine id_field if it isn't set
    unless ($c->_session_plugin_config->{id_field}) {
        my $model = $c->session_store_model;
        my $rs = ref $model ? $model
            : $model->can('resultset_instance') ? $model->resultset_instance
            : $model;
        my @primary_columns = $rs->result_source->primary_columns;

        Catalyst::Exception->throw(
            message => __PACKAGE__ . qq/: Primary key consists of more than one column; please set id_field manually/
        ) if @primary_columns > 1;

        $c->_session_plugin_config->{id_field} = $primary_columns[0];
    }

    $c->next::method(@_);
}

=head2 session_store_dbic_class

Return the L<DBIx::Class> class name to be passed to C<< $c->model >>.
Defaults to C<DBIC::Session>.

=cut

sub session_store_dbic_class {
    shift->_session_plugin_config->{dbic_class} || 'DBIC::Session';
}

=head2 session_store_dbic_id_field

Return the configured ID field name.  Defaults to C<id>.

=cut

sub session_store_dbic_id_field {
    shift->_session_plugin_config->{id_field} || 'id';
}

=head2 session_store_dbic_data_field

Return the configured data field name.  Defaults to C<session_data>.

=cut

sub session_store_dbic_data_field {
    shift->_session_plugin_config->{data_field} || 'session_data';
}

=head2 session_store_dbic_expires_field

Return the configured expires field name.  Defaults to C<expires>.

=cut

sub session_store_dbic_expires_field {
    shift->_session_plugin_config->{expires_field} || 'expires';
}

=head2 session_store_model

Return the model used to find a session.

=cut

sub session_store_model {
    my ($c, $id) = @_;

    my $dbic_class = $c->session_store_dbic_class;
    $c->model($dbic_class, $id) or die "Couldn't find a model named $dbic_class";
}

=head2 get_session_store_delegate

Load the row corresponding to the specified session ID.  If none is
found, one is automatically created.

=cut

sub get_session_store_delegate {
    my ($c, $id) = @_;

    Catalyst::Plugin::Session::Store::DBIC::Delegate->new({
        model      => $c->session_store_model($id),
        id_field   => $c->session_store_dbic_id_field,
        data_field => $c->session_store_dbic_data_field,
    });
}

=head2 session_store_delegate_key_to_accessor

Match the specified key and operation to the session ID and field
name.

=cut

sub session_store_delegate_key_to_accessor {
    my $c = shift;
    my $key = $_[0];
    my ($field, @args) = $c->next::method(@_);

    my ($type) = ($key =~ /^(\w+):/);

    $field = $c->session_store_dbic_id_field      if $field eq 'id';
    $field = $c->session_store_dbic_expires_field if $field eq 'expires';
    $field = $c->session_store_dbic_data_field    if $field eq 'session' or $field eq 'flash';

    my $accessor = sub { shift->$type($key)->$field(@_) };

    if ($field eq $c->session_store_dbic_data_field) {
        @args = map { MIME::Base64::encode(Storable::nfreeze($_ || '')) } @args;
        $accessor = sub {
            my $value = shift->$type($key)->$field(@_);
            return unless $value;
            return Storable::thaw(MIME::Base64::decode($value));
        };
    }

    return ($accessor, @args);
}

=head2 delete_session_data

Delete the specified session from the backend store.

=cut

sub delete_session_data {
    my ($c, $key) = @_;

    # expires is stored on the session row for compatibility with Store::DBI
    return if $key =~ /^expires/;

    $c->session_store_model->search({
        $c->session_store_dbic_id_field => $key,
    })->delete;
}

=head2 delete_expired_sessions

Delete all expired sessions.

=cut

sub delete_expired_sessions {
    my $c = shift;

    $c->session_store_model->search({
        $c->session_store_dbic_expires_field => { '<', time() },
    })->delete;
}

=head1 CONFIGURATION

The following parameters should be placed in your application
configuration under the C<Plugin::Session> key.

=head2 dbic_class

(Required) The name of the L<DBIx::Class> that represents a session in
the database.  It is recommended that you provide only the part after
C<MyApp::Model>, e.g. C<DBIC::Session>.

If you are using L<Catalyst::Model::DBIC::Schema>, the following
layout is recommended:

=over 4

=item * C<MyApp::Schema> - your L<DBIx::Class::Schema> class

=item * C<MyApp::Schema::Session> - your session table class

=item * C<MyApp::Model::DBIC> - your L<Catalyst::Model::DBIC::Schema> class

=back

This module will then use C<< $c->model >> to access the appropriate
result source from the composed schema matching the C<dbic_class>
name.

For more information, please see L<Catalyst::Model::DBIC::Schema>.

=head2 expires

Number of seconds for which sessions are active.

Note that no automatic cleanup is done on your session data.  To
delete expired sessions, you can use the L</delete_expired_sessions>
method with L<Catalyst::Plugin::Scheduler>.

=head2 id_field

The name of the field on your sessions table which stores the session
ID.  Defaults to C<id>.

=head2 data_field

The name of the field on your sessions table which stores session
data.  Defaults to C<session_data> for compatibility with
L<Catalyst::Plugin::Session::Store::DBI>.

=head2 expires_field

The name of the field on your sessions table which stores the
expiration time of the session.  Defaults to C<expires>.

=head1 SCHEMA

Your sessions table should contain the following columns:

    id           CHAR(72) PRIMARY KEY
    session_data TEXT
    expires      INTEGER

The C<id> column should probably be 72 characters.  It needs to handle
the longest string that can be returned by
L<Catalyst::Plugin::Session/generate_session_id>, plus another eight
characters for internal use.  This is less than 72 characters when
SHA-1 or MD5 is used, but SHA-256 will need all 72 characters.

The C<session_data> column should be a long text field.  Session data
is encoded using L<MIME::Base64> before being stored in the database.

Note that MySQL C<TEXT> fields only store 64 kB, so if your session
data will exceed that size you'll want to use C<MEDIUMTEXT>,
C<MEDIUMBLOB>, or larger. If you configure your
L<DBIx::Class::ResultSource> to include the size of the column, you
will receive warnings for this problem:

    This session requires 1180 bytes of storage, but your database
    column 'session_data' can only store 200 bytes. Storing this
    session may not be reliable; increase the size of your data field

See L<DBIx::Class::ResultSource/add_columns> for more information.

The C<expires> column stores the future expiration time of the
session.  This may be null for per-user and flash sessions.

Note that you can change the column names using the L</id_field>,
L</data_field>, and L</expires_field> configuration parameters.
However, the column types must match the above.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>danieltwc@cpan.orgE<gt>

=head1 ACKNOWLEDGMENTS

=over 4

=item * Andy Grundman, for L<Catalyst::Plugin::Session::Store::DBI>

=item * David Kamholz, for most of the testing code (from
        L<Catalyst::Plugin::Authentication::Store::DBIC>)

=item * Yuval Kogman, for assistance in converting to
        L<Catalyst::Plugin::Session::Store::Delegate>

=item * Jay Hannah, for tests and warning when session size 
        exceeds DBIx::Class storage size.

=back

=head1 COPYRIGHT

Copyright (c) 2006 - 2009
the Catalyst::Plugin::Session::Store::DBIC L</AUTHOR>
as listed above.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
