package AnyEvent::MessagePack;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.20';

use AnyEvent::Handle;

use Data::MessagePack 0.34;
use Data::MessagePack::Stream 0.05;

AnyEvent::Handle::register_write_type(msgpack => sub {
    my ($self, $data) = @_;
    Data::MessagePack->pack($data);
});

AnyEvent::Handle::register_read_type(msgpack => sub {
    my ($self, $cb) = @_;

    # FIXME This implementation eats all the data, so the stream may
    # contain only MessagePack packets.

    my $unpacker = $self->{_msgpack} ||= Data::MessagePack::Stream::->new;

    sub {
        my $buffer = delete $_[0]{rbuf};

        $unpacker->feed($buffer) if defined $buffer;

        if ($unpacker->next) {
            $cb->( $_[0], $unpacker->data );
            return 1;
        }
        return 0;
    }
});

1;
__END__

=encoding utf8

=head1 NAME

AnyEvent::MessagePack - MessagePack stream serializer/deserializer for AnyEvent

=head1 SYNOPSIS

    use AnyEvent::MessagePack;
    use AnyEvent::Handle;

    my $hdl = AnyEvent::Handle->new(
        # settings...
    );
    $hdl->push_write(msgpack => [ 1,2,3 ]);
    $hdl->push_read(msgpack => sub {
        my ($hdl, $data) = @_;
        # your code here
    });

=head1 DESCRIPTION

AnyEvent::MessagePack is MessagePack stream serializer/deserializer for AnyEvent.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 THANKS TO

kazeburo++

=head1 SEE ALSO

L<AnyEvent::Handle>, L<AnyEvent::MPRPC>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
