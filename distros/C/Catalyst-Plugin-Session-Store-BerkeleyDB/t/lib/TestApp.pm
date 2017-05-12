package TestApp;
use strict;
use warnings;

use Catalyst qw/Session Session::Store::BerkeleyDB Session::State::Cookie/;

__PACKAGE__->config( session => {
    expires => 50,
});

__PACKAGE__->setup;

1;
