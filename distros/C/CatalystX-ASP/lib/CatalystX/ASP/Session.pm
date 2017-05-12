package CatalystX::ASP::Session;

use namespace::autoclean;
use Moose;
use parent 'Tie::Hash';

has 'asp' => (
    is       => 'ro',
    isa      => 'CatalystX::ASP',
    required => 1,
    weak_ref => 1,
);

=head1 NAME

CatalystX::ASP::Session - $Session Object

=head1 SYNOPSIS

  use CatalystX::ASP::Session;

  my $session = CatalystX::ASP::Session->new(asp => $asp);
  tie %Session, 'CatalystX::ASP::Session', $session;
  $Session{foo} = $bar;

=head1 DESCRIPTION

The C<$Session> object keeps track of user and web client state, in a persistent
manner, making it relatively easy to develop web applications. The C<$Session>
state is stored across HTTP connections, in database files in the C<Global> or
C<StateDir> directories, and will persist across web server restarts.

The user session is referenced by a 128 bit / 32 byte MD5 hex hashed cookie, and
can be considered secure from session id guessing, or session hijacking. When a
hacker fails to guess a session, the system times out for a second, and with
2**128 (3.4e38) keys to guess, a hacker will not be guessing an id any time
soon.

If an incoming cookie matches a timed out or non-existent session, a new session
is created with the incoming id. If the id matches a currently active session,
the session is tied to it and returned. This is also similar to the Microsoft
ASP implementation.

The C<$Session> reference is a hash ref, and can be used as such to store data
as in:

    $Session->{count}++;     # increment count by one
    %{$Session} = ();   # clear $Session data

The C<$Session> object state is implemented through L<MLDBM>, and a user should
be aware of the limitations of MLDBM. Basically, you can read complex
structures, but not write them, directly:

  $data = $Session->{complex}{data};     # Read ok.
  $Session->{complex}{data} = $data;     # Write NOT ok.
  $Session->{complex} = {data => $data}; # Write ok, all at once.

Please see L<MLDBM> for more information on this topic. C<$Session> can also be
used for the following methods and properties:

=cut

has '_is_new' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    traits  => [qw(Bool)],
    handles => {
        '_set_is_new'   => 'set',
        '_unset_is_new' => 'unset'
    },
);

has '_session_key_index' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    traits  => [qw(Counter)],
    handles => {
        _inc_session_key_index   => 'inc',
        _reset_session_key_index => 'reset',
    },
);

has '_session_keys' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => [qw(Array)],
    handles => {
        _session_keys_get => 'get',
    },
);

=head1 ATTRIBUTES

=over

=item $Session->{CodePage}

Not implemented.  May never be until someone needs it.

=cut

has 'CodePage' => (
    is  => 'ro',
    isa => 'Item',
);

=item $Session->{LCID}

Not implemented.  May never be until someone needs it.

=cut

has 'LCID' => (
    is  => 'ro',
    isa => 'item',
);

=item $Session->{SessionID}

SessionID property, returns the id for the current session, which is exchanged
between the client and the server as a cookie.

=cut

has 'SessionID' => (
    is  => 'rw',
    isa => 'Str',
);

=item $Session->{Timeout} [= $minutes]

Timeout property, if minutes is being assigned, sets this default timeout for
the user session, else returns the current session timeout.

If a user session is inactive for the full timeout, the session is destroyed by
the system. No one can access the session after it times out, and the system
garbage collects it eventually.

=cut

has 'Timeout' => (
    is      => 'rw',
    isa     => 'Int',
    default => 60,
);

=back

=head1 METHODS

=over

=item $Session->Abandon()

The abandon method times out the session immediately. All Session data is
cleared in the process, just as when any session times out.

=cut

has 'IsAbandoned' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    traits  => [qw(Bool)],
    handles => {
        Abandon => 'set',
    },
);

=item $Session->Lock()

Not implemented. This is a no-op. This was meant to be for performance
improvement, but it's not necessary.

=cut

# TODO: will not implement
sub Lock {
    my ( $self ) = @_;
    $self->asp->c->log->warn( "\$Session->Lock has not been implemented!" );
    return;
}

=item $Session->UnLock()

Not implemented. This is a no-op. This was meant to be for performance
improvement, but it's not necessary.

=cut

# TODO: will not implement
sub UnLock {
    my ( $self ) = @_;
    $self->asp->c->log->warn( "\$Session->UnLock has not been implemented!" );
    return;
}

=item $Session->Flush()

Not implemented.

=cut

# TODO: will not implement; not part of API so just no-op
sub Flush { }

# The Session is tied to Catalyst's $c->session so as to skip the storage of the
# $asp object
sub TIEHASH {
    my ( $class, $self ) = @_;
    my $c = $self->asp->c;

    # By default, assume using Catalyst::Plugin::Session otherwise assume using
    # Catalyst::Plugin::iParadigms::Session
    my $session_is_valid = $c->can( 'session_is_valid' ) ? 'session_is_valid' : 'is_valid_session_id';
    unless ( $c->$session_is_valid( $c->sessionid ) ) {
        $self->_set_is_new;
        $self->SessionID( $c->sessionid );
    }
    return $self;
}

sub STORE {
    my ( $self, $key, $value ) = @_;
    return $value if $key =~ /asp|_is_new|_session_key/;
    $self->asp->c->session->{$key} = $value;
}

sub FETCH {
    my ( $self, $key ) = @_;
    for ( $key ) {
        if    ( /asp/ )          { return $self->asp }
        elsif ( /_is_new/ )      { return $self->_is_new }
        elsif ( /_session_key/ ) {return}
        else                     { return $self->asp->c->session->{$key} }
    }
}

sub FIRSTKEY {
    my ( $self ) = @_;
    $self->_session_keys( [ keys %{ $self->asp->c->session } ] );
    $self->_reset_session_key_index;
    $self->NEXTKEY;
}

sub NEXTKEY {
    my ( $self, $lastkey ) = @_;
    my $key = $self->_session_keys_get( $self->_session_key_index );
    $self->_inc_session_key_index;
    if ( defined $key && $key =~ m/asp|_is_new|_session_key/ ) {
        return $self->NEXTKEY;
    } else {
        return $key;
    }
}

sub EXISTS {
    my ( $self, $key ) = @_;
    exists $self->asp->c->session->{$key};
}

sub DELETE {
    my ( $self, $key ) = @_;
    delete $self->asp->c->session->{$key};
}

sub CLEAR {
    my ( $self ) = @_;
    $self->DELETE( $_ ) for ( keys %{ $self->asp->c->session } );
}

sub SCALAR {
    my ( $self ) = @_;
    scalar %{ $self->asp->c->session };
}

__PACKAGE__->meta->make_immutable;

=back

=head1 SEE ALSO

=over

=item * L<CatalystX::ASP::Request>

=item * L<CatalystX::ASP::Response>

=item * L<CatalystX::ASP::Application>

=item * L<CatalystX::ASP::Server>

=back
