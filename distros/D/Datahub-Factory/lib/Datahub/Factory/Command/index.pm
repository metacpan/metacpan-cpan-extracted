package Datahub::Factory::Command::index;

use Datahub::Factory::Sane;

our $VERSION = '1.77';

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

    if (! -e $opt->{'pipeline'}) {
        $self->usage_error('The provided pipeline file does not exist.'); 
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

Datahub::Factory::Command::transport - Transport data in bulk to a enterprise search engine.

=head1 DESCRIPTION

This command allows datamanagers to (a) fetch data from a local source (b)  upload the data to a search enterprise instance as a bulk file.

=head1 COMMAND LINE INTERFACE

=over

=item C<--pipeline>

Location of the pipeline configuration file.

=back

=head2 Pipeline configuration file

The I<pipeline configuration file> is in the L<INI format|http://search.cpan.org/~sherzodr/Config-Simple-4.59/Simple.pm#INI-FILE> and its location is provided to the application using the C<--pipeline> switch.

The file is broadly divided in two parts: the first (shortest) part configures
the pipeline itself and sets the plugin to use for the I<index> action. The second part sets options specific for the used plugin.

=head4 Pipeline configuration

This part has one section: C<[Indexer]>. This section has just one option: C<plugin>. Set this to the plugin you want to use for this action.

All current supported plugins are in the C<Indexer> folder.

=head3 Plugin configuration

    [Indexer]
    plugin = Solr

    [plugin_indexer_Solr]
    request_handler = http://path_to_solr_data_import_handler
    file_name = /tmp/upload.json

All plugins have their own configuration options in sections called C<[plugin_type_name]> where C<type> is I<indexer>  and C<name> is the name of the plugin.

All plugins define their own options as parameters to the respective
plugin. All possible parameters are valid items in the configuration
section.

If a plugin requires no options, you still need to create the (empty)
configuration section (e.g. C<[plugin_indexer_name]> in the above
example).

=head1 AUTHORS

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=head1 COPYRIGHT

Copyright 2016 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
