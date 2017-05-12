package TestApp;
use strict;
use warnings;

use Catalyst qw/Firebug/;

__PACKAGE__->config(
    name => 'TestApp',
);

sub index :Path('/') {
    my ($self, $c) = @_;

    $c->response->body( $c->welcome_message );
}

1;
