package Catmandu::Exporter::PICA;
use strict;
use warnings;

use Catmandu::Sane;
use PICA::Data qw(pica_writer);
use Moo;

our $VERSION = '1.07';

with 'Catmandu::Exporter';

has type => ( is => 'rw', default => sub { 'xml' } );
has writer => ( is => 'lazy' );

sub _build_writer {
    my ($self) = @_;
    pica_writer( $self->type, fh => $self->fh );
}

sub add {
    my ( $self, $data ) = @_;

    # utf8::decode ???
    $self->writer->write($data);
}

sub commit {
    my ($self) = @_;

    # collection element is optional for type xml
    $self->writer->end if $self->writer->can('end');
}

1;
__END__

=head1 NAME

Catmandu::Exporter::PICA - Package that exports PICA data

=head1 DESCRIPTION

See L<PICA::Data> for more information about PICA data format and record
structure.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Exporter> the exporter
can be configured with a C<type> parameter as described at
L<Catmandu::Importer>.

=cut
