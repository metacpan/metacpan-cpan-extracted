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
	$options->{$importer_plugin} = $self->plugin_options('importer', $importer_plugin);

	my $fixer_plugin = $self->cfg->param('Fixer.plugin');
	if (!defined($fixer_plugin)) {
		die 'Undefined value for plugin at [Fixer]';
	}
	$options->{$fixer_plugin} = $self->plugin_options('fixer', $fixer_plugin);

	my $exporter_plugin = $self->cfg->param('Exporter.plugin');
	if (!defined($exporter_plugin)) {
		die 'Undefined value for plugin at [Exporter]';
	}
	$options->{$exporter_plugin} = $self->plugin_options('exporter', $exporter_plugin);

	# Legacy options
	$options->{'importer'} = $self->cfg->param('Importer.plugin');
	$options->{'fixer'} = $self->cfg->param('Fixer.plugin');
	$options->{'exporter'} = $self->cfg->param('Exporter.plugin');
	$options->{'oimport'} = $options->{$options->{'importer'}};
	$options->{'ofixer'} = $options->{$options->{'fixer'}};
	$options->{'oexport'} = $options->{$options->{'exporter'}};
	# Even more legacy
	$options->{'fixes'} = $options->{$options->{'fixer'}}->{'file_name'};
	$options->{'id_path'} = $options->{$options->{'fixer'}}->{'id_path'};

	return $options;
}

sub plugin_options {
	my ($self, $plugin_type, $plugin_name) = @_;
	my $block = $self->cfg->get_block(sprintf('plugin_%s_%s', $plugin_type, $plugin_name));
	return $block;
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

sub check_object {
    my $self = shift;


    if ( ! $self->conf_object->{pipeline} ) {
		# Only require the CLI switches if no pipeline file was specified
		if ( ! $self->conf_object->{importer} ) {
			die "Importer is missing";
		}

		if ( ! $self->conf_object->{exporter} ) {
			die "Exporter is missing";
		}

		if ( ! $self->conf_object->{fixes} ) {
			die "Fixes are missing";
		}

		if ( $self->conf_object->{importer} eq "Adlib" ) {
			if ( ! $self->conf_object->{oimport}->{file_name} ) {
				die "Adlib: Import file is missing";
			}
		}

		if ( $self->conf_object->{importer} eq "TMS" ) {
			if ( ! $self->conf_object->{oimport}->{db_name} ) {
				die "TMS: database name is missing";
			}

			if ( ! $self->conf_object->{oimport}->{db_user} ) {
				die "TMS: database user is missing";
			}

			if ( ! $self->conf_object->{oimport}->{db_password} ) {
				die "TMS: database user password is missing";
			}

			if ( ! $self->conf_object->{oimport}->{db_host} ) {
				die "TMS: database host is missing";
			}
		}

		if ( $self->conf_object->{exporter} eq "Datahub" ) {
			# This should move to a separate module
			if ( ! $self->conf_object->{oexport}->{datahub_url} ) {
				die "Datahub: the URL to the datahub instance is missing";
			}

			if ( ! $self->conf_object->{oexport}->{oauth_client_id} ) {
				die "Datahub OAUTH: the client id is missing";
			}

			if ( ! $self->conf_object->{oexport}->{oauth_client_secret} ) {
				die "Datahub OAUTH: the client secret is missing";
			}

			if ( ! $self->conf_object->{oexport}->{oauth_username} ) {
				die "Datahub OAUTH: the client username is missing";
			}

			if ( ! $self->conf_object->{oexport}->{oauth_password} ) {
				die "Datahub OAUTH: the client passowrd is missing";
			}
		}
	} else {
		if ( ! -f $self->conf_object->{pipeline} ) {
			die sprintf('The configuration file %s does not exist', $self->conf_object->{pipeline});
		}
	}
    return undef;
}

1;
