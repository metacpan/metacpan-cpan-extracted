package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst qw/
    +Acme::CatalystX::ILoveDebug
    -Log=fatal
/;

extends 'Catalyst';

__PACKAGE__->setup;

1;
