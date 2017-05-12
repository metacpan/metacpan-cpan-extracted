use Test::More tests => 4;
use Config::Yacp;

my $ini="t/config.ini";

my $cy=Config::Yacp->new(FileName=>$ini);

$cy->add_section("Section3");
my @sections=$cy->retrieve_sections;
ok(scalar @sections == 3,'Adding sections works');

$cy->add_parameter("Section3","Parameter5","Value5");
my @params=$cy->retrieve_parameters("Section3");
ok(scalar @params == 1,'Adding parameter/values works');

$cy->add_parameter("Section4","Parameter6","Value6","Comment XX");
my @sec=$cy->retrieve_sections;
ok(scalar @sec==4);
my $comment=$cy->retrieve_comment("Section4","Parameter6");
is($comment,"Comment XX");

