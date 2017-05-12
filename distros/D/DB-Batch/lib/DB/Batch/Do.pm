package DB::Batch::Do;
# encapsulate write functionality
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

##
# Execute a write to the database in batches
# execute the given query until all bind variables have been bound in batches
sub do_batch {
	my $self      = shift;
	my %args      = @_;
	my $parent    = $args{parent};
	my $query_str = $args{query};
	my $opts      = $args{opts};
	my $dbi_binds = $args{dbi_binds} || [];

	die 'query not defined' unless ($query_str);

	my $dbh = $parent->get_dbh();
	my $log = $opts->{log};
	my $H = $opts->{output};

	my $query      = $parent->get_query_object($query_str,$opts);
	my $bindvalues = $parent->get_bindvalue_object($query,$opts);
	my $key        = $query->get_key();  # get hash key of query w/ placeholders

	my @batch = $bindvalues->increment();

	while(@batch) {

		my $bound_query = $query->bind_batch(\@batch); # bind current batch of data to placeholders

		# run post hook subroutine if provided in opts
		$parent->{__last_query_key__} = $key;
		$parent->{__last_query__}     = $bound_query; # accessed with Batch::Main->get_last_query()

		if (defined $opts->{pre_hook} && ref $opts->{pre_hook} eq 'CODE') {
			$opts->{pre_hook}->();
		}

		$opts->{log}->info($query->bindstr($bound_query,@$dbi_binds)) if ($opts->{log});

		if (defined $H) {

			# send the query to whatever was specified in $opts->{output}
			# if nothing was specified then the query is executed on the db
			#
			# if a sub ref was passed in then the sub is called with args [query,(dbi bind values)]
			# if an array ref was passed in, then the fully bound query is added to the array
			# if a filehandle was passed in, then the fully bound query is printed to the handle
			if (ref($H) eq 'CODE') {
				$H->($bound_query,@_);    
			} elsif (ref($H) eq 'ARRAY') {
				push @$H, $query->bindstr($bound_query,@$dbi_binds);
			} elsif(ref(\$H) eq 'GLOB') {
				print $H $query->bindstr($bound_query,@$dbi_binds);
			}

		} else {
			$dbh->do($bound_query,undef,@$dbi_binds);
		}

		# run post hook subroutine if provided in opts
		if (defined $opts->{post_hook} && ref $opts->{post_hook} eq 'CODE') {
			$opts->{post_hook}->();
		}

		@batch = $bindvalues->increment();

		last unless (@batch);
		$parent->auto_throttle($opts);
		$parent->throttle($opts);
	} 
	$parent->clear($key);
}

1;
