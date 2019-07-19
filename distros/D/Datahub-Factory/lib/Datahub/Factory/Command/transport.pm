package Datahub::Factory::Command::transport;

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
    "Transport data from a data source to a data sink."
}

sub description {
    "Transport data from a data source to a data sink using pipeline configurations."
}

sub opt_spec {
    return (
        [ "pipeline|p=s", "Location of the pipeline configuration file"],
        [ "general|g=s", "Location of the general configuration file"],
        [ "importer|i=s", "Location of the importer configuration file"],
        [ "fixer|f=s", "Location of the fixer configuration file"],
        [ "exporter|e=s", "Location of the exporter configuration file"],
        [ "number|n=i", "Number of records to process before breaking"],
        [ "verbose|v", "Verbose output"]
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    if (! $opt->{'pipeline'}) {
        for my $plugin ('general', 'importer', 'fixer', 'exporter') {
            if (! $opt->{$plugin}) {
                $self->usage_error(sprintf('The --%s configuration file is required.', $plugin));
            }

            if (! -e $opt->{$plugin}) {
                $self->usage_error(sprintf('The provided %s configuration file does not exist.', $plugin));
            }
        }
    } else {
        if (! -e $opt->{'pipeline'}) {
            $self->usage_error('The provided pipeline file does not exist.');
        }
    }

    # no args allowed, only options!
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

    if (! $opt->{pipeline}) {
        for my $plugin ('general', 'importer', 'fixer', 'exporter') {
            $pipeline = Datahub::Factory->pipeline($opt->{$plugin}, ucfirst($plugin));
            $pipeline->parse(\$options);
        }
    } else {
        $pipeline = Datahub::Factory->pipeline($opt->{pipeline}, 'Transport');
        $options = $pipeline->parse();
    }

    # Load modules
    $self->info("Initializing importer/exporter...");
    my ($import_module, $fix_module, $export_module);
    $import_module = Datahub::Factory
        ->importer($options->{importer}->{name})
        ->new($options->{importer}->{options});
    $export_module = Datahub::Factory
        ->exporter($options->{exporter}->{name})
        ->new($options->{exporter}->{options});

    # Load conditions & fixers
    $self->info("Initializing fixers...");
    my $condition = Datahub::Factory::Fixer::Condition->new('fixer' => $options->{fixer});
    my $fixers = $condition->get_fixers();

    my $counter = 0;

    # Import data and start processing
    $self->info("Importing data from source...");
    $import_module->each(sub {
        my $item = shift;
        my ($msg, $item_id);

        $counter++;

        $item_id = data_at($options->{'id_path'}, $item);
        $item_id //= 'Undefined ID';

        # We use an extra try/catch block here to catch non-fatal errors. If we
        # didn't, errors thrown by the Catmandu modules would be caught by the
        # catch block in CLI.pm and break the processing. Errors caused by
        # dirty data should skip the processing of a particular record.
        if (try {
            $fix_module = $condition->fix_module($fixers, $item);
            $fix_module->fixer->fix($item);
            $export_module->add($item);

            $msg = sprintf('Item #%s : %s (id): exported.', $counter, $item_id);
            $self->success($msg);
            $logger->info($msg);
        } catch {
            my $error = ($_->can('message')) ? $_->message : $_;

            # Determine if we should skip, or halt the processing entirely.
            # Depends on the type of Exception which bubbles up.
            if (is_instance $_, 'Catmandu::BadVal') {
                $msg = sprintf('Item #%d (counted): %s (id): could not execute fix: %s', $counter, $item_id, $error);
                $self->error($msg);
                $logger->error($msg);
                return 1;
            }
            elsif (is_instance $_, 'Datahub::Factory::InvalidCondition') {
                $msg = sprintf('Item #%d (counted): %s (id): %s', $counter, $item_id, $error);
                $self->error($msg);
                $logger->error($msg);
                return 1;
            }
            elsif (is_instance $_, 'Datahub::Factory::InvalidPipeline') {
                # Throw a fatal error if the pipeline configuration was invalid
                $self->error($msg);
                $logger->fatal($error);
                exit 1;
            }
            elsif (is_instance $_, 'Datahub::Factory::FixFileNotFound') {
                # Throw a fatal error if the pipeline configuration was invalid
                $self->error($msg);
                $logger->fatal($error);
                exit 1;
            }
            elsif (is_instance $_, 'Datahub::Factory::ModuleNotFound') {
                # Throw a fatal error if we couldn't load a fix module
                $logger->fatal($error);
                exit 1;
            }
            elsif (is_instance $_, 'Catmandu::HTTPError') {
                # Need to move this to proper Exception handling.
                if (!defined($error)) {
                    $error = $_->response_body;
                }
                $msg = sprintf('Item %d (counted): %s (id): %s', $counter, $item_id, $error);
                $self->error($msg);
                $logger->fatal($error);
                return 1;
            }
            else {
                # Catmandu modules produce a wide variety of exceptions. This
                # block catches them, but doesn't halt the processing entirely.
                $msg = sprintf('Item %d (counted): %s (id): %s', $counter, $item_id, $error);
                $logger->error($msg);
                $self->error($error);
                return 1;
            }
        } finally {
            # Break when we hit the pre-defined number of records to process
            # if this option was set.
            if ($opt->{number}) {
                if ($counter == $opt->{number}) {
                    exit 1;
                }
            }
        }) {
            # skip to the next record if an error was raised.
            return 1;
        };
    });
}

1;

__END__

=head1 NAME

Datahub::Factory::Command::transport - Implements the 'transport' command.

=head1 DESCRIPTION

This command allows datamanagers to (a) fetch data from a (local) source (b)
transform the data to LIDO using a fix (c) upload the LIDO transformed data to
a Datahub instance.

=head1 COMMAND LINE INTERFACE

=over

=item C<--pipeline>

Location of the pipeline configuration file.

=item C<--general>

Location of the general configuration file.

=item C<--importer>

Location of the importer configuration file.

=item C<--fixer>

Location of the fixer configuration file.

=item C<--exporter>

Location of the exporter configuration file.

=item C<--verbose>

Set this flag for pretty output of the ETL processing.

=back

=head2 Pipeline configuration file

The I<pipeline configuration file> is in the L<INI format|http://search.cpan.org/~sherzodr/Config-Simple-4.59/Simple.pm#INI-FILE> and its location is
provided to the application using the C<--pipeline> switch.

The file is broadly divided in two parts: the first (shortest) part configures
the pipeline itself and sets the plugins to use for the I<import>, I<fix> and
I<export> actions. The second part sets options specific for the used plugins.

=head4 Pipeline configuration

This part has three sections: C<[Importer]>, C<[Fixer]> and C<[Exporter]>.
Every section has just one option: C<plugin>. Set this to the plugin you
want to use for every action.

All current supported plugins are in the C<Importer> and C<Exporter> folders.
For the C<[Fixer]>, only the I<Fix> plugin is supported.

Supported I<Importer> plugins:

=over

=item L<TMS|Datahub::Factory::Importer::TMS>

=item L<Adlib|Datahub::Factory::Importer::Adlib>

=item L<OAI|Datahub::Factory::Importer::OAI>

=back

Supported I<Exporter> plugins:

=over

=item L<Datahub|Datahub::Factory::Exporter::Datahub>

=item L<LIDO|Datahub::Factory::Exporter::LIDO>

=item L<YAML|Datahub::Factory::Exporter::YAML>

=back

=head3 Plugin configuration

    [Importer]
    plugin = OAI
    id_path = 'lidoRecID.0._'

    [plugin_importer_OAI]
    endpoint = https://oai.my.museum/oai

    [Fixer]
    plugin = Fix

    [plugin_fixer_Fix]
    file_name = '/home/datahub/my.fix'

    [Exporter]
    plugin = YAML

    [plugin_exporter_YAML]

All plugins have their own configuration options in sections called
C<[plugin_type_name]> where C<type> can be I<importer>, I<exporter>
or I<fixer> and C<name> is the name of the plugin.

All plugins define their own options as parameters to the respective
plugin. All possible parameters are valid items in the configuration
section.

If a plugin requires no options, you still need to create the (empty)
configuration section (e.g. C<[plugin_exporter_LIDO]> in the above
example).

=head4 Importer plugin

The C<id_path> option contains the path (in Fix syntax) of the identifier of
each record in your data after the fix has been applied, but before it is
submitted to the I<Exporter>. It is used for reporting and logging.

=head4 Fixer plugin

    [plugin_fixer_Fix]
    condition = record.institution_name
    fixers = FOO, BAR

    [plugin_fixer_Fix]
    file_name = /home/datahub/my.fix

The C<[plugin_fixer_Fix]> can directly load a fix file (via the option
C<file_name>) or can be configured to conditionally load a different
fix file to support multiple fix files for the same data stream (e.g.
when two institutions with different data models use the same API
endpoint). This is done by setting the C<condition> and C<fixers>
options.

=head4 Conditional fixers

    [plugin_fixer_Fix]
    condition = record.institution_name
    fixers = FOO, BAR

    [plugin_fixer_FOO]
    condition = 'Museum of Foo'
    file_name = '/home/datahub/foo.fix'

    [plugin_fixer_BAR]
    condition = 'Museum of Bar'
    file_name = '/home/datahub/bar.fix'

If you want to separate the data stream into multiple (smaller) streams with
a different fix file for each stream, you can do this by setting the appropriate
options in the C<[plugin_fixer_Fix]> block. Note that C<id_path> is still mandatory.

Set C<condition> to the Fix-compatible path in the original stream that holds
the condition you want to use to split the stream.

Provide a comma-separated list of fixer plugins in C<fixers>.

For every fixer plugin in C<fixers>, create a configuration block called
C<[plugin_fixer_name]> and provide the following options:

=over

=item C<condition>

The value that the C<condition> from C<[plugin_fixer_Fix]> must have for
the record to belong to this block.

=item C<file_name>

The location of the fix file that must be executed for every record in this
block.

=back

=head4 Example configuration file

  [Importer]
  plugin = Adlib
  id_path = 'record.id'

  [Fixer]
  plugin = Fix

  [Exporter]
  plugin = Datahub

  [plugin_importer_Adlib]
  file_name = '/tmp/adlib.xml'
  data_path = 'recordList.record.*'

  [plugin_fixer_Fix]
  file_name = '/tmp/msk.fix'

  [plugin_exporter_Datahub]
  datahub_url = https://my.thedatahub.io
  datahub_format = LIDO
  oauth_client_id = datahub
  oauth_client_secret = datahub
  oauth_username = datahub
  oauth_password = datahub

=head1 AUTHORS

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>
Pieter De Praetere <pieter@packed.be>

=head1 COPYRIGHT

Copyright 2016 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
