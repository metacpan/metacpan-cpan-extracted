package Basic::Test;

use strict;
use warnings FATAL => 'all';

sub init {
    my ( $self, $c ) = @_;

    my $object = $c->plugin('JSON');

    $self->_success($c) if (ref($object));
}

sub _success {
    my ( $self, $c ) = @_;

    $c->request->content_type('text/html');

    print "success";
    exit;
}

1;
