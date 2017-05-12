package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst qw/
    +CatalystX::Debug::ResponseHeaders
/;

extends 'Catalyst';

__PACKAGE__->setup;

1;
