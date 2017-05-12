package DBGp::Client::Response::Notification;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    name
));

sub is_oob { '1' }
sub is_stream { '0' }
sub is_notification { '1' }

1;
