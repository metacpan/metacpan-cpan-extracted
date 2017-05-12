package PostApp::Controller::WithWSDL4;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} = 't/hello4.wsdl';

sub Greet : WSDLPort('Greet') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{who};
    my $grt = $args->{greeting};
    $c->stash->{soap}->compile_return({ greeting => $grt.' '.$who.'!' });
}

sub Shout : WSDLPort('Greet') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{who};
    my $grt = $args->{greeting};
    $c->stash->{soap}->compile_return({ greeting => uc($grt).' '.uc($who).'!' });
}

sub Blag : WSDLPort('Greet') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{who};
    my $grt = $args->{greeting};
    $c->res->body($grt);
}

1;
