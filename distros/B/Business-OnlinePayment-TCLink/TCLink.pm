package Business::OnlinePayment::TCLink;

use strict;
use Net::TCLink;
use Business::OnlinePayment;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '1.03';

sub set_defaults {
    my $self = shift;

    # this module uses Net::TCLink for connections to the payment gateway
    $self->server('');
    $self->port('');
    $self->path('');

    $self->build_subs('order_number');
}

sub map_fields {
    my($self) = @_;

    my %content = $self->content();

    # ACTION MAP
    my %actions = ('normal authorization' => 'sale',
                   'authorization only'   => 'preauth',
                   'credit'               => 'credit',
                   'post authorization'   => 'postauth',
                  );
    $content{'action'} = $actions{lc($content{'action'})} || $content{'action'};

    # TYPE MAP
    my %types = ('visa'               => 'cc',
                 'mastercard'         => 'cc',
                 'american express'   => 'cc',
                 'discover'           => 'cc',
                 'novus'              => 'cc',
                 "diner's club"       => 'cc',
                 'carte blanche'      => 'cc',
                 'japan card'         => 'cc',
                 'enroute'            => 'cc',
                 'cc'                 => 'cc',
                 'check'              => 'ach',
                );
    $content{'type'} = $types{lc($content{'type'})} || $content{'type'};
    $self->transaction_type($content{'type'});

    # stuff it back into %content
    $self->content(%content);
}

sub remap_fields {
    my($self,%map) = @_;

    my %content = $self->content();
    foreach(keys %map) {
        $content{$map{$_}} = $content{$_};
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
    $self->remap_fields(
        type           => 'media',
        login          => 'custid',
        password       => 'password',
        action         => 'action',
        amount         => 'amount',
        first_name     => 'first_name',
        last_name      => 'last_name',
        address        => 'address1',
        city           => 'city',
        state          => 'state',
        zip            => 'zip',
        card_number    => 'cc',
        expiration     => 'exp',
        account_number => 'account',
        routing_code   => 'routing',
        country        => 'country',
        phone          => 'phone',
        email          => 'email',
	order_number   => 'transid'
    );

    if($self->transaction_type() eq "ach") {
        $self->required_fields(qw/type login password action amount first_name
                                  last_name account_number routing_code/);
    } elsif($self->transaction_type() eq 'cc' ) {
      if ( $self->{_content}->{action} eq 'postauth' ) {
        $self->required_fields(qw/login password action amount order_number
                                  card_number expiration/);
      } else {
        $self->required_fields(qw/login password action amount first_name
                                  last_name card_number expiration/);
      }
    } else {
        Carp::croak("TrustCommerce can't handle transaction type: ".
                    $self->transaction_type());
    }

    my %params = $self->get_fields(qw/media custid password action amount
                                      first_name last_name address1 city state
                                      zip cc exp account routing country phone
                                      email transid/);
    $params{'demo'} = $self->test_transaction() ? 'y' : 'n';
    $params{'avs'} = $self->require_avs() ? 'y' : 'n';
    $params{'name'} = $params{'first_name'} . ' ' . $params{'last_name'};
    delete $params{'first_name'};
    delete $params{'last_name'};
    $params{'amount'} =~ s/\D//g; # strip non-digits
    $params{'cc'} =~ s/\D//g;
    $params{'exp'} =~ s/\D//g;
    $params{'exp'} = '0' . $params{'exp'} if length($params{'exp'}) == 3;

    my %results = Net::TCLink::send(\%params);

    if($results{'status'} eq 'approved' or $results{'status'} eq 'accepted') {
        $self->is_success(1);
        $self->result_code($results{'status'});
        $self->authorization($results{'avs'});
        $self->order_number($results{'transid'});
    } else {
        $self->is_success(0);
        $self->result_code($results{'status'});

        my $error;
        if ($results{'status'} eq 'decline') {
            if ($results{'declinetype'} eq 'carderror') {
                $error = 'The credit card number is invalid.';
            } else {
                $error = 'The credit card transaction was declined.';
            }
	} elsif ($results{'status'} eq 'baddata') {
            $error = 'The transaction data is invalid.';
	} elsif ($results{'status'} eq 'error') {
            $error = 'There was a network failure during processing.';
	}
        $self->error_message($error);
    }
}

1;
__END__

=head1 NAME

Business::OnlinePayment::TCLink - TrustCommerce backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("TCLink");
  $tx->content(
      type           => 'VISA',
      login          => '99999',
      password       => '',
      action         => 'Normal Authorization',
      amount         => '49.95',
      first_name     => 'Dan',
      last_name      => 'Helfman',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      card_number    => '4111111111111111',
      expiration     => '09/05',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSACTION TYPES

=head2 Visa, MasterCard, American Express, Discover, Novus, Diner's Club,
Carte Blanche, Japan Card, Enroute, CC

Content required: type, login, password, action, amount, first_name, last_name, card_number, expiration.

=head2 Check

Content required: type, login, password, action, amount, first_name, last_name, account_number, routing_code.

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

To settle an authorization-only transaction (where you set action to
'Authorization Only'), submit the transaction id code in the field
"order_number" with the action set to "Post Authorization".  You can get
the transaction id from the authorization by calling the order_number
method on the object returned from the authorization.  You must also
submit the amount field with a value less than or equal to the amount
specified in the original authorization.

=head1 COMPATIBILITY

This module relies on L<Net::TCLink> for interacting with the
TrustCommerce payment engine. See
http://www.trustcommerce.com/tclink.html for details.

=head1 AUTHOR

Dan Helfman <dan@trustcommerce.com>

Derived from code by Jason Kohles and Ivan Kohler.

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>. L<Net::TCLink>.

=cut

