package Business::OnlinePayment::eSec;

use strict;
use Carp;
use Business::OnlinePayment;
use Business::CreditCard;
use Net::SSLeay qw( make_form post_https );
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.02';

$DEBUG = 0;

sub set_defaults {
    my $self = shift;
    $self->server('sec.aba.net.au');
    $self->port('443');
    $self->path('/cgi-bin/service/authint');
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
    die 'eSec only supports "Authorization Only" transactions'
      unless $action eq 'authorization only';

    my %typemap = (
      "VISA card"                  => 'visa',
      "MasterCard"                 => 'mastercard',
      "Discover card"              => 'discover', #not supported...
      "American Express card"      => 'amex',
      "Diner's Club/Carte Blanche" => 'dinersclub',
      "enRoute"                    => 'enroute', #not supported...
      "JCB"                        => 'jcb',
      "BankCard"                   => 'bankcard',
    );
    my $cardtype = $self->test_transaction
                     ? 'testcard'
                     : $typemap{cardtype($content{'card_number'})};

    $content{'expiration'} =~ /^(\d+)\D+(\d+)$/
      or croak "unparsable expiration $content{expiration}";
    my ($month, $year) = ( $1, $2 );
    $month += 0;
    $year += 2000 if $year < 2000; #not y4k safe, oh shit

    $self->revmap_fields(
      EPS_MERCHANT    => 'login',
      EPS_REFERENCEID => 'invoice_number',
      EPS_CARDNUMBER  => 'card_number',
      EPS_CARDTYPE    => \$cardtype,
      EPS_EXPIRYMONTH => \$month,
      EPS_EXPIRYYEAR  => \$year,
      EPS_NAMEONCARD  => 'name',
      EPS_AMOUNT      => 'amount',
      EPS_CCV         => \'',
      EPS_VERSION     => \'2',
      EPS_TEST        => \( $self->test_transaction() ? 'true' : 'false' ),
    );
    %content = $self->content;
    if ( $DEBUG ) {
      warn "content:$_ => $content{$_}\n" foreach keys %content;
    }

    if ($self->transaction_type() eq 'CC' ) {
      $self->required_fields(qw/type action amount card_number expiration/);
    } else {
      croak("eSec can't handle transaction type: ".
            $self->transaction_type());
    }

    my %post_data = $self->get_fields( map "EPS_$_", qw(
      MERCHANT REFERENCEID CARDNUMBER CARDTYPE EXPIRYMONTH EXPIRYYEAR
      NAMEONCARD AMOUNT CCV VERSION TEST
    ) );
    if ( $DEBUG ) {
      warn "post_data:$_ => $post_data{$_}\n" foreach keys %post_data;
    }

    my $pd = make_form(%post_data);
    my $server = $self->server();
    my $port = $self->port();
    my $path = $self->path();
    my($page,$server_response,%headers) =
      post_https($server,$port,$path,'',$pd);

    my( $r, $a, $m, $s, $e ) =
      map { /^\s*\w+\s*\=\s*(.*)$/; $1; } split("\n", $page);

    if ( $m =~ /^200/ ) {
      $self->is_success(1);
      $self->result_code($e);
      $self->authorization($a);
    } else {
      $self->is_success(0);
      $self->result_code($e);
      $self->error_message($m);
    }

}

1;
__END__

=head1 NAME

Business::OnlinePayment::eSec - eSec backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("eSec");
  $tx->content(
      type           => 'CC',
      login          => 'test', #EPS_MERCHANT
      action         => 'Authorization Only',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      name           => 'Tofu Beast',
      card_number    => '4007000000027',
      expiration     => '09/02',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

=head1 COMPATIBILITY

This module implements eSec's API verison 2.  See
http://www.esec.com.au/sep/content/eps_support/integrate/integrate_use.html
for details.

=head1 AUTHOR

Ivan Kohler <ivan-esec@420.am>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

