package Business::OnlinePayment::Cardcom;

use strict;
use Carp;
use Tie::IxHash;
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS 0.03;
#use Data::Dumper;
use vars qw($VERSION $DEBUG @ISA);

@ISA = qw(Business::OnlinePayment::HTTPS);
$VERSION = '0.02';
$DEBUG = 0;

sub set_defaults {
    my $self = shift;

    $self->server('secure.cardcom.co.il'); 
    $self->path('/BillGoldPost.aspx');
    $self->port('443');
}

# XXX?
# -Identity number
# -Configurable currency
# -Configurable deal code
sub submit {
    my($self) = @_;

    #warn Dumper($self) if $DEBUG > 1;

    $self->remap_fields(
        card_number => 'cardnumber',
        amount      => 'Sum',
        login       => 'Username',
        password    => 'userpassword',
        cvv2        => 'cvv',
    );

    my $action = $self->{_content}{'action'};
    if ( $action =~ /^\s*credit\s*$/i ) {
        $self->{_content}{dealtype} = 51;
        $self->{_content}{credittype} = 1;
    } elsif ( $action !~ /^\s*normal\s*authorization\s*$/i ) {
        die "invalid action";
    }

    $self->{_content}{'expiration'} =~ /^(\d+)\D+\d*(\d{2})$/
        or croak "unparsable expiration ". $self->{_content}{expiration};
    my( $month, $year ) = ( $1, $2 );
    $month = '0'. $month if $month =~ /^\d$/;
    $self->{_content}{cardvalidityyear} = $year;
    $self->{_content}{cardvaliditymonth} = $month;

    $self->{_content}{amount} = sprintf('%.2f', $self->{_content}{amount} );
    $self->{_content}{languages} = 'en';
    
    $self->terminalnumber =~ /^\d+$/ or die "invalid TerminalNumber";
    $self->{_content}{TerminalNumber} = $self->terminalnumber;
    
    $self->required_fields(
        qw( login password TerminalNumber card_number amount )
    );
    
    if($self->test_transaction) {
        $self->{_content}{'Username'} = 'gali';
        $self->{_content}{'userpassword'} = '7654321';
        $self->{_content}{'TerminalNumber'} = '1000';
    }
      
    tie my %fields, 'Tie::IxHash', $self->get_fields( $self->fields );
    my $post_data =   join('&', map "$_=$fields{$_}", keys %fields );
    warn "POSTING: ".$post_data if $DEBUG > 1;

    my( $page, $response, @reply_headers) = $self->https_post( $post_data );

    if ($response !~ /^200/)  {
        # Connection error
        $response =~ s/[\r\n]+/ /g;  # ensure single line
        $self->is_success(0);
        my $diag_message = $response || "connection error";
        die $diag_message;
    }
    
    $self->server_response($page);

    unless ( $page =~ /^(\d+);(\d+);(.*?)$/ ) {
       die "unparsable response received from gateway" . 
            ( $DEBUG ? ": $page" : '' ); 
    }

    my $result = $1;
    my $authorization = $2;
    my $message = $3;

    $self->result_code($result);
    if ( $result == 0 ) {
        $self->is_success(1);
        $self->authorization($authorization);
    } else {
        $self->is_success(0);
        $self->error_message($message);
    }
}

sub fields {
        my $self = shift;

        qw(
          TerminalNumber
          Sum
          cardnumber
          cardvalidityyear
          cardvaliditymonth
          Username
          userpassword
          languages
          dealtype
          credittype
          cvv
        );
}

sub _info {
   {
    'info_compat'       => '0.01',
    'gateway_name'      => 'Cardcom',
    'gateway_url'       => 'http://www.cardcom.co.il',
    'module_version'    => $VERSION,
    'supported_types'   => [ 'CC' ],
    'token_support'     => 0, # well technically the gateway supports it, but we haven't implemented it
    'test_transaction'  => 1, 
    'supported_actions' => [ 
                            'Normal Authorization',
                            'Credit', 
                           ], 
   };
}

1;

__END__

=head1 NAME

Business::OnlinePayment::Cardcom - Cardcom backend module for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment::Cardcom;

  ####
  # One step transaction, the simple case.
  ####

  my $tx = new Business::OnlinePayment("Cardcom", 'TerminalNumber'=>1234 );
  $tx->content(
      type           => 'CC',
      login          => 'Cardcom Username',
      password       => 'Cardcom Password',
      action         => 'Normal Authorization',
      amount         => '49.95',
      card_number    => '4005550000000019',
      expiration     => '08/06',
      cvv2           => '123',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSACTION TYPES

=head2 CC

Content required: type, login, password, action, amount, card_number, expiration.

=head1 PREREQUISITES

  Tie::IxHash

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 AUTHOR

Original Author: Erik Levinson

Current Maintainer: Ivan Kohler C<< <ivan-cardcom@freeside.biz> >>

perl(1). L<Business::OnlinePayment>.

=head1 ADVERTISEMENT

Need a complete, open-source back-office and customer self-service solution?
The Freeside software includes support for credit card and electronic check
processing, integrated trouble ticketing, and customer signup and self-service
web interfaces.

http://freeside.biz/freeside/


=cut
