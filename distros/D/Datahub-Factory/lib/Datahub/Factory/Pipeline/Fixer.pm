package Datahub::Factory::Pipeline::Fixer;

use Datahub::Factory::Sane;

our $VERSION = '1.75';

use Moo;
use namespace::clean;

with 'Datahub::Factory::Pipeline';

sub parse {
    my $self = shift;
    my $options = shift;

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

    $$options->{'fixer'}->{'plugin'} = $fixer;

    $$options->{'fixer'}->{$fixer} = {
        'name' => $fixer,
        'options' => $self->plugin_options('fixer', $fixer)
    };

    my $conditional_fixers = $$options->{'fixer'}->{$fixer}->{'options'}->{'fixers'};
    foreach my $conditional_fixer (@{$conditional_fixers}) {
        $$options->{'fixer'}->{'conditionals'}->{$conditional_fixer} = {
            'name' => $conditional_fixer,
            'options' => $self->block_options(sprintf('plugin_fixer_%s', $conditional_fixer))
        };
    }
}

1;

__END__
