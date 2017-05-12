package Business::OnlinePayment::StGeorge;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp qw(croak);
use Business::OnlinePayment;

@ISA = qw(Business::OnlinePayment);
$VERSION = '0.02';

use webpayperl; #webpayperl.pm from St.George
webpayperl::init_client or croak "St.George initialization failed\n";

sub set_defaults {
    my $self = shift;

    $self->server('www.gwipg.stgeorge.com.au');
    $self->port('3006');

    $self->build_subs(qw(order_number));

}

sub map_fields {
    my($self) = @_;

    my %content = $self->content();

    #ACTION MAP
    my %actions = ('normal authorization' => 'PURCHASE',
                   'authorization only'   => 'PREAUTH',
                   'credit'               => 'REFUND',
                   'post authorization'   => 'COMPLETION',
                  );
    $content{'action'} = $actions{lc($content{'action'})} || $content{'action'};

    # TYPE MAP
    my %types = ('cc'                 => 'CREDITCARD',
                 'visa'               => 'CREDITCARD',
                 'mastercard'         => 'CREDITCARD',
                 'american express'   => 'CREDITCARD',
                 'discover'           => 'CREDITCARD',
                );
    $content{'type'} = $types{lc($content{'type'})} || $content{'type'};
    $self->transaction_type($content{'type'});

    # stuff it back into %content
    $self->content(%content);
}

sub build_subs {
    my $self = shift;
    foreach(@_) {
        #no warnings; #not 5.005
        local($^W)=0;
        eval "sub $_ { my \$self = shift; if(\@_) { \$self->{$_} = shift; } return \$self->{$_}; }";
    }
}

sub remap_fields {
    my($self,%map) = @_;

    my %content = $self->content();
    foreach(keys %map) {
        $content{$map{$_}} = $content{$_};
    }
    $self->content(%content);
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

sub get_fields {
    my($self,@fields) = @_;

    my %content = $self->content();
    my %new = ();
    foreach( grep defined $content{$_}, @fields) { $new{$_} = $content{$_}; }
    return %new;
}

sub submit {
    my($self) = @_;

    $self->map_fields();

    my %content = $self->content;

    my $exp = '';
    unless ( $content{action} eq 'STATUS' ) {

      $content{'expiration'} =~ /^(\d+)\D+\d*(\d{2})$/
        or croak "unparsable expiration $content{expiration}";

      my( $month, $year ) = ( $1, $2 );
      $month = '0'. $month if $month =~ /^\d$/;
      $exp = "$month$year";

    }

    if ( $self->test_transaction) {
      $self->port(3007);
    }

    my $terminal_type = 0;
    $terminal_type = 4 if $content{'recurring_billing'};

    $self->revmap_fields(
      INTERFACE           => 'type',
      TRANSACTIONTYPE     => 'action',
      TOTALAMOUNT         => 'amount',
      #TAXAMOUNT
      CARDDATA            => 'card_number',
      CARDEXPIRYDATE      => \$exp,
      #TXNREFERENCE
      #ORIGINALTXNREF
      #AUTHORISATIONNUMBER
      CLIENTREF           => 'customer_id',
      COMMENT             => 'invoice_number',
      TERMINALTYPE        => \$terminal_type,
      CVC2                => 'cvv2',
    );

    my $action = $content{action};

    if ( $action eq 'PURCHASE' || $action eq 'PREAUTH' ) {
      $self->required_fields(qw/
        login password
        INTERFACE TRANSACTIONTYPE TOTALAMOUNT CARDDATA CARDEXPIRYDATE
      /);
    } elsif ( $action eq 'REFUND' ) {
      $self->required_fields(qw/
        login password
        INTERFACE TRANSACTIONTYPE TOTALAMOUNT CARDDATA CARDEXPIRYDATE
        ORIGINALTXNREF
      /);
    } elsif ( $action eq 'COMPLETION' ) {
      $self->required_fields(qw/
        login password
        INTERFACE TRANSACTIONTYPE TOTALAMOUNT CARDDATA CARDEXPIRYDATE
        AUTHORISATIONNUMBER
      /);
    } elsif ( $action eq 'STATUS' ) {
      $self->required_fields(qw/
        login password
        TXNREFERENCE
      /);
    }

    my %post = $self->get_fields(qw/
      login password
      INTERFACE TRANSACTIONTYPE TOTALAMOUNT CARDDATA CARDEXPIRYDATE
    /);

    # if ( $DEBUG ) { warn "$_ => $post{$_}\n" foreach keys %post; }

    my $webpayRef = webpayperl::newBundle;
    webpayperl::addVersionInfo($webpayRef);
    webpayperl::put($webpayRef, "DEBUG", "OFF");
    #webpayperl::put($webpayRef, "LOGFILE", "webpay.log");
    webpayperl::put_ClientID           ( $webpayRef, delete $post{'login'}    );
    webpayperl::put_CertificatePath    ( $webpayRef, $self->cert_path         );
    webpayperl::put_CertificatePassword( $webpayRef, delete $post{'password'} );
    webpayperl::setPort                ( $webpayRef, $self->port              );
    webpayperl::setServers             ( $webpayRef, $self->server            );

    foreach my $key ( keys %post ) {
      warn "$key undefined" unless defined($post{$key});
      webpayperl::put($webpayRef, $key, $post{$key} );
    }

    my $tranProcessed = webpayperl::execute( $webpayRef );
    unless ( $tranProcessed ) {
      #St.George error handling is bunk
      $self->is_success(0);
      $self->error_message( webpayperl::get( $webpayRef, "ERROR").
                            ' (transaction reference: '.
                            webpayperl::get( $webpayRef, 'TXNREFERENCE' ).
                            ')'
                          );

      webpayperl::cleanup( $webpayRef );
      return;
    }

    my $responseCode = webpayperl::get( $webpayRef, "RESPONSECODE"); 
    $self->result_code($responseCode);

    if ( grep { $responseCode eq $_ } qw( 00 08 77 ) ) {
      $self->is_success(1);
      $self->authorization(webpayperl::get( $webpayRef, "AUTHCODE"));
      $self->order_number(webpayperl::get( $webpayRef, "TXNREFERENCE"));
    } else {
      $self->is_success(0);
      $self->error_message( webpayperl::get( $webpayRef, "RESPONSETEXT"). ' - '.
                            webpayperl::get( $webpayRef, "ERROR").
                            ' (transaction reference: '.
                            webpayperl::get( $webpayRef, 'TXNREFERENCE' ).
                            ')'
                          );
    }
 
    webpayperl::cleanup( $webpayRef );

}

END {
    webpayperl::free_client();
}

1;
__END__

=head1 NAME

Business::OnlinePayment::StGeorge - St.George Bank backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment( 'StGeorge',
    'cert_path'     => '/home/StGeorge/client.cert',
  );

  $tx->content(
      login          => '10000000', #The Client ID issued to you
      password       => 'w0rd', #The password protecting your certificate file
      type           => 'VISA',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jsk',
      name           => 'Jason Kohles',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      email          => 'ivan-stgeorge@420.am',
      card_number    => '4007000000027',
      expiration     => '09/99',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSCTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 COMPATIBILITY

This module implements an interface to the St. George Bank Internet Payment
Gateway Perl API.

https://www.ipg.stgeorge.com.au/

This module has been developed against webpayPerl version 2.8

=head1 BUGS

=head1 AUTHOR

Ivan Kohler <ivan-stgeorge@420.am>

Based on Busienss::OnlinePayment::AuthorizeNet written by Jason Kohles.

=head1 SEE ALSO

perl(1), L<Business::OnlinePayment>.

=cut

