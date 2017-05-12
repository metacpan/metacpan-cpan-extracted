package Datahub::Factory::Exporter::LIDO;

use strict;
use warnings;

use Moo;
use Catmandu;

has file_name => (is => 'ro');

with 'Datahub::Factory::Exporter';

sub _build_out {
    my $self = shift;
    my $exporter;
    if (defined($self->file_name)) {
        $exporter = Catmandu->exporter('LIDO', file => $self->file_name);
    } else {
        $exporter = Catmandu->exporter('LIDO');
    }
    return $exporter;
}

sub add {
    my ($self, $item) = @_;
    $self->out->add($item);
}

1;
