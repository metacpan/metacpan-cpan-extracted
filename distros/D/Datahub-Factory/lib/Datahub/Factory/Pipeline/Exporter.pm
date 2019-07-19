package Datahub::Factory::Pipeline::Exporter;

use Datahub::Factory::Sane;

our $VERSION = '1.77';

use Moo;
use namespace::clean;

with 'Datahub::Factory::Pipeline';

sub parse {
    my $self = shift;
    my $options = shift;

    # Exporter

    my $exporter = $self->config->param('Exporter.plugin');
    if (!defined($exporter)) {
        Datahub::Factory::InvalidPipeline->throw(
            'message' => sprintf('Undefined value for plugin at [Exporter]')
        );
    }

    $$options->{'exporter'} = {
        'name'    => $exporter,
        'options' => $self->plugin_options('exporter', $exporter)
    };
}

1;

__END__
