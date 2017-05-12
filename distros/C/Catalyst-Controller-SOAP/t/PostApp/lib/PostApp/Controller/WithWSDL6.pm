package PostApp::Controller::WithWSDL6;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} = 't/hello6.wsdl';
__PACKAGE__->config->{soap_action_prefix} = 'http://example.com/';

sub Greet : WSDLPortWrapped('Greet') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{who};
    my $grt = $args->{greeting};
    $c->stash->{soap}->compile_return({ greeting => 'Greet '.$grt.' '.$who.'!' });
}

sub Shout : WSDLPortWrapped('Greet') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{who};
    my $grt = $args->{greeting};
    $c->stash->{soap}->compile_return({ greeting => 'Shout '.$grt.' '.$who.'!' });
}

sub Blag : WSDLPortWrapped('Greet') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{who};
    my $grt = $args->{greeting};
    $c->res->body('Blag '.$grt.' '.$who.'!');
}

1;
