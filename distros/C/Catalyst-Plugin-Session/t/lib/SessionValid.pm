package SessionValid;
use Catalyst qw/Session Session::Store::Dummy Session::State::Cookie/;

use strict;
use warnings;

__PACKAGE__->config('Plugin::Session' => {
    cookie_expires => 0,
    expires => 1,
});

__PACKAGE__->setup;

__PACKAGE__;

