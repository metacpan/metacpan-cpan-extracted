package Datahub::Factory::Pipeline::Transport;

use Datahub::Factory::Sane;

our $VERSION = '1.77';

use Moo;
use namespace::clean;

with 'Datahub::Factory::Pipeline';

sub parse {
    my $self = shift;
    my $options;

    # General

    # Set the id_path of the incoming item. Points to the identifier of an object.

    if (!defined($self->config->param('General.id_path'))) {
        Datahub::Factory::InvalidPipeline->throw(
            'message' => sprintf('Missing required property id_path in the [General] block.')
        );
    }

    $options->{'id_path'} = $self->config->param('General.id_path');

    # Importer

    my $importer = $self->config->param('Importer.plugin');
    if (!defined($importer)) {
        Datahub::Factory::InvalidPipeline->throw(
            'message' => sprintf('Undefined value for plugin at [Importer]')
        );
    }

    $options->{'importer'} = {
        'name'    => $importer,
        'options' => $self->plugin_options('importer', $importer)
    };

    # Exporter

    my $exporter = $self->config->param('Exporter.plugin');
    if (!defined($exporter)) {
        Datahub::Factory::InvalidPipeline->throw(
            'message' => sprintf('Undefined value for plugin at [Exporter]')
        );
    }

    $options->{'exporter'} = {
        'name'    => $exporter,
        'options' => $self->plugin_options('exporter', $exporter)
    };

    # Fixers

    # Default fixer

    my $fixer = $self->config->param('Fixer.plugin');
    if (!defined($fixer)) {
        die 'Undefined value for plugin at [Fixer]'; # Throw Error object instead
    }

    my $plugin_options = $self->plugin_options('fixer', $fixer);

    # Validate if both condition_path or fixers properties are present
    if (!defined($plugin_options->{'file_name'})) {
        if (!defined($plugin_options->{'condition_path'})) {
            Datahub::Factory::InvalidPipeline->throw(
                'message' => sprintf('The "condition_path" was not set correctly.')
            );
        }

        if (!defined($plugin_options->{'fixers'})) {
            Datahub::Factory::InvalidPipeline->throw(
                'message' => sprintf('The "fixers" was not set correctly.')
            );
        }
    }

    # If fixers exist, check if comma separated list, if not throw validation error

    $options->{'fixer'}->{'plugin'} = $fixer;

    $options->{'fixer'}->{$fixer} = {
        'name' => $fixer,
        'options' => $self->plugin_options('fixer', $fixer)
    };

    if (defined($options->{'fixer'}->{$fixer}->{'options'}->{'fixers'})) {
        my $conditional_fixers;

        if (ref($options->{'fixer'}->{$fixer}->{'options'}->{'fixers'}) ne 'ARRAY') {
            my @items = ();
            push @items, $options->{'fixer'}->{$fixer}->{'options'}->{'fixers'};
            $options->{'fixer'}->{$fixer}->{'options'}->{'fixers'} = \@items;
        }

        $conditional_fixers = $options->{'fixer'}->{$fixer}->{'options'}->{'fixers'};
        foreach my $conditional_fixer (@{$conditional_fixers}) {
           $options->{'fixer'}->{'conditionals'}->{$conditional_fixer} = {
               'name' => $conditional_fixer,
               'options' => $self->block_options(sprintf('plugin_fixer_%s', $conditional_fixer))
           };
        }
    }

    return $options;
}


1;

__END__

