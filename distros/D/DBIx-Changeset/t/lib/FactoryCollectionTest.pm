package FactoryCollectionTest;

use base qw(DBIx::Changeset::Collection);

use DBIx::Changeset::Record;
DBIx::Changeset::Record->add_factory_type( 'test' => FactoryFileTest );

my @FILES = qw(1.sql 2.sql 3.sql 4.sql);

sub retrieve_all {
	my $self = shift;

	my @records = ();
	foreach my $file ( @FILES ) {
		push @records, DBIx::Changeset::Record->new('test', { uri => $file } );
	}
	#### hack some flags to test
	# this would probably not be where these would be set
	$records[1]->outstanding(1);
	$records[2]->valid(1);
	$records[3]->skipped(1);
	$self->files(\@records);
	$self->current_index(undef);

	return;
}

sub retrieve_like {
	my ($self, $regex) = @_;

	my @found = grep { $regex } @FILES;
	my @records = ();
	foreach my $file ( @found ) {
		push @records, DBIx::Changeset::Record->new('test', { uri => $file } );
	}

	$self->files(\@records);
	$self->current_index(undef);

	return;
}

sub add_changeset {
	my ($self, $name) = @_;

	my $record = DBIx::Changeset::Record->new('test', { uri => $name });

	$record->generate_uid();
	
	push @{$self->files}, $record;

	return;
}

1;
