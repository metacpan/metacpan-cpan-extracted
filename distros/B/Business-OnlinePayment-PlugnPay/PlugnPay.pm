package Business::OnlinePayment::PlugnPay;

use strict;
use vars qw($VERSION $DEBUG);
use Carp qw(carp croak);

use base qw(Business::OnlinePayment::HTTPS);

$VERSION = '0.03';
$VERSION = eval $VERSION;
$DEBUG   = 0;

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

sub set_defaults {
    my $self = shift;
    my %opts = @_;

    # standard B::OP methods/data
    $self->server("pay1.plugnpay.com");
    $self->port("443");
    $self->path("/payment/pnpremote.cgi");

    $self->build_subs(qw( 
                          order_number avs_code cvv2_response
                          response_page response_code response_headers
                     ));

    # module specific data
    if ( $opts{debug} ) {
        $self->debug( $opts{debug} );
        delete $opts{debug};
    }

    my %_defaults = ();
    foreach my $key (keys %opts) {
      $key =~ /^default_(\w*)$/ or next;
      $_defaults{$1} = $opts{$key};
      delete $opts{$key};
    }
    $self->{_defaults} = \%_defaults;

}

sub _map_fields {
    my ($self) = @_;

    my %content = $self->content();

    #ACTION MAP
    my %actions = (
        'normal authorization' => 'auth',     # Authorization/Settle transaction
        'credit'               => 'newreturn',# Credit (refund)
        'void'                 => 'void',     # Void
    );

    $content{'mode'} = $actions{ lc( $content{'action'} ) }
      || $content{'action'};

    # TYPE MAP
    my %types = (
        'visa'             => 'CC',
        'mastercard'       => 'CC',
        'american express' => 'CC',
        'discover'         => 'CC',
        'cc'               => 'CC',
        'check'            => 'ECHECK',
    );

    $content{'type'} = $types{ lc( $content{'type'} ) } || $content{'type'};

    # PAYMETHOD MAP
    my %paymethods = (
        'CC'           => 'credit',
        'ECHECK'       => 'onlinecheck',
    );

    $content{'paymethod'} = $paymethods{ $content{'type'} };

    $self->transaction_type( $content{'type'} );

    $content{'transflags'} = 'recurring'
      if lc( $content{'recurring_billing'} ) eq 'yes';

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
        $expdate_mmyy = sprintf( "%02d/", $month ) . $year;
    }
    return defined($expdate_mmyy) ? $expdate_mmyy : $expiration;
}

sub required_fields {
    my($self,@fields) = @_;

    my @missing;
    my %content = $self->content();
    foreach(@fields) {
      next
        if (exists $content{$_} && defined $content{$_} && $content{$_}=~/\S+/);
      push(@missing, $_);
    }

    Carp::croak("missing required field(s): " . join(", ", @missing) . "\n")
      if(@missing);

}

sub submit {
    my ($self) = @_;

    die "Processor does not support a test mode"
      if $self->test_transaction;

    $self->_map_fields();

    my %content = $self->content;

    my %required;
    $required{CC_auth} =  [ qw( mode publisher-name card-amount card-name
                                card-number card-exp paymethod ) ];
    $required{CC_newreturn} = [ @{$required{CC_auth}}, qw( publisher-password ) ];
    $required{CC_void} =  [ qw( mode publisher-name publisher-password orderID
                                card-amount ) ];
    #$required{ECHECK_auth} =  [ qw( mode publisher-name accttype routingnum
    #                                accountnum checknum paymethod ) ];
    my %optional;
    $optional{CC_auth} =  [ qw( publisher-email authtype required dontsndmail
                                easycard client convert cc-mail transflags
                                card-address1 card-address2 card-city card-state
                                card-prov card-zip card-country card-cvv
                                currency phone fax email shipinfo shipname
                                address1 address2 city state province zip
                                country ipaddress accttype orderID tax
                                shipping app-level order-id acct_code magstripe
                                marketdata carissuenum cardstartdate descrcodes
                                retailterms transflags ) ];
    $optional{CC_newreturn} = [ qw( orderID card-address1 card-address2
                                    card-city card-state card-zip card-country
                                    notify-email
                                  ) ];
    $optional{CC_void}      = [ qw( notify-email ) ];

    #$optional{ECHECK_auth}      = $optional{CC_auth};      # ?
    #$optional{ECHECK_newreturn} = $optional{CC_newreturn}; # ?  legal combo?
    #$optional{ECHECK_void}      = $optional{CC_void};      # ?  legal combo?

    my $type_action = $self->transaction_type(). '_'. $content{mode};
    unless ( exists($required{$type_action}) ) {
      $self->error_message("plugnpay can't handle transaction type: ".
        "$content{action} on " . $self->transaction_type() );
      $self->is_success(0);
      return;
    }

    my $expdate_mmyy = $self->expdate_mmyy( $content{"expiration"} );

    $self->_revmap_fields(

        'publisher-name'     => 'login',
        'publisher-password' => 'password',

        'card-amount'        => 'amount',
        'card-name'          => 'name',
        'card-address1'      => 'address',
        'card-city'          => 'city',
        'card-state'         => 'state',
        'card-zip'           => 'zip',
        'card-country'       => 'country',
        'card-number'        => 'card_number',
        'card-exp'           => \$expdate_mmyy,    # MMYY from 'expiration'
        'card-cvv'           => 'cvv2',
        'order-id'           => 'invoice_number',
        'orderID'            => 'order_number',


    );

    my %shipping_params = ( shipname => (($content{ship_first_name} || '') .
                                        ' '. ($content{ship_last_name} || '')),
                            address1 => $content{ship_address},
                            map { $_ => $content{ "ship_$_" } } 
                              qw ( city state zip country )
                          );


    foreach ( keys ( %shipping_params ) ) {
      if ($shipping_params{$_} && $shipping_params{$_} =~ /^\s*$/) {
        delete $shipping_params{$_};
      }
    }
    $shipping_params{shipinfo} = 1 if scalar(keys(%shipping_params));

    my %params = ( $self->get_fields( @{$required{$type_action}},
                                      @{$optional{$type_action}},
                                    ),
                   (%shipping_params)
                 );

    $params{'txn-type'} = 'auth' if $params{mode} eq 'void';

    foreach ( keys ( %{($self->{_defaults})} ) ) {
      $params{$_} = $self->{_defaults}->{$_} unless exists($params{$_});
    }

    
    $self->required_fields(@{$required{$type_action}});
    
    warn join("\n", map{ "$_ => $params{$_}" } keys(%params)) if $DEBUG > 1;
    my ( $page, $resp, %resp_headers ) = 
      $self->https_post( %params );

    $self->response_code( $resp );
    $self->response_page( $page );
    $self->response_headers( \%resp_headers );

    warn "$page\n" if $DEBUG > 1;
    # $page should contain key/value pairs

    my $status ='';
    my %results = map { s/\s*$//;
                        my ($name, $value) = split '=', $_, 2;
                        $name  =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
                        $value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
                        $name, $value;
                      } split '&', $page;

    # AVS and CVS values may be set on success or failure
    $self->avs_code( $results{ 'avs-code' } );
    $self->cvv2_response( $results{ cvvresp } );
    $self->result_code( $results{ 'resp-code' } );
    $self->order_number( $results{ orderID } );
    $self->authorization( $results{ 'auth-code' } );
    $self->error_message( $results{ MErrMsg } );


    if ( $resp =~ /^(HTTP\S+ )?200/
      &&($results{ FinalStatus } eq "success" ||
         $results{ FinalStatus } eq "pending" && $results{ mode } eq 'newreturn'
        )
       ) {
        $self->is_success(1);
    } else {
        $self->is_success(0);
    }
}

1;

__END__

=head1 NAME

Business::OnlinePayment::PlugnPay - plugnpay backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;
  
  my $tx = new Business::OnlinePayment( 'PlugnPay' );
  
  # See the module documentation for details of content()
  $tx->content(
      type           => 'CC',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment::plugnpay test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jef',
      name           => 'Jeff Finucane',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'GA',
      zip            => '30004',
      email          => 'plugnpay@weasellips.com',
      card_number    => '4111111111111111',
      expiration     => '12/09',
      cvv2           => '123',
      order_number   => 'string',
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
      print(
          "Card was rejected: ", $tx->error_message, "\n",
          "order number: ",      $tx->order_number,  "\n",
      );
  }

=head1 DESCRIPTION

This module is a back end driver that implements the interface
specified by L<Business::OnlinePayment> to support payment handling
via plugnpay's payment solution.

See L<Business::OnlinePayment> for details on the interface this
modules supports.

=head1 Standard methods

=over 4

=item set_defaults()

This method sets the 'server' attribute to 'pay1.plugnpay.com' and
the port attribute to '443'.  This method also sets up the
L</Module specific methods> described below.

=item submit()

=back

=head1 Unofficial methods

This module provides the following methods which are not officially part of the
standard Business::OnlinePayment interface (as of 3.00_06) but are nevertheless
supported by multiple gateways modules and expected to be standardized soon:

=over 4

=item L<order_number()|/order_number()>

=item L<avs_code()|/avs_code()>

=item L<cvv2_response()|/cvv2_response()>

=back

=head1 Module specific methods

This module provides the following methods which are not currently
part of the standard Business::OnlinePayment interface:

=over 4

=item L<expdate_mmyy()|/expdate_mmyy()>

=item L<debug()|/debug()>

=back

=head1 Settings

The following default settings exist:

=over 4

=item server

pay1.plugnpay.com

=item port

443

=item path

/payment/pnpremote.cgi

=back

=head1 Parameters passed to constructor

If any of the key/value pairs passed to the constructor have a key
beginning with "default_" then those values are passed to plugnpay as
a the corresponding form field (without the "default_") whenever
content(%content) lacks that key.

=head1 Handling of content(%content)

The following rules apply to content(%content) data:

=head2 type

If 'type' matches one of the following keys it is replaced by the
right hand side value:

  'visa'               => 'CC',
  'mastercard'         => 'CC',
  'american express'   => 'CC',
  'discover'           => 'CC',

The value of 'type' is used to set transaction_type().  Currently this
module only supports the above values.

=head1 Setting plugnpay parameters from content(%content)

The following rules are applied to map data to plugnpay parameters
from content(%content):

    # plugnpay param     => $content{<key>}
      publisher-name     => 'login',
      publisher-password => 'password',

      card-amount        => 'amount',
      card-number        => 'card_number',
      card-exp           => \( $month.$year ), # MM/YY from 'expiration'
      ssl_cvv            => 'cvv2',
      order-id           => 'invoice_number',

      card-name          => 'name',
      card-address1      => 'address',
      card-city          => 'city',
      card-state         => 'state',
      card-zip           => 'zip'
      card-country       => 'country',
      orderID            => 'order_number'     # can be set via order_number()

      shipname           => 'ship_first_name' . ' ' . 'ship_last_name',
      address1           => 'ship_address',
      city               => 'ship_city',
      state              => 'ship_state',
      zip                => 'ship_zip',
      country            => 'ship_country',

      transflags         => 'recurring' if ($content{recurring_billing}) eq 'yes',

=head1 Mapping plugnpay transaction responses to object methods

The following methods provides access to the transaction response data
resulting from a plugnpay request (after submit()) is called:

=head2 order_number()

This order_number() method returns the orderID field for transactions
to uniquely identify the transaction.

=head2 result_code()

The result_code() method returns the resp-code field for transactions.
It is the alphanumeric return code indicating the outcome of the attempted
transaction.

=head2 error_message()

The error_message() method returns the MErrMsg field for transactions.
This provides more details about the transaction result.

=head2 authorization()

The authorization() method returns the auth-code field,
which is the approval code obtained from the card processing network.

=head2 avs_code()

The avs_code() method returns the avs-code field from the transaction result.

=head2 cvv2_response()

The cvv2_response() method returns the cvvresp field, which is a
response message returned with the transaction result.

=head2 expdate_mmyy()

The expdate_mmyy() method takes a single scalar argument (typically
the value in $content{expiration}) and attempts to parse and format
and put the date in MM/YY format as required by the plugnpay
specification.  If unable to parse the expiration date simply leave it
as is and let the plugnpay system attempt to handle it as-is.

=head2 debug()

Enable or disble debugging.  The value specified here will also set
$Business::OnlinePayment::HTTPS::DEBUG in submit() to aid in
troubleshooting problems.

=head1 COMPATIBILITY

This module implements an interface to the plugnpay Remote Client Integration
Specification Rev. 10.03.2007

=head1 AUTHORS

Jeff Finucane <plugnpay@weasellips.com>

Based on Business::OnlinePayment::PayflowPro written by Ivan Kohler
and Phil Lobbes.

=head1 SEE ALSO

perl(1), L<Business::OnlinePayment>, L<Carp>, and the Remote Client Integration
Specification from plugnpay.

=cut
