package Business::OnlinePayment::AuthorizeNet;

use strict;
use Carp;
use Business::OnlinePayment;
use vars qw($VERSION @ISA $me);

@ISA = qw(Business::OnlinePayment);
$VERSION = '3.23';
$me = 'Business::OnlinePayment::AuthorizeNet';

sub set_defaults {
    my $self = shift;

    $self->build_subs(qw( order_number md5 avs_code cvv2_response
                          cavv_response
                     ));
}

sub _map_processor {
    my($self) = @_;

    my %content = $self->content();
    my %processors = ('recurring authorization'          => 'ARB',
                      'modify recurring authorization'   => 'ARB',
                      'cancel recurring authorization'   => 'ARB',
                     );
    $processors{lc($content{'action'})} || 'AIM';
}

sub submit {
    my($self) = @_;

    my $processor = $me. "::". $self->_map_processor();

    eval "use $processor";
    croak("unknown processor $processor ($@)") if $@;
    
    my $object = bless $self, $processor;
    $object->set_defaults();
    $object->submit();
    bless $self, $me;
}

1;
__END__

=head1 NAME

Business::OnlinePayment::AuthorizeNet - AuthorizeNet backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # One step transaction, the simple case.
  ####

  my $tx = new Business::OnlinePayment("AuthorizeNet");
  $tx->content(
      type           => 'VISA',
      login          => 'testdrive',
      password       => '', #password or transaction key
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jsk',
      email          => 'jason@example.com',
      first_name     => 'Jason',
      last_name      => 'Kohles',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      country        => 'US',
      card_number    => '4007000000027',
      expiration     => '09/02',
      cvv2           => '1234', #optional
      referer        => 'http://valid.referer.url/',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

  ####
  # Two step transaction, authorization and capture.
  # If you don't need to review order before capture, you can
  # process in one step as above.
  ####

  my $tx = new Business::OnlinePayment("AuthorizeNet");
  $tx->content(
      type           => 'VISA',
      login          => 'testdrive',
      password       => '',  #password or transaction key
      action         => 'Authorization Only',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jsk',
      email          => 'jason@example.com',
      first_name     => 'Jason',
      last_name      => 'Kohles',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      country        => 'US',
      card_number    => '4007000000027',
      expiration     => '09/02',
      cvv2           => '1234', #optional
      referer        => 'http://valid.referer.url/',
  );
  $tx->submit();

  if($tx->is_success()) {
      # get information about authorization
      $authorization = $tx->authorization
      $ordernum = $tx->order_number;
      $avs_code = $tx->avs_code; # AVS Response Code
      $cvv2_response = $tx->cvv2_response; # CVV2/CVC2/CID Response Code
      $cavv_response = $tx->cavv_response; # Cardholder Authentication
                                           # Verification Value (CAVV) Response
                                           # Code

      # now capture transaction
      my $capture = new Business::OnlinePayment("AuthorizeNet");

      $capture->content(
          type           => 'CC',
          action         => 'Post Authorization',
          login          => 'YOURLOGIN
          password       => 'YOURPASSWORD', #or transaction key
          order_number   => $ordernum,
          amount         => '49.95',
      );

      $capture->submit();

      if($capture->is_success()) { 
          print "Card captured successfully: ".$capture->authorization."\n";
      } else {
          print "Card was rejected: ".$capture->error_message."\n";
      }

  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

  ####
  # One step subscription, the simple case.
  ####

  my $tx = new Business::OnlinePayment("AuthorizeNet::ARB");
  $tx->content(
      type           => 'CC',
      login          => 'testdrive',
      password       => 'testpass', #or transaction key
      action         => 'Recurring Authorization',
      interval       => '7 days',
      start          => '2008-3-10',
      periods        => '16',
      amount         => '99.95',
      trialperiods   => '4',
      trialamount    => '0',
      description    => 'Business::OnlinePayment test',
      invoice_number => '1153B33F',
      customer_id    => 'vip',
      first_name     => 'Tofu',
      last_name      => 'Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'GA',
      zip            => '84058',
      card_number    => '4111111111111111',
      expiration     => '09/02',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->order_number."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }
  my $subscription = $tx->order_number


  ####
  # Subscription change.   Modestly more complicated.
  ####

  $tx->content(
      type           => 'CC',
      subscription   => '99W2C',
      login          => 'testdrive',
      password       => 'testpass', #or transaction key
      action         => 'Modify Recurring Authorization',
      interval       => '7 days',
      start          => '2008-3-10',
      periods        => '16',
      amount         => '29.95',
      trialperiods   => '4',
      trialamount    => '0',
      description    => 'Business::OnlinePayment test',
      invoice_number => '1153B340',
      customer_id    => 'vip',
      first_name     => 'Tofu',
      last_name      => 'Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'GA',
      zip            => '84058',
      card_number    => '4111111111111111',
      expiration     => '09/02',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Update processed successfully."\n";
  } else {
      print "Update was rejected: ".$tx->error_message."\n";
  }
  $tx->content(
      subscription   => '99W2D',
      login          => 'testdrive',
      password       => 'testpass', # or transaction key
      action         => 'Cancel Recurring Authorization',
  );
  $tx->submit();

  ####
  # Subscription cancellation.   It happens.
  ####

  if($tx->is_success()) {
      print "Cancellation processed successfully."\n";
  } else {
      print "Cancellation was rejected: ".$tx->error_message."\n";
  }


=head1 SUPPORTED TRANSACTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

Content required: type, login, password, action, amount, first_name, last_name, card_number, expiration.

=head2 Check

Content required: type, login, password, action, amount, first_name, last_name, account_number, routing_code, bank_name (non-subscription), account_type (subscription), check_type (subscription).

=head2 Subscriptions

Additional content required: interval, start, periods.

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 METHODS AND FUNCTIONS

See L<Business::OnlinePayment> for the complete list. The following methods either override the methods in L<Business::OnlinePayment> or provide additional functions.  

=head2 result_code

Returns the response reason code (from the message.code field for subscriptions).

=head2 error_message

Returns the response reason text (from the message.text field for subscriptions.

=head2 server_response

Returns the complete response from the server.

=head1 Handling of content(%content) data:

=head2 action

The following actions are valid

  normal authorization
  authorization only
  credit
  post authorization
  void
  recurring authorization
  modify recurring authorization
  cancel recurring authorization

=head2 interval

  Interval contains a number of digits, whitespace, and the units of days or months in either singular or plural form.
  

=head1 Setting AuthorizeNet ARB parameters from content(%content)

The following rules are applied to map data to AuthorizeNet ARB parameters
from content(%content):

      # ARB param => $content{<key>}
      merchantAuthentication
        name                     =>  'login',
        transactionKey           =>  'password',
      subscription
        paymentSchedule
          interval
            length               => \( the digits in 'interval' ),
            unit                 => \( days or months gleaned from 'interval' ),          startDate              => 'start',
          totalOccurrences       => 'periods',
          trialOccurrences       => 'trialperiods',
        amount                   => 'amount',
        trialAmount              => 'trialamount',
        payment
          creditCard
            cardNumber           => 'card_number',
            expiration           => \( $year.'-'.$month ), # YYYY-MM from 'expiration'
          bankAccount
            accountType          => 'account_type',
            routingNumber        => 'routing_code',
            accountNumber        => 'account_number,
            nameOnAccount        => 'name',
            bankName             => 'bank_name',
            echeckType           => 'check_type',
        order
          invoiceNumber          => 'invoice_number',
          description            => 'description',
        customer
          type                   => 'customer_org',
          id                     => 'customer_id',
          email                  => 'email',
          phoneNumber            => 'phone',
          faxNumber              => 'fax',
          driversLicense
            number               => 'license_num',
            state                => 'license_state',
            dateOfBirth          => 'license_dob',
          taxid                  => 'customer_ssn',
        billTo
          firstName              => 'first_name',
          lastName               => 'last_name',
          company                => 'company',
          address                => 'address',
          city                   => 'city',
          state                  => 'state',
          zip                    => 'zip',
          country                => 'country',
        shipTo
          firstName              => 'ship_first_name',
          lastName               => 'ship_last_name',
          company                => 'ship_company',
          address                => 'ship_address',
          city                   => 'ship_city',
          state                  => 'ship_state',
          zip                    => 'ship_zip',
          country                => 'ship_country',

=head1 NOTES

Use your transaction key in the password field.

Unlike Business::OnlinePayment or pre-3.0 versions of
Business::OnlinePayment::AuthorizeNet, 3.1 requires separate first_name and
last_name fields.

Business::OnlinePayment::AuthorizeNet uses Authorize.Net's "Advanced
Integration Method (AIM) (formerly known as ADC direct response)" and
"Automatic Recurring Billing (ARB)", sending a username and password (or
transaction key as password) with every transaction.  Therefore,
Authorize.Net's referrer "security" is not necessary.  In your Authorize.Net
interface at https://secure.authorize.net/ make sure the list of allowable
referers is blank.  Alternatively, set the B<referer> field in the transaction
content.

To settle an authorization-only transaction (where you set action to
'Authorization Only'), submit the nine-digit transaction id code in
the field "order_number" with the action set to "Post Authorization".
You can get the transaction id from the authorization by calling the
order_number method on the object returned from the authorization.
You must also submit the amount field with a value less than or equal
to the amount specified in the original authorization.

For the subscription actions an authorization code is never returned by
the module.  Instead it returns the value of subscriptionId in order_number.
This is the value to use for changing or cancelling subscriptions.

Authorize.Net has turned address verification on by default for all merchants
since 2002.  If you do not have valid address information for your customer
(such as in an IVR application), you must disable address verification in the
Merchant Menu page at https://secure.authorize.net/ so that the transactions
aren't denied due to a lack of address information.

=head1 COMPATIBILITY

This module implements Authorize.Net's API using the Advanced Integration
Method (AIM) version 3.1, formerly known as ADC Direct Response and the 
Automatic Recurring Billing version 1.0 using the XML interface.  See
http://www.authorize.net/support/AIM_guide.pdf and http://www.authorize.net/support/ARB_guide.pdf for details.

=head1 AUTHORS

Original author: Jason Kohles, jason@mediabang.com

Ivan Kohler <ivan-authorizenet@freeside.biz> updated it for Authorize.Net
protocol 3.0/3.1 and is the current maintainer.  Please see the next section
for for information on contributing.

Jason Spence <jspence@lightconsulting.com> contributed support for separate
Authorization Only and Post Authorization steps and wrote some docs.
OST <services@ostel.com> paid for it.

Jeff Finucane <authorizenetarb@weasellips.com> added the ARB support.
ARB support sponsored by Plus Three, LP. L<http://www.plusthree.com>.

T.J. Mather <tjmather@maxmind.com> sent a number of CVV2 patches.

Mike Barry <mbarry@cos.com> sent in a patch for the referer field and a fix for
ship_company.

Yuri V. Mkrtumyan <yuramk@novosoft.ru> sent in a patch to add the void action.

Paul Zimmer <AuthorizeNetpm@pzimmer.box.bepress.com> sent in a patch for
card-less post authorizations.

Daemmon Hughes <daemmon@daemmonhughes.com> sent in a patch for "transaction
key" authentication as well support for the recurring_billing flag and the md5
method that returns the MD5 hash which is returned by the gateway.

Steve Simitzis contributed a patch for better compatibility with
eProcessingNetwork's AuthorizeNet compatibility mode.

Michael G. Schwern contributed cleanups, test fixes, and more.

Erik Hollensbe implemented card-present data (track1/track2), the
duplicate_window parameter, and test fixes.

Paul Timmins added the check_number field.

Nate Nuss implemented the ("Additional Shipping Information (Level 2 Data)"
fields: tax, freight, duty, tax_exempt, po_number.

Michael Peters fixed a bug in email address handling.

Thomas Sibley <trs@bestpractical.com> wrote B:OP:AuthorizeNet::AIM::ErrorCodes
which was borged and used to provide more descriptive error messages.

Craig Pearlman <cpearlma@yahoo.com> sent in a patch to more accurately declare
required fields for E-check transcations.

=head1 CONTRIBUTIONS AND REPOSITORY

Please send patches as unified diffs (diff -u) to (in order of preference):

=over 4

=item CPAN RT

http://rt.cpan.org/Public/Bug/Report.html?Queue=Business-OnlinePayment-AuthorizeNet

=item The bop-devel mailing list

http://420.am/cgi-bin/mailman/listinfo/bop-devel

=item Ivan

Ivan Kohler <ivan-authorizenet@freeside.biz>

=back

The code is available from our public git repository:

  git clone git://fit.freeside.biz/Business-OnlinePayment-AuthorizeNet.git

Or on the web:

  http://freeside.biz/gitweb/?p=Business-OnlinePayment-AuthorizeNet.git

=head1 A WORD FROM OUR SPONSOR

This module and the Business::OnlinePayment framework are maintained by by
Freeside Internet Services.  If you need a complete, open-source web-based
application to manage your customers, billing and trouble ticketing, please
visit http://freeside.biz/

=head1 COPYRIGHT & LICENSE

Copyright 2010-2015 Freeside Internet Services, Inc.
Copyright 2008 Thomas Sibley
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

