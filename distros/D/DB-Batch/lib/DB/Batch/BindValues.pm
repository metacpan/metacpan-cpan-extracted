package DB::Batch::BindValues;
# handle the batching of batched bind values
#
# Copyright 2010, Chris Becker <clbecker@gmail.com>
#
# Original work sponsered by Shutterstock, LLC. http://shutterstock.com
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict;
use warnings;

use Data::Dumper;
use POSIX qw(ceil);
use List::Util qw(min max);

#
# args:
# query => Batch::Query object
# bindvalues => []
# dbh => database handle
# start => start incrementing ranged arguments at this value (i.e. for BETWEEN start AND end)
# end => stop incrementing ranged arguments at this value
# batch => number of items to batch at once
# list =>
sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless \%args, $class;

	# used to cache the current start value for ranged batches over multiple queries (e.g. between # and #)
	$self->{increment} ||= {};   
	$self->identify_range_args();

	return $self;
}


##
# figure out what the next batch of bind values should be, and return them as a list
sub increment {
	my $self = shift;
	my $key  = $self->{query}->get_key();

	# if we're following a previous batch, set the next start value to start + batch size
	# if we're just starting, set the start of this increment to $self->{start}
	if (exists $self->{increment}{$key} && defined $self->{increment}{$key}{start}) {
		$self->{increment}{$key}{start} += $self->{batch};
	} else {
		$self->{increment}{$key}{start} = $self->{start};
	}

	# don't go past the specified end value
	unless ($self->{list}) {
		if ($self->{increment}{$key}{start} +  $self->{batch} > $self->{end}) {
			$self->{batch} = $self->{end} - $self->{increment}{$key}{start} + 1;
		}
	}

	# if start reaches end, we're done
	if ($self->{increment}{$key}{start} > $self->{end}) {
		$self->{__current_batch_values__} = [];
		return ();
	}

	# split list into batches to inject directly into query 
	if ($self->{list}) {
		$self->{__current_batch_values__} = [ $self->set_list_args() ];
	} else {
	    # create start and end values to inject into between or limit/offset clause
		$self->{__current_batch_values__} = [ $self->set_range_args() ];
	}

	return @{$self->{__current_batch_values__}}
}


# identify which arguments in the query are start (offset), end (start + limit), or limit
# based on simple patterns
sub identify_range_args {
	my $self = shift;
	my $query = $self->{query};

	# depending on the query, placeholders may have different meanings
	# i.e. ...where id between 100 and 200
	#      ...limit 100,200
	#      ...limit 200 offset 100
	if ($self->{list} && @{$self->{list}}) {

		if ($self->{makebinds} && $self->{groups}) {
			# e.g. (#,#),(#,#),(#,#); makebinds = 2, groups = 3, batch = 6
			$self->{batch} = $self->{makebinds} * $self->{groups};
		} elsif ($self->{makebinds}) {
			# e.g. (#,#,#) makebinds = 3, batch = 3
			$self->{batch} = $self->{makebinds};
		} else {
			# set batch count to total number of placeholders that the user manually put in the query string
			$self->{batch} = $query->get_placeholder_count(); 
			my $size = scalar @{$self->{list}};
			if ($size % $self->{batch} != 0) {
				die "number of arguments is not a multiple of the number of placeholders in this query";
			}
		}

		if (ref $self->{list}[0] eq 'ARRAY') {
			# if given a list of lists of bind values, set the end value to the total number of items (i.e. x * y)
			$self->{end} = scalar @{$self->{list}[0]} * scalar @{$self->{list}};
		} else {
			# if given a list of bind values, set the end to the number of values in the list
			$self->{end} = scalar @{$self->{list}};
		}

		# these are only used if defining ranges, e.g. for 'between # and #' clauses
		$self->{arg1} = undef;
		$self->{arg2} = undef;
		return;
	}

	if ($query->get_param_type() eq 'limit') {
		# e.g. ...LIMIT offset,rowcount
		$self->{arg1} = 'offset';
		$self->{arg2} = 'row_count';

	} elsif ($query->get_param_type() eq 'limit-offset') {
		# e.g. ...LIMIT row_count OFFSET offset
		$self->{arg1} = 'row_count';
		$self->{arg2} = 'offset';

	} elsif ($query->get_param_type() eq 'between') {
		# e.g. ...BETWEEN offset AND end
		$self->{arg1} = 'offset';
		$self->{arg2} = 'end';

	} elsif (!defined $self->{list}) {
		# base start, end, limit on number of bind values entered
		$self->{arg1} = 'offset'    if (defined $self->{start});
		$self->{arg2} = 'row_count' if (defined $self->{limit});
		$self->{arg2} = 'end'       if (defined $self->{end});
		die 'you need to define start, limit, and/or end;'."\n-- $query" unless (defined $self->{arg1} && defined $self->{arg2});

	} else {
		die 'you need to define start, limit or end, or list'."\n-- $query";
	}
}


# return a batch of $opts->{list} 
sub set_list_args {
	my $self = shift;
	my $key = $self->{query}->get_key();

	return undef unless @{$self->{list}};

	my @args;
	# if list contains lists of bind values.  shift one value off each list until all placeholders are filled
	if (ref $self->{list}[0] eq 'ARRAY') {
		my $index = 0;

		# e.g. (#,#,#)
		# list => [ [1,4], [2,5], [3,6] ] 
		# results in: 
		# (1,2,3)
		# (4,5,6)

		for my $i (1..$self->{batch}) {
			my $_list = $self->{list}[$index++];
			last unless @$_list;
			push @args, shift @$_list;
			$index = 0 if ($index > $#{$self->{list}});
		}
	} else {
		my $end;

		# if dynamically generating placeholders, avoid excess undef entries in list
		if ($self->{makebinds}) {
			# calculated end point, or actual end point
			$end = min($self->{increment}{$key}{start} + $self->{batch} - 1, $#{ $self->{list} });
		} else {
			# calculate end point using the specified batch size
			$end = $self->{increment}{$key}{start} + $self->{batch};
		}

		$end = $end > $#{$self->{list}} ? $#{$self->{list}} : $end;

		if ($self->{makebinds} && 
		    $self->{groups} && 
		    @{$self->{list}} % $self->{makebinds}) {

			# if generating groups of placeholders, avoid extra groups of placeholders
			# but fill the last group with null's if there aren't enough values
			# e.g. (#,#,#),(#,#,#)
			# list => [1,2,3,4,5]
			# results in:
			# (1,2,3),(4,5,NULL)
			my $g = ceil((@{$self->{list}} - $self->{increment}{$key}{start}) / $self->{makebinds});
			$end = $self->{increment}{$key}{start} + $self->{makebinds} * $g - 1;
		}

		@args = @{ $self->{list} }[ $self->{increment}{$key}{start}..$end];
	}

	# run each argument through $dbh->quote, or a custom quote function if provided
	return map {
		if (defined ($self->{quote}) && ref($self->{quote}) eq 'CODE') {
			$self->{quote}->($_);
		} else {
			$self->{dbh}->quote($_);
		}
	} @args;
}


# return a start and end/limit for current query
sub set_range_args {
	my $self = shift;
	my $key = $self->{query}->get_key();

	# map field to position in array
	# position in array then corresponds to the order in which each element is bound in the query via sprintf
	my %m = (
		arg1 => 0,
		arg2 => 1,
	);

	# self->{arg1} and $self->{arg2} are defined in identify_range_args()
	# assign argN of @return as follows:
	# if argN is 'offset', assign to start of the current increment
	# if argN is 'end', assign to start + batch size for the current increment
	# if argN is 'row_count', assign to batch size

	# between identify_range_args() and this function, a sample result would be:
	#  given query: ...LIMIT #,#
	# then identify_range_args() says: 
	#  arg1 = 'offset', 
	#  arg2 = 'row_count'
	# then this functions sets:
	#  $return[0] = $self->{increment}{$key}{start};
	#  $return[1] = $self->{batch}
	#
	my @return;	
	# place arguments in correct positions based on resut of identify_range_args()
	for my $k (keys %m) {

		if ($self->{$k} eq 'offset') {

			$return[$m{$k}] = $self->{increment}{$key}{start};
		} elsif ($self->{$k} eq 'end') {

			$return[$m{$k}] = $self->{increment}{$key}{start} + $self->{batch} - 1; # make between's exclusive
		} elsif ($self->{$k} eq 'row_count') {

			$return[$m{$k}] = $self->{batch};
		}
	}

	return @return;
}

# get the last batch of bind values that was executed
sub get_last_batch {
	my $self = shift;
	return @{$self->{__current_batch_values__}};
}


1;
