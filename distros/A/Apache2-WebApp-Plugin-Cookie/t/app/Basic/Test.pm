package Basic::Test;

use strict;
use warnings FATAL => 'all';

sub set {
    my ( $self, $c ) = @_;

    $c->plugin('Cookie')->set( $c, {
        name    => 'foo',
        value   => 'bar',
        expires => '1h',
        secure  => 0,
      });

    $self->_success($c);

    $c->plugin('CGI')->redirect( $c, '/app/test/get' );
}

sub get {
    my ( $self, $c ) = @_;

    my $result = $c->plugin('Cookie')->get('foo');

    if ($result) {
        $self->_success($c) if ($result eq 'bar'); 
    }
    else {
        $self->_success($c) if ( $c->request->param('deleted') );
    }
}

sub delete {
    my ( $self, $c ) = @_;

    $c->plugin('Cookie')->delete( $c, 'foo' );

    $c->plugin('CGI')->redirect( $c, '/app/test/get/?deleted=1' );
}

sub _success {
    my ( $self, $c ) = @_;

    $c->request->content_type('text/html');

    print "success";
    exit;
}

1;
