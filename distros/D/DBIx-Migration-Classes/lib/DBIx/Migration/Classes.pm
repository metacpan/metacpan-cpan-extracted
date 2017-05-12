package DBIx::Migration::Classes;

use 5.008009;
use strict;
use warnings;

use DBI;
use Module::Collect;
use Data::Dumper;

our $VERSION = '0.02';

################################################################################

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->_init(@args);
}

sub _test
{
	my ($self) = @_;
	my @tests = (
		# [<currentstate>,<targetstate>]
	
		# up
		['NONE', 'HEAD'],
		['MyTestChanges::CreateTableUser', 'HEAD'],
		['MyTestChanges::CreateTableUser', 'MyTestChanges::AddUserName'],
		['MyTestChanges::AddUserName', 'HEAD'],
		
		# down
		['HEAD', 'NONE'],
		['HEAD', 'MyTestChanges::CreateTableUser'],
		['MyTestChanges::AddUserName', 'MyTestChanges::CreateTableUser'],
		['HEAD', 'MyTestChanges::AddUserName'],
		
		# same
		['NONE','NONE'],
		['HEAD','HEAD'],
		['MyTestChanges::CreateTableUser','MyTestChanges::CreateTableUser'],
		['MyTestChanges::AddUserName','MyTestChanges::AddUserName'],
	);
	my $t = 0;
	foreach my $test (@tests) {
		_info("\n---( $t )---------------------------------------------\n");
		_info("--- $test->[0] .. $test->[1]\n\n");
		$self->migrate(undef, $test->[0], $test->[1]);
		$t++;
	}
}

sub migrate
{
	my ($self, $targetstate, $_state, $_targetstate) = @_;
	return 1 unless scalar @{$self->{'changeclasses'}};

	my $state = $self->state();
	
	# for testing purposes
	$state       = $_state       if defined $_state;
	$targetstate = $_targetstate if defined $_targetstate;

	# state = the name of the changeclass which changes were last APPLIED
	#         OR "NONE" if no changeclasses were applied
	#
	# targetstate = the name of the changeclass which is the last one to be APPLIED
	
	my $first_pos = $self->_get_position_of_changeclass($state);
	my $last_pos  = $self->_get_position_of_changeclass($targetstate);
	return 1 if $first_pos eq $last_pos;

	my $dir = ($first_pos <=> $last_pos); # up = -1, down = 1, same = 0

	$state       = $self->{'changeclasses'}->[$first_pos == -1 ? 0 : $first_pos]->[0];
	$targetstate = $self->{'changeclasses'}->[$last_pos ]->[0];

	_info("migrating database from state $state to $targetstate...\n");

	my @changes = (); # actual database changes perfored by the changeclasses
	if ($dir == 0) { # same
		_info("- doing changes from ".$self->{'changeclasses'}->[$first_pos]->[0]."\n");
		push @changes, $self->{'changeclasses'}->[$first_pos]->[1]->get_changes();
	}
	elsif ($dir == -1) { # up
		for (my $p = $first_pos + 1; $p <= $last_pos; $p++) {
			_info("- doing changes from ".$self->{'changeclasses'}->[$p]->[0]."\n");
			push @changes, $self->{'changeclasses'}->[$p]->[1]->get_changes();
		}
	}
	elsif ($dir == 1) { # down
		for (my $p = $first_pos; $p > $last_pos; $p--) {
			_info("- undoing changes from ".$self->{'changeclasses'}->[$p]->[0]."\n");
			push @changes, $self->{'changeclasses'}->[$p]->[1]->get_changes('undo');		
		}
		$targetstate = 'NONE' if $last_pos == -1;
	}
	
	if (defined $_state) {
		_info("database is now in state '".$self->state()."'\n");
		_info("not applying changes, because this is a test\n");
		return;
	}
	
	# actually perform all changes
	map { $self->_perform_change($_) } @changes;

	$self->_set_state($targetstate);
	_info("database is now in state '".$self->state()."'\n");
}

sub errstr
{
	my ($self) = @_;
	die "Error: error() method not yet implemented.\n";
}

sub state
{
	my ($self) = @_;
	my $sql = 'select version from `'.$self->{'db-meta-tablename'}.'` limit 1';
	my $sth = $self->_get_dbh()->prepare($sql);
	$sth->execute() or die("Error: Failed to read meta status: $! $@\n");
	my $meta = $sth->fetchrow_arrayref();
	unless ($meta) {
		# set state to 'NONE'
		$self->_query('insert into `meta` values ("NONE")')
			or die "Error: failed to set meta table version.\n";
	}
	return ($meta ? $meta->[0] : 'NONE');
}

sub changes
{
	my ($self) = @_;
	die "Error: changes() method not yet implemented.\n";
}

################################################################################

sub _init
{
	my ($self, %opts) = @_;
	
	$self->{'namespaces'} = $opts{'namespaces'} || die "Error: no namespace(s) supplied.\n";

	$self->{'changeclasses'} = {}; # <classname> => <instance>
	$self->_collect_changeclasses();
	
	$self->{'db-name'} 		= $opts{'dbname'} 		|| die "Error: no database name supplied.\n";
	$self->{'db-user'} 		= $opts{'dbuser'} 		|| 'root';
	$self->{'db-password'} = $opts{'dbpassword'} || '';
	$self->{'db-host'} 		= $opts{'dbhost'} 		|| 'localhost';
	$self->{'db-engine'} 	= $opts{'dbengine'} 	|| 'mysql';
	
	$self->{'db-meta-tablename'} = 'meta';
	
	$self->{'dbh'} = undef;
	$self->_init_database_metatable();
	
	return $self;
}

sub _set_state
{
	my ($self, $state) = @_;
	$self->_query('update `'.$self->{'db-meta-tablename'}.'` set version = "'.$state.'"')
		or die "Error: failed to update meta table.\n";
	return 1;
}

sub _perform_change
{
	my ($self, $change) = @_;
	my ($action, %opts) = @{$change};
	#print Dumper($change);

	if ($action eq 'create_table') {
		$self->_query('create table `'.$opts{'name'}.'` (`dummy` tinyint null)')
			or die "Error: failed to create table '$opts{'name'}': ".$self->_get_dbh()->errstr."\n";
	}
	elsif ($action eq 'drop_table') {
		$self->_query('drop table `'.$opts{'name'}.'`')
			or die "Error: failed to drop table '$opts{'name'}': ".$self->_get_dbh()->errstr."\n";	
	}
	elsif ($action eq 'alter_table_add_column') {
		$self->_query('alter table `'.$opts{'tablename'}.'` add column `'.$opts{'name'}.'` '.$opts{'type'})
			or die "Error: failed to add column '$opts{'name'}': ".$self->_get_dbh()->errstr."\n";			
	}
	elsif ($action eq 'alter_table_drop_column') {
		$self->_query('alter table `'.$opts{'tablename'}.'` drop column `'.$opts{'name'}.'`')
			or die "Error: failed to drop column '$opts{'name'}': ".$self->_get_dbh()->errstr."\n";					
	}
	else {
		die "Error: action '$action' (change type) not yet implemented/supported.\n";
	}
	return 1;
}

sub _query
{
	my ($self, $sql) = @_;
	my $sth = $self->_get_dbh()->prepare($sql);
	return $sth->execute();
}

sub _get_position_of_changeclass
{
	my ($self, $classname) = @_;
	return -1 if $classname eq 'NONE';
	return scalar @{$self->{'changeclasses'}} - 1 if $classname eq 'HEAD';
	foreach my $p (0.. scalar @{$self->{'changeclasses'}}) {
		return $p if $self->{'changeclasses'}->[$p]->[0] eq $classname;
	}
	die "Error: failed to find change class '$classname'.\n";
}

sub _collect_changeclasses
{
	my ($self) = @_;
	
	# find all classes
	my $classes = {};
	foreach my $path (@INC) {
		#print "$path:\n";
		foreach my $namespace (@{$self->{'namespaces'}}) {	
			#print "  $namespace:\n";
			my $c = Module::Collect->new(path => $path, prefix => $namespace, multiple => 0);
			for my $module (@{$c->modules}) {
				my $classname = $module->package;
				next if exists $classes->{$classname};
				$module->require;
				eval('$classes->{$classname} = '.$classname.'->new()');
				$classes->{$classname}->perform(); # register actual changes (no effect in db)
				die "Error: error while loading change class '$classname': $! $@\n" if $@;
			}
		}
  }

  # store classes in execute order
  $self->{'changeclasses'} = []; # [<classname>,<instance>], ...
  
  # find first one with after()=""
  foreach my $classname (keys %{$classes}) {
  	my $class = $classes->{$classname};
  	if ($class->after() eq '') {
  		$self->{'changeclasses'}->[0] = [ $classname, $class ];
  		delete $classes->{$classname};
  		last;
  	}
  }
  while (scalar keys %{$classes}) {
  	# find one coming after last one
  	my $found = 0;
		foreach my $classname (keys %{$classes}) {
			my $class = $classes->{$classname};
			if ($class->after() eq $self->{'changeclasses'}->[-1]->[0]) {
				push @{$self->{'changeclasses'}}, [ $classname, $class ];
				delete $classes->{$classname};
				$found = 1;
				last;
			}
		}
		die "Error: failed to find a successor change class for '".
			$self->{'changeclasses'}->[-1]->[0]."'.\n" 
				unless $found;
  }
	#print Dumper($self);
}

sub _get_dbh
{
	my ($self) = @_;
	if (!defined $self->{'dbh'} || !$self->{'dbh'}->ping()) {
		_info("(re)connecting to database...\n");
		$self->{'dbh'} = $self->_connect_db()
	}
	return $self->{'dbh'};
}

sub _connect_db
{
	my ($self) = @_;
	my $dbh =
		DBI->connect(
				"DBI:".$self->{'db-engine'}.":".$self->{'db-name'}.":".$self->{'db-host'},
				$self->{'db-user'}, $self->{'db-password'},
				{ PrintError => 0 },
			)
		or die("Error: Could not connect to database: $! $@\n");	
	
	die("Error: could not connect to database: $! $@\n")
		unless defined $dbh;
	return $dbh;
}

sub _init_database_metatable
{
	my ($self) = @_;
	# create db tables if nessessary
	my $sth = $self->_get_dbh()->table_info("", $self->{'db-name'}, $self->{'db-meta-tablename'}, "TABLE");
	unless ($sth->fetch()) {
		_info("creating metatable in database...\n");
		my $sql = 'create table `'.$self->{'db-meta-tablename'}.'` (`version` varchar(255))';
		$self->_query($sql) or die "Error: failed to create meta table: $! $@\n";
	}
}

sub _info
{
	my (@msg) = @_;
	print STDERR join('', @msg);
}

################################################################################
1;
__END__

=head1 NAME

DBIx::Migration::Classes - Class-based migration for relational databases.

=head1 SYNOPSIS

Migration program:

  use DBIx::Migration::Classes;
  my $migrator = DBIx::Migration::Classes->new(namespaces => ['MyApp::Changes'], dbname => 'myapp');
  $migrator->migrate('HEAD');

To create a new migration, just create a new class in one of the namespaces
that you tell the migrator to look in, e.g.:

I<libpath>/MyApp/Changes/MyChangeTwo.pm:

  package MyApp::Changes::MyChangeTwo;
  use base qw(DBIx::Migration::Classes::Change);

  sub after { "MyApp::Changes::MyChangeOne" }
  sub perform {
    my ($self) = @_;
    $self->add_column('new_column', 'varchar(42)', -null => 1, -primary_key => 1);
    $self->create_table('new_table');
    return 1;
  }
  1;

=head1 DESCRIPTION

When writing database powered applications it is often nessessary to
adapt the database structure, e.g. add a table, change a column type etc.

Suppose a developer works on a feature, creates a new database field,
and from then on the codebase relies on that column to exist. His/her
fellow programmers get his revised codebase, but they still have an
old database, which is lacking this very column.

This module makes it possible to encapsulate a bunch of (structural) changes to
a database into a "changeclass". These changeclasses are collected by
this module and applied to a database. The database can now be seen as
having an attached "version" and can be rolled back and forth to any desired state
(regarding the structure, but hopefully in the future the data as well).

=head2 Some definitions

B<Change>

A change is a simple transformation of a database, e.g. "add column x of type y"
or "drop table z".

B<Unchange>

An unchange (pardon the word) is the reverse transformation to a given change.
DBIx::Migration::Classes will automatically create an unchange for any given change,
so anything that can be changed in the database can be reversed.
Details on what kind of changes are possible, see below.

B<Changeclass>

A changeclass encapsulates a bunch of ordered changes under a globally
unique name. A changeclass contains also the name of the changeclass
that is coming directly before itself. Given a bunch of changeclasses,
it is easy to bring them into an order that represents the "history" (and "future")
of the database. Each changeclass is a subclass of DBIx::Migration::Classes::Change.

B<DBVersion (Database Version)>

A dbversion is the name of the last applied changeclass in a database.
This information is stored directly inside the database in a meta table.
A database can only have one dbversion at a given time.
The special dbversion "NONE" marks the point when no changeclasses have
been applied.

B<Migration>

A migration is the application of all the changes from an ordered list
of changeclasses to a database. A migration always starts at the current
dbversion of the database and ends at another given dbversion.

=head2 Features of DBIx::Migration::Classes

Having defined all the words in the previous section, we can now
easily define the features of this module. DBIx::Migration::Classes lets the
programmer...

=over 2

=item *

...define changeclasses with changes.

=item *

...migrate a database from dbversion A to dbversion B.

=item *

...do all this either from Perl or using a commandline utility
(useful in build scripts or post-update hooks in version control systems).

=back

=head2 new( %options )

This creates a new migrator instance. 
The following options are available:

=over 2

=item

=over 2

=item B<namespaces> => I<Arrayref of Perl namespaces> (mandatory)

The namespaces given via the
"namespaces"-option are used to find all changes that exists.
Each change is a subclass of DBIx::Migration::Classes::Change, see below.

=item B<dbname> => I<Database name> (mandatory)

=item B<dbuser> => I<Database username> (optional, defaults to "root")

=item B<dbpassword> => I<Database password> (optional, defaults to "")

=item B<dbhost> => I<Database host> (optional, defaults to "localhost")

=item B<dbengine> => I<Database engine> (optional, defaults to "mysql")

=back

=back

=head2 migrate( "I<changeclass classname>" )

This method migrates the database from its current state to the given
changeclass (including).

The special string "NONE" defines the state when NO changeclass is applied.
Roll back the database to its initial state:

  $migrator->migrate('NONE');

The special string "HEAD" defines the state when ALL available changeclasses
are applied. Migrate the database to the most current available state:

  $migrator->migrate('HEAD');

If anything goes wrong, the method will return 0, else 1.
In case of an error, the error message can be retrieved via errstr().

  $migrator->migrate('HEAD')
    or die "failed to migrate: ".$migrator->errstr()."\n";

=head2 errstr()

This method returns the error message of the last error occured,
or the empty string in case of no error.

  print "last error: ".$migrator->errstr()."\n";

=head2 state()

This method returns the name of the change that was executed last
on the given DBI database handle. The change name is the package name
of the DBIx::Migration::Classes::Change based change class.

  print "last applied changeclass in db: ".$migrator->state()."\n";

=head2 changes()

This method returns a list of changes that were executed 
on the given DBI database handle in the order they were executed.

  my @changes = $migrator->changes();
  print "applied changes: ".join(', ', @changes)."\n";

=head2 EXPORT

None by default.

=head1 SEE ALSO

None.

=head1 AUTHOR

Tom Kirchner, E<lt>tom@tomkirchner.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
