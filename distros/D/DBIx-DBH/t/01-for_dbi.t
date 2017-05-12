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


my @connect_data = $config->for_dbi;

is (shift @connect_data, "dbi:mysql:database=red;port=3306", 'form-dsn');
is (shift @connect_data, "bill", 'username');
is (shift @connect_data, "smith", 'password');
is_deeply (shift @connect_data, { RaiseError => 1 } , 'attrs');

done_testing();
