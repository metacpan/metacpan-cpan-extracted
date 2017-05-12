
use strict;
use warnings;

use Plack;
use Plack::Builder;

builder {
    mount '/hello' => sub {
        return [ 200, [], [ 'WORLD' ]]
    }
};
