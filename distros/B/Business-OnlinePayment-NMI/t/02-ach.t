use Test::More tests => 3;

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
  account_number => '222223333344', # meaningless
  routing_code => '411151111',
  amount     => '13.00',
  );

# SALE
my %content = %defaults;
my $ordernum = ok_test(\%content, 'echeck sale');

#VOID
%content = (
  action => 'Void',
  order_number => $ordernum,
);
ok_test(\%content, 'echeck void');

#FAILURE
%content = %defaults;
$content{amount} = '0.10'; # amounts < 1.00 are declined on the demo account
$content{fail} = 1;
ok_test(\%content, 'echeck decline');

sub ok_test {
  my ($content, $label) = @_;
  my $fail = delete $content{fail} or 0;
  my $trans = new Business::OnlinePayment('NMI');
  $trans->content(
    login    => 'demo',
    password => 'password',
    type     => 'echeck',
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
