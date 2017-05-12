package Bluepay::Bluepay20DailyReport;

$VERSION   = '0.15';

use strict;
use warnings;

# Required modules
use Digest::MD5  qw(md5_hex);
use LWP::UserAgent;
use URI::Escape;
use Text::CSV;


## Bluepay20post default fields ##
my $URL = 'https://secure.bluepay.com/interfaces/bpdailyreport';


=head1 NAME

Bluepay::Bluepay20DailyReport

=head1 VERSION

Version: 0.15
April 2008

=head1 SYNOPSIS

Bluepay::Bluepay20DailyReport - The BluePay 2.0 Daily Report interface

=head1 DESCRIPTION

Bluepay::Bluepay20DailyReport is a Perl based implementation for interaction with the 
Bluepay 2.0 Daily Report interface.  The Bluepay 2.0 Daily Report interface is intended 
to be polled by a merchant on a daily basis, to get updates on VOID/DECLINED/SETTLED 
status for transactions on the day prior.  Bluepay20DailyReport interface has been 
developed on Windows XP, but should work on any OS where Perl is installed.

=head1 RUNNING Bluepay::Bluepay20DailyReport

	use Bluepay::Bluepay20DailyReport;

	# Create the object
	my $bp20Obj = Bluepay::Bluepay20DailyReport->new();

	# Populate fields for tx
	$bp20Obj->{ACCOUNT_ID} = "myaccountid";
	$bp20Obj->{SECRET_KEY} = 'mysecretkey';
	$bp20Obj->{REPORT_START_DATE} = "2008-05-01";	# These are the dates within which transactions will be reported.
	$bp20Obj->{REPORT_END_DATE} = "2008-05-02";
	$bp20Obj->{PAYMENT_TYPE} = 'ACH';	# ACH or CREDIT

	# Post data to retrieve tx results
	my $postResults = $bp20Obj->post();

	# If result is array, SUCCESS
	if(ref($postResults) eq 'ARRAY') {
		foreach my $result (@$postResults) {
			print "Tx Info: " . $result->{id} . "\n";
			while ( my ($key, $value) = each(%$result) ) {
			    print "$key => $value\n";
			}
			print "\n";
		}
	}
	# ELSE, print error
	else { print "$postResults\n"; }	

=head1 METHODS

=head2 new

Creates a new instance of a Bluepay::Bluepay20DailyReport object

=cut

# New
sub new  { 
	my $class = shift;
    my $self  = {};         # allocate new hash for object
    bless($self, $class);
       
    # Set defaults
    $self->{URL} = $URL;
       
	# return object
    return $self;
}

=head2 post

Posts the data to the Bluepay::Bluepay20post interface

=cut

sub post {
    my $self = shift; 
    
    ## Create TAMPER_PROOF_SEAL:
	# TAMPER_PROOF_SEAL - And md5 hash used to verify the request.  This md5 should be generated as follows:
	#  1) Create a string consisting of your Bluepay SECRET_KEY, ACCOUNT_ID, and the REPORT_START_DATE 
	#  and REPORT_END_DATE concatenated together.  For example: 
	#  "ABCDABCDABCDABCDABCDABCD1234123412342006-08-082006-08-09"
	#  2) Calculate the md5 of the string created in step 1.
	#  3) Convert the md5 to hexadecimal encoding, if necessary.  At this point it should
	#  be exactly 32 characters in length.
	#  4) Submit the hexadecimal md5 with your request, with the name "TAMPER_PROOF_SEAL".
	my $TAMPER_PROOF_DATA = ($self->{SECRET_KEY} || '') . ($self->{ACCOUNT_ID} || '') 
		. ($self->{REPORT_START_DATE} || '') . ($self->{REPORT_END_DATE} || '');
	my $TAMPER_PROOF_SEAL = md5_hex $TAMPER_PROOF_DATA;;
  
    # Create request (encode)
    my $request = $self->{URL} . "\?TAMPER_PROOF_SEAL=" . uri_escape($TAMPER_PROOF_SEAL || '');	
	while ( my ($key, $value) = each(%$self) ) { 
		if ($key eq 'SECRET_KEY') { next; }  $request .= "&$key=" . uri_escape($value || ''); 
	}

    # Create Agent
    my $ua = new LWP::UserAgent;
    #my $response = $ua->post("$request"); #OLD
    my $response = $ua->get("$request");
    my $content = $response->content;
    chomp $content;
    
    # Parse Response
    my @rptResponse;  my $rptPos = 0;  my $rowPos = 0;  my @columns;
	my @records = split(/\n/, $content);  my $numberOfACHs = 0;
	my $csv = Text::CSV->new;
	foreach my $record (@records) {
		chomp $record;

		if ($csv->parse($record)) {
			my %reportRepsonseHash;
			my @fields = $csv->fields;
			my $fieldPos = 0;
			if ($rowPos == 0) { @columns = @fields;  $rowPos++;  next; }
			for my $field (@fields) {
				my $colName = $columns[$fieldPos];
				$reportRepsonseHash{$colName} = $field || "";  $fieldPos++;
			}
			$rptResponse[$rptPos] = \%reportRepsonseHash;  $rptPos++;
		}
		else { return $csv->error_input . ' - ' . $content; }	# Return CSV error
	}
        
    # Return
    if ($rowPos == 1 and length(@columns) == 1) { return $content; }	# If nothing parsed, print error
    return \@rptResponse;
}

=head1 MODULES
 
This script has some dependencies that need to be installed before it
can run.  You can use cpan to install the modules.  They are:
 - Digest::MD5
 - LWP::UserAgent
 - URI::Escape
 - Text::CSV

=head1 AUTHOR

The Bluepay::Bluepay20DailyReport perl module was written by Christopher Kois <ckois@bluepay.com>.

=head1 COPYRIGHTS

	The Bluepay::Bluepay20DailyReport package is Copyright (c) April, 2008 by BluePay, Inc. 
	http://www.bluepay.com All rights reserved.  You may distribute this module under the terms 
	of GNU General Public License (GPL). 
	
Module Copyrights:
 - The Digest::MD5 module is Copyright (c) 1998-2003 Gisle Aas.
	Available at: http://search.cpan.org/~gaas/Digest-MD5-2.36/MD5.pm
 - The LWP::UserAgent module is Copyright (c) 1995-2008 Gisle Aas.
	Available at: http://search.cpan.org/~gaas/libwww-perl-5.812/lib/LWP/UserAgent.pm
 - The URI::Escape module is Copyright (c) 1995-2004 Gisle Aas.
	Available at: http://search.cpan.org/~gaas/URI-1.36/URI/Escape.pm
 - The Text::CSV module is Copyright (c) 2007-2008 Makamaka Hannyaharamitu.
	Available at: http://search.cpan.org/~makamaka/Text-CSV-1.04/lib/Text/CSV.pm
				
NOTE: Each of these modules may have other dependencies.  The modules listed here are
the modules that Bluepay::Bluepay20DailyReport specifically references.

=head1 SUPPORT/WARRANTY

Bluepay::Bluepay20DailyReport is free Open Source software.  This code is Free.  You may use it, modify it, 
redistribute it, post it on the bathroom wall, or whatever.  If you do make modifications that are 
useful, Bluepay would love it if you donated them back to us!

=head1 KNOWN BUGS:

This is version 0.15 of Bluepay::Bluepay20DailyReport.  There are currently no known bugs.

=cut

1;
