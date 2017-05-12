# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Business::Cashcow;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print &Business::Cashcow::InitCashcow("abcd", "test") ? "ok 2\n" : "not ok 2\n";
my $transaction = {
          'card_expirymonth' => 11,
          'result_ticket' => '',
          'card_number' => '5413036820085953',
          'result_approval' => '',
          'merchant_zip' => '2100 OE',
          'merchant_country' => 'DNK',
          'cashcow' => '',
          'merchant_city' => 'Koebenhavn',
          'card_expiryyear' => '0',
          'transaction_currency' => 208,
          'merchant_name' => 'Enterprise Advertising A/S',
          'transaction_reference' => 99910326,
          'merchant_region' => '',
          'merchant_address' => 'Aarhusgade 108E, 3.',
          'transaction_amount' => '7.25',
          'merchant_number' => 2133334,
          'merchant_terminalid' => 'INET01',
          'result_action' => '0',
          'merchant_poscode' => '0'
        };
use Data::Dumper;
print Dumper(&Business::Cashcow::RequestAuth($transaction,$ticket,"mykey"));
print Dumper($ticket);
print Dumper(&Business::Cashcow::RequestCapture($ticket,"mykey",7.25));
