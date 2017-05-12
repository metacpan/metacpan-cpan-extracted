package DBGp::Client::Response::PropertySet;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command success
));

1;
