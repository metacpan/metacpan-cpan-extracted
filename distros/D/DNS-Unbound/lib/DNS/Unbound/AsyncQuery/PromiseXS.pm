package DNS::Unbound::AsyncQuery::PromiseXS;

use strict;
use warnings;

use Promise::XS ();

use parent (
    'DNS::Unbound::AsyncQuery',
    'Promise::XS::Promise',
);

use constant _DEFERRED_CR => \&Promise::XS::deferred;

*_then = \&Promise::XS::Promise::then;

1;
