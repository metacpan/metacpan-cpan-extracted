package DBGp::Client::Response::FeatureGet;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command supported
));

sub feature {
    defined $_[0]->{attrib}{feature} ? $_[0]->{attrib}{feature} :
                                       $_[0]->{attrib}{feature_name}
}

sub value {
    return DBGp::Client::Parser::_text($_[0])
}

1;
