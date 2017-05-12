package Business::Eway;

use warnings;
use strict;
use Carp qw/croak/;
use URI::Escape qw/uri_escape/;
use LWP::UserAgent;
use XML::Simple qw/XMLin/;

our $VERSION = '0.03';

sub new {
    my $class = shift;
    my $args = scalar @_ % 2 ? shift : { @_ };
    
    # validate
    ($args->{CustomerID} =~ /^\d+$/) or croak 'CustomerID is required';
    $args->{UserName} or croak 'UserName is required';
    
    $args->{RequestURL} ||= 'https://payment.ewaygateway.com/Request';
    $args->{ResultURL}  ||= 'https://payment.ewaygateway.com/Result';
    
    unless ( $args->{ua} ) {
        my $ua_args = delete $args->{ua_args} || {};
        $args->{ua} = LWP::UserAgent->new(%$ua_args);
    }
    
    bless $args, $class;
}

sub request {
    my $self = shift;
    my $args = scalar @_ % 2 ? shift : { @_ };
    
    my $url = $self->request_url($args);
    my $resp = $self->{ua}->get($url);
    unless ($resp->is_success) {
        croak $resp->status_line;
    }
    my $content = $resp->content;
    my $rtn = XMLin($content, SuppressEmpty => undef);
    if (wantarray) {
        if ( $rtn->{Result} eq 'True' ) {
            return (1, $rtn->{URI});
        } else {
            return (0, $rtn->{Error});
        }
    } else {
        return $rtn;
    }
}

sub request_url {
    my $self = shift;
    my $args = scalar @_ % 2 ? shift : { @_ };
    
    # validate
    my $Amount = $args->{Amount} || $self->{Amount} || croak 'Amount is required';
    $Amount = sprintf ("%.2f", $Amount); # .XX format
    my $Currency  = $args->{Currency} || $self->{Currency} || croak 'Currency is required';
    my $CancelURL = $args->{CancelURL} || $self->{CancelURL} || croak 'CancelURL is required';
    my $ReturnUrl = $args->{ReturnUrl} || $self->{ReturnUrl} || croak 'ReturnUrl is required';
    
    # ReturnUrl can't contain '?'
    if ( $ReturnUrl =~ /\?/ ) {
        croak "ReturnUrl can't contain '?' inside, use MerchantOption1, MerchantOption2, MerchantOption3 instead\n";
    }
    
    my $url = sprintf("$self->{RequestURL}?CustomerID=$self->{CustomerID}&UserName=$self->{UserName}&Amount=$Amount&Currency=$Currency&CancelURL=%s&ReturnUrl=%s",
        uri_escape($CancelURL), uri_escape($ReturnUrl)
    );;
    
    # other args
    foreach my $k ( 'PageTitle', 'PageDescription', 'PageFooter',
        'Language', 'CompanyName', 'CompanyLogo', 'PageBanner',
        'CustomerFirstName', 'CustomerLastName', 'CustomerAddress', 'CustomerCity',
        'CustomerState', 'CustomerPostCode', 'CustomerCountry', 'CustomerPhone',
        'CustomerEmail', 'InvoiceDescription', 'MerchantReference', 'MerchantInvoice',
        'MerchantOption1', 'MerchantOption2', 'MerchantOption3'
    ) {
        my $val = $args->{$k} || $self->{$k};
        if ( defined $val ) {
            $url .= sprintf("&$k=%s", uri_escape($val));
        } else {
            $url .= "&$k=";
        }
    }
    foreach my $k ( 'UseAVS', 'UseZIP', 'ModifiableCustomerDetails' ) {
        my $val = $args->{$k} || $self->{$k};
        $val = ( not $val or $val =~ /false/i) ? 'false' : 'true';
        $url .= "&$k=$val";
    }
    
    return $url;
}

sub result {
    my ( $self, $AccessPaymentCode ) = @_;
    
    my $url = $self->result_url($AccessPaymentCode);
    my $resp = $self->{ua}->get($url);
    unless ($resp->is_success) {
        croak $resp->status_line;
    }
    my $content = $resp->content;
    return XMLin($content, SuppressEmpty => undef);
}

sub result_url {
    my ( $self, $AccessPaymentCode ) = @_;
    return "https://payment.ewaygateway.com/Result?CustomerID=$self->{CustomerID}&UserName=$self->{UserName}&AccessPaymentCode=$AccessPaymentCode";
}

1;
__END__

=head1 NAME

Business::Eway - eWAY - eCommerce the SAFE and EASY way

=head1 SYNOPSIS

    use Business::Eway;

    my $eway = Business::Eway->new(
        CustomerID => 87654321,
        UserName => 'TestAccount',
    );
    
    # when submit the cart order
    if ( $submit_order ) {
        my $rtn = $eway->request($args); # $args from CGI params
        if ( $rtn->{Result} eq 'True' ) {
            print $q->redirect( $rtn->{URI} );
        } else {
            die $rtn->{Error};
        }
    }
    # when user returns back from eway
    elsif ( $in_return_or_cancel_page or $params->{AccessPaymentCode} ) {
        my $rtn = $eway->result($AccessPaymentCode);
        if ( $rtn->{TrxnStatus} eq 'true' ) {
            print "Transaction Success!\n";
        } else {
            print "Transaction Failed!\n";
        }
    }

=head1 DESCRIPTION

eWAY - eCommerce the SAFE and EASY way L<http://www.eway.co.uk/>

=head2 new

    my $eway = Business::Eway->new(
        CustomerID => 87654321,
        UserName => 'TestAccount',
    );

=over 4

=item * C<CustomerID> (required)

=item * C<UserName> (required)

Your eWAY Customer ID and User Name.

=item * C<ua>

=item * C<ua_args>

By default, we use LWP::UserAgent->new as the UserAgent. you can pass C<ua> or C<ua_args> to use a different one.

=back

=head2 Arguments

All those arguments can be passed into Business::Eway->new() or pass into $eway->request later

=over 4

=item * C<Amount> (required)

The amount of the transaction in dollar form 
 
(ie $27.00 transaction would have a Amount value of "27.00")

=item * C<Currency> (required)

Three letter acronym of the currency code according to ISO 4217 (ie British Pound Sterling would be 'GBP')

Default: 'GBP'

=item * C<ReturnUrl> (required)

The web address to direct the customer with the result of the transaction. 

=item * C<CancelURL> (required)

The web address to direct the customer when the transaction is cancelled. 

=item * C<PageTitle>

This is value will be displayed as the title of the browser. 

Default: eWAY Hosted Payment Page

=item * C<PageDescription>

This value will be displayed above the Transaction Details.

Default: Blank 

=item * C<PageFooter>

This value will be displayed below the Transaction Details. 

=item * C<Language>

The two letter acronym of the language code. supported languages now:

    English  EN 
    Spanish  ES 
    French   FR 
    German   DE 
    Dutch    NL 

Default: EN

=item * C<CompanyName>

This will be displayed as the company the customer is purchasing from, including this is highly recommended. 

=item * C<CompanyLogo>

The url of the image can be hosted on the merchants website and pass the secure https:// path of the image to be displayed at the top of the website.  This is the top image block on the webpage and is restricted to 960px X 65px. A default secure image is used if none is 
supplied.

=item * C<PageBanner>

The url of the image can be hosted on the merchants website and pass the secure https:// path of the image to be displayed at the top of the website.  This is the second image block on the webpage and is restricted to 960px X 65px. A default secure image is used if none 
is supplied. 

=item * C<CustomerFirstName>

=item * C<CustomerLastName>

=item * C<CustomerAddress>

=item * C<CustomerCity>

=item * C<CustomerState>

=item * C<CustomerPostCode>

=item * C<CustomerCountry>

=item * C<CustomerPhone>

=item * C<CustomerEmail>

Customer Information

=item * C<InvoiceDescription>

This field is used to display to the user a description of the purchase they are about to make, usually product summary information. 

=item * C<MerchantReference>

=item * C<MerchantInvoice>

This is a number created by the merchant for this transaction.

=item * C<MerchantOption1>

=item * C<MerchantOption2>

=item * C<MerchantOption3>

This field is not displayed to the customer but is returned in the result string. Anything 
can be used here, useful for tracking transactions 

=back

=head2 request

    my $url = $eway->request_url($args);
    my $rtn = $eway->request($args);
    my ($status, $url_or_error) = $eway->request($args); # $status 1 - OK, 0 - ERROR

request a URL to https://payment.ewaygateway.com/Request and parse the XML into HASHREF. sample:

    $VAR1 = \{
        'Error' => {},
        'URI' => 'https://payment.ewaygateway.com/UK1/PaymentPage.aspx?value=mwm4VNOrYxxxxxx',
        'Result' => 'True'
    };

Usually you need redirect to the $rtn->{URI} when Result is True (or $url_or_error when $status is 1).

=head2 result

    my $url = $eway->result_url($AccessPaymentCode);
    my $rtn = $eway->result($AccessPaymentCode);
    if ( $rtn->{TrxnStatus} eq 'true' ) {
        print "Transaction Success!\n";
    } else {
        print "Transaction Failed!\n";
    }
    foreach my $k ('TrxnStatus', 'AuthCode', 'ResponseCode', 'ReturnAmount', 'TrxnNumber', 
    'TrxnResponseMessage', 'MerchantOption1', 'MerchantOption2', 'MerchantOption3', 
    'MerchantInvoice', 'MerchantReference') {
        print "$k: $rtn->{$k}\n";
    }

Eway will POST to your C<ReturnUrl> (or C<CancelURL>) when you finish the transaction (or click Cancel button). the POST would contain a param B<AccessPaymentCode> which you can request to get the transaction status.

=head2 TIPS

=head3 I need params in C<ReturnUrl>

For example, you want your ReturnUrl to be 'http://mysite.com/cgi-bin/cart.cgi?cart_id=ABC'.

you need write the request like:

    my $rtn = $eway->request(
        # others
        ReturnUrl => 'http://mysite.com/cgi-bin/cart.cgi',
        MerchantOption1 => 'ABC',
    );

and you can get the C<MerchantOption1> in

    my $rtn = $eway->result($AccessPaymentCode);
    my $cart_id = $rtn->{MerchantOption1}

=head1 EXAMPLES

There is 'examples' directory in the .tar.gz in case you want to have a check.

=head1 SEE ALSO

=over 4

=item * Testing

L<http://www.eway.co.uk/Developer/Testing/Testing.aspx>

=item * Response Code

L<http://www.eway.co.uk/Developer/Downloads/ResponseCodes.aspx>

=item * Downloads

L<http://www.eway.co.uk/Developer/Downloads/SampleCode/eWAY-Sample-API-Code.aspx>

=back

=head1 AUTHOR

eWAY Europe Ltd, C<< <support at eway.co.uk> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 eWAY Europe Ltd.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
