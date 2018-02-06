package Business::OnlinePayment;

use strict;
use vars qw($VERSION %_info_handler);
use Carp;

require 5.005;

$VERSION = '3.05';
$VERSION = eval $VERSION; # modperlstyle: convert the string into a number

# Remember subclasses we have "wrapped" submit() with _pre_submit()
my %Presubmit_Added = ();

my @methods = qw(
    authorization
    order_number
    error_message
    failure_status
    fraud_detect
    is_success
    partial_auth_amount
    maximum_risk
    path
    port
    require_avs
    result_code
    server
    server_response
    test_transaction
    transaction_type
    fraud_score
    fraud_transaction_id
    response_code
    response_header
    response_page
    avs_code
    cvv2_response
    txn_date
);

__PACKAGE__->build_subs(@methods);

#fallback
sub _info {
  my $class = shift;
  ( my $gw = $class ) =~ s/^Business::OnlinePayment:://;
  {
    'info_compat'    => '0.00',
    'gateway_name'   => $gw,
    'module_notes'   => "Module does not yet provide info.",
  };
}

#allow classes to declare info in a flexible way, but return normalized info
%_info_handler = (
  'supported_types'   => sub {
    my( $class, $v ) = @_;
    my $types = ref($v) ? $v : defined($v) ? [ $v ] : [];
    $types = { map { $_=>1 } @$types } if ref($types) eq 'ARRAY';
    $types;
  },
  'supported_actions' => sub {
    my( $class, $v ) = @_;
    return %$v if ref($v) eq 'HASH';
    $v = [ $v ] unless ref($v);
    my $types = $class->info('supported_types') || {};
    ( map { $_ => $v } keys %$types );
  },
);

sub info {
  my $class = shift; #class or object
  my $info = $class->_info;
  if ( @_ ) {
    my $key = shift;
    exists($_info_handler{$key})
      ? &{ $_info_handler{$key} }( $class, $info->{$key} )
      : $info->{$key};
  } else {
    wantarray ? ( keys %$info ) : [ keys %$info ];
  }
}

sub new {
    my($class,$processor,%data) = @_;

    croak("unspecified processor") unless $processor;

    my $subclass = "${class}::$processor";
    eval "use $subclass";
    croak("unknown processor $processor ($@)") if $@;

    my $self = bless {processor => $processor}, $subclass;

    if($self->can("set_defaults")) {
        $self->set_defaults(%data);
    }

    foreach(keys %data) {
        my $key = lc($_);
        my $value = $data{$_};
        $key =~ s/^\-+//;
        $self->build_subs($key);
        $self->$key($value);
    }

    # "wrap" submit with _pre_submit only once
    unless ( $Presubmit_Added{$subclass} ) {
        my $real_submit = $subclass->can('submit');

	no warnings 'redefine';
	no strict 'refs';

	*{"${subclass}::submit"} = sub {
	    my $self = shift;
	    return unless $self->_pre_submit(@_);
	    return $real_submit->($self, @_);
	}
    }

    return $self;
}

sub _risk_detect {
    my ($self, $risk_transaction) = @_;

    my %parent_content = $self->content();
    $parent_content{action} = 'Fraud Detect';
    $risk_transaction->content( %parent_content );
    $risk_transaction->submit();
    if ($risk_transaction->is_success()) {
         $self->fraud_score( $risk_transaction->fraud_score );
         $self->fraud_transaction_id( $risk_transaction->fraud_transaction_id );
	if ( $risk_transaction->fraud_score <= $self->maximum_fraud_score()) {
	    return 1;
	} else {
	    $self->error_message('Excessive risk from risk management');
	}
    } else {
	$self->error_message('Error in risk detection stage: ' .  $risk_transaction->error_message);
    }
    $self->is_success(0);
    return 0;
}

my @Fraud_Class_Path = qw(Business::OnlinePayment Business::FraudDetect);

sub _pre_submit {
    my ($self) = @_;
    my $fraud_detection = $self->fraud_detect();

    # early return if user does not want optional risk mgt
    return 1 unless $fraud_detection;

    # Search for an appropriate FD module
    foreach my $fraud_class ( @Fraud_Class_Path ) {
	my $subclass = $fraud_class . "::" . $fraud_detection;
	eval "use $subclass ()";
	if ($@) {
	    croak("error loading fraud_detection module ($@)")
              unless ( $@ =~ m/^Can\'t locate/ );
        } else {
            my $risk_tx = bless( { processor => $fraud_detection }, $subclass );
            if ($risk_tx->can('set_defaults')) {
                $risk_tx->set_defaults();
            }
            $risk_tx->_glean_parameters_from_parent($self);
            return $self->_risk_detect($risk_tx);
	}
    }
    croak("Unable to locate fraud_detection module $fraud_detection"
		. " in \@INC under Fraud_Class_Path (\@Fraud_Class_Path"
	        . " contains: @Fraud_Class_Path) (\@INC contains: @INC)");
}

sub content {
    my($self,%params) = @_;

    if(%params) {
        if($params{'type'}) { $self->transaction_type($params{'type'}); }
        %{$self->{'_content'}} = %params;
    }
    return exists $self->{'_content'} ? %{$self->{'_content'}} : ();
}

sub required_fields {
    my($self,@fields) = @_;

    my @missing;
    my %content = $self->content();
    foreach(@fields) {
        push(@missing, $_) unless exists $content{$_};
    }

    croak("missing required field(s): " . join(", ", @missing) . "\n")
	  if(@missing);
}

sub get_fields {
    my($self, @fields) = @_;

    my %content = $self->content();

    #my %new = ();
    #foreach(@fields) { $new{$_} = $content{$_}; }
    #return %new;
    map { $_ => $content{$_} } grep defined $content{$_}, @fields;
}

sub remap_fields {
    my($self,%map) = @_;

    my %content = $self->content();
    foreach( keys %map ) {
        $content{$map{$_}} = $content{$_};
    }
    $self->content(%content);
}

sub submit {
    my($self) = @_;

    croak("Processor subclass did not override submit function");
}

sub dump_contents {
    my($self) = @_;

    my %content = $self->content();
    my $dump = "";
    foreach(sort keys %content) {
        $dump .= "$_ = $content{$_}\n";
    }
    return $dump;
}

# didnt use AUTOLOAD because Net::SSLeay::AUTOLOAD passes right to
# AutoLoader::AUTOLOAD, instead of passing up the chain
sub build_subs {
    my $self = shift;

    foreach(@_) {
        next if($self->can($_));
        eval "sub $_ { my \$self = shift; if(\@_) { \$self->{$_} = shift; } return \$self->{$_}; }";
    }
}

#helper method

sub silly_bool {
  my( $self, $value ) = @_;
  return 1 if $value =~ /^[yt]/i;
  return 0 if $value =~ /^[fn]/i;
  #return 1 if $value == 1;
  #return 0 if $value == 0;
  $value; #die??
}

1;

__END__

=head1 NAME

Business::OnlinePayment - Perl extension for online payment processing

=head1 SYNOPSIS

  use Business::OnlinePayment;
  
  my $transaction = new Business::OnlinePayment($processor, %processor_info);
  $transaction->content(
                        type        => 'Visa',
                        amount      => '49.95',
                        card_number => '1234123412341238',
                        expiration  => '06/15',
                        name        => 'John Q Doe',
                       );

  eval { $transaction->submit(); };

  if ( $@ ) {

    print "$processor error: $@\n";

  } else {
  
    if ( $transaction->is_success() ) {
      print "Card processed successfully: ". $transaction->authorization()."\n";
    } else {
      print "Card was rejected: ". $transaction->error_message(). "\n";
    }

  }

=head1 DESCRIPTION

Business::OnlinePayment is a generic module for processing payments
through online credit card processors, electronic cash systems, etc.

=head1 CONSTRUCTOR

=head2 new($processor, %processor_options)

Create a new Business::OnlinePayment object, $processor is required,
and defines the online processor to use.  If necessary, processor
options can be specified, currently supported options are 'Server',
'Port', and 'Path', which specify how to find the online processor
(https://server:port/path), but individual processor modules should
supply reasonable defaults for this information, override the defaults
only if absolutely necessary (especially path), as the processor
module was probably written with a specific target script in mind.

=head1 TRANSACTION SETUP METHODS

=head2 content(%content)

The information necessary for the transaction, this tends to vary a
little depending on the processor, so we have chosen to use a system
which defines specific fields in the frontend which get mapped to the
correct fields in the backend.  The currently defined fields are:

=head3 PROCESSOR FIELDS

=over 4

=item login

Your login name to use for authentication to the online processor.

=item password

Your password to use for authentication to the online processor.

=back

=head3 REQUIRED TRANSACTION FIELDS

=over 4

=item type

Transaction type, supported types are: CC (credit card), ECHECK
(electronic check) and LEC (phone bill billing).  Deprecated types
are: Visa, MasterCard, American Express, Discover, Check.  Not all
processors support all transaction types.

=item action

What action being taken by this transaction. Currently available are:

=over 8

=item Normal Authorization

=item Authorization Only

=item Post Authorization

=item Reverse Authorization

=item Void

=item Credit

=item Tokenize

=item Recurring Authorization

=item Modify Recurring Authorization

=item Cancel Recurring Authorization

=back

=item amount

The amount of the transaction.  No dollar signs or currency identifiers,
just a whole or floating point number (i.e. 26, 26.1 or 26.13).

=back

=head3 OPTIONAL TRANSACTION FIELDS

=over 4

=item partial_auth

If you are prepared to handle partial authorizations
(see L<partial_auth_amount()|/"partial_auth_amount()">
 in L<TRANSACTION RESULT FIELDS|/"TRANSACTION RESULT FIELDS">),
pass a true value in this field to enable them.

If this flag is not set, a partial authorization will be immediately reversed
or voided.

=item description

A description of the transaction (used by some processors to send
information to the client, normally not a required field).

=item invoice_number

An invoice number, for your use and not normally required, many
processors require this field to be a numeric only field.

=item po_number

Purchase order number (normally not required).

=item tax

Tax amount (portion of amount field, not added to it).

=item freight

Freight amount (portion of amount field, not added to it).

=item duty

Duty amount (portion of amount field, not added to it).

=item tax_exempt

Tax exempt flag (i.e. TRUE, FALSE, T, F, YES, NO, Y, N, 1, 0).

=item currency

Currency, specified as an ISO 4217 three-letter code, such as USD, CAD, EUR,
AUD, DKK, GBP, JPY, NZD, etc.

=back

=head3 CUSTOMER INFO FIELDS

=over 4

=item customer_id

A customer identifier, again not normally required.

=item name

The customer's name, your processor may not require this.

=item first_name

=item last_name

The customer's first and last name as separate fields.

=item company

The customer's company name, not normally required.

=item address

The customer's address (your processor may not require this unless you
are requiring AVS Verification).

=item city

The customer's city (your processor may not require this unless you
are requiring AVS Verification).

=item state

The customer's state (your processor may not require this unless you
are requiring AVS Verification).

=item zip

The customer's zip code (your processor may not require this unless
you are requiring AVS Verification).

=item country

Customer's country.

=item ship_first_name

=item ship_last_name

=item ship_company

=item ship_address

=item ship_city

=item ship_state

=item ship_zip

=item ship_country

These shipping address fields may be accepted by your processor.
Refer to the description for the corresponding non-ship field for
general information on each field.

=item phone

Customer's phone number.

=item fax

Customer's fax number.

=item email

Customer's email address.

=item customer_ip

IP Address from which the transaction originated.

=back

=head3 CREDIT CARD FIELDS

=over 4

=item card_number

Credit card number.

=item expiration

Credit card expiration, MM/YY.

=item cvv2

CVV2 number (also called CVC2 or CID) is a three- or four-digit
security code used to reduce credit card fraud.

=item card_token

If supported by your gateway, you can pass a card_token instead of a
card_number and expiration.

=cut

#=item card_response
#
#Some card_token schemes implement a challenge/response handshake.  In those
#cases, this field is used for the response.  In most cases the handshake
#it taken care of by the gateway module.

=item track1

Track 1 on the magnetic stripe (Card present only)

=item track2

Track 2 on the magnetic stripe (Card present only)

=item recurring_billing

Recurring billing flag

=back

=head3 ELECTRONIC CHECK FIELDS

=over 4

=item account_number

Bank account number

=item routing_code

Bank's routing code

=item account_type

Account type.  Can be (case-insensitive): B<Personal Checking>,
B<Personal Savings>, B<Business Checking> or B<Business Savings>.

=item nacha_sec_code

NACHA SEC Code for US ACH transactions.  'PPD' indicates customer signed a form
giving authorization for the charge, 'CCD' same for a business checking/savings
account, 'WEB' for online transactions where a box was checked authorizing the
charge, and 'TEL' for authorization via recorded phone call (NACHA script
required).

=item account_name

Account holder's name.

=item bank_name

Bank name.

=item bank_city

Bank city.

=item bank_state

Bank state.

=item check_type

Check type.

=item customer_org

Customer organization type.

=item customer_ssn

Customer's social security number.

=item license_num

Customer's driver's license number.

=item license_dob

Customer's date of birth.

=back

=head3 FOLLOW-UP TRANSACTION FIELDS

These fields are used in follow-up transactions related to an original
transaction (Post Authorization, Reverse Authorization, Void, Credit).

=over 4

=item authorization

=item order_number

=item txn_date

=back

=head3 RECURRING BILLING FIELDS

=over 4

=item interval 

Interval expresses the amount of time between billings: digits, whitespace
and units (currently "days" or "months" in either singular or plural form).

=item start

The date of the first transaction (used for processors which allow delayed
start) expressed as YYYY-MM-DD.

=item periods

The number of cycles of interval length for which billing should occur 
(inclusive of 'trial periods' if the processor supports recurring billing
at more than one rate)

=back

=head2 test_transaction()

Most processors provide a test mode, where submitted transactions will
not actually be charged or added to your batch, calling this function
with a true argument will turn that mode on if the processor supports
it, or generate a fatal error if the processor does not support a test
mode (which is probably better than accidentally making real charges).

=head2 require_avs()

Providing a true argument to this module will turn on address
verification (if the processor supports it).

=head1 TRANSACTION SUBMISSION METHOD

=head2 submit()

Submit the transaction to the processor for completion.

If there is a gateway communication error or other "meta" , the submit method
will throw a fatal exception.  You can catch this with eval {} if you would
like to treat gateway co

=head1 TRANSACTION RESULT METHODS

=head2 is_success()

Returns true if the transaction was approved by the gateway, false if 
it was submitted but not approved, or undef if it has not been 
submitted yet.

=head2 partial_auth_amount()

If this transaction was a partial authorization (i.e. successful, but less than
the requested amount was processed), then the amount processed is returned in
this field.

(When is_success is true but this field is empty or 0, that indicates a normal
full authorization for the entire requested amount.)

=head2 error_message()

If the transaction has been submitted but was not accepted, this
function will return the provided error message (if any) that the
processor returned.

=head2 failure_status()

If the transaction failed, it can optionally return a specific failure
status (normalized, not gateway-specific).  Currently defined statuses
are: "expired", "nsf" (non-sufficient funds), "stolen", "pickup",
"blacklisted" and "declined" (card/transaction declines only, not
other errors).

Note that not all processor modules support this, and that if supported,
it may not be set for all declines.

=head2 authorization()

If the transaction has been submitted and accepted, this function will
provide you with the authorization code that the processor returned.
Store this if you would like to run inquiries or refunds on the transaction
later.

=head2 order_number()

The unique order number for the transaction generated by the gateway.  Store
this if you would like to run inquiries or refunds on the transaction later.

=head2 card_token()

If supported by your gateway, a card_token can be used in a subsequent
transaction to refer to a card number.

=head2 txn_date()

Transaction date, as returned by the gateway.  Required by some gateways
for follow-up transactions.  Store this if you would like to run inquiries or
refunds on the transaction later.

=head2 fraud_score()

Retrieve or change the fraud score from any Business::FraudDetect plugin

=head2 fraud_transaction_id()

Retrieve or change the transaction id from any Business::FraudDetect plugin

=head2 response_code()

=head2 response_headers()

=head2 response_page()

These three fields are set by some processors (especially those which use
HTTPS) when the transaction fails at the communication level rather than
as a transaction.

response_code is the HTTP response code and message, i.e.
'500 Internal Server Error'.

response_headers is a hash reference of the response headers

response_page is the raw content.

=head2 result_code()

Returns the precise result code that the processor returned, these are
normally one letter codes that don't mean much unless you understand
the protocol they speak, you probably don't need this, but it's there
just in case.

=head2 avs_code()

=head2 cvv2_response()

=head1 MISCELLANEOUS INTERNAL METHODS

=head2 transaction_type()

Retrieve the transaction type (the 'type' argument to contents()).
Generally only used internally, but provided in case it is useful.

=head2 server()

Retrieve or change the processor submission server address (CHANGE AT
YOUR OWN RISK).

=head2 port()

Retrieve or change the processor submission port (CHANGE AT YOUR OWN
RISK).

=head2 path()

Retrieve or change the processor submission path (CHANGE AT YOUR OWN
RISK).

=head1 HELPER METHODS FOR GATEWAY MODULE AUTHORS

=head2 build_subs( @sub_names )

Build setter/getter subroutines for new return values.

=head2 get_fields( @fields )

Get the named fields if they are defined.

=head2 remap_fields( %map )

Remap field content (and stuff it back into content).

=head2 required_fields( @fields )

Croaks if any of the required fields are not present.

=head2 dump_contents

=head2 silly_bool( $value )

Returns 1 if the value starts with y, Y, t or T.
Returns 0 if the value starts with n, N, f or F.
Otherwise returns the value itself.

Use this for handling boolean content like tax_exempt.

=head1 AUTHORS

(v2 series)

Jason Kohles, email@jasonkohles.com

(v3 rewrite)

Ivan Kohler <ivan-business-onlinepayment@420.am>

Phil Lobbes E<lt>phil at perkpartners dot comE<gt>

=head1 COPYRIGHT

Copyright (c) 1999-2004 Jason Kohles
Copyright (c) 2004 Ivan Kohler
Copyright (c) 2007-2018 Freeside Internet Services, Inc.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 HOMEPAGE

Homepage:  http://perl.business/onlinepayment

Development:  http://perl.business/onlinepayment/ng.html

=head1 MAILING LIST

Please direct current development questions, patches, etc. to the mailing list:
http://mail.freeside.biz/cgi-bin/mailman/listinfo/bop-devel/

=head1 REPOSITORY

The code is available from our public git repository:

  git clone git://git.freeside.biz/Business-OnlinePayment.git

Or on the web:

  http://git.freeside.biz/gitweb/?p=Business-OnlinePayment.git
  Or:
  http://git.freeside.biz/cgit/Business-OnlinePayment.git

Many (but by no means all!) processor plugins are also available in the same
repository, see:

  http://git.freeside.biz/gitweb/
  Or:
  http://git.freeside.biz/cgit/

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

http://perl.business/onlinepayment

For verification of credit card checksums, see L<Business::CreditCard>.

=cut
