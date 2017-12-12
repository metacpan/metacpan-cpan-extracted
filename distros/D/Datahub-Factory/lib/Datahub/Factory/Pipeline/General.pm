package Datahub::Factory::Pipeline::General;

use Datahub::Factory::Sane;

our $VERSION = '1.73';

use Moo;
use namespace::clean;

with 'Datahub::Factory::Pipeline';

sub parse {
    my $self = shift;
    my $options = shift;

    # General

    # Set the id_path of the incoming item. Points to the identifier of an object.

    if (!defined($self->config->param('General.id_path'))) {
        Datahub::Factory::InvalidPipeline->throw(
            'message' => sprintf('Missing required property id_path in the [General] block.')
        );
    }

    $$options->{'id_path'} = $self->config->param('General.id_path');
}

1;

__END__
