package Business::OnlinePayment::viaKLIX;

use strict;
use vars qw($VERSION $DEBUG);
use Carp qw(carp croak);

use base qw(Business::OnlinePayment::HTTPS);

$VERSION = '0.02';
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
    $self->server("www.viaKLIX.com");
    $self->port("443");
    $self->path("/process.asp");

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
        'normal authorization' => 'SALE',  # Authorization/Settle transaction
        'credit'               => 'CREDIT', # Credit (refund)
    );

    $content{'ssl_transaction_type'} = $actions{ lc( $content{'action'} ) }
      || $content{'action'};

    # TYPE MAP
    my %types = (
        'visa'             => 'CC',
        'mastercard'       => 'CC',
        'american express' => 'CC',
        'discover'         => 'CC',
        'cc'               => 'CC',
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

    $self->_map_fields();

    my %content = $self->content;

    my %required;
    $required{CC_SALE} =  [ qw( ssl_transaction_type ssl_merchant_id ssl_pin
                                ssl_amount ssl_card_number ssl_exp_date
                              ) ];
    $required{CC_CREDIT} = $required{CC_SALE};
    my %optional;
    $optional{CC_SALE} =  [ qw( ssl_user_id ssl_salestax ssl_cvv2 ssl_cvv2cvc2
                                ssl_description ssl_invoice_number
                                ssl_customer_code ssl_company ssl_first_name
                                ssl_last_name ssl_avs_address ssl_address2
                                ssl_city ssl_state ssl_avs_zip ssl_country
                                ssl_phone ssl_email ssl_ship_to_company
                                ssl_ship_to_first_name ssl_ship_to_last_name
                                ssl_ship_to_address ssl_ship_to_city
                                ssl_ship_to_state ssl_ship_to_zip
                                ssl_ship_to_country
                              ) ];
    $optional{CC_CREDIT} = $optional{CC_SALE};

    my $type_action = $self->transaction_type(). '_'. $content{ssl_transaction_type};
    unless ( exists($required{$type_action}) ) {
      $self->error_message("viaKLIX can't handle transaction type: ".
        "$content{action} on " . $self->transaction_type() );
      $self->is_success(0);
      return;
    }

    my $expdate_mmyy = $self->expdate_mmyy( $content{"expiration"} );
    my $zip          = $content{'zip'};
    $zip =~ s/[^[:alnum:]]//g;

    my $cvv2indicator = 'present' if ( $content{"cvv2"} ); # visa only

    $self->_revmap_fields(

        ssl_merchant_id     => 'login',
        ssl_pin             => 'password',

        ssl_amount          => 'amount',
        ssl_card_number     => 'card_number',
        ssl_exp_date        => \$expdate_mmyy,    # MMYY from 'expiration'
        ssl_cvv2            => \$cvv2indicator,
        ssl_cvv2cvc2        => 'cvv2',
        ssl_description     => 'description',
        ssl_invoice_number  => 'invoice_number',
        ssl_customer_code   => 'customer_id',

        ssl_first_name      => 'first_name',
        ssl_last_name       => 'last_name',
        ssl_avs_address     => 'address',
        ssl_city            => 'city',
        ssl_state           => 'state',
        ssl_avs_zip         => \$zip,          # 'zip' with non-alnums removed
        ssl_country         => 'country',
        ssl_phone           => 'phone',
        ssl_email           => 'email',

    );

    my %params = $self->get_fields( @{$required{$type_action}},
                                    @{$optional{$type_action}},
                                  );

    foreach ( keys ( %{($self->{_defaults})} ) ) {
      $params{$_} = $self->{_defaults}->{$_} unless exists($params{$_});
    }

    $params{ssl_test_mode}='true' if $self->test_transaction;
    
    $params{ssl_show_form}='false';
    $params{ssl_result_format}='ASCII';

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
    my %results = map { s/\s*$//; split '=', $_, 2 } split '^', $page;

    # AVS and CVS values may be set on success or failure
    $self->avs_code( $results{ssl_avs_response} );
    $self->cvv2_response( $results{ ssl_cvv2_response } );
    $self->result_code( $status = $results{ ssl_result } );
    $self->order_number( $results{ ssl_txn_id } );
    $self->authorization( $results{ ssl_approval_code } );
    $self->error_message( $results{ ssl_result_message } );


    if ( $resp =~ /^(HTTP\S+ )?200/ && $status eq "0" ) {
        $self->is_success(1);
    } else {
        $self->is_success(0);
    }
}

1;

__END__

=head1 NAME

Business::OnlinePayment::viaKLIX - viaKLIX backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;
  
  my $tx = new Business::OnlinePayment(
      'viaKLIX', 'default_ssl_user_id' => 'webuser',
  );
  
  # See the module documentation for details of content()
  $tx->content(
      type           => 'CC',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment::viaKLIX test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jef',
      name           => 'Jeff Finucane',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'GA',
      zip            => '30004',
      email          => 'viaklix@weasellips.com',
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
via viaKLIX's Internet payment solution.

See L<Business::OnlinePayment> for details on the interface this
modules supports.

=head1 Standard methods

=over 4

=item set_defaults()

This method sets the 'server' attribute to 'www.viaklix.com' and
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

www.viaklix.com

=item port

443

=item path

/process.asp

=back

=head1 Parameters passed to constructor

If any of the key/value pairs passed to the constructor have a key
beginning with "default_" then those values are passed to viaKLIX as
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

=head1 Setting viaKLIX parameters from content(%content)

The following rules are applied to map data to viaKLIX parameters
from content(%content):

    # viaKLIX param     => $content{<key>}
      ssl_merchant_id   => 'login',
      ssl_pin           => 'password',

      ssl_amount        => 'amount',
      ssl_card_number   => 'card_number',
      ssl_exp_date      => \( $month.$year ), # MM/YY from 'expiration'
      ssl_cvv2          => 'present' whenever cvv2 data is provided
      ssl_cvv2cvc2      => 'cvv2',
      ssl_description   => 'description',
      ssl_invoice_number=> 'invoice_number',
      ssl_customer_code   => 'customer_id',

      ssl_first_name    => 'first_name',
      ssl_last_name     => 'last_name',
      ssl_avs_address   => 'address',
      ssl_city          => 'city',
      ssl_state         => 'state',
      ssl_zip           => \$zip,       # 'zip' with non-alphanumerics removed
      ssl_country       => 'country',
      ssl_phone         => 'phone',
      ssl_email         => 'email',

      CardHolderName    => 'name',
      CustomerName      => 'account_name',


=head1 Mapping viaKLIX transaction responses to object methods

The following methods provides access to the transaction response data
resulting from a viaKLIX request (after submit()) is called:

=head2 order_number()

This order_number() method returns the ssl_txn_id field for card transactions
to uniquely identify the transaction.

=head2 result_code()

The result_code() method returns the ssl_result field for card transactions.
It is the numeric return code indicating the outcome of the attempted
transaction.

=head2 error_message()

The error_message() method returns the ssl_result_message field for
transactions.  This provides more details about the transaction result.

=head2 authorization()

The authorization() method returns the ssl_approval_code field,
which is the approval code obtained from the card processing network.

=head2 avs_code()

The avs_code() method returns the ssl_avs_response field from the
transaction result.

=head2 cvv2_response()

The cvv2_response() method returns the ssl_cvvw_response field, which is a
response message returned with the transaction result.

=head2 expdate_mmyy()

The expdate_mmyy() method takes a single scalar argument (typically
the value in $content{expiration}) and attempts to parse and format
and put the date in MMYY format as required by PayflowPro
specification.  If unable to parse the expiration date simply leave it
as is and let the PayflowPro system attempt to handle it as-is.

=head2 debug()

Enable or disble debugging.  The value specified here will also set
$Business::OnlinePayment::HTTPS::DEBUG in submit() to aid in
troubleshooting problems.

=head1 COMPATIBILITY

This module implements an interface to the viaKLIX API version 2.0

=head1 AUTHORS

Jeff Finucane <viaklix@weasellips.com>

Based on Business::OnlinePayment::PayflowPro written by Ivan Kohler
and Phil Lobbes.

=head1 SEE ALSO

perl(1), L<Business::OnlinePayment>, L<Carp>, and the Developer Guide to the
viaKLIX Virtual Terminal.

=cut
