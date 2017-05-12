package TestAppAction;
use strict;
use warnings;

use Catalyst;

__PACKAGE__->config(
    name => 'TestApp',
);

sub index : Path('/') {
    my ($self, $c) = @_;

    $c->response->body( $c->welcome_message );
}

sub end : ActionClass('Firebug') {}

1;
