use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Alister::Base::Sums ':all';
use Cwd;
use vars qw($_part );

my $dbh = get_testing_dbh();

# can we setup  .. ?
ok( table_reset_sums($dbh), 'table_reset_sums()' );

# change to.. 
my %sum = (qw/1146d965d6fc77b0b8d12e5e0e5da6f5 8846d965d6fc77b0b8d12e5e0e5da6f5
2246d965d6fc77b0b8aa2e5e0e5da6f5 6646d965d6fc77b0b8d12e5e0e5da6f5
3346d445d6fc77b0b8d12e5e0e5da6f5 7746d965d6fc77b0b8d12e5e0e5da6f5/);



while (my ($s1, $s2) =  each %sum){
   my $id;
   ok( $id = sum_add($dbh, $s1),'sum_add()');

   warn("id is $id\n");


   my $r;
   ok( $r = sum_update($dbh, $s1, $s2), 'sum_update() via sum');

   ok( $r = sum_update($dbh, $id, $s1), 'sum_update() via id');

   



}

ok_part('conds..');
ok( !sum_update($dbh, '0000000000003333b8daaaae0e5da6f5', '7746d965d6fc77b0b8d12e5e0e5d8888'),
      'updating one that does not exist....');

ok_part();

ok sum_add($dbh, '0000000000003333b8daaaae0e5da6cc');
ok sum_add($dbh, '0000000000003333b8daaaae99999999');


ok(
   !sum_update( $dbh, '0000000000003333b8daaaae99999999', '0000000000003333b8daaaae0e5da6cc'),
   'what if i update two to same value.. should not have multiples..');

# TODO
# no.. should not fail if we update to existing sum.. should remove old one, and return matching old one











# SUBS ...............


sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
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

