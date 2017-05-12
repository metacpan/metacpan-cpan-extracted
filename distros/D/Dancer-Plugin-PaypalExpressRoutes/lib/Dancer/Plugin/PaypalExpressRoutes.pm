package Dancer::Plugin::PaypalExpressRoutes;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::Database;
use Business::PayPal::API::ExpressCheckout;

use strict;

  our $VERSION = '0.12';

  my $settings = plugin_setting() || undef;

  my ($pp,%ppresponse,%ppdetails,%ppresult,$pptoken,$payerid,$customer_email,$country,$zip);

  my ($order_total,$subtotal,$shipping,$currency_code,$sandbox,$opt,$flash);

register ppsetrequest => sub {

		($order_total,$opt) = @_;
		$order_total ||= session('total_cost') || '0';
		$currency_code = $opt->{'currency_code'} || session('currency_code') || setting('currency_code') || 'USD';
		$sandbox = $opt->{'sandbox'} || '0'; # set to '1' to use
		
		my $id = $settings->{'pp_id'} || $opt->{'id'} || '';
		my $password = $settings->{'pp_password'} || $opt->{'password'} || '';
		my $signature = $settings->{'pp_signature'} || $opt->{'signature'} || '';
		my $returnurl = $settings->{'pp_returnurl'} || $opt->{'returnurl'} || '';
		my $cancelurl = $settings->{'pp_cancelurl'} || $opt->{'cancelurl'} || '';
		
		if (! length $order_total) {
		my $msg = set_flash('We need an order total if we are to proceed');
		return($msg)
		}
	$pp = new Business::PayPal::API::ExpressCheckout (
			  Username  => $id,
			  Password  => $password,
			  Signature => $signature,
			  sandbox   => $sandbox 
			  );

	 %ppresponse = $pp->SetExpressCheckout ( 
	             OrderTotal    => $order_total,  
                 currencyID    => $currency_code, 
                 ReturnURL     => $returnurl,
                 CancelURL     => $cancelurl, 
                 );
   $pptoken = $ppresponse{Token};
   
  return redirect '/paypalcheckout' unless length $pptoken;
  
  my $redirecturl = $settings->{'paypal_redirecturl'} || "https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout";
	 $redirecturl .= "&token=$ppresponse{Token}";

  return redirect $redirecturl if $ppresponse{Token};

};

register ppgetrequest => sub {
  $pptoken ||= '';
  $pp ||= '';
 
	return redirect '/checkout' unless $pptoken && $pp;
 
   %ppdetails = $pp->GetExpressCheckoutDetails( $pptoken ); 
          
  session 'phone'        => $ppdetails{ContactPhone} || '';
  session 'email'        => $ppdetails{Payer} || '';          
  session 'first_name'   => $ppdetails{FirstName} || '';
  session 'last_name'    => $ppdetails{LastName} || '';
  session 'company'      => $ppdetails{PayerBusiness} || '';
  session 'address1'     => $ppdetails{Street1} || '';
  session 'address2'     => $ppdetails{Street2} || '';
  session 'city'         => $ppdetails{CityName} || '';
  session 'state'        => $ppdetails{StateOrProvince} || '';
  session 'postcode'     => $ppdetails{PostalCode} || '';
  session 'country_code' => $ppdetails{Country} || '';
  session 'country_name' => $ppdetails{CountryName} ||= database->quick_lookup('country', { code => $ppdetails{Country} }, 'name' ) || '';
  
  session 'pp_correlationid'  => $ppdetails{CorrelationID} || '';
  session 'pp_payerid'        => $ppdetails{PayerID} || '';
  session 'pp_payer_status'   => $ppdetails{PayerStatus} || '';    
  session 'pp_address_status' => $ppdetails{AddressStatus} || '';
  session 'pp_name'           => $ppdetails{Name} || '';
  session 'pp_custom'         => $ppdetails{Custom} || '';   
  
  session 'payment_method' => 'Paypal';
  
  $customer_email = $ppdetails{Payer} || '';
  
  $payerid = $ppdetails{PayerID};
  
  $country = $ppdetails{Country};
  $zip = $ppdetails{PostalCode};
  
	return(\%ppdetails);

};

register getppdetails => sub {
	return(\%ppdetails)
};

register ppdorequest  => sub {
	   $order_total = shift || params->{'total_cost'} || '0';
	   $payerid ||= session('pp_payerid');

	   if (!$pptoken or !$order_total) {
		set_flash('The Paypal token has expired - please go to Paypal again. Apologies');
	  return redirect '/checkout';
	  }

	  %ppresult = $pp->DoExpressCheckoutPayment ( 
	                   Token         => $pptoken,
                       PaymentAction => 'Sale',
                       PayerID       => $payerid,
                       OrderTotal    => $order_total,
                       currencyID    => $currency_code,
                       );

  session 'pp_final_token'     => $ppresult{Token};        
  session 'pp_transactionid'   => $ppresult{TransactionID};
  session 'pp_transactiontype' => $ppresult{TransactionType};
  session 'pp_paymenttype'     => $ppresult{PaymentType};
  session 'pp_paymentdate'     => $ppresult{PaymentDate};
  session 'pp_grossamount'     => $ppresult{GrossAmount};
  session 'pp_feeamount'       => $ppresult{FeeAmount};
  session 'pp_settleamount'    => $ppresult{SettleAmount};
  session 'pp_taxamount'       => $ppresult{TaxAmount};
  session 'pp_exchangerate'    => $ppresult{ExchangeRate};
  session 'pp_paymentstatus'   => $ppresult{PaymentStatus};
  session 'pp_pendingreason'   => $ppresult{PendingReason};

    if ($ppresult{Token}) {
    return('success');
		  }
	else {
	my $msg = set_flash('There was an error at Paypal');
	return($msg);
	}	 
};

register getppresult => sub {
	return(\%ppresult);
};	

register_plugin;

=head1 NAME 

         Dancer::Plugin::PaypalExpressRoutes
         
=head1 VERSION
  
  Version 0.12, April 2014
  
=head1 CHANGES

  v 0.12: updated installation files

=head1 DESCRIPTION

This is a Dancer interface for Business::PayPal::API::ExpressCheckout. It 
calls ExpressCheckout with the three requests involved in a transaction, 
and also makes available the customer data and transaction data returned
in hashes from Paypal for possible use on a receipt page or logging. 

=head1 CONFIGURATION

Your config.yml would contain something like this:

	  plugins:
			PaypalExpressRoutes:
			  pp_id: xxx
			  pp_password: xxx
			  pp_signature: xxx
			  pp_returnurl: http://mysite.tld/paypalgetrequest
			  pp_cancelurl: http://mysite.tld

=head1 FUNCTIONS

Your site.pm would include:

	use Dancer::Plugin::PaypalExpressRoutes;

and the following routes:

    post '/paypalsetrequest' => sub {
	     $pptotal = params->{'total_cost'}; # or your method
	     ppsetrequest( $pptotal );
     };

This will transfer the customer to the Paypal site. When he hits the 'confirm'
button, Paypal will invoke the configured return url which will invoke the 
next route:

    get '/paypalgetrequest' => sub {
       ppgetrequest(); 
	   return redirect '/paypalcheckout'; # or your preferred page
     };

The paypalcheckout page should include whatever data you want the customer to
see before finalising the order. Optionally you may populate the page with 
the details hash returned from the previous request, eg [% details.FirstName %]
and so on, as found in the ppgetrequest() sub above.

     get '/paypalcheckout' => sub {
       template 'checkout/paypalcheckout', {
    	   $details = getppdetails(), # customer details
		   # order details
		  }
      };

The 'finalise order' button should then invoke the following route:

    post '/paypaldorequest' => sub  {
	
		my $ok = ppdorequest( $pp_order_total );

		if ($ok eq 'success') {
		# complete order process
		return  redirect  '/paypalreceipt'; 
			}
		else {
		  # some sort of error message or page
		}
		
		return redirect '/checkout' if ! $ppresult{Token};
                                           
	};

And this then invokes the final route to display the receipt:

     get '/paypalreceipt' => sub {
	    return template 'checkout/paypalreceipt', {
    	   $details = getppdetails(), # customer details
		   # other details to display
		   }
     };

=head1 CONVENIENCE FUNCTIONS

	getppdetails(); 
	
will access all customer data returned in the details hash 
from the 'ppgetrequest' upon the customer returning from Paypal

	getppresult(); 
	
will access all the transaction data in the results hash returned 
from the 'ppdorequest' finalising the transaction.

=head1 AUTHOR

Lyn St George, lyn@zolotek.net

=head1 LICENCE AND COPYRIGHT

Copyright Lyn St George

This module is free software and is published under the same
terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
