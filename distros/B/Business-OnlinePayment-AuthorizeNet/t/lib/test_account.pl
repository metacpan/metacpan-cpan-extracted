sub test_account_or_skip {
    my $suffix = shift;
    my($login, $password) = test_account($suffix);

    unless( defined $login ) {
        plan skip_all => "No test account";
    }

    return($login, $password);
}

sub test_account {
    my $suffix = shift || '';
    $suffix = "_$suffix" if $suffix;
    open TEST_ACCOUNT, "t/test_account$suffix" or return;
    my($login, $password) = <TEST_ACCOUNT>;
    chomp $login;
    chomp $password;

    return($login, $password);
}

sub expiration_date {
    my($month, $year) = (localtime)[4,5];
    $month += 1;
    $year++;       # So we expire next year.
    $year %= 100;  # y2k?  What's that?

    return sprintf("%02d/%02d", $month, $year);
}

sub tomorrow {
    my($day, $month, $year) = (localtime(time+86400))[3..5];
    return sprintf("%04d-%02d-%02d", $year+1900, ++$month, $day);
}

1;
