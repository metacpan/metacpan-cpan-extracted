package Datahub::Factory::Pipeline::Importer;

use Datahub::Factory::Sane;

our $VERSION = '1.77';

use Moo;
use namespace::clean;

with 'Datahub::Factory::Pipeline';

sub parse {
    my $self = shift;
    my $options = shift;

    # Set the id_path of the incoming item. Points to the identifier of an object.

    if (!defined($self->config->param('Importer.id_path'))) {
        Datahub::Factory::InvalidPipeline->throw(
            'message' => sprintf('Missing required property id_path in the [Importer] block.')
        );
    }
    $$options->{'id_path'} = $self->config->param('Importer.id_path');

    # Importer

    my $importer = $self->config->param('Importer.plugin');
    if (!defined($importer)) {
        Datahub::Factory::InvalidPipeline->throw(
            'message' => sprintf('Undefined value for plugin at [Importer]')
        );
    }

    $$options->{'importer'} = {
        'name'    => $importer,
        'options' => $self->plugin_options('importer', $importer)
    };

}

1;

__END__
