package BGPmon::Validator;
use strict;
use warnings;
use constant FALSE => 0;
use constant TRUE => 1;
use BGPmon::Fetch2;
use XML::LibXML;

BEGIN{
  require Exporter;
  our $VERSION = '1.092';
  our $AUTOLOAD;
  our @ISA = qw(Exporter);
  our @EXPORT_OK = qw(init validate get_error_msg get_error_code);

}


# Variables to hold error codes and messages
my %error_code;
my %error_msg;

use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG => 'No Error. Relax with some tea.';


#Error codes for parsing the XML file.
use constant NO_MSG_GIVEN => 690;
use constant NO_MSG_GIVEN_MSG => "Invalid XML message was given.";

#My Variables
my $parser;
my $schema;
my @$validMessage;


sub init{
  my $xsdFilename = shift;
  my $fname = 'init';

  $parser = XML::LibXML::->new();

  $schema = XML::LibXML::Schema->new(location => $xsdFilename);
  #TODO catch if the file didn't open properly and make a new error code that is thrown


  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;

  return 0;


}



sub validate{
  my $xmlMsgLoc = shift;
  my $doc = $parser->parse_string($$xmlMsgLoc);

  eval {$schema->validate($doc)};
  @$validMessage = $@;
  if($@){ # invalid message!
    #TODO make an error code and throw it here
    return FALSE;
  }

  return TRUE

}




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


