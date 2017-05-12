package DBIx::Changeset::App::Command::update;

use warnings;
use strict;

use base qw/DBIx::Changeset::App::BaseCommand/;
use DBIx::Changeset::Collection;
use DBIx::Changeset::Loader;
use DBIx::Changeset::Exception;
use Term::Report;
use Term::Prompt;
use Data::Dumper;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::App::Command::update - display a list of outstanding changesets

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
	
	my $rep = Term::Report->new(
		startRow => 4,
		numFormat => 0,
		statusBar => [
			label => 'Changeset Checking:',
			subText => 'determining outstanding changesets',
			subTextAlign => 'center',
			showTime => 1,
		],
	);
			
	### deal with status bar
	$rep->{'statusBar'}->setItems($coll->total_outstanding);
	$rep->{'statusBar'}->start;
	
	$rep->savePoint('total', "Total changesets: ", 1);
	$rep->savePoint('applied', "\nApplied changesets: ", 1);
	$rep->savePoint('forced', "\nForced changesets: ", 1);

	my $total = 0;
	my $applied = 0;
	my $forced = 0;
	### create the loader object
	my $loader = DBIx::Changeset::Loader->new($opt->{'loader'}, { db_host => $opt->{'db_host'}, db_name => $opt->{'db_name'}, db_pass => $opt->{'db_password'}, db_user => $opt->{'db_user'} });
	$coll->reset;
	while ( my $record = $coll->next_outstanding ) {
		
		$rep->finePrint('applied',0,++$total);
		$rep->{'statusBar'}->subText($record->uri);
		eval { $loader->apply_changeset($record); };
		if ( $e = Exception::Class->caught('DBIx::Changeset::Exception::LoaderException') ) {
			$rep->clear();
			$rep->printLine("Details of Changeset with Problems:\n");
			$rep->printLine(sprintf("Id: %s\n", $record->id));
			$rep->printLine(sprintf("md5: %s\n", uc($record->md5)));
			$rep->printLine(sprintf("Changeset Location: %s%s\n\n", $record->changeset_location, $record->uri));
			if ( $opt->{'prompt'} ) {
				printf STDERR ("Could not apply Changeset %s because: %s\n\n", $record->uri, $e->error);
				my $result = &prompt("y", "Mark changeset as Applied ?", "(y/N)", "N");

				### reset report
				$rep->clear();
				$rep->{'statusBar'}->start;
				$rep->savePoint('total', "Total changesets: ", 1);
				$rep->savePoint('applied', "\nApplied changesets: ", 1);
				$rep->savePoint('forced', "\nForced changesets: ", 1);

				if ( $result == 1 ) {
					$record->forced(1);
					$rep->finePrint('forced',0,++$forced);
				} else {
					$rep->{'statusBar'}->update;
					next;
				}
			} else {
				$rep->finish();
				warn $e->error, "\n";
				warn $e->trace->as_string, "\n" if defined $opt->{'debug'};	
				exit;
			}
		} elsif ( $e = Exception::Class->caught() ) {
			$rep->clear();
			$rep->finish();
			warn $e->error, "\n";
			warn $e->trace->as_string, "\n" if defined $opt->{'debug'};	
			exit;
		} 
		
		$rep->finePrint('applied',0,++$applied);
		
		### update/create the history record
		my $hrec = DBIx::Changeset::HistoryRecord->new({
			history_db_dsn => $opt->{'history_db_dsn'},
			history_db_user => $opt->{'history_db_user'},
			history_db_password => $opt->{'history_db_password'},
		});

		eval { $hrec->write($record); };

		if ( $e = Exception::Class->caught() ) {
			$rep->clear();
			$rep->finish();
			warn $e->error, "\n";
			warn $e->trace->as_string, "\n" if defined $opt->{'debug'};	
			exit;
		}

		$rep->{'statusBar'}->update;

	}

	$rep->printBarReport(
		"\n\n\n\n Outstanding Changeset Summary:\n\n",
		{
			"   Total:	" => $coll->total_outstanding,
			"   Applied:	" => $applied,
			"   Forced:	" => $forced,
		}
	);


	$rep->finish();

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
		[ 'loader=s' => 'Which loader factory to use (default mysql)', { default => $app->{'config'}->{'loader'} || $app->{'config'}->{'update'}->{'loader'} || 'mysql' } ],
		[ 'like=s' => 'only types matching regex', { default => $app->{'config'}->{'like'} || $app->{'config'}->{'update'}->{'like'} || undef } ],
		[ 'history_db_dsn=s' => 'DBI DSN for the history db', { default => $app->{'config'}->{'history_db_dsn'} || $app->{'config'}->{'update'}->{'history_db_dsn'} || undef, required => 1 } ],
		[ 'history_db_user=s' => 'db user for history db', { default => $app->{'config'}->{'history_db_user'} || $app->{'config'}->{'update'}->{'history_db_user'} || undef } ],
		[ 'history_db_password=s' => 'db password for the history db user', { default => $app->{'config'}->{'history_db_password'} || $app->{'config'}->{'update'}->{'history_db_password'} || undef } ],
		[ 'db_name=s' => 'db name for update db', { default => $app->{'config'}->{'db_name'} || $app->{'config'}->{'update'}->{'db_name'} || undef } ],
		[ 'db_host=s' => 'db host for update db', { default => $app->{'config'}->{'db_host'} || $app->{'config'}->{'update'}->{'db_host'} || undef } ],
		[ 'db_user=s' => 'db user for update db', { default => $app->{'config'}->{'db_user'} || $app->{'config'}->{'update'}->{'db_user'} || undef } ],
		[ 'db_password=s' => 'db password for the update db user', { default => $app->{'config'}->{'db_password'} || $app->{'config'}->{'update'}->{'db_password'} || undef } ],


	);
}

=head2 validate

 define the options validation for the compare command

=cut

sub validate {
	my ($self,$opt,$args) = @_;
	$self->usage_error('This command requires a valid changeset location') unless ( ( defined $opt->{'location'} ) && ( -d $opt->{'location'} ) );
	$self->usage_error('This command requires a history_db_dsn') unless ( defined $opt->{'history_db_dsn'} ); 
	$self->usage_error('This command requires a db_name for the db to apply changesets too') unless ( defined $opt->{'db_name'} ); 
	return;
}

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset
