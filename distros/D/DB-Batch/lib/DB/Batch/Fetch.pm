package DB::Batch::Fetch;
#
# encapsulate fetching functionality
#
# Copyright 2010, Chris Becker <clbecker@gmail.com>
#
# Original work sponsered by Shutterstock, LLC. http://shutterstock.com
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict;
use warnings;

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless \%args, $class;
	return $self;
}

# execute a query with the next batch of bind values
# then cache the statement handle to retrieve results
# via process_sth()
sub execute_batch_read {
	my $self    = shift;
	my %args      = @_;
	my $parent    = $args{parent}; # Batch::Main instance calling this
	my $query     = $args{query};  # Batch::Query instance
	my $opts      = $args{opts};   # hashref passed in from the calling script
	my $bind      = $args{bindvalues}; # Batch::BindValues instance
	my $dbi_bind  = $args{dbi_bind};   # values passed through, bound to '?' placeholders for DBI

	my $dbh       = $parent->get_dbh();
	my $key       = $query->get_key(); # md5 checksum of query string
	my $H         = $parent->{output}; # optional output handle/array/sub

	unless (defined $parent->{sth}{$key}) {	    
		my @batch = $bind->increment();  # get the current batch of bind values

		# set flag to indicate the execution of the next query in the batch
		# call Batch::Main->is_new_batch() from the while loop processing the query
		$parent->{__new_batch__} = 1;    
		unless (@batch) {
			# if we're out of data to bind, clear cached stuff and finish
			$parent->clear($key);
			return;
		}

		my $bound_query               = $query->bind_batch(\@batch); # bind current batch of data to placeholders
		$parent->{__last_query_key__} = $key;
		$parent->{__last_query__}     = $bound_query; # accessed with Batch::Main->get_last_query()

		# run post hook subroutine if provided in opts
		if (defined $opts->{pre_hook} && ref $opts->{pre_hook} eq 'CODE') {
			$opts->{pre_hook}->();
		}

		$parent->{sth}{$key} = $dbh->prepare($bound_query); # prepare statement handle and cache it
		$opts->{log}->info($query->bindstr($bound_query,@$dbi_bind)) if $opts->{log};

		if (defined $H) {

			# send the query to whatever was specified in $opts->{output}
			# if nothing was specified then the query is executed on the db
			#
			# if a sub ref was passed in then the sub is called with args [query,(dbi bind values)]
			# if an array ref was passed in, then the fully bound query is added to the array
			# if a filehandle was passed in, then the fully bound query is printed to the handle

			if (ref($H) eq 'CODE') {
				$H->($bound_query,@$dbi_bind);    
			} elsif (ref($H) eq 'ARRAY') {
				push @$H, $query->bindstr($bound_query,@$dbi_bind);
			} elsif(ref(\$H) eq 'GLOB') {
				print $H $query->bindstr($bound_query,@$dbi_bind);
			}

		} else { 
			$parent->{sth}{$key}->execute(@$dbi_bind); # execute the cached statement handle
		}
	} else {
		$parent->{__new_batch__} = 0;
	}
	return 1;
}

# return a row from the cached statement handle for the current query
# if the current statement handle is finished, execute the query with the next batch of bind values
sub process_sth {
	my $self     = shift;
	my %args     = @_;
	my $parent   = $args{parent};
	my $query    = $args{query};
	my $opts     = $args{opts};
	my $dbi_bind = $args{dbi_bind};  # these are bound to ? placeholders for DBI
	my $caller   = $args{caller};
	my $key      = $query->get_key();
	my $dbh      = $parent->get_dbh();

	# call the appropriate fetch function from the statement handle based on what was called on Batch::Main
	if (defined $parent->{sth}{$key}) {
		if ($caller =~ m/fetchrow_hashref$/) {
			if (my $hr = $parent->{sth}{$key}->fetchrow_hashref()) {
				return $hr;
			}
		} elsif ($caller =~ m/fetchrow_arrayref$/) {
			if (my $ar = $parent->{sth}{$key}->fetchrow_arrayref()) {
				return $ar;
			}
		} elsif ($caller =~ m/fetchrow_array$/) {
			if (my @arr = $parent->{sth}{$key}->fetchrow_array()) {
				return @arr;
			}
		} elsif ($caller =~ m/fetchbatch_custom$/) {
			# send the sth to the custom subroutine and return the result
			$parent->auto_throttle($opts);
			$parent->throttle($opts);
			return $opts->{sub}->( $parent->{sth}{$key}, $opts->{sub_args}, $opts );
		}

		# run post hook subroutine if provided in opts
		if (defined $opts->{post_hook} && ref $opts->{post_hook} eq 'CODE') {
			$opts->{post_hook}->();
		}

		# perform any throttling before executing the next query
		$parent->auto_throttle($opts);
		$parent->throttle($opts);
		undef $parent->{sth}{$key};
		
		# if we've finished executing a statement handle, proceed to execute the query with the next batch of arguments
		if ($caller =~ m/fetchrow_hashref$/) {
			$parent->fetchrow_hashref($query->get_original_query(),$opts,@$dbi_bind);

		} elsif ($caller =~ m/fetchrow_arrayref$/) {
			$parent->fetchrow_arrayref($query->get_original_query(),$opts,@$dbi_bind);

		} elsif ($caller =~ m/fetchrow_array$/) {
			$parent->fetchrow_array($query->get_original_query(),$opts,@$dbi_bind);
		} 
	}	
}

1;
