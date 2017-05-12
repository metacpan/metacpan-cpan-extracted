package Business::OnlinePayment::AuthorizeNet::ARB;

use strict;
use Carp;
use Business::OnlinePayment::AuthorizeNet;
use Business::OnlinePayment::HTTPS;
use XML::Simple;
use XML::Writer;
use Tie::IxHash;
use vars qw($VERSION $DEBUG @ISA $me);

@ISA = qw(Business::OnlinePayment::AuthorizeNet Business::OnlinePayment::HTTPS);
$VERSION = '0.02';
$DEBUG = 0;
$me='Business::OnlinePayment::AuthorizeNet::ARB';

sub set_defaults {
    my $self = shift;

    $self->server('api.authorize.net') unless $self->server;
    $self->port('443') unless $self->port;
    $self->path('/xml/v1/request.api') unless $self->path;

    $self->build_subs(qw( order_number md5 avs_code cvv2_response
                          cavv_response
                     ));
}

sub map_fields {
    my($self) = @_;

    my %content = $self->content();

    # ACTION MAP
    my %actions = ('recurring authorization'
                      => 'ARBCreateSubscriptionRequest',
                   'modify recurring authorization'
                      => 'ARBUpdateSubscriptionRequest',
                   'cancel recurring authorization'
                      => 'ARBCancelSubscriptionRequest',
                  );
    $content{'action'} = $actions{lc($content{'action'} || '')} || $content{'action'};

    # TYPE MAP
    my %types = ('visa'               => 'CC',
                 'mastercard'         => 'CC',
                 'american express'   => 'CC',
                 'discover'           => 'CC',
                 'check'              => 'ECHECK',
                );
    $content{'type'} = $types{lc($content{'type'} || '')} || $content{'type'};
    $self->transaction_type($content{'type'});

    # ACCOUNT TYPE MAP
    my %account_types = ('personal checking'   => 'checking',
                         'personal savings'    => 'savings',
                         'business checking'   => 'businessChecking',
                         'business savings'    => 'savings',
                        );
    $content{'account_type'} = $account_types{lc($content{'account_type'} || '')}
                               || $content{'account_type'};

    # MASSAGE EXPIRATION 
    $content{'expdate_yyyymm'} = $self->expdate_yyyymm($content{'expiration'});

    # stuff it back into %content
    $self->content(%content);

}

sub revmap_fields {
  my $self = shift;
  tie my(%map), 'Tie::IxHash', @_;
  my %content = $self->content();
  map {
        my $value;
        if ( ref( $map{$_} ) eq 'HASH' ) {
          $value = $map{$_} if ( keys %{ $map{$_} } );
        }elsif( exists( $content{ $map{$_} } ) ) {
          $value = $content{ $map{$_} };
        }

        if (defined($value)) {
          ($_ => $value);
        }else{
          ();
        }
      } (keys %map);
}

sub expdate_yyyymm {
  my $self = shift;
  my $expiration = shift;
  my $expdate_yyyymm;
  if ( defined($expiration) and $expiration =~ /^(\d{1,2})\D+(\d{2})$/ ) {
    my ( $month, $year ) = ( $1, $2 );
   $expdate_yyyymm = sprintf( "20%02d-%02d", $year, $month );
  }
  return defined($expdate_yyyymm) ? $expdate_yyyymm : $expiration;
};

sub _xmlwrite {
  my ($self, $writer, $item, $value) = @_;
  $writer->startTag($item);
  if ( ref( $value ) eq 'HASH' ) {
    foreach ( keys ( %$value ) ) {
      $self->_xmlwrite($writer, $_, $value->{$_});
    }
  }else{
    $writer->characters($value);
  }
  $writer->endTag($item);
}

sub submit {
  my($self) = @_;

  $self->map_fields();

  my @required_fields = qw(action login password);

  if ( $self->{_content}->{action} eq 'ARBCreateSubscriptionRequest' ) {
    push @required_fields,
      qw( type interval start periods amount first_name last_name );

    if ($self->transaction_type() eq "ECHECK") {
      push @required_fields,
        qw( amount routing_code account_number account_type account_name
            check_type
          );
    } elsif ($self->transaction_type() eq 'CC' ) {
      push @required_fields, qw( card_number expiration );
    }
  }elsif ( $self->{_content}->{action} eq 'ARBUpdateSubscriptionRequest' ) {
    push @required_fields, qw( subscription );
  }elsif ( $self->{_content}->{action} eq 'ARBCancelSubscriptionRequest' ) {
    push @required_fields, qw( subscription );
  }else{
    croak "$me can't handle transaction type: ".
      $self->{_content}->{action}. " for ". 
      $self->transaction_type();
  }

  $self->required_fields(@required_fields);

  tie my %merchant, 'Tie::IxHash',
    $self->revmap_fields(
                          name           => 'login',
                          transactionKey => 'password',
                        );

  my ($length,$unit) =
    ($self->{_content}->{interval} or '') =~ /^\s*(\d+)\s+(day|month)s?\s*$/;
  tie my %interval, 'Tie::IxHash', (
                                     ($length ? (length => $length)   : () ),
                                     ($unit   ? (unit   => $unit.'s') : () ),
                                   );

  tie my %schedule, 'Tie::IxHash',
    $self->revmap_fields(
                          interval         => \%interval,
                          startDate        => 'start',
                          totalOccurrences => 'periods',
                          trialOccurrences => 'trialperiods',
                        );

  tie my %account, 'Tie::IxHash', ( 
    ( defined($self->transaction_type())
      && $self->transaction_type() eq 'CC'
    ) ? $self->revmap_fields(
                              cardNumber     => 'card_number',
                              expirationDate => 'expdate_yyyymm',
                            )
      : $self->revmap_fields(
                              accountType    => 'account_type',
                              routingNumber  => 'routing_code',
                              accountNumber  => 'account_number',
                              nameOnAccount  => 'account_name',
                              echeckType     => 'check_type',
                              bankName       => 'bank_name',
                            )
  );

  tie my %payment, 'Tie::IxHash',
    $self->revmap_fields(
                           ( ( defined($self->transaction_type()) && # require?
                               $self->transaction_type() eq 'CC'
                             ) ?  'creditCard'
                               : 'bankAccount'
                           )  => \%account,
                         );

  tie my %order, 'Tie::IxHash',
    $self->revmap_fields(
                          invoiceNumber => 'invoice_number',
                          description   => 'description',
                        );

  tie my %drivers, 'Tie::IxHash',
    $self->revmap_fields(
                          number      => 'license_num',
                          state       => 'license_state',
                          dateOfBirth => 'license_dob',
                        );

  tie my %billto, 'Tie::IxHash',
    $self->revmap_fields(
                          firstName => 'first_name',
                          lastName  => 'last_name',
                          company   => 'company',
                          address   => 'address',
                          city      => 'city',
                          state     => 'state',
                          zip       => 'zip',
                          country   => 'country',
                        );

  tie my %shipto, 'Tie::IxHash',
    $self->revmap_fields(
                          firstName => 'ship_first_name',
                          lastName  => 'ship_last_name',
                          company   => 'ship_company',
                          address   => 'ship_address',
                          city      => 'ship_city',
                          state     => 'ship_state',
                          zip       => 'ship_zip',
                          country   => 'ship_country',
                        );

  tie my %customer, 'Tie::IxHash',
    $self->revmap_fields(
                          type           => 'customer_org',
                          id             => 'customer_id',
                          email          => 'email',
                          phoneNumber    => 'phone',
                          faxNumber      => 'fax',
                          driversLicense => \%drivers,
                          taxid          => 'customer_ssn',
                        );

  tie my %sub, 'Tie::IxHash',
    $self->revmap_fields(
                          name            => 'subscription_name',
                          paymentSchedule => \%schedule,
                          amount          => 'amount',
                          trialAmount     => 'trialamount',
                          payment         => \%payment,
                          order           => \%order,
                          customer        => \%customer,
                          billTo          => \%billto,
                          shipTo          => \%shipto,
                        );


  tie my %req, 'Tie::IxHash',
    $self->revmap_fields (
                           merchantAuthentication => \%merchant,
                           subscriptionId         => 'subscription',
                           subscription           => \%sub,
                         );

  my $ns = "AnetApi/xml/v1/schema/AnetApiSchema.xsd";
  my $post_data;
  my $writer = new XML::Writer( OUTPUT      => \$post_data,
                                DATA_MODE   => 1,
                                DATA_INDENT => 1,
                                ENCODING    => 'utf-8',
                              );
  $writer->xmlDecl();
  $writer->startTag($self->{_content}->{action}, 'xmlns', $ns);
  foreach ( keys ( %req ) ) {
    $self->_xmlwrite($writer, $_, $req{$_});
  }
  $writer->endTag($self->{_content}->{action});
  $writer->end();

  if ($self->test_transaction()) {
    $self->server('apitest.authorize.net');
  }

  warn $post_data if $DEBUG;
  my($page,$server_response,%headers) =
    $self->https_post( { 'Content-Type' => 'text/xml' }, $post_data);

  #trim leading (4?) characters of unknown origin not in spec
  $page =~ s/^(.*?)</</;
  my $garbage=$1;
  warn "Trimmed $garbage from response page.\n" if $DEBUG;

  warn $page if $DEBUG;

  my $response;
  my $message;
  if ($server_response =~ /200/){
    $response = XMLin($page);
    if (ref($response->{messages}->{message}) eq 'ARRAY') {
      $message = $response->{messages}->{message}->[0];
    }else{
      $message = $response->{messages}->{message};
    }
  }else{
    $response->{messages}->{resultCode} = "Server Failed";
    $message->{code} = $server_response;
  }

  $self->server_response($page);
  $self->order_number($response->{subscriptionId});
  $self->result_code($message->{code});
  $self->error_message($message->{text});

  if($response->{messages}->{resultCode} eq "Ok" ) {
      $self->is_success(1);
  } else {
      $self->is_success(0);
      unless ( $self->error_message() ) { #additional logging information
        $self->error_message(
          "(HTTPS response: $server_response) ".
          "(HTTPS headers: ".
            join(", ", map { "$_ => ". $headers{$_} } keys %headers ). ") ".
          "(Raw HTTPS content: $page)"
        );
      }
  }
}

1;
__END__

=head1 NAME

Business::OnlinePayment::AuthorizeNet::ARB - AuthorizeNet ARB backend for Business::OnlinePayment

=head1 AUTHOR

Jeff Finucane, authorizenetarb@weasellips.com

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

