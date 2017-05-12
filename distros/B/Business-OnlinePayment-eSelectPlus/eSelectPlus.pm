package Business::OnlinePayment::eSelectPlus;

use strict;
use Carp;
use Tie::IxHash;
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS 0.03;
use vars qw($VERSION $DEBUG @ISA);

@ISA = qw(Business::OnlinePayment::HTTPS);
$VERSION = '0.07';
$DEBUG = 0;

sub set_defaults {
    my $self = shift;

    #USD
    #$self->server('esplusqa.moneris.com');  # development
    $self->server('esplus.moneris.com');   # production
    $self->path('/gateway_us/servlet/MpgRequest');

    ##CAD
    ##$self->server('esqa.moneris.com');  # development
    #$self->server('www3.moneris.com');   # production
    #$self->path('/gateway2/servlet/MpgRequest');

    $self->port('443');

    $self->build_subs(qw( order_number avs_code ));
    # avs_code order_type md5 cvv2_response cavv_response
}

sub submit {
    my($self) = @_;

    if ( defined( $self->{_content}{'currency'} )
              &&  $self->{_content}{'currency'} eq 'CAD' ) {
      $self->server('www3.moneris.com');
      $self->path('/gateway2/servlet/MpgRequest');
    } else { #sorry, default to USD
      $self->server('esplus.moneris.com');
      $self->path('/gateway_us/servlet/MpgRequest');
    }

    if ($self->test_transaction)  {
       if ( defined( $self->{_content}{'currency'} )
                 &&  $self->{_content}{'currency'} eq 'CAD' ) {
         $self->server('esqa.moneris.com');
         $self->{_content}{'login'} = 'store2';   # store[123]
         $self->{_content}{'password'} = 'yesguy';
       } else { #sorry, default to USD
         $self->server('esplusqa.moneris.com');
         $self->{_content}{'login'} = 'monusqa002';   # monusqa00[123]
         $self->{_content}{'password'} = 'qatoken';
       }
    }

    my %cust_id = ( 'invoice_number' => 'cust_id' );

    my $invoice_number = $self->{_content}{invoice_number};

    # BOP field => eSelectPlus field
    #$self->map_fields();
    $self->remap_fields(
        #                => 'order_type',
        #                => 'transaction_type',
        #login            => 'store_id',
        #password         => 'api_token',
        #authorization   => 
        #customer_ip     =>
        #name            =>
        #first_name      =>
        #last_name       =>
        #company         =>
        #address         => 
        #city            => 
        #state           => 
        #zip             => 
        #country         =>
        phone            => 
        #fax             =>
        email            =>
        card_number      => 'pan',
        #expiration        =>
        #                => 'expdate',

        'amount'         => 'amount',
        customer_id      => 'cust_id',
        order_number     => 'order_id',   # must be unique number
        authorization    => 'txn_number'  # reference to previous trans

        #cvv2              =>
    );

    my $action = $self->{_content}{'action'};
    if ( $self->{_content}{'action'} =~ /^\s*normal\s*authorization\s*$/i ) {
      $action = 'purchase';
    } elsif ( $self->{_content}{'action'} =~ /^\s*authorization\s*only\s*$/i ) {
      $action = 'preauth';
    } elsif ( $self->{_content}{'action'} =~ /^\s*post\s*authorization\s*$/i ) {
      $action = 'completion';
    } elsif ( $self->{_content}{'action'} =~ /^\s*void\s*$/i ) {
      $action = 'purchasecorrection';
    } elsif ( $self->{_content}{'action'} =~ /^\s*credit\s*$/i ) {
      if ( $self->{_content}{'authorization'} ) {
        $action = 'refund';
      } else {
        $action = 'ind_refund';
      }
    }

    if ( $action =~ /^(purchase|preauth|ind_refund)$/ ) {

      $self->required_fields(qw(
        login password amount card_number expiration
      ));

      #cardexpiremonth & cardexpireyear
      $self->{_content}{'expiration'} =~ /^(\d+)\D+\d*(\d{2})$/
        or croak "unparsable expiration ". $self->{_content}{expiration};
      my( $month, $year ) = ( $1, $2 );
      $month = '0'. $month if $month =~ /^\d$/;
      $self->{_content}{expdate} = $year.$month;

      $self->generate_order_id;

      $self->{_content}{order_id} .= '-'. ($invoice_number || 0);

      $self->{_content}{amount} = sprintf('%.2f', $self->{_content}{amount} );

    } elsif ( $action =~ /^(completion|purchasecorrection|refund)$/ ) {

      $self->required_fields(qw(
        login password order_number authorization
      ));

      if ( $action eq 'completion' ) {
        $self->{_content}{comp_amount} = delete $self->{_content}{amount};
      } elsif ( $action eq 'purchasecorrection' ) {
        delete $self->{_content}{amount};
      #} elsif ( $action eq 'refund' ) {
      } 

    }

    # E-Commerce Indicator (see eSelectPlus docs)
    $self->{_content}{'crypt_type'} ||= 7;

    $action = "us_$action"
      unless defined( $self->{_content}{'currency'} )
                   && $self->{_content}{'currency'} eq 'CAD';

    #no, values aren't escaped for XML.  their "mpgClasses.pl" example doesn't
    #appear to do so, i dunno
    tie my %fields, 'Tie::IxHash', $self->get_fields( $self->fields );
    my $post_data =
      '<?xml version="1.0"?>'.
      '<request>'.
      '<store_id>'.  $self->{_content}{'login'}. '</store_id>'.
      '<api_token>'. $self->{_content}{'password'}. '</api_token>'.
      "<$action>".
      join('', map "<$_>$fields{$_}</$_>", keys %fields ).
      "</$action>".
      '</request>';

    warn "POSTING: ".$post_data if $DEBUG > 1;

    my( $page, $response, @reply_headers) = $self->https_post( $post_data );

    if ($DEBUG > 1) {
      my %reply_headers = @reply_headers;
      warn join('', map { "  $_ => $reply_headers{$_}\n" } keys %reply_headers)
    }

    if ($response !~ /^200/)  {
        # Connection error
        $response =~ s/[\r\n]+/ /g;  # ensure single line
        $self->is_success(0);
        my $diag_message = $response || "connection error";
        die $diag_message;
    }

    # avs_code - eSELECTplus_Perl_IG.pdf Appendix F
    my %avsTable = ('A' => 'A',
                    'B' => 'A',
                    'C' => 'E',
                    'D' => 'Y',
                    'G' => '',
                    'I' => '',
                    'M' => 'Y',
                    'N' => 'N',
                    'P' => 'Z',
                    'R' => 'R',
                    'S' => '',
                    'U' => 'E',
                    'W' => 'Z',
                    'X' => 'Y',
                    'Y' => 'Y',
                    'Z' => 'Z',
                    );
    my $AvsResultCode = $self->GetXMLProp($page, 'AvsResultCode');
    $self->avs_code( defined($AvsResultCode) && exists $avsTable{$AvsResultCode}
                         ?  $avsTable{$AvsResultCode}
                         :  $AvsResultCode
                   );

    #md5 cvv2_response cavv_response ...?

    $self->server_response($page);

    my $result = $self->GetXMLProp($page, 'ResponseCode');

    die "gateway error: ". $self->GetXMLProp( $page, 'Message' )
      if $result =~ /^null$/i;

    # Original order_id supplied to the gateway
    $self->order_number($self->GetXMLProp($page, 'ReceiptId'));

    # We (Whizman & DonorWare) do not have enough info about "ISO"
    # response codes to make use of them.
    # There may be good reasons why the ISO codes could be preferable,
    # but we would need more information.  For now, the ResponseCode.
    # $self->result_code( $self->GetXMLProp( $page, 'ISO' ) );
    $self->result_code( $result );

    if ( $result =~ /^\d+$/ && $result < 50 ) {
        $self->is_success(1);
        $self->authorization($self->GetXMLProp($page, 'TransID'));
    } elsif ( $result =~ /^\d+$/ ) {
        $self->is_success(0);
        my $tmp_msg = $self->GetXMLProp( $page, 'Message' );
        $tmp_msg =~ s/\s{2,}//g;
        $tmp_msg =~ s/[\*\=]//g;
        $self->error_message( $tmp_msg );
    } else {
        die "unparsable response received from gateway (response $result)".
            ( $DEBUG ? ": $page" : '' );
    }

}

use vars qw(@oidset);
@oidset = ( 'A'..'Z', '0'..'9' );
sub generate_order_id {
    my $self = shift;
    #generate an order_id if order_number not passed
    unless (    exists ($self->{_content}{order_id})
             && defined($self->{_content}{order_id})
             && length ($self->{_content}{order_id})
           ) {
      $self->{_content}{'order_id'} =
        join('', map { $oidset[int(rand(scalar(@oidset)))] } (1..23) );
    }
}

sub fields {
        my $self = shift;

        #order is important to this processor
        qw(
          order_id
          cust_id
          amount
          comp_amount
          txn_number
          pan
          expdate
          crypt_type
          cavv
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

Business::OnlinePayment::eSelectPlus - Moneris eSelect Plus backend module for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # One step transaction, the simple case.
  ####

  my $tx = new Business::OnlinePayment("eSelectPlus");
  $tx->content(
      type           => 'VISA',
      login          => 'eSelect Store ID,
      password       => 'eSelect API Token',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      currency       => 'USD', #or CAD for compatibility with previous releases
      name           => 'Tofu Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      phone          => '420-867-5309',
      email          => 'tofu.beast@example.com',
      card_number    => '4005550000000019',
      expiration     => '08/06',
      cvv2           => '1234', #optional
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }
  print "AVS code: ". $tx->avs_code. "\n"; # Y - Address and ZIP match
                                           # A - Address matches but not ZIP
                                           # Z - ZIP matches but not address
                                           # N - no match
                                           # E - AVS error or unsupported
                                           # R - Retry (timeout)
                                           # (empty) - not verified

=head1 SUPPORTED TRANSACTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

Content required: type, login, password, action, amount, card_number, expiration.

=head1 PREREQUISITES

  URI::Escape
  Tie::IxHash

  Net::SSLeay _or_ ( Crypt::SSLeay and LWP )

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTES

=head2 Note for Canadian merchants upgrading to 0.03

As of version 0.03, this module now defaults to the US Moneris.  Make sure to
pass currency=>'CAD' for Canadian transactions.

=head2 Note for upgrading to 0.05

As of version 0.05, the bank authorization code is discarded (AuthCode),
so that authorization() and order_number() can return the 2 fields needed
for capture.  See also
cpansearch.perl.org/src/IVAN/Business-OnlinePayment-3.02/notes_for_module_writers_v3

=head1 AUTHOR

Ivan Kohler <ivan-eselectplus@420.am>
Randall Whitman L<whizman.com|http://whizman.com>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

