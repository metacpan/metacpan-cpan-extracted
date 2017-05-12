package DBIx::Sequence;

use strict;
use vars qw($VERSION);
$VERSION = '1.5';

use DBI;
use Carp;

use constant COLUMN_PREFIX => '';
use constant DEFAULT_INIT_VALUE => 1;
use constant DEFAULT_ALLOW_ID_REUSE => 1;
use constant DEBUG_LEVEL => 0;
use constant DEFAULT_STATE_TABLE => 'dbix_sequence_state';
use constant DEFAULT_RELEASE_TABLE => 'dbix_sequence_release';

sub new
{
	my $class_name = shift;
	my $args = shift;

	my $self = {};
	$self = bless $self, $class_name;

	$self->{_dbh} = $args->{dbh} || $self->getDbh($args) || die 'Cannot get Database handle';

	$self->{state_table} = $args->{state_table};
	$self->{release_table} = $args->{release_table};
	$self->{_arg_reuse} = $args->{allow_id_reuse} if(exists $args->{allow_id_reuse});

	delete $self->{db_user};
	delete $self->{db_pw};
	delete $self->{db_dsn};

	$self->_InitQueries();


	return $self; 
}

sub getDbh
{
	my $self = shift;
	my $args = shift;

	return DBI->connect($args->{db_dsn}, $args->{db_user}, $args->{db_pw}, {
								RaiseError => 0,
								PrintError => 0,
								AutoCommit => 1,
								Warn => 0, }) || croak __PACKAGE__.": $DBI::errstr";
}


sub Next
{
	my $self = shift;
	my $dataset = shift;

	croak "No dataset specified" if not defined $dataset;

	print STDERR "Request of Next() id\n" if $self->DEBUG_LEVEL();

	my $current_sth = $self->{_current_sth};
	my $init_sth = $self->{_init_sth};

	if($self->_Create_Dataset($dataset))
	{
		return $self->DEFAULT_INIT_VALUE();
	}

	if($self->_AllowedReuse())
	{
		my $released_ids_sth = $self->{_released_ids_sth};

		$released_ids_sth->execute($dataset);

		while(my $released_id = $released_ids_sth->fetchrow())
		{
			if($self->_release_race_for($dataset, ( $released_id =~ m/^(\d+)$/ )[0] ))
			{
				print STDERR "Returning released id $released_id\n" if $self->DEBUG_LEVEL();
				$released_ids_sth->finish;
				return $released_id;
			}
		}
	}
				
	my $unique_id = $self->_race_for($dataset);
	if(!$unique_id)
	{
		croak __PACKAGE__." was unable to generate a unique id for ".$dataset."\n";
	}

	print STDERR "Returning new unique id $unique_id\n" if $self->DEBUG_LEVEL();
	return $unique_id;
}

sub Currval
{
	my $self = shift;
	my $dataset = shift;

	croak "No dataset specified" if !$dataset;

	my $current_sth = $self->{_current_sth};
	$current_sth->execute($dataset) || croak __PACKAGE__.": $DBI::errstr";
	my ($c_dataset, $current_id) = $current_sth->fetchrow(); $current_sth->finish;

	print STDERR "Returning CURRVAL $current_id for $c_dataset\n";
	return $current_id;
}	


sub Release
{
	my $self = shift;
	my $dataset = shift;
	my $release_id = shift;

	croak "No dataset specified" if !$dataset;
	croak __PACKAGE__." NO ID specified for Release()" if not defined $release_id;

	print STDERR "Asked to release id $release_id in dataset $dataset\n" if $self->DEBUG_LEVEL();


	if($self->_AllowedReuse())
	{	
		my $release_id_sth = $self->{_release_id_sth};
	
		if($release_id_sth->execute($dataset, $release_id) ne 'OEO')
		{
			print STDERR "Release successful.\n" if $self->DEBUG_LEVEL();
			return 1;
		}	
		return 0;
	}
	else
	{
		warn "Release() of ID not permitted by class ".__PACKAGE__; 
	}
}

	
sub Delete_Dataset
{
	my $self = shift;
	my $dataset = shift;

	croak "No dataset specified" if !$dataset;	


	my $delete_state_sth = $self->{_delete_state_sth};
	my $delete_release_sth = $self->{_delete_release_sth};

	print STDERR "Deleting dataset ".$dataset."\n" if $self->DEBUG_LEVEL();

	$delete_state_sth->execute($dataset) || croak __PACKAGE__.": $DBI::errstr";
	$delete_release_sth->execute($dataset) || croak __PACKAGE__.": $DBI::errstr";

	print STDERR "Deletion successul\n" if $self->DEBUG_LEVEL();

	return 1;
}

sub Bootstrap
{
	my $self = shift;
	my $dataset = shift;
	my $data_table = shift;
	my $data_field = shift;

	croak "No dataset specified" if !$dataset;
	croak "No data_table to Bootstrap()" if(!$data_table);
	croak "No data_field to Bootstrap()" if(!$data_field);


	print STDERR "Bootstrapping dataset ". $dataset." with $data_table and $data_field\n" if $self->DEBUG_LEVEL();

	my $bootstrap_query = "SELECT
					MAX($data_field)
				FROM
					".$data_table;
	
	print STDERR "\n\n", $bootstrap_query, "\n\n" if $self->DEBUG_LEVEL();

	my $bootstrap_sth = $self->{_dbh}->prepare($bootstrap_query) || croak __PACKAGE__.": $DBI::errstr";
	$bootstrap_sth->execute() || croak __PACKAGE__.": $DBI::errstr";

	my $bootstrap_id = $bootstrap_sth->fetchrow(); $bootstrap_sth->finish;

	croak "Bootstrap() failed" if(!$bootstrap_id);

	$self->_Create_Dataset($dataset);

	print STDERR "Bootstrap successfull.\n" if $self->DEBUG_LEVEL();

	my $next_id = $self->_race_for($dataset, $bootstrap_id + 1);

	print STDERR "Bootstrap next id is : $next_id\n" if $self->DEBUG_LEVEL();

	return $next_id;
}

sub _Create_Dataset
{
	my $self = shift;
	my $dataset = shift;

	croak "No dataset specified" if !$dataset;

	my $current_sth = $self->{_current_sth};
	my $init_sth = $self->{_init_sth};

        $current_sth->execute($dataset) || croak __PACKAGE__.": $DBI::errstr";
        my ($c_dataset, $current_id) = $current_sth->fetchrow(); $current_sth->finish;

        if(!$c_dataset)
        {
                $init_sth->execute($dataset,$self->DEFAULT_INIT_VALUE()) || croak __PACKAGE__.": $DBI::errstr";
                return $self->DEFAULT_INIT_VALUE();
        }
	else { return 0; }
}	

sub STATE_TABLE 
{
	my $self = shift;

	croak "Self not defined!" if not defined $self;

	return $self->{state_table} || $self->DEFAULT_STATE_TABLE();
}

sub RELEASE_TABLE
{
	my $self = shift;
	
	croak "Self not defined!" if not defined $self;
	
	return $self->{release_table} || $self->DEFAULT_RELEASE_TABLE();
}
	
sub _AllowedReuse
{
	my $self = shift;

	if(exists $self->{_arg_reuse})
	{
		return undef if($self->{_arg_reuse} =~ /no/i);
		return 1 if($self->{_arg_reuse});
		return undef;
	}
	else
	{
		return $self->DEFAULT_ALLOW_ID_REUSE();
	}
}
		
sub _race_for
{
	my $self = shift;
	my $dataset = shift;
	my $race_for_id = shift;

	croak "No dataset specified" if !$dataset;

	my $current_sth = $self->{_current_sth};
	my $race_sth = $self->{_race_sth};

	my $unique_id;
	my $got_id = 0;
	my $current_id;
	while($got_id == 0)
	{
		$current_sth->execute($dataset) || croak __PACKAGE__.": $DBI::errstr"; 
		$current_id = ($current_sth->fetchrow() =~ m/^(\d+)$/ )[0]; $current_sth->finish;

		if(!$race_for_id || $race_for_id <= $current_id)
		{ 
			$race_for_id = $current_id + 1; 
		}
			
		if ($race_sth->execute(($race_for_id), $dataset, $current_id) ne '0E0')
                {
			$unique_id = $race_for_id;
                        $got_id = 1;
                }
	}	

	return $unique_id;
}

sub _release_race_for
{
	my $self = shift;
	my $dataset = shift;
	my $release_id = shift;

	croak "No dataset specified" if !$dataset;
	croak "No ID specified for release race" if not defined $release_id;

	if($self->{_race_release_sth}->execute($dataset, $release_id) ne 'OEO')
	{
		return 1;
	}
	return 0;
}
		
sub _InitQueries
{
	my $self = shift;

	
	my $current_query = "SELECT
				".$self->COLUMN_PREFIX()."dataset,
				".$self->COLUMN_PREFIX()."state_id
				FROM
					".$self->STATE_TABLE()."
				WHERE
					".$self->COLUMN_PREFIX()."dataset = ?";

	print STDERR "\n\n", $current_query, "\n\n" if $self->DEBUG_LEVEL();

	$self->{_current_sth} = $self->{_dbh}->prepare_cached($current_query) || croak __PACKAGE__.": $DBI::errstr";

	my $init_query = "INSERT INTO
				".$self->STATE_TABLE()." (
								".$self->COLUMN_PREFIX()."dataset,
								".$self->COLUMN_PREFIX()."state_id
							) values (?,?)";

	print STDERR "\n\n", $init_query, "\n\n" if $self->DEBUG_LEVEL();

	$self->{_init_sth} = $self->{_dbh}->prepare_cached($init_query) || croak __PACKAGE__.": $DBI::errstr"; 

		
	my $race_query = "UPDATE
				".$self->STATE_TABLE()."
				SET
					".$self->COLUMN_PREFIX()."state_id  = ?
				WHERE
					".$self->COLUMN_PREFIX()."dataset = ?
				AND
					".$self->COLUMN_PREFIX()."state_id = ?";


	print STDERR "\n\n", $race_query, "\n\n" if $self->DEBUG_LEVEL();

	$self->{_race_sth} = $self->{_dbh}->prepare_cached($race_query) || croak __PACKAGE__.": $DBI::errstr"; 

			
	my $release_query = "DELETE FROM
					".$self->RELEASE_TABLE()."
				WHERE
					".$self->COLUMN_PREFIX()."dataset = ?
				AND	
					".$self->COLUMN_PREFIX()."released_id = ?";


	print STDERR "\n\n", $release_query, "\n\n" if $self->DEBUG_LEVEL();

	$self->{_race_release_sth} = $self->{_dbh}->prepare_cached($release_query) || croak __PACKAGE__.": $DBI::errstr";


	my $released_ids_query = "SELECT
					".$self->COLUMN_PREFIX()."released_id
				FROM
					".$self->RELEASE_TABLE()."
				WHERE
					".$self->COLUMN_PREFIX()."dataset = ?";

	print STDERR "\n\n", $released_ids_query, "\n\n" if $self->DEBUG_LEVEL();

	$self->{_released_ids_sth} = $self->{_dbh}->prepare_cached($released_ids_query) || croak __PACKAGE__.": $DBI::errstr";
			


	my $release_id_query = "INSERT INTO
					".$self->RELEASE_TABLE()."
					(
					".$self->COLUMN_PREFIX()."dataset,
					".$self->COLUMN_PREFIX()."released_id
					) values (?,?)";

	print STDERR "\n\n", $release_id_query, "\n\n" if $self->DEBUG_LEVEL();

	$self->{_release_id_sth} = $self->{_dbh}->prepare_cached($release_id_query) || croak __PACKAGE__.": $DBI::errstr";


	my $delete_state_query = "DELETE FROM 
						".$self->STATE_TABLE()."	
					WHERE
						dataset = ?";

	print STDERR "\n\n", $delete_state_query, "\n\n" if $self->DEBUG_LEVEL();

	$self->{_delete_state_sth} = $self->{_dbh}->prepare_cached($delete_state_query) || croak __PACKAGE__.": $DBI::errstr";


	my $delete_release_query = "DELETE FROM 
						".$self->RELEASE_TABLE()."
					WHERE
						dataset = ?";
	
	print STDERR "\n\n", $delete_release_query, "\n\n" if $self->DEBUG_LEVEL();

	$self->{_delete_release_sth} = $self->{_dbh}->prepare_cached($delete_release_query) || croak __PACKAGE__.": $DBI::errstr";

	
	return 1;	
}

42;


__END__

=head1 NAME

DBIx::Sequence - A simple SQL92 ID generator 

=head1 SYNOPSIS

  use DBIx::Sequence;

  my $sequence = new DBIx::Sequence({ dbh => $dbh });
  my $next_id = $sequence->Next('dataset');


=head1 DESCRIPTION

This module is intended to give easier portability to Perl database application by providing
a database independant unique ID generator. This way, an application developer is not
bound to use his database's SEQUENCE or auto_increment thus making his application 
portable on multiple database environnements.

This module implements a simple Spin Locker mechanism and is garanteed to return
a unique value every time it is called, even with concurrent processes. It uses
your database for its state storage with ANSI SQL92 compliant SQL. All SQL queries
inside DBIx::Sequence are pre cached and very efficient especially under mod_perl.

=head1 INSTALLATION

	perl Makefile.PL
	make
	make test
	make install

Note:

If you decide to run extended tests for the module, you will have to provide the
make test with a DSN (connect string) to your database (dbi:Driver:db;host=hostname)
and a valid username/password combination for a privileged user.

DBIx::Sequence uses 2 tables for its operation, namely the dbix_sequence_state and the
dbix_sequence_release tables. Those tables will be created if you run extended tests, if 
not you will need to create them yourself. 

	dbix_sequence_state:
	| dataset  | varchar(50) |      
	| state_id | int(11)     |    

	dbix_sequence_release:
	| dataset     | varchar(50) |     
	| released_id | int(11)     |     

Those table names are overloadable at your convenience, see the OVERLOADING section
for details.

=head1 BASIC USAGE

The basic usage of this module is to generate a unique ID to replace the use of your
database's SEQUENCE of auto_increment field. 

=head2 INIT

First, you need to create the sequence object:

	use DBIx::Sequence;
	my $sequence = new DBIx::Sequence({
						db_user => 'scott',
						db_pw => 'tiger',
						db_dsn => 'dbi:mysql:scottdb',
						allow_id_reuse => 1,
						});

DBIx::Sequence can be used to manage multiple sets of ID's (perhaps you could have one dataset 
per table, or one and only one dataset). This permits you to handle multiple applications with 
the same sequence class.  The dataset is normally simply a token string that represents your ID 
set. If the dataset does not exists, DBIx::Sequence will create automagically for you. No special 
steps are involved in the creation of a dataset.

The arguments contains the database informations, db_user, db_pw and db_dsn and are stored
in a hash reference.

At this point, the object has pre cached all of the SQL that will be used to generate
the spin locker race. It is normally a good idea to have a shared sequence object (especially)
under mod_perl to save the prepare overhead.  The 'allow_id_reuse' argument can be passed to 
the constructor to either allow the use of the Release() or deny it. (True value makes it allowed)

=head2 GETTING THE NEXT ID

To get the next id, you simpy have to use the Next() method of your sequence while specifying the
dataset you are getting the next id for.

	my $next_id = $sequence->Next($dataset);

=head2 RELEASING ID'S.

Generated ID's can be _explicitly_ released in your application.  When an ID is released, 
the sequence will be able to give this id back to you throught the Next() method.

This is how it is done:

	$sequence->Release($dataset, $id);

Note:

You must use release only when you are _CERTAIN_ that your ID is not used anymore and that
you want it to be recycled. The Spin Locking mechanism will also take place on released id's
to ensure that no two processes can get the same ID.

=head2 PERMANENTLY REMOVING A DATASET

To make DBIx::Sequence forget about an existing dataset, you need to use the Delete_Dataset()
method.

	$sequence->Delete_Dataset($dataset);

This will clear all state and existence for this dataset and will also clear it's
released id's. Note that if your application still uses this dataset, it will be
automatically recreated blank.


=head2 BOOTSTRAPPING A DATASET FROM EXISTING DATA

It is possible to sync the state of a DBIx::Sequence dataset by using the Bootstrap()
method. 

	$sequence->Bootstrap('my_dataset','my_bootstrap_table','my_primary_field');

Bootstrap() takes 3 arguments. 

=over 3

=item * The dataset to bootstrap

=item * The table from wich you will bootstrap

=item * The field in the bootstrap table that will be used to bootstrap the dataset.

=back

Bootstrap will then sync up the DBIx::Sequence's state with the maximum id of the 
'my_primary_field' in 'my_bootstrap_table'. The bootstrap field must be a numeric
field as you can suspect. The SQL function MAX() will be called on it during the 
bootstrap process.

Note: The bootstrap method _can_ be used at runtime since it will initiate a race
for updating the value thus following the same algorithm. It is recommended though
that you use Bootstrap() when no other concurrent processes are requesting id's.

=head2 OVERLOADING

It is possible to create an overloaded class of DBIx::Sequence. 
This permits you to create a DBIx::Sequence that has different properties than 
the orignal one. The only thing you really have to overload to modify the behaviour
of DBIx::Sequence are some constants:

=over 3

=item * STATE_TABLE : Defines the table used by DBIx::Sequence to store dataset's states.

=item * RELEASE_TABLE : Defines the table used by DBIx::Sequence to store released id's.

=item * COLUMN_PREFIX : A string to be prepended to every column in the internal SQL statements.

=item * DEFAULT_INIT_VALUE : Value used to initialize a dataset when it is first created.

=item * DEFAULT_ALLOW_ID_REUSE : When set to true, will allow the use of Release() if not specified in the constructor. (allow_id_reuse)

=item * DEBUG_LEVEL : When set to true, will enable debugging to STDERR.

=back

So it is very easy to specify the behaviour of DBIx::Sequence that you wish to use
by creating an overloaded class.

Also, a very important method to overload is the getDbh() method. This is the 
function that returns the database handle to the DBIx::Sequence. Your overloaded
class should redefine the getDbh method.

Overloading getDbh will make your sequence class integrate more cleanly with your application.

i.e.

	package MySequence;

	use DBI;
	use DBIx::Sequence;

	use vars qw(@ISA);
	@ISA = qw(DBIx::Sequence);

	use constant STATE_TABLE => 'my_state_table';
	use constant RELEASE_TABLE => 'my_release_table';
	use constant COLUMN_PREFIX => '';
	use constant DEFAULT_INIT_VALUE => '100';
	use constant DEFAULT_ALLOW_ID_REUSE => 1;
	use constant DEBUG_LEVEL => 0;

	sub getDbh
	{
		my $self = shift;

		return MyApplication::MyDBModule::getDbh();
	}

	1;

Then, your code can use this class for its sequencing. Notice that since we overloaded getDbh(), we don't
need to pass a second parameter to new().


	use MySequence;

	my $sequence = new MySequence();
	my $next_id = $sequence->Next($dataset);



=head1 SPECIAL NOTE ON DATABASE HANDLE OPTIONS

DBIx::Sequence requires that the dbh object you passe to it has the AutoCommit flag
set to 1. The main reason for this is that if AutoCommit is off, DBIx::Sequence will have
to do an implicit commit() call, wich in most cases is a bad idea, especially when the dbh
passed to the sequence object already has transactions prelogged in it. 


=head1 CVS AND BLEEDING VERSIONS

For the latest development information, CVS access and Changelog, please visit:

http://labs.turbulent.ca

If you use this module in a project, please let me know!

Your comments and rants are more than welcomed!

Commercial support for this module is available, please contact me for info!

=head1 TODO

=over 3

=item * Implement multiple locking mechanism (semaphore, spin, db locker)

=item * Implement pluggable locking module support

=back

=head1 AUTHOR

Benoit Beausejour, <bbeausej@pobox.com>

=head1 NOTES

This code was made possible by the help of individuals:

Philippe "Gozer" M. Chiasson <gozer@cpan.org>

Thanks to Uri Guttman for documentation checks ;)

=head1 CONTRIBUTORS

Here are the people who submitted patches and changes to the module, they have 
my thanks for their contributions:

Trevor Shellhorn <trevor.schellhorn-perl@marketingtips.com>

Dan Kubb <dkubb@cpan.org>

=head1 SEE ALSO

perl(1).

=head1 COPYRIGHT

Copyright (c) 2000 Benoit Beausejour <bbeausej@pobox.com>
All rights reserved. This program is free software, you can
redistribute it and/or modify it under the same terms as
Perl itself.

=cut
