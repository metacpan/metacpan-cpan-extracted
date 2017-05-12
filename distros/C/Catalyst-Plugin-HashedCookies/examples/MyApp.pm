package # hide from PAUSE
    MyApp;

use strict;
use warnings FATAL => 'all';

use Catalyst qw/HashedCookies/;

MyApp->config->{hashedcookies} = {
    key       => $secret_key,
    algorithm => 'SHA1', # optional
    required  => 1,      # optional
};

MyApp->setup;

1;
