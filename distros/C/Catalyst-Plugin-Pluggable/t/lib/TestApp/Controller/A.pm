package TestApp::Controller::A;

use base qw( Catalyst::Controller );

sub test : Local {
    my( $self, $c, $arg ) = @_;
    $arg   ||= '';
    my $body = $c->res->body || '';
    $c->res->body( ( $c->res->body || '' ) . "A$arg\n" );
}

1;