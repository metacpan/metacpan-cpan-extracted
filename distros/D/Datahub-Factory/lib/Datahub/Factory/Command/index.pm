package Datahub::Factory::Command::index;

use Datahub::Factory::Sane;

our $VERSION = '1.72';

use parent 'Datahub::Factory::Cmd';

use Moo;
use Module::Load;
use Catmandu;
use Catmandu::Util qw(data_at is_instance);
use Datahub::Factory;
use Datahub::Factory::Pipeline;
use Datahub::Factory::Fixer::Condition;
use namespace::clean;

with 'Datahub::Factory::Flash';

sub abstract {
    "Transport data from a flat file to a data index in bulk."
}

sub description {
    "Transport data from a flat file to a data sink in bulk using pipeline configurations."
}

sub opt_spec {
    return (
        [ "pipeline|p=s", "Location of the pipeline configuration file"],
        [ "verbose|v", "Verbose output"]
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    if (! $opt->{'pipeline'}) {
        $self->usage_error('The --pipeline flag is required.');
    }

    # no args allowed but options!
    $self->usage_error("No args allowed") if @$args;
}

sub execute {
    my ($self, $opt, $args) = @_;

    # Get a logger
    my $logger = Datahub::Factory->log;

    # Enable verbosity based on -v flag
    $self->verbose($opt->{verbose});

    # Load the configuration
    # @todo
    #    Validation of the pipeline configuration happens here. Throw and catch
    #    nice errors.
    $self->info("Loading pipeline configuration...");
    my ($pipeline, $options);
    $pipeline = Datahub::Factory->pipeline($opt->{pipeline}, 'Index');
    $options = $pipeline->parse();

    # Load an bulk exporter module.
    $self->info("Initializing indexer...");
    my ($indexer_module);
    $indexer_module = Datahub::Factory
        ->indexer($options->{indexer}->{name})
        ->new($options->{indexer}->{options});

    # Execute the indexer module.
    try {
        $indexer_module->index();
        $self->success('Indexing job completed.');
        $indexer_module->commit();
        $self->success('Commit job completed.');
    } catch {
        my $error = ($_->can('message')) ? $_->message : $_;

        # Catmandu modules produce a wide variety of exceptions. This
        # block catches them, but doesn't halt the processing entirely.
        $logger->error($error);
        $self->error($error);
        exit 1;
     };
}

1;

__END__

=head1 NAME

Datahub::Factory::Command::index - Implements the 'index' command.



