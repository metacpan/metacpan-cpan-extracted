package DNS::Unbound::AsyncQuery::PromiseES6;

use strict;
use warnings;

use parent (
    'DNS::Unbound::AsyncQuery',
    'Promise::ES6',
);

use constant _DEFERRED_CR => undef;

*_dns_unbound_then = \&Promise::ES6::then;

*_dns_unbound_finally = \&Promise::ES6::finally;

1;
