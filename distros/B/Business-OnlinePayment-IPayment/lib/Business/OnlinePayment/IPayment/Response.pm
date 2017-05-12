package Business::OnlinePayment::IPayment::Response;
use strict;
use warnings;
use utf8;
use Digest::MD5 qw/md5_hex/;
use Moo;

=encoding utf8

=head1 NAME

Business::OnlinePayment::IPayment::Response - Helper class for Ipayment responses

=head1 SYNOPSIS

  # where %params are the GET parameters
  $ipayres = Business::OnlinePayment::IPayment::Response->new(%params);

  $ipayres->set_credentials(
                          my_amount   => "5000",
                          my_currency => "EUR",
                          my_userid   => "99999",
                          my_security_key => "testtest",
                         );
  ok($ipayres->is_success && $ipayres->is_valid, "Payment looks ok");

=head1 DESCRIPTION

=head2 ACCESSORS

=over 4

=item ret_transtime

Time of transaction.

=cut

has ret_transtime           => (is => 'ro',
                                default => sub { return "" });

=item ret_transdate

Date of the transaction.

=cut 

has ret_transdate           => (is => 'ro',
                                default => sub { return "" });

=item ret_errorcode

The error code of 0 means that the transaction was successful. When in
a CGI integration mode parameter redirect_needed returned with the
value 1 is the only means that all data is correct and a redirect must
be running. The return value is meaningful only after a second call.

=cut

has ret_errorcode           => (is => 'ro',
                                default => sub { return "" });

=item redirect_needed

This parameter is set if the payment could not be completed because of
a redirect necessary.

=cut


=item ret_errormsg

Error message (in German). This is important to propagate to the web
interface.

=cut

has ret_errormsg            => (is => 'ro',
                                default => sub { return "" });


=item ret_additionalmsg

Additional Error message, sometimes in English, sometimes inexistent.

=cut

has ret_additionalmsg => (is => 'ro',
                          default => sub { return "" });

=item ret_fatalerror

This value is returned only if an error has occurred.

Based on this value, your shop offer the buyer the option of payment
data correct as long as there is no fatal error. Fatal errors are
usually disruptions in Bank network or other problems where a new
trial is expected no Improvement brings. Your customers, you can in
this case, a specific error message

=cut

has ret_fatalerror          => (is => 'ro',
                                default => sub { return "" });


has redirect_needed         => (is => 'ro',
                                default => sub { return "" });

=item addr_name

Data type: string, maximum 100 characters
Name of the buyer. This parameter is required for all payments.

=cut

has addr_name               => (is => 'ro',
                                default => sub { return "" });


=item addr_email

Data type: string, B<maximum 80 characters>

E-mail address of the buyer. If this field is filled in, the e-mail
address is checked for plausibility.

=cut

has addr_email => (is => 'ro',
                   default => sub { return "" });

=item addr_street

=cut

has addr_street => (is => 'ro',
                    default => sub { return "" });

=item addr_city

City

=cut

has addr_city => (is => 'ro',
                  default => sub { return "" });

=item addr_zip

ZIP code

=cut

has addr_zip => (is => 'ro',
                 default => sub { return "" });

=item addr_country

ISO country code (2 chars, not 3 as the documentation says)

=back

=cut

has addr_country => (is => 'ro',
                     default => sub { return "" });

=head3 Optional contact details

=over 4

=item addr_street2

Second street.

=cut

has addr_street2 => (is => 'ro',
                     default => sub { return "" });

=item addr_state

(USA only), two chars.

=cut 

has addr_state => (is => 'ro',
                   default => sub { return "" });

=item addr_telefon

Telephone, max 30 chars

=cut

has addr_telefon => (is => 'ro',
                     default => sub { return "" });

=item addr_telefax

Telefax, max 30 chars

=back

=cut

has addr_telefax => (is => 'ro',
                     default => sub { return "" });

=head3 Payment details

=over 4

=item trx_paymentmethod

In this parameter the name of the medium used, payment will be
returned. the For example, a credit card type (such as Visa or
MasterCard) or ELV.

=cut

has trx_paymentmethod       => (is => 'ro',
                                default => sub { return "" });

=item ret_authcode            

Authorization number of third party payment for this transaction or
other unique Identification of the payment the payment provider. The
parameters may in certain cases be empty.

=cut

has ret_authcode => (is => 'ro',
                     default => sub { return ""});


=item trx_currency            

Currency in which the payment is processed. There are all known
three-letter ISO Currency codes allowed. A list of known currency
codes, see L<https://ipayment.de/> under B<Technik>.

Note that the processing of payments in the currency must be agreed
with your payment provider.


=cut

has trx_currency            => (is => 'ro',
                                default => sub { return "" });


=item ret_url_checksum        

=cut

has ret_url_checksum        => (is => 'ro',
                                default => sub { return "" });


=item ret_param_checksum      

=cut

has ret_param_checksum      => (is => 'ro',
                                default => sub { return "" });


=item ret_ip                  

IP of the client who did the transaction

=cut

has ret_ip                  => (is => 'ro',
                                default => sub { return "" });


=item trx_typ                 

See C<transactionType> in L<Business::OnlinePayment::IPayment>

=cut

has trx_typ                 => (is => 'ro',
                                default => sub { return "" });


=item ret_trx_number          

If the status is C<SUCCESS>, here we have the Unique transaction
number (reservation number) of ipayment system. this number is
returned in the form of "x-xxxxxxx", where x is a single digit. with
this Transaction number, you can perform other actions such as
charging or cancellations.

=cut

has ret_trx_number          => (is => 'ro',
                                default => sub { return "" });


=item ret_status              

The possible values ​​are:

C<SUCCESS>: The transaction has been successfully completed.

C<ERROR>: In transaction processing, an error occurred.

C<REDIRECT>: To further processing must be performed a redirect (3-D
secure, verification needed)

=cut

has ret_status              => (is => 'ro',
                                default => sub { return "" });


=item trx_paymenttyp          

Values: C<cc> (Credit card), C<elv> (ELV), C<pp> (Prepaid payment)

=cut

has trx_paymenttyp          => (is => 'ro',
                                default => sub { return "" });


=item trx_paymentdata_country 

In this parameter, if possible, the ISO code of the country returned
to the the payment data belongs. The field contains, for example, for
credit card payments, the country the card-issuing bank and ELV
payments the bank country.

=cut

has trx_paymentdata_country => (is => 'ro',
                                default => sub { return "" });


=item trx_amount              

Amount to be debited. Enter the value in the B<smallest currency
unit>, for Example cents. B<Decimal points> or other characters except
numbers are B<not allowed>.

For example, the amount of EUR 10.00 is given as 1000 cents.

=cut

has trx_amount              => (is => 'ro',
                                default => sub { return "" });


=item ret_booknr              

Used for the checksum and apparently not documented.

=cut

has ret_booknr              => (is => 'ro',
                                default => sub { return "" });


=item trxuser_id              

See C<trxuserId> in Business::OnlinePayment::IPayment

=cut

has trxuser_id              => (is => 'ro',
                                default => sub { return "" });


=item trx_remoteip_country

Iso code of the IP which does the transaction

=back

=cut

has trx_remoteip_country    => (is => 'ro',
                                default => sub { return "" });

=head2 Payment data

Optional data returned by the Ipayment server if the cgi parameter
C<return_paymentdata_details> is set to 1 (no SOAP for this, you have
to add an hidded input field in the form).

The credit card number is returned masked with the last 4 digits
visible.

=over 4

=item paydata_cc_cardowner

=cut

has paydata_cc_cardowner => (is => 'ro',
                             default => sub { return "" });


=item paydata_cc_number

=cut

has paydata_cc_number => (is => 'ro',
                          default => sub { return "" });


=item paydata_cc_typ

=cut

has paydata_cc_typ => (is => 'ro',
                       default => sub { return "" });



=item paydata_cc_expdate

=cut

has paydata_cc_expdate => (is => 'ro',
                           default => sub { return "" });

=back

=cut


=head2 Setters needed for the hash checking

=head3 my_amount

You need to set the C<my_amount> attribute if you want to check
the hash.

=cut

has my_amount => (is => 'rw');

=head3 my_userid

Our trxuser_id 

=cut 

has my_userid => (is => 'rw');

=head3 my_currency

Our currency

=cut

has my_currency => (is => 'rw');

=head3 my_security_key

The security key

=cut

has my_security_key => (is => 'rw');

=head3 shopper_id

The cart->id of the transaction

=cut

has shopper_id => (is => 'rw');


=head3 invoice_text

In payment processing with the below payment provider you can use a
Specify text that is sent to the payment provider. This text if the
debiting more precisely describe. Depending on the payment providers
and credit cards out bender site This text is printed on the card
account of the customer and / or dealer. If this parameter is not set,
ipayment automatically uses the company name merchant that you
specified in the configuration menu ipayment under General Data

This can be sent into the options as C<options->{invoiceText}>

=cut

has invoice_text => (is => 'ro',
                     default => sub { return "" });

=head3 trx_user_comment

Comment that is stored in the transaction in ipayment system. this
comment is not sent to the bank or payment processor.

This can be sent into the options as C<options->{trxUserComment}>

=cut

has trx_user_comment => (is => 'ro',
                         default => sub { return "" });


=head2 Storage accessors

=head3 datastorage_expirydate

The date as returned by the ipayment server (like: 2008/09/15)

=cut

has datastorage_expirydate => (is => 'ro',
                               default => sub { return "" });

=head3 storage_id

The storage id for the current transaction.

=cut

has storage_id => (is => 'ro',
                   default => sub { return "" });


=head3 trx_issuer_avs_response

AVS related response.p. 62 of the doc

=cut

has trx_issuer_avs_response => (is => 'ro',
                                default => sub { return "" });

=head3 trx_payauth_status

3D-related response, p. 62 of the doc

=cut

has trx_payauth_status => (is => 'ro',
                           default => sub { return "" });



=head2 METHODS

=head3 set_credentials(%hash)

As a shortcut, you can set the above attribute using this method

=cut

sub set_credentials {
    my ($self, %args) = @_;
    if (defined $args{my_userid}) {
        $self->my_userid($args{my_userid});
    }
    if (defined $args{my_security_key}) {
        $self->my_security_key($args{my_security_key});
    }
    if (defined $args{my_amount}) {
        $self->my_amount($args{my_amount})
    }
    if (defined $args{my_currency}) {
        $self->my_currency($args{my_currency});
    }
}


=head3 is_success

Return true if the transaction was successful, undef otherwise

=cut

sub is_success {
    my $self = shift;
    if ($self->ret_status eq 'SUCCESS' and !$self->ret_errorcode) {
        return 1;
    }
    else {
        return undef;
    }
}

=head3 is_error

Return true if the transaction raised an error, undef otherwise.
You can access the German error message with the accessor
C<ret_errormsg>

=cut

sub is_error {
    my $self = shift;
    if ($self->ret_status eq 'ERROR') {
        return 1;
    }
    else {
        return undef;
    }
}


=head3 is_valid

Return true if the servers return a checksum (for this you have to
build a session with C<trx_securityhash> for this to work, and you
shoul use the app_security_key).

CGI Name: C<ret_param_checksum>
Data type: String

The hash is the md5sum of the concatenation of C<trxuser_id>
C<trx_amount>, C<trx_currency>, C<ret_authcode>, C<ret_booknr> and
I<transaction security key>.

If one of the fields is empty or not returned, use the empty string.


The checksum is only in case of success of a transaction
(ret_errorcode = 0 and redirect_ needed = 0) are available.

  perl -e 'use Digest::MD5 qw/md5_hex/;
      print md5_hex("99998" . 5000 . "EUR" . "" . "1-83400472" .  "testtest");'

  # => 6bff5d51a44f048e887d1ab7677c4798 and it matches

=head3 validation_errors

With this accessor you are able to lookup the validation errors found

=cut

has validation_errors => (is => 'rwp');

sub _add_valid_error {
    my $self = shift;
    my $error = shift;
    my $olderr = $self->validation_errors || "";
    $self->_set_validation_errors($olderr . " " . $error);
}

sub is_valid {
    my $self = shift;
    # clear the error stack
    $self->_set_validation_errors("");
    unless ($self->ret_param_checksum) {
        $self->_set_validation_errors("No checksum provided!");
        return 0;
    }

    die "Validation asked, but you didn't provide the security key!\n"
      unless $self->my_security_key;
    
    
    unless ($self->my_amount) {
        $self->_add_valid_error("Using the data passed by the server!");
        $self->my_amount($self->trx_amount);
    }
    unless ($self->my_currency) {
        $self->_add_valid_error("Using the currency passed by the server!");
        $self->my_currency($self->trx_currency);
    }
    unless ($self->my_userid) {
        $self->_add_valid_error("Using the userid passed by the server!");
        $self->my_userid($self->trxuser_id);
    }
    
    my $expectedhash = md5_hex($self->my_userid .
                               $self->my_amount .
                               $self->my_currency .
                               $self->ret_authcode .
                               $self->ret_booknr .
                               $self->my_security_key);
    if ($expectedhash eq $self->ret_param_checksum) {
        return "OK"
    }
    else {
        $self->_add_valid_error("Expected hash $expectedhash isn't " . $self->ret_param_checksum);
        return 0;
    }
}


=head3 raw_url 

Accessor for the raw, undecoded url (used for the checksum).

=cut


has raw_url => (is => 'rw');



=head3 url_is_valid($raw_undecoded_url)

You may ask for the validation of the url, which comes with a checksum
attached. For this you should have already provided the security key
and you should pass the raw undecoded url as argument.

Alternatively, if you set the attribute C<raw_url> in the constructor
or with the accessor, you can call url_is_valid without arguments.

Return false on failure, true on success

Original German doc (left in place because the translation was drunk).

CGI-Name: ret_url_checksum 
Webservice-Name: - (nicht benötigt) 
Datentyp: String 

Wenn Sie für eine Transaktion eine Anwendung mit einem Security-Key
verwendet haben, wird dieser Parameter mit einem MD5-Hash an die
Rücksprungs-URL angehängt.

Für die Bildung des Hash wird an die Rücksprungs-URL ein & und der
Transaktions-Security- Key der Anwendung angehängt. Für diese
Zeichenkette wird die MD5-Prüfsumme generiert. Der ermittelte Hash
wird als Parameter ret_url_checksum an die Rücksprungs-URL hinter alle
anderen Parameter an das Ende angehängt.

Um die Prüfsumme zu überprüfen müssen Sie den Parameter
ret_url_checksum von der vollständigen URL des aufgerufenen Scriptes
abschneiden, den Transaktions-Security-Key anhängen und dann die
MD5-Prüfsumme ermitteln. Wenn die Prüfsumme nicht mit dem Wert des
Parameters ret_url_checksum übereinstimmt, liegt vermutlich eine
Manipulation der URL vor.

=cut

sub url_is_valid {
    my ($self, $url) = @_;
    unless ($url) {
        $url = $self->raw_url;
    }
    # clear the error stack;
    $self->_set_validation_errors("");
    $self->_set_validation_errors("Missing url for url validation")
      unless $url;
    $self->_add_valid_error("Missing secret key for url validation")
      unless $self->my_security_key;
    unless ($url and $self->my_security_key) {
        return 0
    }

    my $checksum;
    # warn $url;
    # unclear if the & should be removed 
    if ($url =~ m/&ret_url_checksum=([A-Za-z0-9]+)$/) {
        $checksum = $1;
        # it looks like the trailing & should be left in place
        $url =~ s/ret_url_checksum=([A-Za-z0-9]+)$//
    } else {
        $self->_add_valid_error("checksum not found\n");
        return 0
    }
    my $ourchecksum = md5_hex($url . $self->my_security_key);
    if ($ourchecksum eq $checksum) {
        return "OK";
    } else {
        $self->_add_valid_error("Url checksums don't match");
        return 0;
    }
}

=head3 address_info

Shortcut that combines the cardholder details, separated by a whitespace

=cut

sub address_info {
    my $self = shift;
    my @details;
    foreach my $method (qw/addr_name addr_street addr_street2
                           addr_zip addr_city
                           addr_state addr_country addr_email
                           addr_telefon
                           addr_telefax/) {
        if (my $det = $self->$method) {
            push @details, $det
        }
    }
    return join(" ", @details);
}



### HERE WE CAN ADD SOME SHORTCUTS FOR THE SHOP, so we can extract the
### interesting parameters

1;




