#!/usr/bin/perl -I../../../perl-easy/lib

use DBI;

use strict;

use Data::Dumper;

use Test::More qw(no_plan);

BEGIN {

	use_ok 'DBI::Easy';
	
	push @INC, 't', 't/DBI-Easy';
	require 'db-config.pl';
	
	my $dbh = &init_db;
	
};

&finish_db;

1;
