package DBIx::Changeset::App::Command::bootstrap;

use warnings;
use strict;

use base qw/DBIx::Changeset::App::BaseCommand/;
use DBIx::Changeset::History;
use DBIx::Changeset::Exception;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::App::Command::bootstrap - set up the changeset history record db

=head1 SYNOPSIS

=head1 METHODS

=head2 execute

=cut
sub execute {
	my ($self, $opt, $args) = @_;
	my $hrec = DBIx::Changeset::History->new({
			history_db_dsn => $opt->{'history_db_dsn'},
			history_db_user => $opt->{'history_db_user'},
			history_db_password => $opt->{'history_db_password'},
	});

	eval { $hrec->init_history_table(); };

	my $e;
	if ( $e = Exception::Class->caught() ) {
		warn $e->error, "\n";
		warn $e->trace->as_string, "\n" if defined $opt->{'debug'};	
		exit;
	}

	print "Bootstrap complete.\n";

	return;
}

=head2 options

	define the options for the create command

=cut

sub options {
	my ($self, $app) = @_;
	return (
		[ 'history_db_dsn=s' => 'DBI DSN for the history db', { default => $app->{'config'}->{'history_db_dsn'} || $app->{'config'}->{'bootstrap'}->{'history_db_dsn'} || undef, required => 1 } ],
		[ 'history_db_user=s' => 'db user for history db', { default => $app->{'config'}->{'history_db_user'} || $app->{'config'}->{'bootstrap'}->{'history_db_user'} || undef } ],
		[ 'history_db_password=s' => 'db password for the history db user', { default => $app->{'config'}->{'history_db_password'} || $app->{'config'}->{'update'}->{'history_db_password'} || undef } ],
	);
}

=head2 validate

 define the options validation for the compare command

=cut

sub validate {
	my ($self,$opt,$args) = @_;
	$self->usage_error('This command requires a history_db_dsn') unless (defined $opt->{'history_db_dsn'});
	return;
}

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset
