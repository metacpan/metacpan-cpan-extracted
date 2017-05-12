package Basic::Test;

use strict;
use warnings FATAL => 'all';

sub _default {
    my ( $self, $c ) = @_;

    $self->_success($c);
}

sub params {
    my ( $self, $c ) = @_;

    my %param = $c->plugin('CGI')->params($c);

    $self->_success($c) if ($param{hello} eq 'world' && $param{goodbye} eq 'world');
}

sub redirect {
    my ( $self, $c ) = @_;

    $c->plugin('CGI')->redirect( $c, '/app/test' );
}

sub _success {
    my ( $self, $c ) = @_;

    $c->request->content_type('text/html');

    print "success";
    exit;
}

1;
