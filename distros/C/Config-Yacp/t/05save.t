use Test::More tests=>1;
use Config::Yacp;

my $config="t/config2.ini";

my $CY1=Config::Yacp->new(FileName=>$config);

$CY1->add_section("Section3");
$CY1->add_parameter("Section3","Parameter5","Value5");

$CY1->save;

my $CY2=Config::Yacp->new(FileName=>$config);

my @sections=$CY2->retrieve_sections;
ok(scalar @sections == 3);

