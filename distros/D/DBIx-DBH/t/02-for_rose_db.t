#! /usr/bin/env perl

use Test::More;
use Data::Dumper;

use_ok( 'DBIx::DBH' );
diag( "Testing DBIx::DBH $DBIx::DBH::VERSION, Perl $], $^X" );

my $config = DBIx::DBH->new
  (
   username => 'bill',
   password => 'smith',
   dsn => { driver => 'mysql', database => 'red', port => 3306 },
   attr => { RaiseError => 1 }
  );


my %connect_data = $config->for_rose_db;

diag(Dumper(\%connect_data));

is_deeply (\%connect_data, 
	   
	   {
           'database' => 'red',
           'password' => 'smith',
           'port' => 3306,
           'driver' => 'mysql',
           'username' => 'bill'
	   }
	   , 'for rose_db');

done_testing();
