package TestApp;

use strict;
use Catalyst qw/DefaultEnd/;

our $VERSION = '0.01';

TestApp->config( name => 'TestApp', root => '/some/dir' );

TestApp->setup;

sub test_view : Global {
    my( $self, $c ) = @_;
    $c->config->{ view } = 'TestApp::View::TestView';
    return 1;
}

sub test_firstview : Global {
    my( $self, $c ) = @_;
    delete $c->config->{ view };
    return 1;
}

sub test_skipview : Global {
    my( $self, $c ) = @_;
    $c->res->body( 'Skipped View' );
}

1;