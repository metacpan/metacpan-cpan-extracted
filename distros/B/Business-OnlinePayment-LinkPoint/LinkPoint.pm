package Business::OnlinePayment::LinkPoint;

use strict;
use vars qw($VERSION @ISA $DEBUG @EXPORT @EXPORT_OK);
use Carp qw(croak);
use Business::OnlinePayment;

@ISA = qw(Business::OnlinePayment);
$VERSION = '0.10';
$VERSION = eval $VERSION; # modperlstyle: convert the string into a number
$DEBUG = 0;

use lpperl; #3;  #lpperl.pm from LinkPoint
$LPPERL::VERSION =~ /^(\d+\.\d+)/
  or die "can't parse lpperl.pm version: $LPPERL::VERSION";
die "lpperl.pm minimum version 3 required\n" unless $1 >= 3;

sub set_defaults {
    my $self = shift;

    #$self->server('staging.linkpt.net');
    $self->server('secure.linkpt.net');
    $self->port('1129');

    $self->build_subs(qw(order_number avs_code));

}

sub map_fields {
    my($self) = @_;

    my %content = $self->content();

    #ACTION MAP
    my %actions = ('normal authorization' => 'SALE',
                   'authorization only'   => 'PREAUTH',
                   'credit'               => 'CREDIT',
                   'post authorization'   => 'POSTAUTH',
                   'void'                 => 'VOID',
                  );
    $content{'action'} = $actions{lc($content{'action'})} || $content{'action'};

    #ACCOUNT TYPE MAP
    my %account_types = ('personal checking' => 'pc',
                         'personal savings'  => 'ps',
                         'business checking' => 'bc',
                         'business savings'  => 'bs',
                        );
    $content{'account_type'} = $account_types{lc($content{'account_type'})}
                               || $content{'account_type'};

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

    my($month, $year);
    unless ( $content{action} eq 'POSTAUTH'
             || ( $content{'action'} =~ /^(CREDIT|VOID)$/
                  && exists $content{'order_number'} )
             || $self->transaction_type() =~ /^e?check$/i
           ) {

        if (  $self->transaction_type() =~
                /^(cc|visa|mastercard|american express|discover)$/i
           ) {
        } else {
            Carp::croak("LinkPoint can't handle transaction type: ".
                        $self->transaction_type());
        }

      $content{'expiration'} =~ /^(\d+)\D+\d*(\d{2})$/
        or croak "unparsable expiration $content{expiration}";

      ( $month, $year ) = ( $1, $2 );
      $month = '0'. $month if $month =~ /^\d$/;
    }

    $content{'address'} =~ /^(\d+)\s/;
    my $addrnum = $1;

    my $result = $content{'result'};
    if ( $self->test_transaction) {
      $result ||= 'GOOD';
      #$self->server('staging.linkpt.net');
    } else {
      $result ||= 'LIVE';
    }

    #strip phone numbers of non-digits for ACH/echeck
    #as per undocumented suggestion from LinkPoint
    if ( $self->transaction_type =~ /^e?check$/i ) {
      foreach my $field (qw( phone fax )) {
        $content{$field} =~ s/\D//g;
      }
    }
    # stuff it back into %content
    $self->content(%content);

    $self->revmap_fields(
      host         => \( $self->server ),
      port         => \( $self->port ),
      #storename    => \( $self->storename ),
      configfile   => \( $self->storename ),
      keyfile      => \( $self->keyfile ),

      chargetotal  => 'amount',
      result       => \$result,
      addrnum      => \$addrnum,
      oid          => 'order_number',
      ip           => 'customer_ip',
      userid       => 'customer_id',
      ponumber     => 'invoice_number',
      comments     => 'description',
      #reference_number => 'reference_number',

      cardnumber   => 'card_number',
      cardexpmonth => \$month,
      cardexpyear  => \$year,

      bankname     => 'bank_name',
      bankstate    => 'bank_state',
      routing      => 'routing_code',
      account      => 'account_number',
      accounttype  => 'account_type',
      name         => 'account_name',
      dl           => 'state_id',
      dlstate      => 'state_id_state',
    );

    my $lperl = new LPPERL;

    my @required_fields = qw(host port configfile keyfile amount);
    if ($self->transaction_type() =~ /^(cc|visa|mastercard|american express|discover)$/i) {
      push @required_fields, qw(cardnumber cardexpmonth cardexpyear);
    }elsif ($self->transaction_type() =~ /^e?check$/i) {
      push @required_fields, qw(
        dl dlstate routing account accounttype bankname bankstate name
                               );
    }
    $self->required_fields(@required_fields);

    my %post_data = $self->get_fields(qw/
      host port configfile keyfile
      result
      chargetotal cardnumber cardexpmonth cardexpyear
      name company email phone fax addrnum city state zip country
      oid
      dl dlstate routing account accounttype bankname bankstate name void

    /);

    $post_data{'ordertype'} = $content{action};

    #docs disagree with lpperl.pm here
    $post_data{'voidcheck'} = 1       
      if $self->transaction_type() =~ /^e?check$/i
          && $post_data{'ordertype'} =~ /^VOID$/;

    if ( $content{'cvv2'} ) { 
      $post_data{cvmindicator} = 'provided';
      $post_data{cvmvalue} = $content{'cvv2'};
    }

    if ( $DEBUG ) {
      warn "$_ => $post_data{$_}\n" foreach keys %post_data;
      $post_data{debug} = 'true';
    }

    $post_data{'cargs'} = '-k -m 300 -s -S' if $self->test_transaction;

    # avoid some uninitialized warnings in lpperl.pm
    foreach (qw(webspace debug debugging)) { $post_data{$_} ||= '' }

    #my %response;
    #{
    #  local($^W)=0;
    #  %response = $lperl->$action(\%post_data);
    #}
    my %response = $lperl->curl_process(\%post_data);

    if ( $DEBUG ) {
      warn "$_ => $response{$_}\n" for keys %response;
    }

    if ( $response{'r_approved'} eq 'APPROVED'
         or ( $self->transaction_type() =~ /^e?check$/i
              && $response{'r_approved'} eq 'SUBMITTED'
            )
       )
    {
      $self->is_success(1);
      $self->result_code($response{'r_code'});
      $self->authorization($response{'r_ref'});
      $self->order_number($response{'r_ordernum'});
      $self->avs_code($response{'r_avs'});
    } else {
      $self->is_success(0);
      $self->result_code('');
      if ( $response{'r_error'} =~ /\S/ ) {
        $self->error_message($response{'r_error'});
      } else {
        $self->error_message($response{'r_approved'}); # no r_error for checks
      }
    }

}

1;
__END__

=head1 NAME

Business::OnlinePayment::LinkPoint - LinkPoint (Cardservice) backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment( 'LinkPoint',
    'storename' => 'your_store_number',
    'keyfile'   => '/path/to/keyfile.pem',
  );

  $tx->content(
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
      email          => 'ivan-linkpoint@420.am',
      card_number    => '4007000000027',
      expiration     => '09/99',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSACTION TYPES

=head2 Visa, MasterCard, American Express, JCB, Discover/Novus, Carte blanche/Diners Club

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 COMPATIBILITY

This module implements an interface to the LinkPoint Perl Wrapper "lpperl",
which you need to download and install separately.
http://www.linkpoint.com/product_solutions/internet/lperl/lperl_main.html
http://www.linkpoint.com/viewcart/down_index.htm

Versions 0.4 and on of this module support the LinkPoint Perl Wrapper version
3.5.

=head1 BUGS

=head1 AUTHOR

Ivan Kohler <ivan-linkpoint@420.am>

Contributions from Mark D. Anderson <mda@discerning.com>

Echeck work by Jeff Finucane <jeff@cmh.net>

Based on Busienss::OnlinePayment::AuthorizeNet written by Jason Kohles.

=head1 SEE ALSO

perl(1), L<Business::OnlinePayment>.

=cut

