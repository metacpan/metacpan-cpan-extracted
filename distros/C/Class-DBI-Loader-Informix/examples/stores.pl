#!/usr/bin/perl -w

use strict;

use DBI;
use Class::DBI::Loader;

my ($datasource) = grep /stores/,  DBI->data_sources('Informix');

if (!$datasource )
{
   print <<EOW;
You don't appear to have a "stores" database. You may be pointing
at the wrong server (in which case check your \$INFORMIXSERVER
environment variable.) Or the database hasn't been created, in
which case you should run the appopriate 'dbaccessdemo' program
to create (or ask your DBA to do so.)
EOW
}
else
{

   my $loader = Class::DBI::Loader->new(
                                         dsn => $datasource,
                                         user => '',
                                         password => '',
                                         relationships => 1,
                                         namespace => 'Stores',
                                         exclude => 'msg',
                                        );

   my $class = $loader->find_class('customer');

   foreach my $customer ($class->retrieve_all())
   {
      print $customer->customer_num(),":", $customer->company(),"\n";
      print "=" x length($customer->customer_num().":". $customer->company()),"\n";
      foreach my $order ($customer->order())
      {
         print "\t",$order->order_num(),"\t",
                    $order->order_date() || '' ,"\t",
                    $order->po_num() || '' ,"\n";
      }
      print "\n";
   }
}
