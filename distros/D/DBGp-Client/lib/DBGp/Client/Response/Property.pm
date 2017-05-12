package DBGp::Client::Response::Property;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_attrib_accessors(qw(
    name fullname constant type children address pagesize page classname key facet size
));

sub numchildren { $_[0]->{attrib}{children} ? $_[0]->{attrib}{numchildren} : 0 }

sub value {
    my $value = DBGp::Client::Parser::_node($_[0], 'value');

    if (!$value) {
        # Xdebug compat
        my $text = DBGp::Client::Parser::_text($_[0]);

        return undef unless $text =~ /\S/;

        my $encoding = $_[0]->{attrib}{encoding};
        return DBGp::Client::Parser::_decode($text, $encoding);
    }

    if (my $encoding = $value->{attrib}{encoding}) {
        my $text = DBGp::Client::Parser::_text($value);

        return length($text) ? DBGp::Client::Parser::_decode($text, $encoding) : undef;
    }
}

sub childs {
    return [] unless $_[0]->children;

    return [
        map bless($_, 'DBGp::Client::Response::Property'),
            DBGp::Client::Parser::_nodes($_[0], 'property'),
    ];
}

1;
