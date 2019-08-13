package TestApp;

use Moose;
use Catalyst;

extends 'Catalyst';

use namespace::autoclean;

__PACKAGE__->config(
    request_class_traits => [
        'Methods'
    ]
);

__PACKAGE__->setup();

1;
