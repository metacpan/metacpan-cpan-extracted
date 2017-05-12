package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst;
extends 'Catalyst';

__PACKAGE__->config(
    default_view => 'HTML',
    'View::HTML::Foo' => {
        test_arg => 111,
    },
);

__PACKAGE__->setup;

1;
