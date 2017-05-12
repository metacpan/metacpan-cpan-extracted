package Business::OnlinePayment::IPayment;

use 5.010001;
use strict;
use warnings;

# preparation
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use Business::OnlinePayment::IPayment::Response;
use Business::OnlinePayment::IPayment::Transaction;
use Business::OnlinePayment::IPayment::Return;
use Digest::MD5 qw/md5_hex/;
use URI;

use Business::OnlinePayment 3;
use Moo;

use base 'Business::OnlinePayment';

# use Log::Report mode => 'DEBUG';

=head1 NAME

Business::OnlinePayment::IPayment - Checkout via Ipayment Silent Mode

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 DESCRIPTION

This module provides an interface for online payments via gateway, using the
IPayment silent mode (L<https://ipayment.de>).

It supports payments, capture and reverse operations, and vault-related
functions.

=head1 SYNOPSIS

  use Business::OnlinePayment::IPayment;
  my %account = (
                 accountid => 99999,
                 trxuserid => 99998,
                 trxpassword => 0,
                 adminactionpassword => '5cfgRT34xsdedtFLdfHxj7tfwx24fe',
                 app_security_key => 'testtest',
                 wsdl_file => $wsdl_file,
                 success_url => 'http://example.net/checkout-payment',
                 failure_url => 'http://example.net/checkout-success',
                 hidden_trigger_rul => 'http://example.net/trigger',
                );
  
  
  my $secbopi = Business::OnlinePayment::IPayment->new(%account);
  $secbopi->transaction(transactionType => 'preauth',
                        trxAmount => 5000);
  # see Business::OnlinePayment::IPayment::Transaction for available options

  $response = $ua->post('https://ipayment.de/merchant/99999/processor/2.0/',
                        { ipayment_session_id => $secbopi->session_id,
                          addr_name => "Mario Pegula",
                          silent => 1,
                          cc_number => "4111111111111111",
                          cc_checkcode => "",
                          cc_expdate_month => "02",
                          trx_securityhash => $secbopi->trx_securityhash,
                          cc_expdate_year => "2014" });
  
  
=head2 ACCESSORS

=head3 Fixed values (accountData and processorUrls)

The following attributes should and can be set only in the
constructor, as they are pretty much fixed values.

=over 4

=item wsdl_file

The name of th WSDL file. It should be a local file.

=cut

has wsdl_file => (is => 'rw');

=item accountid

The Ipayment account id (the one put into the CGI url). Integer.

=cut

has accountid => (is => 'rw',
                  isa => sub {
                      die "Not an integer" unless $_[0] =~ m/^[0-9]+$/s
                  });

=item trxuserid

The application ID, you can in your ipayment configuration menu read
using  Anwendung > Details. Integer

=cut

has trxuserid => (is => 'rw',
                  isa => sub {
                      die "Not an integer" unless $_[0] =~ m/^[0-9]+$/s
                  });

=item trxpassword

For each application, there is an application password which
automatically ipayment System is presented. The password consists of
numbers. You will find the application password in your ipayment
Anwendungen > Details

B<This is not the account password!>

=cut

has trxpassword => (is => 'rw');

=item adminactionpassword

The admin password.

B<This is not the account password!>

=cut 

has adminactionpassword => (is => 'rw');


=item app_security_key

If this attribute is set, we will (and shall) send a checksum for the
parameters.

B<Without this, we are opened to tampering>

=cut

has app_security_key => (is => 'rw');


=item accountData

Accessor to retrieve the hash with the account data details. The
output will look like this:

 accountData => {
                 accountid => 99999,
                 trxuserid => 99999,
                 trxpassword =>0,
                 adminactionpassword => '5cfgRT34xsdedtFLdfHxj7tfwx24fe'}


=cut

sub accountData {
    my $self = shift;
    my %account_data = (  # mandatory
                        accountId => $self->accountid,
                        trxuserId => $self->trxuserid,
                        trxpassword => $self->trxpassword
                        );
    my $adminpass = $self->adminactionpassword;
    if (defined $adminpass) {
        $account_data{adminactionpassword} = $adminpass;
    }
    return \%account_data;
}

=item success_url 

Mandatory (for us) field, where to redirect the user in case of success.

CGI-Name: C<redirect_url>

I<In silent mode, the parameters are always passed by GET to the
script.> (no need to C<redirect_action>)

=cut

has success_url => (is => 'rw',
                    isa => sub { die "Missing success url" unless $_[0] },
                    default => sub { die "Missing success url" },
                   );

=item failure_url

Mandatory (for us) field, where to redirect the user in case of failure.

CGI Name: C<silent_error_url>
Data type: String

This URL is more in case of failure of ipayment system with the error information and parameters B<using the GET method>. This URL must point to a CGI script that can handle the paramaters.

=cut

has failure_url => (is => 'rw',
                    isa => sub { die "Missing failure url" unless $_[0] },
                    default => sub { die "Missing success url" },
                   );


=item hidden_trigger_url

Optional url for the hidden trigger.

=cut

has hidden_trigger_url => (is => 'rw');


=item processorUrls

Return the hashref with the defined urls

=back

=cut

sub processorUrls {
    my $self = shift;
    return {
            redirectUrl => $self->success_url,
            silentErrorUrl => $self->failure_url,
            hiddenTriggerUrl => $self->hidden_trigger_url
           };
}





=head3 error

This accessors point to a XML::Compile::SOAP backtrace. The object is
quite large and deeply nested, but it's there just in case we need it.

=cut

has error => (is => 'rwp');

=head3 debug

Every call to session id stores the trace into this attribute.

=cut

has debug => (is => 'rwp');

=head3 trx_obj

Attribute to hold a L<Business::OnlinePayment::IPayment::Transaction> object

=cut

has trx_obj => (is => 'rwp');

=head3 transaction

Constructor for the object above. All the argument are passed verbatim
to the L<Business::OnlinePayment::IPayment::Transaction> constructor,
then the object is stored.

=cut

sub transaction {
    my $self = shift;
    my %trx = @_;
    my $trxdata = Business::OnlinePayment::IPayment::Transaction->new(%trx);
    $self->_set_trx_obj($trxdata);
}


=head2 METHODS

=over 4

=item session_id

This is the main method to call. The session is not stored in the object, because it can used only B<once>. So calling session_id will send the data to the SOAP service and retrieve the session key.

=cut

sub session_id {
    my $self = shift;
    # clean eventually stale data
    $self->_set_error(undef);

    my %args = (
                # fixed values
                accountData => $self->accountData,
                processorUrls => $self->processorUrls,
                # then the transaction
                transactionType => $self->trx_obj->transactionType,
                paymentType => $self->trx_obj->paymentType,
                transactionData => $self->trx_obj->transactionData,
               );
    # and the options, if needed
    if ($self->trx_obj->options) {
        $args{options} = $self->trx_obj->options;
    }

    # do the request passing the accountData
    my ($res, $trace) = $self->_get_soap_object('createSession')->(%args);
    $self->_set_debug($trace);

    # check if we got something valuable
    unless ($res and
            ref($res) eq 'HASH' and 
            exists $res->{createSessionResponse}->{sessionId}) {
        # ok, we got an error. Save the trace to the error and return
        $self->_set_error($trace);
        return undef;
    }

    return $res->{createSessionResponse}->{sessionId};
    # please note that we don't store the sessionId. It's a fire and forget.
}


=item raw_response_hash

Debug for the arguments passed to IPayment::Return;

=cut

has raw_response_hash => (is => 'rwp');



=item capture($ret_trx_number, $amount, $currency, $opts)

Charge an amount previously preauth'ed. C<$amount> and C<$currency>
are optional and may be used to charge partial amounts. C<$amount> and
C<$currency> follow the same rules of C<trxAmount> and C<trxCurrency>
of L<Business::OnlinePayment::IPayment::Transaction> (no decimal,
usually multiply by 100).

The last optional argument should be a hashref with additional
parameters to pass to transactionData (notably shopperId).

=cut

sub _do_post_payment_op {
    my ($self, $op, $number, $amount, $currency, $trxdetails) = @_;
    unless (defined $number) {
        $self->_set_error("Missing transaction number");
        return undef;
    }
    die "Wrong usage, missing operation" unless $op;
    my %args = (
                accountData => $self->accountData,
                origTrxNumber => $number,
                );
    # amount is always mandatory for transactionData
    if ($amount) {
        my %trxdata;
        die "Wrong amount $amount!\n" unless ($amount =~ m/^[1-9][0-9]*$/s);

        unless ($currency) {
            $currency = 'EUR'
        }
        unless ($currency =~ m/^[A-Z]{3}$/s) {
            die "Wrong currency name!\n";
        }
        
        %trxdata = (
                    trxAmount => $amount,
                    trxCurrency => $currency,
                    );
        if ($trxdetails and
            (ref($trxdetails) eq 'HASH')
            and %$trxdetails) {
            foreach my $k (keys %$trxdetails) {
                unless ($trxdata{$k}) {
                    $trxdata{$k} = $trxdetails->{$k}
                }
            }
        }
        $args{transactionData} = \%trxdata;
    }

    die "Wrong operation" unless ($op eq 'capture' or
                                  $op eq 'refund' or
                                  $op eq 'reverse');

    my ($res, $trace) = $self->_get_soap_object($op)->(%args);
    $self->_set_debug($trace);
    $self->_set_raw_response_hash($res);
    if ($res and ref($res) eq 'HASH' and
        exists $res->{"${op}Response"}->{ipaymentReturn}) {
        return Business::OnlinePayment::IPayment::Return
          ->new($res->{"${op}Response"}->{ipaymentReturn});
    }
    else {
        $self->_set_error($trace);
        return undef;
    }
}

=item datastorage_op($datastorage_id)

After calling C<transaction>, if you have a valid datastorage id, you
may want to use that instead of creating a session and use the form.

This method will do a SOAP request to the Ipayment server, using the
transaction details provided in the call to C<transaction>, and do the
requested operation. So far it's supported preauth and auth. The
capture and other operations should be done via its own method (which
don't require the datastorage, but simply the previous transaction's
id).

=cut

sub datastorage_op {
    my ($self, $id) = @_;
    return unless $id;
    
    $self->_set_error(undef);
    # this should be fully populated by now
    my %args = (
                accountData => $self->accountData,
                paymentData => {
                                storageData => {
                                                fromDatastorageId => $id,
                                               },
                               },
                transactionData => $self->trx_obj->transactionData,
               );
    my $operation = $self->trx_obj->transactionType;
    # append the options if needed
    if ($self->trx_obj->options) {
        $args{options} = $self->trx_obj->options;
    }
    my ($res, $trace) = $self->_get_soap_object($operation)->(%args);
    $self->_set_debug($trace);
    $self->_set_raw_response_hash($res);

    # in the trasaction object the call is defined as in CGI, but we
    # need the SOAP one
    my $op = $self->_translate_to_soap_call($operation);

    if ($res and ref($res) eq 'HASH' and
        exists $res->{"${op}Response"}->{ipaymentReturn}) {
        return Business::OnlinePayment::IPayment::Return
          ->new($res->{"${op}Response"}->{ipaymentReturn});
    }
    else {
        $self->_set_error($trace);
        return undef;
    }
}

=item expire_datastorage($id)

Given the storage id passed as argument, expire it. Keep in mind that
expiring it multiple times returns always true, so the return code is
not really interesting.

It returns 0 if the storage didn't exist.

=cut

sub expire_datastorage {
    my ($self, $id) = @_;
    return unless $id;
    my $op = 'expireDatastorage';
    my %args = (
                accountData => $self->accountData,
                datastorageId => $id,
               );
    my ($res, $trace) = $self->_get_soap_object($op)->(%args);
    $self->_set_debug($trace);
    $self->_set_raw_response_hash($res);
    if ($res and ref($res) eq 'HASH' and
        exists $res->{"${op}Response"}->{expireDatastorageReturn}) {
        return $res->{"${op}Response"}->{expireDatastorageReturn};
    }
    return;
}


sub capture {
    my ($self, $number, $amount, $currency, $opts) = @_;
    # init the soap, if not already
    return $self->_do_post_payment_op(capture => $number,
                                      $amount, $currency, $opts);
}

=item reverse($ret_trx_number)

Release the amount previously preauth'ed, passing the original
transaction number. No partial amount can be released, and will
succeed only if no charging has been done.

=cut


sub reverse {
    my ($self, $number) = @_;
    # we don't pass $amount and $currency
    return $self->_do_post_payment_op(reverse => $number);
}

=item refund($ret_trx_number, $amount, $currency, $opts)

Refund the given amount. Please note that we have to pass the
transaction number B<of the capture>, not the C<preauth> one.

The last optional argument should be a hashref with additional
parameters to pass to transactionData (notably shopperId).

=cut

sub refund {
    my ($self, $number, $amount, $currency, $opts) = @_;
    return $self->_do_post_payment_op(refund => $number,
                                      $amount, $currency, $opts);
}

# accessors to soap objects

has _soap_createSession => (is => 'rw');
has _soap_capture => (is => 'rw');
has _soap_reverse => (is => 'rw');
has _soap_refund => (is => 'rw');
has _soap_preAuthorize => (is => 'rw');
has _soap_authorize => (is => 'rw');
has _soap_expireDatastorage => (is => 'rw');

sub _get_soap_object {
    my ($self, $op) = @_;
    my $call = $self->_translate_to_soap_call($op);
    my $accessor = "_soap_" . $call;
    my $obj = $self->$accessor;
    return $obj if $obj;
    my $wsdl = XML::Compile::WSDL11->new($self->wsdl_file);
    my $client = $wsdl->compileClient($call);
    # set the object
    $self->$accessor($client);
    return $self->$accessor;
}

# this method may be used for to do a sanity check, as it will die on
# undef/wrong values.

sub _translate_to_soap_call {
    my ($self, $op) = @_;
    die "No operation provided!" unless $op;
    my %hash = (capture => 'capture',
                reverse =>  'reverse',
                refund =>  'refund',
                preauth => 'preAuthorize',
                auth => 'authorize',
                authorize =>  'authorize',
                preAuthorize => 'preAuthorize',
                createSession => 'createSession',
                expireDatastorage => 'expireDatastorage',
               );
    die "Wrong call $op!" unless $hash{$op};
    return $hash{$op};
}

=back

=head2 SOAP specification

  Name: createSession
  Binding: ipaymentBinding
  Endpoint: https://ipayment.de/service/3.0/
  SoapAction: createSession
  Input:
    use: literal
    namespace: https://ipayment.de/service_v3/binding
    message: createSessionRequest
    parts:
      accountData: https://ipayment.de/service_v3/extern:AccountData
      transactionData: https://ipayment.de/service_v3/extern:TransactionData
      transactionType: https://ipayment.de/service_v3/extern:TransactionType
      paymentType: https://ipayment.de/service_v3/extern:PaymentType
      options: https://ipayment.de/service_v3/extern:OptionData
      processorUrls: https://ipayment.de/service_v3/extern:ProcessorUrlData
  Output:
    use: literal
    namespace: https://ipayment.de/service_v3/binding
    message: createSessionResponse
    parts:
      sessionId: http://www.w3.org/2001/XMLSchema:string
  Style: rpc
  Transport: http://schemas.xmlsoap.org/soap/http
  

=head2 SECURITY

=over 4

=item trx_securityhash

If we have a security key, we trigger the hash generation, so we can
double check the result.

CGI Name: C<trx_securityhash>
Data type: string, maximum 32 characters

Security hash of CGI command concatenating Id, amount, currency,
password, Transaction Security Key (should be set in the configuration
menu using ipayment). The hash is C<trxuser_id>, C<trx_amount>,
C<trx_currency>, C<trxpassword> and the I<transaction security key>.

  md5_hex($trxuser_id . $trx_amount . $trx_currency . $trxpassword . $sec_key); 

  perl -e 'use Digest::MD5 qw/md5_hex/;
                print  md5_hex("99998" . 5000 . "EUR" . 0 .  "testtest"), "\n";'
  # => then in the form
  <input type="hidden" name="trx_securityhash"
         value="db4812171baef817dec0cd56c0f5c8cd">

=cut

sub trx_securityhash {
    my $self = shift;
    unless ($self->app_security_key) {
        warn "hash requested, but app_security_key wasn't provided!\n";
        return;
    }
    return md5_hex($self->trxuserid .
                   $self->trx_obj->trxAmount .
                   $self->trx_obj->trxCurrency .
                   $self->trxpassword .
                   $self->app_security_key);
}

=back

=head2 UTILITIES

=head3 get_response_obj($rawuri) or get_response_obj(%params)

To be sure the transaction happened as aspected, we have to check this back.
Expected hash:

Success:

  'ret_transtime' => '08:42:05',       'ret_transtime' => '08:42:03',
  'ret_errorcode' => '0',              'ret_errorcode' => '0',
  'redirect_needed' => '0',            'redirect_needed' => '0',
  'ret_transdate' => '14.03.13',       'ret_transdate' => '14.03.13',
  'addr_name' => 'Mario Pegula',       'addr_name' => 'Mario Rossi',
  'trx_paymentmethod' => 'VisaCard',   'trx_paymentmethod' => 'AmexCard',
  'ret_authcode' => '',                'ret_authcode' => '',
  'trx_currency' => 'EUR',             'trx_currency' => 'EUR',
  'ret_url_checksum' => 'md5sum',
  'ret_param_checksum' => 'md5sum',
  'ret_ip' => '88.198.37.147',         'ret_ip' => '88.198.37.147',
  'trx_typ' => 'preauth',              'trx_typ' => 'preauth',
  'ret_trx_number' => '1-83443831',    'ret_trx_number' => '1-83443830',
  'ret_status' => 'SUCCESS',           'ret_status' => 'SUCCESS',
  'trx_paymenttyp' => 'cc',            'trx_paymenttyp' => 'cc',
  'trx_paymentdata_country' => 'US',
  'trx_amount' => '5000',              'trx_amount' => '1000',
  'ret_booknr' => '1-83443831',        'ret_booknr' => '1-83443830',
  'trxuser_id' => '99998',             'trxuser_id' => '99999',
  'trx_remoteip_country' => 'DE'       'trx_remoteip_country' => 'DE'

Returns a L<Business::OnlinePayment::IPayment::Response> object, so you
can call ->is_success on it.

This is just a shortcut for

  Business::OnlinePayment::IPayment::Response->new(%params);

with C<my_security_key> and C<my_userid> inherited from the fixed
values of this class.

=cut

sub get_response_obj {
    my ($self, @args) = @_;
    my %details;
    # only one argument: we have an URI
    if (@args == 1) {
        my $raw_url = shift(@args);
        my $uri = URI->new($raw_url);
        %details = $uri->query_form;
        $details{raw_url} = $raw_url;
    }
    elsif ((@args % 2) == 0) {
        %details = @args;
    }
    else {
        die "Arguments to validate the response not provided "
          . "(paramaters or raw url";
    }
    unless (exists $details{my_security_key}) {
        $details{my_security_key} = $self->app_security_key;
    }
    unless (exists $details{my_userid}) {
        $details{my_userid}       = $self->trxuserid;
    }
    return Business::OnlinePayment::IPayment::Response->new(%details);
}

=head3 ipayment_cgi_location

Returns the correct url where the customer posts the CC data, which is simply:
L<https://ipayment.de/merchant/<Account-ID>/processor/2.0/>

=cut

sub ipayment_cgi_location {
    my $self = shift;
    return 'https://ipayment.de/merchant/' . $self->accountid
      . '/processor/2.0/';
}


=head2 Additional information

=head3 country

Country code of the cardholder of the current
L<Business::OnlinePayment::IPayment::Transaction> object

Being these information transaction specific, if a transaction has not
been initiated, the method will not do anything nor will return
anything.

UK will be translated to GB, and EI to IE.


=cut

sub country {
    my $self = shift;
    # 
    return unless $self->trx_obj;
    if (@_ == 1) {
        $self->trx_obj->addr_info->{country} = shift;
    }
    my $country = uc($self->trx_obj->addr_info->{country});
    return unless $country =~ m/^[A-Z]{2,3}$/s;
    if ($country eq 'UK') {
        return 'GB';
    }
    elsif ($country eq 'EI') {
        return 'IE';
    }
    else {
        return $country;
    }
}

=head1 TESTING

Test credit card numbers can be found here: L<https://ipayment.de/technik/cc_testnumbers.php4>.

=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-onlinepayment-ipayment at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-OnlinePayment-IPayment>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::OnlinePayment::IPayment


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-OnlinePayment-IPayment>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-OnlinePayment-IPayment>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-OnlinePayment-IPayment>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-OnlinePayment-IPayment/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Stefan Hornburg (Racke) C<racke@linuxia.de> for the initial
code, ideas and support.

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2014 Marco Pessotto.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Business::OnlinePayment::IPayment
