package DNS::Unbound::AsyncQuery::PromiseES6;

use strict;
use warnings;

use parent (
    'DNS::Unbound::AsyncQuery',
    'Promise::ES6',
);

use constant _DEFERRED_CR => undef;

*_then = \&Promise::ES6::then;

*_finally = \&Promise::ES6::finally;

1;
