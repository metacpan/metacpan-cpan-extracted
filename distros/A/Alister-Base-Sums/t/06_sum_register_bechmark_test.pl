#!/usr/bin/perl
use strict;
use lib './lib';
use Test::Simple 'no_plan';

use Alister::Base::Sums ':all';

# generate random sums and get ids for them




my $dbh = get_testing_dbh();
$dbh->{AutoCommit} = 0;

# can we setup  .. ?
ok( table_reset_sums($dbh), 'table_reset_sums()' );


for (0 .. 10 ){
   validate_argument_sum( rndsum() ) or die;
}

my @rndsums;
my @rndsums2;

my $total = 5000;
for ( 1 .. $total ){

   push @rndsums, rndsum();
   push @rndsums2, rndsum();


}


my $got = scalar @rndsums;
ok( $got, "got random gen sums count : $got");



ok( enter_many_without_asking_for_id(\@rndsums), 'enter_many_without_asking_for_id');
ok( enter_many_without_asking_for_id(\@rndsums), 'enter_many_without_asking_for_id, again');

ok( enter_many_asking_for_id(\@rndsums2), 'enter_many_asking_for_id');
ok( enter_many_asking_for_id(\@rndsums2), 'enter_many_asking_for_id, again, same ones..');


exit;




sub rndsum {   
   my @chars = qw/0 1 2 3 4 5 6 7 8 9 a b c d e f/;
   my $rndsum;
   for ( 0 .. 31 ) {
      $rndsum.= $chars[int(rand (16))];
   }
   $rndsum;
}


# TODO make sure autocommit is off!!!

sub enter_many_asking_for_id {
   my $sums = shift;

   my $id;
   for (@$sums){
      $id = sum_add($dbh, $_);
      #print STDERR "$id ";
   }
   print STDERR "\n";
   1;
}



sub enter_many_without_asking_for_id {
   my $sums = shift;

   for (@$sums){
      sum_add($dbh, $_);
   }
   1;
}














sub get_testing_dbh {
   ok 1, 'started';
   my $abs_conf = "./t/dev.dbh.conf";
   
   # NEED A DBH
   unless( -f $abs_conf ) {
      warn("# do not have '$abs_conf', see README");
      exit;
   }

   require YAML::DBH;
   my $dbh = YAML::DBH::yaml_dbh($abs_conf)
      or die("Make sure '$abs_conf' has real and valid params,. check that db server is running.");
}

