package Business::OnlinePayment::IPayment::Return;
use strict;
use warnings;
use utf8;
use Moo;

=encoding utf8

=head1 NAME

Business::OnlinePayment::IPayment::Return - Helper class for Ipayment SOAP ipaymentReturn

=head1 SYNOPSIS

  my $bopi = Business::OnlinePayment::IPayment->new(....)
  # do the preauth transaction and post
  my $response = $ua->post($secbopi->ipayment_cgi_location, { ... });
  # get the parameters
  my $ipayres = $bopi->get_response_obj($response->header('location'));

  # here we have our Business::OnlinePayment::IPayment::Return object
  my $return = $bopi->capture($ipayres->ret_trx_number);
  if ($return->is_success) {
    print $return->address_info, "\n", $return->ret_transdate, "\n",
      $return->ret_transtime, "\n", $return->trx_paymentmethod, "\n",
      $return->ret_trx_number, "\n", $return->ret_authcode, "\n",
      $return->trx_paymentdata_country, "\n"
  }
  elsif($return->is_error) {
    print $return->status, $return->error_info
  }
  
=cut

# please note that the interface is very similar to the
# IPayment::Respone, but the parsing is done differently. In fact,
# with a response we have the paramaters flattened, while with a SOAP
# response we get nested structures.

=head2 ACCESSORS

We get this from the response hashref from the SOAP server

=over 4

=item errorDetails

Hashref with the error details

   {
   'retAdditionalMsg' => 'Not enough funds left (28184) for this capture.',
   'retFatalerror' => 0,
   'retErrorMsg' => 'Capture nicht m',
   'retErrorcode' => 10031
   }


=cut

has errorDetails => (is => 'ro');

=item status

=item ret_status

Status string (ERROR or SUCCESS)

=cut

has status => (is => 'ro',
               default => sub { return "" });

sub ret_status {
    return shift->status;
}


=item successDetails

Hashref with the success details

  {
    'retTransDate' => '17.04.13',
    'retTrxNumber' => '1-84664243',
    'retTransTime' => '10:34:10',
    'retAuthCode' => '',
    'retStorageId' => '18895061', # if storage is used
    'trxPayauthStatus' => 'I', # 3D detail
    'trxIssuerAvsResponse' => 'A', # avs detail
  }                                                                   }

=cut

has successDetails => (is => 'ro');


=item trx_paymentmethod

=item paymentMethod

In this parameter the name of the medium used, payment will be
returned. the For example, a credit card type (such as Visa or
MasterCard) or ELV.

=cut

has paymentMethod => (is => 'ro',
                      default => sub { return "" });

sub trx_paymentmethod {
    return shift->paymentMethod;
}

=item trx_remoteip_country

=item trxRemoteIpCountry

Iso code of the IP which does the transaction.

=cut

has trxRemoteIpCountry => (is => 'ro',
                           default => sub { return "" });

sub trx_remoteip_country {
    return shift->trxRemoteIpCountry;
}


=item trx_paymentdata_country 

=item trxPaymentDataCountry

In this parameter, if possible, the ISO code of the country returned
to the the payment data belongs. The field contains, for example, for
credit card payments, the country the card-issuing bank and ELV
payments the bank country.

=cut

has trxPaymentDataCountry => (is => 'ro',
                              default => sub { return "" });


sub trx_paymentdata_country {
    return shift->trxPaymentDataCountry;
}

=item addressData

Hashref with the details of the cardholder's address

=cut

has addressData => (is => 'ro');


=item is_success

Return true if the transaction was successful, false otherwise

=cut

sub is_success {
    my $self = shift;
    if ((uc($self->status) eq 'SUCCESS') and
        $self->successDetails) {
        return 1
    } else {
        return undef
    }
}

=item is_error

Return true if there is an error and the SOAP service says so.

=cut

sub is_error {
    my $self = shift;
    if ((uc($self->status) eq 'ERROR') or (!$self->is_success)) {
        return 1
    } else {
        return undef
    }
}

=item address_info

The various AddressData fields combined in a single string. It could
return just an empty string.

=cut


sub address_info {
    my $self = shift;
    my $data = $self->addressData;
    return "" unless $data;
    my @details;
    foreach my $k (qw/addrName addrStreet addrStreet2 addrZip addrCity
                      addrState addrCountry addrEmail addrTelefon 
                      addrTelefax/) {
        if (my $f = $data->{$k}) {
            push @details, $f;
        }
    }
    return join(" ", @details);
}

=item error_info

Given that if you need to access the individual fields of the error,
the method C<errorDetails> is available, you may want to use this for
a stringified message, which basically combine all the 4 fields.

=cut


sub error_info {
    my $self = shift;
    return "" unless $self->is_error;
    my $error_details = $self->errorDetails;
    unless ($error_details) {
        warn "An error without an error string?\n";
        return ""
    }
    my @errors;
    if ($error_details->{retFatalerror}) {
        push @errors, "FATAL:";
    }
    foreach my $k (qw/retErrorMsg retAdditionalMsg retErrorcode/) {
        push @errors, $error_details->{$k} if $error_details->{$k}
    }
    return join(" ", @errors);
}

=item ret_transdate

=item ret_transtime

=item trx_timestamp

Date of the transaction, time of the transaction, and the two combined.

=cut

sub ret_transdate {
    my $self = shift;
    return "" unless ($self->successDetails and
                      defined $self->successDetails->{retTransDate});
    return $self->successDetails->{retTransDate};
}

sub ret_transtime {
    my $self = shift;
    return "" unless ($self->successDetails and
                      defined $self->successDetails->{retTransTime});
    return $self->successDetails->{retTransTime};
}

sub trx_timestamp {
    my $self = shift;
    if ($self->ret_transdate or $self->ret_transtime) {
        return $self->ret_transdate . " " . $self->ret_transtime;
    } else {
        return "";
    }
}

=item ret_trx_number

Transaction number, as returned by the IPayment server

=cut

sub ret_trx_number {
    my $self = shift;
    return "" unless ($self->successDetails and
                      defined($self->successDetails->{retTrxNumber}));
    return $self->successDetails->{retTrxNumber};
}


=item ret_authcode

Auth code, as returned by the IPayment server

=cut

sub ret_authcode {
    my $self = shift;
    return "" unless ($self->successDetails and
                      defined($self->successDetails->{retAuthCode}));
    return $self->successDetails->{retAuthCode};
}

=item storage_id

The storage id (if used).

=cut

sub storage_id {
    my $self = shift;
    return "" unless ($self->successDetails and
                      defined($self->successDetails->{retStorageId}));
    return $self->successDetails->{retStorageId};
}

=item trx_issuer_avs_response

AVS related response.p. 62 of the doc

=cut

sub trx_issuer_avs_response {
    my $self = shift;
    return "" unless ($self->successDetails and
                      defined($self->successDetails->{trxIssuerAvsResponse}));
    return $self->successDetails->{trxIssuerAvsResponse};
}

=item trx_payauth_status

3D-related response, p. 62 of the doc

=cut

sub trx_payauth_status {
    my $self = shift;
    return "" unless ($self->successDetails and
                      defined($self->successDetails->{trxPayauthStatus}));
    return $self->successDetails->{trxPayauthStatus};
}


=item ret_errorcode

The error code. 0 in case of success

=cut

sub ret_errorcode {
    my $self = shift;
    unless ($self->errorDetails) {
        if (lc($self->status) eq 'success') {
            return 0;
        } else {
            return "";
        }
    }
    return $self->errorDetails->{retErrorcode};
}


=back

=cut

1;
