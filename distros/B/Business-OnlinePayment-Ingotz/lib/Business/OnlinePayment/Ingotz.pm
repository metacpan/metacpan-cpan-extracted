package Business::OnlinePayment::Ingotz;

use strict;
use Business::OnlinePayment;
use Net::SSLeay qw/make_form post_https/;
use vars qw/@ISA $VERSION @EXPORT @EXPORT_OK $DEBUG %ERRORS/;

$DEBUG = 1;
@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.01';
%ERRORS = (
    '-1' => "Not enough points for the transactions (not enough funds)",
    '-2' => "Invalid card/pin number",
    '-3' => "Invalid merchant number",
    '-4' => "System error",
    '-5' => "System unavailable",
);


sub set_defaults{
    my $self = shift;
    $self->server('secure.ingotz.com');
    $self->port('443');
    $self->path('/process/process.jsp');
}


sub map_fields{
    my $self = shift;
    my %content = $self->content();

    my %actions = ( 'normal authorization' => 'raw' );
    $content{action} = $actions{lc $content{action}} || 'raw';
  
    $self->content(%content);
}


sub remap_fields{
    my ($self, %map) = @_;
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
  

sub submit{
    my $self = shift;
 
    $self->map_fields();
    $self->remap_fields(
        login          => 'merchant_id',
        action         => 'ingtype',
        description    => 'info',
        amount         => 'amount',
        card_number    => 'card_number',
        pin            => 'pin',
    );

    $self->required_fields( qw/login action amount card_number pin/ );
  
    # Now we are ready to post request
  
    my %post_data = $self->get_fields(
        qw/merchant_id ingtype info amount card_number pin/
    );
    my $pd = make_form(%post_data);
    my ($page, $server_response, %headers) = post_https( 
        $self->server(),
        $self->port(),
        $self->path(),
        '',
        $pd,
    );
    $self->response_code($server_response);
    $self->response_headers(%headers);
  
    if ($server_response =~/200 OK/) {
        
        # Handling server response
        # the response will either be
        # > 0  a valid transaction this number is the transaction number for
        
        $page=~s/\s//msg;
        print STDERR "Server Response:\n$page\n" if $DEBUG; 
        if ($page > 0) {
            $self->is_success(1);
            $self->result_code($page);
        }
        else {
        
        # -1 Not enough points for the transactions (not enough funds)
        # -2 Invalid card/pin number
        # -3 invalid merchant number
        # -4 System Error
        # -5 System unavailable
        
            $self->is_success(0);
            $self->result_code($page);
            $self->error_message($ERRORS{$page} || 'Unknown Error');
        }
            
    }
    else {
        
        # HTTP Error
        
        $self->is_success(0);
        $self->result_code('-6');
        $self->error_message('HTTP error: check response code');
        $self->server_response($page);    
    }
}


sub response_headers{
  my ($self, %headers) = @_;
  $self->{headers} = join "\n", map{"$_: $headers{$_}"} keys %headers 
                                                        if %headers;
  $self->{headers};
}


sub response_code{
  my ($self, $code) = @_;
  $self->{code} = $code if $code;
  $self->{code};
}


###
# That's all
#
1;

__END__

=head1 NAME 

Business::OnlinePayment::Ingotz - Ingotz backend for Business::OnlinePayment

=head1 SYNOPSYS

  use Business::OnlinePayment;
  
  my $tr = Business::OnlinePayment->new('Ingotz');
  $tr->content(
    login          => '6277177700000000',
    action         => 'Normal Authorization',
    amount         => '199',
    card_number    => '312312312312345',
    pin            => '0505',
    description    => '1 Subscription to Pay per Use service L2.00',
  );
  $tr->submit;

  if ($tr->is_success){
    print "Card processed successfully: ".$tr->authorization."\n";
  }else{
    print "Card processing was failed: ".$tr->error_message."\n";
  }

=head1 DESCRIPTION

This module allows you to link any e-commerce order processing system directly
to Ingotz transaction server (http://www.ingotz.com). All transaction fields
are submitted via GET or POST to the secure transaction server at the following
URL: https://secure.ingotz.com/process/process.jsp. 
The following fields are required:

=over 4

=item login - the shop owners Ingotz Merchant account number

=item action - type of transaction (must be "Normal Authorization")

=item amount - the amount to deduct in pence(points)

=item card_number - the customer card number

=item pin - the customer pin number

=item description - the description to appear on the customers and merchants statements

=back

=head1 SEE ALSO

L<Business::OnlinePayment>

=cut
