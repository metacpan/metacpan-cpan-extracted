package DB::Batch::Main;
# Manage overall flow of control of DB::Batch
#
# Copyright 2010, Chris Becker <clbecker@gmail.com>
#
# Original work sponsered by Shutterstock, LLC. http://shutterstock.com
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use DB::Batch::Query;
use DB::Batch::BindValues;
use DB::Batch::Fetch;
use DB::Batch::Do;

# args:
# dbh => provide your own DB instance
sub new {
	my $class = shift;
	my %args  = @_;    

	die 'You need to provide a database handle' unless $args{dbh};

	my $self = bless \%args, $class;

	# set modules to process fetching, executing, and writing data
	# other variants of these will allow separate scripts to split batches and run in parallel
	$self->{fetcher}       ||= DB::Batch::Fetch->new();
	$self->{doer}          ||= DB::Batch::Do->new();

	# TODO: encapsulate autothrottling to DB::Batch::Autothrottler
	# if set this will allow throttling to be determined automatically based on replication times and server load and such
	$self->{autothrottler} ||= undef;

	# TODO: write DB::Batch::LoadBalancer plugin
	# - provide a list of db handles to it
	# - it'll return the right one to use
	$self->{loadbalancer}  ||= undef; # DB::Batch::LoadBalancer->new($self->{dbh});
	return $self;
}


# send a custom subroutine in to process the sth manually
sub fetchbatch_custom {
	my $self = shift;
	die 'batch subroutine not defined' unless (defined $_[1]{sub});
	return $self->_fetch(@_);
}

# acts like DBI::sth counterparts
sub fetchrow_hashref {
	my $self = shift;
	return $self->_fetch(@_);
}

sub fetchrow_arrayref {
	my $self = shift;
	return $self->_fetch(@_);
}

sub fetchrow_array {
	my $self = shift;
	return $self->_fetch(@_);
}


##
# $query: sql select statement
# $opts: hash of options (see options section in pod below)
# @_: arguments passed to execute()
sub _fetch {
	my $self = shift;
	my $query = shift;
	my $opts = $self->vivifyopts(shift);

	die 'query not defined' unless ($query);

	my $caller    = (caller(1))[3]; # get the calling subroutine (e.g. .._hashref, .._arrayref, .._array)
	my $dbh       = $self->{dbh};
	my $query_obj = $self->get_query_object($query,$opts);
	my $bind_obj  = $self->get_bindvalue_object($query_obj,$opts);
	my $key       = $query_obj->get_key();  # get hash key of query w/ placeholders

	$self->{sth}{$key} = undef if ($caller =~ m/fetchbatch_custom$/); # sth is dealt with in custom sub for fetchbatch_custom()

	# run query with incremented values.  If nothing is returned, then return undef or () to finish
	unless ($self->_execute_batch_read(
		query      => $query_obj, 
		opts       => $opts, 
		bindvalues => $bind_obj, 
		dbi_bind   => [@_])) {
		return wantarray ? () : undef 
	}

	# process the sth behind the scenes
	return $self->_process_sth(
		query    => $query_obj, 
		opts     => $opts, 
		dbi_bind => [@_],
		caller   => $caller,
	);
}


# execute query with current range of data
sub _execute_batch_read {
 	my $self = shift;
	$self->{fetcher}->execute_batch_read(parent => $self, @_);
}


# process the executed sth
sub _process_sth {
	my $self = shift;
	$self->{fetcher}->process_sth(parent => $self, @_);
}


##
# $query: sql statement (e.g. insert/update)
# $opts: hash of options (see options section in pod below)
# @_: arguments passed to execute()
sub do_batch {
	my $self      = shift;
 	my $query_str = shift;
 	my $opts      = $self->vivifyopts(shift);

	$self->{doer}->do_batch(parent => $self, query => $query_str, opts => $opts, dbi_binds => [@_]);
}

#
# add list of bind variables to a buffer for later execution in batches
sub buffer_batch {
	my $self  = shift;
	my $query = shift;
	die 'query not defined' unless ($query);
	my $key   = md5_hex($query);
	push @{$self->{buffer}{$key}}, @_;
}

# execute query with buffered list of bind variables
sub exec_buffer {
	my $self  = shift;
	my $query = shift;
	my $opts  = shift;

	die 'query not defined' unless ($query);
	my $key   = md5_hex($query);
	return unless ($self->{buffer}{$key} && @{$self->{buffer}{$key}});

	$opts->{list} = $self->{buffer}{$key};
	$self->do_batch($query,$opts,@_);
	undef @{$self->{buffer}{$key}};
}

# determine throttling dynamically based on server stats
sub auto_throttle {
	my $self = shift;
	return unless $self->{autothrottler};
	$self->{autothrottler}->throttle();
}

# sleep for some amount of microseconds
sub throttle {
	my $self = shift;
	my $opts = shift;
	sleep($self->{autothrottle_sleep} || $opts->{sleep});
}

# initialize all possible options.  
sub vivifyopts {
	my $self = shift;
	my $opts = shift;

	# if a string is given for any field expecting an integer, 
	# presume its a query and store its result;
	for my $field qw(limit start end batch sleep) {

		if (defined $opts->{$field} && $opts->{$field} =~ m/\D+/) {

			my ($result) = $self->{dbh}->selectrow_array($opts->{$field});
			$opts->{$field} = $result || 0;
			$opts->{$field} += 1 if $field eq 'end'; # adjust for exclusiveness for end id
		}
	}
	
	$opts->{log}       ||= undef;  # Log::Log4Perl object
	$opts->{list}      ||= undef;  # array of values to bind in batches
	$opts->{quote}     ||= undef;  # custom quote function (else use dbh->quote)
	$opts->{verbose}   ||= 0;     
	$opts->{batch}     ||= 0;      # range of values to retrieve in one query
	$opts->{makebinds} ||= 0;
	$opts->{groups}    ||= 0;
	$opts->{limit}     ||= 0;      # number of values to return before finishing
	$opts->{start}     ||= 0;      # min value to start at
	$opts->{sleep}     ||= 0;      # time (microseconds) to wait between executing
	$opts->{end}       ||= $opts->{start} + $opts->{limit}; # final value to return before exiting
	$opts->{output}    ||= undef;  # file/output handle to redirect updates
	$opts->{sub_args}  ||= undef;  # args sent to the sub called by fetchbatch_custom
	$opts->{sub}       ||= undef;  # sub called by fetchbatch_custom
	return $opts;
}


# call this in a while ...$this->fetchrow_* loop to get whether or not we just started the next query in the batch
sub is_new_batch {
	my $self = shift;
	return $self->{__new_batch__} || 0;
}

# return a list of the current batch of bound values
sub get_last_batch {
	my $self = shift;
	return ($self->{__bindvalues__}{ $self->{__last_query_key__} }->get_last_batch());
}

# return a list of the current batch of bound values
sub get_sth {
	my $self = shift;
	return ($self->{sth}{ $self->{__last_query_key__} }->get_last_batch());
}


# return the last executed query with batched bind variables bound
sub get_last_query {
	my $self = shift;
	return $self->{__last_query__};
}

# create a Batch::Query object of the given query if one has not been created yet, otherwise return one stored in cache
sub get_query_object {
	my $self = shift;
	my $query = shift;
	my $opts = shift;
	my $key = md5_hex($query);

	return $self->{__queries__}{$key} || ($self->{__queries__}{$key} = DB::Batch::Query->new(query => $query, %$opts));
}

# create a Batch::BindValue object to handle argument increments and whatnot if one hasn't been created yet
sub get_bindvalue_object {
	my $self  = shift;
	my $query = shift;
	my $opts  = shift;
	my $key   = $query->get_key();

	return $self->{__bindvalues__}{$key} || ($self->{__bindvalues__}{$key} = DB::Batch::BindValues->new(query => $query, dbh => $self->{dbh}, %$opts));
}

# get the current db handle to use
sub get_dbh {
	my $self = shift;

	if ($self->{loadbalancer}) {
		# TODO: write loadbalancer
	}

	return $self->{dbh};
}

# remove cached data for a query 
sub clear {
	my $self = shift;
	my $key  = shift;
	undef $self->{__queries__}{$key};
	undef $self->{__bindvalues__}{$key};
	undef $self->{sth}{$key};
}

1;
