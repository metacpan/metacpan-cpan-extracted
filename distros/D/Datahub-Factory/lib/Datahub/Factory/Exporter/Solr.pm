package Datahub::Factory::Exporter::Solr;

use Datahub::Factory::Sane;

use Moo;
use Catmandu;
use HTTP::Headers;

with 'Datahub::Factory::Exporter';

has url         => (is => 'ro', required => 1);

sub _build_out {
    my $self = shift;
    my $store = Catmandu->store(
        'Solr',
        url => $self->url
    );

    return $store;
}

sub add {
    my ($self, $item) = @_;
    $self->out->bag->add($item);
    $self->out->bag->commit;
}

1;
