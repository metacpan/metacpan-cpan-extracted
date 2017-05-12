package Business::OnlinePayment::Cardstream;
# $Id: Cardstream.pm,v 1.0 2000/02/16 11:15:21 belcham Exp $

use Business::OnlinePayment;
use strict;
use Net::SSLeay qw/make_form post_https/;
require Exporter;


use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
$VERSION = do { my @r=(q$Revision: 1.0 $=~/\d+/g);sprintf "%d."."%02d"x$#r,@r};

## Default values...
sub set_defaults{
	my $self = shift;
	$self->server('auth.cardstream.com');
	$self->port('443');
	$self->path('/auth_text.cgi');
}

## process_params, Business::OnlinePayment sets a standard of
## parameter formats for generic use on multiple processor
## sublclasses, some of these may need to be changed for Cardstream

sub process_params {
	my $self = shift;
	my %content = $self->content();
	
	my %actions = ('authorize'	=>	'AUTH',
		       'authorise'	=>	'AUTH',
		       'refund'		=>	'REFUND');

	my %cardtype = ('visa'			=>	'VISA',
			'mastercard'		=>	'MASTERCARD',
			'amex'			=>	'AMEX',
			'american express'	=>	'AMEX',
			'switch'		=>	'SWITCH'
			);

	$content{'type'} = $cardtype{lc($content{'type'})};
	$content{'action'} = $actions{lc($content{'action'})};
	$self->content(%content);
}

sub sanity {
	my $self = shift;
	my %content = $self->content;

	## Required for any transaction...
	$self->required_fields(qw/CARDTYPE USERNAME PASSWD 
			          ACTION AMOUNT CARDNO EXP/);

	## Switch cards require an issue number.
	$self->required_fields(qw/ISSUE/) 
		if $content{'type'} eq 'SWITCH';
}

	

			          


## submit.  Required and called by Business::OnlinePayment
sub submit {
	my $self = shift;
	
	$self->process_params;	# Fiddle with the parameters.
	$self->remap_fields(
		type		=>	'CARDTYPE',
		login		=>	'USERNAME',
		password	=>	'PASSWD',
		action		=>	'ACTION',
		amount		=>	'AMOUNT',
		name		=>	'CUSTNAME',
		address		=>	'CUSTADDRESS',
		card_number	=>	'CARDNO',
		expiration	=>	'EXP',
		issue		=>	'ISSUE',
		email		=>	'EMAIL'
	);

	$self->sanity;		# Are we kosha enough to post a request?

	my %post = $self->get_fields(qw/CARDTYPE USERNAME PASSWD ACTION
		                        AMOUNT CUSTNAME CUSTADDRESS 
			                CARDNO EXP ISSUE EMAIL/);



	$post{'TEST'} = ($self->test_transaction) ? '1' : undef ;
	my $query = &make_form(%post);
	my $server = $self->server;
	my $port   = $self->port;
	my $path   = $self->path;

	my ($page,$server_response,%headers) = 
		&post_https($server,$port,$path,'',$query);

	$self->server_response($page);
	my %response = (split('\|',$page));
	
	if ($response{'RESPCODE'} eq '00') {
		$self->is_success(1);
		$self->result_code($response{'RESPCODE'});
		$self->authorization($response{'AUTHCODE'});
	} else {
		$self->is_success(0);
		$self->result_code($response{'RESPCODE'});
		$self->error_message($response{'ERRORMSG'});
	}
}


1;
__END__

=head1 NAME

Business::OnlinePayment::Cardstream - Cardstream Plugin for Business::OnlinePayment

=head1 SYNOPSIS

	use Business::OnlinePayment;
	my $Cardstream = new Business::OnlinePayment("Cardstream");
	
	$Cardstream->content(
		type		=>	'visa',
		login		=>	'mylogin',
		passwd		=>	'mypassword',
		action		=>	'authorise',
		amount		=>	'5.00',
		name		=>	'John Watson',
		address		=>	'6 Elms, Oak Road.',
		card_number	=>	'4725444499992827',
		expiration	=>	'0112' #YYMM
		);
	$Cardstream->submit;
	
	if ($Cardstream->is_success) {
		print "Success, Auth Code is ".$Cardstream->authorization;
	} else {
		print "Failed, Error message ".$Cardstream->error_message;
	}

	my @RESPONSE = split('\|',$Cardstream->server_response);
	my %response_hash = @RESPONSE;
	


=head1 Supported Cards

=head2 Visa, MasterCard, Switch	(Check website for updates)

Switch cards require issue number; $Cardstream->content(issue => '1')

=head1 NOTES

=head2 Merchant accounts

A Cardstream merchant account is free of charge to set-up.  Cardstream operates on a commission basis. Please see http://www.cardstream.com for pricing information, or contact sales@cardstream.com. 

=head2 Expiration dates

Cardstream.pm requires expiration dates in APACS/30 Standard format, which, unlike what is printed on the card, is YYMM.

=head2 server-response

The auth code and error messages are stored into $Cardstream->authorization and $Cardstream->error_message, however should you require more debugging information, server-response contains a pipe delimited hash consisting of the error code, text message from bank...etc.  

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 AUTHOR

Craig R. Belcham, crb@cardstream.com.

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.
http://www.cardstream.com for merchant account information.
=cut
