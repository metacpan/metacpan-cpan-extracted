# Based on the Business-OnlinePayment-AuthorizeNet tests by 
# Jason Kohles and/or Ivan Kohler.

sub test_account_or_skip {
  my ($login, $password) = test_account();
  if(!defined $login) {
    plan skip_all => "No test account";
  }
  return ($login, $password);
}

sub test_account {
  open TEST_ACCOUNT, 't/test_account' or return;
  my ($login, $password) = <TEST_ACCOUNT>;
  chomp ($login, $password);
  return ($login, $password);
}

1;
