package BGPmon::Translator::XFB2PerlHash;

use 5.14.0;
use strict;
use warnings;
use XML::LibXML::Simple;
use Data::Dumper;

BEGIN{
require Exporter;
    our $AUTOLOAD;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(translate_msg toString get_content reset 
                        get_error_code get_error_message get_error_msg);
    our $VERSION = '2.0';
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
use constant INVALID_FUNCTION_SPECIFIED_MSG => 
  'Invalid Function Name Specified';
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

my $xml_string = '...


#Convering and soring the xml message

my %hash = translate_msg($xml_string);


#printing the data in an easier-to-read way

print toString(); 


#printing the port number of the peer that passed us this message

my $result = get_content('/BGP_MONITOR_MESSAGE/SOURCE/PORT/content');

print $result;


#Printing all the prefixes found in the NLRI section

$result = get_content('/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:NLRI/');

print $_->{'ADDRESS'}->{'content'} foreach (@$result);


#Resetting the module

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
        $data = $xml->XMLin("$xml_msg",ForceArray => 
          ['PREFIX','ATTRIBUTE','AS_SEG','AS'], KeepRoot => 1 , 
          ForceContent => 1);
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

    Authors: M. Lawrence Weikum, Jason Bartlett, Kaustubh Gadkari, Dan Massey, Cathie Olschanowsky
    Date: 13 October 2013
=cut

1; # End of BGPmon::Translator::XFB2PerlHash
