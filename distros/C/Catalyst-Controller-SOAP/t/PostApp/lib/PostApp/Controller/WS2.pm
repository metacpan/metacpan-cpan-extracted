package PostApp::Controller::WS2;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP::RPC';

sub hello : Local SOAP('RPCLiteral') {
    my ( $self, $c, $body ) = @_;
    my $who = $body->string_value();
    $c->stash->{soap}->string_return('Hello '.$who.'!');
}

1;
