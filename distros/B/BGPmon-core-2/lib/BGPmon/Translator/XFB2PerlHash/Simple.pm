package BGPmon::Translator::XFB2PerlHash::Simple;

use 5.14.0;
use strict;
use warnings;
use BGPmon::Translator::XFB2PerlHash;
use Data::Dumper;
use List::MoreUtils qw(uniq);

BEGIN{
require Exporter;
    our $AUTOLOAD;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(init get_timestamp get_dateTime get_nlri get_mp_nlri
get_withdrawn get_mp_withdrawn get_peering get_origin get_as_path get_as4_path 
get_next_hop get_mp_next_hop get_xml_string get_error_code get_error_message 
get_error_msg get_xml_message_type get_status);
    our $VERSION = '2.0';
}

#Variables to hold error codes and messages
my %error_code;
my %error_msg;
my @function_names = ('init', 'get_timestamp', 'get_dateTime', 'get_nlri',
'get_mp_nlri','get_withdrawn','get_mp_withdrawn','get_peering','get_origin',
'get_as_path','get_as4_path','get_next_hop','get_mp_next_hop','get_xml_string'
,'get_xml_message_type', 'get_status');

use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG => 'No Error. Life is good.';
use constant INVALID_FUNCTION_SPECIFIED_CODE => 603;
use constant INVALID_FUNCTION_SPECIFIED_MSG => 
  'Invalid Function Name Specified';

=head1 NAME

BGPmon::Translator::XFB2PerlHash::Simple - a clean interface to extract
commonly-used information from XFB messages.

=head1 SYNOPSIS

use BGPmon::Translator::XFB2PerlHash::Simple;

print get_error_msg('init') if !init('/XML/MESSAGE/TO/PARSE');

my $scalar_result = get_timestamp();

print $scalar_result;

my @array_result = get_nlri();

do_something() foreach my $nlri (@array_result)...

my $hash_ref_result = get_peering();

print $hash_ref_result-{'element'}-{'subelement'}-{'attribute'};

=cut

=head1 EXPORT


init get_timestamp get_dateTime get_nlri get_mp_nlri get_withdrawn 
get_mp_withdrawn get_peering get_origin get_as_path get_as4_path get_next_hop 
get_mp_next_hop get_xml_string get_error_code get_error_message get_error_msg 
get_xml_message_type get_status

=head1 SUBROUTINES/METHODS

=head2 init

This function takes an XML message to be translated and internally converts it
to an appropriate data structure for querying.

   Input:      The message to be translated

   Output:     1 on success, 0 on failure

=cut

sub init{
    my $msg = shift;
    my $fname = 'init';
    my $hash = BGPmon::Translator::XFB2PerlHash::translate_msg($msg);
    if( !keys %$hash ){
        $error_code{$fname} = 
          BGPmon::Translator::XFB2PerlHash::get_error_code('translate_msg');
        $error_msg{$fname} = 
          BGPmon::Translator::XFB2PerlHash::get_error_msg('translate_msg');
        return 0;
    }
    $error_code{$fname} = NO_ERROR_CODE;
    $error_msg{$fname} = NO_ERROR_MSG;
    return 1;
}



=head2 get_error_code

Get the error code

Input : the name of the function whose error code we should report

Output: the function's error code 
        or NO_FUNCTION_SPECIFIED if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function
=cut
sub get_error_code {
    my $function = shift;

    # check we got a function name
    if (!defined($function)) {
        return INVALID_FUNCTION_SPECIFIED_CODE;
    }

    # check this is one of our exported function names
    if (!defined($error_code{$function}) ) {
        return INVALID_FUNCTION_SPECIFIED_CODE;
    }

    my $code = $error_code{$function};
    return $code;
}

=head2 get_error_message

Get the error message

Input : the name of the function whose error message we should report

Output: the function's error message
        or NO_FUNCTION_SPECIFIED if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function
=cut
sub get_error_message {
    my $function = shift;

    # check we got a function name
    if (!defined($function)) {
        return INVALID_FUNCTION_SPECIFIED_MSG;
    }

    # check this is one of our exported function names
    if (!defined($error_msg{$function}) ) {
        return INVALID_FUNCTION_SPECIFIED_MSG;
    }

    my $msg = $error_msg{$function};
    return $msg;
}

=head2 get_error_msg

Get the error message

This function is identical to get_error_message

=cut
sub get_error_msg {
    my $msg = shift;
    return get_error_message($msg);
}

############################## BEGIN UNEXPORTED FUNCTIONS #####################

#The autoloader handles all the functions that we want to define in this module
#   Input:      a function name of the format 'get_*' where * is some element
#                   of an XFB message
#   Output:     the appropriate value(s) from the message, or undef if either
#                   the lookup fails or the element is not a defined lookup
sub AUTOLOAD{
    our $AUTOLOAD;
    my  $msg = shift;

    # get the function name 
    my $sub = $AUTOLOAD;
    (my $function_name = $sub) =~ s/.*:://;

    # check we got a valid function name
    if( !defined $function_name ) {
        # no function name so no error code/msg to set
        return undef;
    }

    #Begin by setting the error code to none; if the function is bad
    #the error code will be set further down
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;

################################# SCALAR ELEMENTS #############################
=head2 get_timestamp

Returns the UNIX timestamp from an XFB message as a scalar.

=cut
    return BGPmon::Translator::XFB2PerlHash::get_content
      ('/BGP_MONITOR_MESSAGE/OBSERVED_TIME/TIMESTAMP/content') 
      if $function_name eq 'get_timestamp';

=head2 get_dateTime

Returns the human-readable timestamp from an XFB message as a scalar.

=cut
    return BGPmon::Translator::XFB2PerlHash::get_content
      ('/BGP_MONITOR_MESSAGE/OBSERVED_TIME/DATETIME/content') 
      if $function_name eq 'get_dateTime';

=head2 get_xml_message_type

Returns the type of message we're seeing - if it's from a live stream or if
it's from a RIB dump from a BGPmon source.

=cut
    return BGPmon::Translator::XFB2PerlHash::get_content
      ('/BGP_MONITOR_MESSAGE/COLLECTION/content') 
      if $function_name eq 'get_xml_message_type';

=head2 get_origin

Returns the stringified origin of the BGP message.  Defined values are given in
the XFB specification.

=cut
    return BGPmon::Translator::XFB2PerlHash::get_content
      ('/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:ORIGIN/content')
      if $function_name eq 'get_origin';

=head2 get_next_hop

Returns a scalar IPv4 address in dotted-decimal notation as given in the next 
hop attribute.

=cut
    #Get the string representation of the content of the NEXT_HOP element
    return BGPmon::Translator::XFB2PerlHash::get_content
      ('/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:NEXT_HOP/content')
      if $function_name eq 'get_next_hop';

=head2 get_xml_string

Returns the raw XML string passed into init

=cut
    return BGPmon::Translator::XFB2PerlHash::get_content('/raw') 
      if $function_name eq 'get_xml_string';
    
=head2 get_status

Returns the status message in the XML if it exists

=cut
    #Return the status message
    return BGPmon::Translator::XFB2PerlHash::get_content
      ('/BGP_MONITOR_MESSAGE/STATUS/TYPE/content') 
      if $function_name eq 'get_status';

################################ ARRAY ELEMENTS ###############################

=head2 get_mp_next_hop

Returns an array of hashes with the next hop(s) from the MP_REACH attribute.

Ex:     my @ret = get_mp_next_hop();
        print my $addr-{'ADDRESS'}-{'content'} foreach $addr (@ret);

=cut
    if($function_name eq 'get_mp_next_hop'){
      my @prefs = ();
      my $hashRes = BGPmon::Translator::XFB2PerlHash::get_content
        ('/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:MP_REACH_NLRI/bgp:MP_NEXT_HOP/');
      if(ref($hashRes) eq "ARRAY"){
        @prefs = (@prefs, @$hashRes);
      }
      elsif(ref($hashRes) eq "HASH"){
        push(@prefs, $hashRes);
      }
      return @prefs; 
    }

=head2 get_nlri

Returns an array of hashes.  Each of these hashes are structured like so:

{
    'SAFI' = {
                'value' = '1',
                'content' = 'UNICAST'
              },
    'AFI' = {
                'value' = '1',
                'content' = 'IPV4'
             },
    'ADDRESS' = {
                'content' = '192.168.0.0/16'
                 }

}
=cut
    if ($function_name eq 'get_nlri'){
      my @nlri_prefs = (); 
      my $hashRes =  BGPmon::Translator::XFB2PerlHash::get_content
        ('/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:NLRI/');
      if(ref($hashRes) eq "ARRAY"){
        @nlri_prefs = (@nlri_prefs, @$hashRes);
      }
      elsif(ref($hashRes) eq "HASH"){
        push(@nlri_prefs, $hashRes);
      }
      return @nlri_prefs;
    }

=head2 get_withdrawn

Returns an array of hashes which contain an AFI,SAFI,and withdrawn IPv4 prefix.
These hashes are structured just like the ones described in the documentation
for get_nlri().

=cut
    if ($function_name eq 'get_withdrawn') {
      my @with_prefs = ();
      my $hashRes = BGPmon::Translator::XFB2PerlHash::get_content
        ('/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:WITHDRAW/');

       if(ref($hashRes) eq "ARRAY"){
         @with_prefs = (@with_prefs, @$hashRes);
       }
       elsif(ref($hashRes) eq "HASH"){
         push(@with_prefs, $hashRes);
       }
       return @with_prefs;
    }

################################### HASHREF ELEMENTS ##########################
=head2 get_as_path

Returns an array of hashes that contains the AS path attribute of the message.
Each hash represents a single AS Segment, which can be either an AS_SEQUENCE
or AS_SET.  Each AS_SEG has an AS subarray that contains the ASNs for that 
segment.

=cut
    return BGPmon::Translator::XFB2PerlHash::get_content
      ('/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:AS_PATH/')  
      if $function_name eq 'get_as_path';

=head2 get_as4_path

Returns an array of hashes that contains the AS4_PATH attribute of the message.
Each hash represents a single AS Segment, which can be either an AS_SEQUENCE
or AS_SET.  Each AS_SEG has an AS subarray that contains the ASNs for that 
segment.

=cut
    return BGPmon::Translator::XFB2PerlHash::get_content
      ('/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:AS4_PATH/')
      if $function_name eq 'get_as4_path';

=head2 get_mp_nlri

Returns an array of hashes which contain an AFI,SAFI,and announced prefix. 
These hashes are structured just like the ones described in the documentation
for get_nlri().

=cut
    return BGPmon::Translator::XFB2PerlHash::get_content
      ('/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:MP_REACH_/NLRI/') 
      if $function_name eq 'get_mp_nlri';

=head2 get_mp_withdrawn

Returns an array of hashes which contain an AFI,SAFI,and withdrawn prefix.
These hashes are structured just like the ones described in the documentation
for get_nlri().

=cut
    return BGPmon::Translator::XFB2PerlHash::get_content
      ('/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:MP_UNREACH_NLRI/') 
      if $function_name eq 'get_mp_withdrawn';

=head2 get_peering

Returns a hash reference that contains information about the BGP peering
session that the message was received from.  To see its contents, check the 
XFB specification or use Data::Dumper.

=cut
    return BGPmon::Translator::XFB2PerlHash::get_content
      ('/BGP_MONITOR_MESSAGE/SOURCE/') if $function_name eq 'get_peering';

################################ ERROR HANDLING ###############################
    #If there's no error code on get_content and none of the above
    #functions were called, then an unknown function was called
    if( !BGPmon::Translator::XFB2PerlHash::get_error_code('get_content') ){
        $error_code{$function_name} = INVALID_FUNCTION_SPECIFIED_CODE;
        $error_msg{$function_name} = INVALID_FUNCTION_SPECIFIED_MSG.": $function_name";
        return undef;
    }
    else{
        $error_code{$function_name} = 
          BGPmon::Translator::XFB2PerlHash::get_error_code('get_content');
        $error_msg{$function_name} = 
          BGPmon::Translator::XFB2PerlHash::get_error_msg('get_content');
        return undef;
    }

}

#Function to return an array of values from a call to get_content
#   Input:      a reference variable that is supposed to point to an array
#   Output:     returns the array pointed at by the reference

sub return_array{
    my $arg = shift;
    return @$arg if defined $arg;
    return ();
}


=head1 BUGS

Please report any bugs or feature requests to
 C<bgpmon at netsec.colostate.edu>, or through
the web interface at L<http://bgpmon.netsec.colostate.edu>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BGPmon::Translator::XFB2PerlHash::Simple

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

    File: Simple.pm

    Authors: M. Lawrence Weikum, Jason Bartlett
    Date: 13 October 2013

=cut
1;  #End of module BGPmon::Translator::XFB2PerlHash::Simple
