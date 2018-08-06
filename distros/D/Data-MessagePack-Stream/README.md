[![Build Status](https://travis-ci.org/typester/Data-MessagePack-Stream.svg?branch=master)](https://travis-ci.org/typester/Data-MessagePack-Stream)
# NAME

Data::MessagePack::Stream - yet another messagepack streaming deserializer

# SYNOPSIS

    use Data::Dumper;
    my $unpacker = Data::MessagePack::Stream->new;

    while (read($fh, my $buf, 1024)) {
        $unpacker->feed($buf);

        while ($unpacker->next) {
            print Dumper($unpacker->data);
        }
    }

# DESCRIPTION

Data::MessagePack::Stream is streaming deserializer for MessagePack.

This module is alternate for [Data::MessagePack::Unpacker](https://metacpan.org/pod/Data::MessagePack::Unpacker).
Unlike original unpacker, this module support internal buffer and it's possible to handle streaming data correctly.

# METHODS

## new

    my $unpacker = Data::MessagePack::Stream->new;

Create new stream unpacker.

## feed($data)

    $unpacker->feed($data);

Push `$data` into unpacker's internal buffer.

## next

    my $bool = $unpacker->next;

If parsable MessagePack packet is fed, return true.
You can get that parsed data by `data` method described below.

## data

    my $data = $unpacker->data;

Return parsed perl object.

# AUTHOR

Daisuke Murase <typester@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (c) 2012 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
