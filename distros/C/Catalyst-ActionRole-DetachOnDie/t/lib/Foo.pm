package Foo;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'Foo',
    disable_component_resolution_regex_fallback => 1,
);

__PACKAGE__->setup();

1;
