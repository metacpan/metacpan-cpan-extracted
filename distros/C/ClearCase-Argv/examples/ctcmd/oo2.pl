use ClearCase::CtCmd 1.01;
my $ctc = ClearCase::CtCmd->new(outfunc=>0, errfunc=>0);
$ctc->exec('pwv', '-s');
