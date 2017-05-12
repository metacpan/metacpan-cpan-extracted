package FactoryLoaderTest;

use base qw(DBIx::Changeset::Loader);

use strict;

sub apply_changeset {
	my ($self, $record) = @_;

	unless( $record ) { DBIx::Changeset::Exception::LoaderException->throw(error => 'Missing a DBIx::Changeset::Record'); }

}

1;
