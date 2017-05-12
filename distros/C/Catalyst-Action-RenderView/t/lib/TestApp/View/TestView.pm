package TestApp::View::TestView;

use base qw( Catalyst::View );

sub process {
    my( $self, $c ) = @_;
    $c->res->body( 'View' );
}

1;