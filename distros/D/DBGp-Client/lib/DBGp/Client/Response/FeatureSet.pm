package DBGp::Client::Response::FeatureSet;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command success
));

sub feature {
    defined $_[0]->{attrib}{feature} ? $_[0]->{attrib}{feature} :
                                       $_[0]->{attrib}{feature_name}
}

1;
