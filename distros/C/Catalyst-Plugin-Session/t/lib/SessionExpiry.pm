package SessionExpiry;
use Catalyst
    qw/Session Session::Store::Dummy Session::State::Cookie Authentication/;

use strict;
use warnings;

__PACKAGE__->config(
    'Plugin::Session' => {

        expires          => 20,
        expiry_threshold => 10,

    },

);

__PACKAGE__->setup;

__PACKAGE__;

