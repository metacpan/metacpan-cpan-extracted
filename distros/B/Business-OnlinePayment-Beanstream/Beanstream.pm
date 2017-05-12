package Business::OnlinePayment::Beanstream;

use strict;
use URI::Escape;
use Business::OnlinePayment;
use Business::OnlinePayment::HTTPS;
use vars qw/@ISA $VERSION $DEBUG @EXPORT @EXPORT_OK/;

@ISA=qw(Exporter AutoLoader Business::OnlinePayment::HTTPS);
@EXPORT=qw();
@EXPORT_OK=qw();
$VERSION='0.02';
$DEBUG = 0;

sub set_defaults{
  my $self = shift;
  $self->server('www.beanstream.com');
  $self->port('443');
  $self->path('/scripts/process_transaction.asp');

  $self->build_subs(qw( order_number avs_code ));
}

sub map_fields{
  my $self = shift;
  my %content = $self->content();

  my %actions = ( 'normal authorization' => 'P', 
                  'authorization only'   => 'PA',
                  'post authorization'   => 'PAC',
                  'credit'               => 'R',  # not really supported yet
                );
  $content{action} = $actions{lc $content{action}} || $content{action};
  $content{requestType} = 'BACKEND';
  $content{expiration} ||= $content{exp_date};  # backward-compatibility 0.01
  # owner | company | name
  $self->content(%content);
}

sub remap_fields{
  my ($self,%map) = @_;
  my %content = $self->content();
  for (keys %map){ $content{$map{$_}} = $content{$_} || '' }
  $self->content(%content);
}

sub get_fields{
  my ($self,@fields) = @_;
  my %content = $self->content();
  my %new = ();

  for (@fields){ $new{$_} = $content{$_} || '' }

  return %new;
}
  

sub submit {
  my $self = shift;

  # Re: test_transaction - test mode is set on/off in the merchant account
  # settings.  No info on convenient way to set test mode per transaction.

  if ($DEBUG > 3)  {
     my %params = $self->content;
     warn join("\n", map { "  $_ => $params{$_}" } keys %params );
  }

  $self->map_fields();                 # set values with special handling
  $self->remap_fields(                 # rename keys
    login          => 'merchant_id',
    action         => 'trnType',
    description    => 'trnComments',
    amount         => 'trnAmount',
    invoice_number => 'trnOrderNumber',
    owner          => 'trnCardOwner',
    name           => 'ordName',
    address        => 'ordAddress1',
    city           => 'ordCity',
    state          => 'ordProvince',
    zip            => 'ordPostalCode',
    country        => 'ordCountry',
    phone          => 'ordPhoneNumber',
    email          => 'ordEmailAddress',
    card_number    => 'trnCardNumber',
    expiration     => 'trnExpYear',
    order_number   => 'adjId',
  );

  # Credits/Returns/Adjustments with Beanstream, are not currently supported.
  # would req: login, inv-num, action/trnType, username, password, adjId, amt
  # Yes Beanstream really require phone & email, for Sales/Purchases
  my @required = qw/login amount invoice_number name address city 
                             state zip country phone card_number
                             expiration owner/;
  $self->required_fields(@required);
  
  # We should prepare some fields to posting, for instance ordAddress1 should be cutted and trnExpYear 
  # should be separated to trnExpMonth and trnExpYear
  
  my %content=$self->content();
  my $address = $content{ordAddress1};
  ($content{ordAddress1}, $content{ordAddress2}) = unpack 'A32 A*', $address;
  
  my $date = $content{trnExpYear};
  ($content{trnExpMonth},$content{trnExpYear}) = ($date =~/\//) ?
                                                  split /\//, $date :
                                                  unpack 'A2 A2', $date;
  
  $self->content(%content);
  
  # Now we are ready to post request
  
  my %params = $self->get_fields( qw/merchant_id trnType trnComments
                                     trnAmount trnOrderNumber trnCardNumber
                                     trnExpYear trnExpMonth trnCardOwner
                                     ordName ordAddress1 ordCity ordProvince
                                     ordPostalCode ordCountry ordPhoneNumber
                                     ordEmailAddress requestType/ );

  warn join("\n", map { "  $_ => $params{$_}" } keys %params )
    if $DEBUG > 3;

  # Send transaction to Beanstream
  my ($page, $server_response, %headers) = $self->https_post( \%params );

  # Convert multi-line error to a single line.
  $server_response =~ s/[\r\n]+/ /g;
  
  # Handling server response
  if ($server_response != 200  and  $server_response !~ /200 OK/)  {
      # Connection error
      $self->is_success(0);
      my $diag_message = $server_response || "connection error";
      warn $diag_message  if $DEBUG;
      $self->result_code( $diag_message );
      $self->error_message( $diag_message );
  }  else  {

    if ($DEBUG > 3)  {
      warn $page;  # how helpful are %headers?
    }
    $self->server_response($page);

    my %fields; 
    for my $pair (split /&/, $page) {
      my ($key, $value) = split '=', $pair;
      $fields{$key} = URI::Escape::uri_unescape($value);
      $fields{$key} =~ tr/+/ /;
    }
    warn join("\n", map { "  $_ => $fields{$_}" } keys %fields )
      if $DEBUG > 2;

    $self->result_code($fields{messageId});
    # Was messageId =~/^[129]$/, but 9 is not approved per Reporting-Guide,
    # and there are approval codes in 61..70, 561.
    if ($fields{trnApproved}) {
      $self->is_success(1);
      $self->authorization($fields{messageText});
      $self->order_number($fields{trnId});
    } else {
      $self->is_success(0);
      if ($fields{errorMessage}) {
	 $self->error_message($fields{errorMessage});
      } else {
	 $self->error_message($fields{messageText});
      }
    }

    # avs_code - Process-Transaction-API-Guide.pdf 1.6.3
    my %avsTable = (0 => '',
		    5 => 'E',
		    9 => 'E',
		    A => 'A',
		    B => 'A',
		    C => '',
		    D => 'Y',
		    E => 'E',
		    G => '',
		    I => '',
		    M => 'Y',
		    N => 'N',
		    P => 'Z',
		    R => 'R',
		    );
    $self->avs_code($avsTable{$fields{avsAddrMatch}});

  }
}

sub response_headers{
  my ($self,%headers) = @_;
  $self->{headers} = join "\n", map{"$_: $headers{$_}"} keys %headers 
                                                        if %headers;
  $self->{headers};
}

sub response_code{
  my ($self,$code) = @_;
  $self->{code} = $code if $code;
  $self->{code};
}

###
# That's all
#
1;

__END__

=head1 NAME 

Business::OnlinePayment::Beanstream - Beanstream backend for Business::OnlinePayment

=head1 SYNOPSYS

  use Business::OnlinePayment;
  
  my $tr = Business::OnlinePayment->new('Beanstream'); 
  $tr->content(
    login          => '100200000',
    action         => 'Normal Authorization',
    amount         => '1.99',
    invoice_number => '56647',
    owner          => 'John Doe',
    card_number    => '312312312312345',
    expiration     => '1212',
    name           => 'Sam Shopper',
    address        => '123 Any Street',
    city           => 'Los Angeles',
    state          => 'CA',
    zip            => '23555',
    country        => 'US',
    phone          => '123-4567',
    email          => 'Sam@shopper.com',
  );
  $tr->submit;

  if ($tr->is_success){
    print "Card processed successfully: ".$tr->authorization."\n";
  }else{
    print "Card processing was failed: ".$tr->error_message."\n";
  }

=head1 DESCRIPTION

This module allows you to link any e-commerce order processing system directly to Beanstream transaction server (http://www.beanstream.com). All transaction fields are submitted via GET or POST to the secure transaction server at the following URL: https://www.beanstream.com/scripts/process_transaction.asp. The following fields are required:

=over 4

=item login - merchant login (Beanstream-assigned nine digit identification number)

=item action - type of transaction (Normal Authorization, Authorization Only)

=item amount - total order amount

=item invoice_number - the order number of the shopper's purchase

=item owner - name of the card owner

=item card_number - number of the credit card

=item expiration - expiration date formated as 'mmyy' or 'mm/yy'

=item name - name of the billing person

=item address - billing address

=item city - billing address city

=item state - billing address state/province

=item zip - billing address ZIP/postal code

=item country - billing address country

=item phone - billing contacts phone

=item email - billing contact's email

=back

Beanstream supports the following credit card:

=over 4

=item - VISA

=item - MasterCard

=item - American Express Card

=item - Discover Card

=item - JCB

=item - Diners

=back

Currently you may process only two types of transaction, namely 'Normal Authorization' (Purchase) and 'Authorization Only' (Pre-Auth).

For detailed information about methods see L<Business::OnlinePayment>

=head1 SEE ALSO

L<Business::OnlinePayment>

=cut
