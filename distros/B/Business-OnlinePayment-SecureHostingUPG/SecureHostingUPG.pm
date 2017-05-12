package Business::OnlinePayment::SecureHostingUPG;

use strict;
use Carp;
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS;
use vars qw($VERSION $DEBUG @ISA);

@ISA = qw(Business::OnlinePayment::HTTPS);
$VERSION = '0.03';
$DEBUG = 0;

sub set_defaults {
	my $self = shift;

	$self->server('www.secure-server-hosting.com');
	$self->port('443');
	$self->path('/secutran/transactionjs1.php');

	$self->build_subs(qw(
	  order_number avs_code
	                 ));
        # order_type
	# md5 cvv2_response cavv_response

}

sub submit {
    my($self) = @_;

    #$self->map_fields();
    $self->remap_fields(
        #                => 'order_type',
        #                => 'transaction_type',
        login            => 'shreference',
        password         => 'checkcode',
        #authorization   => 
        #customer_ip     =>
        name             => 'cardholdersname',
        #first_name      =>
        #last_name       =>
        #company         =>
        address          => 'cardholderaddr1',
        #                => 'cardholderaddr2',
        city             => 'cardholdercity',
        state            => 'cardholderstate',
        zip              => 'cardholderpostcode',
        #country         =>
        phone            => 'cardholdertelephonenumber',
        #fax             =>
        email            => 'cardholdersemail',
        card_number      => 'cardnumber',
        #                => 'cardexpiremonth',
        #                => 'cardexpireyear',

        'amount'         => 'transactionamount',
        #invoice_number  =>
        #customer_id     =>
        #order_number    =>

        currency          => 'transactioncurrency',

        #expiration        =>
        cvv2              => 'cv2',
        issue_number      => 'switchnumber',
    );

    die "only Normal Authorization is currently supported"
      unless $self->{_content}{'action'} =~ /^\s*normal\s*authorization\s*$/i;

    #cardexpiremonth & cardexpireyear
    $self->{_content}{'expiration'} =~ /^(\d+)\D+\d*(\d{2})$/
      or croak "unparsable expiration ". $self->{_content}{expiration};
    my( $month, $year ) = ( $1, $2 );
    $month = '0'. $month if $month =~ /^\d$/;
    $self->{_content}{cardexpiremonth} = $month;
    $self->{_content}{cardexpireyear} = $year;

    #cardstartmonth & cardstartyear
    $self->{_content}{'card_start'} =~ /^(\d+)\D+\d*(\d{2})$/
      or croak "unparsable card_start ". $self->{_content}{expiration};
    my( $smonth, $syear ) = ( $1, $2 );
    $smonth = '0'. $smonth if $smonth =~ /^\d$/;
    $self->{_content}{cardstartmonth} = $smonth;
    $self->{_content}{cardstartyear} = $syear;

    $self->required_fields(qw(
      shreference checkcode transactionamount transactioncurrency
      cardexpireyear cardexpiremonth cardstartyear cardstartmonth
      switchnumber cv2 cardnumber cardholdersname cardholdersemail
    ));

    my( $page, $response, @reply_headers) =
      $self->https_post( $self->get_fields( $self->fields ) );
    #my( $page, $response, @reply_headers) =
    #  $self->https_get( $self->get_fields( $self->fields ) );

    #my %reply_headers = @reply_headers;
    #warn join('', map { "  $_ => $reply_headers{$_}\n" } keys %reply_headers )
    #  if $DEBUG;

    #XXX check $response and die if not 200?

    #	avs_code
    #	is_success
    #	result_code
    #	authorization
    #md5 cvv2_response cavv_response ...?

    $self->server_response($page);

    my $result = $self->GetXMLProp($page, 'result');

    if ( defined($result) && $result eq 'success' ) {
      $self->is_success(1);
      $self->avs_code( $self->GetXMLProp($page, 'cv2asvresult') );
    } elsif ( defined($result) && $result eq 'failed' ) {
      $self->is_success(0);
      my $error = '';
      my $tranerrdesc   = $self->GetXMLProp($page, 'tranerrdesc');
      my $tranerrdetail = $self->GetXMLProp($page, 'tranerrdetail');
      $error = $tranerrdesc if defined $tranerrdesc;
      $error .= " - $tranerrdetail"
        if defined $tranerrdetail && length $tranerrdetail;
      $self->error_message($error);
    } else {
      die "unparsable response received from gateway".
          ( $DEBUG ? ": $page" : '' );
    }

}


sub fields {
	my $self = shift;

	qw(
	  shreference
	  checkcode
	  transactionamout
	  transactioncurrency
	  cardexpireyear
	  cardexpiremonth
	  cardstartyear
	  cardstartmonth
	  switchnumber
	  cv2
	  cardnumber
	  cardholdersname
	  cardholdersemail
	  cardholderaddr1
	  cardholderaddr2
	  cardholdercity
	  cardholderstate
	  cardholderpostcode
	  cardholdertelephonenumber
	);
}

sub GetXMLProp {
	my( $self, $raw, $prop ) = @_;
	local $^W=0;

	my $data;
	($data) = $raw =~ m"<$prop>(.*?)</$prop>"gsi;
	#$data =~ s/<.*?>/ /gs;
	chomp $data;
	return $data;
}

1;

__END__

=head1 NAME

Business::OnlinePayment::SecureHostingUPG - SecureHosting UPG backend module for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # One step transaction, the simple case.
  ####

  my $tx = new Business::OnlinePayment("SecureHostingUPG");
  $tx->content(
      type           => 'VISA',
      login          => 'SecureHosting Reference',
      password       => 'SecureHosting Checkcode value',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      currency       => 'GBP',
      name           => 'Tofu Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      phone          => '420-867-5309',
      email          => 'tofu.beast@example.com',
      card_number    => '4005550000000019',
      expiration     => '08/06',
      card_start     => '05/04',
      cvv2           => '1234', #optional
      issue_number   => '5678',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSACTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

Content required: type, login, password, action, amount, first_name, last_name, card_number, expiration.

=head1 PREREQUISITES

  URI::Escape
  Tie::IxHash

  Net::SSLeay _or_ ( Crypt::SSLeay and LWP )

  The included htmlgood.html and htmlbad.html files must be uploaded to your
  Secure Hosting account (Settings | File Manager).

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

Only "Normal Authorization" is supported by the gateway.

=head1 AUTHOR

Ivan Kohler <ivan-securehostingupg@420.am>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

