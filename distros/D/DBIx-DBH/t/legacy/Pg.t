# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DBIx-DBH.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Data::Dumper;
use Test::More;

BEGIN { plan 'no_plan' }

use_ok('DBIx::DBH');


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @opt = 'tty';
my @dat = ( driver => 'Pg',
	dbname => 'db_terry',
	user => 'terry',
	password => 'markso'
	  );


sub make_data {
  DBIx::DBH->form_dsn
      (	
       @dat,
       map { $_ => 1 } @opt
      );
}



is(make_data, 'dbi:Pg:dbname=db_terry;tty=1');

push @dat , host => '123.Baker.org';

is(make_data, 'dbi:Pg:dbname=db_terry;host=123.Baker.org;tty=1');

push @dat , port => 3312;

is(make_data, 'dbi:Pg:dbname=db_terry;host=123.Baker.org;port=3312;tty=1');

push @dat , options => '-F -B';

is(make_data, 'dbi:Pg:dbname=db_terry;host=123.Baker.org;port=3312;options=-F -B;tty=1');

