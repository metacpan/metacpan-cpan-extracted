use ClearCase::ClearPrompt qw(clearprompt /TRIGGERSERIES);

$ENV{CLEARCASE_SERIES_ID} = 'a1:b2:c3:d4';

for my $seq (1..3) {
    $ENV{CLEARCASE_BEGIN_SERIES} = $seq == 1;
    $ENV{CLEARCASE_END_SERIES} =   $seq == 3;

    my @testx = qw(text -pref -prompt);
    my $msgx = qq(Testing trigger series with text prompt

    Please type some characters at the prompt:);
    my $data = clearprompt(@testx, $msgx);
    $data =~ s/"/'/g if MSWIN;
    print qq(At text prompt #$seq you entered '$data'.\n);

    my $rc = clearprompt(qw(yes_no -type ok -pref -pro),
						    "Choose any response");
    my $resp = qw(Yes No Abort)[$rc];
    print qq(At proceed prompt #$seq you entered '$resp'.\n);
}
