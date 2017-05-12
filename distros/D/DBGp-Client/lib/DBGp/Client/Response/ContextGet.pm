package DBGp::Client::Response::ContextGet;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

use DBGp::Client::Response::Property;

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command context_id
));

sub values {
    return [map +(bless $_, 'DBGp::Client::Response::Property'),
                DBGp::Client::Parser::_nodes($_[0], 'property')];
}

1;
