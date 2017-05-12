use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Alister::Base::Sums ':all';
use Cwd;
use vars qw($_part );

my $dbh = get_testing_dbh();

# can we setup  .. ?
ok( table_reset_sums($dbh), 'table_reset_sums()' );


my @valid_sums = qw/
f946d965d6fc77b0b8d12e5e0e5da6f5
f946d965d6fc77b0b8aa2e5e0e5da6f5
f946d445d6fc77b0b8d12e5e0e5da6f5
/;
my @invalid_sums = (
'p946d965d6fc77b0b8d12e5e0e5da6f5', # has letter p
'f946d965d6fc77b0b8aa2e5e0e5da6f', # 31 chars instead of 32
'f946d445d6fc77b0b8d12e5e0 e5da6f5', # spaces not allowed
undef,
);








ok_part('make sure sum_add() works for good and fails for bad, sums');
for (@valid_sums){
   my ($id,$id2);
   ok( $id = sum_add($dbh, $_), 'sum_add() works' );
   ok( $id2 = sum_add($dbh, $_), 'sum_add() works 2nd time' );
   ok( $id == $id2, "first time and second time id is same");
   
}

ok_part('invalids');

for (@invalid_sums){
   ok( ! sum_add($_), 'sum_add() fails on bad sums' );
}



ok_part('check add return vals..');
# what are we returning?
my $r = sum_add($dbh, 'f946d445d11117b0b8d12e5e0e5da6f5');
warn("# Got '$r'");
ok $r;
ok( validate_argument_id($r), "returned val  validates as id argument");

# if we do again, next id is more than last one
my $r2 = sum_add($dbh, '8846d445d11117b0b8d12e5e0e5da6f5');
ok( validate_argument_id($r2), "returned val  validates as id argument");
ok( ( $r + 1) == $r2, "next id is more than last one");










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

