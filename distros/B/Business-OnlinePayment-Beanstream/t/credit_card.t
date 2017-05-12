use strict;
use Test::More tests=>2;
use constant DEBUG => 0;

use Business::OnlinePayment;

my $login = 'placeholder';  # Put your merchant ID here
                            # Configure your merchant account in test mode.

SKIP:   # skip attempts at connecting unless merchant ID specified
{

   if ($login eq 'placeholder')  {
      skip('you must specify your merchant ID in order to connect', 2);
   }
   my $trans = Business::OnlinePayment->new('Beanstream');

# 1. We will try to connect to beanstream server and post faked data.
#    Expect declined.

   $trans->content(
		   login          => $login,
		   action         => 'Normal Authorization',
		   amount         => '1.99',
		   invoice_number => '56647',
		   owner          => 'John Doe',
		   card_number    => '4003050500040005',
		   exp_date       => '12/12',
		   name           => 'Sam Shopper',
		   address        => '123 Any Street',
		   city           => 'Los Angeles',
		   state          => 'CA',
		   zip            => '23555',
		   country        => 'US',
		   phone          => '123-4567',
		   email          => 'Sam@shopper.com',
		   requestType    => 'BACKEND',
		   );

   $trans->submit();
   print STDERR $trans->error_message(),"\n" if DEBUG; 
   ok(!$trans->is_success);

# 2. We will try to connect to beanstream server and post a correct data.
#    Test transaction should succeed, with server in TEST mode.

   $trans->content(
		   login          => $login,
		   action         => 'Normal Authorization',
		   amount         => '1.99',
		   invoice_number => '56647',
		   owner          => 'John Doe',
		   card_number    => '4030000010001234',
		   exp_date       => '12/12',
		   name           => 'Sam Shopper',
		   address        => '123 Any Street',
		   city           => 'Los Angeles',
		   state          => 'CA',
		   zip            => '23555',
		   country        => 'US',
		   phone          => '123-4567',
		   email          => 'Sam@shopper.com',
		   requestType    => 'BACKEND',
		   );

   $trans->submit();
   if (DEBUG){
      if ($trans->is_success) {
	 print STDERR "\n",$trans->authorization(),"\n"; 
      } else {
	 print STDERR "\n",$trans->error_message(),"\n"; 
      }
   }
   ok($trans->is_success);

}
