package PostApp::Controller::WithWSDL2;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP::RPC';

__PACKAGE__->config->{wsdl} = 't/hello2.wsdl';
__PACKAGE__->config->{xml_compile} = {
    # reader => {sloppy_integers => 1},
    # writer => {sloppy_integers => 1},
};

sub Greet : SOAP('RPCLiteral') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{who};
    my $grt = $args->{greeting};
    my $num = $args->{count};
    $c->stash->{soap}->compile_return({ greeting => $num.' '.$grt.' '.$who.'!'.(ref $num||'') });
}

1;
