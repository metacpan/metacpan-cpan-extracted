package Data::AMF::Formatter::AMF0;
use Any::Moose;

require bytes;
use Scalar::Util qw/looks_like_number blessed/;
use Data::AMF::IO;

has 'io' => (
    is      => 'rw',
    isa     => 'Data::AMF::IO',
    lazy    => 1,
    default => sub {
        Data::AMF::IO->new( data => q[] );
    },
);

no Any::Moose;

sub format {
    my ($self, @obj) = @_;
    $self = $self->new unless blessed $self;

    for my $obj (@obj) {
        if (my $pkg = blessed $obj) {
            $self->format_typed_object($obj);
        }
        elsif (my $ref = ref($obj)) {
            if ($ref eq 'ARRAY') {
                $self->format_strict_array($obj);
            }
            elsif ($ref eq 'HASH') {
                $self->format_object($obj);
            }
            else {
                Carp::confess qq[cannot format "$ref" object];
            }
        }
        else {
            if (looks_like_number($obj) && $obj !~ /^0\d/) {
                $self->format_number($obj);
            }
            elsif (defined($obj)) {
                $self->format_string($obj);
            }
            else {
                $self->format_null($obj);
            }
        }
    }

    $self->io->data;
}

sub format_number {
    my ($self, $obj) = @_;
    $self->io->write_u8(0x00);
    $self->io->write_double($obj);
}

sub format_string {
    my ($self, $obj) = @_;
    $self->io->write_u8(0x02);
    $self->io->write_utf8($obj);
}

sub format_strict_array {
    my ($self, $obj) = @_;
    my @array = @{ $obj };

    $self->io->write_u8(0x0a);

    $self->io->write_u32( scalar @array );
    for my $v (@array) {
        $self->format($v);
    }
}

sub format_object {
    my ($self, $obj) = @_;

    $self->io->write_u8(0x03);

    for my $key (keys %$obj) {
        my $len = bytes::length($key);
        $self->io->write_u16($len);
        $self->io->write($key);
        $self->format($obj->{$key});
    }

    $self->io->write_u16(0x00);
    $self->io->write_u8(0x09);      # object-end marker
}

sub format_null {
    my ($self, $obj) = @_;

    $self->io->write_u8(0x05);  # null marker
}

sub format_typed_object {
    my ($self, $obj) = @_;

    $self->io->write_u8(0x10);

    my $class = blessed $obj;
    $self->io->write_utf8($class);

    $self->format_object($obj);
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Data::AMF::Formatter::AMF0 - AMF0 serializer

=head1 SYNOPSIS

    my $amf0_data = Data::AMF::Formatter::AMF0->format($obj);

=head1 METHODS

=head2 format

=head2 format_number

=head2 format_string

=head2 format_strict_array

=head2 format_object

=head2 format_null

=head2 format_typed_object

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
