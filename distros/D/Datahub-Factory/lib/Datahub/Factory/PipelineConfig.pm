package Datahub::Factory::PipelineConfig;

use strict;
use warnings;

use Moo;
use namespace::clean;
use Config::Simple;
use Data::Dumper qw(Dumper);

has conf_object => (is => 'ro', required => 1);

has opt => (is => 'lazy');
has cfg => (is => 'lazy');

sub _build_cfg {
    my $self = shift;
    return new Config::Simple($self->conf_object->{pipeline});
}

sub _build_opt {
    my $self = shift;
    if ( ! $self->conf_object->{pipeline} ) {
        return $self->from_cli_args();
    } else {
        return $self->parse_conf_file();
    }
}

sub parse {
    my $self = shift;
    my $options;

    # Collect all plugins
    my $importer_plugin = $self->cfg->param('Importer.plugin');
    if (!defined($importer_plugin)) {
        die 'Undefined value for plugin at [Importer]';
    }
    $options->{sprintf('importer_%s', $importer_plugin)} = $self->plugin_options('importer', $importer_plugin);

    my $fixer_plugin = $self->cfg->param('Fixer.plugin');
    if (!defined($fixer_plugin)) {
        die 'Undefined value for plugin at [Fixer]';
    }
    $options->{sprintf('fixer_%s', $fixer_plugin)} = $self->plugin_options('fixer', $fixer_plugin);

    foreach my $fixer_conditional_plugin (@{$options->{sprintf('fixer_%s', $fixer_plugin)}->{'fixers'}}) {
        $options->{sprintf('fixer_%s', $fixer_conditional_plugin)} = $self->block_options(sprintf('plugin_fixer_%s', $fixer_conditional_plugin));
    }

    my $exporter_plugin = $self->cfg->param('Exporter.plugin');
    if (!defined($exporter_plugin)) {
        die 'Undefined value for plugin at [Exporter]';
    }
    $options->{sprintf('exporter_%s', $exporter_plugin)} = $self->plugin_options('exporter', $exporter_plugin);

    $options->{'importer'} = $self->cfg->param('Importer.plugin');
    $options->{'fixer'} = $self->cfg->param('Fixer.plugin');
    $options->{'exporter'} = $self->cfg->param('Exporter.plugin');

    if (!defined($self->cfg->param('Importer.id_path'))) {
        die "Missing required property id_path in the [Importer] block.";
    }
    $options->{'id_path'} = $self->cfg->param('Importer.id_path');

    # Legacy options
    $options->{'oimport'} = $options->{sprintf('importer_%s', $options->{'importer'})};
    $options->{'ofixer'} = $options->{sprintf('fixer_%s', $options->{'fixer'})};
    $options->{'oexport'} = $options->{sprintf('exporter_%s', $options->{'exporter'})};
    # Even more legacy
    $options->{'fixes'} = $options->{sprintf('fixer_%s', $options->{'fixer'})}->{'file_name'};

    return $options;
}

sub plugin_options {
    my ($self, $plugin_type, $plugin_name) = @_;
    return $self->block_options(sprintf('plugin_%s_%s', $plugin_type, $plugin_name));
}

sub module_options {
    my ($self, $module_name) = @_;
    return $self->block_options(sprintf('module_%s', $module_name));
}

sub block_options {
    my ($self, $plugin_block_name) = @_;
    return $self->cfg->get_block($plugin_block_name);
}

sub parse_conf_file {
    my $self = shift;
    return $self->parse();
}

sub from_cli_args {
    my $self = shift;
    # Why make things harder?
    return $self->conf_object;
}

1;
