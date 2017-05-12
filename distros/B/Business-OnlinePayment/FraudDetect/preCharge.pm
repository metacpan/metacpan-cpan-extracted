package Business::FraudDetect::preCharge;

use strict;
use Carp;
use vars qw($VERSION @ISA);
use Business::OnlinePayment::HTTPS;

@ISA = qw( Business::OnlinePayment::HTTPS );

$VERSION = '0.02';

sub _glean_parameters_from_parent {
    my ($self, $parent) = @_;
    foreach my $method (qw / precharge_id precharge_security1 precharge_security2 /) {
	$self->$method($parent->$method);
    }
}

sub set_defaults {
    my ($self) = @_;
    $self->server('api.precharge.net');
    $self->port(443);
    $self->path('/charge');
    $self->build_subs(qw /currency fraud_score error_code
		      precharge_id precharge_security1 precharge_security2 force_success fraud_transaction_id / );
    $self->currency('USD');
    return $self;
}

sub submit {
    my ($self) = @_;
    if ($self->force_success()) {
	$self->is_success(1);
	$self->result_code('1');
	$self->error_message('No Error.  Force success path');
	return $self;
    }
    my %content = $self->content();
    Carp::croak("Action: $content{action} not supported.") unless
	lc($content{action}) eq 'fraud detect';
    
    $self->required_fields(qw(
			      amount card_number expiration
			      first_name last_name state zip country phone email
			      ip_address
			      ));

    $self->remap_fields( qw/
                            ip_address         ecom_billto_online_ip 
                            zip                ecom_billto_postal_postalcode 
                            phone              ecom_billto_telecom_phone_number 
                            first_name         ecom_billto_postal_name_first
                            last_name          ecom_billto_postal_name_last
                            email              ecom_billto_online_email 
                            country            ecom_billto_postal_countrycode
                            card_number        ecom_payment_card_number
                            amount             ecom_transaction_amount
                           /
                       );


    my %post_data = $self->get_fields(qw(
      ecom_billto_online_ip ecom_billto_postal_postalcode
      ecom_billto_telecom_phone_number ecom_billto_online_email
      ecom_transaction_amount currency
      ecom_billto_postal_name_first ecom_billto_postal_name_last
      ecom_billto_postal_countrycode
      ecom_payment_card_number
    ));

    # set up some reasonable defaults

    #
    # split out MM/YY from exp date
    #

    @post_data{ qw/ ecom_payment_card_expdate_month
                    ecom_payment_card_expdate_year
                  /
              } = split(/\//,$content{expiration});

    @post_data{qw/merchant_id security_1 security_2/} = (
      $self->precharge_id,
      $self->precharge_security1,
      $self->precharge_security2
    );

    if ($self->test_transaction()) {
	$post_data{test} = 1;
    }
    my ($page, $response, %headers) = $self->https_post(\%post_data);

    $self->server_response($page);

    my @details = split ',',$page;

    my %error_map = ( 101 => 'Invalid Request Method',
		      102 => 'Invalid Request URL',
		      103 => 'Invalid Security Code(s)',
		      104 => 'Merchant Status not Verified',
		      105 => 'Merchant Feed is Disabled',
		      106 => 'Invalid Request Type',
		      107 => 'Missing IP Address',
		      108 => 'Invalid IP Address Syntax',
		      109 => 'Missing First Name',
		      110 => 'Invalid First Name',
		      111 => 'Missing Last Name',
		      112 => 'Invalid Last Name',
		      113 => 'Invalid Address 1',
		      114 => 'Invalid Address 2',
		      115 => 'Invalid City',
		      116 => 'Invalid State',
		      117 => 'Invalid Country',
		      118 => 'Missing Postal Code',
		      119 => 'Invalid Postal Code',
		      120 => 'Missing Phone Number',
		      121 => 'Invalid Phone Number',
		      122 => 'Missing Expiration Month',
		      123 => 'Invalid Expiration Month',
		      124 => 'Missing Expiration Year',
		      125 => 'Invalid Expiration Year',
		      126 => 'Expired Credit Card',
		      127 => 'Missing Credit Card Number',
		      128 => 'Invalid Credit Card Number',
		      129 => 'Missing Email Address',
		      130 => 'Invlaid Email Syntax',
		      131 => 'Duplicate Transaction',
		      132 => 'Invlaid Transaction Amount',
		      133 => 'Invalid Currency',
		      998 => 'Unknown Error',
		      999 => 'Service Unavailable',
		      1001 => 'No detail returned',
		   );
		   

    my %output = ( error => 1001 );

    foreach my $detail (@details) {
	my ($k, $v) = split('=', $detail);
	$output{$k} = $v;
    }

    if ($output{response} == 1 )  {
        $self->is_success(1);
        $self->fraud_score($output{score});
        $self->result_code($output{response});
        $self->fraud_transaction_id($output{transaction});
        $self->error_message('No Error.  Risk assesment transaction successful');
    } else {
        $self->is_success(0);
        $self->fraud_score($output{score});
        $self->result_code($output{error});
        $self->error_message( exists( $error_map{$output{error}} )
                                ? $error_map{$output{error}}
                                :  "preCharge error $output{error} occurred."
                            );
    }
}


1;


=pod

=head1 NAME 

Business::FraudDetect::preCharge - backend for Business::FraudDetect (part of Business::OnlinePayment)

=head1 SYNOPSIS

 use Business::OnlinePayment
 my $tx = new Business::OnlinePayment ( 'someGateway',
                                        fraud_detect => 'preCharge',
                                        maximum_fraud_score => 500,
                                        preCharge_id => '1000000000000001',
                                        preCharge_security1 => 'abcdef0123',
                                        preCharge_security2 => '3210fedcba',
                                       );
 $tx->content(  
    first_name => 'Larry Walton',
    last_name => 'Sanders',
    login => 'testdrive',
    password => '',
    action => 'Normal Authorization',
    type => 'VISA',
    state => 'MA',
    zip => '02145',
    country => 'US',
    phone => '617 555 8900',
    email => 'lws@sanders.com',
    ip_address => '18.62.0.6',
    card_number => '4111111111111111',
    expiration => '0307',
    amount => '25.00',
    );
 $tx->submit();
 if ($tx->is_success()) {
    # successful charge
    my $score = $tx->fraud_score;
    my $id = $tx->fraud_transaction_id;
       #returns the preCharge transaction id
 } else {
    # unsucessful 
    my $score = $tx->fraud_score;
 }

=head1 DESCRIPTION

This module provides a driver for the preCharge Risk Management Solutions API Version 1.7 (16 Jan 2006).

See L<Business::OnlinePayment> and L<Business::FraudDetect> for more information.  


=head1 CONSTRUCTION

Whe constructing the Business::OnlinePayment object, three risk management parameters must be included for the preCharge object to be properly constructed.  

=over 4

=item * precharge_id

This field is called "merchant_id" in the preCharge API manual


=item * precharge_security1

This field is called "security_1" in the preCharge API manual

=item * precharge_secuirty2

This field is called "security_2" in the preCharge API manual

=back


=head1 METHODS

This module provides no public methods.  

=head1 AUTHORS

Lawrence Statton <lawrence@cluon.com>

Jason Hall <jayce@lug-nut.com>

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

http://420.am/business-onlinepayment

=cut
