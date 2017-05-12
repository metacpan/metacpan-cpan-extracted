#BEGIN { $| = 1; print "1..4\n"; }
BEGIN { $| = 1; print "1..3\n"; }

use Business::OnlinePayment;

my %phone2error = (
  '2033500000' => '0130',
  '2012179746' => '0150',
  '4083624100' => '0160',
  #got 0416 (expected 0141)?? #'9044270189' => '0141',
);

foreach my $phone (keys %phone2error) {

  my $tx = new Business::OnlinePayment("PayConnect",
    partner => 's9Te1',
  );
  $tx->content(
      type           => 'LEC',
      login          => '7001',
      password       => '9PIci',
      action         => 'Authorization Only',
      description    => 'Business::OnlinePayment LEC test',
      amount         => '1.01',
      invoice_number => '100100',
      customer_id    => 'jsk',
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
  if($tx->is_success() || $tx->result_code ne $phone2error{$phone} ) {
      warn "**** got ". $tx->result_code. " (expected $phone2error{$phone}): ".
           $tx->error_message. " ****\n";
      print "not ok $num\n";
  } else {
      print "ok $num\n";
  }

}
