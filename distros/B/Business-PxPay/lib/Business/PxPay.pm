package Business::PxPay;

# ABSTRACT: PX Pay Interface for www.paymentexpress.com

use warnings;
use strict;
use Carp qw/croak/;
use URI::Escape qw/uri_escape/;
use LWP::UserAgent;
use XML::Simple qw/XMLin XMLout/;
use vars qw/%TRANSACTIONS/;

our $VERSION = '0.05';

%TRANSACTIONS = (
    purchase      => 'Purchase',
    credit        => 'Refund',
    authorization => 'Auth',
    capture       => 'Complete',
    validate      => 'Validate'
);

sub new {
    my $class = shift;
    my $args = scalar @_ % 2 ? shift : { @_ };

    # validate
    $args->{userid} or croak 'userid is required';
    $args->{key}    or croak 'key is required';

    $args->{url} ||= 'https://sec.paymentexpress.com/pxpay/pxaccess.aspx';

    unless ( $args->{ua} ) {
        my $ua_args = delete $args->{ua_args} || {};
        $args->{ua} = LWP::UserAgent->new(%$ua_args);
    }

    bless $args, $class;
}

sub request {
    my $self = shift;
    my $args = scalar @_ % 2 ? shift : { @_ };

    my $xml = $self->request_xml($args);
    my $resp = $self->{ua}->post($self->{url}, Content => $xml);
    unless ($resp->is_success) {
        croak $resp->status_line;
    }
    my $rtn = XMLin($resp->content, SuppressEmpty => undef);
    return $rtn;
}

sub request_xml {
    my $self = shift;
    my $args = scalar @_ % 2 ? shift : { @_ };

    # validate
    my $TxnType = $args->{TxnType} || croak 'TxnType is required';
    my $Amount = $args->{Amount} || $self->{Amount} || croak 'Amount is required';
    $Amount = sprintf ("%.2f", $Amount); # .XX format
    my $Currency   = $args->{Currency} || $self->{Currency} || croak 'Currency is required';
    my $UrlFail    = $args->{UrlFail} || $self->{UrlFail} || croak 'UrlFail is required';
    my $UrlSuccess = $args->{UrlSuccess} || $self->{UrlSuccess} || croak 'UrlSuccess is required';
    my $MerchantReference = $args->{MerchantReference} || croak 'MerchantReference is required';

    # UrlFail can't contain '?' or '&'
    if ( $UrlFail =~ /\?/ or $UrlFail =~ /\&/ ) {
        croak "UrlFail can't contain '?' or '&', please use TxnData1, TxnData2, TxnData3 or Opt\n";
    }
    if ( $UrlSuccess =~ /\?/ or $UrlSuccess =~ /\&/ ) {
        croak "UrlSuccess can't contain '?' or '&', please use TxnData1, TxnData2, TxnData3 or Opt\n";
    }

    my $request = {
        GenerateRequest => {
            PxPayUserId => [ $self->{userid} ],
            PxPayKey    => [ $self->{key} ],
            AmountInput => [ $Amount ],
            CurrencyInput => [ $Currency ],
            MerchantReference => [ $MerchantReference ],
            EmailAddress => [ $args->{EmailAddress} ],
            TxnData1     => [ $args->{TxnData1} ],
            TxnData2     => [ $args->{TxnData2} ],
            TxnData3     => [ $args->{TxnData3} ],
            TxnType      => [ $TxnType ],
            TxnId        => [ $args->{TxnId} ],
            BillingId    => [ $args->{BillingId} ],
            EnableAddBillCard => [ $args->{EnableAddBillCard} ],
            UrlSuccess   => [ $UrlSuccess ],
            UrlFail      => [ $UrlFail ],
            Opt          => [ $args->{Opt} ],
        },
    };
    return XMLout( $request, KeepRoot => 1 );
}

sub result {
    my ( $self, $ResponseCode ) = @_;

    my $xml = $self->result_xml($ResponseCode);
    my $resp = $self->{ua}->post($self->{url}, Content => $xml);
    unless ($resp->is_success) {
        croak $resp->status_line;
    }
    my $rtn = XMLin($resp->content, SuppressEmpty => undef);
    return $rtn;
}

sub result_xml {
    my ( $self, $ResponseCode ) = @_;

    my $request = {
        ProcessResponse => {
            PxPayUserId => [ $self->{userid} ],
            PxPayKey    => [ $self->{key} ],
            Response    => [ $ResponseCode ],
        },
    };
    return XMLout( $request, KeepRoot => 1 );
}

1;
__END__

=head1 SYNOPSIS

    use Business::PxPay;

    my $pxpay = Business::PxPay->new(
        userid => 'TestAccount',
        key    => 'c9fff215b9e2add78d252b78e214880b46a906e73190a380483c1c29acab4157'
    );

    # when submit the cart order
    if ( $submit_order ) {
        my $rtn = $pxpay->request($args); # $args from CGI params
        if ( exists $rtn->{valid} and $rtn->{valid} == 1 ) {
            print $q->redirect( $rtn->{URI} );
        } else {
            die Dumper(\$rtn);
        }
    }
    # when user returns back from pxpal
    elsif ( $in_return_or_cancel_page or $params->{result} ) {
        my $rtn = $pxpay->result($params->{result});
        if ( exists $rtn->{valid} and $rtn->{valid} == 1 ) {
            print "Transaction Success!\n";
        } else {
            print "Transaction Failed!\n";
        }
    }

=head1 DESCRIPTION

PX Pay - Payment Express L<http://www.paymentexpress.com/>

=head2 new

    my $pxpay = Business::PxPay->new(
        userid => $user,
        key    => $key
    );

=over 4

=item * C<userid> (required)

=item * C<key> (required)

PxPayUserId & PxPayKey

=item * C<ua>

=item * C<ua_args>

By default, we use LWP::UserAgent->new as the UserAgent. you can pass C<ua> or C<ua_args> to use a different one.

=item * C<url>

    my $pxpay = Business::PxPay->new(
        userid => $user,
        key    => $key,
        url    => 'https://sec2.paymentexpress.com/pxpay/pxaccess.aspx', # to test?
    );

The URL is 'https://www.paymentexpress.com/pxpay/pxaccess.aspx' by default.

=back

=head2 Arguments

All those arguments can be passed into Business::PxPay->new() or pass into $pxpay->request later

    {
        TxnType => 'Purchase',
        Amount  => 10.9,
        UrlFail => 'http://test.com',
        UrlSuccess => 'http://example.com',
        MerchantReference => 'Test Transaction',
        EmailAddress => 'test@example.com',
        TxnData1 => 'test=A',
        TxnData2 => 'data2=B',
        TxnData3 => 'data3=C',
    };

=over 4

=item * C<Amount> (required)

Amount value in d.cc format

=item * C<Currency> (required)

L<http://www.paymentexpress.com/technical_resources/ecommerce_hosted/pxpay.html#currencyinput>

=item * C<UrlFail> (required)

URL of the merchant transaction failure page. No parameters ("&" or "?") are permitted.

=item * C<UrlSuccess> (required)

URL of the merchant transaction success page. No parameters ("&" or "?") are permitted.

=item * C<TxnType> (required)

"Auth" or "Purchase"

=item * C<MerchantReference> (required)

Reference field to appear on transaction reports

=item * C<BillingId>

Optional identifier when adding a card for recurring billing

=item * C<EmailAddress>

Optional email address

=item * C<EnableAddBillCard>

Required when adding a card to the DPS system for recurring billing. Set element to "1" for true

=item * C<TxnId>

A value that uniquely identifies the transaction

=item * C<TxnData1>

=item * C<TxnData2>

=item * C<TxnData3>

Optional free text

=item * C<Opt>

Optional additional parameter

=back

=head2 request

    my $xml = $pxpay->request_xml($args);
    my $rtn = $pxpay->request($args);

request and parse the response XML into HASHREF. sample:

    $VAR1 = \{
        'URI' => 'https://sec2.paymentexpress.com/pxpay/pxpay.aspx?userid=
TestAccount&request=v51flwn7rvSNcbY86uRMdJ74XB2gHd8ZY-WHqyEYoPm9xd1ROXX00pXYkkuk
dleLlS402E65EjOSCkrqvmAsZUWRCck8RkmIJcRLvG0KZLi7PQRBfpIQ0wzKwdHGKvBCpqhRH6Tx-w93
MRYsP0ThOK4btgTneR_hGEk0supyLeE1taNWCkyFj8KX7rzZ9ncdWRlmciNBsiV4zX4DQ_7Poi9qiblI
5o0Gm49yb90kUlUtH1hrV3ulzidQbn0CcQKhHFKGX8IVMXiAtVN29r_Cgdzc7dOrwOxY-LBY2h4Or5GQ
hJHB96kjBziu3GyGBvaGfsosNodT3-wyM29A5M-Z62ITkno6JUA6H4',
        'valid' => '1'
    };

Usually you need redirect to the $rtn->{URI} when valid is 1

=head2 result

    my $xml = $pxpay->result_xml($ResponseCode);
    my $rtn = $pxpay->result($ResponseCode);
    if ( exists $rtn->{valid} and $rtn->{valid} == 1 ) {
        print "Transaction Success!\n";
    } else {
        print "Transaction Failed!\n";
    }

PxPay will POST to your C<UrlSuccess> (or C<UrlFail>) when you finish the transaction (or click Cancel button). the POST would contain a param B<result> which you can request to get the transaction status.

=head2 TIPS

=head3 I need params in C<UrlSuccess>

For example, you want your UrlSuccess to be 'http://mysite.com/cgi-bin/cart.cgi?cart_id=ABC'.

you need write the request like:

    my $rtn = $pxpay->request(
        # others
        UrlSuccess => 'http://mysite.com/cgi-bin/cart.cgi',
        TxnData1 => 'ABC',
    );

and you can get the C<TxnData1> in

    my $rtn = $pxpay->result($ResponseCode);
    my $cart_id = $rtn->{TxnData1}
