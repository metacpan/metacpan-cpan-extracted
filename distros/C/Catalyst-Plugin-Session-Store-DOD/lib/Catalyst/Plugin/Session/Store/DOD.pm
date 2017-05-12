package Catalyst::Plugin::Session::Store::DOD;
use strict;
use warnings;

use base qw/Class::Data::Inheritable Catalyst::Plugin::Session::Store/;
use MIME::Base64;
use NEXT;
use Storable qw/nfreeze thaw/;

our $VERSION = '0.01';

__PACKAGE__->mk_classdata('_sth_get_session_data');
__PACKAGE__->mk_classdata('_sth_get_expires');
__PACKAGE__->mk_classdata('_sth_check_existing');
__PACKAGE__->mk_classdata('_sth_update_session');
__PACKAGE__->mk_classdata('_sth_insert_session');
__PACKAGE__->mk_classdata('_sth_update_expires');
__PACKAGE__->mk_classdata('_sth_delete_session');
__PACKAGE__->mk_classdata('_sth_delete_expired_sessions');

sub get_session_data {
    my ( $c, $key ) = @_;
    
    # expires:sid expects an expiration time
    if ( my ($sid) = $key =~ /^expires:(.*)/ ) {
        $key = "session:$sid";
        my $session = $c->config->{session}->{model}->lookup($key);
        return $session->expires
            if $session;
    }
    else {
        my $session = $c->config->{session}->{model}->lookup($key);
        return thaw( decode_base64($session->session_data) )
            if $session;
    }
    return;
}

sub store_session_data {
    my ( $c, $key, $data ) = @_;
    
    # expires:sid keys only update the expiration time
    if ( my ($sid) = $key =~ /^expires:(.*)/ ) {
        $key = "session:$sid";

        # Update or create new
        my $session = $c->config->{session}->{model}->new(
            id           => $key,
            expires      => $c->session_expires,
        );
        $session->exists() ? $session->update() : $session->insert;

    } else {
        # Prepare the data
        my $frozen = encode_base64( nfreeze($data) );
        my $expires = $key =~ /^(?:session|flash):/ 
                    ? $c->session_expires 
                    : undef;

        # Update or create new
        my $session = $c->config->{session}->{model}->new(
            id           => $key,
            session_data => $frozen,
            expires      => $expires,
        );
        $session->exists() ? $session->update() : $session->insert;
    }
    
    return;
}

sub delete_session_data {
    my ( $c, $key ) = @_;
    
    return if $key =~ /^expires/;

    my $session = $c->config->{session}->{model}->lookup($key);
    $session->remove
        if $session;

    return;
}

sub delete_expired_sessions {
    my $c = shift;

    my @sessions = $c->config->{session}->{model}->search({
        expires => {
            op    => "IS NOT NULL AND expires <",
            value => time(),
        }
    });
    # This sucks, it will pound the DB
    foreach (@sessions) {
        $_->remove;
    }

    return;
}

sub setup_session {
    my $c = shift;

    $c->NEXT::setup_session(@_);
    
    unless ( $c->config->{session}->{model}->has_column('id') &&
             $c->config->{session}->{model}->has_column('session_data') &&
             $c->config->{session}->{model}->has_column('expires')
    ) {
        Catalyst::Exception->throw( 
            message => 'The DOD object does not have the required columns '
                     . 'to store session data.'
        );
    }
}

1;
__END__

=head1 NAME

Catalyst::Plugin::Session::Store::DOD - Store your sessions in a database
using Data::ObjectDriver.

=head1 SYNOPSIS

    # Create a table in your database for sessions
    CREATE TABLE sessions (
        id           char(72) primary key,
        session_data text,
        expires      int(10)
    );
    
    # Create a Data::ObjectDriver model
    package BaseObject::M::Session;
    use base qw( Data::ObjectDriver::BaseObject );

    use Data::ObjectDriver::Driver::DBI;

    __PACKAGE__->install_properties({
        columns     => [ 'id', 'session_data', 'expires' ],
        primary_key => [ 'id' ],
        datasource  => 'sessions',
        get_driver  => sub {
            Data::ObjectDriver::Driver::DBI->new(
                dsn => "dbi:SQLite:session.db",
            ),
        },
    });

    # In your app
    use Catalyst qw/Session Session::Store::DOD Session::State::Cookie/;
    
    # Connect directly to the database
    MyApp->config->{session} = {
        expires => 3600,
        model   => "BaseObject::M::Session",
    };

    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

This storage module will store session data in a database using a
Data::ObjectDriver model.  It is based on version 0.13 of
Catalyst::Plugin::Session::Store::DBI by Andy Grundman
<andy@hybridized.org> and is basically a port of his module to use
D::OD instead of directly interacting via DBI.

=head1 CONFIGURATION

These parameters are placed in the configuration hash under the C<session>
key.

=head2 expires

The expires column in your table will be set with the expiration value.
Note that no automatic cleanup is done on your session data, but you can use
the delete_expired_sessions method to perform clean up.  You can make use of
the L<Catalyst::Plugin::Scheduler> plugin to schedule automated session
cleanup.

=head2 model

L<Data::ObjectDriver::BaseObject::Model> object which is configuered to
interact with your storage engine for session information. 

=head1 SCHEMA

Your 'sessions' model must contain at minimum the following 3 attributes:

    id           char(72) primary key
    session_data text
    expires      int(10)

The 'id' column should probably be 72 characters. It needs to handle the
longest string that can be returned by
L<Catalyst::Plugin::Authentication/generate_session_id>, plus another 8
characters for internal use. This is less than 72 characters in practice when
SHA-1 or MD5 are used, but SHA-256 will need all those characters.

The 'session_data' column should be a long text field.  Session data is
encoded using Base64 before being stored in the database.

The 'expires' column stores the future expiration time of the session.  This
may be null for per-user and flash sessions.

=head1 METHODS

=head2 get_session_data

=head2 store_session_data

=head2 delete_session_data

=head2 delete_expired_sessions

=head2 setup_session

These are implementations of the required methods for a store. See
L<Catalyst::Plugin::Session::Store>.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>, L<Catalyst::Plugin::Scheduler>

=head1 AUTHOR

David Recordon, <david@sixapart.com>

Based on Catalyst::Plugin::Session::Store::DBI by Andy Grundman
<andy@hybridized.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
