##############################################################################
# Business::OnlinePayment::iTransact
#
# Credit card transactions via iTransact's XML API Connection
#
# Refer to iTransact's documentation for more info
# https://itransact.com/support/toolkit/xml-connection/api/
#
# AUTHOR
#
# Bill Gerrard <bill@gerrard.org>
#
# BUSINESS::ONLINEPAYMENT IMPLEMENTATION
#
# Bill Gerrard <bill@gerrard.org>
#
# VERSION HISTORY
#
# + v1.00	07/17/2017 Business::OnlinePayment implementation
#
# COPYRIGHT AND LICENSE
#
# Copyright (C) 2017 Bill Gerrard
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.20.2 or,
# at your option, any later version of Perl 5 you may have available.
#
# Disclaimer of warranty: This program is provided by the copyright holder
# and contributors "As is" and without any express or implied warranties.
# The implied warranties of merchantability, fitness for a particular purpose,
# or non-infringement are disclaimed to the extent permitted by your local
# law. Unless required by law, no copyright holder or contributor will be
# liable for any direct, indirect, incidental, or consequential damages
# arising in any way out of the use of the package, even if advised of the
# possibility of such damage.
#
################################################################################

package Business::OnlinePayment::iTransact;

use 5.008004;
use strict;
use Carp;
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS;

# iTransact specificprerequisites:
use XML::Hash::LX;
use Digest::HMAC_SHA1;

our @ISA = qw(Business::OnlinePayment::HTTPS);
our $VERSION = '1.00';

sub set_defaults {
    my $self = shift;

    $self->server('secure.itransact.com');
    $self->port('443');
    $self->path('/cgi-bin/rc/xmltrans2.cgi');

    $self->build_subs(qw(
        avs_category timestamp total card_type
        error_category warning_message auth_amount
    ));
}

sub map_fields {
    my ( $self ) = @_;
    my %content = $self->content();

    my $action  = lc( $content{'action'} );
    my %map = (
        'normal authorization' => 'AuthTransaction',
        #'authorization only'   => 'AuthTransaction-PreAuth',
        #'avs only'             => 'AuthTransaction-AVSOnly',
        ## 'credit'               => 'TranCredTransaction',
        ## 'post authorization'   => 'PostAuthTransaction',
        ## 'void'                 => 'VoidTransaction',
    );
    $content{'action_type'} = $map{$action}
      or croak 'Invalid action: '. $action;

    $self->transaction_type($content{'type'});

    $self->content( %content );
}

sub submit {
    my($self) = @_;

    $self->map_fields();

    my @required_fields = qw(type action amount description 
        first_name last_name card_number expiration);
    $self->required_fields( @required_fields );

    my %c = $self->content();

    if ( lc( $c{'type'} ) =~ /^e?check$/i ) {
      $self->is_success(0);
      $self->error_message('Business::OnlinePayment::iTransact does not currently support checks');
      return;
    }

    my $action = $c{action_type};

    ### start XML Generation
    my $customer_info = {
        CustomerData => {
            CustId          => $c{customer_id},
            Email           => $c{email},
            BillingAddress  => {
                    Address1        => $c{address},
                    FirstName       => $c{first_name},
                    LastName        => $c{last_name},
                    City            => $c{city},
                    State           => $c{state},
                    Zip             => $c{zip},
                    Country         => $c{country},
                    Phone           => $c{phone},
            },
        },
    };

    my $account_info;

    if (lc $c{type} eq 'cc') {

      # expiration date
      $c{'expiration'} =~ /^(\d+)\D+\d*(\d{2})$/
        or croak "unparsable expiration ". $c{expiration};
      my( $month, $year ) = ( $1, $2 );
      $month = '0'. $month if $month =~ /^\d$/;
      $year = '20' . $year if length($year) == 2;

       $account_info = {
            AccountInfo => {
                CardAccount => {
                    AccountNumber   => $c{card_number},
                    ExpirationMonth => $month,
                    ExpirationYear  => $year,
                    CVVNumber       => $c{cvv2},
                },
            },
       };
    } 

    my $http = $self->{port} eq '443' ? 'https://' : 'http://';
    my $gateway_url = $http . $self->{server} . $self->{path};

    my $payload = {
        $action => {
             TransactionControl => {
                 SendCustomerEmail => $self->email_customer,
                 SendMerchantEmail => $self->email_merchant,
                 TestMode          => $self->{test_mode} ? 'TRUE' : 'FALSE',
             },
             %{$customer_info},
             %{$account_info},
             Description => $c{description},
             Total => $c{amount},
         },
    };

    my $xml = hash2xml $payload;
    $xml = (split(/\n/, $xml))[1]; # remove <xml> declaration
    my $hmac = Digest::HMAC_SHA1->new($self->password);
    $hmac->add($xml);
    my $payload_signature = $hmac->b64digest . '='; # add closing '=' to signature

    # build request with calculated payload signature
    my %request = (
        GatewayInterface    => {
            APICredentials  => {
                Username            => $self->login,
                PayloadSignature    => $payload_signature,
            },
            %{$payload},
        },
    );
    $xml = hash2xml \%request;
    ### end XML Generation

    my ( $page, $status_code, %headers ) =
        $self->https_post( { 'Content-Type' => 'text/xml; charset=utf-8' } , $xml);

    my $response = {};
    if ( $status_code =~ /^200/ ) {
        if ( ! eval {
            my $decoded_xml = xml2hash $page;
            $response = $decoded_xml->{GatewayInterface}{TransactionResponse}{TransactionResult};
        } ) {
            die "XML PARSING FAILURE: $@";
        }
    }
    else {
        $status_code =~ s/[\r\n\s]+$//; # remove newline so you can see the error in a linux console
        die "CONNECTION FAILURE: $status_code";
    }

    $self->server_response( $page );
    $self->authorization( $response->{AuthCode} );
    $self->order_number(  $response->{XID} );
    $self->avs_code( $response->{AVSResponse} );
    $self->cvv2_response( $response->{CVV2Response} );
    # iTransact specific return fields
    $self->avs_category( $response->{AVSCategory} );
    $self->timestamp( $response->{TimeStamp} );
    $self->total( $response->{Total} );
    $self->auth_amount( $response->{AuthAmount} );
    $self->card_type( $response->{CardName} );

    if ($response->{Status} eq 'ok') { #success
        $self->is_success(1);
    } else {
      $self->is_success(0);
      $self->error_message( $response->{ErrorMessage} );
      $self->error_category( $response->{ErrorCategory} );
    }

}

sub test_transaction {
    my $self = shift;
    my $testMode = shift;
    if (! defined $testMode) { $testMode = $self->{test_mode} || 0; }

    $testMode = 1 if uc $testMode eq 'TRUE';
    $testMode = 0 if uc $testMode eq 'FALSE';

    if ($testMode) {
        $self->{test_mode} = 1;
    } else {
        $self->{test_mode} = 0;
    }

    return $self->{test_mode};
}

1;

__END__

=head1 NAME

Business::OnlinePayment::iTransact - iTransact backend module for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment( 'iTransact',
      login          => 'api_username', # iTransact API Username
      password       => 'apiKey', # iTransact API Key
      email_customer => 'TRUE', # send email to customer
      email_merchant => 'TRUE', # send email to merchant
  );

  $tx->content(
      action         => 'Normal Authorization',
      type           => 'cc',
      description    => 'Business::OnlinePayment::iTransact XML Test',
      amount         => '20.17',
      customer_id    => '123-CUST',
      first_name     => 'John',
      last_name      => 'Doe',
      card_number    => '5454545454545454',
      expiration     => '12/18',
      cvv2           => '123',
      email          => 'user@example.com',
      ### optional; include address fields to perform AVS check
      address        => '123 Main St',
      city           => 'Salt Lake City',
      state          => 'UT',
      zip            => '84001',
      country        => 'US',
      phone          => '801-555-1212',
  );

  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully.\n\n";
      print "Authorization Code: " . $tx->authorization . "\n";
      print "Transaction ID: " . $tx->order_number . "\n";
      print "CVV Result Code: " . $tx->cvv2_response . "\n";
      print "AVS Result Code: " . $tx->avs_code . "\n";
      print "AVS Result Category: " . $tx->avs_category . "\n";
      print "Date and Time of Transaction: " . $tx->timestamp . "\n";
      print "Authorized Amount: " . $tx->total . "\n";
      print "Card Type: " . $tx->card_type . "\n";
  } else {
      print "Card was rejected.\n\n";
      print "Error Message: ".$tx->error_message."\n";
      print "Error Category: " . $tx->error_category . "\n";
  }

=head1 DESCRIPTION

Process Credit Card transactions via iTransact's XML API Connection.

This is a plugin for the Business::OnlinePayment interface. Please refer to
that documentation for general usage, and here for iTransact specific usage.

=head1 SUPPORTED TRANSACTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

Content required: type, login, password, action, amount, description,
first_name, last_name, card_number, expiration.

=head1 SUPPORTED TRANSACTION ACTIONS

=head2 Normal Authorization

An action of 'Normal Authorization' will send a 'AuthTransaction' sale request to iTransact. 

A sale request is the default authorization type performed which is an authorization that will automatically be captured during the settlement process. An AVSOnly credit card transaction request is a sale request run with a zero amount and can be used to validate the AVS and CVV information on a card without actually running an authorization.

=head1 METHODS AND FUNCTIONS

See L<Business::OnlinePayment> for the complete list. The following methods either override the methods in L<Business::OnlinePayment> or provide additional functions.

=head2 order_number

Unique transaction identifier assigned by the gateway (XID)

=head2 cvv2_response

Security code verification response (CVV2Response)

=head2 avs_code

Address verification response (AVSResponse)

=head2 avs_category

Address verification response category (AVSCategory)

=head2 timestamp

Date and time of transactioni (TimeStamp)

=head2 total

Total transaction amount (Total)

=head2 card_type

Type of credit card used, i.e. VISA, MasterCard, etc. (CardName)

=head2 error_code

Returns the iTransact error code when an error occurs.

=head2 error_message

Returns the response error description text.

=head2 server_response

The raw XML response from the iTransact XML Gateway

=head1 UNIMPLEMENTED FEATURES

Certain features are not yet implemented (no current personal business need), such as check processing
and other transaction action types supported by iTransact. 

=head1 PREREQUISITES

  Business::OnlinePayment
  Business::OnlinePayment::HTTPS
  XML::Hash::LX
  Digest::HMAC_SHA1

=head1 SEE ALSO

Refer to iTransact's documentation for more info
L<https://itransact.com/support/toolkit/xml-connection/api/>

For detailed information about Business::OnlinePayment see L<Business::OnlinePayment>.

The latest version of Business::OnlinePayment::iTransact can be found at
L<https://github.com/billgerrard/Business-OnlinePayment-iTransact>

=head1 AUTHOR

Original Author
Bill Gerrard <bill@gerrard.org>

Business::OnlinePayment Implementation
Bill Gerrard <bill@gerrard.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Bill Gerrard

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.

Disclaimer of warranty: This program is provided by the copyright holder
and contributors "As is" and without any express or implied warranties.
The implied warranties of merchantability, fitness for a particular purpose,
or non-infringement are disclaimed to the extent permitted by your local
law. Unless required by law, no copyright holder or contributor will be
liable for any direct, indirect, incidental, or consequential damages
arising in any way out of the use of the package, even if advised of the
possibility of such damage.

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

