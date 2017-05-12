use ClearCase::Argv ':functional';

ClearCase::Argv->ctcmd(2);
ClearCase::Argv->dbglevel(1);
ClearCase::Argv->attropts;      # scan cmdline for CCArgv -/flags

my $cwv = ctqx('pwv -s');
chomp($cwv);
print "Current View is '$cwv'\n";
