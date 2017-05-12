package DBGp::Client::Response::ContextNames;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command
));

sub contexts {
    return [map +(bless $_, 'DBGp::Client::Response::ContextName'),
                DBGp::Client::Parser::_nodes($_[0], 'context')];
}

package DBGp::Client::Response::ContextName;

use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    name id
));

1;
