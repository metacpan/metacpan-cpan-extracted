package PostApp::Controller::WithWSDL;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} = 't/hello.wsdl';
__PACKAGE__->config->{soap_action_prefix} = 'http://example.com/actions/';
__PACKAGE__->config->{xml_compile} = {
    reader => {sloppy_integers => 1},
    writer => {sloppy_integers => 1},
};

sub Greet : Local SOAP('DocumentLiteral') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{parameters}{who};
    my $grt = $args->{parameters}{greeting};
    my $num = $args->{parameters}{count};
    $c->stash->{soap}->compile_return({ details => { greeting => $num.' '.$grt.' '.$who.'!'.(ref $num||'') }});
}

sub doclw : Local ActionClass('SOAP::DocumentLiteralWrapped') { }

1;
