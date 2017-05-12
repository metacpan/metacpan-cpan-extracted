# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Chess-Elo.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More 'no_plan';
use Chess::Elo qw(:all);


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @test = (	
  {	
    args 	 => [2100, 1, 1200],
    expected => [qw(2100.17894295388 1199.82105704612)]
   },	

  {   
    args 	 => [2100, 0.5, 1200],
    expected => [qw(2084.17894295388 1215.82105704612)]
   },


  {					
    args 	 => [2100, 0, 1200],
    expected => [qw(2068.17894295388 1231.82105704612)]
   },


  {					
    args 	 => [1200, 0, 2100],
    expected => [qw(1199.82105704612 2100.17894295388)]
   },

  {	
    args 	 => [1200, 0.5, 2100], 
    expected => [qw(1215.82105704612 2084.17894295388)]
   },	
  {   
    args 	 => [1200, 1, 2100],
    expected => [qw(1231.82105704612 2068.17894295388)]
   },

 )	;					

for my $test (@test) {

  my @arg = @{$test->{args}} ;
  my @exp = @{$test->{expected}} ;
  my @out = elo(@arg);

  diag  "test with input: @arg expecting @exp received @out" ;
  for (0..1) {
    is ($out[$_], $exp[$_], "test with input: @arg expecting $exp[$_]")	;
  }
}
