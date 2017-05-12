use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;
use Test::Fatal;

use App::Nopaste::Service;

like(
    exception { App::Nopaste::Service->uri() },
    qr/App::Nopaste::Service must provide a 'uri' method/,
    'appropriate error when no URI is provided',
);

done_testing;
