package TestApp::Controller::B;

use base qw( Catalyst::Controller );

sub test : Local {
    my( $self, $c, $arg ) = @_;
    $arg   ||= '';
    my $body = $c->res->body || '';
    $c->res->body( ( $c->res->body || '' ) . "B$arg\n" );
}

1;