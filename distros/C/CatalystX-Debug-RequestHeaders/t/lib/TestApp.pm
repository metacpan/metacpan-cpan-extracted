package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst qw/
    +CatalystX::Debug::RequestHeaders
/;

extends 'Catalyst';

__PACKAGE__->setup;

1;
