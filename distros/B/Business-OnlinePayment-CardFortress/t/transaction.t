use Test::More tests => 4;
use File::Slurp;
use Business::OnlinePayment;

my @opt = (
  'CardFortress',
    'gateway' => 'IPPay',
    'gateway_login' => 'TESTMERCHANT',
    'gateway_password' => '',,
);

my $tx = new Business::OnlinePayment(@opt);

$tx->test_transaction(1);

$tx->content(
    type           => 'VISA',
    login          => 'user',
    password       => 'secret',
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment test',
    amount         => '49.95',
    customer_id    => 'tfb',

    #have to specify both for now... maybe some auto-transforming later
    name           => 'Tofu Beast',
    first_name     => 'Tofu',
    last_name      => 'Beast',

    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    card_number    => '4007000000027',
    expiration     => '09/22',
    cvv2           => '1234', #optional (not stored)
);
$tx->submit();

ok($tx->is_success, 'Transaction successful');
warn $tx->error_message."\n" unless $tx->is_success;

#use Data::Dumper; warn Dumper($tx);

my $token = $tx->card_token;
ok(length($token), 'Token returned');


SKIP: {
  my $private_key = read_file('t/private_key.txt') or skip 'no private key', 2;

  like( $private_key, qr/-----BEGIN RSA PRIVATE KEY-----/, 'private key good' );

  my $rx = new Business::OnlinePayment( @opt,
                                        'private_key' => $private_key,
                                      );

  $rx->test_transaction(1);

  $rx->content(
      type           => 'VISA',
      login          => 'user',
      password       => 'secret',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '12.95',
      #card_token     => $token
      card_number     => $token,
  );
  $rx->submit();

  ok($rx->is_success, 'Token transaction successful');

  #use Data::Dumper; warn Dumper($rx);

}

