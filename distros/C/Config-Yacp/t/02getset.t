use Test::More tests => 6;
use Config::Yacp;

my $config_file="t/config.ini";

my $CY=Config::Yacp->new(FileName=>$config_file);

#1
my @sections=$CY->retrieve_sections;
ok(scalar @sections == 2,'Correct number of sections');

#2
my @params;
foreach(@sections){
  my @p=$CY->retrieve_parameters($_);
  push @params,@p;
}
ok(scalar @params == 4,'Correct number of parameters');

#3
my $value=$CY->retrieve_value("Section1","Parameter1");
is($value,"Value1",'Correct parameter value retrieved');

#4
my $CY2=Config::Yacp->new(FileName=>$config_file);
$CY2->change_value("Section1","Parameter1","Value9");
my $value2=$CY2->retrieve_value("Section1","Parameter1");
is($value2,"Value9",'Changing values works');

#5
my $comment=$CY->retrieve_comment("Section2","Parameter3");
is($comment," Comment A",'Retrieve comments');

#6
my $cmmnt="Comment X";
$CY->add_comment("Section2","Parameter3",$cmmnt);
my $change=$CY->retrieve_comment("Section2","Parameter3");
is($change,"Comment X",'Change comment');

