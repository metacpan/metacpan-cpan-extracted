BEGIN { $| = 1; print "1..2\n"; }

use Business::OnlinePayment;

for my $testnum ( 1 .. 2 ) {
  &run_xaction($testnum);
}

sub run_xaction {

  my $testnum = shift;

  my $tx = new Business::OnlinePayment("StGeorge",
  #  'cert_path'   => './java.cert',
    'cert_path'   => '/home/ivan/Business-OnlinePayment-StGeorge/t2/java.cert',
  );

  $tx->content(
      login          => '10005432',
      password       => 'certphrase',
      type           => 'CC',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment::LinkPoint visa test',
      amount         => '1.00',
      first_name     => 'Tofu',
      last_name      => 'Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      country        => 'US',
      email          => 'ivan-stgeorge@420.am',
      card_number    => '4564456445644564',
      expiration     => '12/2005',
  );

  $tx->test_transaction(1);

  $tx->submit();

  if($tx->is_success()) {
      print "ok $testnum\n";
      $auth = $tx->authorization;
      warn "********* $auth ***********\n";
  } else {
      print "not ok $testnum\n";
      warn '***** '. $tx->error_message. " *****\n";
      exit;
  }

}

