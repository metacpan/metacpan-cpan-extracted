# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DBIx-DBH.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Data::Dumper;
use Test::More;
BEGIN { plan 'no_plan' }
use DBIx::DBH;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @dat = ( driver => 'Pg',
	    dbname => 'db_terry',
	    user => 'terry' ) ;
	 

sub ret_attr {

  my @connect_data = DBIx::DBH->connect_data
    ( 
     @dat,
     RaiseError => 17,
     pg_auto_escape=> 3
    );

  $connect_data[3];

}
    
is (ret_attr->{RaiseError},     17);
is (ret_attr->{pg_auto_escape}, 3);
