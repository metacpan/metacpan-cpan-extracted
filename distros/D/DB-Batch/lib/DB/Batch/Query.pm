package DB::Batch::Query;
# expand queries into batch form
# example query: SELECT id FROM accounts WHERE id BETWEEN # AND #
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
use Digest::MD5 qw(md5_hex);

# args:
# query     => 'sql query'
# makebinds => convert # into this number of placeholders
# groups    => used for batch inserts, makes this number of groups containing $makebinds placeholders each
# args      => list of values to be binded
sub new {
	my $class = shift;
	my %args  = @_;
	my $self  = bless \%args, $class;

	$self->{__placeholder_query__} = $self->convert_placeholders();

	return $self;
}

# If bind parameters determine some range, figure out what type of clause we're dealing with
sub get_param_type {
	my $self = shift;

	return $self->{__type__} if $self->{__type__};

	if ($self->{__placeholder_query__} =~ m/LIMIT\s+\%s\s*,\s*\%s/i) {
		$self->{__type__} = 'limit';
	} elsif ($self->{__placeholder_query__} =~ m/LIMIT\s+\%s\s+OFFSET\s+\%s/i) {
		$self->{__type__} = 'limit-offset';
	} elsif ($self->{__placeholder_query__} =~ m/BETWEEN\s+%s\s+AND\s+%s/i) {
		$self->{__type__} = 'between';
	}

	return $self->{__type__};
}

# bind the current batch of values to the query
sub bind_batch {
	my $self   = shift;
	my $values = shift || [];

	# expand any placeholders based on the values of makebinds and groups
	my $_query = $self->expand_placeholders(scalar @$values);
	return sprintf($_query,@$values);
}

# expand # into #,#,#...
# optional args:
# $batch_size: number of arguments being bound.  
# if this number is less than makebinds, then fewer placeholders will be generated to avoid null entries in the query
#
# example: 
# with the parameters groups => 2, makebinds => 3
# the query:
#  INSERT INTO foo VALUES #
# will expand to:
#  INSERT INTO foo VALUES (#,#,#),(#,#,#)
sub expand_placeholders {
	my $self       = shift;
	my $batch_size = shift || $self->{makebinds};
	my $query      = $self->{__placeholder_query__};

	if ($self->{makebinds} && $self->{groups}) {

		if ($self->{groups} * $self->{makebinds} > $batch_size) {
			$self->{groups} = ceil($batch_size / $self->{makebinds});
		}
		return sprintf($query,group_placeholders($self->{groups},$self->{makebinds},'%s',$self->{group}));
	} elsif ($self->{makebinds}) {
		return sprintf($query,placeholders($batch_size,'%s'));
	} 
	return $query;
}


# return unique identifier of the current query and cache for later use
sub get_key {
	my $self = shift;
	return $self->{__md5__} || ($self->{__md5__} = md5_hex($self->{query}));
}

# return the original sql string given
sub get_original_query {
	my $self = shift;
	return $self->{query};
}

# return the current number of placeholders
sub get_placeholder_count {
	my $self = shift;
	my $placeholder_count = () = $self->{__placeholder_query__} =~ m/(%s)/g; 
	return $placeholder_count;
}

# return query string with bind variables (e.g. '?') bound
sub bindstr {
	my $self  = shift;
	my $query = shift || $self->{query};
	$query    =~ s/%(?!s)/%%/g; # escape standalone %'s
	$query    =~ s/(?<!\\)\?/%s/g; # replace all #'s with %s unless escaped
	return sprintf ($query,@_);
}

# convert '#' to '%s'
sub convert_placeholders {
	my $self    = shift;
	my $query   = $self->{query};
	if ($query  =~ m/(?<!\\)#/) {
		$query =~ s/%(?!s)/%%/g;   # escape standalone %'s
		$query =~ s/(?<!\\)#/%s/g; # replace all #'s with %s unless escaped
	}
	return $query;
}

# given column names, create the body of an insert statement with placeholders
sub make_insert_string {
     my $fields       = shift;
	my $placeholder  = shift;
     my $field_string = join(',',map {"`$_`"} @$fields);
	my $binds        = placeholders(scalar @$fields,$placeholder);
     return " ($field_string) VALUES ($binds)";
}

# given column names, create the body of an insert statement with multiple sets of placeholders
# INSERT INTO table (a,b,c) VALUES (#,#,#),(#,#,#)...
#
# $fields: list of columns 
# $count: number of batches of values (optional, default 1)
# $placeholder: optional, default '?'
sub make_multi_insert_string {
	my $fields       = shift;
	my $count        = shift || 1;
	my $placeholder  = shift;
	my $field_string = join(',',map {"`$_`"} @$fields);
	return " ($field_string) VALUES ".group_placeholders($count,scalar @$fields,$placeholder);
}

# create a string containing N comma-separated placeholders
# args:
# $_[0]: number of placeholders
# $_[1]: (optional) placeholder character to use.  Default is '?'
sub placeholders {
	my $num = shift;
	my $p   = shift || '?';
	return join(',', ($p) x $num);
}

# created $g groups containing $n placeholders
# $_[0]: number of groups
# $_[1]: number of placeholders per group
# $_[2]: (optional) placeholder string, default '?'
# $_[3]: (optional) predefined placeholder group 
sub group_placeholders {
	my $g     = shift;
	my $n     = shift;
	my $p     = shift || '?';
	my $binds = shift || placeholders($n,$p);
	return join(',',("($binds)") x $g);
}

1;
