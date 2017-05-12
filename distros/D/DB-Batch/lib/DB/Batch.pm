package DB::Batch;
# Encapsulate DB::Batch components
use strict;
use warnings;

use DB::Batch::Main;
use DB::Batch::Fetch;
use DB::Batch::Do;

use base qw(DB::Batch::Main);

our $VERSION = '0.11';

# put together the pieces that make a DB::Batch object
sub new {
	my $class = shift;
	my $self  = bless DB::Batch::Main->new(@_), $class;

	$self->{fetcher}       = DB::Batch::Fetch->new();
	$self->{doer}          = DB::Batch::Do->new();
	$self->{autothrottler} = undef;
	$self->{loadbalancer}  = undef;

	return $self;
}

1;

=head1 NAME

	DB::Batch - Run database queries in batches through DBI

=head1 SYNOPSIS

	DB::Batch is a system for breaking up queries into batches behind the scenes, 
	while maintaining the appearance of running a single query.  
	Queries are run against an instance of DBI.  

	For example, a query like: 

	SELECT * FROM TABLE

	is expressed as:

	SELECT * FROM TABLE WHERE id BETWEEN # AND #

	and would be executed as:

	SELECT * FROM TABLE WHERE id BETWEEN 1 AND 100
	SELECT * FROM TABLE WHERE id BETWEEN 101 AND 200
	SELECT * FROM TABLE WHERE id BETWEEN 201 AND 300
	...

	Until the MAX(id) is reached.

	The script running this query, however, acts as if you are just 
	running 'SELECT * FROM TABLE'.

	The purpose of this is to diminish load on a sql database when large amounts of
	data need to be retrieved by managing batch size and throttling.  
	

=head1 USAGE

=over

=item Divide a query over a primary key.

In this example, we use a BETWEEN clause with two '#' placeholders.  
During execution the values in these placeholders are automatically incremented in chunks of 1000 (based on the batch size sent in)
The execution starts at the given start and end values, which can be defined as integers or sql statements

calling $batch->fetchrow_array, fetchrow_hashref, or fetchrow_array will return all rows from the table, 
however in the background it will be running separate queries for each batch

	use DB::Batch;
	use DBI;
	
	my $dbh   = DBI->connect(...);
	my $batch = DB::Batch->new(dbh => $dbh);
	
	my $sql = 'SELECT id,col FROM table WHERE id BETWEEN # AND #';
	my %db_args = (
		start => 1,
		end   => 'SELECT MAX(id) FROM table',
		batch => 1000,
		sleep => 1,
	);
	
	# this will retrieve all rows from table
	while (my ($id,$col) = $batch->fetchrow_array($sql,\%db_args) {
		print "$id,$col \n";
	}
		

=item Divide a query using limits and offsets

In this example, DB::Batch will automatically increment our values for LIMIT and OFFSET
behind the scenes until 1000 rows have been returned. 
(Note: this method is not optimal for very large data sets)


	use DB::Batch;
	use DBI;
	
	my $dbh   = DBI->connect(...);
	my $batch = DB::Batch->new(dbh => $dbh);

	my $sql = 'SELECT id,col FROM table WHERE id LIMIT # OFFSET #';

	# you can also use the form: 	  
	# my $sql = 'SELECT id,col FROM table WHERE id LIMIT #,#';

	my %db_args = (
		start => 1,
		limit => 1000, 
		batch => 100,
		sleep => 1,
	);

	# this will retrieve all rows from table
	while (my ($id,$col) = $batch->fetchrow_array($sql,\%db_args) {
		print "$id,$col \n";
	}
		



=item Selecting with a list of arguments.

In this example we provide a list of arguments and tell DB::Batch to bind 10 values at a time.
The '#' will be expanded to the number of placeholders specified by makebinds, or up to as many placeholders 
that are needed to bind all the values of the given list.  

	use DB::Batch;
	use DBI;
	
	my $dbh   = DBI->connect(...);
	my $batch = DB::Batch->new(dbh => $dbh);

	my $sql = 'SELECT id,col FROM table WHERE id IN (#)';


	my %db_args = (
		list      => [qw(1..105)],
		makebinds => 10,
	);

	# this will retrieve all rows from table
	while (my ($id,$col) = $batch->fetchrow_array($sql,\%db_args) {
		print "$id,$col \n";
	}


=item Inserting.

Inserting can be done in batches using do_batch.  
In this example, 10 values from the given list will be binded and executed at a time behind the scenes.  

	use DB::Batch;
	use DBI;
	
	my $dbh   = DBI->connect(...);
	my $batch = DB::Batch->new(dbh => $dbh);

	my $sql   = "UPDATE foo SET col='abc' WHERE id IN (#)";

	my %db_args = (
		list      => [qw(1..105)],
		makebinds => 10,
	);

	# this will retrieve all rows from table
	$batch->do_batch($sql,\%db_args);



=item Inserting II

inserting multiple rows at once can be done by specifying the number of groups and number of placeholders 
with makebinds

	use DB::Batch;
	use DBI;
	
	my $dbh   = DBI->connect(...);
	my $batch = DB::Batch->new(dbh => $dbh);

	my $sql = 'INSERT INTO foo (col1,col2) VALUES #';

	my %db_args = (
		list      => [qw(1 col2value2 2 col2value2 3 col2value3)],
		makebinds => 2, #
		groups    => 3, # make 3 groups of 2 placeholders
	);

	# this will retrieve all rows from table
	$batch->do_batch($sql,\%db_args);


=item Inserting III

If the flow of control of your script requires you to iterate over a large amount of data, 
use buffer_batch to buffer a number of rows of data and then execute it all at once in the end


	use DB::Batch;
	use DBI;
	
	my $dbh   = DBI->connect(...);
	my $batch = DB::Batch->new(dbh => $dbh);

	my $sql = 'INSERT INTO foo (col1,col2) VALUES #';

	my @data = (1..10000);

	my %db_args = (
		makebinds => 2, #
		groups    => 3, # make 3 groups of 2 placeholders
	);

	for my $col1 (@data) {
		my $col2 = $col1;
		$batch->buffer_batch($sql,$col1,$col2);
	}	  

	$batch->exec_buffer($sql,\%db_args);


Hooks


	use DB::Batch;
	use DBI;
	
	my $dbh   = DBI->connect(...);
	my $batch = DB::Batch->new(dbh => $dbh);

	my $sql    = 'SELECT id,col FROM table WHERE id BETWEEN # AND #';
	my $insert = 'INSERT INTO foo (col1,col2) VALUES #';


	my %db_args = (
		start => 1,
		end   => 'SELECT MAX(id) FROM table',
		batch => 1000,
		sleep => 1,
		pre_hook => sub {
			# this is executed before the query is run through $dbh->prepare
			print Dumper [ $batch->get_last_batch() ]; # returns values about to be bound
		},
		post_hook => sub {
			# This will run the INSERT after each batch of the SELECT query is finished,
			# this way the entire table worth of data doesn't need to be kept in memory 
			# and written all at once
			$batch->exec_buffer($insert,{makebinds => 2, groups => 10});
		}
	);


	# this will retrieve all rows from table
	while (my ($id,$col) = $batch->fetchrow_array($sql,\%db_args) {

		# returns true if a new batch was started behind the scenes
		if ($batch->is_new_batch()) {
			print Dumper [ $batch->get_last_batch() ]; # returns current values being bound
		}

		# you can buffer results from one query to insert in batches to another table
		$batch->buffer_batch($insert,$id,$col);
	}





=back

=head1 PUBLIC METHODS

=over

=item new (dbh => DBI::db)

=item fetchrow_array ($SQL_STRING, {ARGS})

=item fetchrow_arrayref ($SQL_STRING, {ARGS})

=item fetchrow_hashref ($SQL_STRING, {ARGS})

	-- start at id 0, and run the query in increments of 100 up to 1000.  
	SQL_STRING: 'SELECT foo FROM table WHERE id BETWEEN # AND #'
	ARGS: {
		start => 0
		end   => 1000,
		batch => 100
		sleep => 100000  # number of microseconds to wait between queries
		pre_hook => sub {
			# do something prior to current sth being prepared
		},
		post_hook => sub {
			# do something after current sth is finished
		}
	}
     
	-- determine start and end values at runtime based on the results of the given queries
	ARGS: {
		start => 'SELECT MIN(id) FROM table'
		end   => 'SELECT MAX(id) FROM table',
		batch => 100
	}
     
     
	-- expand the placeholder into 10 placeholders and bind the values of 'list' 10 at a time
	SQL_STRING: 'SELECT foo FROM table WHERE id IN (#)'
	ARGS: {
		makebinds => 10,
		list      => [qw(2 4 6 8 10 12 14 16 18 20)],
	}


=item buffer_batch ($SQL_STRING,@LIST)
	
	buffer the values in @LIST to be bound and run when exec_buffer is called on the same SQL_STRING

=item exec_buffer($SQL_STRING,\%ARGS)

	run do_batch after having buffered a list of bind values using buffer_batch();

     -- args are identical to do_batch, except 'list' was build internally when buffer_batch was called
	SQL_STRING: 'INSERT INTO table VALUES #'
	ARGS: {
		makebinds => 10,
	}

=item buffer_batch_triggered ($SQL_STRING,\%ARGS,@LIST)
	
	buffer the values in @LIST to be bound and run when exec_buffer is called on the same SQL_STRING
	when the number of rows of data matches $ARGS->{trigger}, the insert is executed automatically

=item do_batch

	execute write queries in batches

	SQL_STRING: 'INSERT INTO table VALUES #'
	ARGS: {
		makebinds => 3,
		groups    => 2
	}

=item get_dbh

	return the primary db handle being used

=item get_last_batch

	return a list of the last batch values bound to the current query

=item get_last_query

	return a string with the full query that was last executed.

=item get_sth

	call this from inside a while($batch->fetch...) { } loop.  Return the statement handle currently being processed

=item is_new_batch

	call this from inside a while($batch->fetch...) { } loop.  Returns 1 if a new query batch was executed.


=back

=head1 COPYRIGHT & LICENSE

Copyright 2010, Chris Becker C<< <clbecker@gmail.com> >>

Original work sponsered by Shutterstock, LLC. 
L<http://shutterstock.com>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
