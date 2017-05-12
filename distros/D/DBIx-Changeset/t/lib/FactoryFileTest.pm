package FactoryFileTest;

use base qw/DBIx::Changeset::Record/;

my $ID = '12312312312312312';

sub read {
	my ($self,$file) = @_;
	$self->id($ID);
	return sprintf('/* tag: %s */',$self->id());
}

sub write {
	my ($self,$data) = @_;
	$ID = $self->id;
	return $data;
}

1;
