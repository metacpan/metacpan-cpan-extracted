package Datahub::Factory::Command::transport;

use Datahub::Factory::Sane;

use parent 'Datahub::Factory::Cmd';

use Module::Load;
use Catmandu;
use Catmandu::Util qw(data_at);
use Datahub::Factory;
use namespace::clean;
use Datahub::Factory::PipelineConfig;
use Datahub::Factory::Fixer::Condition;

use Data::Dumper qw(Dumper);

sub abstract { "Transport data from a data source to a datahub instance" }

sub description { "Long description on blortex algorithm" }

sub opt_spec {
	return (
		[ "pipeline|p=s", "Location of the pipeline configuration file"]
	);
}

sub validate_args {
	my ($self, $opt, $args) = @_;

    if (! $opt->{'pipeline'}) {
        $self->usage_error('The --pipeline flag is required.');
    }

	my $pcfg = Datahub::Factory->pipeline($opt);
    try {
        $pcfg->check_object();
    } catch {
        $self->usage_error($_);
    }
	# no args allowed but options!
	$self->usage_error("No args allowed") if @$args;
}

sub execute {
  my ($self, $arguments, $args) = @_;

  my $logger = Datahub::Factory->log;

  my ($pcfg, $opt);
  try {
      $pcfg = Datahub::Factory->pipeline($arguments);
      $opt = $pcfg->opt;
  } catch {
        my $error_msg;
        if ($_->can('message')) {
              $error_msg = $_->message;
        } else {
              $error_msg = $_;
        }
        $logger->fatal($error_msg);
        exit 1;
  };

  # Load modules
  my ($import_module, $fix_module, $export_module);
  try {
      $import_module = Datahub::Factory->importer($opt->{importer})->new($opt->{oimport});
  } catch {
        my $error_msg;
        if ($_->can('message')) {
              $error_msg = sprintf('%s at [plugin_importer_%s]', $_->message, $opt->{'importer'});
        } else {
              $error_msg = sprintf('%s at [plugin_importer_%s]', $_, $opt->{'importer'});
        }
        $logger->fatal($error_msg);
        exit 1;
  };
  try {
      $export_module = Datahub::Factory->exporter($opt->{exporter})->new($opt->{oexport});
  } catch {
        my $error_msg;
        if ($_->can('message')) {
              $error_msg = sprintf('%s at [plugin_exporter_%s]', $_->message, $opt->{'exporter'});
        } else {
              $error_msg = sprintf('%s at [plugin_exporter_%s]', $_, $opt->{'exporter'});
        }
        $logger->fatal($error_msg);
        exit 1;
  };

  # Perform import/fix/export
  #try {
      my $condition = Datahub::Factory::Fixer::Condition->new('options' => $opt);
      $condition->fixers;
  #} catch {
      # todo
      #   Implement me.
  #}


  # Catmandu::Fix treats all warnings as fatal errors (this is good)
  # so we can catch them with try-catch
  # Not that errors here are _not_ fatal => continue running
  # till all records have been processed
  my $counter = 0;

  # $import_module->importer might also generate to-catch errors
  $import_module->each(sub {
      my $item = shift;
      my $fix_module;

      my $item_id = data_at($opt->{'id_path'}, $item);

      $counter++;

      my $f = try {
          ##
          # Normally, failures in loading the fixer (which happens here)
          # *should* be fatal. However. Perl/Catmandu does not really allow
          # us to distinguish between errors:
          # - Failure to load a module should be fatal and end the program.
          # - Failure to find the correct fix because the $condition does not appear
          #   *should not* be fatal and continue the run.
          # The second failure will happen more, and will cause more issues
          # so, we don't die and simply log the error, and continue to the next
          # $item. This will have the effect of errorring out on every $item if
          # the first failure occurs. Nihil ad facere. (This is not good Latin)
          ##
          my $c = try {
            $fix_module = $condition->fix_module($item);
          } catch {
              if ($_->meta->name eq 'Catmandu::BadVal') {
                  # Non-fatal
                  $logger->error('Item %d (counted): could not execute fix: %s', $counter, $_->message);
                  return 1;
              } else {
                  my $error_msg;
                  if ($_->can('message')) {
                      $error_msg = $_->message;
                  } else {
                      $error_msg = $_;
                  }
                  $logger->fatal($error_msg);
                  exit 1;
              }
          };

          if (defined($c) && $c == 1) {
              return 1;
          } else {
             # Execute the fix
             $fix_module->fixer->fix($item);
          }
      } catch {
          my $error_msg;
          if ($_->can('message')) {
              $error_msg = sprintf('Item %d (counted): could not execute fix: %s', $counter, $_->message);
          } else {
              $error_msg = sprintf('Item %d (counted): could not execute fix: %s', $counter, $_);
          }
          $logger->error($error_msg);
          return 1;
      };
      if (defined($f) && $f == 1) {
          # End the processing of this record, go to the next one.
          return;
      }

      my $e = try {
          $export_module->add($item);
      } catch {
          my $error_msg;

          # $item_id can be undefined if it isn't set in the source, but this
          # is only discovered when exporting (and not during fixing)
          my $id_type = 'id';
          if (!defined($item_id)) {
              $item_id = $counter;
              $id_type = 'counted';
          }
          if ($_->can('message')) {
              $error_msg = sprintf('Item %s (%s): could not export item: %s', $item_id, $id_type, $_->message);
          } else {
              $error_msg = sprintf('Item %s (%s): could not export item: %s', $item_id, $id_type, $_);
          }
          $logger->error($error_msg);
          return 1;
      };

      if (defined($e) && $e == 1) {
          # End the processing of this record, go to the next one.
          return;
      }
      $logger->info(sprintf('Item #%s : %s (id): exported.', $counter, $item_id));
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

    [plugin_importer_OAI]
    endpoint = https://oai.my.museum/oai

    [Fixer]
    plugin = Fix

    [plugin_fixer_Fix]
    file_name = '/home/datahub/my.fix'
    id_path = 'lidoRecID.0._'

    [Exporter]
    plugin = LIDO

    [plugin_exporter_LIDO]

All plugins have their own configuration options in sections called
C<[plugin_type_name]> where C<type> can be I<importer>, I<exporter>
or I<fixer> and C<name> is the name of the plugin.

All plugins define their own options as parameters to the respective
plugin. All possible parameters are valid items in the configuration
section.

If a plugin requires no options, you still need to create the (empty)
configuration section (e.g. C<[plugin_exporter_LIDO]> in the above
example).

=head4 Fixer plugin

    [plugin_fixer_Fix]
    condition = record.institution_name
    fixers = MSK, GRO
    id_path = record.id

    [plugin_fixer_Fix]
    file_name = /home/datahub/my.fix
    id_path = record.id

The C<[plugin_fixer_Fix]> can directly load a fix file (via the option
C<file_name>) or can be configured to conditionally load a different
fix file to support multiple fix files for the same data stream (e.g.
when two institutions with different data models use the same API
endpoint). This is done by setting the C<condition> and C<fixers>
options.

The C<id_path> option contains the path (in Fix syntax) of the identifier of
each record in your data after the fix has been applied, but before it is
submitted to the I<Exporter>. It is used for reporting and logging.

=head4 Conditional fixers

    [plugin_fixer_Fix]
    condition = record.institution_name
    fixers = MSK, GRO
    id_path = 'lidoRecID.0._'

    [plugin_fixer_GRO]
    condition = 'Groeningemuseum'
    file_name = '/home/datahub/gro.fix'

    [plugin_fixer_MSK]
    condition = 'Museum voor Schone Kunsten Gent'
    file_name = '/home/datahub/msk.fix'

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

  [Fixer]
  plugin = Fix

  [Exporter]
  plugin = Datahub

  [plugin_importer_Adlib]
  file_name = '/tmp/adlib.xml'
  data_path = 'recordList.record.*'

  [plugin_fixer_Fix]
  file_name = '/tmp/msk.fix'
  id_path = 'record.id'

  [plugin_exporter_Datahub]
  datahub_url = https://my.thedatahub.io
  datahub_format = LIDO
  oauth_client_id = datahub
  oauth_client_secret = datahub
  oauth_username = datahub
  oauth_password = datahub

=head1 AUTHORS

Pieter De Praetere <pieter@packed.be>

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=head1 COPYRIGHT

Copyright 2016 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
