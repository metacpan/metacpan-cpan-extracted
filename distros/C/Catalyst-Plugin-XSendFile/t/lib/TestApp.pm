package TestApp;
use strict;
use warnings;

use Catalyst qw/XSendFile/;

__PACKAGE__->config(
    name => 'TestApp',
);

sub sendfile : Global {
    my ( $self, $c, $filename ) = @_;

    $c->res->sendfile($filename);
}

sub sendfile_emuration : Global {
    my ( $self, $c, $filename ) = @_;
    $c->res->sendfile( $c->path_to( 'root', $filename )->stringify );
}

1;
