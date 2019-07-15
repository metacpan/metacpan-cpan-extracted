package Datahub::Factory::Pipeline::Index;

use Datahub::Factory::Sane;

our $VERSION = '1.75';

use Moo;
use namespace::clean;

with 'Datahub::Factory::Pipeline';

sub parse {
    my $self = shift;
    my $options;

    # Indexer

    my $indexer = $self->config->param('Indexer.plugin');
    if (!defined($indexer)) {
        Datahub::Factory::InvalidPipeline->throw(
            'message' => sprintf('Undefined value for plugin at [Indexer]')
        );
    }

    $options->{'indexer'} = {
        'name'    => $indexer,
        'options' => $self->plugin_options('indexer', $indexer)
    };

    return $options;
}

1;

__END__

