#!/usr/bin/perl -w

use strict;
use Test::More tests => 6;

use DBI;
use Class::DBI::Loader;

my ($datasource) = grep /stores/,  DBI->data_sources('Informix');

SKIP:
{
   skip "No stores database to test against" unless $datasource;

   my $loader;
   eval
   { 
      $loader = Class::DBI::Loader->new(
                                         dsn => $datasource,
                                         user => '',
                                         password => '',
                                         relationships => 1,
                                         namespace => 'Stores',
                                         exclude => 'msg',
                                        );
   };

   ok(!$@,"Load and analyze DB");

   my $class;

   eval
   {
      $class = $loader->find_class('customer');
   };
   ok(!$@,'find customer class');

   my $newcust;

   eval
   {
      $newcust = $class->insert({
                               fname => 'John',
                               lname => 'Cooper Clarke',
                               company => 'Test company'
                            });
   };
   ok(!$@ && defined $newcust,"Insert new customer");

   my $neworder;
   eval
   {
      $neworder = $newcust->add_to_order({ship_instruct => 'Testshipping'});
   };
   ok(!$@ && defined $neworder,"Insert child order");

   my @customers;
   ok(@customers = $class->retrieve_all(),'Retrieve customers');
   ok(($customers[0]->order())[0],"Retrieve an order");
}
