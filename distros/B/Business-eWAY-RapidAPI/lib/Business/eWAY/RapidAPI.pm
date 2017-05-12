package Business::eWAY::RapidAPI;
$Business::eWAY::RapidAPI::VERSION = '0.11';

# ABSTRACT: eWAY RapidAPI V3

use Moo;
use Business::eWAY::RapidAPI::CreateAccessCodeRequest;
use Business::eWAY::RapidAPI::GetAccessCodeResultRequest;
use Business::eWAY::RapidAPI::TransactionRequest;
use Data::Dumper;
use WWW::Mechanize;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );

with 'Business::eWAY::RapidAPI::Role::Parser';
with 'Business::eWAY::RapidAPI::Role::ErrorCodeMap';

has 'mode' => ( is => 'rw', default => sub { 'live' } );
has 'urls' => ( is => 'lazy' );

sub _build_urls {
    my $self = shift;
    if ( $self->mode eq 'live' ) {
        return {
            'PaymentService.Soap' =>
              'https://api.ewaypayments.com/soap.asmx?WSDL',
            'PaymentService.POST.CreateAccessCode' =>
              'https://api.ewaypayments.com/CreateAccessCode.xml',
            'PaymentService.POST.GetAccessCodeResult' =>
              'https://api.ewaypayments.com/GetAccessCodeResult.xml',
            'PaymentService.REST' => 'https://api.ewaypayments.com/',
            'PaymentService.RPC'  => 'https://api.ewaypayments.com/json-rpc',
            'PaymentService.JSONPScript' =>
              'https://api.ewaypayments.com/JSONP/v1/js',
        };
    }
    else {
        return {
            'PaymentService.Soap' =>
              'https://api.sandbox.ewaypayments.com/Soap.asmx?WSDL',
            'PaymentService.POST.CreateAccessCode' =>
              'https://api.sandbox.ewaypayments.com/CreateAccessCode.xml',
            'PaymentService.POST.GetAccessCodeResult' =>
              'https://api.sandbox.ewaypayments.com/GetAccessCodeResult.xml',
            'PaymentService.REST' => 'https://api.sandbox.ewaypayments.com/',
            'PaymentService.RPC' =>
              'https://api.sandbox.ewaypayments.com/json-rpc',
            'PaymentService.JSONPScript' =>
              'https://api.sandbox.ewaypayments.com/JSONP/v1/js',
        };
    }
}

has 'username' => ( is => 'rw', required => 1 );
has 'password' => ( is => 'rw', required => 1 );
has 'debug'    => ( is => 'rw', default  => sub { 0 } );
has 'ShowDebugInfo' => ( is => 'lazy' );
sub _build_ShowDebugInfo { (shift)->debug }

has 'Request_Method' =>
  ( is => 'rw', required => 1, default => sub { 'REST' } );
has 'Request_Format' =>
  ( is => 'rw', required => 1, default => sub { 'JSON' } );

has 'ua' => ( is => 'lazy' );

sub _build_ua {
    my $self = shift;
    return WWW::Mechanize->new(
        timeout     => 60,
        autocheck   => 0,
        stack_depth => 1,
        ssl_opts    => {
            verify_hostname => 0,
            SSL_verify_mode => SSL_VERIFY_NONE,    # BAD
        }
    );
}

sub CreateAccessCode {
    my ( $self, $request ) = @_;

    if ( $self->debug ) {
        print STDERR "Request Ojbect for CreateAccessCode: \n";
        print STDERR Dumper( \$request ) . "\n";
    }

    my $Request_Method = $self->Request_Method;
    my $Request_Format = $self->Request_Format;

    ## Request_Method eq 'RPC' is not implemented yet
    $Request_Method = 'REST' if $Request_Method eq 'RPC';

    if ( $Request_Method ne 'SOAP' ) {
        if ( $Request_Format eq "XML" ) {
            if ( $Request_Method ne 'RPC' ) {
                $request = $self->Obj2XML( $request, 'CreateAccessCode' );
            }
            else {
                $request = $self->Obj2RPCXML( "CreateAccessCode", $request );
            }
        }
        else {
            if ( $Request_Method ne 'RPC' ) {

                # fixes
                $request            = $self->Obj2ARRAY($request);
                $request->{Items}   = delete $request->{Items}->{LineItem};
                $request->{Options} = delete $request->{Options}->{Option};

                $request = $self->Obj2JSON($request);
            }
            else {
                $request = $self->Obj2JSONRPC( "CreateAccessCode", $request );
            }
        }
    }
    else {
        $request = $self->Obj2ARRAY($request);
    }

    if ( $self->debug ) {
        print "Request String for CreateAccessCode: \n";
        print STDERR Dumper( \$request ) . "\n";
    }

    my $method   = 'CreateAccessCode' . $Request_Method;
    my $response = $self->$method($request);

    if ( $self->debug ) {
        print "Response String for CreateAccessCode: \n";
        print STDERR Dumper( \$response ) . "\n";
    }

    # Convert Response Back TO An Object
    my $result;
    if ( $Request_Method ne 'SOAP' ) {
        if ( $Request_Format eq "XML" ) {
            if ( $Request_Method ne 'RPC' ) {
                $result = $self->XML2Obj($response);
            }
            else {
                $result = $self->RPCXML2Obj($response);
            }
        }
        else {
            if ( $Request_Method ne 'RPC' ) {
                $result = $self->JSON2Obj($response);
            }
            else {
                $result = $self->JSONRPC2Obj($response);
            }
        }
    }
    else {
        $result = $request;
    }

    # Is Debug Mode
    if ( $self->debug ) {
        print "Response Object for CreateAccessCode: \n";
        print STDERR Dumper( \$result ) . "\n";
    }

    return $result;
}

sub CreateAccessCodeREST {
    my ( $self, $request ) = @_;

    return $self->PostToRapidAPI(
        $self->urls->{'PaymentService.REST'} . "AccessCodes", $request );
}

sub GetAccessCodeResult {
    my ( $self, $request ) = @_;

    if ( $self->debug ) {
        print STDERR "Request Ojbect for GetAccessCodeResult: \n";
        print STDERR Dumper( \$request ) . "\n";
    }

    my $AccessCode     = $request->AccessCode;
    my $Request_Method = $self->Request_Method;
    my $Request_Format = $self->Request_Format;

    ## Request_Method eq 'RPC' is not implemented yet
    $Request_Method = 'REST' if $Request_Method eq 'RPC';

    if ( $Request_Method ne 'SOAP' ) {
        if ( $Request_Format eq "XML" ) {
            if ( $Request_Method ne 'RPC' ) {
                $request = $self->Obj2XML( $request, 'GetAccessCodeResult' );
            }
            else {
                $request = $self->Obj2RPCXML( "GetAccessCodeResult", $request );
            }
        }
        else {
            if ( $Request_Method ne 'RPC' ) {
                $request = $self->Obj2JSON($request);
            }
            else {
                $request =
                  $self->Obj2JSONRPC( "GetAccessCodeResult", $request );
            }
        }
    }
    else {
        $request = $self->Obj2ARRAY($request);
    }

    if ( $self->debug ) {
        print "Request String for GetAccessCodeResult: \n";
        print STDERR Dumper( \$request ) . "\n";
    }

    my $method = 'GetAccessCodeResult' . $Request_Method;
    my $response = $self->$method( $request, $AccessCode );

    if ( $self->debug ) {
        print "Response String for GetAccessCodeResult: \n";
        print STDERR Dumper( \$response ) . "\n";
    }

    # Convert Response Back TO An Object
    my $result;
    if ( $Request_Method ne 'SOAP' ) {
        if ( $Request_Format eq "XML" ) {
            if ( $Request_Method ne 'RPC' ) {
                $result = $self->XML2Obj($response);
            }
            else {
                $result = $self->RPCXML2Obj($response);
            }
        }
        else {
            if ( $Request_Method ne 'RPC' ) {
                $result = $self->JSON2Obj($response);
            }
            else {
                $result = $self->JSONRPC2Obj($response);
            }
        }
    }
    else {
        $result = $request;
    }

    # Is Debug Mode
    if ( $self->debug ) {
        print "Response Object for GetAccessCodeResult: \n";
        print STDERR Dumper( \$result ) . "\n";
    }

    return $result;
}

sub GetAccessCodeResultREST {
    my ( $self, $request, $AccessCode ) = @_;

    return $self->PostToRapidAPI(
        $self->urls->{'PaymentService.REST'} . "AccessCode/" . $AccessCode,
        $request, 0 );
}

sub Transaction {
    my ( $self, $request ) = @_;

    if ( $self->debug ) {
        print STDERR "Request Ojbect for Transaction: \n";
        print STDERR Dumper( \$request ) . "\n";
    }

    my $Request_Method = $self->Request_Method;
    my $Request_Format = $self->Request_Format;

    ## Request_Method eq 'RPC' is not implemented yet
    $Request_Method = 'REST' if $Request_Method eq 'RPC';

    if ( $Request_Method ne 'SOAP' ) {
        if ( $Request_Format eq "XML" ) {
            if ( $Request_Method ne 'RPC' ) {
                $request = $self->Obj2XML( $request, 'Transaction' );
            }
            else {
                $request = $self->Obj2RPCXML( "Transaction", $request );
            }
        }
        else {
            if ( $Request_Method ne 'RPC' ) {

                # fixes
                $request            = $self->Obj2ARRAY($request);
                $request->{Items}   = delete $request->{Items}->{LineItem};
                $request->{Options} = delete $request->{Options}->{Option};

                $request = $self->Obj2JSON($request);
            }
            else {
                $request = $self->Obj2JSONRPC( "Transaction", $request );
            }
        }
    }
    else {
        $request = $self->Obj2ARRAY($request);
    }

    if ( $self->debug ) {
        print "Request String for Transaction: \n";
        print STDERR Dumper( \$request ) . "\n";
    }

    my $method   = 'Transaction' . $Request_Method;
    my $response = $self->$method($request);

    if ( $self->debug ) {
        print "Response String for Transaction: \n";
        print STDERR Dumper( \$response ) . "\n";
    }

    # Convert Response Back TO An Object
    my $result;
    if ( $Request_Method ne 'SOAP' ) {
        if ( $Request_Format eq "XML" ) {
            if ( $Request_Method ne 'RPC' ) {
                $result = $self->XML2Obj($response);
            }
            else {
                $result = $self->RPCXML2Obj($response);
            }
        }
        else {
            if ( $Request_Method ne 'RPC' ) {
                $result = $self->JSON2Obj($response);
            }
            else {
                $result = $self->JSONRPC2Obj($response);
            }
        }
    }
    else {
        $result = $request;
    }

    # Is Debug Mode
    if ( $self->debug ) {
        print "Response Object for Transaction: \n";
        print STDERR Dumper( \$result ) . "\n";
    }

    return $result;
}

sub TransactionREST {
    my ( $self, $request ) = @_;

    return $self->PostToRapidAPI(
        $self->urls->{'PaymentService.REST'} . "Transaction", $request );
}

sub PostToRapidAPI {
    my ( $self, $url, $request, $is_post ) = @_;

    $is_post = 1 unless defined $is_post;
    my $Request_Format = $self->Request_Format;

    my $content_type;
    if ( $Request_Format eq "XML" ) {
        $content_type = "text/xml";
    }
    else {
        $content_type = "application/json";
    }

    my $ua = $self->ua;
    $ua->credentials( $self->username, $self->password );
    my $resp;
    if ($is_post) {
        $resp = $ua->post(
            $url,
            Content        => $request,
            'Content-Type' => $content_type
        );
    }
    else {
        $resp = $ua->get(
            $url,
            Content        => $request,
            'Content-Type' => $content_type
        );
    }

    unless ( $resp->is_success ) {
        my $r =
          { TransactionStatus => 0, ResponseMessage => $resp->status_line };
        if ( $Request_Format eq 'XML' ) {
            return $self->Obj2XML( $r, 'Error' );
        }
        else {
            return $self->Obj2JSON($r);
        }

# print '<h2>POST Error: ' . $resp->status_line . ' URL: ' . $url. ' </h2> <pre>';
# die Dumper(\$resp);
    }

    return $resp->decoded_content;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::eWAY::RapidAPI - eWAY RapidAPI V3

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    use Business::eWAY::RapidAPI;

    my $rapidapi = Business::eWAY::RapidAPI->new(
        username => "44DD7C70Jre1dVgIsULcEyi+A+/cX9V5SAHkIiyVdWrHRG2tZm0rdintfZz85Pa/kGwq/1",
        password => "Abcd1234",
    );

=head1 DESCRIPTION

eWAY RapidAPI L<http://www.eway.com.au/developers/api/rapid-3-0>

check L<https://github.com/fayland/p5-Business-eWAY-RapidAPI/tree/master/examples/web> for usage demo.

=head2 METHODS

=head3 CONSTRUCTION

    my $rapidapi = Business::eWAY::RapidAPI->new(
        mode => 'test',
        username => "44DD7C70Jre1dVgIsULcEyi+A+/cX9V5SAHkIiyVdWrHRG2tZm0rdintfZz85Pa/kGwq/1",
        password => "Abcd1234",
    );

=over 4

=item * mode

default 'live'

=item * username

required

=item * password

required

=item * debug

default 0

=back

=head3 CreateAccessCode

request AccessCode by submit customer/shippingaddress/payment/redirectUrl etc.

    ## Create AccessCode Request Object
    my $request = Business::eWAY::RapidAPI::CreateAccessCodeRequest->new();

    ## Populate values for Customer Object
    if (defined $q->param('txtTokenCustomerID')){
        $request->Customer->TokenCustomerID($q->param('txtTokenCustomerID'));
    };
    $request->Customer->Reference( $q->param('txtCustomerRef') );
    $request->Customer->Title( $q->param('ddlTitle') );
    # Note: FirstName is Required Field When Create/Update a TokenCustomer
    $request->Customer->FirstName( $q->param('txtFirstName') );
    # Note: LastName is Required Field When Create/Update a TokenCustomer
    $request->Customer->LastName( $q->param('txtLastName') );
    $request->Customer->CompanyName( $q->param('txtCompanyName') );
    $request->Customer->JobDescription( $q->param('txtJobDescription') );
    $request->Customer->Street1( $q->param('txtStreet1') );
    $request->Customer->Street2( $q->param('txtStreet2') );
    $request->Customer->City( $q->param('txtCity') );
    $request->Customer->State( $q->param('txtState') );
    $request->Customer->PostalCode( $q->param('txtPostalcode') );
    # Note: Country is Required Field When Create/Update a TokenCustomer
    $request->Customer->Country( $q->param('txtCountry') );
    $request->Customer->Email( $q->param('txtEmail') );
    $request->Customer->Phone( $q->param('txtPhone') );
    $request->Customer->Mobile( $q->param('txtMobile') );
    $request->Customer->Comments("Some Comments Here");
    $request->Customer->Fax("0131 208 0321");
    $request->Customer->Url("http://www.yoursite.com");

    ## Populate values for ShippingAddress Object.
    ## This values can be taken from a Form POST as well. Now is just some dummy data.
    $request->ShippingAddress->FirstName("John");
    $request->ShippingAddress->LastName("Doe");
    $request->ShippingAddress->Street1("9/10 St Andrew");
    $request->ShippingAddress->Street2(" Square");
    $request->ShippingAddress->City("Edinburgh");
    $request->ShippingAddress->State("");
    $request->ShippingAddress->Country("gb");
    $request->ShippingAddress->PostalCode("EH2 2AF");
    $request->ShippingAddress->Email('sales@eway.co.uk');
    $request->ShippingAddress->Phone("0131 208 0321");
    # ShippingMethod, e.g. "LowCost", "International", "Military". Check the spec for available values.
    $request->ShippingAddress->ShippingMethod("LowCost");

    ## Populate values for LineItems
    my $item1 = Business::eWAY::RapidAPI::LineItem->new();
    $item1->SKU("SKU1");
    $item1->Description("Description1");
    my $item2 = Business::eWAY::RapidAPI::LineItem->new();
    $item2->SKU("SKU2");
    $item2->Description("Description2");
    $request->Items->LineItem([ $item1, $item2 ]);

    ## Populate values for Options
    my $opt1 = Business::eWAY::RapidAPI::Option->new(Value => $q->param('txtOption1'));
    my $opt2 = Business::eWAY::RapidAPI::Option->new(Value => $q->param('txtOption2'));
    my $opt3 = Business::eWAY::RapidAPI::Option->new(Value => $q->param('txtOption3'));
    $request->Options->Option([$opt1, $opt2, $opt3]);

    $request->Payment->TotalAmount($q->param('txtAmount'));
    $request->Payment->InvoiceNumber($q->param('txtInvoiceNumber'));
    $request->Payment->InvoiceDescription( $q->param('txtInvoiceDescription') );
    $request->Payment->InvoiceReference( $q->param('txtInvoiceReference') );
    $request->Payment->CurrencyCode( $q->param('txtCurrencyCode') );

    ## Url to the page for getting the result with an AccessCode
    $request->RedirectUrl($q->param('txtRedirectURL'));
    ## Method for this request. e.g. ProcessPayment, Create TokenCustomer, Update TokenCustomer & TokenPayment
    $request->Method($q->param('ddlMethod'));

    my $result = $rapidapi->CreateAccessCode($request);

    ## Save result into Session. payment.pl and results.pl will retrieve this result from Session
    $session->param('TotalAmount', $q->param('txtAmount') );
    $session->param('InvoiceReference', $q->param('txtInvoiceReference') );
    $session->param('Response', $result );
    $session->flush();

    ## Check if any error returns
    if (defined( $result->{'Errors'} )) {
        $lblError = $rapidapi->ErrorsToString( $result->{'Errors'} );
    } else {
        ## All good then redirect to the payment page
        print $session->header(-location => 'payment.pl');
        exit();
    }

    ## $result is HASHREF contains
    ## FormActionURL
    ## AccessCode

=head3 GetAccessCodeResult

get payment result by previous stored AccessCode

    my $request = Business::eWAY::RapidAPI::GetAccessCodeResultRequest->new();
    $request->AccessCode($q->param('AccessCode'));

    ## Call RapidAPI to get the result
    my $result = $rapidapi->GetAccessCodeResult($request);

    ## Check if any error returns
    my $lblError;
    if (defined($result->{'Errors'})) {
        $lblError = $rapidapi->ErrorsToString($result->{'Errors'});
    }

    ## $result is HASHREF contains:
    ## ResponseCode
    ## Options
    ## TransactionID
    ## ... etc.

=head3 Transaction

Direct Payment L<http://api-portal.anypoint.mulesoft.com/eway/api/eway-rapid-31-api/docs/reference/direct-connection>

    ## Create AccessCode Request Object
    my $request = Business::eWAY::RapidAPI::TransactionRequest->new();

    ## Populate values for Customer Object
    if (defined $q->param('txtTokenCustomerID')){
        $request->Customer->TokenCustomerID($q->param('txtTokenCustomerID'));
    };
    $request->Customer->Reference( $q->param('txtCustomerRef') );
    $request->Customer->Title( $q->param('ddlTitle') );
    # Note: FirstName is Required Field When Create/Update a TokenCustomer
    $request->Customer->FirstName( $q->param('txtFirstName') );
    # Note: LastName is Required Field When Create/Update a TokenCustomer
    $request->Customer->LastName( $q->param('txtLastName') );
    $request->Customer->CompanyName( $q->param('txtCompanyName') );
    $request->Customer->JobDescription( $q->param('txtJobDescription') );
    $request->Customer->Street1( $q->param('txtStreet1') );
    $request->Customer->Street2( $q->param('txtStreet2') );
    $request->Customer->City( $q->param('txtCity') );
    $request->Customer->State( $q->param('txtState') );
    $request->Customer->PostalCode( $q->param('txtPostalcode') );
    # Note: Country is Required Field When Create/Update a TokenCustomer
    $request->Customer->Country( $q->param('txtCountry') );
    $request->Customer->Email( $q->param('txtEmail') );
    $request->Customer->Phone( $q->param('txtPhone') );
    $request->Customer->Mobile( $q->param('txtMobile') );
    $request->Customer->Comments("Some Comments Here");
    $request->Customer->Fax("0131 208 0321");
    $request->Customer->Url("http://www.yoursite.com");

    $request->Customer->CardDetails->Number('4444333322221111');
    $request->Customer->CardDetails->Name('Card Holder Name');
    $request->Customer->CardDetails->ExpiryMonth('12');
    $request->Customer->CardDetails->ExpiryYear('16');
    $request->Customer->CardDetails->CVN('123');
    # $request->Customer->CardDetails->StartMonth('11');
    # and others like StartYear, IssueNumber

    ## Populate values for ShippingAddress Object.
    ## This values can be taken from a Form POST as well. Now is just some dummy data.
    $request->ShippingAddress->FirstName("John");
    $request->ShippingAddress->LastName("Doe");
    $request->ShippingAddress->Street1("9/10 St Andrew");
    $request->ShippingAddress->Street2(" Square");
    $request->ShippingAddress->City("Edinburgh");
    $request->ShippingAddress->State("");
    $request->ShippingAddress->Country("gb");
    $request->ShippingAddress->PostalCode("EH2 2AF");
    $request->ShippingAddress->Email('sales@eway.co.uk');
    $request->ShippingAddress->Phone("0131 208 0321");
    # ShippingMethod, e.g. "LowCost", "International", "Military". Check the spec for available values.
    $request->ShippingAddress->ShippingMethod("LowCost");

    ## Populate values for LineItems
    my $item1 = Business::eWAY::RapidAPI::LineItem->new();
    $item1->SKU("SKU1");
    $item1->Description("Description1");
    my $item2 = Business::eWAY::RapidAPI::LineItem->new();
    $item2->SKU("SKU2");
    $item2->Description("Description2");
    $request->Items->LineItem([ $item1, $item2 ]);

    $request->Payment->TotalAmount($q->param('txtAmount'));
    $request->Payment->InvoiceNumber($q->param('txtInvoiceNumber'));
    $request->Payment->InvoiceDescription( $q->param('txtInvoiceDescription') );
    $request->Payment->InvoiceReference( $q->param('txtInvoiceReference') );
    $request->Payment->CurrencyCode( $q->param('txtCurrencyCode') );

    ## Method for this request. eg. ProcessPayment, CreateTokenCustomer, UpdateTokenCustomer, TokenPayment
    $request->method('ProcessPayment');

    ## Method for this request. e.g. Purchase, MOTO, Recurring
    $request->TransactionType('Purchase');

    my $result = $rapidapi->Transaction($request);

    ## Check if any error returns
    if (defined( $result->{'Errors'} )) {
        $lblError = $rapidapi->ErrorsToString( $result->{'Errors'} );
    } else {
        ## All good. go ahead
        print "Transaction done.\n";
        exit();
    }

    ## $result is HASHREF contains
    ## TransactionID
    ## TransactionStatus etc.

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
