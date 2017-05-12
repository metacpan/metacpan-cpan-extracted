use Test::More tests=>4;
use Config::Yacp;

my $ini="t/config.ini";
my $cy=Config::Yacp->new(FileName=>$ini);

$cy->delete_comment("Section2","Parameter3");
my $cm=$cy->retrieve_comment("Section2","Parameter3");
ok(defined $@);

$cy->delete_parameter("Section2","Parameter3");
my @parameters=$cy->retrieve_parameters("Section2");
ok(scalar @parameters == 1);

$cy->delete_section("Section2");
my @sections = $cy->retrieve_sections;
ok(scalar @sections == 1);

eval{ $cy->delete_comment("Section1","Parameter1"); };
ok(defined $@,'Catch deletion of non existent comment');

