package DBIx::Changeset::Loader;

use warnings;
use strict;

use base qw/Class::Factory DBIx::Changeset/;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::Collection - Factory Interface to objects to load changesets into the database

=head1 SYNOPSIS

Factory Interface to objects to load changesets into the database

Perhaps a little code snippet.

    use DBIx::Changeset::Loader;

    my $foo = DBIx::Changeset::Loader->new('type', $opts);
    ...
	 $foo->apply_changeset();

=head1 INTERFACE

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
}

=head1 TYPES
 Default types included

=head2 mysql
	use mysql to load changeset records into the db
=cut
__PACKAGE__->register_factory_type( mysql => 'DBIx::Changeset::Loader::Mysql' );

=head2 pg
	use psql to load changeset records into the db
=cut
__PACKAGE__->register_factory_type( pg => 'DBIx::Changeset::Loader::Pg' );


=head1 ACCESSORS

=head2 db_pass
	database password
args:
	string
returns:
	string

=head2 db_name
	the database name
args: 
	string
returns:
	string

=head2 db_user
	the database user
args: 
	string
returns:
	string

=head2 db_host
	the database host
args: 
	string
returns:
	string

=cut

my @ACCESSORS = qw/db_pass db_name db_user db_host/;
__PACKAGE__->mk_accessors(@ACCESSORS);

=head2 init
 Called automatically to intialise the factory objects takes params passed to new and assigns them to
 accessors if they exist
=cut

sub init {
	my ( $self, $params ) = @_;

	foreach my $field ( keys %{$params} ) {
		$self->{ $field } = $params->{ $field } if ( $self->can($field) );
	}
	return $self;
}

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset
