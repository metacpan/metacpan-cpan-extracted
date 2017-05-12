package DBGp::Client::Response::Stream;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    type
));

sub content {
    my $text = DBGp::Client::Parser::_text($_[0]);
    my $encoding = $_[0]->{attrib}{encoding};

    return DBGp::Client::Parser::_decode($text, $encoding);
}

sub is_oob { '1' }
sub is_stream { '1' }
sub is_notification { '0' }

1;
