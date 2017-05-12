sub test_account {
#  'login' => 'yCaWGYQsSVR0S48B6AKMK07RQhaxHvGu', #test platform
  'login' => 'tSfl065j5F1Z5Uw7jQ2i69z9sd30A6k1',
  'password' => '5432',
}

sub expiration_date {
    my($month, $year) = (localtime)[4,5];
    $month += 1;
    $year++;       # So we expire next year.
    $year %= 100;  # y2k?  What's that?

    return sprintf("%02d/%02d", $month, $year);
}

1;
