#
# $Id: PayPal.pm,v 1.5 2007/02/16 04:48:34 plobbes Exp $

package Business::OnlinePayment::PayPal;

use 5.006;
use strict;
use warnings;
use base qw(Business::OnlinePayment);
use Business::PayPal::API qw(DirectPayments);

our $VERSION = '0.11';
$VERSION = eval $VERSION;

=head1 NAME

Business::OnlinePayment::PayPal - PayPal backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;
  
  my $tx = Business::OnlinePayment->new(
      "PayPal",
      "Username"  => "my_api1.domain.tld",
      "Password"  => "Xdkis9k3jDFk39fj29sD9",    ## supplied by PayPal
      "Signature" => "f7d03YCpEjIF3s9Dk23F2...", ## supplied by PayPal
  );
  
  $tx->content(
      action      => "Normal Authorization",
      amount      => "19.95",
      type        => "Visa",
      card_number => "4111111111111111",
      expiration  => "01/10",
      cvv2        => "123",
      name        => "John Doe",
      address     => "123 My Street",
      city        => "Chicago",
      state       => "IL",
      zip         => "61443",
      IPAddress   => "10.0.0.1",
  );
  
  $tx->test_transaction(1);
  $tx->submit;
  
  if ( $tx->is_success ) {
      print(
          "SUCCESS:\n",
          "  CorrelationID: ", $tx->correlationid, "\n",
          "  auth:          ", $tx->authorization, "\n",
          "  AVS code:      ", $tx->avs_code, "\n",
          "  CVV2 code:     ", $tx->cvv2_code, "\n",
      );
  }
  else {
      print(
          "ERROR: ", $tx->error_message, "\n"
      );
  }

=head1 DESCRIPTION

Business::OnlinePayment::PayPal is a plugin for using PayPal as a
payment processor backend with the Business::OnlinePayment API.
Specifically, this module uses PayPal's 'DoDirectPayment' operation
which utilizes the 'DoDirectPaymentRequest' message type.

This module does not do any checks to be sure that all the required
fields/arguments/attributes/values, per PayPal's WSDL/XSD, have been
provided.  In general, PayPal's service will catch errors and return
relevant information.  However when requests do not meet the minimum
message format/structure requirements or if the request contains
information not supported by the 'DoDirectPaymentRequest' very generic
errors (i.e. PPBaseException) may be sent to STDERR by underlying
modules and our response data structure may be completely empty.

Anyone using this module or any modules that talk to PayPal should
familiarize themselves with the information available at PayPal's
integration center.  See the L</SEE ALSO> section for links to useful
reference material.

=head1 METHODS

The following methods exist for use with this module.

=head2 Convenience methods

=over 4

=item authorization()

Provides access to the TransactionID returned in the PayPal results.
This method is part of the Business::OnlinePayment "standard" API.

=item transactionid()

This method is an alias for the L</authorization()> method.

=item correlationid()

Provides access to the CorrelationID returned in the PayPal results.

=item order_number()

This method is an alias for the L</correlationid()> method.  It is
provided for compatibility with the PayflowPro backend.

=item server_response()

Provides access, via a hashref, to the results hash returned in the
Business::PayPal::API results object returned by
DoDirectPaymentRequest.  This method is part of the
Business::OnlinePayment "standard" API.

=item result_code()

Returns "" or the first ErrorCode returned from
DoDirectPaymentRequest.  This method is part of the
Business::OnlinePayment "standard" API.

=item avs_code()

Returns the AVSCode returned from DoDirectPaymentRequest.

=item cvv2_code()

Returns the CVV2Code returned from DoDirectPaymentRequest.

=item is_success()

Returns 1 or 0 on success or failure of DoDirectPaymentRequest.  This
method is part of the Business::OnlinePayment "standard" API.

=item error_message()

Returns a string containing an error message, if any.  This method is
part of the Business::OnlinePayment "standard" API.

=back

=head2 set_defaults()

Creates accessor methods L</avs_code()>, L</correlationid()>,
L</cvv2_code()> and __map_fields_data (see L</get_request_data>).

=cut

sub set_defaults {
    my $self = shift;

    $self->build_subs(qw(avs_code correlationid cvv2_code __map_fields_data));

    $self->__map_fields_data(
        {
            PaymentAction => "action",
            OrderTotal    => "amount",    # Payment Detail

            # Credit Card
            CreditCardType   => "type",
            CreditCardNumber => "card_number",
            CVV2             => undef,

            # Card Owner / Payer Name
            Payer     => "email",
            FirstName => "name",
            LastName  => undef,

            # Payer Address
            Street1         => "address",
            Street2         => undef,
            CityName        => "city",
            StateOrProvince => "state",
            Country         => "country",
            PostalCode      => "zip",
        }
    );
}

sub transactionid { shift()->authorization(@_); }

sub order_number { shift()->correlationid(@_); }

=head2 get_credentials()

Get the credential information for Business::PayPal::API that was
provided to Business::OnlinePayment::new().  The supported arguments
are:

=over 4

=item * Username Password PKCS12File PKCS12Password

=item * Username Password CertFile KeyFile

=item * Username Password Signature

=back

Business::OnlinePayment::PayPal does not currently map arguments to
new() from (standard?) names to the PayPal backend specific name.  For
example, if the argument "login" were passed to new() the module could
potentially try to identify that and map that to "Username".

NOTE: This requirement/capability seems to be more of a
Business::OnlinePayment issue than a backend issue and it isn't clear
if behavior like this is needed in this module so I will wait for user
feedback to determine if we need/want to implement this.

=cut

sub get_credentials {
    my $self = shift;

    my %credentials;
    my @cred_vars = (
        [qw(PKCS12File PKCS12Password)],
        [qw(CertFile KeyFile)], [qw(Signature)],
    );

    foreach my $aref (@cred_vars) {
        my $need = 0;
        my @vars = ( qw(Username Password), @$aref );

        foreach my $var (@vars) {

            # HACK: Business::OnlinePayment makes method lower case
            my $method = lc($var);
            if ( $self->can($method) ) {
                $credentials{$var} = $self->$method;
            }
            else {
                $need++;
            }
        }

        if ($need) {
            undef %credentials;
        }
        else {
            last;
        }
    }
    return %credentials;
}

=head2 get_request_data()

Return a hash %data with all the data from content() that we will try
to use in our request to PayPal.  Tasks performed:

=over 4

=item *

Remove unsupported values from our hash (i.e. description fax login
password phone).

=item *

Translate the value in "action" if necessary, from
Business::OnlinePayment names to names used by PayPal.  Translations
used are:

    "normal authorization" => "Sale"
    "authorization only"   => "Authorization"
    "void"                 => "None"

=item *

Translate the value in "type" if necessary, from
Business::OnlinePayment names to names used by PayPal.  See
L</normalize_creditcardtype()> for details.

=item *

If necessary, separate ExpMonth and ExpYear values from the single
"standard" Business::OnlinePayment "expiration" field.  See
L</parse_expiration()> for details.

=item *

Call get_remap_fields to map content() into the %data that we will
pass to PayPal.  All fields not "mapped" will be passed AS-IS.  The
mapping used is (map hashref stored in __map_fields_data()):

  PaymentAction    => "action"
  # Payment Detail
  OrderTotal       => "amount"
  # Credit Card
  CreditCardType   => "type"
  CreditCardNumber => "card_number"
  CVV2             => undef
  # Card Owner / Payer Name
  Payer            => "email"
  FirstName        => "name"
  LastName         => undef
  # Payer Address
  Street1          => "address"
  Street2          => undef
  CityName         => "city"
  StateOrProvince  => "state"
  Country          => "country"
  PostalCode       => "zip"

NOTE: an 'undef' on the right hand side means that field will be
looked for as the mixed-case name specified on the left and also as an
all lower-case name).

=back

=cut

sub get_request_data {
    my $self    = shift;
    my %content = $self->content;

    return () unless (%content);

    # remove some unsupported content
    # others? description, invoice_number, customer_id
    delete @content{qw(description fax login password phone)};

    # action: map "standard" names to supported as needed
    if ( $content{action} ) {
        my $act     = lc( $content{action} );
        my %actions = (
            "normal authorization" => "Sale",
            "authorization only"   => "Authorization",
            "void"                 => "None",
        );
        $content{action} = $actions{$act} || $content{action};
    }

    # type: translate to supported CreditCardType values
    if ( $content{type} ) {
        my $type = $content{type};
        $content{type} = $self->normalize_creditcardtype($type) || $type;
    }

    # expiration: need separate month and year values
    if ( $content{expiration}
        and ( !$content{ExpMonth} or !$content{ExpYear} ) )
    {
        my $exp = $content{expiration};
        delete $content{expiration};

        # we only set ExpMonth/ExpYear if they aren't already set
        my ( $y, $m ) = $self->parse_expiration($exp);
        if ( $m and !$content{ExpMonth} ) {
            $content{ExpMonth} = $m;
        }
        if ( $y and !$content{ExpYear} ) {
            $content{ExpYear} = $y;
        }
    }

    my %data = $self->get_remap_fields(
        content => \%content,
        map     => $self->__map_fields_data,
    );
    return %data;
}

=head2 submit()

Method that overrides the superclass stub.  This method performs the
following tasks:

=over 4

=item *

Get credentials to be used for authentication with PayPal by calling
L</get_credentials()>.

=item *

Get request data to be passed to PayPal by calling
L</get_request_data()>.

=item *

Connect to PayPal and perform a DirectPaymentRequest.  The request
will be run in test mode (i.e. go to PayPal's "sandbox") if
test_transaction() returns true.  NOTE: I believe PayPal automatically
does AVS checking if possible.

=item *

Store the entire response in server_response().

=item *

Set result_code() to "" or the first ErrorCode in Errors (if present).

=item *

Set avs_code() to the response AVSCode.

=item *

Set cvv2_code() to the response CVV2Code.

=item *

Set is_success() to 1 or 0, indicating if the transaction was
successful or not.

=item *

On success, set authorization() with the value of TransactionID.  On
failure, set error_message() with a string containing all ErrorCode
and LongMessage values joined together.

=back

=cut

sub submit {
    my $self = shift;

    my %credentials = $self->get_credentials;
    my %request     = $self->get_request_data;

    my $pp =
      Business::PayPal::API->new( %credentials,
        sandbox => $self->test_transaction, );

    my %resp = $pp->DoDirectPaymentRequest(%request);

    $self->server_response( \%resp );
    $self->result_code( $resp{Errors} ? $resp{Errors}->[0]->{ErrorCode} : "" );
    $self->avs_code( $resp{AVSCode} );
    $self->cvv2_code( $resp{CVV2Code} );

    if ( $resp{Ack} and $resp{Ack} eq "Success" ) {
        $self->is_success(1);
        $self->authorization( $resp{TransactionID} );
        $self->correlationid( $resp{CorrelationID} );
    }
    else {
        $self->is_success(0);
    }

    if ( $resp{Errors} and @{ $resp{Errors} } ) {
        my $error = join( "; ",
            map { $_->{ErrorCode} . ": " . $_->{LongMessage} }
              @{ $resp{Errors} } );
        $self->error_message($error);
    }

    return $self->is_success;
}

=head2 get_remap_fields()

  Options:
    content => $href (default: { $self->content } )
    map     => $href (default: { } )

Combines some of the functionality of get_fields and remap_fields for
convenience and also extends/alters their behavior.  Unlike
Business::OnlinePayment::remap_fields, this doesn't modify content(),
and can therefore be called more than once.  Also, unlike
Business::OnlinePayment::get_fields in 3.x, this doesn't exclude
fields content with a value of undef.

=cut

sub get_remap_fields {
    my ( $self, %opt ) = @_;

    my $content = $opt{content} || { $self->content };
    my $map     = $opt{map}     || {};
    my %data;

    while ( my ( $to, $from ) = each %$map ) {
        my $tolc = lc($to);
        my $v;
        if ( defined $from ) {
            $v = $content->{$from};
            delete $content->{$from};
        }
        $v ||= $content->{$to} || $content->{$tolc};
        delete @$content{ $to, $tolc };

        if ( defined $v ) {
            $data{$to} = $v;
        }
    }

    %data = ( %$content, %data );

    return %data;
}

=head2 normalize_creditcardtype()

Attempt to normalize the credit card type to names supported by
PayPal.  If the module is unable to identify the given type it leaves
the value AS-IS and leaves it to PayPal to do what it can with the
data given.  Supported card types are:

  Visa | MasterCard | Discover | Amex

Translations used are:

  /^vis/i     => "Visa"
  /^mas/i     => "MasterCard"
  /^ame/i     => "Amex"
  /^dis/i     => "Discover"

=cut

sub normalize_creditcardtype {
    my ( $self, $cctype ) = @_;

    if    ( $cctype =~ /^vis/i ) { $cctype = "Visa"; }
    elsif ( $cctype =~ /^mas/i ) { $cctype = "MasterCard"; }
    elsif ( $cctype =~ /^ame/i ) { $cctype = "Amex"; }
    elsif ( $cctype =~ /^dis/i ) { $cctype = "Discover"; }
    else {

        # Credit Card type '$cctype' not known
    }
    return ($cctype);
}

=head2 parse_expiration()

Business::OnlinePayment documents the use of a single expiration or
exp_date value.  However PayPal requires separate values for both the
month and year.  There are multiple formates that expiration dates are
often specified in so, we try to our best to handle them all.

The following formats are supported:

  YYYY[.-]MM, YYYY[.-]M, YY[-/]M, YY[.-]MM
  MM[-/]YYYY, M[-/]YYYY, M[-/]YY, MM/YY, MMYY

NOTE: this method is based on the parse_exp method found in
L<Business::OnlinePayment::InternetSecure|Business::OnlinePayment::InternetSecure>.

If an unrecognized format is encountered this method it will return an
empty list and leave it to PayPal to do what it can with the data
given.  To avoid having this module attempt to parse 'expiration'
explicitly set ExpMonth and ExpYear in content().

=cut

sub parse_expiration {
    my ( $self, $exp ) = @_;
    my ( $y, $m );

    return () unless ($exp);

    if (
        $exp =~ /^(\d{4})[.-](\d{1,2})$/ ||    # YYYY[.-]MM or YYYY[.-]M
        $exp =~ /^(\d\d)[-\/](\d)$/ ||         # YY[-/]M
        $exp =~ /^(\d\d)[.-](\d\d)$/
      )                                        # YY[.-]MM
    {
        ( $y, $m ) = ( $1, $2 );
    }
    elsif (
        $exp =~ /^(\d{1,2})[-\/](\d{4})$/ ||    # MM[-/]YYYY or M[-/]YYYY
        $exp =~ /^(\d)[-\/](\d\d)$/ ||          # M[-/]YY
        $exp =~ /^(\d\d)\/?(\d\d)$/
      )                                         # MM/YY or MMYY
    {
        ( $y, $m ) = ( $2, $1 );
    }
    else {
        return ();    # unable to parse expiration date '$exp'
    }

    # HACK: add the current century - 1
    if ( $y < 100 ) {
        $y += int( ( ( localtime(time) )[5] + 1900 ) / 100 ) * 100;
    }

    return ( $y, sprintf( "%02.0f", $m ) );
}

1;

__END__

=head1 SEE ALSO

L<http://sourceforge.net/projects/bop-paypal/>: source code for this
module is maintained on Sourceforge.

L<Business::OnlinePayment|Business::OnlinePayment>: the framework/API
used by this module.

L<Business::PayPal::API|Business::PayPal::API>: details and code that
this module relies on to actually do the work of talking to PayPal
servers.

L<Business::OnlinePayment::InternetSecure|Business::OnlinePayment::InternetSecure>: the module that helped to guide me in development of this module.

L<https://www.paypal.com/integration>: PayPal's integration center
home and the source of all information relating to how to integrate to
services provided by PayPal.

=head1 AUTHOR

Phil Lobbes E<lt>phil at perkpartners dot comE<gt>

=head1 COPYRIGHT

Copyright (C) 2006 by Phil Lobbes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
