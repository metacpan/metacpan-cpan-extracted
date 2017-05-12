package Basic::Test;

use strict;
use warnings FATAL => 'all';

sub open {
    my ( $self, $c ) = @_;

    $c->plugin('File')->open( $c, $ENV{'DOCUMENT_ROOT'} . '/test.gif' );
}

sub download {
    my ( $self, $c ) = @_;

    $c->plugin('File')->download( $c, $ENV{'DOCUMENT_ROOT'} . '/test.gif' );
}

1;
