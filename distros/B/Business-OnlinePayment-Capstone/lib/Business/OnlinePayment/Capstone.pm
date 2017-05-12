package Business::OnlinePayment::Capstone;

use strict;
use Carp;
#use Tie::IxHash;
use URI::Escape;
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS 0.03;
use vars qw($VERSION $DEBUG @ISA);

@ISA = qw(Business::OnlinePayment::HTTPS);
$VERSION = '0.02';
$DEBUG = 0;

sub set_defaults {
    my $self = shift;

    $self->server('www.capstonepay.com');
    $self->port('443');
    $self->path('/cgi-bin/client/transaction.cgi');

    $self->build_subs(qw( order_number avs_code cvv2_response ));
}

sub submit {
    my($self) = @_;

    my $action = $self->{_content}{'action'};
    if ( $self->{_content}{'action'} =~ /^\s*normal\s*authorization\s*$/i ) {
      $action = 'authpostauth';
    } elsif ( $self->{_content}{'action'} =~ /^\s*authorization\s*only\s*$/i ) {
      $action = 'auth';
    } elsif ( $self->{_content}{'action'} =~ /^\s*post\s*authorization\s*$/i ) {
      $action = 'postauth';
    } elsif ( $self->{_content}{'action'} =~ /^\s*void\s*$/i ) {
      $action = 'void';
    } elsif ( $self->{_content}{'action'} =~ /^\s*credit\s*$/i ) {
      $action = 'return';
    }

   #$self->map_fields();
    $self->revmap_fields(
        merchantid          =>'login',
        account_password    => 'password',
        action              => \$action,
        amount              => 'amount',
        name                => 'name',
        address1            => 'address',
        #address2
        city                => 'city',
        state               => 'state',
        postal              => 'zip',
        country             => 'country',
        currency            => \'USD', #XXX fix me
        email               => 'email',
        ipaddress           => 'customer_ip',
        card_num            => 'card_number',
        #card_exp            => 'expiration', #strip /
        card_cvv            => 'cvv2',
        #start_date          => 'card_start', #strip /
        issue_num           => 'issue_number',
        #bank_name   #XXX fix to support ACH
        #bank_phone  #XXX fix to support ACH
        orderid             => 'order_number',
        custom0             => 'description',
      );

        #                => 'order_type',
        #                => 'transaction_type',

        #authorization   => 

        #company         =>
        #phone            => 
        #fax             =>

        #invoice_number  =>
        #customer_id     =>
        #authorization    => 'txn_number'

    if ( $action =~ /^auth(postauth)?$/ ) {

      $self->required_fields(qw(
                                 login password action amount
                                 name address city state zip
                                 email
                                 card_number expiration 
                            ));

      $self->{_content}{'expiration'} =~ /^(\d+)\D+\d*(\d{2})$/
        or croak "unparsable expiration: ". $self->{_content}{expiration};
      my( $month, $year ) = ( $1, $2 );
      $month = '0'. $month if $month =~ /^\d$/;
      $self->{_content}{card_exp} = $month.$year;

      if ( $self->{_content}{'card_start'} ) {
        $self->{_content}{'card_start'} =~ /^(\d+)\D+\d*(\d{2})$/
          or croak "unparsable card_start ". $self->{_content}{card_start};
        my( $month, $year ) = ( $1, $2 );
        $month = '0'. $month if $month =~ /^\d$/;
        $self->{_content}{start_date} = $month.$year;
      }

#      $self->{_content}{amount} = sprintf('%.2f', $self->{_content}{amount} );

    } elsif ( $action =~ /^(postauth|void|return)$/ ) {

      $self->required_fields(qw(
                                 login password action order_number
                            ));

    } else {
      die "unknown action $action";
    }

    $self->{'_content'}{country} ||= 'US';

    #tie my %post_data, 'Tie::IxHash', $self->get_fields(qw(
    my %post_data = $self->get_fields(qw(
      merchantid
      account_password
      action
      amount
      name
      address1
      city
      state
      postal
      country
      currency
      email
      ipaddress
      card_num
      card_exp
      card_cvv
      state_date
      issue_num
      bank_name
      bank_phone
      orderid
      custom0
    ));

    warn join("\n", map { "$_: ". $post_data{$_} } keys %post_data )
      if $DEBUG;

    #my( $page, $response, @reply_headers) = $self->https_post( \%post_data );
    my( $page, $response, @reply_headers) = $self->https_post( %post_data );

    #my %reply_headers = @reply_headers;
    #warn join('', map { "  $_ => $reply_headers{$_}\n" } keys %reply_headers )
    #  if $DEBUG;

    #XXX check $response and die if not 200?

    $self->server_response($page);

    #warn "****** $page *******";

    $page =~ s/^\n+//;

    my %result = map { 
                       /^(\w+)=(.*)$/ or die "can't parse response: $_";
                       ($1, uri_unescape($2));
                     }
                 split(/\&/, $page);

    $self->result_code(   $result{'status_code'} );
    $self->avs_code(      $result{'avs_resp'} );
    $self->cvv2_response( $result{'cvv_resp'} );

    if ( $result{'status'} eq 'good' ) {
      $self->is_success(1);
      $self->authorization( $result{'auth_code'}   );
      $self->order_number(  $result{'orderid'}     );
    } elsif ( $result{'status'} =~ /^(bad|error|fraud)$/ ) {
      $self->is_success(0);
      $self->error_message("$1: ". $result{'status_msg'});
    } else {
      die "unparsable response received from gateway".
          ( $DEBUG ? ": $page" : '' );
    }

}

sub revmap_fields {
    my($self, %map) = @_;
    my %content = $self->content();
    foreach(keys %map) {
#    warn "$_ = ". ( ref($map{$_})
#                         ? ${ $map{$_} }
#                         : $content{$map{$_}} ). "\n";
        $content{$_} = ref($map{$_})
                         ? ${ $map{$_} }
                         : $content{$map{$_}};
    }
    $self->content(%content);
}

1;

__END__

=head1 NAME

Business::OnlinePayment::Capstone - CapstonePay backend module for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # One step transaction, the simple case.
  ####

  my $tx = new Business::OnlinePayment("Capstone");
  $tx->content(
      type           => 'VISA',
      login          => 'Merchant ID',
      password       => 'API password',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      name           => 'Tofu Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      phone          => '420-867-5309',
      email          => 'tofu.beast@example.com',
      card_number    => '4005550000000019',
      expiration     => '08/06',
      card_start     => '05/04', #switch/solo 
      issue_number   => '5678',  #
      cvv2           => '1234', #optional
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSACTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

Content required: type, login, password, action, amount, card_number, expiration.

=head1 PREREQUISITES

  URI::Escape
  #Tie::IxHash

  Net::SSLeay _or_ ( Crypt::SSLeay and LWP )

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

=head1 AUTHOR

Ivan Kohler <ivan-capstone@420.am>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

