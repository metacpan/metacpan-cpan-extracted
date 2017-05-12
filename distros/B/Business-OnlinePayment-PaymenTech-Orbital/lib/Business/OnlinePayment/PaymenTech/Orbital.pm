package Business::OnlinePayment::PaymenTech::Orbital;
use strict;

our $VERSION = '1.7';

=head1 NAME

Business::OnlinePayment::PaymenTech::Orbital - PaymenTech Orbital backend for Business::OnlinePayment

=head1 SYNPOSIS

  my %options;
  $options{'merchantid'} = '1234';
  my $tx = Business::OnlinePayment->new('PaymenTech::Orbital', %options);
  $tx->content(
    username        => 'username',
    password        => 'pass',
    invoice_number  => $orderid,
    trace_number    => $trace_num, # Optional
    action          => 'Authorization Only',
    cvn             => 123, # cvv2, cvc2, cid
    card_number     => '1234123412341234',
    exp_date        => '0410',
    address         => '123 Test Street',
    name            => 'Test User',
    amount          => 100 # $1.00
  );
  $tx->submit;

  if($tx->is_success) {
    print "Card processed successfully: ".$tx->authorization."\n";
  } else {
    print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 DESCRIPTION

Business::OnlinePayment::PaymenTech::Orbital allows you to utilize
PaymenTech's Orbital SDK credit card services.  You will need to install the
Perl Orbital SDK for this to work.

This module was previous named Business::OnlinePayment::PaymenTech but was
renamed since it is specific to the Orbital SDK product.

For detailed information see L<Business::OnlinePayment>.

=head1 SUPPORTED ACTIONS

Authorization Only, Authorization and Capture, Capture, Credit

By default, Business::Online::PaymenTech::Orbital uses the MOTO API calls in
the PaymenTech library.  If you specifically set the C<ecommerce> option to a
true value in your C<content> then the CC API will be used where applicable,
notably Authorization, Authorization and Capture and Refund. (Actually,
refund uses ECOMMERCE_REFUND when C<ecommerce> is true).

=head1 NOTES

There are a few rough edges to this module, but having it significantly eased
a transition from one processor to another.

=head1 SOFT DESCRIPTORS

The Soft Descriptor feature is enabled by setting C<sd_merchant_name> and,
optionally, any of the the following fields:

=over 4

=item sd_merchant_name

=item sd_product_description

=item sd_merchant_city

=item sd_merchant_phone

=item sd_merchant_url

=item sd_merchant_email

=head2 DEFAULTS

=back

=item time zone defaults to 706 (Central)

=item BIN defaults 001

=back

Some extra getters are provided.  They are:

 response       - Get the response code
 avs_response   - Get the AVS response
 cvv2_response  - Get the CVV2 response
 transaction_id - Get the PaymenTech assigned Transaction Id

=cut

use base qw(Business::OnlinePayment);

use Paymentech::SDK;
use Paymentech::eCommerce::RequestBuilder 'requestBuilder';
use Paymentech::eCommerce::RequestTypes qw(CC_AUTHORIZE_REQUEST MOTO_AUTHORIZE_REQUEST CC_MARK_FOR_CAPTURE_REQUEST ECOMMERCE_REFUND_REQUEST MOTO_REFUND_REQUEST);
use Paymentech::eCommerce::TransactionProcessor ':alias';

sub set_defaults {
    my $self = shift;

    $self->{'_content'} = {};

    $self->build_subs(
        qw(response avs_response cvv2_response transaction_id card_proc_resp)
    );
}

sub submit {
    my $self = shift;

    my %content = $self->content;

    my $req;

    if($content{'action'} eq 'Authorization Only') {
        if(lc($content{industry}) eq 'ecommerce') {
            $req = requestBuilder()->make(CC_AUTHORIZE_REQUEST());
            if(defined($content{'cvn'})) {
                $req->CardSecVal($content{'cvn'});
            }

        } else {
            $req = requestBuilder()->make(MOTO_AUTHORIZE_REQUEST());
        }
        $self->_add_bill_to($req);
        # Authorize
        $req->MessageType('A');
        $req->CurrencyCode('840');

        $req->Exp($content{'exp_date'});
        $req->AccountNum($content{'card_number'});

    } elsif($content{'action'} eq 'Capture') {

        $req = requestBuilder()->make(CC_MARK_FOR_CAPTURE_REQUEST());
        $req->TxRefNum($content{'tx_ref_num'});

    } elsif($content{'action'} eq 'Force Authorization Only') {
        # ?
    } elsif($content{'action'} eq 'Authorization and Capture') {
        if(lc($content{industry}) eq 'ecommerce') {
            $req = requestBuilder()->make(CC_AUTHORIZE_REQUEST());
            if(defined($content{'cvn'})) {
                $req->CardSecVal($content{'cvn'});
            }

        } else {
            $req = requestBuilder()->make(MOTO_AUTHORIZE_REQUEST());
        }
        $self->_add_bill_to($req);
        # Authorize and Capture
        $req->MessageType('AC');
        $req->CurrencyCode('840');

        $req->Exp($content{'exp_date'});
        $req->AccountNum($content{'card_number'});

    } elsif($content{'action'} eq 'Credit') {
        if(lc($content{industry}) eq 'ecommerce') {
            $req = requestBuilder()->make(ECOMMERCE_REFUND_REQUEST());
        } else {
            $req = requestBuilder()->make(MOTO_REFUND_REQUEST());
        }
        $req->CurrencyCode($content{'currency_code'} || '840');
        $req->AccountNum($content{'card_number'});

    } else {
        die('Unknown Action: '.$content{'action'}."\n");
    }

    if(defined($content{sd_merchant_name}) && $content{'action'} ne 'Capture') {
        $self->_add_soft_descriptor($req);
    }

    $req->BIN($content{'BIN'} || '000001');
    $req->MerchantID($self->{'merchantid'});
    if(exists($content{'trace_number'}) && $content{'trace_number'} =~ /^\d+$/) {
        $req->traceNumber($content{'trace_number'});
    }
    $req->OrderID($content{'invoice_number'});

    $req->Amount(sprintf("%012d", $content{'amount'}));
    $req->TzCode($content{'TzCode'} || '706');
    if(exists($content{'comments'})) {
        $req->Comments($content{'comments'} || '');
    }

    $self->{'request'} = $req;

    $self->_post;

    $self->_process_response;
}

sub _post {
    my $self = shift;

    my %content = $self->content;

    if($self->test_transaction) {
        print STDERR $self->{request}->renderAsXML."\n";
    }


    my $gw_resp = gatewayTP()->process($self->{'request'});
}

sub _process_response {
    my $self = shift;

    my $resp = $self->{'request'}->response;

    unless(defined($resp)) {
        $self->is_success(0);
        $self->error_message($self->error_message." No response.");
        return;
    }

    if($self->test_transaction) {
        print STDERR $resp->raw;
    }

    $self->transaction_id($resp->value('TxRefNum'));
    $self->cvv2_response($resp->CVV2ResponseCode);
    $self->response($resp->ResponseCode);
    $self->avs_response($resp->AVSResponseCode);
    $self->authorization($resp->value('AuthCode'));
    $self->error_message($resp->status);

    if(!$resp->approved) {
        $self->is_success(0);
        return;
    }

    $self->is_success(1);
}

sub _add_bill_to {
    my ($self, $req) = @_;

    my %content = $self->content;

    $req->AVSname($content{'name'});
    $req->AVSaddress1($content{'address'});
    $req->AVSaddress2($content{'address2'});
    $req->AVScity($content{'city'});
    $req->AVSstate($content{'state'});
    $req->AVSzip($content{'zip'});
    $req->AVScountryCode($content{'country'});
    if(exists($content{'phone_number'})) {
        $req->AVSphoneNum($content{'phone_number'});
    }
}

sub _add_soft_descriptor {
    my ($self, $req) = @_;

    my %content = $self->content;
    $req->SDMerchantName($content{'sd_merchant_name'});
    $req->SDProductDescription($content{'sd_product_description'});
    $req->SDMerchantCity($content{'sd_merchant_city'});
    $req->SDMerchantPhone($content{'sd_merchant_phone'});
    $req->SDMerchantURL($content{'sd_merchant_url'});
    $req->SDMerchantEmail($content{'sd_merchant_email'});
}

=head1 AUTHOR

Cory 'G' Watson <gphat@cpan.org>

=head2 CONTRIBUTORS

Garth Sainio <gsainio@cpan.org>

=head1 SEE ALSO

perl(1), L<Business::OnlinePayment>.

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Magazines.com, LLC

You can redistribute and/or modify this code under the same terms as Perl
itself.

=cut
1;
