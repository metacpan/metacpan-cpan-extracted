package Basic::Test;

use strict;
use warnings FATAL => 'all';

sub _default {
    &_success;
}

sub _success {
    my ( $self, $c ) = @_;

    $c->request->content_type('text/html');

    print "success";
    exit;
}

1;
