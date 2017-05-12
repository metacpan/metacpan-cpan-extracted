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
/;


for my $sum (@valid_sums){
   my $id;
   ok( $id = sum_add($dbh, $sum), "sum_add()");
   
   warn("# id: '$id', sum: '$sum'\n");
   
   my $get_id = sum_get( $dbh, $sum );
   ok( $get_id,"sum_get()");
   ok( $get_id == $id ,'sum_get() returns id expected');


   my $get_sum = sum_get( $dbh, $id );
   ok( $get_sum,"sum_get() but via id..");
   ok( $get_sum eq $sum ,'sum_get() returns sum expected');


   warn("# got id: '$get_id', got sum: '$get_sum'\n\n");   

}




ok_part('sum_get() for valid but unregistered sums..');

for my $sum (qw/1234 1146d99996fc77b0b8aa2e5e0e5da6f5 0000d965d6fc77b0b8aa2e5e0e5da6f5/){ # not registered
   my $r;
   
   ok( ! ($r = sum_get( $dbh, $sum )), 'sum_get() returns false for sum not registered');
   warn("# r : $r\n\n");   

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

