package Connector::Role::SessionCache;

use strict;
use warnings;
use English;

use Moose::Role;

our %sessioncache;

requires 'authid';
requires 'terminate_session';
requires 'validate_session';

has session => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    lazy => 1,
    builder => '_init_session',
    clearer => 'clear_session',
    predicate => 'has_session',
);

sub DEMOLISH {};

before 'DEMOLISH' => sub {

    my $self = shift;
    # do not cleanup when program is already dying
    # as the linked objects might no longer be there we will get
    # unpredicatable behaviour and ugly errors in the logs
    if (${^GLOBAL_PHASE} ne 'DESTRUCT') {
        $self->detach_session();
    }
};

=head2 attach_session

Reads authid from the class and checks if the session cache has a
suitable item. If found, the session is validated, the reference
counter is increased and the session id is returned. If a session
fails validation, it is removed from the cache. If no valid session
is found, returns undef.

=cut

sub attach_session {

    my $self = shift;
    my $authid = $self->authid();
    return unless ($sessioncache{$authid});

    my ($instcnt, $session) = @{$sessioncache{$authid}};
    if ($session && !$self->validate_session($session)) {
        delete $sessioncache{$authid};
        $self->clear_session();
        $self->log()->debug('Cached session already gone - discard');
    } else {
        $self->log()->debug('Allocate session id from cache for ' . $authid );
        $sessioncache{$authid}->[0]++;
        return $session;
    }
    return;
}

=head2 register_session

Expects the session information to store in the session cache as
argument and puts it into the sessioncache object using the class I<authid>
from the class as index.

Existing items in the cache will be overwritten, passing I<undef>
removes the cache item.

Returns the session information.

=cut

sub register_session {

    my $self = shift;
    my $session = shift;
    my $authid = $self->authid();
    if ($session) {
        $sessioncache{$authid} = [ 1, $session ];
    } else {
        $sessioncache{$authid} = undef;
    }
    return $session;

}

=head2 detach_session

Detach this instance from the session cache and terminate the session
in case this is the last reference to it. The session can be passed as
argument, in case no argument or undef is passed, the session is read
from the class I<session> method.

=cut

sub detach_session {

    my $self = shift;
    my $session = shift;

    return unless ($session || $self->has_session());
    $session ||= $self->session();

    $self->log()->debug('Detach session ' . $session);
    my $authid = $self->authid();
    return unless ($sessioncache{$authid});

    # using cmp allows us to overload the comparission when using objects
    # NB: cmp = 0 if strings are equal
    return if ($sessioncache{$authid}->[1] cmp $session);

    if ($sessioncache{$authid}->[0] > 1) {
        $sessioncache{$authid}->[0]--;
        $self->log()->debug(sprintf('Session has %01d other references', $sessioncache{$authid}->[0]));
        return;
    }

    $self->log()->trace('Last reference to session - terminating');
    delete $sessioncache{$authid};
    $self->terminate_session( $session );
    return 1;

}

1;

__END__;
