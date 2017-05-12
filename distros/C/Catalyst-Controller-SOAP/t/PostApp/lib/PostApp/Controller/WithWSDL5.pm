package PostApp::Controller::WithWSDL5;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} = 't/hello5.wsdl';

sub Greet : WSDLPort('GreetPort') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{parameters}{who};
    my $grt = $args->{parameters}{greeting};
    $c->response->body($grt);
}

1;
