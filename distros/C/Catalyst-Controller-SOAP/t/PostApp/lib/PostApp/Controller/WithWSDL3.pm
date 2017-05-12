package PostApp::Controller::WithWSDL3;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} = 't/hello3.wsdl';

sub Greet : WSDLPort('Greet') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{parameters}{who};
    my $grt = $args->{parameters}{greeting};
    $c->stash->{soap}->compile_return({ details => { greeting => $grt.' '.$who.'!' }});
}

sub Shout : WSDLPort('Shout') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{parameters}{who};
    my $grt = $args->{parameters}{greeting};
    $c->stash->{soap}->compile_return({ details => {greeting => uc($grt).' '.uc($who).'!!' }});
}

1;
