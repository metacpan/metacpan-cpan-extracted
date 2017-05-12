package TestApp;

use Moose;
use namespace::autoclean;

use Catalyst;

extends 'Catalyst';

with 'CatalystX::AuthenCookie';

__PACKAGE__->config( authen_cookie => { mac_secret => 'the knife' } );

__PACKAGE__->setup();

__PACKAGE__->meta()->make_immutable();

1;
