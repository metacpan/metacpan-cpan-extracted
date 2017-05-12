package DBIx::Changeset::App::BaseCommand;

use warnings;
use strict;

use base qw/App::Cmd::Command/;
use Digest::MD5;
use Encode;
use Term::Report;
use Term::Prompt;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::App::BaseCommand - Base module for the command line app commands

=head1 SYNOPSIS

Base module for the command line app commands

use as a base for an App::Cmd::Command:

use base qw/DBIx::Changeset::App::BaseCommand/;

=head1 METHODS

=head2 opt_spec

	Override opt_spec to provide the defaults from config:
	
	commands implement the options method to add there own options

=cut

sub opt_spec {
	my ( $class, $app ) = @_;
	my ( $name ) = $class->command_names;
	my @options = (
		[ 'help' => "This usage screen" ],
		[ 'prompt' => "Prompt where optional", { default => $app->{'config'}->{'prompt'} || $app->{'config'}->{$name}->{'prompt'} || 1 } ],
		[ 'debug' => "Show debug output", { default => $app->{'config'}->{'debug'} || $app->{'config'}->{$name}->{'debug'} || undef } ],
	);
	push @options, $class->options($app) if $class->can('options');
	return @options;
}

=head2 validate_args

=cut

sub validate_args {
	my ( $self, $opt, $args ) = @_;
	print $self->_usage_text and exit if $opt->{'help'};
	$self->validate( $opt, $args ) if $self->can('validate');
	return;
}

=head2 determine_outstanding

	Loop to determine the outstanding records in a collection put here as its used
	by both compare and update. also prompts to fix records

=cut
sub determine_outstanding {
	my ($self, $opt, $coll) = @_;

	my $rep = Term::Report->new(
		startRow => 4,
		numFormat => 1,
		statusBar => [
			label => 'Changeset Checking:',
			subText => 'determining outstanding changesets',
			subTextAlign => 'center',
			showTime => 1,
		],
	);

	### deal with status bar
	$rep->{'statusBar'}->setItems($coll->total);
	$rep->{'statusBar'}->start;

	$rep->savePoint('total', "Total changesets: ", 1);
	$rep->savePoint('outstanding', "\nOutstanding changesets: ", 1);
	$rep->savePoint('skipped', "\nSkipped changesets: ", 1);
	$rep->savePoint('fixed', "\nFixed changesets: ", 1);
	$rep->savePoint('invmd5', "\nChangesets with differing md5: ", 1);


	my $count = 0;
	my $outstanding = 0;
	my $skipped = 0;
	my $fixed = 0;
	my $invmd5 = 0;
	$rep->finePrint('fixed', 0, $fixed);
	$rep->finePrint('skipped', 0, $skipped);
	$rep->finePrint('invmd5', 0, $fixed);
	while ( my $record = $coll->next ) {
		$rep->{'statusBar'}->subText($record->uri);

		### check the record is valid
		unless ( $record->valid ) {
			if ( $opt->{'prompt'} ) {
				$rep->clear();
				my $value = &prompt('m', { 
					prompt => "choice:",
					title => sprintf("Record: %s is invalid should I:", $record->uri),
					items => [ qw(repair skip) ],
					cols => 1,
					accept_multiple_selections => 0,
					accept_empty_selection => 0,
				}, "", 1);
				$rep->clear();
				### redraw report screen
				$rep->{'statusBar'}->start;
				$rep->savePoint('total', "Total changesets: ", 1);
				$rep->savePoint('outstanding', "\nOutstanding changesets: ", 1);
				$rep->savePoint('skipped', "\nSkipped changesets: ", 1);
				$rep->savePoint('fixed', "\nFixed changesets: ", 1);

				if ( $value == 0 ) {
					$record->generate_uid();	
					$rep->finePrint('fixed', 0, ++$fixed);
					$rep->finePrint('skipped', 0, $skipped);
				} else {
					$rep->{'statusBar'}->update;
					$record->skipped(1);		
					$rep->finePrint('fixed', 0, $fixed);
					$rep->finePrint('skipped', 0, ++$skipped);
					next;
				}

			} else {
				$rep->subText('Skipping invalid record');
				$rep->{'statusBar'}->update;
				$record->skipped(1);		
				$rep->finePrint('skipped', 0, ++$skipped);
				next;
			}
		}

		$rep->finePrint('total', 0, ++$count);

		### does the record have a historyrecord
		my $hrec = DBIx::Changeset::HistoryRecord->new({
			history_db_dsn => $opt->{'history_db_dsn'},
			history_db_user => $opt->{'history_db_user'},
			history_db_password => $opt->{'history_db_password'},
		});
		eval { $hrec->read($record->id); };
		
		my $e;

		if ( $e = Exception::Class->caught('DBIx::Changeset::Exception::ReadHistoryRecordException') ) {
			### ok no history record so must be outstanding
			$rep->finePrint('outstanding', 0, ++$outstanding);
			$record->outstanding(1);
		} elsif ( $e = Exception::Class->caught() ) {
			$rep->clear();
			$rep->finish();
			warn $e->error, "\n";
			warn $e->trace->as_string, "\n" if defined $opt->{'debug'};	
			exit;
		} else {
			### existing record so is the MD5 the same
			my $md5 = $record->md5();
			if ( $md5 ne $hrec->md5 ) {

				### md5's dont match so outstanding
				$rep->finePrint('outstanding', 0, ++$outstanding);
				$record->outstanding(1);
				$rep->finePrint('invmd5', 0, ++$invmd5);
			
			}
		}
		
		$rep->{'statusBar'}->update;
	}

	$rep->printBarReport(
		"\n\n\n\n Outstanding Changeset Summary [" . $opt->{'history_db_dsn'} . "]\n\n",
		{
			"   Total:	" => $count,
			"   Outstanding:	" => $outstanding,
			"   Invalid md5:	" => $invmd5,
			"   Skipped:	" => $skipped,
			"   Fixed:	" => $fixed,
		}
	);

	$rep->finish();
	$coll->reset();
	my $out_count = 1;
	while ( my $record = $coll->next_outstanding ) {
		printf STDERR "%d.\t%s\t%s %s\n", $out_count, $record->uri, $record->id, $record->valid ? '' : '[ INVALID ]';
		$out_count++;
	}

	return;
}

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset
