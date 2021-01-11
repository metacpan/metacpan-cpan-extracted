package DNS::Unbound::AsyncQuery::MojoPromise;

use strict;
use warnings;

use parent (
    'DNS::Unbound::AsyncQuery',
    'Mojo::Promise',
);

use constant _DEFERRED_CR => undef;

*_dns_unbound_then = \&Mojo::Promise::then;

*_dns_unbound_finally = \&Mojo::Promise::finally;

1;
