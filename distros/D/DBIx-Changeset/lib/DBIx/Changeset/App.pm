package DBIx::Changeset::App;

use warnings;
use strict;

use base qw/App::Cmd/;
use YAML 'LoadFile';
use Path::Class 'file';
use Hash::Merge qw( merge );

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::App - Main App File to the command line app

=head1 SYNOPSIS

Main App File to the command line app

create a script like so:

	#!/usr/bin/env perl
	use DBIx::Changeset::App;

	my $cmd = DBIx::Changeset::App->new();
	$cmd->config('config.yml');
	$cmd->run;


=head1 METHODS

=head2 config

Load Given YAML files as config 
expects a YAML File with following format

globaloption: <value>
command:
	commandoption: <value>

=cut
sub config {
	my ($app,$config) = @_;

	$app->{'config'} = {};
	Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );
	
	my @config_files;
	if ( defined $config && ref $config eq 'ARRAY' ) {
		@config_files = @{$config};
	} else {
		my $config_file = $config || 'config.yml';
		push @config_files, $config_file;
	}
	foreach my $config_file ( @config_files ) {
		$config_file = file('.', $config_file) unless file($config_file)->is_absolute;
		next unless -e $config_file;
		my $conf = LoadFile($config_file);
		%{$app->{'config'}} = %{ merge( $app->{'config'}, $conf ) };
	}
	return;
}

=head2 default_plugin

 Called by App::Cmd to set the default command when none is given this should automatically be 
 'help' with documented default_command method but doest work so must be a bug in App::Cmd..

=cut

sub default_plugin {
	return 'help';
}

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset
