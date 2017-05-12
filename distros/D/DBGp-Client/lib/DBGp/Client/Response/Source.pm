package DBGp::Client::Response::Source;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    transaction_id command success
));

sub source {
    my $text = DBGp::Client::Parser::_text($_[0]);
    my $encoding = $_[0]->{attrib}{encoding};

    return DBGp::Client::Parser::_decode($text, $encoding);
}

1;
