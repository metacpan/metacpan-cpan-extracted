package BGPmon::Translator::XFB2PerlHash::Simpler;
use strict;
use warnings;
use constant FALSE => 0;
use constant TRUE => 1;
use BGPmon::Translator::XFB2BGPdump qw(translate_message);
use List::MoreUtils qw(uniq);


BEGIN{
  require Exporter;
  our $VERSION = '2.00';
  our $AUTOLOAD;
  our @ISA = qw(Exporter);
  our @EXPORT_OK = qw( 
    get_error_msg get_error_code parse_xml_msg 
    extract_sender_addr extract_sender_port extract_sender_asn
    extract_withdraw extract_nlri extract_mpreach_nlri
    extract_mpunreach_nlri extract_aspath extract_as4path
    extract_origin);
}


# Variables to keep parsed data in
my $msgHash = undef;;


# Variables to hold error codes and messages
my %error_code = ();
my %error_msg = ();

use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG => 'No Error. Relax with some tea.';

use constant NO_MESSAGE_GIVEN => 200;
use constant NO_MESSAGE_GIVEN_MSG => "There was no XML message given.";
use constant BLANK_MESSAGE_GIVEN => 201;
use constant BLANK_MESSAGE_GIVEN_MSG => "The XML message given was blank.";


=head1 NAME

BGPmon::Translator::XFB2PerlHash::Simpler - a cleaner interface to extract 
commonly-used information from XFB messages that, unline XFB2PerlHash::Simple, 
will ignore xml attributes.

=head1 SYNOPSIS

  use BGPmon::Translator::XFB2PerlHash::Simpler;

  my $xml_message = "...

  if(BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($xml_message)){

    print BGPmon::Translator::SFB2PerlHash::get_error_msg('parse_xml_msg')."\n";

    exit 1;

  }

  my @withdrawn_prefixes = BGPmon::Translator::XFB2PerlHash::get_withdraw();

  foreach(@withdrawn_prefixes){

    ...

  }

  my $peer_address = BGPmon::Translator::XFB2PerlHash::extract_sender_addr();

  print "Seen at peer $peer_address\n";

=head1 EXPORT

get_error_msg get_error_code parse_xml_msg  extract_sender_addr 
extract_sender_port extract_sender_asn extract_withdraw extract_nlri 
extract_mpreach_nlri extract_mpunreach_nlri extract_aspath extract_as4path
extract_origin




=head1 SUBROUTINES/METHODS


=head2 get_error_msg

Will return the error message of the given function name.

Input:  A string that contains the function name where an error occured.

Output: The message which represents the error stored from that function.

=cut
sub get_error_msg{
  my $str = shift;
  my $fname = 'get_error_msg';
  my $toReturn = $error_msg{$str};
  return $toReturn;
}

=head2 get_error_code

Will return the error code of the given function name.

Input:  A string that represents the function name where an error occured.

Output: The code which represents the error stored from that function.

=cut
sub get_error_code{
  my $str = shift;
  my $fname = 'get_error_code';
  my $toReturn = $error_code{$str};
  return $toReturn;
}


#comment
#
#Will reset the most recently filtered prefixes and AS numbers, parse the 
#message that was sent to it, and store a unique set of prefixes and 
#AS numbers.
#
#cut
=head2 parse_xml_msg

Will translate an XML message from a string to a perl hash

Input:  An XML string from a BGPmon source

Output: 0 if parsing completed successfully

=cut
sub parse_xml_msg{

  my $fname = 'parse_xml_msg';
  my $xmlMsg = shift;

  if(!defined($xmlMsg)){
    $error_code{$fname} = NO_MESSAGE_GIVEN;
    $error_msg{$fname} = NO_MESSAGE_GIVEN_MSG;
    return 1;
  }

  if($xmlMsg eq ""){
    $error_code{$fname} = BLANK_MESSAGE_GIVEN;
    $error_msg{$fname} = BLANK_MESSAGE_GIVEN_MSG;
    return 1;
  }

  $msgHash = BGPmon::Translator::XFB2PerlHash::translate_msg($xmlMsg);

  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;

  return 0;
}


=head2 extract_sender_addr

Will extract a sender's IP address from the parsed XML mesage.

Input:  None

Output: IPv4/6 Address if successful; undef if not.

=cut
sub extract_sender_addr{

  my $fname = 'extract_sender_addr';
  my $hashRes = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/SOURCE/ADDRESS/content');
  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;
  return $hashRes;
}

=head2 extract_sender_port

Will extract a sender's port number from the parsed XML mesage.

Input:  None

Output: Port number if successful; undef if not.

=cut
sub extract_sender_port{

  my $fname = 'extract_sender_port';
  my $hashRes = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/SOURCE/PORT/content');
  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;
  return $hashRes;

}

=head2 extract_sender_asn

Will extract a sender's ASN number from the parsed XML mesage.

Input:  None

Output: ASN number if successful; undef if not.

=cut
sub extract_sender_asn{

  my $fname = 'extract_sender_asn';
  my $hashRes2 = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/SOURCE/ASN2/content');
  my $hashRes4 = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/SOURCE/ASN4/content');
  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;

  if(defined($hashRes2) and $hashRes2 ne ""){
    return $hashRes2;
  }
  elsif(defined($hashRes4) and $hashRes4 ne ""){
    return $hashRes4;
  }
  else{
    return undef;
  }
}


=head2 extract_withdraw

Will extract all the withdrawn prefixes from the parsed XML mesage.

Input:  None

Output: Array of IPv4/6 prefixes that were seen to have been withdrawn.

=cut
sub extract_withdraw{

  my $fname = 'extract_withdarw';
  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;

  #Getting Withdraws
  my @with_prefs = ();
  my $hashRes = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:WITHDRAW/');

  if(ref($hashRes) eq "ARRAY"){
    foreach my $res (@$hashRes){
      push(@with_prefs, $res->{'content'});
    }
  }
  elsif(ref($hashRes) eq "HASH"){
    push(@with_prefs, $hashRes->{'content'});
  }

  #Uniqueing
  @with_prefs = uniq(@with_prefs);
  
  return @with_prefs;
}

=head2 extract_nlri

Will extract all the prefixes in NLRI areas from the parsed XML mesage.

Input:  None

Output: Array of IPv4 prefixes that were seen in NLRIs.

=cut
sub extract_nlri{

  my $fname = 'extract_nlri';
  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;
  
  #Getting NLRI's
  my @nlris = ();

   #Getting NLRI announcements
   my @nlri_prefs = ();
   my $hashRes = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:NLRI/');

   if(ref($hashRes) eq "ARRAY"){
     foreach my $res (@$hashRes){
       push(@nlris, $res->{'content'});
     }
   }
   elsif(ref($hashRes) eq "HASH"){
     push(@nlris, $hashRes->{'content'});
   }

  #Uniqueing
  @nlris = uniq(@nlris);

  return @nlris;
}

=head2 extract_mpreach_nlri

Will extract all the IPv4/6 prefixes announced in MP_REACH_NLRI's from 
the parsed XML mesage.  This will exclude the MP_REACH NEXT_HOP.

Input:  None

Output: Array of IPv4/6 prefixes that were seen in MP_REACH_NLRI's

=cut
sub extract_mpreach_nlri{

  my $fname = 'extract_mpreach_nlri';
  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;

  #Getting mp_reach_nlris
  my @mpnlri_prefs = ();
  my $hashRes = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:MP_REACH_NLRI/bgp:MP_NLRI/');
  
  if(ref($hashRes) eq "ARRAY"){
    foreach my $res (@$hashRes){
      push(@mpnlri_prefs, $res->{'content'});
    }
  }
  elsif(ref($hashRes) eq "HASH"){
    push(@mpnlri_prefs, $hashRes->{'content'});
  }
  
  #Uniqueing
  @mpnlri_prefs = uniq(@mpnlri_prefs);

  return @mpnlri_prefs;
}

=head2 extract_mpunreach_nlri

Will extract all the IPv4/6 prefixes withdrawn in MP_UNREACH_NLRI's from 
the parsed XML mesage.

Input:  None

Output: Array of IPv4/6 prefixes that were seen in MP_UNREACH_NLRI's

=cut
sub extract_mpunreach_nlri{

  my $fname = 'extract_mpunreach_nlri';
  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;

  #Getting mp_unreach_nlris
  my @toReturn = ();
  my $hashRes = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:MP_UNREACH_NLRI/bgp:MP_NLRI/');
       
  if(ref($hashRes) eq "ARRAY"){
    foreach my $res (@$hashRes){
      push(@toReturn, $res->{'content'});
    }
  }                      
  elsif(ref($hashRes) eq "HASH"){
    push(@toReturn,$hashRes->{'content'});
  }

  #Uniquing
  @toReturn = uniq(@toReturn);

  return @toReturn;
}


=head2 extract_aspath

Will extract all the ASNs found in either AS_PATH/AS_SET or AS_PATH/AS_SEQUENCE
from the parsed XML mesage.

Input:  None

Output: Array of ASNs found in the AS_PATH  path attribute.

=cut
sub extract_aspath{
  my $fname = 'extract_aspath';
  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;

  #Checking for AS numbers in the AS_Path attribute
  my @toReturn = ();
  my $hashRes = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:AS_PATH/bgp:AS_SEQUENCE/bgp:ASN2/');  
  if(ref($hashRes) eq "ARRAY"){
    foreach my $res (@$hashRes){
      push(@toReturn, $res->{'content'});
    }
  }                      
  elsif(ref($hashRes) eq "HASH"){
    push(@toReturn,$hashRes->{'content'});
  }

  #If we have the data already, return!
  my $size = scalar(@toReturn);
  return @toReturn if($size !=0);

  $hashRes = BGPmon::Translator::XFB2PerlHash::get_content(
    '/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:AS_PATH/bgp:AS_SEQUENCE/bgp:ASN4/');  
  
  if(ref($hashRes) eq "ARRAY"){
    foreach my $res (@$hashRes){
      push(@toReturn, $res->{'content'});
    }
  }                      
  elsif(ref($hashRes) eq "HASH"){
    push(@toReturn,$hashRes->{'content'});
  }

  return @toReturn;
}

=head2 extract_as4path

Will extract all the ASNs found in either AS4_PATH/AS_SET or 
AS4_PATH/AS_SEQUENCE from the parsed XML mesage.

Input:  None

Output: Array of ASNs found in the AS4_PATH  path attribute.

=cut
sub extract_as4path{
  my $fname = 'extract_as4path';
  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;
  my @areas = (
    "/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:AS4_PATH/bgp:AS_SEQUENCE/bgp:ASN2/",
    "/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:AS4_PATH/bgp:AS_SEQUENCE/bgp:ASN4/",
    "/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:AS4_PATH/bgp:AS4_SEQUENCE/bgp:ASN2/",
    "/BGP_MONITOR_MESSAGE/bgp:UPDATE/bgp:AS4_PATH/bgp:AS4_SEQUENCE/bgp:ASN4/");
  

  my @toReturn = ();
  foreach(@areas){
    my $hashRes = BGPmon::Translator::XFB2PerlHash::get_content($_);

    if(ref($hashRes) eq "ARRAY"){
      foreach my $res (@$hashRes){
        push(@toReturn, $res->{'content'});
      }
    }                      
    elsif(ref($hashRes) eq "HASH"){
      push(@toReturn,$hashRes->{'content'});
    }

    #if we have the data, return it!
    my $size = scalar(@toReturn);
    return @toReturn if($size > 0);
  }
  return @toReturn;
}


=head2 extract_origin

Will extract the ASN where the message was announced 
from within the parsed XML mesage.

Input:  None

Output: The ASN of the origin AS; undef if there is none.

=cut
sub extract_origin{
  my $fname = 'extract_origin';
  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;

  my @aspath = extract_aspath();
  if(scalar(@aspath) == 0){
    @aspath = extract_as4path();
  }
  if(scalar(@aspath) == 0){
    return undef;
  }

  return $aspath[-1];
}


1;
__END__


=head1 ERROR CODES AND MESSAGES

The following error codes and messages are defined:

0:  There isn't an error.  'No Error. Relax with some tea.'

200:  Run parse_xml_message first. "There was no XML message given."

201:  Invalid xml message given "The XML message given was blank."


=cut

=head1 AUTHOR

M. Lawrence Weikum C<< <mweikum at rams.colostate.edu> >>

=cut

=head1 BUGS

Please report any bugs or feature requeues to 
C<bgpmon at netsec.colostate.edu> or through the web interface
at L<http://bgpmon.netsec.colostate.edu>.

=cut

=head1 SUPPORT

You can find documentation on this module with the perldoc command.

perldoc BGPmon::Filter

=cut


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Colorado State University

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

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

  File: Simpler.pm
  Authors: M. Lawrence Weikum
  Date: 13 October 2013
=cut
