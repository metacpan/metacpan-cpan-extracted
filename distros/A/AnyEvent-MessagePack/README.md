# NAME

AnyEvent::MessagePack - MessagePack stream serializer/deserializer for AnyEvent

# SYNOPSIS

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

# DESCRIPTION

AnyEvent::MessagePack is MessagePack stream serializer/deserializer for AnyEvent.

# AUTHOR

Tokuhiro Matsuno &lt;tokuhirom AAJKLFJEF@ GMAIL COM>

# THANKS TO

kazeburo++

# SEE ALSO

[AnyEvent::Handle](https://metacpan.org/pod/AnyEvent::Handle), [AnyEvent::MPRPC](https://metacpan.org/pod/AnyEvent::MPRPC)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
