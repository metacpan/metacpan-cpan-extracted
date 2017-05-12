package DBIx::Changeset::History;

use warnings;
use strict;

use base qw/DBIx::Changeset/;

use Exception::Class::DBI;
use DBIx::Changeset::HistoryRecord;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::History - Object to query the changeset record log

=head1 SYNOPSIS

Object to query the changeset record log

Perhaps a little code snippet.

    use DBIx::Changeset::History;

    my $foo = DBIx::Changeset::History->new($opts);
    ...
	$foo->retrieve_all();

=head1 ATTRIBUTES

=cut

my @ATTRS = qw/dbh records current_index pb/;

__PACKAGE__->mk_accessors(@ATTRS);


=head1 METHODS

=head2 new

=cut
sub new {
	my($proto, $fields) = @_;
	my($class) = ref $proto || $proto;

	DBIx::Changeset::Exception::ObjectCreateException->throw(error => 'Missing required db connection fields') unless defined $fields;
    
	my $self = bless {%$fields}, $class;

	$self->_connect_to_db;

	return $self;
}

=head2 init_history_table

	This method loads the sql for creation of the history table

=cut
sub init_history_table {
	my $self = shift;

	$self->_connect_to_db() unless defined $self->dbh();
	
	### get the table create query
	my $q = $self->pb->query('create_changeset_history');
	### execute it	
	$q->execute();

	$q->finish();
	
	return;
}

=head2 retrieve_all

	Get a list of the history records from the database.

=cut

sub retrieve_all {
	my $self = shift;

	$self->_connect_to_db() unless defined $self->dbh();

	my $q = $self->pb()->query('get_all_changeset_history');

	my @records;
       
	while(my $row = $q->fetchrow_hashref() ) {
		push @records, $row;
	}

	$q->finish();

	$self->records(\@records);

	return;
}

=head2 retrieve

=cut

sub retrieve {
	my ($self, $uid) = @_;

	return;
}

=head2 next

=cut
sub next {
	my $self = shift;
	if ( not defined $self->current_index ) {
		$self->current_index(0);
	} else {
		$self->current_index($self->current_index + 1);
	}
	my $db_entry = $self->records->[$self->current_index];

	my $hrec = DBIx::Changeset::HistoryRecord->new({
			history_db_dsn => $self->history_db_dsn, 
			history_db_user => $self->history_db_user, 
			history_db_password => $self->history_db_password,
			%{$db_entry},
	});

	return $hrec;
}

=head2 add_history_record

=cut
sub add_history_record {
	my ($self,$record) = @_;
	
	my $hrec = DBIx::Changeset::HistoryRecord->new({history_db_dsn => $self->history_db_dsn, history_db_user => $self->history_db_user, history_db_password => $self->history_db_password});

	$hrec->write($record);

	return $hrec;
}

=head2 total 

=cut
sub total {
	my $self = shift;

	return scalar(@{$self->records});
}

=head2 reset

=cut
sub reset {
	my $self = shift;

	$self->current_index(undef);
	return;
}

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
