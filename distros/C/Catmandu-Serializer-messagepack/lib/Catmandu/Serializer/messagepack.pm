package Catmandu::Serializer::messagepack;

use Catmandu::Sane;
use Data::MessagePack;
use MIME::Base64 ();
use Moo;

=head1 NAME

Catmandu::Serializer::messagepack - A Catmandu::Serializer backend using Data::MessagePack

=head1 VERSION

Version 0.0102

=cut

our $VERSION = '0.0102';

has mp => (
    is      => 'ro',
    default => sub { Data::MessagePack->new->utf8 },
);

sub serialize {
    MIME::Base64::encode($_[0]->mp->pack($_[1]));
}

sub deserialize {
    $_[0]->mp->unpack(MIME::Base64::decode($_[1]));
}

1;

