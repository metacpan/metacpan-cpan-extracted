package Business::OnlinePayment::VirtualNet;

use strict;
use Carp;
use File::CounterFile;
use Date::Format;
use Business::OnlinePayment;
#use Business::CreditCard;
use Net::SSLeay qw( make_form post_https );
use String::Parity qw(setEvenParity isEvenParity);
use String::LRC;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.02';

$DEBUG ||= 0;

use vars qw( $STX $ETX $FS $ETB );
$STX = pack("C", 0x02 );
$ETX = pack("C", 0x03 );
$FS = pack("C", 0x1c );
$ETB = pack("C", 0x17 );
#$EOT = pack("C", 0x04 );

##should be configurable **FIXME**
#my $industry_code = '0';
my $industry_code = 'D'; #Direct Marketing

sub set_defaults {
    my $self = shift;
    $self->server('ssl.pgs.wcom.net');
    $self->port('443');
    $self->path('/scripts/gateway.dll?Transact');

    $self->build_subs(qw( authorization_source_code returned_ACI
                          transaction_sequence_num transaction_identifier
                          validation_code local_transaction_date
                          local_transaction_time AVS_result_code ));
}

sub revmap_fields {
    my($self,%map) = @_;
    my %content = $self->content();
    foreach(keys %map) {
        $content{$_} = ref($map{$_})
                         ? ${ $map{$_} }
                         : $content{$map{$_}};
    }
    $self->content(%content);
}

sub get_fields {
    my($self,@fields) = @_;

    my %content = $self->content();
    my %new = ();
    foreach( grep defined $content{$_}, @fields) { $new{$_} = $content{$_}; }
    return %new;
}

sub submit {
    my($self) = @_;
    my %content = $self->content;

    my $action = lc($content{'action'});

    #? what's supported
    if (  $self->transaction_type() =~
           /^(cc|visa|mastercard|american express|discover)$/i ) {
      $self->required_fields(qw/type action amount card_number expiration/);
    } else {
      croak("VirtualNet can't handle transaction type: ".
            $self->transaction_type());
    }

    #my %content = $self->content;
    if ( $DEBUG ) {
      warn " \n";
      warn "content:$_ => $content{$_}\n" foreach keys %content;
    }

    my( $message, $mimetype );
    if ( $action eq 'authorization only' ) {
      $message = $self->eis1080_request( \%content );
      $mimetype = 'x-Visa-II/x-auth';
    } elsif ( $action eq 'post authorization' ) { 
      $message = $self->eis1081_request( \%content );
      $mimetype = 'x-Visa-II/x-settle';
    } elsif ( $action eq 'normal authorization' ) {
      croak 'Normal Authorization not supported';
    } elsif ( $action eq 'credit' ) {
      croak 'Credit not (yet) supported';
    }

    if ( $DEBUG ) {
      warn "post_data:$message\n";
    }

    my $server = $self->server();
    my $port = $self->port();
    my $path = $self->path();
    my($page,$response,%headers) =
      post_https($server,$port,$path,'',$message, $mimetype );

    #warn "Response: $page";

    if ( $page eq '' ) {
      die "protocol unsucessful: empty response, status $response\n";
    }

    if ( $page =~ /^(\d+)\s+\-\s+(\S.*)$/ ) {
      die "VirtualNet protocol error: $page";
    }

    warn "protocol sucessful, decoding VisaNet-II response\n" if $DEBUG;

    isEvenParity($page) or die "VisaNet-II response not even parity";
    $page =~ s/(.)/pack('C', unpack('C',$1) & 0x7f)/ge; #drop parity bits

    my %response;
    if ( $action eq 'authorization only' ) {
      %response = $self->eis1080_response( $page );
    } elsif ( $action eq 'post authorization' ) { 
      %response = $self->eis1081_response( $page );
    #} elsif ( $action eq 'normal authorization' ) {
    #  croak 'Normal Authorization not supported';
    #} elsif ( $action eq 'credit' ) {
    #  croak 'Credit not (yet) supported';
    }

    for my $field ( qw( is_success result_code error_message authorization
                        authorization_source_code returned_ACI
                        transaction_identifier validation_code
                        transaction_sequence_num local_transaction_date
                        local_transaction_time AVS_result_code ) ) {
      $self->$field($response{$field});
    }

}

sub testhost {
  my $self = shift;

  my $content = 'D4.999995';
  #my $content = 'D2.999995';
  #my $content = 'D0.999995';
  my $message = 
    $STX.
    $content.
    $ETX.
    lrc($content.$ETX)
  ;
  $message = setEvenParity $message;
  
  if ( $DEBUG ) {
    warn "post_data: $message\n";
    warn "post_data hex dump: ". join(" ", unpack("H*", $message) ). "\n";
  }

  my $server = $self->server();
  my $port = $self->port();
  my $path = $self->path();
  my($page,$response,%headers) =
    post_https($server,$port,$path,'',$message, 'x-Visa-II/x-auth');

  #warn "Response: $page";

  if ( $page =~ /^(\d+)\s+\-\s+(\S.*)$/ ) {
    die "VirtualNet protocol error: $page";
    #$self->is_success(0);
    #$self->result_code($1);
    #$self->error_message($2);
    #$self->error_message($page);
  } else {
    warn "protocol sucessful, not decoding VisaNet-II response" if $DEBUG;
    $self->is_success(1);
  }

}

sub eis1080_request {
  my( $self, $param ) = @_;
  # card_number expiration address zip amount

  #D-Format    Authorization Request Message  (Non-Set Electronic Commerce) 

#  my $zip = $param->{zip};
#  $zip =~ s/\D//g;
#  $zip = substr("$zip         ",0,9); #Left-justified/Space-filled

  $param->{expiration} =~ /^(\d{1,2})\D+(\d{2})?(\d{2})$/
    or croak "unparsable expiration ". $param->{expiration};
  my ($month, $year) = ( $1, $3 );
  $month = "0$month" if length($month) < 2;
  my $exp= "$month$year";

  #my $zip = $param->{zip};
  #$zip =~ s/\D//g;
  #$zip = substr("$zip         ",0,9);

  my $amount = $param->{amount};
  $amount =~ s/\.//;

  my $zip = substr( $self->zip. "         ", 0, 9 );

  my $seq_file = $self->seq_file;
  my $counter = File::CounterFile->new($seq_file, '0001')
    or die "can't create sequence file $seq_file: $!";

  $counter->lock();
  my $seq = substr('0000'.$counter->inc, -4);
  $seq = substr('0000'.$counter->inc, -4) if $seq eq '0000';
  $counter->unlock();

                                # Byte Length Field: Content

  my $content = 'D4.';            # 1     1    Record format: D
                                  # 2     1    Application Type: 4=Interleaved
                                  # 3     1    Message Delimiter: .
  $content .= $self->bin;         # 4-9   6    Acquirer BIN
  $content .= $self->merchant_id; # 10-21 12   Merchant Number
  $content .= $self->store;       # 22-25 4    Store Number
  $content .= $self->terminal;    # 26-29 4    Terminal Number
  $content .= 'Q';                # 30    1    Device Code:
                                  #          Q="Third party software developer"
  #$content .= 'C';                # 30    1    Device Code: C="P.C."
  #$content .= 'M';                # 30    1    Device Code: M="Main Frame"
  $content .= $industry_code;      # 31    1    Industry Code
  $content .= '840';              # 32-34 3    Currency Code: 840=U.S. Dollars
  $content .= '840';              # 35-37 3    Country Code: 840=United States
  $content .= $zip;               # 38-46 9    (Merchant) City Code(Zip);
  $content .= '00';               # 47-48 2    Language Indicator: 00=English
                                  # ***FIXME***
  $content .= '705';              # 49-51 3    Time Zone Differential: 705=EST
  $content .= $self->mcc;         # 52-55 4    Metchant Category Code: 5999
  $content .= 'Y';                # 56    1    Requested ACI (Authorization
                                  #            Characteristics Indicator):
                                  #            Y=Device is CPS capable
  $content .= $seq;               # 57-60 4    Tran Sequence Number
  $content .= '56';               # 61-62 2    Auth Transaction Code:
                                  #            56=Card Not Present
  $content .= 'N';                # 63    1    Cardholder ID Code: N=AVS
                                  #            (Address Verification Data or
                                  #            CPS/Card Not Present or
                                  #            Electronic Commerce)
  $content .= '@';                # 64    1    Account Data Source:
                                  #            @=No Cardreader

  die "content-length should be 64!" unless length($content) == 64;

  # - 5-76 Customer Data Field: Acct#<FS>ExpDate<FS>
  $content .= $param->{card_number}. $FS. $exp. $FS;

  # - 1 Field Separator
  $content .= $FS;

  # - 0-29 Address Verification Data
  $content .= substr($param->{address}, 0, 23)." ". substr($param->{zip}, 0, 5);

  $content .= $FS; # - 1 Field Separator
  $content .= $FS; # - 1 Field Separator

  $content .= $amount; # - 1-12 Transaction Amount

  $content .= $FS; # - 1 Field Separator
  $content .= $FS; # - 1 Field Separator
  $content .= $FS; # - 1 Field Separator

  # - 25 Merchant Name
  $content .= substr($self->merchant_name.(' 'x25),0,25);

  # - 13 Merchant City
  $content .= substr($self->merchant_city.(' 'x13),0,13);

  # - 2 Merchant State
  $content .= substr($self->merchant_state.('X'x2),0,2);

  $content .= $FS; # - 1 Field Separator
  $content .= $FS; # - 1 Field Separator
  $content .= $FS; # - 1 Field Separator

  #-----

  $content .= '014'; # - 3 Group III Version Number:
                     #014=MOTO/Electronic Commerce

  $content .= '7'; # - 1 MOTO/Electronic Com. Ind: 7= Non-Authenticated
                   # Security transaction, such as a channel-encrypted
                   # transaction (e.g., ssl, DES or RSA)


  my $message = 
    $STX.
    $content.
    $ETX.
    lrc($content.$ETX)
  ;

  $message = setEvenParity $message;

  $message;
}

sub eis1080_response {
  my( $self, $response) = @_;
  my %response;

  #$response =~ /^$STX(.{67})([\w ]{0,15})$FS([\w ]{0,4})$FS.*$ETX(.)$/
  $response =~ /^$STX(.{67})([\w ]{0,15})$FS([\w ]{0,4})$FS(\d{3})$ETX(.)$/
    or die "can't decode (eis1080) response: $response\n". join(' ', map { sprintf("%x", unpack('C',$_)) } split('', $response) );
  ( $response{transaction_identifier},
    $response{validation_code},
    my $group3version,
    my $lrc
  ) = ($2, $3, $4, $5);

  die "group iii version $group3version ne 014"
    unless $group3version eq '014';

  warn "$response\n".
       join(' ', map { sprintf("%x", unpack('C',$_)) } split('', $response) ).
       "\n"
    if $DEBUG;

  (
    $response{record_format},
    $response{application_type},
    $response{message_delimiter},
    $response{returned_ACI},
    $response{store_number},
    $response{terminal_number},
    $response{authorization_source_code},
    $response{transaction_sequence_num},
    $response{response_code},
    $response{approval_code},
    $response{local_transaction_date},
    $response{local_transaction_time},
    $response{auth_response_text},
    $response{AVS_result_code},
    $response{retrieval_reference_num},
    $response{market_specific_data_id},
  ) = unpack "AAAAA4A4A1A4A2A6A6A6A16A1A12A1", $1;

  if ( $response{record_format} ne "E" ) {
    die "unknown response record_format $response{record_format}";
  }
  if ( $response{application_type} ne "4" ) {
    die "unknown response record_format $response{application_type}";
  }
  if ( $response{message_delimiter} ne "." ) {
    die "unknown response record_format $response{message_delimiter}";
  }

  $response{is_success} = $response{response_code} =~ /^(00|85)$/;
  $response{result_code} = $response{response_code};
  $response{error_message} = $response{auth_response_text};
  $response{authorization} = $response{approval_code};

  %response;
}

sub eis1081_request {
  my( $self, $param ) = @_;

  my $batchnum_file = $self->batchnum_file;
  my $counter = File::CounterFile->new($batchnum_file, '001')
    or die "can't create batchnumuence file $batchnum_file: $!";

  $counter->lock();
  my $batchnum = substr('000'.$counter->inc, -3);
  $batchnum = substr('000'.$counter->inc, -3) if $batchnum eq '000';
  $counter->unlock();

  #K-Format Header Record (Base Group)
#Byte Length Frmt Field description Content Section
                                  # Byte Length Field: Content (section)
  my $header = 'K1.ZH@@@@';   # 1     1  A/N Record Format: K (4.154)
                              # 2     1  NUM Application Type: 1=Single Batch
                              #                                          (4.10)
                              # 3     1  A/N Message Delimiter: . (4.123)
                              # 4     1  A/N X.25 Routing ID: Z (4.226)
                              # 5-9   5  A/N Record Type: H@@@@ (4.155)
  $header .= $self->bin;      # 10-15 6  NUM Acquirer BIN  (4.2)
  $header .= $self->agent;    # 16-21 6  NUM Agent Bank Number (4.5)
  $header .= $self->can('chain') ? $self->chain : '000000';
                              # 22-27 6  NUM Agent Chain Number (4.6)
  $header .= $self->merchant_id; 
                              # 28-39 12 NUM Merchant Number (4.121)
  $header .= $self->store;    # 40-43 4  NUM Store Number (4.187)
  $header .= $self->terminal; # 44-47 4  NUM Terminal Number 9911 (4.195)
  $header .= 'Q';             # 48    1  A/N Device Code:
                              #       Q="Third party software developer" (4.62)
  #$header .= 'C';             # 48    1  A/N Device Code: C="P.C." (4.62)
  #$header .= 'M';            # 48    1  A/N Device Code M="Main Frame" (4.62)
  $header .= $industry_code;  # 49    1  A/N Industry Code (4.94)
  $header .= '840';           # 50-52 3  NUM Currency Code (4.52)
  $header .= '00';            # 53-54 2  NUM Language Indicator: 00=English
                              #                                         (4.104)
                              # ***FIXME***
  $header .= '705';           # 55-57 3  NUM Time Zone Differential (4.200)

  my $mmdd = substr(time2str('0%m%d',time),-4);
  $header .= $mmdd;           # 58-61 4  NUM Batch Transmission Date MMDD (4.22)

  $header .= $batchnum;       # 62-64 3  NUM Batch Number 001 - 999 (4.18)
  $header .= '0';             # 65    1  NUM Blocking Indicator 0=Not Blocked
                              #                                          (4.23)

  die "header length should be 65!" unless length($header) == 65;

  my $message = 
    $STX.
    $header.
    $ETB.
    lrc($header.$ETB)
  ;

  my $zip = substr( $self->zip. "         ", 0, 9 );

  #K-Format Parameter Record (Base Group)
#Byte Length Frmt Field Description Content Section

  my $parameter = 'K1.ZP@@@@'; # 1   1 A/N Record Format: K (4.154)
                               # 2   1 NUM Application Type: 1=Single Batch
                               #                                         (4.10)
                               # 3   1 A/N Message Delimiter: . (4.123)
                               # 4   1 A/N X.25 Routing ID: Z (4.226)
                               # 5-9 5 A/N Record Type: P@@@@ (4.155)
  $parameter .= '840';         # 10-12 3 NUM Country Code 840 4.47
  $parameter .= $zip;          # 13-21 9 A/N City Code
                               #    Left-Justified/Space-Filled 4.43
  $parameter .= $self->mcc;    # 22-25 4 NUM Merchant Category Code (4.116)

  # 26-50 25 A/N Merchant Name Left-Justified/Space-Filled (4.27.1)
  $parameter .= substr($self->merchant_name.(' 'x25),0,25);

  #51-63 13 A/N Merchant City Left-Justified/Space-Filled (4.27.2)
  $parameter .= substr($self->merchant_city.(' 'x13),0,13);

  # 64-65 2 A/N Merchant State (4.27.3)
  $parameter .= substr($self->merchant_state.('X'x2),0,2);

  $parameter .= '00001'; # 66-70 5 A/N Merchant Location Number 00001 4.120

  $parameter .= $self->v; # 71-78 8 NUM Terminal ID Number 00000001 4.194

  die "parameter length should be 78 (is ". length($parameter). ")!"
    unless length($parameter) == 78;

  $message .= 
    $STX.
    $parameter.
    $ETB.
    lrc($parameter.$ETB)
  ;

# K-Format Detail Record (Electronic Commerce)
#Byte Size Frmt Field Description Content Section
#D@@'D'  `
  my $detail = 'K1.ZD@@`D';  # 1   1 A/N Record Format: K (4.154)
                              # 2   1 NUM Application Type 1=Single Batch
                              #                                          (4.10)
                              # 3   1 A/N Message Delimiter: . (4.123)
                              # 4   1 A/N X.25 Routing ID: Z (4.226)
                              # 5-9 5 A/N Record Type: D@@`D (4.155)

  $detail .= '56';               # 10-11 2 A/N Transaction Code:
                                 #             56 = Card Not Present
                                 #             (4.205)
  $detail .= 'N';                # 12 1 A/N Cardholder Identification Code N 4.32
                                 #            (Address Verification Data or
                                 #            CPS/Card Not Present or
                                 #            Electronic Commerce)
  $detail .= '@';                # 13 1 A/N Account Data Source Code @ = No Cardreader 4.1
                                 #            @=No Cardreader

  #14-35 22 A/N Cardholder Account Number Left-Justified/Space-Filled 4.30
  $detail .= substr( $param->{card_number}.'                      ', 0, 22 );

  $detail .= 'Y';                # 36    1    Requested ACI (Authorization
                                 #            Characteristics Indicator):
                                 #            N (4.163)

  # 37 1 A/N Returned ACI (4.168)
  $detail .= $param->{returned_ACI} || ' ';

  # *** 38 1 A/N Authorization Source Code (4.13)
  $detail .= $param->{authorization_source_code} || '6';

  # 39-42 4 NUM Transaction Sequence Number Right-Justified/Zero-Filled (4.207)
  die "missing transaction_sequence_num"
    unless $param->{transaction_sequence_num};
  $detail .= $param->{transaction_sequence_num};
  
  $detail .= '00'; # ###FIXME (from auth)*** 43-44 2 A/N Response Code 4.164
  
  # 45-50 6 A/N Authorization Code Left-Justified/Space-Filled (4.12)
  $detail .= $param->{authorization};

  # 51-54 4 NUM Local Transaction Date MMDD (4.113)
  die "missing local_transaction_date"
    unless $param->{local_transaction_date};
  $detail .= substr($param->{local_transaction_date}, 0, 4);

  # 55-60 6 NUM Local Transaction Time HHMMSS (4.114)
  die "missing local_transaction_time"
    unless $param->{local_transaction_time};
  #die "length of local_transaction_time ". $param->{local_transaction_time}.
  #    " != 6"
  #  unless length($param->{local_transaction_time}) == 6;
  $detail .= $param->{local_transaction_time};
  
  #(from auth) 61 1 A/N AVS Result Code 4.3
  die "missing AVS_result_code"
    unless $param->{AVS_result_code};
  $detail .= $param->{AVS_result_code};

  # 62-76 15 A/N Transaction Identifier Left-Justified/Space-Filled 4.206
  my $transaction_identifier =
    length($param->{transaction_identifier})
      ? substr($param->{transaction_identifier}. (' 'x15), 0, 15)
      : '000000000000000';
  $detail .= $transaction_identifier;

  # 77-80 4 A/N Validation Code 4.218
  $detail .= substr($param->{validation_code}.'    ', 0, 4);
  
  $detail .= ' '; # 81 1 A/N Void Indicator <SPACE> = Not Voided 4.224
  $detail .= '00'; # 82-83 2 NUM Transaction Status Code 00 4.208
  $detail .= '0'; # 84 1 A/N Reimbursement Attribute 0 4.157

  my $amount = $param->{amount};
  $amount =~ s/\.//;
  $amount = substr('000000000000'.$amount,-12);

  $detail .= $amount; # 85-96 12 NUM Settlement Amount
                      # Right-Justified/Zero-Filled 4.175

  $detail .= $amount; # 97-108 12 NUM Authorized Amount
                      # Right-Justified/Zero-Filled 4.14

  $detail .= $amount; # 109-120 12 NUM Total Authorized Amount
                      # Right-Justified/Zero-Filled 4.201

#  $detail .= '1'; # 121 1 A/N Purchase Identifier Format Code 1 4.150
#
#  # 122-146 25 A/N Purchase Identifier Left-Justified/Space-Filled 4.149
#  $detail .= 'Internet Services        ';
#             #1234567890123456789012345

  $detail .= '0'; # 121 1 A/N Purchase Identifier Format Code 1 4.150

  # 122-146 25 A/N Purchase Identifier Left-Justified/Space-Filled 4.149
  $detail .= '                         ';
             #1234567890123456789012345

  $detail .= '01'; # ??? 147-148 2 NUM Multiple Clearing Sequence Number 4.129
  $detail .= '01'; # ???  149-150 2 NUM Multiple Clearing Sequence Count 1.128
  $detail .= '7'; # 151 1 A/N MOTO/Electronic Commerce Indicator 7 = Channel Encrypted 4.127

  die "detail length should be 151 (is ". length($detail). ")"
    unless length($detail) == 151;

  $message .= 
    $STX.
    $detail.
    $ETB.
    lrc($detail.$ETB)
  ;

# K-Format     Trailer Record
#Byte    Length    Frmt    Field Description    Content    Section

  my $trailer = 'K1.ZT@@@@';
#1    1    A/N    Record Format    K    4.154
#2    1    NUM    Application Type    1=Single 3=Multiple Batch    4.10
#3    1    A/N    Message Delimiter    .    4.123
#4    1    A/N    X.25 Routing ID    Z    4.226
#5-9    5    A/N    Record Type    T@@@@    4.155

  $trailer .= $mmdd;           # 10-13  4 NUM Batch Transmission Date MMDD 4.22
  $trailer .= $batchnum;       # 14-16  3 NUM Batch Number    001 - 999    4.18
  $trailer .= '000000004';        # 17-25  9 NUM Batch Record Count
                                  #Right-Justified/Zero-Filled    4.19
  $trailer .= '0000'.$amount;     # 26-41 16 NUM Batch Hashing Total
                                  #Purchases + Returns    4.16
  $trailer .= '0000000000000000'; # 42-57 16 NUM Cashback Total 4.38
  $trailer .= '0000'.$amount;     # 58-73 16 NUM Batch Net Deposit
                                  # Purchases - Returns    4.17

  die "trailer length should be 73!" unless length($trailer) == 73;

  $message .= 
    $STX.
    $trailer.
    $ETX.
    lrc($trailer.$ETX)
  ;

  ####

  $message = setEvenParity $message;

  $message;

}

sub eis1081_response {
  my( $self, $response ) = @_;
  my %response;

  $response =~ /^$STX(.{41})(.*)$ETX(.)$/
    or die "can't decode (eis1081) response: $response";
  my $remainder = $2;
  my $lrc = $3;

  (
    $response{record_format},
    $response{application_type},
    $response{message_delimiter},
    $response{x25_routing_id},
    $response{record_type},
    $response{batch_record_count},
    $response{batch_net_deposit},
    $response{batch_response_code},
    $response{filler},
    $response{batch_number},
  ) = unpack "AAAAA5A9A16A2A2A3", $1;
  warn "$1\n" if $DEBUG;

  if ( $response{record_format} ne "K" ) {
    die "unknown response record_format $response{record_format}";
  }
  if ( $response{application_type} ne "1" ) {
    die "unknown response record_format $response{application_type}";
  }
  if ( $response{message_delimiter} ne "." ) {
    die "unknown response record_format $response{message_delimiter}";
  }

  if ( $response{is_success} = $response{batch_response_code} eq 'GB' ) {
    $response{result_code} = $response{batch_response_code};
    $response{error_message} = '';
  } elsif ( $response{batch_response_code} eq 'RB' ) {
    $response{result_code} = $response{batch_response_code};
    #$remainder =~ /^(.)(.{4})(.)(..)(.{32})$/
    $remainder =~ /^(.)(.{4})(.)(..)(.*)$/
      or die "can't decode (eis1081) RB response (41+ ". length($remainder).
             "): $remainder";
    my( $error_type, $error_record_sequence_number, $error_record_type,
        $error_data_field_number, $error_data ) = ( $1, $2, $3, $4, $5 );
    my %error_type = (
      B => 'Blocked Terminal',
      C => 'Card Type Error',
      D => 'Device Error',
      E => 'Error in Batch',
      S => 'Sequence Error',
      T => 'Transmission Error',
      U => 'Unknown Error',
      V => 'Routing Error',
    );
    my %error_record_type = (
      H => 'Header Record',
      P => 'Parameter Record',
      D => 'Detail Record',
      T => 'Trailer Record',
    );
    $response{error_message} = 'Auth sucessful but capture rejected: '.
      $error_type{$error_type}. ' in '. $error_record_type{$error_record_type}.
      ' #'. $error_record_sequence_number. ' field #'. $error_data_field_number.
      ': '. $error_data;
  } else {
    $response{result_code} = $response{batch_response_code};
    $response{error_message} = $remainder;
  }

  %response;
}

1;

__END__

=head1 NAME

Business::OnlinePayment::VirtualNet - Vital VirtualNet backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("VirtualNet",
    'merchant_id' => '999999999911',
    'store'       => '0011',
    'terminal'    => '9911',
    'mcc'         => '5999', #merchant category code
    'bin'         => '999995', #acquirer BIN (Bank Identification Number)
    'zip'         => '543211420', #merchant zip (US) or assigned city code

    'agent'       => '000000', #agent bank
    'v'           => '00000001',

    'merchant_name'  => 'Internet Service Provider', #25 char max
    'merchant_city'  => 'Gloucester', #13 char max
    'merchant_state' => 'VA', #2 char

    'seq_file'      => '/tmp/bop-virtualnet-sequence',
    'batchnum_file' => '/tmp/bop-virtualnet-batchnum', # :/  0-999 in 5 days

  );
  $tx->content(
      type           => 'CC',
      login          => 'test',
      action         => 'Authorization Only',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      name           => 'Tofu Beast',
      card_number    => '4111111111111111',
      expiration     => '09/03',
  );
  $tx->submit();

  if( $tx->is_success() ) {
      print "Card authorized successfully: ".$tx->authorization."\n";
  } else {
      print "Error: ".$tx->error_message."\n";
  }

 if( $tx->is_success() ) {

      my $capture = new Business::OnlinePayment("VirtualNet",
        'agent'       => '000001',
        'chain'       => '000000', #optional?
        'v'           => '00000001',

        'merchant_id' => '999999999911',
        'store'       => '0011',
        'terminal'    => '9911',
        'mcc'         => '5999', #merchant category code
        'bin'         => '999995', #acquirer BIN (Bank Identification Number)
      );

      $capture->content(
        type           => 'CC',
        action         => 'Post Authorization',
        amount         => '49.95',
        card_number    => '4111111111111111',
        expiration     => '09/03',
        authorization             => $tx->authorization,
        authorization_source_code => $tx->authorization_source_code,
        returned_ACI              => $tx->returned_ACI,
        transaction_identifier    => $tx->transaction_identifier,
        validation_code           => $tx->validation_code,
        transaction_sequence_num  => $tx->transaction_sequence_num,
        local_transaction_date    => $tx->local_transaction_date,
        local_transaction_time    => $tx->local_transaction_time,
        AVS_result_code           => $tx->AVS_result_code,
        #description    => 'Business::OnlinePayment::VirtualNet test',

          action         => 'Post Authorization',
      #    order_number   => $ordernum,
      #    amount         => '0.01',
      #    authorization  => $auth,
      #    description    => 'Business::OnlinePayment::VirtualNet test',
      );

      $capture->submit();

      if( $capture->is_success() ) { 
          print "Card captured successfully\n";
      } else {
          print "Error: ".$capture->error_message."\n";
      }

  }

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

=head1 COMPATIBILITY

This module implements the interface documented at
http://www.vitalps.com/sections/int/int_Interfacespecs.html

Specifically, start with
http://www.vitalps.com/pdfs_specs/VirtualNet%020Specification%0200011.pdf
and then http://www.vitalps.com/pdfs_specs/EIS%0201080%020v6_4_1.pdf and
http://www.vitalps.com/pdfs_specs/EIS_1081_v_6_4.pdf and maybe even
http://www.vitalps.com/pdfs_specs/EIS%0201051.pdf and
http://www.vitalps.com/pdfs_specs/EIS%0201052.pdf

=head1 AUTHOR

Ivan Kohler <ivan-virtualnet@420.am>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

