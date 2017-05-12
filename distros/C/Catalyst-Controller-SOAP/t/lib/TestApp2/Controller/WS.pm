package TestApp2::Controller::WS;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} = 't/hello.wsdl';

sub Greet :WSDLPort('GreetPort') {
    my ($self, $c, $args) = @_;
    my $who = $args->{parameters}{who};
    my $grt = $args->{parameters}{greeting};
    my $num = $args->{parameters}{count};
    $c->stash->{soap}->compile_return({ details => { greeting => $num.' '.$grt.' '.$who.'!'.(ref $num||'') }});
}

1;
