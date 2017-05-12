use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Alister::Base::Sums ':all';
use Cwd;
use vars qw($_part );

no warnings;
my $dbh = get_testing_dbh();
table_reset_sums($dbh) or die;


my @valid_sums = qw/
0046d965d6fc77b0b8d12e5e0e5da6f5
1146d965d6fc77b0b8aa2e5e0e5da6f5
2246d445d6fc77b0b8d12e5e0e5da6f5
3346d445d6fc77b0b8d12e5e0e5da6f5
4446d445d6fc77b0b8d12e5e0e5da6f5
/;
my @invalid_sums = qw/
0046d965d6fc77b0b8d12e5e0e5da6f5
046d965d6fc77b0b8d12e5e0e5da6f5
0046d965d6fc77b0b8d12e5e0e5da6f5e
/;



ok_part('sum_delete() via sum string');
for my $sum (@valid_sums){
   my $id;
   ok( $id = sum_add($dbh, $sum), "sum_add()");
   
   warn("# id: '$id', sum: '$sum'\n");
   my $r;

   ok( $r = sum_delete($dbh, $sum),'sum_delete() via sum string');
   warn("# got result: $r\n");




}


ok_part('sum_delete() via id');
for my $sum (@valid_sums){
   my $id;
   ok( $id = sum_add($dbh, $sum), "sum_add()");
   
   warn("# id: '$id', sum: '$sum'\n");
   my $r;

   ok( $r = sum_delete($dbh, $id),'sum_delete() via sum id');
   warn("# got result: $r\n");

}



ok_part('what if I do it again.. but they are not there..');
for my $sum (@valid_sums){
   my $r;
   ok( !($r = sum_delete($dbh, $sum)),'sum_delete() via sum that is no longer there');
   warn("# got result: $r\n");

}






ok_part('sum_delete() invalid sums');
for my $sum (@invalid_sums){
   
   my $r;
   ok( ! eval { sum_delete($dbh, $sum) } ,'sum_delete() via sum string, fake sum, returns false');
   warn("# got result: $r\n");


}














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

