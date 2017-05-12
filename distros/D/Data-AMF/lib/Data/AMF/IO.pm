package Data::AMF::IO;
use Any::Moose;

require bytes;

use constant ENDIAN => unpack('S', pack('C2', 0, 1)) == 1 ? 'BIG' : 'LITTLE';

has data => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { '' },
    lazy    => 1,
);

has pos => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 0 },
    lazy    => 1,
);

has refs => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    lazy    => 1,
);

no Any::Moose;

sub read {
    my ($self, $len) = @_;

    if ($len + $self->pos > bytes::length($self->data) ) {
        return;
    }

    my $data = substr $self->data, $self->pos, $len;
    $self->pos( $self->pos + $len );

    $data;
}

sub read_u8 {
    my $self = shift;

    my $data = $self->read(1);
    return unless defined $data;

    unpack('C', $data);
}

sub read_u16 {
    my $self = shift;

    my $data = $self->read(2);
    return unless defined $data;

    unpack('n', $data);
}

sub read_s16 {
    my $self = shift;

    my $data = $self->read(2);
    return unless defined $data;

    return unpack('s>', $data) if $] >= 5.009002;
    return unpack('s', $data)  if ENDIAN eq 'BIG';
    return unpack('s', swap($data));
}

sub read_u24 {
    my $self = shift;

    my $data = $self->read(3);
    return unpack('N', "\0$data");
}

sub read_u32 {
    my $self = shift;

    my $data = $self->read(4);
    unpack('N', $data);
}

sub read_double {
    my $self = shift;

    my $data = $self->read(8);

    return unpack('d>', $data) if $] >= 5.009002;
    return unpack('d', $data)  if ENDIAN eq 'BIG';
    return unpack('d', swap($data));
}

sub read_utf8 {
    my $self = shift;

    my $len = $self->read_u16;
    return unless defined $len;

    $self->read($len);
}

sub read_utf8_long {
    my $self = shift;

    my $len = $self->read_u32;
    return unless defined $len;

    $self->read($len);
}

sub swap {
    join '', reverse split '', $_[0];
}

sub write {
    my ($self, $data) = @_;
    $self->{data} .= $data;
}

sub write_u8 {
    my ($self, $data) = @_;
    $self->write( pack('C', $data) );
}

sub write_u16 {
    my ($self, $data) = @_;
    $self->write( pack('n', $data) );
}

sub write_s16 {
    my ($self, $data) = @_;

    return $self->write( pack('s>', $data) ) if $] >= 5.009002;
    return $self->write( pack('s', $data) )  if ENDIAN eq 'BIG';
    return $self->write( swap pack('s', $data) );
}

sub write_u24 {
    my ($self, $data) = @_;

    $data = pack('N', $data);
    $data = substr $data, 1, 3;

    $self->write($data);
}

sub write_u32 {
    my ($self, $data) = @_;
    $self->write( pack('N', $data) );
}

sub write_double {
    my ($self, $data) = @_;

    return $self->write( pack('d>', $data) ) if $] >= 5.009002;
    return $self->write( pack('d', $data) )  if ENDIAN eq 'BIG';
    return $self->write( swap pack('d', $data) );
}

sub write_utf8 {
    my ($self, $data) = @_;

    my $len = bytes::length($data);

    $self->write_u16($len);
    $self->write($data);
}

sub write_utf8_long {
    my ($self, $data) = @_;

    my $len = bytes::length($data);

    $self->write_u32($len);
    $self->write($data);
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Data::AMF::IO - IO class for reading/writing AMF data

=head1 DESCRIPTION

IO class for reading/writing AMF data

=head1 METHODS

=head2 new

=head2 read

=head2 read_u8

=head2 read_u16

=head2 read_s16

=head2 read_u24

=head2 read_u32

=head2 read_double

=head2 read_utf8

=head2 read_utf8_long

=head2 write

=head2 write_u8

=head2 write_u16

=head2 write_s16

=head2 write_u24

=head2 write_u32

=head2 write_double

=head2 write_utf8

=head2 write_utf8_long

=head2 swap

=head2 ENDIAN

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
