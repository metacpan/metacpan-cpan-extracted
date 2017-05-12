package DBGp::Client::Response::BreakpointGetUpdateRemove;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

use DBGp::Client::Response::Breakpoint;

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command
));

sub breakpoint {
    return bless DBGp::Client::Parser::_node($_[0], 'breakpoint'),
                 'DBGp::Client::Response::Breakpoint';
}

1;
