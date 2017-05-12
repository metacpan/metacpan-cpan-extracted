use ClearCase::ClearPrompt qw(clearprompt);
my $rc = clearprompt(qw(yes_no -type ok -pref -pro), "Choose any response");
exit $rc;
