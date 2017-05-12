# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-OnlinePayment-Exact.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
use Term::ReadLine;
BEGIN { use_ok('Business::OnlinePayment::Exact') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $term = new Term::ReadLine 'E-Xact Test';
diag("Please enter a test account for E-Xact");
my $prompt = "ExactID: ";
my $login = $term->readline($prompt);
diag("Please enter the password for the test account $login");
$prompt = "Password: ";
my $pass = $term->readline($prompt);
diag("Please enter a valid credit card to test (it will not be charged)");
$prompt = "Card Number: ";
my $card = $term->readline($prompt);
diag("Please enter an expiry date for the card in the form MMYY");
$prompt = "Expiry: ";
my $expiry = $term->readline($prompt);
diag("Please enter a name to match the card");
$prompt = "Name: ";
my $name = $term->readline($prompt);

my $tx;
ok($tx = new Business::OnlinePayment('Exact'), 'New Exact');
ok($tx->content(
    amount => '9.95',
    card_number => $card,
    expiration => $expiry,
    name => $name,
    action => 'normal authorization',
    login => $login,
    password => $pass,
    referer => 'Business::OnlinePayment::Exact testing',
    ),
    'Add Some Content');

ok($tx->submit(), 'submit');
ok($tx->is_success(), 'Success!!!');
my $auth;
ok($auth = $tx->authorization(), "authorization $auth");
my $err;
ok($err = $tx->error_message(), "error $err");
my $on;
ok($on = $tx->order_number(), "order number $on");


