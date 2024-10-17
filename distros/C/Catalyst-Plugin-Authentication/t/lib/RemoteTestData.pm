package RemoteTestData;
use strict;
use warnings;

use Moose::Role;

if ($Catalyst::VERSION < 5.89000) {
    require RemoteTestEngine;
    around engine_class => sub { 'RemoteTestEngine' };
}

around psgi_app => sub {
    my ($orig, $self, @arg) = @_;
    my $app = $self->$orig(@arg);
    sub {
        my ($e) = @_;
        $e->{REMOTE_USER} = $RemoteTestEngine::REMOTE_USER;
        $e->{SSL_CLIENT_S_DN} = $RemoteTestEngine::SSL_CLIENT_S_DN;
        $app->($e);
    };
};

1;
