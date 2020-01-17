package TestApp;

use base qw(Catalyst);

use MyContainer;

__PACKAGE__->config( container('config')->{web} );

__PACKAGE__->setup(
    "Authentication",
);
