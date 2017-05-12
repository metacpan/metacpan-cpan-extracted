package BGPmon::Translator::XFB2BGPdump;
our $VERSION = '2.0';

use 5.14.0;
use strict;
use warnings;
#use XML::LibXML;
use BGPmon::Translator::XFB2PerlHash;

use Data::Dumper;

require Exporter;
our $AUTOLOAD;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(translate_message translate_msg get_error_code 
                    get_error_message get_error_msg);

# Private variables
our $initialized = 0;
our $base_str;

# Variables for libxml use.
our $xml_schema;
our $parser;
our $context;

# Variables for error checking and reporting.
my %error_code;
my %error_msg;

# Error messages
use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MESSAGE => 'No error.';
use constant NO_MSG_ERROR => 701;
use constant NO_MSG_MESSAGE => 
  'XML to BGPdump translator did not get a xml message';
use constant PARSER_CREATE_FAIL_CODE => 702;
use constant PARSER_CREATE_FAIL_MESSAGE => 
  'Error creating parser in XML to BGPdump translator';
use constant INCOMPLETE_MSG_CODE => 703;
use constant INCOMPLETE_MSG_MESSAGE => 
  'XML to BGPdump translator did not receive a complete XML message.';
use constant MSG_PARSE_CODE => 704;
use constant MSG_PARSE_MESSAGE => 'Error parsing XML message.';
use constant NOT_UPDATE_OR_TABLE_MSG_CODE => 705;
use constant NOT_UPDATE_OR_TABLE_MSG_MESSAGE => 
  'Received message is not an UPDATE message.';
use constant NO_TIMESTAMP_CODE => 706;
use constant NO_TIMESTAMP_MESSAGE => 
  'Received message does not have a timestamp.';
use constant NO_PEER_ORIGIN_AS_CODE => 707;
use constant NO_PEER_ORIGIN_AS_MESSAGE => 
  'Received message does not have a peer origin AS.';
use constant NO_AS_PATH_CODE => 711;
use constant NO_AS_PATH_MESSAGE => 
  'Received message that does not have an AS_PATH';
use constant NO_PEER_ADDRESS_CODE => 708;
use constant NO_PEER_ADDRESS_MESSAGE => 
  'Received message does not have a peer address.';
use constant BAD_NLRI_AFI_SAFI_CODE => 709;
use constant BAD_NLRI_AFI_SAFI_MESSAGE => 
  'Bad AFI and SAFI values in NLRI section. Should be IPV4/UNICAST.';
use constant BAD_WITHDRAWN_AFI_SAFI_CODE => 710;
use constant BAD_WITHDRAWN_AFI_SAFI_MESSAGE => 
  'Bad AFI and SAFI values in WITHDRAWN section. Should be IPV4/UNICAST.';
use constant ARGUMENT_ERROR_CODE => 797;
use constant ARGUMENT_ERROR_MESSAGE => 'Invalid number of arguments.';
use constant INVALID_FUNCTION_SPECIFIED_CODE => 798;
use constant INVALID_FUNCTION_SPECIFIED_MESSAGE => 
  'Invalid function name specified.';
use constant UNKNOWN_ERROR_CODE => 799;
use constant UNKNOWN_ERROR_MSG => 'Unknown error occurred.';

$error_code{'translate_message'} = NO_ERROR_CODE;
$error_msg{'translate_message'} = NO_ERROR_MESSAGE;

=head1 NAME

BGPmon::Translator::XFB2BGPdump - Converts an XML message into an array of 
BGPdump formatted messages.

=head1 SYNOPSIS

This module takes a XML message as input and outputs a string in 
libbgpdump format.

use BGPmon::Translator::XFB2BGPdump;

my %bgpdump_strs = translate_msg ($xml_message);

foreach my $safi (sort{$a <= $b} keys %bgpdump_strs) {

  print "Printing bgpdump lines for prefixes with safi value $safi\n";

  my @safi_lines = @{$bgpdump_strs{$safi}};
	
  foreach my $bgpdump_line (@safi_lines) {
		
    print "$bgpdump_line\n";
	
  }

}


=head1 EXPORT

translate_message
translate_msg
get_error_code
get_error_message
get_error_msg

=head1 SUBROUTINES/METHODS

=head2 translate_message

This function accepts exactly one XML message and returns a hash of arrays, 
indexed by SAFI values. Each array contains bgpdump formatted strings for the 
SAFI value.

Inputs:
1. xmlmessage : Exactly one XML message.

Outputs:
1. Returns a hash of arrays, indexed by SAFI values.  Each array contains
bgpdump formatted strings for the SAFI value.

=cut

sub translate_message {
	my $xml_msg = shift;

	# Output hash.
	#my %output;
	my $output = [];

	# Set the error code to NO_ERROR initially.
	$error_code{'translate_message'} = NO_ERROR_CODE;
	$error_msg{'translate_message'} = NO_ERROR_MESSAGE;

	# Get XML message from arguments
	unless (defined($xml_msg)) {
		$error_code{'translate_message'} = NO_MSG_ERROR;
		$error_msg{'translate_message'} = NO_MSG_MESSAGE;
		#return %output;
		return undef;
	}

	# Check if we have a complete XML message
	if ($xml_msg !~ /<BGP_MONITOR_MESSAGE.*?BGP_MONITOR_MESSAGE>/) {
		$error_code{'translate_message'} = INCOMPLETE_MSG_CODE;
		$error_msg{'translate_message'} = INCOMPLETE_MSG_MESSAGE;
		#return %output;
		return undef;
	}

	# Parse XML message and check if valid.
	my $doc = BGPmon::Translator::XFB2PerlHash::translate_msg($xml_msg);
	if(BGPmon::Translator::XFB2PerlHash::get_error_code('translate_msg') != 0){
		$error_code{'translate_message'} = MSG_PARSE_CODE;
		$error_msg{'translate_message'} = MSG_PARSE_MESSAGE;
		#return %output;
		return undef;
	}
	# TODO: add validation


	# Start parsing out message elements.

	# Check if message is from a live stream or a table dump
	my $collection = BGPmon::Translator::XFB2PerlHash::get_content(
    "/BGP_MONITOR_MESSAGE/COLLECTION/content");

	if (!defined($collection) or 
    ($collection ne "LIVE" and $collection ne "TABLE_DUMP")) {
		$error_code{'translate_message'} = NOT_UPDATE_OR_TABLE_MSG_CODE;
		$error_msg{'translate_message'} = NOT_UPDATE_OR_TABLE_MSG_MESSAGE;
		#return %output;
		return undef;
	}

	# Get the timestamp.
	my $ts = BGPmon::Translator::XFB2PerlHash::get_content(
    "/BGP_MONITOR_MESSAGE/OBSERVED_TIME/TIMESTAMP/content");
	if (!defined($ts)) {
		$error_code{'translate_message'} = NO_TIMESTAMP_CODE;
		$error_msg{'translate_message'} = NO_TIMESTAMP_MESSAGE;
		#return %output;
		return undef;
	}

	# Set the base string. This is the beginning of each output string.
	$base_str = "";
	if($collection eq "LIVE"){
		$base_str = "BGP4MP|$ts";
	} elsif ($collection eq "TABLE_DUMP"){
		$base_str = "TABLE_DUMP2|$ts";
	}

	# Get the peer origin AS.
	my $src_as = BGPmon::Translator::XFB2PerlHash::get_content(
    "/BGP_MONITOR_MESSAGE/SOURCE/ASN2/content");
	$src_as = BGPmon::Translator::XFB2PerlHash::get_content(
    "/BGP_MONITOR_MESSAGE/SOURCE/ASN4/content") if(!defined($src_as));
	unless (defined($src_as)) {
		$error_code{'translate_message'} = NO_PEER_ORIGIN_AS_CODE;
		$error_msg{'translate_message'} = NO_PEER_ORIGIN_AS_MESSAGE;
		#return %output;
		return undef;
	}

	# Get the peer address.
	my $src_addr = BGPmon::Translator::XFB2PerlHash::get_content(
    "/BGP_MONITOR_MESSAGE/SOURCE/ADDRESS/content");
	unless ($src_addr) {
		$error_code{'translate_message'} = NO_PEER_ADDRESS_CODE;
		$error_msg{'translate_message'} = NO_PEER_ADDRESS_MESSAGE;
		#return %output;
		return undef;
	}

	# Get AS_PATH
	my $as_path = "";
	my $ashash = BGPmon::Translator::XFB2PerlHash::get_content(
    "/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:AS_PATH/bgp:AS_SEQUENCE/bgp:ASN4/");
	$ashash = BGPmon::Translator::XFB2PerlHash::get_content(
    "/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:AS_PATH/bgp:AS_SEQUENCE/bgp:ASN2/") 
    if not defined $ashash;
	if(defined($ashash)){
		if(ref($ashash) eq "HASH"){
			$as_path = join(" ", $as_path, $ashash->{'content'});
		}
		elsif(ref($ashash) eq "ARRAY"){
			my @as_arr = @$ashash;
			foreach(@as_arr){
				$as_path = join(" ", $as_path, $_->{'content'});
			}
		}
	}
	# Remove trailing whitespace from AS PATH.
	$as_path =~ s/^\s+//;

	# Get IPv4 announced list.
	my $pref_arr = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:NLRI/');
	if(defined($pref_arr)){

		my @pr = ();
		if(ref($pref_arr) eq "HASH"){
			push(@pr, $pref_arr);
		}
		elsif(ref($pref_arr) eq "ARRAY"){
			@pr = (@pr, @$pref_arr);
		}


		foreach my $prefix (@pr) {
			# Get prefix and afi
			my $addr = $prefix->{'content'};
			my $afi = $prefix->{'afi'};

			# In the NLRI section, AFI should be IPV4 always.
			if ($afi ne '1') {
				$error_code{'translate_message'} = BAD_NLRI_AFI_SAFI_CODE;
				$error_msg{'translate_message'} = BAD_NLRI_AFI_SAFI_MESSAGE;
				return undef;
			}
			write_out_line(as_path => $as_path,
					pref => $addr,
					peer_ip => $src_addr,
					type => "A",
					src_as => $src_as,
					#op => \%output);
					op => $output);
		}
	}

	# Get IPv4 withdrawn list.
	my $pref_arr_w = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:WITHDRAW/');
	if(defined($pref_arr_w)){


		my @pr = ();
		if(ref($pref_arr_w) eq "HASH"){
			push(@pr, $pref_arr_w);
		}
		elsif(ref($pref_arr_w) eq "ARRAY"){
			@pr = (@pr, @$pref_arr_w);
		}

		foreach my $prefix (@pr) {
			# Get prefix, afi and safi
			my $addr = $prefix->{'content'};
			my $afi = $prefix->{'afi'};

			# In the WITHDRAWN section, AFI should be IPV4 always.
			if ($afi ne '1') {
				$error_code{'translate_message'} = BAD_WITHDRAWN_AFI_SAFI_CODE;
				$error_msg{'translate_message'} = BAD_WITHDRAWN_AFI_SAFI_MESSAGE;
				next;
			}
			write_out_line(pref => $addr,
					peer_ip => $src_addr,
					type => "W",
					src_as => $src_as,
					op => $output);
		}
	}

	# Get IPv6 announced list.
	my $pref_arr_six = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:MP_REACH_NLRI/bgp:MP_NLRI/');
	if(defined($pref_arr_six)){

		my @pr = ();
		if(ref($pref_arr_six) eq "HASH"){
			push(@pr, $pref_arr_six);
		}
		elsif(ref($pref_arr_six) eq "ARRAY"){
			@pr = (@pr, @$pref_arr_six);
		}

		foreach my $prefix (@pr) {
			# Get prefix, afi 
			my $addr = $prefix->{'content'};
			my $afi = $prefix->{'afi'};

			write_out_line(as_path => $as_path,
					pref => $addr,
					peer_ip => $src_addr,
					type => "A",
					src_as => $src_as,
					#op => \%output);
					op => $output);
		}
	}

	# Get IPv6 withdrawn list.
	my $pref_arr_sixw = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:MP_UNREACH_NLRI/bgp:MP_NLRI/');
	if(defined($pref_arr_sixw)){

		my @pr = ();
		if(ref($pref_arr_sixw) eq "HASH"){
			push(@pr, $pref_arr_sixw);
		}
		elsif(ref($pref_arr_sixw) eq "ARRAY"){
			@pr = (@pr, @$pref_arr_sixw);
		}

		foreach my $prefix (@pr) {
			# Get prefix, afi
			my $addr = $prefix->{'content'};
			my $afi = $prefix->{'afi'};

			write_out_line(pref => $addr,
					peer_ip => $src_addr,
					type => "W",
					src_as => $src_as,
					#op => \%output);
					op => $output);
		}
	}

	# Return the output hash.
	#return %output;
	return $output;
}

=head2 translate_msg

Shorthand call for translate_message.

=cut
sub translate_msg {
	my $msg = shift;
	return translate_message($msg);
}

=head2 get_error_code

Get the error code for a given function
Input : the name of the function whose error code we should report
Output: the function's error code
or ARGUMENT_ERROR if the user did not supply a function
or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function
Usage:  my $err_code = get_error_code("connect_archive");

=cut
sub get_error_code {
	my $function = shift;
	unless (defined $function) {
		return ARGUMENT_ERROR_CODE;
	}

	return $error_code{$function} if (defined $error_code{$function});
	return INVALID_FUNCTION_SPECIFIED_CODE;
}

=head2 get_error_message {

	Get the error message of a given function
		Input : the name of the function whose error message we should report
		Output: the function's error message
		or ARGUMENT_ERROR if the user did not supply a function
		or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function
		Usage:  my $err_msg = get_error_message("read_xml_message");

=cut
		sub get_error_message {
			my $function = shift;
			unless (defined $function) {
				return ARGUMENT_ERROR_MESSAGE;
			}

			return $error_msg{$function} if (defined $error_msg{$function});
			return INVALID_FUNCTION_SPECIFIED_MESSAGE;
		}

=head2 get_error_msg

		Shorthand call for get_error_message

=cut

		sub get_error_msg{
			my $fname = shift;
			return get_error_message($fname);
		}

# Private functions.

## Write an output line to the appropriate output array
	sub write_out_line {
		my %args = @_;

		my $as_path = "";
		if ($args{as_path}) {
			$as_path = $args{as_path};
		}

		my $safi = 1;
#    if ($args{safi}) {
#        $safi = $args{safi};
#    }

		my $type = $args{type};
		my $pref = $args{pref};
		my $peer_ip = $args{peer_ip};
		my $src_as = $args{src_as};
		my $op = $args{op};

		# Check if msg is UNICAST. If it is, 
    # push to output array in hash with key = 1
		my $line = join("|", $base_str, $type, $peer_ip, $src_as, $pref, $as_path);

		# Remove trailing '|' at the end of withdrawn messages.
		if ($type eq "W") {
			chop($line);
		}

		#push(@{$op->{$safi}}, $line);
		push(@$op, $line);
	}



=head1 BUGS

		Please report any bugs or feature requests to 
    C<bgpmon at netsec.colostate.edu>, or through	the web interface at 
    L<http://bgpmon.netsec.colostate.edu>.


=head1 SUPPORT

		You can find documentation for this module with the perldoc command.

		perldoc BGPmon::Client

=cut
=head1 LICENSE AND COPYRIGHT
		Copyright (c) 2012 Colorado State University

		Permission is hereby granted, free of charge, to any person
		obtaining a copy of this software and associated documentation
		files (the "Software"), to deal in the Software without
		restriction, including without limitation the rights to use,
		copy, modify, merge, publish, distribute, sublicense, and/or
			sell copies of the Software, and to permit persons to whom
			the Software is furnished to do so, subject to the following
			conditions:

			The above copyright notice and this permission notice shall be
			included in all copies or substantial portions of the Software.

			THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
			OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
			NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
			HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
		WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
			FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
			OTHER DEALINGS IN THE SOFTWARE.


			File: XFB2BGPdump.pm
			
      Authors: M. Lawrence Weikum, Kaustubh Gadkari, Dan Massey, Cathie Olschanowsky
			
      Date: 13 October 2013
=cut
1;
