#!/usr/bin/perl
use Data::Dumper;
use Business::OnlinePayment;
$\ = "\n";

# This script is used to run a series of prescribed transactions, in order to certify the application

$login = {'login'       => '...',     # info for test account
          'password'    => '...',
          'serial'      => '...',
         };

$cards = {
          'visa'       => {'cc'  => '4003000123456781',
                           'exp' => '10/04',
                          },
          'mastercard' => {'cc'  => '5454545454545454',
                           'exp' => '08/04',
                          },
          'amex'       => {'cc'  => '371449635398431',
                           'exp' => '05/12',
                          },
          'discover'   => {'cc'  => '6011901165142939',
                           'exp' => '01/05',
                           },
          'diners'     => {'cc'  => '36438999960016',
                           'exp' => '05/12',
                          },
          'jcb'        => {'cc'  => '3566002020360224',
                           'exp' => '10/04',
                          },
         };

@tests = (
          {
           'action'        => 'Normal Authorization',
           'entry_method'  => 'Swipe',
           'card_number'   => $cards->{'visa'}->{'cc'},
           'expiration'    => $cards->{'visa'}->{'exp'},
           'amount'        => '1.31',
          },
          {
           'action'        => 'Normal Authorization',
           'entry_method'  => 'Manual',
           'card_number'   => $cards->{'visa'}->{'cc'},
           'expiration'    => $cards->{'visa'}->{'exp'},
           'amount'        => '1.32',
           'cvv2'          => '412',
           'street'        => '652',
          },
          {
           'action'        => 'Normal Authorization',
           'entry_method'  => 'Swipe',
           'card_number'   => $cards->{'mastercard'}->{'cc'},
           'expiration'    => $cards->{'mastercard'}->{'exp'},
           'amount'        => '1.33',
          },
          {
           'action'        => 'Normal Authorization',
           'entry_method'  => 'Manual',
           'card_number'   => $cards->{'amex'}->{'cc'},
           'expiration'    => $cards->{'amex'}->{'exp'},
           'amount'        => '1.34',
           'street'        => '1234',
           'zip'           => '35289',
          },
          {
           'action'        => 'Normal Authorization',
           'entry_method'  => 'Manual',
           'card_number'   => $cards->{'diners'}->{'cc'},
           'expiration'    => $cards->{'diners'}->{'exp'},
           'amount'        => '1.35',
          },
          {
           'action'        => 'Credit',
           'entry_method'    => 'Swipe',
           'card_number'   => $cards->{'visa'}->{'cc'},
           'expiration'    => $cards->{'visa'}->{'exp'},
           'amount'        => '1.36',
          },
          {
           'action'        => 'Credit',
           'entry_method'  => 'Manual',
           'card_number'   => $cards->{'amex'}->{'cc'},
           'expiration'    => $cards->{'amex'}->{'exp'},
           'amount'        => '1.37',
           'street'        => '62347',
           'zip'           => '3A45E2',   # weird, but ok...
          },
          {
           'action'        => 'Credit',
           'entry_method'  => 'Swipe',
           'card_number'   => $cards->{'discover'}->{'cc'},
           'expiration'    => $cards->{'discover'}->{'exp'},
           'amount'        => '1.38',
          },
          {
           'action'        => 'Void',
           'entry_method'  => 'Swipe',
           'card_number'   => $cards->{'discover'}->{'cc'},
           'expiration'    => $cards->{'discover'}->{'exp'},
           'amount'        => '1.38',
          },
          {
           'action'        => 'Post Authorization',
           'entry_method'  => 'Swipe',
           'card_number'   => $cards->{'visa'}->{'cc'},
           'expiration'    => $cards->{'visa'}->{'exp'},
           'amount'        => '1.39',
           'authorization' => 'AE34BH',
          },
          {
           'action'        => 'Post Authorization',
           'entry_method'  => 'Manual',
           'card_number'   => $cards->{'amex'}->{'cc'},
           'expiration'    => $cards->{'amex'}->{'exp'},
           'amount'        => '1.40',
           'authorization' => '112233',
          },
          {
           'action'        => 'Void',
           'entry_method'  => 'Manual',
           'card_number'   => $cards->{'amex'}->{'cc'},
           'expiration'    => $cards->{'amex'}->{'exp'},
           'amount'        => '1.40',
           'authorization' => '112233',
          },
          {
           'action'        => 'Authorization Only',
           'entry_method'  => 'Swipe',
           'card_number'   => $cards->{'visa'}->{'cc'},
           'expiration'    => $cards->{'visa'}->{'exp'},
           'amount'        => '0.00',
           'authorization' => '',
           'cvv2'          => '',
           'street'        => '',
           'zip'           => '',
          },
          {
           'action'        => 'Authorization Only',
           'entry_method'  => 'Manual',
           'card_number'   => $cards->{'mastercard'}->{'cc'},
           'expiration'    => $cards->{'mastercard'}->{'exp'},
           'amount'        => '1.41',
           'cvv2'          => '843',
          },
          {
           'action'        => 'Normal Authorization',
           'entry_method'  => 'Swipe',
           'card_number'   => $cards->{'visa'}->{'cc'},
           'expiration'    => $cards->{'visa'}->{'exp'},
           'amount'        => '14120.49',
          },
         );

$time = localtime;
print $time;

LOOP:
foreach $test (@tests)
{
#  print '----------'

  my $tx = new Business::OnlinePayment("iAuthorizer");
  $test->{'entry_method'} = 'Manual';

  $tx->content(%{$test}, %{$login});
  $tx->submit();

#  unless($tx->is_success)            # uncomment for some debug output
#  {
#   print Dumper($test);
#   print Dumper({$tx->content()});
#   print $tx->server_response();
#   print $tx->error_message();
#  }
#  else
#  {
   print $tx->server_response();
#  }
}

$time = localtime;
print $time;

