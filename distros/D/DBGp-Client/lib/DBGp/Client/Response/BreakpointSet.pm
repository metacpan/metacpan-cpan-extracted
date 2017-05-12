package DBGp::Client::Response::BreakpointSet;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command state id
));

1;
