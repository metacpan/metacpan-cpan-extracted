package Business::OnlinePayment::iAuthorizer;

# $Id: iAuthorizer.pm,v 1.6 2003/09/11 05:30:38 db48x Exp $

use Data::Dumper;
use strict;
use Business::OnlinePayment;
use Net::SSLeay qw/make_form post_https make_headers/;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.2';

sub set_defaults {
    my $self = shift;

    $self->server('tran1.iAuthorizer.net');
    $self->port('443');
    $self->path('/trans/postto.asp');

    $self->build_subs('action');
    $self->build_subs('debug');
}

sub map_fields {
    my($self) = @_;

    my %content = $self->content();

    # ACTION MAP
    my %actions = ('normal authorization' => '5',
                   'authorization only'   => '6',
                   'credit'               => '0',
                   'post authorization'   => '2',
                   'void'                 => '1',
                  );
    $content{'action'} = $actions{lc($content{'action'})};

    my %methods = ('manual'         => '0',
                   'swipe'          => '1',
                   'swipe, track 1' => '1',
                   'swipe, track 2' => '2',
                  );
    $content{'entry_method'} = $methods{lc($content{'entry_method'})};

    ($content{'expMonth'}, $content{'expYear'}) = split('/', $content{'expiration'});

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
    foreach(grep defined $content{$_}, @fields) { $new{$_} = $content{$_}; }

    return %new;
}

sub transaction_type {
    my $self = shift;
    return $self->content()->{'action'};
}

sub submit {
    my($self) = @_;

    $self->map_fields();
    $self->remap_fields(
        entry_method   => 'EntryMethod',
        login          => 'MerchantCode',
        password       => 'MerchantPWD',
        serial         => 'MerchantSerial',
        action         => 'Trantype',
        amount         => 'amount',
        invoice_number => 'invoicenum',
	order_number   => 'referencenum',
	authorization  => 'appcode',
        customer_id    => 'customer',
        address        => 'Address',
        zip            => 'ZipCode',
        card_number    => 'ccnumber',
        cvv2           => 'CVV2',
    );

#    if ($self->action() == 0 || $self->action() == 1) # void or force
#    {
#      $self->required_fields(qw/login password serial action card_number expiration amount authorization/);
#    }
#    else
#    {
      $self->required_fields(qw/login password serial action card_number expiration amount/);
#    }

    my %post_data = $self->get_fields(qw/MerchantCode MerchantPWD MerchantSerial ccnumber 
                                         expYear expMonth Trantype EntryMethod amount 
                                         invoicenum ordernum Zipcode Address CVV2 CF appcode/);

    $post_data{'EntryMethod'} = 0;   # hand entered, as opposed to swiped through a card reader
    $post_data{'CF'} = 'ON';         # return comma-delimited data

    my $pd = make_form(%post_data);
    my $s = $self->server();
    my $p = $self->port();
    my $t = $self->path();
    my $r = $self->{_content}->{referer};
    my($page,$server_response,%headers) = post_https($s,$p,$t,$r,$pd);

    my @col = split(',', $page);

    $self->server_response($page);
    if($col[0] eq "0" ) {
        $self->is_success(1);
        $self->result_code($col[1]);
        $self->authorization($col[1]);
    } else {
        $self->is_success(0);
        $self->result_code($col[1]);
        $self->error_message($col[2]);
    }

    $self->debug("&lt;no response code, debug info follows&gt;\n".
      "HTTPS response:\n  $server_response\n\n".
      "HTTPS headers:\n  ".
        join("\n  ", map { "$_ => ". $headers{$_} } keys %headers ). "\n\n".
      "POST Data:\n  ".
        join("\n  ", map { "$_ => ". $post_data{$_} } keys %post_data ). "\n\n".
      "Raw HTTPS content:\n  $page");
}

1;
__END__

=head1 NAME

Business::OnlinePayment::iAuthorizer - iAuthorizer.net backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("iAuthorizer");
  $tx->content('login'       => '...', # login, password, and serial for your account
               'password'    => '...',   
               'serial'      => '...',
               'action'      => 'Normal Authorization',
               'card_number' => '4012888888881',  # test card       
               'expiration'  => '05/05',
               'amount'      => '1.00',
               'address'     => '123 Anystreet',
               'zip'         => '12345',
               'cvv2'        => '1234',
              );

  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSACTION TYPES



=head2 Credit Card transactions

All credit card transactions require the login, password, serial, action, 
amount, card_number and expiration fields.

The type field is never required, as the module does not support 
check transactions.

The action field may be filled out as follows:

=head3 Normal Authorization, Authorization Only, and Credit

   The API documentation calls these Purchase, Authorization Only and Return.

=head3 Post Authorization and Void

   Refered to as Force and Void transaction types in the API documentation, 
   you must also pass in the authorization code (in the authorization field) 
   that you recieved with the original transaction.

=head2 Check transactions

Check transactions are not supported by this module. It would not be 
difficult to add, but I will not be needing it, so I may not get to 
it. Feel free to submit a patch :).

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 COMPATIBILITY

This module implements iAuthorizer.net's API, but does not support 
check transactions or the 'post back' response method.

This module has been certified by iAuthorizer.

=head1 AUTHOR

Copyright (c) 2003 Daniel Brooks <db48x@yahoo.com>

Many thanks to Jason Kohles and Ivan Kohler, who wrote and maintain
Business::OnlinePayment::AuthorizeNet, which I borrowed heavily from
while building this module.

The iAuthorizer.net service is required before this module will function, 
however the module itself is free software and may be redistributed and/or 
modified under the same terms as Perl itself.

=head1 SEE ALSO

L<Business::OnlinePayment>.

=cut

