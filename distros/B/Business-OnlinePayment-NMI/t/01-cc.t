use Test::More tests => 6;

use Business::OnlinePayment;

my %defaults = (
  name       => 'Joe Tester',
  address    => '888',
  city       => 'Nowhere',
  state      => 'CA',
  zip        => '77777',
  phone      => '510-555-0021',
  email      => 'joe@example.com',
  description => 'Business::OnlinePayment::NMI Test',

  action     => 'Normal Authorization',
  card_number => '5431111111111111',
  expiration => '10/10',
  amount     => '12.00',
  );

# SALE
my %content = %defaults;
my $ordernum = ok_test(\%content, 'credit card sale');

# REFUND
%content = ( 
  action => 'Credit', 
  order_number => $ordernum,
  amount => '6.00',
);
ok_test(\%content, 'credit card refund');

# AUTH/CAPTURE
%content = %defaults;
$content{'action'} = 'Authorization Only';
$ordernum = ok_test(\%content, 'credit card auth');

%content = (
  action => 'Post Authorization',
  order_number => $ordernum,
  amount => '12.00',
);
ok_test(\%content, 'credit card capture');

#VOID
%content = (
  action => 'Void',
  order_number => $ordernum,
);
ok_test(\%content, 'credit card void');

#FAILURE
%content = %defaults;
$content{amount} = '0.10'; # amounts < 1.00 are declined on the demo account
$content{fail} = 1;
ok_test(\%content, 'credit card decline');

sub ok_test {
  my ($content, $label) = @_;
  my $fail = delete $content{fail} or 0;
  my $trans = new Business::OnlinePayment('NMI');
  $trans->content(
    login    => 'demo',
    password => 'password',
    type     => 'CC',
    %$content
  );
  $trans->submit;
  diag($trans->error_message) if (!$fail and $trans->error_message);
  if($fail) {
    ok(!$trans->is_success, $label)
  }
  else {
    ok($trans->is_success, $label);
  }
  return $trans->order_number;
}

1;
