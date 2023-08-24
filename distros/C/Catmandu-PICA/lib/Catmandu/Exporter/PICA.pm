package Catmandu::Exporter::PICA;
use strict;
use warnings;

use Catmandu::Sane;
use PICA::Data qw(pica_writer);
use Moo;

our $VERSION = '1.17';

with 'Catmandu::Exporter';

has type               => ( is => 'rw', default => sub { 'xml' } );
has subfield_indicator => ( is => 'rw', default => sub { '$' } );
has field_separator    => ( is => 'rw', default => sub { "\n" } );
has record_separator   => ( is => 'rw', default => sub { "\n" } );
has writer             => ( is => 'lazy' );
has annotate           => ( is => 'rw' );

sub _build_writer {
    my ($self) = @_;
    pica_writer(
        $self->type,
        fh       => $self->fh,
        us       => $self->subfield_indicator,
        rs       => $self->field_separator,
        gs       => $self->record_separator,
        annotate => $self->annotate,
    );
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
can be configured with 

=over

=item C<type>

Serialization type as described at L<Catmandu::Importer>. Supports C<xml>
(default), C<plain>, C<import>, C<plus>, C<picaplus>, C<binary>, and C<ppxml>.

The type C<generic> can be used to further control output format with options:

=item C<annotate>

Include field annotations to write annotated PICA format (e.g. PICA Patch format).

=item C<subfield_indicator>

Character sequence to use as subfield indicator (serialization type C<generic> only)

=item C<field_separator>

Character sequence to write at the end of a field (serialization type C<generic> only)

=item C<record_separator>

Character sequence to write at the end of a record (serialization type C<generic> only)

=back

=cut
