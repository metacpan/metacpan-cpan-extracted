package DBIx::Changeset::App::Command::compare;

use warnings;
use strict;

use base qw/DBIx::Changeset::App::BaseCommand/;
use DBIx::Changeset::Collection;
use DBIx::Changeset::Exception;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::App::Command::compare - display a list of outstanding changesets

=head1 SYNOPSIS

=head1 METHODS

=head2 run

=cut
sub run {
	my ($self, $opt, $args) = @_;

	my $coll = DBIx::Changeset::Collection->new($opt->{'type'}, {
		changeset_location => $opt->{'location'},
	});
	
	eval { $coll->retrieve_all(); };
	my $e;
	if ( $e = Exception::Class->caught() ) {
		warn $e->error, "\n";
		warn $e->trace->as_string, "\n" if defined $opt->{'debug'};	
		exit;
	}

	$self->determine_outstanding($opt,$coll);



	return;
}

=head2 options

	define the options for the create command

=cut

sub options {
	my ($self, $app) = @_;
	return (
		[ 'location=s' => 'Path to changeset files', { default => $app->{'config'}->{'location'} || $app->{'config'}->{'update'}->{'location'} || undef, required => 1 } ],
		[ 'type=s' => 'Which factory to use (default disk)', { default => $app->{'config'}->{'type'} || $app->{'config'}->{'update'}->{'type'} || 'disk' } ],
		[ 'like=s' => 'only types matching regex', { default => $app->{'config'}->{'like'} || $app->{'config'}->{'update'}->{'like'} || undef } ],
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
	$self->usage_error('This command requires a valid changeset location') unless ( ( defined $opt->{'location'} ) && ( -d $opt->{'location'} ) );
	$self->usage_error('This command requires a history_db_dsn') unless ( defined $opt->{'history_db_dsn'} ); 
	return;
}

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset
