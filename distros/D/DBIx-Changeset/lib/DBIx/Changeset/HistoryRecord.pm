package DBIx::Changeset::HistoryRecord;

use warnings;
use strict;

use base qw/DBIx::Changeset/;
use DBI;
use Exception::Class::DBI;
use DateTime;
use DateTime::Format::ISO8601;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::HistoryRecord - Object to query a changeset record log entry

=head1 SYNOPSIS

Object to query a changeset record log entry

    use DBIx::Changeset::HistoryRecord;

    my $foo = DBIx::Changeset::HistoryRecord->new();
    ...
	$foo->find_all();

=head1 METHODS

=head2 new

=cut
sub new {
	my($proto, $fields) = @_;
	my($class) = ref $proto || $proto;

	DBIx::Changeset::Exception::ObjectCreateException->throw(error => 'Missing required db connection fields') unless defined $fields;
    
	my $self = bless {%$fields}, $class;

	return $self;
}

=head2 read

=cut
sub read {
	my ($self, $uid) = @_;

	## check for a uid
	DBIx::Changeset::Exception::ReadHistoryRecordException->throw(error => 'Need a uid to read') unless defined $uid;
	
	$self->_connect_to_db() unless defined $self->dbh();

	## right we got a uid so do a search
	my $q = $self->pb()->query('get_changeset_record', { id => $uid });

	my $hrecord = $q->fetchrow_hashref;

	DBIx::Changeset::Exception::ReadHistoryRecordException->throw(error => "No record found with uid of $uid") unless defined $hrecord;

	# set the accessors
	foreach my $key (qw(id filename md5 version skipped_b forced_b modify_ts create_ts)) {
		$self->$key($hrecord->{$key});
	}

	$q->finish();
	
	return;
}

=head2 write

=cut
sub write {
	my ($self, $record) = @_;

	DBIx::Changeset::Exception::WriteHistoryRecordException->throw(error => 'No DBIx::Changeset::Record object provided') unless defined $record;

	$self->_connect_to_db() unless defined $self->dbh();

	### does a record exist already
	my $q = $self->pb()->query('get_changeset_record', { id => $record->id });

	### work out filename
	my $filename = File::Spec->catfile($record->changeset_location, $record->uri);

	### md5
	my $md5 = $record->md5();
	### timestamp	
	my $dt = DateTime->now();
	my $ts = $dt->ymd . ' ' . $dt->hms;
	
	my $hrecord = $q->fetchrow_hashref;

	if ( defined($hrecord) ) {
		### update
		my $q_ = $self->pb()->query('update_changeset_record', { 
			filename => $filename,
			md5 => $md5,
			modify_ts => $ts,
			id => $hrecord->{'id'},
		});
		$q_->execute();
		$q_->finish();
	} else {
		### create
		my $q_ = $self->pb()->query('create_changeset_record', { 
			id	=> $record->id,
			filename => $filename,
			md5 => $md5,
			modify_ts => $ts,
			create_ts => $ts,
			version => 1,
		});

		$q_->execute();
		$q_->finish();
	}

	$q->finish();

	return;
}

=head1 ACCESSORS

=head2 id
	The id of this record (matches the DBIx::Changeset::Record uid)
args:
	string
returns:
	string

=head2 dbh
	The dbh connection to the historyrecord database
args:
	DBD::H
returns:
	DBD::H

=head2 filename
	The uri of the matching changeset record
args:
	string
returns:
	string

=head2 md5
	The md5 hash of the Record content when it was updated
args:
	string
returns:
	string

=head2 forced_b
	records wether this was a forced update 
args:
	bool
returns:
	bool

=head2 skipped_b
	records wether this update was skipped
args:
	bool
returns:
	bool

=head2 modify_ts
	records the timestamp of when this record was last modified
args:
	timestamp
returns:
	timestamp

=head2 modify_ts
	records the timestamp of when this record was created
args:
	timestamp
returns:
	timestamp
=head2 pb
	the data phrasebook used for loading the correct sql
args:
	phrasebook object
returns:
	phreasebook object

=cut

my @ACCESSORS = qw/dbh id filename md5 forced_b skipped_b version modify_ts create_ts pb/;
__PACKAGE__->mk_accessors(@ACCESSORS);

sub DESTROY {
	my $self = shift;

	if ( defined $self->dbh ) {
		$self->dbh->disconnect();
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
