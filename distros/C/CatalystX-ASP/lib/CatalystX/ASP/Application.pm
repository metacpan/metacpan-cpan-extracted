package CatalystX::ASP::Application;

use namespace::autoclean;
use Moose;

has 'asp' => (
    is       => 'ro',
    isa      => 'CatalystX::ASP',
    required => 1,
    weak_ref => 1,
);

=head1 NAME

CatalystX::ASP::Application - $Application Object

=head1 SYNOPSIS

  use CatalystX::ASP::Application;

  my $application = CatalystX::ASP::Application->new(asp => $asp);
  $application->{foo} = $bar;

=head1 DESCRIPTION

Like the C<$Session> object, you may use the C<$Application> object to store
data across the entire life of the application. Every page in the ASP
application always has access to this object. So if you wanted to keep track of
how many visitors there where to the application during its lifetime, you might
have a line like this:

  $Application->{num_users}++

The Lock and Unlock methods are used to prevent simultaneous access to the
C<$Application> object.

=head1 METHODS

=over

=item $Application->Lock()

Not implemented. This is a no-op. This is unnecessary given the implementation

=cut

# TODO: will not implement
sub Lock {
    my ( $self ) = @_;
    $self->asp->c->log->warn( "\$Application->Lock has not been implemented!" );
    return;
}

=item $Application->UnLock()

Not implemented. This is a no-op. This is unnecessary given the implementation

=cut

# TODO: will not implement
sub UnLock {
    my ( $self ) = @_;
    $self->asp->c->log->warn( "\$Application->UnLock has not been implemented!" );
    return;
}

=item $Application->GetSession($sess_id)

This NON-PORTABLE API extension returns a user C<$Session> given a session id.
This allows one to easily write a session manager if session ids are stored in
C<$Application> during C<Session_OnStart>, with full access to these sessions
for administrative purposes.

Be careful not to expose full session ids over the net, as they could be used
by a hacker to impersonate another user. So when creating a session manager, for
example, you could create some other id to reference the SessionID internally,
which would allow you to control the sessions. This kind of application would
best be served under a secure web server.

=cut

sub GetSession {
    my ( $self, $sess_id ) = @_;
    my $c             = $self->asp->c;
    my $session_class = ref $self->asp->Session;
    if ( $c->can( 'get_session_data' ) ) {
        my $session = $c->get_session_data( $sess_id );
        return bless $session, $session_class
    } elsif ( $c->can( 'session_cache' ) ) {
        my $session = $c->session_cache->get( $sess_id, existing_session_only => 1 );
        return bless $session, $session_class
    } else {
        return $self->asp->Session;
    }
}

=item $Application->SessionCount()

This NON-PORTABLE method returns the current number of active sessions in the
application, and is enabled by the C<SessionCount> configuration setting. This
method is not implemented as part of the original ASP object model, but is
implemented here because it is useful. In particular, when accessing databases
with license requirements, one can monitor usage effectively through accessing
this value.

=cut

# TODO: will not implement
sub SessionCount {
    my ( $self ) = @_;
    $self->asp->c->log->warn( "\$Application->SessionCount has not been implemented!" );
    return;
}

sub DEMOLISH {
    my ( $self ) = @_;

    # It's okay if it fails...
    eval { $self->asp->GlobalASA->Application_OnEnd };
}

__PACKAGE__->meta->make_immutable;

=back

=head1 SEE ALSO

=over

=item * L<CatalystX::ASP::Session>

=item * L<CatalystX::ASP::Request>

=item * L<CatalystX::ASP::Response>

=item * L<CatalystX::ASP::Server>

=back
