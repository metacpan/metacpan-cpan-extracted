package Basic::Test;

use strict;
use warnings FATAL => 'all';

sub _default {
    my ($self, $c) = @_;

    $self->_success($c);
}

sub _success {
    my ($self, $c) = @_;

    $c->request->content_type('text/html');

    print "success";
    exit;
}

1;
