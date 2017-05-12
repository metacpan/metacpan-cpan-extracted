package DBIx::Changeset::Loader::Pg;

use warnings;
use strict;
use File::Spec;

use base qw/DBIx::Changeset::Loader/;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::Loader::Pg - factory object for loading changesets into a PostgreSQL database

=head1 SYNOPSIS

Perhaps a little code snippet.

    use DBIx::Changeset::Loader;

    my $foo = DBIx::Changeset::Loader->new('Pg', $opts);
    ...
	$foo->apply_changeset($record);

=head1 METHODS

=head2 start_transaction 
	This is the start_transaction interface to implement in your own class
=cut
sub start_transaction {
}

=head2 commit_transaction 
	This is the commit_transaction interface to implement in your own class
=cut
sub commit_transaction {
}

=head2 rollback_transaction 
	This is the rollback_transaction interface to implement in your own class
=cut
sub rollback_transaction {
}

=head2 apply_changeset 
	This is the apply_changeset interface to implement in your own class
=cut
sub apply_changeset {
	my ($self, $record) = @_;

	unless ( defined $record ) { DBIx::Changeset::Exception::LoaderException->throw(error => 'Missing a DBIx::Changeset::Record'); }
	unless ( $record->valid() ) { DBIx::Changeset::Exception::LoaderException->throw(error => 'Passed an Invalid DBIx::Changeset::Record'); }
	unless ( defined $self->db_name ) { DBIx::Changeset::Exception::LoaderException->throw(error => 'need a db_name parameter'); }
	
	my $perms = "";
	$perms  = "-U".$self->db_user() if ($self->db_user);
	$perms .= " -h".$self->db_host() if ($self->db_host);

	## set the connection password if supplied in PGPASSWORD
	$ENV{'PGPASSWORD'} = $self->db_pass() if ($self->db_pass);

	my $DB = "";
	$DB = $self->db_name if ($self->db_name);

	my $sql = File::Spec->catfile($record->changeset_location, $record->uri);
	
	my $result = qx/psql $perms $DB < $sql 2>&1/;
	
	delete $ENV{'PGPASSWORD'} if ($self->db_pass);

	if ($? or ($result =~ m#ERROR#xmgs)) {
		DBIx::Changeset::Exception::LoaderException->throw(error => $result);
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
