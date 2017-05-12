package PluginTestApp;
use Test::More;

use Catalyst qw(
    HashedCookies
);

__PACKAGE__->config( hashedcookies => { key => 'abcdef0123456789ASDF' } );
__PACKAGE__->setup;

1;
