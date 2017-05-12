package Catmandu::Exporter::PICA;
use strict;
use warnings;

use Catmandu::Sane;
use PICA::Writer::Plus;
use PICA::Writer::Plain;
use PICA::Writer::Binary;
use PICA::Writer::XML;
use Moo;

our $VERSION = '0.19';

with 'Catmandu::Exporter';

has type   => ( is => 'rw', default => sub { 'xml' } );
has writer => ( is => 'lazy' );

sub _build_writer {
    my ($self) = @_;

    my $type = lc $self->type;

    if ( $type =~ /^(pica)?plus$/ ) {
        PICA::Writer::Plus->new( fh => $self->fh );
    } elsif ( $type eq 'binary') {
        PICA::Writer::Binary->new( $self->fh );
    } elsif ( $type eq 'plain') {
        PICA::Writer::Plain->new( fh => $self->fh );
    } elsif ( $type eq 'xml') {
        PICA::Writer::XML->new( fh => $self->fh );
    } else {
        die "unknown type: $type";
    }
}
 
sub add {
    my ($self, $data) = @_;
    # utf8::decode ???
    $self->writer->write($data);
}

sub commit { # TODO: why is this not called automatically?
    my ($self) = @_;
    $self->writer->end if $self->can('end');
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
