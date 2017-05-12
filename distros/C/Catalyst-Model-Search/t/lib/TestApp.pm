package TestApp;

use strict;
use Catalyst;

our $VERSION = '0.01';

TestApp->config(
    name => 'TestApp',
);

TestApp->setup();

sub default : Private {
    my ( $self, $c ) = @_;

}

1;
