package DBGp::Client::Response::Init;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_accessors(qw(
    fileuri parent idekey thread appid protocol_version hostname language
));

1;
