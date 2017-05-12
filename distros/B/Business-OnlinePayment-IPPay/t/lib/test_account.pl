sub test_account_or_skip {
    my $suffix = shift;
    my($login, $password, %opt) = test_account($suffix);

    unless( defined $login ) {
        plan skip_all => "No test account";
    }

    return($login, $password, %opt);
}

sub test_account {
    my $suffix = shift || 'card';

    my($login, $password) = ('TESTTERMINAL', '');

    my %opt;
    if ( $suffix eq 'check ' ) {
      %opt = ('Origin' => 'RECURRING');
    } else {
      %opt = ('default_Origin' => 'RECURRING');
    }

    return($login, $password, %opt);
}

sub expiration_date {
    my($month, $year) = (localtime)[4,5];
    $month += 1;
    $year++;       # So we expire next year.
    $year %= 100;  # y2k?  What's that?

    return sprintf("%02d/%02d", $month, $year);
}

#sub tomorrow {
#    my($day, $month, $year) = (localtime(time+86400))[3..5];
#    return sprintf("%04d-%02d-%02d", $year+1900, ++$month, $day);
#}

1;

