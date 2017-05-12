use ClearCase::Argv;

ClearCase::Argv->ctcmd(2);
ClearCase::Argv->dbglevel(1);

my $ct = ClearCase::Argv->new;
$ct->autochomp(1);

my $cwv = $ct->pwv('-s')->qx;
print "Current View is '$cwv'\n";
