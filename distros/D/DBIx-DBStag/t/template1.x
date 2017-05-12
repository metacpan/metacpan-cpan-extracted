use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    use DBStagTest;
    plan tests => 4;
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

$dbh->add_template(agent =>
		   q/
		   SELECT *
		   FROM agent 
		   NATURAL JOIN mission
		   NATURAL JOIN mission_gizmo
		   NATURAL JOIN mission_to_person
		   NATURAL JOIN person
		   WHERE lastname = ?
		   /);
$dbh->add_template(agent_by_mission =>
		   q/
		   SELECT *
		   FROM agent 
		   NATURAL JOIN mission
		   NATURAL JOIN mission_gizmo
		   NATURAL JOIN mission_to_person
		   NATURAL JOIN person
		   WHERE agent_id IN
		   (SELECT agent_id 
		    FROM MISSION 
		    WHERE codename = ?)
		   /);

# use 'agent' template
my $bond = $dbh->fetch_agent("Bond");
$bond = $dbh->fetch_agent("mission.codename" => "goldfinger");

# use 'agent_by_mission' template
$bond = $dbh->fetch_agent_by_mission(codename => "goldfinger");


$dbh->disconnect;
