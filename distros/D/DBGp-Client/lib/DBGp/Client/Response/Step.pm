package DBGp::Client::Response::Step;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id reason command status
));

sub filename {
    my $xdebug = DBGp::Client::Parser::_node($_[0], 'xdebug:message');

    return $xdebug->{attrib}{filename};
}

sub lineno {
    my $xdebug = DBGp::Client::Parser::_node($_[0], 'xdebug:message');

    return $xdebug->{attrib}{lineno};
}

1;
