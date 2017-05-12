package AuthDigestDotnetTestApp::Controller::Root;
use strict;
use warnings;

use base qw/ Catalyst::Controller /;

__PACKAGE__->config(namespace => '');

sub moose : Local {
    my ( $self, $c ) = @_;
    #$c->authenticate( { realm => 'testrealm@host.com' } );
    $c->authenticate();
    $c->res->body( $c->user->id );
}

1;

