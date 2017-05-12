use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    use DBStagTest;
    plan tests => 5;
}
use DBIx::DBStag;
use DBI;
use Data::Stag;
use FileHandle;
use strict;

drop();
my $f = "t/data/bond.el";
my $spydata = Data::Stag->parse($f);
my $dbh = dbh();
my $ddl = $dbh->autoddl($spydata);
$dbh->do($ddl);
my @kids = $spydata->kids;
foreach (@kids) {
    $dbh->storenode($_);
}

my $out = $dbh->selectall_stag('SELECT * FROM agent NATURAL JOIN mission NATURAL JOIN mission_gizmo NATURAL JOIN gizmo');
my @agents = $out->get_agent;
ok(@agents,1);
my $agent = shift @agents;
my @missions = $agent->get_mission;
ok(@missions,2);
my @missions_with_a_car = 
  $out->where('mission',
	      sub {
		  grep { $_->get_gizmo_type eq 'car' } shift->find_gizmo
	      });
ok(@missions_with_a_car,1);
print $missions_with_a_car[0]->sxpr;
ok($missions_with_a_car[0]->get_codename,'goldfinger');

$out = $dbh->selectall_stag("SELECT agent.*, bureau.*, agent.firstname || agent.lastname AS agent__fullname FROM agent NATURAL JOIN bureau_to_agent NATURAL JOIN bureau");

print $out->sxpr;
ok($out->sget_agent->sget_fullname,'JamesBond');

$dbh->disconnect;
