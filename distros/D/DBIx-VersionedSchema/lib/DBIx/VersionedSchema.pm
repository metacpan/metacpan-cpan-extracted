=head1 NAME

DBIx::VersionedSchema - helps to manage database schema versions

=head1 SYNOPSIS
	
	package MyVersions;
	use base 'DBIx::VersionedSchema';

	# Set the name of the table
	__PACKAGE__->Name('my_schema_versions');

	# Add first version
	__PACKAGE__->add_version(sub {
		my $dbh = shift;
		$dbh->do(...);
	});

	# Add another one
	__PACKAGE__->add_version(...);

	package main;

	my $vs = MyVersions->new($dbh);

	# recreates / adds versions
	$vs->run_updates;

=head1 DESCRIPTION

This module helps to evolve database schema in small increments called
schema versions henceforth.

Each of those versions is perl function that you pass to add_version function.
Those versions are replayed by calling run_updates function.

DBIx::VersionedSchema keeps track of applied versions by using database table.
You should provide the name of this table by using Name property of your
inheriting class.

The tracking table will be created on the first call to run_updates function.

=head1 METHODS

=cut

use strict;
use warnings FATAL => 'all';

package DBIx::VersionedSchema;
use base qw(Class::Data::Inheritable);
our $VERSION     = 0.03;

__PACKAGE__->mk_classdata('Versions');

=head2 Name

This is per class method. It should be used to set the name of the tracking
table.

=cut

__PACKAGE__->mk_classdata('Name');

=head2 add_version(function)

Adds another schema version as perl function. This function will run during
run_updates call. Database handle will be provided to the
function as an argument.

=cut

sub add_version {
	my ($self, $func) = @_;
	my $versions = $self->Versions || [];
	push @$versions, $func;
	$self->Versions($versions);
}

=head2 new(dbh)

Creates new instance. $dbh is the database handle which will be passed
down to the schema changing functions.

=cut
sub new {
	my ($class, $dbh) = @_;
	my $self = bless { dbh => $dbh }, $class;
	return $self;
}

=head2 current_version

Returns current schema version. Returns C<undef> if no version tracking table
has been found. Returns 0 if the table exists but no updates have been run yet.

=cut
sub current_version {
	my $self = shift;
	my @res = $self->{dbh}->selectrow_array(q{ select *
			from information_schema.tables 
			where table_name = ? }, undef, $self->Name)
		or return undef;
	@res = $self->{dbh}->selectrow_array(sprintf(q{ select version 
				from %s
				order by version desc limit 1 }, $self->Name));
	return @res ? $res[0] : 0;
}

=head2 run_updates

Runs the updates starting from the current schema version.

=cut
sub run_updates {
	my $self = shift;
	my $dbh = $self->{dbh};
	$dbh->do(q{ set client_min_messages to warning });
	my $cur_version = $self->current_version;
	local $dbh->{AutoCommit};
	unless (defined($cur_version)) {
		$dbh->do(sprintf(q{ create table %s (
			version smallint primary key,
			release_date timestamp default current_timestamp
		) }, $self->Name));
		$cur_version = 0;
	}
	my $versions = $self->Versions || [];
	my $i = $cur_version;
	for (; $i < scalar(@$versions); $i++) {
		$versions->[$i]->($dbh);
	}
	$dbh->do(sprintf(q{ insert into %s (version)
			values (?) }, $self->Name), undef, scalar(@$versions))
		if $i > $cur_version;
}

1; 

=head1 AUTHOR

	Boris Sukholitko
	boriss@gmail.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Test::TempDatabase - for creation of temporary databases.

=cut


