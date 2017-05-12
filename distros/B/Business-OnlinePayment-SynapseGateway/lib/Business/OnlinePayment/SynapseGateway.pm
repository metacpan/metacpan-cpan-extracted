package Business::OnlinePayment::SynapseGateway;


use strict;
use warnings;
use Carp;
use Business::OnlinePayment;
use Business::OnlinePayment::HTTPS;
use vars qw($VERSION @ISA $me);

@ISA = qw(Business::OnlinePayment::HTTPS);

$VERSION = '0.01';

$me = 'Business::OnlinePayment::SynapseGateway';

sub set_defaults {
    my $self = shift;
    $self->server("connect12.synapsegateway.net");
    $self->port("443");
    $self->path("/Submit.aspx");    
	
    $self->build_subs(qw( order_number avs_code                           
		      ));
}

sub map_fields {
    my($self) = @_;
    my %content = $self->content();

    my %map;
    if ($content{'type'} =~ /^(cc)$/i) {
 
        %map = ( 'normal authorization' => 'S',
                 'authorization only'   => 'A',
                 'credit'               => 'C',
                 'post authorization'   => 'P',
                 'void'                 => 'V',
               );   
    }

    $content{'action'} = $map{lc($content{'action'})}
      or croak 'Unknown action: '. $content{'action'};  

    $self->transaction_type($content{'type'});

    # stuff it back into content
    $self->content(%content);
}

sub required_fields {
    my($self,@fields) = @_;

    my @missing;
    my %content = $self->content();
    foreach(@fields) {
      next
        if (exists $content{$_} && defined $content{$_} && $content{$_}=~/\S+/);
      push(@missing, $_);
    }

    Carp::croak("missing required field(s): " . join(", ", @missing) . "\n")
      if(@missing);
}

sub submit {
    my($gateway) = @_;
    my $tranType;
    my $tranAmt;
    $gateway->map_fields();
    $gateway->remap_fields(	
	login            => 'Syn_Act',
	password         => 'Syn_Pwd',
	action           => 'Tran_Type',
	amount		 => 'Tran_Amt',
	invoice_number	 => 'Tran_Inv',
	customer_id      => 'Tran_CNum',
	description      => 'Tran_Note',
	card_number      => 'Card_Num',
	name             => 'Card_Name',
	expiration       => 'Card_Exp',
	address          => 'AVS_Street',
	zip              => 'AVS_Zip',
	cvv2             => 'CVV_Num',	
	order_number	 => 'Proc_ID',
    );
    #Set required fields based on action
    my %required;
    #Sale
    $required{S} =  [ qw( Syn_Act Syn_Pwd Tran_Type Tran_Amt Card_Name
                                Card_Num Card_Exp ) ];
    #Credit
    $required{C} =  [ qw( Syn_Act Syn_Pwd Tran_Type Tran_Amt Card_Name
                                Card_Num Card_Exp ) ];
    #Void
    $required{V} =  [ qw( Syn_Act Syn_Pwd Tran_Type Proc_ID ) ];
    #Auth
    $required{A} =  [ qw( Syn_Act Syn_Pwd Tran_Type Tran_Amt Card_Name
                                Card_Num Card_Exp ) ];
    #Post Auth
    $required{P} =  [ qw( Syn_Act Syn_Pwd Tran_Type Tran_Amt Proc_ID  ) ];    
    #Mark
    $required{M} =  [ qw( Syn_Act Syn_Pwd Tran_Type Tran_Amt Proc_ID  ) ];                             
                                
    #Collect content
    my %trans = $gateway->content(); 
    $tranType = $trans{'Tran_Type'};
    $tranAmt = $trans{'Tran_Amt'};
    
    #Check for post auth
    if ($trans{'Tran_Type'} eq "P"){
	#Collect content for query   
	my %query = $gateway->content();
	$query{'Tran_Type'} = 'Q';
	$gateway->content(%query);
	#Send query
	my( $Qpage, $Qresp, %Qresp_headers) =
	$gateway->https_post( $gateway->get_fields( $gateway->fields ) );
    
	$gateway->response_code( $Qresp );
	$gateway->response_page( $Qpage );
	$gateway->response_headers( \%Qresp_headers );
	#parse query response
	my %Qresults = map { s/\s*$//;
			my ($name, $value) = split '=', $_, 2;
                        $name  =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
                        $value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
                        $name, $value;
                      } split '&', $Qpage;

	#Check if passed amount and auth amount are the same
	if ($trans{'amount'}+0 eq $Qresults{'Tran_Amt'}+0){
	    #Amounts are the same, change to Mark instead of Post Auth	    
	    $trans{'Tran_Type'} = 'M';
	    $gateway->content(%trans);	
	} else {
	    #Submit passed values
	    $trans{'Tran_type'} = $tranType;
	    $trans{'Tran_Amt'} = $tranAmt;
	    $gateway->content(%trans);
	}  
    }    
    #Check for required
    $gateway->required_fields(@{$required{$trans{'Tran_Type'}}});
    #Submit
    my( $page, $resp, %resp_headers) =
    $gateway->https_post( $gateway->get_fields( $gateway->fields ) );
    
    $gateway->response_code( $resp );
    $gateway->response_page( $page );
    $gateway->response_headers( \%resp_headers );
    #Get results
    my %results = map { s/\s*$//;
			my ($name, $value) = split '=', $_, 2;
                        $name  =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
                        $value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
                        $name, $value;
                      } split '&', $page;
    #Parse results                  
    $gateway->avs_code( $results{ 'AVS_Code' } );
    $gateway->result_code( $results{ 'Proc_Resp' } );
    $gateway->order_number( $results{ 'Proc_ID' } );
    $gateway->authorization( $results{ 'Proc_Code' } );
    $gateway->error_message( $results{ 'Proc_Mess' } );  
	
    #If type is Post Auth send Mark
    if ($results{ 'Proc_Resp' } eq "Approved" && $results{ 'Tran_Type' } eq "P"){
	#Setup mark transaction         
	my %mark = $gateway->content();
	$mark{'Tran_Type'} = 'M';
	$mark{'order_number'} = $results{'Proc_ID'};
	$gateway->content(%mark);
	#Send mark
	my( $page, $resp, %resp_headers) =
	$gateway->https_post( $gateway->get_fields( $gateway->fields ) );
    
	$gateway->response_code( $resp );
	$gateway->response_page( $page );
	$gateway->response_headers( \%resp_headers );
	#Get results
	my %results = map { s/\s*$//;
		my ($name, $value) = split '=', $_, 2;
		$name  =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
		$value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
		$name, $value;
	} split '&', $page;    
    }		    
    #Set success
    if ($results{ 'Proc_Resp' } eq "Approved"){
        $gateway->is_success(1);
    } else {
        $gateway->is_success(0);
    }    
}

sub fields {
	my $self = shift;
	my @fields = qw(
	  Syn_Act
	  Syn_Pwd
	  Tran_Type
	  Tran_Amt
	  Tran_Inv
	  Tran_CNum
	  Tran_Note
	  Card_Num
	  Card_Name
	  Card_Exp
	  AVS_Street
	  AVS_Zip
	  CVV_Num
	  Proc_ID
	);

	return @fields;
}

1;
__END__

=head1 NAME

Business::OnlinePayment::SynapseGateway - SynapseGateway backend for Business::OnlinePayment

=head1 SYNOPSIS

use Business::OnlinePayment;
 
  my $transaction = new Business::OnlinePayment($processor, %processor_info);
  $transaction->content(
                        login=>'Demo-Syn',
			password=>'demo',
			type=>'cc',
			action=>'normal authorization',
			amount=>'4.00',
			description=>'perl test',
			invoice_number=>'123456',
			customer_id=>'123',
			name=>'Mr Customer',
			address=>'123 Main',
			zip=>'55123',
			card_number=>'4111111111111111',
			expiration=>'1214',
			cvv2=>'123',
			order_number=>'',
                       );    
                                         
  $transaction->submit();
  
    if($transaction->is_success()) {
    print "Transaction processed successfully: ", $transaction->authorization(), "\n";
  } else {
    print "Transaction was rejected: ", $transaction->error_message(), "\n";
  }

=head1 DESCRIPTION

This module is a back end driver that implements the interface specified by Business::OnlinePayment to support payment handling via SynapseGateway payment solution.

=head2 SUPPORTED TRANSACTION ACTIONS

Type = 'CC'

Normal Authorization
Authorization Only
Post Authorization*
Void*
Credit

Content required: type, login, password, action, amount, name, card_number, expiration, *order_number.

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 METHODS AND FUNCTIONS

See L<Business::OnlinePayment> for the complete list. The following methods either override the methods in L<Business::OnlinePayment> or provide additional functions.

=head1 NOTES

To settle an authorization-only transaction (where you set action to
'authorization only'), submit the twelve-digit transaction id code in
the field "order_number" with the action set to "post authorization".
You can get the transaction id from the authorization by calling the
order_number method on the object returned from the authorization.
You must also submit the amount field with a value less than or more than
the amount specified in the original authorization. If the amount is the same,
a "mark for settlement" will be sent to the gateway in place of a post authorization.
"mark for settlement" automatically takes place on all post authorization
with varying amounts.
 
SynapseGateway supports AVS and CVV Verification. If the user would like to use 
these features, the following information should be submitted with each 
transaction: Address, Zip, and CVV number. If these values are present the 
gateway will return responses for these verifications.  

=head1 AUTHOR

Mike Dunham<lt>mdunham@synapsecorporation.com<gt>


=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut
