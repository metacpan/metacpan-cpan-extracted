package DBGp::Client::Response::Breakpoint;

use strict;
use warnings;

use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    id type state filename lineno function exception
    hit_value hit_condition hit_count temporary
));

sub expression {
    my $value = DBGp::Client::Parser::_node($_[0], 'expression');

    return DBGp::Client::Parser::_text($value);
}

1;
