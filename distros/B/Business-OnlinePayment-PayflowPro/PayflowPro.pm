package Business::OnlinePayment::PayflowPro;

use strict;
use vars qw($VERSION $DEBUG);
use Carp qw(carp croak);
use Digest::MD5;
use Business::OnlinePayment::HTTPS 0.06;

use base qw(Business::OnlinePayment::HTTPS);

$VERSION = '1.01';
$VERSION = eval $VERSION;
$DEBUG   = 0;

# CGI::Util was included starting with Perl 5.6. For previous
# Perls, let them use the old simple CGI method of unescaping
my $no_cgi_util;
BEGIN {
    eval { require CGI::Util; };
    $no_cgi_util = 1 if $@;
}

# return current request_id or generate a new one if not yet set
sub request_id {
    my $self = shift;
    if ( ref($self) ) {
        $self->{"__request_id"} = shift if (@_);    # allow value change/reset
        $self->{"__request_id"} = $self->_new_request_id()
          unless ( $self->{"__request_id"} );
        return $self->{"__request_id"};
    }
    else {
        return $self->_new_request_id();
    }
}

sub _new_request_id {
    my $self = shift;
    my $md5  = Digest::MD5->new();
    $md5->add( $$, time(), rand(time) );
    return $md5->hexdigest();
}

sub debug {
    my $self = shift;

    if (@_) {
        my $level = shift || 0;
        if ( ref($self) ) {
            $self->{"__DEBUG"} = $level;
        }
        else {
            $DEBUG = $level;
        }
        $Business::OnlinePayment::HTTPS::DEBUG = $level;
    }
    return ref($self) ? ( $self->{"__DEBUG"} || $DEBUG ) : $DEBUG;
}

# cvv2_code: support legacy code and but deprecate method
sub cvv2_code { shift->cvv2_response(@_); }

sub set_defaults {
    my $self = shift;
    my %opts = @_;

    # standard B::OP methods/data
    $self->server("payflowpro.paypal.com");
    $self->port("443");
    $self->path("/transaction");

    $self->build_subs(
        qw(
          partner vendor
          client_certification_id client_timeout
          headers test_server
          cert_path
          order_number avs_code cvv2_response
          response_page response_code response_headers
          )
    );

    # module specific data
    if ( $opts{debug} ) {
        $self->debug( $opts{debug} );
        delete $opts{debug};
    }

    # HTTPS Interface Dev Guide: must be set but will be removed in future
    $self->client_certification_id("ClientCertificationIdNotSet");

    # required: 45 secs recommended by HTTPS Interface Dev Guide
    $self->client_timeout(45);

    $self->test_server("pilot-payflowpro.paypal.com");
}

sub _map_fields {
    my ($self) = @_;

    my %content = $self->content();

    #ACTION MAP
    my %actions = (
        'normal authorization' => 'S',    # Sale transaction
        'credit'               => 'C',    # Credit (refund)
        'authorization only'   => 'A',    # Authorization
        'post authorization'   => 'D',    # Delayed Capture
        'void'                 => 'V',    # Void
    );

    $content{'action'} = $actions{ lc( $content{'action'} ) }
      || $content{'action'};

    # TYPE MAP
    my %types = (
        'visa'             => 'C',
        'mastercard'       => 'C',
        'american express' => 'C',
        'discover'         => 'C',
        'cc'               => 'C',

        #'check'            => 'ECHECK',
    );

    $content{'type'} = $types{ lc( $content{'type'} ) } || $content{'type'};

    $self->transaction_type( $content{'type'} );

    # stuff it back into %content
    $self->content(%content);
}

sub _revmap_fields {
    my ( $self, %map ) = @_;
    my %content = $self->content();
    foreach ( keys %map ) {
        $content{$_} =
          ref( $map{$_} )
          ? ${ $map{$_} }
          : $content{ $map{$_} };
    }
    $self->content(%content);
}

sub expdate_mmyy {
    my $self       = shift;
    my $expiration = shift;
    my $expdate_mmyy;
    if ( defined($expiration) and $expiration =~ /^(\d+)\D+\d*(\d{2})$/ ) {
        my ( $month, $year ) = ( $1, $2 );
        $expdate_mmyy = sprintf( "%02d", $month ) . $year;
    }
    return defined($expdate_mmyy) ? $expdate_mmyy : $expiration;
}

sub submit {
    my ($self) = @_;

    $self->_map_fields();

    my %content = $self->content;

    if ( $self->transaction_type() ne 'C' ) {
        croak( "PayflowPro can't (yet?) handle transaction type: "
              . $self->transaction_type() );
    }

    my $expdate_mmyy = $self->expdate_mmyy( $content{"expiration"} );
    my $zip          = $content{'zip'};
    $zip =~ s/[^[:alnum:]]//g;

    $self->server( $self->test_server ) if $self->test_transaction;

    my $vendor  = $self->vendor;
    my $partner = $self->partner;

    $self->_revmap_fields(

        # BUG?: VENDOR B::OP:PayflowPro < 0.05 backward compatibility.  If
        # vendor not set use login although test indicate undef vendor is ok
        VENDOR => $vendor ? \$vendor : 'login',
        PARTNER  => \$partner,
        USER     => 'login',
        PWD      => 'password',
        TRXTYPE  => 'action',
        TENDER   => 'type',
        ORIGID   => 'order_number',
        COMMENT1 => 'description',
        COMMENT2 => 'invoice_number',

        ACCT    => 'card_number',
        CVV2    => 'cvv2',
        EXPDATE => \$expdate_mmyy,    # MM/YY from 'expiration'
        AMT     => 'amount',

        FIRSTNAME   => 'first_name',
        LASTNAME    => 'last_name',
        NAME        => 'name',
        EMAIL       => 'email',
        COMPANYNAME => 'company',
        STREET      => 'address',
        CITY        => 'city',
        STATE       => 'state',
        ZIP         => \$zip,          # 'zip' with non-alnums removed
        COUNTRY     => 'country',

        # As of 8/18/2009: CUSTCODE appears to be cut off at 18
        # characters and isn't currently reportable.  Consider storing
        # local customer ids in the COMMENT1/2 fields as a workaround.
        CUSTCODE        => 'customer_id',
        SHIPTOFIRSTNAME => 'ship_first_name',
        SHIPTOLASTNAME  => 'ship_last_name',
        SHIPTOSTREET    => 'ship_address',
        SHIPTOCITY      => 'ship_city',
        SHIPTOSTATE     => 'ship_state',
        SHIPTOZIP       => 'ship_zip',
        SHIPTOCOUNTRY   => 'ship_country',
    );

    # Reload %content as _revmap_fields makes our copy old/invalid!
    %content = $self->content;

    my @required = qw( TRXTYPE TENDER PARTNER VENDOR USER PWD );

    # NOTE: we croak above if transaction_type ne 'C'
    if ( $self->transaction_type() eq 'C' ) {    # credit card
        if ( defined( $content{'ORIGID'} ) && length( $content{'ORIGID'} ) ) {
            push @required, qw(ORIGID);
        }
        else {
            push @required, qw(AMT ACCT EXPDATE);
        }
    }

    $self->required_fields(@required);

    my %params = $self->get_fields(
        qw(
          VENDOR PARTNER USER PWD TRXTYPE TENDER ORIGID COMMENT1 COMMENT2
          ACCT CVV2 EXPDATE AMT
          FIRSTNAME LASTNAME NAME EMAIL COMPANYNAME
          STREET CITY STATE ZIP COUNTRY
          SHIPTOFIRSTNAME SHIPTOLASTNAME
          SHIPTOSTREET SHIPTOCITY SHIPTOSTATE SHIPTOZIP SHIPTOCOUNTRY
          CUSTCODE
          )
    );

    # get header data
    my %req_headers = %{ $self->headers || {} };

    # get request_id from %content if defined for ease of use
    if ( defined $content{"request_id"} ) {
        $self->request_id( $content{"request_id"} );
    }

    unless ( defined( $req_headers{"X-VPS-Request-ID"} ) ) {
        $req_headers{"X-VPS-Request-ID"} = $self->request_id();
    }

    unless ( defined( $req_headers{"X-VPS-VIT-Client-Certification-Id"} ) ) {
        $req_headers{"X-VPS-VIT-Client-Certification-Id"} =
          $self->client_certification_id;
    }

    unless ( defined( $req_headers{"X-VPS-Client-Timeout"} ) ) {
        $req_headers{"X-VPS-Client-Timeout"} = $self->client_timeout();
    }

    my %options = (
        "Content-Type" => "text/namevalue",
        "headers"      => \%req_headers,
    );

    # Payflow Pro does not use URL encoding for the request.  The
    # following implements their custom encoding scheme.  Per the
    # developer docs, the PARMLIST Syntax Guidelines are:
    # - Spaces are allowed in values
    # - Enclose the PARMLIST in quotation marks ("")
    # - Do not place quotation marks ("") within the body of the PARMLIST
    # - Separate all PARMLIST name-value pairs using an ampersand (&)
    # 
    # Because '&' and '=' have special meanings/uses values containing
    # these special characters must be encoded using a special "length
    # tag".  The "length tag" is simply the length of the "value"
    # enclosed in square brackets ([]) and appended to the "name"
    # portion of the name-value pair.
    #
    # For more details see the sections 'Using Special Characters in
    # Values' and 'PARMLIST Syntax Guidelines' in the PayPal Payflow
    # Pro Developer's Guide
    #
    # NOTE: we pass a string to https_post so it does not do encoding
    my $params_string = join(
        '&',
        map {
            my $key = $_;
            my $value = defined( $params{$key} ) ? $params{$key} : '';
            if ( index( $value, '&' ) != -1 || index( $value, '=' ) != -1 ) {
                $key = $key . "[" . length($value) . "]";
            }
            "$key=$value";
          } keys %params
    );

    my ( $page, $resp, %resp_headers ) =
      $self->https_post( \%options, $params_string );

    $self->response_code($resp);
    $self->response_page($page);
    $self->response_headers( \%resp_headers );

    # $page should contain name=value[[&name=value]...] pairs
    my $response = $self->_get_response( \$page );

    # AVS and CVS values may be set on success or failure
    my $avs_code;
    if ( defined $response->{"AVSADDR"} or defined $response->{"AVSZIP"} ) {
        if ( $response->{"AVSADDR"} eq "Y" && $response->{"AVSZIP"} eq "Y" ) {
            $avs_code = "Y";
        }
        elsif ( $response->{"AVSADDR"} eq "Y" ) {
            $avs_code = "A";
        }
        elsif ( $response->{"AVSZIP"} eq "Y" ) {
            $avs_code = "Z";
        }
        elsif ( $response->{"AVSADDR"} eq "N" or $response->{"AVSZIP"} eq "N" )
        {
            $avs_code = "N";
        }
        else {
            $avs_code = "";
        }
    }

    $self->avs_code($avs_code);
    $self->cvv2_response( $response->{"CVV2MATCH"} );
    $self->result_code( $response->{"RESULT"} );
    $self->order_number( $response->{"PNREF"} );
    $self->error_message( $response->{"RESPMSG"} );
    $self->authorization( $response->{"AUTHCODE"} );

    # RESULT must be an explicit zero, not just numerically equal
    if ( defined( $response->{"RESULT"} ) && $response->{"RESULT"} eq "0" ) {
        $self->is_success(1);
    }
    else {
        $self->is_success(0);
    }
}

# Process the response page for params.  Based on parse_params in CGI
# by Lincoln D. Stein.
sub _get_response {
    my ( $self, $page ) = @_;

    my %response;

    if ( !defined($page) || ( ref($page) && !defined($$page) ) ) {
        return \%response;
    }

    my ( $param, $value );
    foreach ( split( /[&;]/, ref($page) ? $$page : $page ) ) {
        ( $param, $value ) = split( '=', $_, 2 );
        next unless defined $param;
        $value = '' unless defined $value;

        if ($no_cgi_util) {    # use old pre-CGI::Util method of unescaping
            $param =~ tr/+/ /;    # pluses become spaces
            $param =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
            $value =~ tr/+/ /;    # pluses become spaces
            $value =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
        }
        else {
            $param = CGI::Util::unescape($param);
            $value = CGI::Util::unescape($value);
        }
        $response{$param} = $value;
    }
    return \%response;
}

1;

__END__

=head1 NAME

Business::OnlinePayment::PayflowPro - Payflow Pro backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;
  
  my $tx = new Business::OnlinePayment(
      'PayflowPro',
      'vendor'  => 'your_vendor',
      'partner' => 'your_partner',
      'client_certification_id' => 'GuidUpTo32Chars',
  );
  
  # See the module documentation for details of content()
  $tx->content(
      type           => 'VISA',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment::PayflowPro test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jsk',
      name           => 'Jason Kohles',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'GA',
      zip            => '30004',
      email          => 'ivan-payflowpro@420.am',
      card_number    => '4111111111111111',
      expiration     => '12/09',
      cvv2           => '123',
      order_number   => 'string',
      request_id     => 'unique_identifier_for_transaction',
  );
  
  $tx->submit();
  
  if ( $tx->is_success() ) {
      print(
          "Card processed successfully: ", $tx->authorization, "\n",
          "order number: ",                $tx->order_number,  "\n",
          "CVV2 response: ",               $tx->cvv2_response, "\n",
          "AVS code: ",                    $tx->avs_code,      "\n",
      );
  }
  else {
      my $info = "";
      $info = " (CVV2 mismatch)" if ( $tx->result_code == 114 );
      
      print(
          "Card was rejected: ", $tx->error_message, $info, "\n",
          "order number: ",      $tx->order_number,         "\n",
      );
  }

=head1 DESCRIPTION

This module is a back end driver that implements the interface
specified by L<Business::OnlinePayment> to support payment handling
via the PayPal's Payflow Pro Internet payment solution.

See L<Business::OnlinePayment> for details on the interface this
modules supports.

=head1 Standard methods

=over 4

=item set_defaults()

This method sets the 'server' attribute to 'payflowpro.paypal.com'
and the port attribute to '443'.  This method also sets up the
L</Module specific methods> described below.

=item submit()

=back

=head1 Unofficial methods

This module provides the following methods which are not officially
part of the standard Business::OnlinePayment interface (as of 3.00_06)
but are nevertheless supported by multiple gateways modules and
expected to be standardized soon:

=over 4

=item L<order_number()|/order_number()>

=item L<avs_code()|/avs_code()>

=item L<cvv2_response()|/cvv2_response()>

=back

=head1 Module specific methods

This module provides the following methods which are not currently
part of the standard Business::OnlinePayment interface:

=head2 client_certification_id()

This gets/sets the X-VPS-VITCLIENTCERTIFICATION-ID which is REQUIRED
and defaults to "ClientCertificationIdNotSet".  This is described in
Website Payments Pro HTTPS Interface Developer's Guide as follows:

"A random globally unique identifier (GUID) that is currently
required. This requirement will be removed in the future. At this
time, you can send any alpha-numeric ID up to 32 characters in length.

NOTE: Once you have created this ID, do not change it. Use the same ID
for every transaction."

=head2 client_timeout()

Timeout value, in seconds, after which this transaction should be
aborted.  Defaults to 45, the value recommended by the Website
Payments Pro HTTPS Interface Developer's Guide.

=head2 debug()

Enable or disble debugging.  The value specified here will also set
$Business::OnlinePayment::HTTPS::DEBUG in submit() to aid in
troubleshooting problems.

=head2 expdate_mmyy()

The expdate_mmyy() method takes a single scalar argument (typically
the value in $content{expiration}) and attempts to parse and format
and put the date in MMYY format as required by PayflowPro
specification.  If unable to parse the expiration date simply leave it
as is and let the PayflowPro system attempt to handle it as-is.

=head2 request_id()

It is recommended that you specify your own unique request_id for each
transaction in %content.  A request_id is REQUIRED by the PayflowPro
processor.  If a request_id is not set, then Digest::MD5 is used to
attempt to generate a request_id for a transaction.

=head2 Deprecated methods

The following methods are deprecated and may be removed in a future
release.  Values for vendor and partner should now be set as arguments
to Business::OnlinePayment->new().  The value for cert_path was used
to support passing a path to PFProAPI.pm (a Perl module/SDK from
Verisign/Paypal) which is no longer used.

=over 4

=item vendor()

=item partner()

=item cert_path()

=item cvv2_code()

=back

=head1 Settings

The following default settings exist:

=over 4

=item server

payflowpro.paypal.com or pilot-payflowpro.paypal.com if
test_transaction() is TRUE

=item port

443

=back

=head1 Handling of content(%content)

The following rules apply to content(%content) data:

=head2 action

If 'action' matches one of the following keys it is replaced by the
right hand side value:

  'normal authorization' => 'S', # Sale transaction
  'credit'               => 'C', # Credit (refund)
  'authorization only'   => 'A', # Authorization
  'post authorization'   => 'D', # Delayed Capture
  'void'                 => 'V',

If 'action' is 'C', 'D' or 'V' and 'order_number' is not set then
'amount', 'card_number' and 'expiration' must be set.

=head2 type

If 'type' matches one of the following keys it is replaced by the
right hand side value:

  'visa'               => 'C',
  'mastercard'         => 'C',
  'american express'   => 'C',
  'discover'           => 'C',
  'cc'                 => 'C',

The value of 'type' is used to set transaction_type().  Currently this
module only supports a transaction_type() of 'C' any other values will
cause Carp::croak() to be called in submit().

Note: Payflow Pro supports multiple credit card types, including:
American Express/Optima, Diners Club, Discover/Novus, Enroute, JCB,
MasterCard and Visa.

=head1 Setting Payflow Pro parameters from content(%content)

The following rules are applied to map data to Payflow Pro parameters
from content(%content):

      # PFP param => $content{<key>}
      VENDOR      => $self->vendor ? \( $self->vendor ) : 'login',
      PARTNER     => \( $self->partner ),
      USER        => 'login',
      PWD         => 'password',
      TRXTYPE     => 'action',
      TENDER      => 'type',
      ORIGID      => 'order_number',
      COMMENT1    => 'description',
      COMMENT2    => 'invoice_number',

      ACCT        => 'card_number',
      CVV2        => 'cvv2',
      EXPDATE     => \( $month.$year ), # MM/YY from 'expiration'
      AMT         => 'amount',

      FIRSTNAME   => 'first_name',
      LASTNAME    => 'last_name',
      NAME        => 'name',
      EMAIL       => 'email',
      COMPANYNAME => 'company',
      STREET      => 'address',
      CITY        => 'city',
      STATE       => 'state',
      ZIP         => \$zip, # 'zip' with non-alphanumerics removed
      COUNTRY     => 'country',

      # As of 8/18/2009: CUSTCODE appears to be cut off at 18
      # characters and isn't currently reportable.  Consider storing
      # local customer ids in the COMMENT1/2 fields as a workaround.
      CUSTCODE    => 'customer_id',

      SHIPTOFIRSTNAME => 'ship_first_name',
      SHIPTOLASTNAME  => 'ship_last_name',
      SHIPTOSTREET    => 'ship_address',
      SHIPTOCITY      => 'ship_city',
      SHIPTOSTATE     => 'ship_state',
      SHIPTOZIP       => 'ship_zip',
      SHIPTOCOUNTRY   => 'ship_country',

The required Payflow Pro parameters for credit card transactions are:

  TRXTYPE TENDER PARTNER VENDOR USER PWD ORIGID

=head1 Mapping Payflow Pro transaction responses to object methods

The following methods provides access to the transaction response data
resulting from a Payflow Pro request (after submit()) is called:

=head2 order_number()

This order_number() method returns the PNREF field, also known as the
PayPal Reference ID, which is a unique number that identifies the
transaction.

=head2 result_code()

The result_code() method returns the RESULT field, which is the
numeric return code indicating the outcome of the attempted
transaction.

A RESULT of 0 (zero) indicates the transaction was approved and
is_success() will return '1' (one/TRUE).  Any other RESULT value
indicates a decline or error and is_success() will return '0'
(zero/FALSE).

=head2 error_message()

The error_message() method returns the RESPMSG field, which is a
response message returned with the transaction result.

=head2 authorization()

The authorization() method returns the AUTHCODE field, which is the
approval code obtained from the processing network.

=head2 avs_code()

The avs_code() method returns a combination of the AVSADDR and AVSZIP
fields from the transaction result.  The value in avs_code is as
follows:

  Y     - Address and ZIP match
  A     - Address matches but not ZIP
  Z     - ZIP matches but not address
  N     - no match
  undef - AVS values not available

=head2 cvv2_response()

The cvv2_response() method returns the CVV2MATCH field, which is a
response message returned with the transaction result.

=head1 COMPATIBILITY

As of 0.07, this module communicates with the Payflow gateway directly
and no longer requires the Payflow Pro SDK or other download.  Thanks
to Phil Lobbes for this great work and Josh Rosenbaum for additional
enhancements and bug fixes.

=head1 AUTHORS

Ivan Kohler <ivan-payflowpro@420.am>

Phil Lobbes E<lt>phil at perkpartners.comE<gt>

Based on Business::OnlinePayment::AuthorizeNet written by Jason Kohles.

=head1 SEE ALSO

perl(1), L<Business::OnlinePayment>, L<Carp>, and the PayPal
Integration Center Payflow Pro resources at
L<https://www.paypal.com/IntegrationCenter/ic_payflowpro.html>

=cut
