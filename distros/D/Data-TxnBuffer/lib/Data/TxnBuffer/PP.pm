package Data::TxnBuffer::PP;
use strict;
use warnings;
use parent 'Data::TxnBuffer::Base';

use Carp;

# pp interface
use constant LITTLE_ENDIAN => !(unpack('S', pack('C2', 0, 1)) == 1);

sub new {
    my ($class, $data) = @_;

    bless {
        cursor => 0,
        data   => defined $data ? $data : '',
    }, $class;
}

sub data {
    my ($self) = @_;
    $self->{data};
}

sub length {
    my ($self) = @_;
    CORE::length($self->{data});
}

sub cursor {
    my ($self) = @_;
    $self->{cursor};
}

sub spin {
    my ($self) = @_;

    my $read = substr $self->{data}, 0, $self->cursor;
    substr($self->{data}, 0, $self->cursor) = '';
    $self->reset;

    $read;
}

sub reset {
    my ($self) = @_;
    $self->{cursor} = 0;
    return;
}

sub clear {
    my ($self) = @_;
    $self->reset;
    $self->{data} = '';
}

sub write {
    my ($self, $data) = @_;
    $self->{data} .= $data;
}

sub read {
    my ($self, $len) = @_;

    if ($len <= 0) {
        croak sprintf 'Positive value is required for read len. got: %d', $len;
    }
    if ($self->cursor + $len > $self->length) {
        croak 'No enough data in buffer';
    }

    my $data = substr $self->data, $self->cursor, $len;
    $self->{cursor} += $len;

    $data;
}

sub write_u32 {
    my ($self, $n) = @_;
    $self->write(pack 'L', $n);
}

sub write_i32 {
    my ($self, $n) = @_;
    $self->write(pack 'l', $n);
}

sub read_u32 {
    my ($self) = @_;
    unpack 'L', $self->read(4);
}

sub read_i32 {
    my ($self) = @_;
    unpack 'l', $self->read(4);
}

sub write_u24 {
    my ($self, $n) = @_;
    my $data = pack 'L', $n;

    if (LITTLE_ENDIAN) {
        $self->{data} .= substr $data, 0, 3;
    }
    else {
        $self->{data} .= substr $data, 1, 3;
    }
}

sub write_i24 {
    my ($self, $n) = @_;
    my $data = pack 'l', $n;

    if (LITTLE_ENDIAN) {
        $self->{data} .= substr $data, 0, 3;
    }
    else {
        $self->{data} .= substr $data, 1, 3;
    }
}

sub read_u24 {
    my ($self) = @_;

    my $data = $self->read(3);
    if (LITTLE_ENDIAN) {
        $data .= pack 'C', 0;
    }
    else {
        $data = pack('C', 0) . $data;
    }

    unpack 'L', $data;
}

sub read_i24 {
    my ($self) = @_;

    my $n = $self->read_u24;
    $n |= 0xff000000 if ($n & 0x800000);

    unpack 'l', pack 'l', $n;
}

sub write_u16 {
    my ($self, $n) = @_;
    $self->write(pack 'S', $n);
}

sub write_i16 {
    my ($self, $n) = @_;
    $self->write(pack 's', $n);
}

sub read_u16 {
    my ($self) = @_;
    unpack 'S', $self->read(2);
}

sub read_i16 {
    my ($self) = @_;
    unpack 's', $self->read(2);
}

sub write_u8 {
    my ($self, $n) = @_;
    $self->write(pack 'C', $n);
}

sub write_i8 {
    my ($self, $n) = @_;
    $self->write(pack 'c', $n);
}

sub read_u8 {
    my ($self) = @_;
    unpack 'C', $self->read(1);
}

sub read_i8 {
    my ($self) = @_;
    unpack 'c', $self->read(1);
}

sub write_n32 {
    my ($self, $n) = @_;
    $self->write(pack 'N', $n);
}

sub read_n32 {
    my ($self) = @_;
    unpack 'N', $self->read(4);
}

sub write_n24 {
    my ($self, $n) = @_;
    $self->write(substr pack('N', $n), 1, 3);
}

sub read_n24 {
    my ($self) = @_;
    unpack 'N', pack('C', 0) . $self->read(3);
}

sub write_n16 {
    my ($self, $n) = @_;
    $self->write(pack 'n', $n);
}

sub read_n16 {
    my ($self) = @_;
    unpack 'n', $self->read(2);
}

sub write_float {
    my ($self, $n) = @_;
    $self->write(pack 'f', $n);
}

sub read_float {
    my ($self) = @_;
    unpack 'f', $self->read(4);
}

sub write_double {
    my ($self, $n) = @_;
    $self->write(pack 'd', $n);
}

sub read_double {
    my ($self) = @_;
    unpack 'd', $self->read(8);
}

1;

__END__

=head1 NAME

Data::TxnBuffer::PP - PP interface for Data::TxnBuffer

=head1 DESCRIPTION

This module is a Pure Perl implementation for Data::TxnBuffer.
See L<Data::TxnBuffer> for more detail.

=head1 METHODS

=head2 clear

=head2 cursor

=head2 data

=head2 length

=head2 new

=head2 read

=head2 read_i16

=head2 read_i24

=head2 read_i32

=head2 read_i8

=head2 read_n16

=head2 read_n24

=head2 read_n32

=head2 read_u16

=head2 read_u24

=head2 read_u32

=head2 read_u8

=head2 read_double

=head2 read_float

=head2 reset

=head2 spin

=head2 write

=head2 write_i16

=head2 write_i24

=head2 write_i32

=head2 write_i8

=head2 write_n16

=head2 write_n24

=head2 write_n32

=head2 write_u16

=head2 write_u24

=head2 write_u32

=head2 write_u8

=head2 write_double

=head2 write_float

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
