package DBGp::Client::Response::Interact;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command status more prompt
));

1;
