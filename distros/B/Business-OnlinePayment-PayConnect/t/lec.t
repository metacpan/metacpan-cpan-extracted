BEGIN { $| = 1; print "1..2\n"; }

use Business::OnlinePayment;

foreach my $phone (qw( 4082435901 8107926049 )) {

  my $tx = new Business::OnlinePayment("PayConnect",
    partner => 's9Te1',
  );
  $tx->content(
      type           => 'LEC',
      login          => '7001',
      password       => '9PIci',
      action         => 'Authorization Only',
      description    => 'Business::OnlinePayment LEC test',
      amount         => '1.00',
      invoice_number => '100100',
      customer_id    => 'jsk',
      name           => 'Tofu Beast',
      first_name     => 'Tofu',
      last_name      => 'Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      phone          => $phone,
  );
  $tx->test_transaction(1); # test, dont really charge (NOP for this gateway)
  $tx->submit();

  $num++;
  if($tx->is_success()) {
      print "ok $num\n";
  } else {
      warn "*******". $tx->error_message. "*******";
      print "not ok $num\n";
  }

}
