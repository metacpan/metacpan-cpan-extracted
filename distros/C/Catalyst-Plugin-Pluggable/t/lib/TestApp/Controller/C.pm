package TestApp::Controller::C;

use base qw( Catalyst::Controller );

sub test : Local {
    my( $self, $c, $arg ) = @_;
    $arg   ||= '';
    my $body = $c->res->body || '';
    $c->res->body( ( $c->res->body || '' ) . "C$arg\n" );
}

1;