#!/usr/bin/perl

require 'dbconn.pl';
use DBIx::Recordset;
use strict;

# This program repeatedly presents sales data on STDOUT, refreshing 
# the view every $view_refresh seconds. It refreshes its 
# model (from the database) every $model_refresh seconds.

# The default values for $model_refresh and $view_refresh imply that 
# the model will refreshed after 2.6 view refreshes or practically speaking
# on every 3rd view refresh.

# You can verify that it makes new hits on the database by noting the
# DBIx::Recordset log messages. You will see this after every 3 view
# displays:
# DB:  'SELECT * FROM sales     ORDER BY sonum DESC  LIMIT 6' bind_values=<> bind_types=<>

# To spice things up, you can open a different terminal window and run
# prefetch-insert.pl, which will insert a new record into the sales table
# every $x seconds.

# This program requires a version of DBIx::Recordset > 0.24, which is the 
# current CPAN release. Or you can apply the patch recently posted to
# the embperl@perl.apache.org mailing list.

my $model_refresh = 13;
my $view_refresh  = 5;

use vars qw(%sales);

tie %sales, 'DBIx::Recordset::Hash',
  {
   conn_dbh(),
   '!Table' => 'sales',
   '!PreFetch' => {
		   '$max'    => 5,
		   '$order'  => 'sonum DESC'
		  },
   '!PrimKey'  => 'sonum',
   '!Expires'  => $model_refresh
  };

sub bynumber { $a <=> $b }

while (1) {

  my (@key) = keys %sales;
  print $sales{$_}{sonum}, $/ for sort bynumber @key;
  sleep $view_refresh;
  print $/;

}

