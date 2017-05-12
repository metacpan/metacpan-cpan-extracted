package DBIx::Changeset;

use warnings;
use strict;

use Data::Phrasebook;
use File::ShareDir qw(dist_file);
use File::Spec;


use base qw/Class::Accessor DBIx::Changeset::Exception/;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset - Discrete management for database changes.

=cut

use 5.008000;

my @ACCESSORS = qw/changeset_location create_template history_db_user history_db_password history_db_dsn/;

__PACKAGE__->mk_accessors(@ACCESSORS);

=head1 SYNOPSIS

You probably want to use dbix_changeset.pl from the command line.
	
	dbix_changeset.pl --help


=head1 DESCRIPTION
	
DBIx::Changeset provides an application to aid with the distrubution and application of database
schemas and schema data as incremental updates. A Changeset is a discrete chunk of sql stored
in a file with a unique id. DBIx::Changeset will compare a list of changesets against a table of 
applied changesets and apply the differences using the target databases native sql insertion tool 
in order. This greatly aids the distrubted development of a database application.

=head2 Example

	User A creates a schema change in his development environment and applies it. Alls good so he checks
	in the changeset file. User B does a checkout on his development environment and runs the changeset 
	update which notices User A's changeset and applies it. User B's development database is now the same
	as User A's. The database schema/schema data is in sync with the code logic.

DBIx::Changeset does not include an undo feature as it is dealing with schema changes this could cause
data loss so is actually an update.

DBIx::Changeset uses a table to store the history of which changesets have been applied, while this 
is normally in the target database in can be set to another location.

DBIx::Changeset Currently supports MySQL,Postgres and SQLlite, but should be easy to port to other
databases.

=head1 USAGE

=head2 Setting up a Database for Changeset

DBIx::Changeset requires a table to store the history of applied changesets. Changeset will
add this table for you with the bootstrap command. It requires several options:

	--history_db_dsn           DBI DSN for the history db
	--history_db_user          db user for history db
	--history_db_password      db password for the history db user


=head2 Creating a Changeset

To create a new empty changeset file from the given template use the create command.
It has several required options:
	
	--location      Path to changeset files
	--template      Path to changeset template

The location is the path were the changeset files are stored and the template is a the path to a file
that is used as the template. There are a couple of optional parameters:

	--edit          Call editor
	--editor        Path to Editor

This loads the created delta up in the choses editor.

	--vcs           Add to version control
	--vcsadd        Command to add to version control
	
These add the created delta file to your vcs using the command given by the vcsadd option.


=head2 Comparing a database
	
To compare a database to a set of changeset files, you use the compare command.
It has a few required options:
		
		--location                 Path to changeset files
		--history_db_dsn           DBI DSN for the history db
		--history_db_user          db user for history ddb
		--history_db_password      db password for the history db user

	There are also a couple of other useful options:

		--type		               Which factory to use (default disk)
		--like                     only types matching regex

=head2 Updating a database
To update a database based on changeset files use the update command. The update command
has several required options:

	--location                 Path to changeset files
	--type                     Which factory to use (default disk)
	--loader                   Which loader factory to use (default mysql)
	--like                     only types matching regex
	--history_db_dsn           DBI DSN for the history db
	--history_db_user          db user for history db
	--history_db_password      db password for the history db user
	--db_name                  db name for update db
	--db_host                  db host for update db
	--db_user                  db user for update db
	--db_password              db password for the update db user

=head3

=head1 ACCESSORS

=head2 db_user
	the db_user

=head2 db_password
	the db_password

=head2 db_uri
	the db_uri

=head2 changeset_location
	the location of the changeset files, in a format the DBIx::Changeset::File factory object will be expecting

=cut

sub _connect_to_db {
	my $self = shift;

	my $dbh = DBI->connect($self->history_db_dsn, $self->history_db_user, $self->history_db_password, {
		PrintError  => 0,
		RaiseError  => 0,
		HandleError => Exception::Class::DBI->handler,
	});

	if ( defined $dbh ) {
		$self->dbh($dbh);
		### setup our sql lib object with normal and if exists specific to this db type
		
		## query the DB type from the DBD handle - info key 17
		my $dbtype = $self->dbh->get_info( 17 );
		eval { 
			$self->pb(Data::Phrasebook->new(  
				class => 'SQL',
				dbh => $self->dbh, 
				loader => 'YAML',
				file => dist_file('DBIx-Changeset', 'changeset_history.yml'),
				dict   => $dbtype) ); 
		};
		if ( $@ ) {
			DBIx::Changeset::Exception::ObjectCreateException->throw(error => sprintf('Could not load SQL phrasebook because: %s.', $@));
		}
	} else {
		DBIx::Changeset::Exception::ObjectCreateException->throw(error => 'Could not connect to db.');
	}

	return;
}

=head1 SUPPORT

Please report any bugs or feature requests via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Queue=DBIx-Changeset>

=head1 AUTHORS

Mike Bissett, Stephen Steneker, Paul Puse
C<< <paran01d@gmail.com> >>

=head1 ACKNOWLEDGEMENTS

Thank you to Grox (L<http://grox.com.au/>) for permitting
the open sourcing and release of this distribution.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset
