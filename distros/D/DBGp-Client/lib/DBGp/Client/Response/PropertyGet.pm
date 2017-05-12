package DBGp::Client::Response::PropertyGet;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

use DBGp::Client::Response::Property;

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command
));

sub property {
    return bless DBGp::Client::Parser::_node($_[0], 'property'),
                 'DBGp::Client::Response::Property';
}

1;
