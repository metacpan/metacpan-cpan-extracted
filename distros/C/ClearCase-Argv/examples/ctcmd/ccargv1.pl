use ClearCase::Argv;

ClearCase::Argv->ctcmd(2);

my $ct = ClearCase::Argv->new;

my $rc = $ct->pwv->system;

exit $rc;
