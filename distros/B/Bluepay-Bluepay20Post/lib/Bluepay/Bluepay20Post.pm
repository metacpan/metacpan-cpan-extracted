package Bluepay::Bluepay20Post;

$VERSION   = '0.10';

use strict;
use warnings;

# Required modules
use Digest::MD5  qw(md5_hex);
use LWP::UserAgent;
use URI::Escape;


## Bluepay20Post default fields ##
my $URL = 'https://secure.bluepay.com/interfaces/bp20Post';
my $MODE = "TEST";


=head1 NAME

Bluepay::Bluepay20Post

=head1 VERSION

Version: 0.10
April 2008

=head1 SYNOPSIS

Bluepay::Bluepay20Post - The BluePay 2.0 Post interface

=head1 DESCRIPTION

Bluepay::Bluepay20Post is a Perl based implementation for interaction with the 
Bluepay 2.0 Post interface.  Bluepay20Post accepts the parameters needed for the 
Bluepay20Post and sends the Post request to Bluepay via HTTPS.  Bluepay20Post 
has been developed on Windows XP, but should work on any OS where Perl is installed.

=head1 RUNNING Bluepay::Bluepay20Post

	use Bluepay::Bluepay20Post;

	# Create object
	my $bp20obj = Bluepay::Bluepay20Post->new();

	# Assign values
	$bp20Obj->{ACCOUNT_ID} = "myaccountid";
	$bp20Obj->{SECRET_KEY} = 'mysecretkey';
	$bp20Obj->{TRANS_TYPE} = 'SALE';
	$bp20Obj->{MODE} = 'TEST';		# Default is TEST --> Set to LIVE for live tx
	$bp20Obj->{AMOUNT} = '3.01';	# ODD returns Approved, EVEN returns Declined in TEST mode
	$bp20Obj->{PAYMENT_ACCOUNT} = '4111111111111111';	# VISA Test Card
	$bp20Obj->{CARD_EXPIRE} = '0808';
	## PLEASE REVIEW THE BP20 POST DOCUMENTATION TO SEE ALL REQUIRED/POSSIBLE VALUES
	## REFERENCE THEM BY NAME DIRECTLY
	
	# Post --> Results contains the name value pair string of the response
	#  In this format: TRANS_ID=&STATUS=&AVS=&CVV2=&MESSAGE=&REBID=
	my $results = $bp20Obj->Post();

	# Can also retrieve the results directly from the object
	print $bp20Obj->{TRANS_ID} . "\n";
	print $bp20Obj->{STATUS} . "\n";
	print $bp20Obj->{AVS} . "\n";
	print $bp20Obj->{CVV2} . "\n";
	print $bp20Obj->{AVS} . "\n";
	print $bp20Obj->{AUTH_CODE} . "\n";
	print $bp20Obj->{MESSAGE} . "\n";
	print $bp20Obj->{REBID} . "\n";
	

=head1 METHODS

=head2 new

Creates a new instance of a Bluepay::Bluepay20Post object

=cut

# New
sub new  { 
	my $class = shift;
    my $self  = {};         # allocate new hash for object
    bless($self, $class);
       
    # Set defaults
    $self->{URL} = $URL;
    $self->{MODE} = $MODE;
       
	# return object
    return $self;
}

=head2 Post

Posts the data to the Bluepay::Bluepay20Post interface

=cut

sub Post {
    my $self = shift; 
    
    ## Create TAMPER_PROOF_SEAL:
	# The TAMPER_PROOF_SEAL is an MD5 checksum of your SECRET KEY and a few transaction parameters.
	# The TAMPER_PROOF_SEAL is currently calculated as follows:
	#  md5(SECRET KEY + ACCOUNT_ID + TRANS_TYPE + AMOUNT + MASTER_ID + NAME1 + PAYMENT_ACCOUNT)
	#   where '+' indicates string concantenation and undefined fields are concantenated as '' (null string)
	my $TAMPER_PROOF_DATA = ($self->{SECRET_KEY} || '') . ($self->{ACCOUNT_ID} || '') . ($self->{TRANS_TYPE} || '') 
		. ($self->{AMOUNT} || '') . ($self->{MASTER_ID} || '') . ($self->{NAME1} || '') . ($self->{PAYMENT_ACCOUNT} || '');
	my $TAMPER_PROOF_SEAL = md5_hex $TAMPER_PROOF_DATA;;
  
    # Create request (encode)
    my $request = $self->{URL} . "\?TAMPER_PROOF_SEAL=" . uri_escape($TAMPER_PROOF_SEAL || ''); 
	while ( my ($key, $value) = each(%$self) ) { 
		if ($key eq 'SECRET_KEY') { next; }  $request .= "&$key=" . uri_escape($value || ''); 
	}

    # Create Agent
    my $ua = new LWP::UserAgent;
    #my $response = $ua->Post("$request"); #OLD
    my $response = $ua->get("$request");
    my $content = $response->content;
    chomp $content;
    
    # Parse Response
	# Split the name-value pairs
	my @pairs = split(/&/, $content);
	foreach my $pair (@pairs) {
      my ($name, $value) = split(/=/, $pair);
      $value =~ tr/+/ /;  $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
      $self->{$name} = $value;
	}
        
    # Return
    return $content;
}

=head1 MODULES

This script has some dependencies that need to be installed before it
can run.  You can use cpan to install the modules.  They are:
 - Digest::MD5
 - LWP::UserAgent
 - URI::Escape

=head1 AUTHOR

The Bluepay::Bluepay20Post perl module was written by Christopher Kois <ckois@bluepay.com>.

=head1 COPYRIGHTS

	The Bluepay::Bluepay20Post package is Copyright (c) April, 2008 by BluePay, Inc. 
	http://www.bluepay.com All rights reserved.  You may distribute this module under the terms 
	of GNU General Public License (GPL). 
	
Module Copyrights:
 - The Digest::MD5 module is Copyright (c) 1998-2003 Gisle Aas.
	Available at: http://search.cpan.org/~gaas/Digest-MD5-2.36/MD5.pm
 - The LWP::UserAgent module is Copyright (c) 1995-2008 Gisle Aas.
	Available at: http://search.cpan.org/~gaas/libwww-perl-5.812/lib/LWP/UserAgent.pm
 - The URI::Escape module is Copyright (c) 1995-2004 Gisle Aas.
	Available at: http://search.cpan.org/~gaas/URI-1.36/URI/Escape.pm
				
NOTE: Each of these modules may have other dependencies.  The modules listed here are
the modules that Bluepay::Bluepay20Post specifically references.

=head1 SUPPORT/WARRANTY

Bluepay::Bluepay20Post is free Open Source software.  This code is Free.  You may use it, modify it, 
redistribute it, Post it on the bathroom wall, or whatever.  If you do make modifications that are 
useful, Bluepay would love it if you donated them back to us!

=head1 KNOWN BUGS:

This is version 0.10 of Bluepay::Bluepay20Post.  There are currently no known bugs.

=cut

1;
