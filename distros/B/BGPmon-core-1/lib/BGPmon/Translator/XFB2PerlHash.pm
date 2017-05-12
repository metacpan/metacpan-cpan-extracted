package BGPmon::Translator::XFB2PerlHash;

use 5.006;
use strict;
use warnings;
use XML::LibXML::Simple;
use Data::Dumper;

BEGIN{
require Exporter;
    our $AUTOLOAD;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(translate_msg toString get_content reset get_error_code get_error_message get_error_msg);
    our $VERSION = '1.092';
}

#Variable to hold both the original as well as the converted XML
my $raw_xml = '';
my $xml_hashref = {};

#Variables to hold error codes and messages
my %error_code;
my %error_msg;
my @function_names = ('translate_msg', 'toString', 'get_content');

use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG => 'No Error. Life is good.';
use constant NO_MESSAGE_CODE => 601;
use constant NO_MESSAGE_MSG => 'No XML message provided';
use constant UNDEFINED_ARGUMENT_CODE => 602;
use constant UNDEFINED_ARGUMENT_MSG => 'Undefined argument';
use constant INVALID_FUNCTION_SPECIFIED_CODE => 603;
use constant INVALID_FUNCTION_SPECIFIED_MSG => 'Invalid Function Name Specified';
use constant PARSER_ERROR_CODE => 604;
use constant PARSER_ERROR_MSG => 'XML Parser Error';
use constant NO_SUCH_INFORMATION_CODE => 605;
use constant NO_SUCH_INFORMATION_MSG => 'No such element/attribute exists';

for my $function_name (@function_names) {
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
}

=head1 NAME

BGPmon::Translator::XFB2PerlHash - convert an XFB message into a Perl hash

This module converts an XML message to a nested hash data structure
and provides an interface to get a stringified representation of
the data structure as well as the ability to extract individual subtrees
from the nested structure.

=head1 SYNOPSIS

use BGPmon::Translator::XFB2PerlHash;

 my $string = '<BGP_MESSAGE length="00002243" version="0.4" 
xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" 
type="UPDATE"><BGPMON_SEQ id="0" seq_num="744909286"/><TIME 
timestamp="1336133702" datetime="2012-05-04T12:15:02Z" precision_time="0"/
><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>2600:803::15</ADDRESS><AFI 
value="2">IPV6</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>701</
SRC_AS><DST_ADDR><ADDRESS>127.0.0.1</ADDRESS><AFI value="1">IPV4</AFI></
DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>6447</DST_AS><BGPID>0.0.0.0</BGPID></
PEERING><ASCII_MSG length="110"><MARKER 
length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" 
path_attr_len="87"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="5"><ATTRIBUTE 
length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN 
value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="26"><FLAGS 
transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG 
type="AS_SEQUENCE" length="6"><AS>701</AS><AS>12702</AS><AS>286</AS><AS>3549</
AS><AS>35994</AS><AS>35994</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE 
length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE 
value="7">AGGREGATOR</TYPE><AGGREGATOR><AS>0</AS><ADDR>192.8.8.2</ADDR></
AGGREGATOR></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" 
transitive="TRUE"/><TYPE value="8">COMMUNITIES</
TYPE><COMMUNITIES><COMMUNITY><AS>701</AS><VALUE>333</VALUE></
COMMUNITY><COMMUNITY><AS>701</AS><VALUE>1020</VALUE></COMMUNITY></
COMMUNITIES></ATTRIBUTE><ATTRIBUTE length="28"><FLAGS optional="TRUE" 
extended="TRUE"/><TYPE value="14">MP_REACH_NLRI</TYPE><MP_REACH_NLRI><AFI 
value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI><NEXT_HOP_LEN>16</
NEXT_HOP_LEN><NEXT_HOP><ADDRESS>2600:803::15</ADDRESS></NEXT_HOP><NLRI 
count="1"><PREFIX label="DANN"><ADDRESS>2001:450:2030::/48</ADDRESS><AFI 
value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></
MP_REACH_NLRI></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="0"/></UPDATE></
ASCII_MSG><OCTET_MSG><OCTETS 
length="110">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF006E02000000574001010040021A02060
00002BD0000319E0000011E00000DDD00008C9A00008C9AC0070800008C9AADDEE9FEC0080802B
D014D02BD03FC900E001C00020110260008030000000000000000000000150030200104502030
</OCTETS></OCTET_MSG></BGP_MESSAGE>';

my %hash = translate_msg($string);  #Converts and internally saves the message

print toString();   #pretty-prints the data

my $result = get_content('/BGP_MESSAGE/ASCII_MSG/MARKER/content');

print $$result;     #Would print 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'

$result = get_content
('/BGP_MESSAGE/ASCII_MSG/UPDATE/PATH_ATTRIBUTES/ATTRIBUTE/MP_REACH_NLRI/PREFIX');

print $res->{'ADDRESS'}->{'content'} foreach $res (@$result);

$result = get_content('/BGP_MESSAGE/PEERING');

print keys %$result;

reset();

=head1 EXPORT

translate_msg
toString
get_content
reset
get_error_code
get_error_msg
get_error_message

=head1 SUBROUTINES/METHODS

=head2 translate_msg

Converts an XML message into a Perl hash structure while maintaining the 
structure of the message itself.

Input:      The XML string to be parsed

Output:     A perl hash structure that contains the converted string
            or an empty hash if there is no string provided or the
                XML parser fails

=cut

sub translate_msg{
    my $xml_msg = shift;
    my $fname = 'translate_msg';
    if( !defined($xml_msg) ){
        $error_code{$fname} = NO_MESSAGE_CODE;
        $error_msg{$fname} = NO_MESSAGE_MSG;
        return {};
    }
    #Reset the state variables
    %$xml_hashref = ();
    $raw_xml = '';
    #Store the XML message
    $raw_xml = $xml_msg;
    #Instantiates a new LibXML::Simple object
    my $xml = new XML::LibXML::Simple;
    #XMLin converts the XML to a nested hash
    #the ForceArray option forces the listed tags to be represented
    #as arrays so that the user can iterate through them
    my $data = ();
    eval{
        $data = $xml->XMLin("$xml_msg",ForceArray => ['PREFIX','ATTRIBUTE','AS_SEG','AS'],
KeepRoot => 1 , ForceContent => 1);
        $data->{'raw'} = $raw_xml;  #Saves the raw XML in the hash structure
        $xml_hashref = $data;
        return $xml_hashref;
    } or do {
        $error_code{$fname} = PARSER_ERROR_CODE;
        $error_msg{$fname} = PARSER_ERROR_MSG . ": $?";
        return {};
    };
}

=head2 toString

Returns a printable version of the most recent XML message that was parsed with
translate_msg.  If there is no such message, returns the empty string.

=cut
sub toString{
    my $fname = 'toString';
    if( !keys %$xml_hashref ){
        $error_code{$fname} = NO_MESSAGE_CODE;
        $error_msg{$fname} = NO_MESSAGE_MSG;
        return '';
    }
    return Dumper($xml_hashref);
}

=head2 get_content

Returns a reference to an element or attribute of the most recent XML message
translated via translate_msg.

Input:      A slash-delimited string which gives the path through
            the message tree structure, i.e. 
            "/ROOT_TAG/NEXT_TAG/attribute_name"
            NOTE: To get the text contents of an element, specify "/content"
                as the final "node" in the target string.

Output:     A reference to the appropriate content if found.
            undef if no such information is found

=cut
sub get_content{
    my $target_loc = shift;
    my $fname = 'get_content';

    if( !keys %$xml_hashref ){
        $error_code{$fname} = NO_MESSAGE_CODE;
        $error_msg{$fname} = NO_MESSAGE_MSG;
        return undef;
    }

    if( !defined($target_loc) ){
        $error_code{$fname} = UNDEFINED_ARGUMENT_CODE;
        $error_msg{$fname} = UNDEFINED_ARGUMENT_MSG;
        return undef;
    }
    #Extract the node names from the input by splitting on forward slashes
    my @path = split "/",$target_loc;
    shift @path;     #Removes the leading blank space from path
    #Now initialize a new hash reference to use to iteratively step
    #through the XML hash
    my $new_hashref = $xml_hashref;
    ELEMENT: foreach my $el (@path){
        #If we encounter an array in the hash structure
        #we need to go through it and see if any element
        #has the next element in the chain in it.
        if( ref $new_hashref eq 'ARRAY' ){
            foreach my $attr (@$new_hashref){
                #If the next element is found, we can move the hashref
                if( exists $attr->{"$el"} ){
                    $new_hashref = $attr;
                    last;
                }
            }
        }
        #Otherwise we try to dereference the next element in the chain.
        #If the array runs out or we give a hash element that isn't there,
        #catch it, set the error, and return.
        eval{ 
            $new_hashref = $new_hashref->{"$el"};
            1;
        } or do {
            $error_code{$fname} = NO_SUCH_INFORMATION_CODE;
            $error_msg{$fname} = NO_SUCH_INFORMATION_MSG;
            return undef;
        };
    }
    if( defined $new_hashref ){
        $error_code{$fname} = NO_ERROR_CODE;
        $error_msg{$fname} = NO_ERROR_MSG;
        return $new_hashref;
    }
    else{
        $error_code{$fname} = NO_SUCH_INFORMATION_CODE;
        $error_msg{$fname} = NO_SUCH_INFORMATION_MSG;
        return undef;
    }
}

=head2 reset

Resets the module's state variables

=cut

sub reset{
    $raw_xml = '';
    %$xml_hashref = ();
    for my $function_name (@function_names) {
        $error_code{$function_name} = NO_ERROR_CODE;
        $error_msg{$function_name} = NO_ERROR_MSG;
    }
    return;
}

=head2 get_error_code

Get the error code for some function

Input : the name of the function whose error code we should report

Output: the function's error code 
        or UNDEFINED_ARGUMENT if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function name
=cut

sub get_error_code {
    my $function = shift;

    # check we got a function name
    if (!defined($function)) {
        return UNDEFINED_ARGUMENT_CODE;
    }

    return $error_code{$function} if defined $error_code{$function};
    return INVALID_FUNCTION_SPECIFIED_CODE;
}

=head2 get_error_message

Get the error message for some function

Input : the name of the function whose error message we should report

Output: the function's error message
        or UNDEFINED_ARGUMENT if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function name
=cut

sub get_error_message {
    my $function = shift;

    # check we got a function name
    if (!defined($function)) {
        return UNDEFINED_ARGUMENT_MSG;
    }

    return $error_msg{$function} if defined($error_msg{$function});
    return INVALID_FUNCTION_SPECIFIED_MSG.": $function";
}

=head2 get_error_msg

Get the error message

This function is identical to get_error_message
=cut
sub get_error_msg {
    my $msg = shift;
    return get_error_message($msg);
}

=head1 ERROR CODES AND MESSAGES

The following error codes and messages are defined:

    0:  No Error
        'No Error. Life is good.'

    601:    There has been no XML message passed through translate_msg
        'No XML message provided'

    602:    No argument was passed to a function expecting one
        'Undefined argument'

    603:    An invalid function name was passed to get_error_[code/message/msg]
        'Invalid Function Name Specified'

    604:    The XML parser failed
        'XML Parser Error'

    605:    There was no information found at the location passed to 
get_content
        'No such element/attribute exists'

=head1 AUTHOR

Jason Bartlett, C<< <bartletj at cs.colostate.edu> >>

=head1 BUGS

Please report any bugs or feature requests to
 C<bgpmon at netsec.colostate.edu>, or through
the web interface at L<http://bgpmon.netsec.colostate.edu>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BGPmon::Translator::XFB2PerlHash

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
    OTHER DEALINGS IN THE SOFTWARE.\

    File: XFB2PerlHash.pm

    Authors: Jason Bartlett, Kaustubh Gadkari, Dan Massey, Cathie Olschanowsky
    Date: 11 July 2012
=cut

1; # End of BGPmon::Translator::XFB2PerlHash
