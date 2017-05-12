package Business::OnlinePayment::OCV;

use strict;
use Carp;
use Business::OnlinePayment;
#use Business::CreditCard;
#use Net::SSLeay qw( make_form post_https );
use Business::OCV; #qw( :transaction );
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.01';

#Business::OCV exporting is broken
use subs qw(TRANS_APPROVED);
sub TRANS_APPROVED   (){ '0' }  # transaction status result - approved

$DEBUG = 0;


sub set_defaults {
    my $self = shift;
#    $self->server('sec.aba.net.au');
#    $self->port('443');
#    $self->path('/cgi-bin/service/authint');
    $self->build_subs(qw( account ));
}

sub submit {
    my $self = shift;
    my %content = $self->content;

    my $action = lc($content{'action'});
    if ( $action eq 'normal authorization' ) {
    } else {
      croak "$action not (yet) supported";
    }

    $content{'expiration'} =~ /^(\d+)\D+\d{0,2}(\d{2})$/
      or croak "unparsable expiration $content{expiration}";
    my ($month, $year) = ( $1, $2 );
    $month += 0;
    $month = "0$month" if $month < 10;
    my $exp = "$month$year";

    my $ocv = new OCV (
        Server      => $self->server. ':'. $self->port,
        ClientID    => $content{login},
        AccountNum  => $self->account,
    ) or die "can't create Business::OCV object: $@!";

    my $m = $ocv->purchase(
      'CardData'   => $content{card_number},
      'CardExpiry' => $exp,
      'Amount'     => $content{'amount'} * 100,
    );
    croak $@ unless $m;

    warn "Result: ". $m->Result, "\n";

    if ( $m->Result == TRANS_APPROVED ) {
      $self->is_success(1);
      $self->result_code($m->Result);
      $self->authorization($m->PreAuth); #?
    } else {
      $self->is_success(0);
      $self->result_code($m->Result);
      $self->error_message($m->ResponseText);
    }

}

1;
__END__

=head1 NAME

Business::OnlinePayment::OCV - OCV backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("OCV");
  $tx->content(
      type           => 'CC',
      login          => 'test', #ClientID
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

This module is a wrapper around Business::OCV written by Benjamin
Low <b.d.low@unsw.edu.au>.  Eventually it will be self-contained.
See <INSERTURLHERE> for details.

=head1 AUTHOR

Ivan Kohler <ivan-ocv@420.am>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>, L<Business::OCV>.

=cut

