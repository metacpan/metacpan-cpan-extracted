package RemoteTestEngineRole;
use Moose::Role;
require Catalyst;

around env => sub {
    my ($orig, $self, @args) = @_;
    my $e = $self->$orig(@args);

    $e->{REMOTE_USER} = $RemoteTestEngine::REMOTE_USER;
    $e->{SSL_CLIENT_S_DN} = $RemoteTestEngine::SSL_CLIENT_S_DN;
    return $e;
};

1;

