package DBGp::Client::Response::PropertyValue;

use strict;
use warnings;
# the DBGp spec is not entirely clear about this, but it's compatible
# with both what the spec says and what Xdebug does
use parent qw(DBGp::Client::Response::Property);

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command
));

1;
