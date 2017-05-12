package Business::OnlinePayment::2CheckOut;

use 5.006;
use strict;
use Business::OnlinePayment;
use Net::SSLeay qw/make_form make_headers post_https/;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

our @ISA = qw(Exporter AutoLoader Business::OnlinePayment);
our @EXPORT = qw();
our @EXPORT_OK = qw();
our $VERSION = '0.01';

sub set_defaults {
  my $self = shift;

  $self->server('www.2checkout.com');
  $self->port('443');
  $self->path('/cgi-bin/Abuyers/purchase.2c');
  $self->build_subs('order_number');
  $self->build_subs('second_path');
  $self->build_subs('proto');
  $self->second_path('/cgi-bin/Abuyers/purchase1.2c');
  $self->proto('https://');
  $self->test_transaction('1');
}

sub map_fields {
  my($self) = @_;
  my %content = $self->content();

  $self->transaction_type($content{'type'});
  # stuff it back into %content
  $self->content(%content);
}

sub parse {
  my($self,$answer) = @_;
  my($key,$element,@hidden_fields);
  my %content;
  $key='';

  @hidden_fields = $answer =~ m/\<input\stype\="?hidden"?\sname\="?([\w\_]+)"?\svalue\="?([\w\d\/\_]+)"?\>/gs;
  foreach $element (@hidden_fields) {
    if ($key) {
      $content{$key}="$element";
      $key='';
    }
    else {
      $content{"$element"}='';
      $key="$element";
    }
  }
  # stuff it back into %content
  $self->content(%content);
}

sub answer_parse {
  my($self,$page,$server_response,%headers) = @_;
  my %content = $self->content();

  $self->server_response($page);
  if($content{'x_response_code'} == "1") { # Authorized/Pending/Test
    $self->is_success(1);
    $self->result_code($content{'x_response_reason_code'});
    $self->authorization($content{'x_auth_code'});
    $self->order_number($content{'content_number'});
  }
  else {
    $self->is_success(0);
    $self->result_code($content{'x_response_reason_code'});
    $self->error_message($content{'x_response_reason_text'});
    unless ( $self->result_code() ) { #additional logging information
      $self->error_message($content{'x_response_reason_text'}.
        " DEBUG: No x_response_code from server, ".
        "(HTTPS response: $server_response) ".
        "(HTTPS headers: ".
        join(", ", map { "$_ => ". $headers{$_} } keys %headers ). ") ".
        "(Raw HTTPS content: $page)"
      );
    }
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

sub get_fields {
  my($self,@fields) = @_;

  my %content = $self->content();
  my %new = ();
  foreach( grep defined $content{$_}, @fields) {
    $new{$_} = $content{$_};
  }
  return %new;
}

sub submit {
  my($self) = @_;

  $self->map_fields();
  $self->remap_fields(
    login          => 'x_login',
    amount         => 'x_amount',
    order_number   => 'x_invoice_num',
    first_name     => 'x_First_Name',
    last_name      => 'x_Last_Name',
    address        => 'x_Address',
    city	   => 'x_City',
    state	   => 'x_State',
    zip		   => 'x_Zip',
    country	   => 'x_Country',
    phone	   => 'x_Phone',
    email	   => 'x_Email',
    card_number    => 'x_Card_Num',
    expiration     => 'x_Exp_Date',
    cvv2           => 'cvv',
  );

  $self->required_fields(qw/login amount order_number first_name last_name
     address city state zip country phone email card_number expiration cvv2/);

  my %post_data = $self->get_fields(qw/x_login x_amount x_invoice_num
    x_First_Name x_Last_Name x_Address x_City x_State x_Zip x_Country
    x_Phone x_Email x_Card_Num x_Exp_Date cvv/);
  $post_data{'x_Test_Request'} = $self->test_transaction()?"TRUE":"FALSE";
  $post_data{'demo'} = $self->test_transaction()?"Y":"";

  my $pd = make_form(%post_data);
  my $s = $self->server();
  my $p = $self->port();
  my $t = $self->path();
  my($page,$server_response,%headers) = post_https($s,$p,$t,'',$pd);
  #escape NULL (binary 0x00) values
  $page =~ s/\x00/\^0/g;

  $self->parse($page);
  %post_data = $self->get_fields(qw/order_number total demo cart_order_id
     sid cem cey x_login x_amount x_invoice_num x_first_name x_last_name
     x_address x_city x_state x_zip x_country x_phone x_email x_exp_date
     x_card_num cvv x_test_request/);

  my $pds = make_form(%post_data);
  $s = $self->server();
  $p = $self->port();
  $t = $self->second_path('/cgi-bin/Abuyers/purchase1.2c');
  my $header=make_headers(
    'Referer' => $self->proto().$self->server().$self->path().'?'.$pd
  );
  ($page,$server_response,%headers) = post_https($s,$p,$t,$header,$pds);
  #escape NULL (binary 0x00) values
  $page =~ s/\x00/\^0/g;

  $self->parse($page);
  $self->answer_parse($page,$server_response,%headers);
}

1;
__END__

=head1 NAME

Business::OnlinePayment::2CheckOut - 2CheckOut backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("2CheckOut");
  $tx->content(
    login          => '124',
    amount         => '23.00',
    order_number   => '100100',
    first_name     => 'Jason',
    last_name      => 'Kohles',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '99999',
    country        => 'USA',
    phone          => '555-55-55',
    email          => 'whoever@anywhere.com',
    card_number    => '4007000000027',
    expiration     => '09/02',
    cvv2           => '123',
  );
  $tx->test_transaction(1); # test, dont really charge
  $tx->submit();

  if($tx->is_success()) {
     print "Card processed successfully: ".$tx->authorization."\n";
  }
  else {
    print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSACTION TYPES

=head2 Visa, MasterCard, American Express, Discover

Content required:
    login - merchant login to the 2CheckOut authorization System,
    amount - total amount of money to be charged,
    first_name - first name of card holder,
    last_name - last name of card holder,
    card_number - the credit card number,
    expiration - expiration date of credit card (formatted as mm/yy),
    cvv2 - CVV2 code on the credit card,
    invoice_number - the order number of the purchase,
    address - billing address,
    city - billing city,
    state - billing state,
    zip - billing zip/postal code,
    country - billing country,
    phone - billing phone,
    email - billing e-mail.


=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 COMPATIBILITY

This module implements Normal Authorization mathod only.
See http://www.2checkout.com/cart_specs.htm for details.

=head1 AUTHOR

Alexey Khobov, E<lt>alex@stork.ruE<gt>

=head1 SEE ALSO

L<perl>. L<Business::OnlinePayment>.

=cut
