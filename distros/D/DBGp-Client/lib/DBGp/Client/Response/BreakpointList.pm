package DBGp::Client::Response::BreakpointList;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

use DBGp::Client::Response::Breakpoint;

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command
));

sub breakpoints {
    return [map +(bless $_, 'DBGp::Client::Response::Breakpoint'),
                DBGp::Client::Parser::_nodes($_[0], 'breakpoint')];
}

1;
