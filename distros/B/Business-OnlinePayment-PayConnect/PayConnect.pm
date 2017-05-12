package Business::OnlinePayment::PayConnect;

use strict;
use Carp;
use Business::OnlinePayment;
#use Business::CreditCard;
use Net::SSLeay qw( make_form post_https get_https make_headers );
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.02';

$DEBUG = 0;

sub set_defaults {
    my $self = shift;

    #test
    $self->server('zavijah.e-ebi.net');
    $self->port('443');
    $self->path('/rtv/servlet/aio');

    $self->build_subs(qw( partner ));
}

sub revmap_fields {
    my($self, %map) = @_;
    my %content = $self->content();
    foreach(keys %map) {
        $content{$_} = ref($map{$_})
                         ? ${ $map{$_} }
                         : $content{$map{$_}};
    }
    $self->content(%content);
}

sub submit {
    my $self = shift;
    my %content = $self->content();

    my $action = lc($content{'action'});
    if ( $action eq 'authorization only' ) {
    } else {
      croak "$action not (yet) supported";
    }
    
    my $type = lc($content{'type'});
    if ( $type eq 'lec' ) {
    } else {
      croak "$type not (yet) supported";
    }

    $content{'zip'} =~ s/\D//g;
    $content{'zip'} =~ /^(\d{5})(\d*)$/;
    my($zip, $zip4) = ($1, $2);

    my $phone = $content{'phone'};
    $phone =~ s/\D//g;

    $self->revmap_fields(
      ebiinfo   => \'AIO-1.0',
      clientid  => 'login',
      password  => 'password',
      partner   => \($self->partner()),
      #sysid
      transtype => \'A', #action
      paytype   => \'lec', #type
      trackid   => 'invoice_number',
      acctid    => 'customer_id',
      billname  => 'name',
      billaddr1 => 'address',
      #billaddr2 =>
      billcity  => 'city',
      billstate => 'state',
      billzip   => \$zip,
      billzip4  => \$zip4,
      amt       => 'amount',

      #LEC
      #ani
      btn       => \$phone,
      #dni
      #traffic
      #planid
      #pincode
    );

    my %post_data = $self->get_fields(qw(
        ebiinfo clientid password partner transtype paytype trackid acctid
        billname billaddr1 billcity billstate billzip billzip4 amt btn
    ));

    my $s = $self->server();
    my $p = $self->port();
    my $t = $self->path();

    my $pd = make_form(%post_data);
    my($page,$server_response,%headers) = post_https($s,$p,$t,'',$pd);

    $page =~ s/\r*\n*$//;

    #warn join('-',%headers);
    #warn $page;
    my %response = map { split('=',$_,2) } split(/\|/,$page);
    #warn "$_: $response{$_}\n" foreach keys %response;

    if ( $response{'response'} eq '0000' ) {
      $self->is_success(1);
      $self->result_code('0000');
      $self->authorization($response{'trackid'});
    } else {
      $self->is_success(0);
      $self->result_code($response{'response'});
      $self->error_message($response{'respmsg'});
    }

}

1;
__END__

=head1 NAME

Business::OnlinePayment::PayConnect - PaymentOne (formerly eBillit) PayConnect  backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("PayConnect",
    'partner' => '',
  );
  $tx->content(
      type           => 'LEC',
      login          => 'test', #ClientID
      password       => 'test',
      action         => 'Authorization Only',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      name           => 'Tofu Beast',
      phone          => '4155554321',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "LEC billing authorized successfully: ".$tx->authorization."\n";
  } else {
      print "LEC billing was rejected: ".$tx->error_message."\n";
  }

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

This module only implements 'LEC' (phone bill billing) functionality at this
time.  Credit card and ACH transactions are not (yet) supported.

=head1 COMPATIBILITY

This module implements an interface the "HTTPS AIO Validation Protocol
version 3.0" of PaymentOne (formerly eBillit) PayConnect
<http://www.paymentone.com/products/paycon.asp>.  Unfortunately, no
documentation is publicly available.

=head1 AUTHOR

Ivan Kohler <ivan-payconnect@420.am>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>

=cut

