package Business::OnlinePayment::PaymenTech;

use strict;
use Carp;
use Business::OnlinePayment::HTTPS;
use XML::Simple;
use Tie::IxHash;
use vars qw($VERSION $DEBUG @ISA $me);

@ISA = qw(Business::OnlinePayment::HTTPS);

$VERSION = '2.05';
$VERSION = eval $VERSION; # modperlstyle: convert the string into a number

$DEBUG = 0;
$me='Business::OnlinePayment::PaymenTech';

my %request_header = (
  'MIME-VERSION'    =>    '1.0',
  'Content-Transfer-Encoding' => 'text',
  'Request-Number'  =>    1,
  'Document-Type'   =>    'Request',
  'Interface-Version' =>  "$me $VERSION",
); # Content-Type has to be passed separately

tie my %new_order, 'Tie::IxHash', (
  OrbitalConnectionUsername => [ ':login', 32 ],
  OrbitalConnectionPassword => [ ':password', 32 ],
  IndustryType              => [ 'EC', 2 ],
  MessageType               => [ ':message_type', 2 ],
  BIN                       => [ ':bin', 6 ],
  MerchantID                => [ ':merchant_id', 12 ],
  TerminalID                => [ ':terminal_id', 3 ],
  CardBrand                 => [ '', 2 ], 
  AccountNum                => [ ':card_number', 19 ],
  Exp                       => [ ':expiration', 4 ],
  CurrencyCode              => [ ':currency_code', 3 ],
  CurrencyExponent          => [ ':currency_exp', 6 ],
  CardSecValInd             => [ ':cvvind', 1 ],
  CardSecVal                => [ ':cvv2', 4 ],
  AVSzip                    => [ ':zip', 10 ],
  AVSaddress1               => [ ':address', 30 ],
  AVScity                   => [ ':city', 20 ],
  AVSstate                  => [ ':state', 2 ],
  AVScountryCode            => [ ':country', 2 ],
  OrderID                   => [ ':invoice_number', 22 ], 
  Amount                    => [ ':amount', 12 ],
  Comments                  => [ ':email', 64 ],
  TxRefNum                  => [ ':order_number', 40 ],# used only for Refund
);

tie my %mark_for_capture, 'Tie::IxHash', (
  OrbitalConnectionUsername => [ ':login', 32 ],
  OrbitalConnectionPassword => [ ':password', 32 ],
  OrderID                   => [ ':invoice_number', 22 ],
  Amount                    => [ ':amount', 12 ],
  BIN                       => [ ':bin', 6 ],
  MerchantID                => [ ':merchant_id', 12 ],
  TerminalID                => [ ':terminal_id', 3 ],
  TxRefNum                  => [ ':order_number', 40 ],
);

tie my %reversal, 'Tie::IxHash', (
  OrbitalConnectionUsername => [ ':login', 32 ],
  OrbitalConnectionPassword => [ ':password', 32 ],
  TxRefNum                  => [ ':order_number', 40 ],
  TxRefIdx                  => [ '0', 4 ],
  OrderID                   => [ ':invoice_number', 22 ],
  BIN                       => [ ':bin', 6 ],
  MerchantID                => [ ':merchant_id', 12 ],
  TerminalID                => [ ':terminal_id', 3 ],
  OnlineReversalInd         => [ 'Y', 1 ],
# Always attempt to reverse authorization.
);

my %defaults = (
  terminal_id => '001',
  currency    => 'USD',
  cvvind      => '',
);

my @required = ( qw(
  login
  password
  action
  bin
  merchant_id
  invoice_number
  amount
  )
);

my %currency_code = (
# Per ISO 4217.  Add to this as needed.
  USD => [840, 2],
  CAD => [124, 2],
  MXN => [484, 2],
);

my %paymentech_countries = map { $_ => 1 } qw( US CA GB UK );

sub set_defaults {
    my $self = shift;

    $self->server('orbitalvar1.paymentech.net') unless $self->server; # this is the test server.
    $self->port('443') unless $self->port;
    $self->path('/authorize') unless $self->path;

    $self->build_subs(qw( 
      order_number
    ));

    #leaking gateway-specific anmes?  need to be mapped to B:OP standards :)
    # ProcStatus 
    # ApprovalStatus 
    # StatusMsg 
    # RespCode
    # AuthCode
    # AVSRespCode
    # CVV2RespCode
    # Response
}

sub build {
  my $self = shift;
  my %content = $self->content();
  my $skel = shift;
  tie my %data, 'Tie::IxHash';
  ref($skel) eq 'HASH' or die 'Tried to build non-hash';
  foreach my $k (keys(%$skel)) {
    my $v = $skel->{$k};
    my $l;
    ($v, $l) = @$v if(ref $v eq 'ARRAY');
    if($v =~ /^:(.*)/) {
      # Get the content field with that name.
      $data{$k} = $content{$1};
    }
    else {
      $data{$k} = $v;
    }
    # Ruthlessly enforce field length.
    $data{$k} = substr($data{$k}, 0, $l) if($data{$k} and $l);
  }
  return \%data;
}

sub map_fields {
    my($self) = @_;

    my %content = $self->content();
    foreach(qw(merchant_id terminal_id currency)) {
      $content{$_} = $self->{$_} if exists($self->{$_});
    }

    $self->required_fields('action');
    my %message_type = 
                  ('normal authorization' => 'AC',
                   'authorization only'   => 'A',
                   'credit'               => 'R',
                   'void'                 => 'V',
                   'post authorization'   => 'MFC', # for our use, doesn't go in the request
                   ); 
    $content{'message_type'} = $message_type{lc($content{'action'})} 
      or die "unsupported action: '".$content{'action'}."'";

    foreach (keys(%defaults) ) {
      $content{$_} = $defaults{$_} if !defined($content{$_});
    }
    if(length($content{merchant_id}) == 12) {
      $content{bin} = '000002' # PNS
    }
    elsif(length($content{merchant_id}) == 6) {
      $content{bin} = '000001' # Salem
    }
    else {
      die "invalid merchant ID: '".$content{merchant_id}."'";
    }

    @content{qw(currency_code currency_exp)} = @{$currency_code{$content{currency}}}
      if $content{currency};

    if($content{card_number} =~ /^(4|6011)/) { # Matches Visa and Discover transactions
      if(defined($content{cvv2})) {
        $content{cvvind} = 1; # "Value is present"
      }
      else {
        $content{cvvind} = 9; # "Value is not available"
      }
    }
    $content{amount} = int($content{amount}*100);
    $content{name} = $content{first_name} . ' ' . $content{last_name};
# According to the spec, the first 8 characters of this have to be unique.
# The test server doesn't enforce this, but we comply anyway to the extent possible.
    if(! $content{invoice_number}) {
      # Choose one arbitrarily
      $content{invoice_number} ||= sprintf("%04x%04x",time % 2**16,int(rand() * 2**16));
    }

    # Always send as MMYY
    $content{expiration} =~ s/\D//g; 
    $content{expiration} = sprintf('%04d',$content{expiration});

    $content{country} ||= 'US';
    $content{country} = ( $paymentech_countries{ $content{country} }
                            ? $content{country}
                            : ''
                        ),

    $self->content(%content);
    return;
}

sub submit {
  my($self) = @_;
  $DB::single = $DEBUG;

  $self->map_fields();
  my %content = $self->content;

  my @required_fields = @required;

  my $request;
  if( $content{'message_type'} eq 'MFC' ) {
    $request = { MarkForCapture => $self->build(\%mark_for_capture) };
    push @required_fields, 'order_number';
  }
  elsif( $content{'message_type'} eq 'V' ) {
    $request = { Reversal => $self->build(\%reversal) };
  }
  else { 
    $request = { NewOrder => $self->build(\%new_order) }; 
    push @required_fields, qw(
      card_number
      expiration
      currency
      address
      city
      zip
      );
  }

  $self->required_fields(@required_fields);

  my $post_data = XMLout({ Request => $request }, KeepRoot => 1, NoAttr => 1, NoSort => 1);

  if (!$self->test_transaction()) {
    $self->server('orbital1.paymentech.net');
  }

  warn $post_data if $DEBUG;
  $DB::single = $DEBUG;
  my($page,$server_response,%headers) =
    $self->https_post( { 'Content-Type' => 'application/PTI47', 
                         'headers' => \%request_header } ,
                          $post_data);

  warn $page if $DEBUG;

  my $response = XMLin($page, KeepRoot => 0);
  #$self->Response($response);

  #use Data::Dumper;
  #warn Dumper($response) if $DEBUG;

  my ($r) = values(%$response);
  #foreach(qw(ProcStatus RespCode AuthCode AVSRespCode CVV2RespCode)) {
  #  if(exists($r->{$_}) and
  #     !ref($r->{$_})) {
  #    $self->$_($r->{$_});
  #  }
  #}

  foreach (keys %$r) {

    #turn empty hashrefs into the empty string
    $r->{$_} = '' if ref($r->{$_}) && ! keys %{ $r->{$_} };

    #turn hashrefs with content into scalars
    $r->{$_} = $r->{$_}{'content'}
      if ref($r->{$_}) && exists($r->{$_}{'content'});
  }

  if ($server_response !~ /^200/) {

    $self->is_success(0);
    my $error = "Server error: '$server_response'";
    $error .= " / Transaction error: '".
              ($r->{'ProcStatusMsg'} || $r->{'StatusMsg'}) . "'"
      if $r->{'ProcStatus'} != 0;
    $self->error_message($error);

  } else {

    if ( !exists($r->{'ProcStatus'}) ) {

      $self->is_success(0);
      $self->error_message( "Malformed response: '$page'" );

    } elsif ( $r->{'ProcStatus'} != 0 or 
              # NewOrders get ApprovalStatus, Reversals don't.
              ( exists($r->{'ApprovalStatus'}) ?
                $r->{'ApprovalStatus'} != 1 :
                $r->{'StatusMsg'} ne 'Approved' )
            )
    {

      $self->is_success(0);
      $self->error_message( "Transaction error: '".
                            ($r->{'ProcStatusMsg'} || $r->{'StatusMsg'}) . "'"
                          );

    } else { # success!

      $self->is_success(1);
      # For credits, AuthCode is empty and gets converted to a hashref.
      $self->authorization($r->{'AuthCode'}) if !ref($r->{'AuthCode'});
      $self->order_number($r->{'TxRefNum'});
    }

  }

}

1;
__END__

=head1 NAME

Business::OnlinePayment::PaymenTech - Chase Paymentech backend for Business::OnlinePayment

=head1 SYNOPSIS

  $trans = new Business::OnlinePayment('PaymenTech',
    merchant_id     => "000111222333",
    terminal_id     => "001",
    currency        => "USD", # CAD, MXN
  );

  $trans->content(
    login           => "login",
    password        => "password",
    type            => "CC",
    card_number     => "5500000000000004",
    expiration      => "0211",
    address         => "123 Anystreet",
    city            => "Sacramento",
    zip             => "95824",
    action          => "Normal Authorization",
    amount          => "24.99",
  );

  $trans->submit;
  if($trans->is_approved) {
    print "Approved: ".$trans->authorization;
  } else {
    print "Failed: ".$trans->error_message;
  }

=head1 NOTES

Electronic check processing and recurring billing are not yet supported.

=head1 AUTHOR

Mark Wells, mark@freeside.biz

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

