package BGPmon::Translator::XFB2BGPdump;
our $VERSION = '1.092';

use 5.006;
use strict;
use warnings;
use XML::LibXML;

require Exporter;
our $AUTOLOAD;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(translate_message translate_msg get_error_code get_error_message get_error_msg);

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
use constant NO_MSG_MESSAGE => 'XML to BGPdump translator did not get a xml message';
use constant PARSER_CREATE_FAIL_CODE => 702;
use constant PARSER_CREATE_FAIL_MESSAGE => 'Error creating parser in XML to BGPdump translator';
use constant INCOMPLETE_MSG_CODE => 703;
use constant INCOMPLETE_MSG_MESSAGE => 'XML to BGPdump translator did not receive a complete XML message.';
use constant MSG_PARSE_CODE => 704;
use constant MSG_PARSE_MESSAGE => 'Error parsing XML message.';
use constant NOT_UPDATE_OR_TABLE_MSG_CODE => 705;
use constant NOT_UPDATE_OR_TABLE_MSG_MESSAGE => 'Received message is not an UPDATE message.';
use constant NO_TIMESTAMP_CODE => 706;
use constant NO_TIMESTAMP_MESSAGE => 'Received message does not have a timestamp.';
use constant NO_PEER_ORIGIN_AS_CODE => 707;
use constant NO_PEER_ORIGIN_AS_MESSAGE => 'Received message does not have a peer origin AS.';
use constant NO_PEER_ADDRESS_CODE => 708;
use constant NO_PEER_ADDRESS_MESSAGE => 'Received message does not have a peer address.';
use constant BAD_NLRI_AFI_SAFI_CODE => 709;
use constant BAD_NLRI_AFI_SAFI_MESSAGE => 'Bad AFI and SAFI values in NLRI section. Should be IPV4/UNICAST.';
use constant BAD_WITHDRAWN_AFI_SAFI_CODE => 710;
use constant BAD_WITHDRAWN_AFI_SAFI_MESSAGE => 'Bad AFI and SAFI values in WITHDRAWN section. Should be IPV4/UNICAST.';
use constant ARGUMENT_ERROR_CODE => 797;
use constant ARGUMENT_ERROR_MESSAGE => 'Invalid number of arguments.';
use constant INVALID_FUNCTION_SPECIFIED_CODE => 798;
use constant INVALID_FUNCTION_SPECIFIED_MESSAGE => 'Invalid function name specified.';
use constant UNKNOWN_ERROR_CODE => 799;
use constant UNKNOWN_ERROR_MSG => 'Unknown error occurred.';

$error_code{'translate_message'} = NO_ERROR_CODE;
$error_msg{'translate_message'} = NO_ERROR_MESSAGE;

=head1 NAME

BGPmon::Translator::XFB2BGPdump - Converts an XML message into an array of BGPdump formatted messages.

=head1 SYNOPSIS
This module takes a XML message as input and outputs a string in libbgpdump format.

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

This function accepts exactly one XML message and returns a hash of arrays, indexed
by SAFI values. Each array contains bgpdump formatted strings for the SAFI value.
Inputs:
    1. xmlmessage : Exactly one XML message.
Outputs:
    1. Returns a hash of arrays, indexed by SAFI values.  Each array contains
    bgpdump formatted strings for the SAFI value.

=cut

sub translate_message {
    my $xml_msg = shift;

    # Output hash.
    my %output;

    # Set the error code to NO_ERROR initially.
    $error_code{'translate_message'} = NO_ERROR_CODE;
    $error_msg{'translate_message'} = NO_ERROR_MESSAGE;

    # Get XML message from arguments
    unless (defined($xml_msg)) {
        $error_code{'translate_message'} = NO_MSG_ERROR;
        $error_msg{'translate_message'} = NO_MSG_MESSAGE;
        return %output;
    }

    # if we have not already -- initialize the parser
    unless ($initialized) {
        #TODO: add in xsd validation
        # Create the parser
        $parser = XML::LibXML->new();
        $context = XML::LibXML::XPathContext->new;
        $context->registerNs('x', 'urn:ietf:params:xml:ns:xfb-0.4');
        if (!defined $parser) {
            $error_code{'translate_message'} = PARSER_CREATE_FAIL_CODE;
            $error_msg{'translate_message'} = PARSER_CREATE_FAIL_MESSAGE;
            return %output;
        }
        $initialized = 1;
    }

    # Check if we have a complete XML message
    if ($xml_msg !~ /<BGP_MESSAGE.*?BGP_MESSAGE>/) {
        $error_code{'translate_message'} = INCOMPLETE_MSG_CODE;
        $error_msg{'translate_message'} = INCOMPLETE_MSG_MESSAGE;
        return %output;
    }

    # Parse XML message and check if valid.
    # TODO: add validation
    my $doc;
    eval {
        $doc = $parser->parse_string($xml_msg);
    };

    if ($@) {
        $error_code{'translate_message'} = MSG_PARSE_CODE;
        $error_msg{'translate_message'} = MSG_PARSE_MESSAGE;
        return %output;
    }

    my $bgp_message = $doc->getDocumentElement;

    # Start parsing out message elements.
    # The Xpaths used are adopted from code originally written by Joe Gersch.

    # Check if message is an UPDATE message
    my $msg_type = $bgp_message->findvalue('@type');

    if ($msg_type ne "UPDATE" && $msg_type ne "TABLE") {
        $error_code{'translate_message'} = NOT_UPDATE_OR_TABLE_MSG_CODE;
        $error_msg{'translate_message'} = NOT_UPDATE_OR_TABLE_MSG_MESSAGE;
        return %output;
    }

    # Get the timestamp.
    my $ts = $context->find('/x:BGP_MESSAGE/x:TIME/@timestamp', $doc);
    if (!$ts) {
        $error_code{'translate_message'} = NO_TIMESTAMP_CODE;
        $error_msg{'translate_message'} = NO_TIMESTAMP_MESSAGE;
        return %output;
    }

    # Set the base string. This is the beginning of each output string.
    $base_str = "";
    if ($msg_type eq "UPDATE") {
        $base_str = "BGP4MP|$ts";
    } elsif ($msg_type eq "TABLE") {
        $base_str = "TABLE_DUMP2|$ts";
    }

    # Get the peer origin AS.
    my $src_as = $context->findvalue('x:BGP_MESSAGE/x:PEERING/x:SRC_AS', $doc);
    unless ($src_as) {
        $error_code{'translate_message'} = NO_PEER_ORIGIN_AS_CODE;
        $error_msg{'translate_message'} = NO_PEER_ORIGIN_AS_MESSAGE;
        return %output;
    }

    # Get the peer address.
    my $src_addr = $context->findvalue('x:BGP_MESSAGE/x:PEERING/x:SRC_ADDR/x:ADDRESS', $doc);
    unless ($src_addr) {
        $error_code{'translate_message'} = NO_PEER_ADDRESS_CODE;
        $error_msg{'translate_message'} = NO_PEER_ADDRESS_MESSAGE;
        return %output;
    }

    # Get AS_PATH
    my @as_arr = $context->findnodes('x:BGP_MESSAGE/x:ASCII_MSG/x:UPDATE/x:PATH_ATTRIBUTES/x:ATTRIBUTE/x:AS_PATH/x:AS_SEG/x:AS', $doc);
    my $as_path = "";
    foreach my $as (@as_arr) {
        $as_path = join(" ", $as_path, $as->to_literal);
    }
    # Remove trailing whitespace from AS PATH.
    $as_path =~ s/^\s+//;

    # Get IPv4 announced list.
    my @pref_arr = $context->findnodes('x:BGP_MESSAGE/x:ASCII_MSG/x:UPDATE/x:NLRI/x:PREFIX', $doc);
    foreach my $prefix (@pref_arr) {
        # Get prefix, afi and safi
        my ($addr, $afi, $safi) = get_addr_afi_safi($prefix);

        # In the NLRI section, AFI and SAFI should be IPV4/UNICAST always.
        if ($afi != 1 || $safi != 1) {
            $error_code{'translate_message'} = BAD_NLRI_AFI_SAFI_CODE;
            $error_msg{'translate_message'} = BAD_NLRI_AFI_SAFI_MESSAGE;
            next;
        }
        write_out_line(as_path => $as_path,
            safi => $safi, pref => $addr,
            peer_ip => $src_addr,
            type => "A",
            src_as => $src_as,
            op => \%output);
    }

    # Get IPv4 withdrawn list.
    @pref_arr = $context->findnodes('x:BGP_MESSAGE/x:ASCII_MSG/x:UPDATE/x:WITHDRAWN/x:PREFIX', $doc);
    foreach my $prefix (@pref_arr) {
        # Get prefix, afi and safi
        my ($addr, $afi, $safi) = get_addr_afi_safi($prefix);

        # In the WITHDRAWN section, AFI and SAFI should be IPV6/UNICAST always.
        if ($afi != 1 || $safi != 1) {
            $error_code{'translate_message'} = BAD_WITHDRAWN_AFI_SAFI_CODE;
            $error_msg{'translate_message'} = BAD_WITHDRAWN_AFI_SAFI_MESSAGE;
            next;
        }
        write_out_line(safi => $safi,
            pref => $addr,
            peer_ip => $src_addr,
            type => "W",
            src_as => $src_as,
            op => \%output);
    }

    # Get IPv6 announced list.
    @pref_arr = $context->findnodes('x:BGP_MESSAGE/x:ASCII_MSG/x:UPDATE/x:PATH_ATTRIBUTES/x:ATTRIBUTE/x:MP_REACH_NLRI/x:NLRI/x:PREFIX', $doc);
    foreach my $prefix (@pref_arr) {
        # Get prefix, afi and safi
        my ($addr, $afi, $safi) = get_addr_afi_safi($prefix);
        write_out_line(as_path => $as_path,
            safi => $safi,
            pref => $addr,
            peer_ip => $src_addr,
            type => "A",
            src_as => $src_as,
            op => \%output);
    }

    # Get IPv6 withdrawn list.
    @pref_arr = $context->findnodes('x:BGP_MESSAGE/x:ASCII_MSG/x:UPDATE/x:PATH_ATTRIBUTES/x:ATTRIBUTE/x:MP_UNREACH_NLRI/x:WITHDRAWN/x:PREFIX', $doc);
    foreach my $prefix (@pref_arr) {
        # Get prefix, afi and safi
        my ($addr, $afi, $safi) = get_addr_afi_safi($prefix);
        write_out_line(safi => $safi,
            pref => $addr,
            peer_ip => $src_addr,
            type => "W",
            src_as => $src_as,
            op => \%output);
    }

    # Return the output hash.
    return %output;
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

    my $safi;
    if ($args{safi}) {
        $safi = $args{safi};
    }

    my $type = $args{type};
    my $pref = $args{pref};
    my $peer_ip = $args{peer_ip};
    my $src_as = $args{src_as};
    my $op = $args{op};

    # Check if message is a UNICAST message. If it is, push to output array in hash with key = 1
    my $line = join("|", $base_str, $type, $peer_ip, $src_as, $pref, $as_path);

    # Remove trailing '|' at the end of withdrawn messages.
    if ($type eq "W") {
        chop($line);
    }

    push(@{$op->{$safi}}, $line);
}

# Helper function to get a prefix's address, AFI and SAFI
sub get_addr_afi_safi {
    my $prefix = shift;
    my @addr_arr = $prefix->getElementsByTagName('ADDRESS');
    my @afi_arr = $prefix->getElementsByTagName('AFI');
    my @safi_arr = $prefix->getElementsByTagName('SAFI');

    # We can do the array indexing since each prefix element can have only one
    # address, afi and safi value.
    # Should we do a sanity check and see if there are more than one
    # address, afi or safis?

    my $addr = $addr_arr[0]->textContent;
    my $afi = $afi_arr[0]->getAttribute('value');
    my $safi = $safi_arr[0]->getAttribute('value');

    # Convert afi and safi values to integers.
    $afi = int($afi);
    $safi = int($safi);
    return ($addr, $afi, $safi);
}


=head1 AUTHOR

Kaustubh Gadkari, C<< <kaustubh at cs.colostate.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bgpmon at netsec.colostate.edu>, or through
the web interface at L<http://bgpmon.netsec.colostate.edu>.


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
  Authors: Kaustubh Gadkari, Dan Massey, Cathie Olschanowsky
  Date: August 3, 2012
=cut
1;
