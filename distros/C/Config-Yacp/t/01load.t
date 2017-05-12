use Test::More tests =>7;

BEGIN{ use_ok('Config::Yacp'); }

my $config_file="t/config.ini";

my $CY=Config::Yacp->new(FileName=>$config_file);

ok(defined $CY, 'An object was created');

ok($CY->isa('Config::Yacp'),'It is the correct type');

my $File=$CY->get_FileName;
ok($File eq "t/config.ini");

my $CM=$CY->get_CommentMarker;
ok($CM eq "#");

my $cy=Config::Yacp->new(FileName=>$config_file,CommentMarker=>';');
my $cm=$cy->get_CommentMarker;
ok($cm eq ";");

eval{ my $invalid_CM=Config::Yacp->new(FileName=>$config_file,CommentMarker=>'@'); };
ok(defined $@);

