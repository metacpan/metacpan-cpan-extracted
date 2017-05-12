package Data::MessagePack::Stream;
use strict;
use warnings;
use XSLoader;

our $VERSION = '1.01';

XSLoader::load __PACKAGE__, $VERSION;

1;

__END__

=for stopwords
messagepack deserializer parsable unpacker unpacker's

=head1 NAME

Data::MessagePack::Stream - yet another messagepack streaming deserializer

=head1 SYNOPSIS

    use Data::Dumper;
    my $unpacker = Data::MessagePack::Stream->new;

    while (read($fh, my $buf, 1024)) {
        $unpacker->feed($buf);

        while ($unpacker->next) {
            print Dumper($unpacker->data);
        }
    }

=head1 DESCRIPTION

Data::MessagePack::Stream is streaming deserializer for MessagePack.

This module is alternate for L<Data::MessagePack::Unpacker>.
Unlike original unpacker, this module support internal buffer and it's possible to handle streaming data correctly.

=head1 METHODS

=head2 new

    my $unpacker = Data::MessagePack::Stream->new;

Create new stream unpacker.

=head2 feed($data)

    $unpacker->feed($data);

Push C<$data> into unpacker's internal buffer.

=head2 next

    my $bool = $unpacker->next;

If parsable MessagePack packet is fed, return true.
You can get that parsed data by C<data> method described below.

=head2 data

    my $data = $unpacker->data;

Return parsed perl object.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
