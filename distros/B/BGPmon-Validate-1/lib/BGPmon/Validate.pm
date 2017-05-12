package BGPmon::Validate;
use strict;
use warnings;
use constant FALSE => 0;
use constant TRUE => 1;
use BGPmon::Fetch;
use XML::LibXML;

BEGIN{
  require Exporter;
  our $VERSION = '1.01';
  our $AUTOLOAD;
  our @ISA = qw(Exporter);
  our @EXPORT_OK = qw(init validate get_error_msg 
                      get_error_code get_valid_error);

}


# Variables to hold error codes and messages
my %error_code;
my %error_msg;

use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG => 'No Error. Relax with some tea.';

#Error opening or parsing the XSD file
use constant XSD_ERROR => 692;

#Error codes for parsing the XML message.
use constant NO_MSG_GIVEN => 690;
use constant NO_MSG_GIVEN_MSG => "Invalid XML message was given.";
use constant INVALID_MSG_GIVEN => 691;
use constant INVALID_MSG_GIVEN_MSG => "XML message did not validate.";
use constant PARSE_MSG_FAILED => 693;

#My Variables
my $parser;
my $schema;
my $validationError = undef;
my $default_xsd_location = 'etc/bgp_monitor_2_00.xsd';



=head1 NAME

BGPmon::Validate

This module provides a way to validate XML messages from a BGPmon source
against the published XSD.
=cut

=head1 SYNOPSIS

use BGPmon::Validate;

if(BGPmon::Validate::init()){

	my $err_code = BGPmon::Validate::get_error_code('init');
	
	my $err_msg = BGPmon::Validate::get_error_msg('init');
	
	print "$err_code : $err_msg\n";
	
	exit 1;
}

my $xml_msg; #put your own xml message here

if(BGPmon::Validate::validate($xml_msg)){
	
	my $err_code = BGPmon::Validate::get_error_code('validate');
	
	my $err_msg = BGPmon::Validate::get_error_msg('validate');
	
	print "$err_code : $err_msg\n";
	
	exit 1;
}
else{
	
	print "Message validated.\n";

}

=head1 EXPORT

init validate get_error_msg get_error_code



=head1 SUBROUTINES/METHODS





=head2 init

Loads the default or desired XSD for the module to use for validation.
If a different XSD is to be used a later time, simply run init again to load
the other XSD.

Input:  The desired XSD (optional)

Output: 1 if there was an error loading the XSD
        0 if there were no errors

=cut
sub init{
  my $xsdFilename = shift;
  my $fname = 'init';

  if(!defined($xsdFilename) or $xsdFilename eq ""){
    $xsdFilename = $default_xsd_location;
  }

  $parser = XML::LibXML::->new();

  eval{
    $schema = XML::LibXML::Schema->new(location => $xsdFilename);
  } or do {
    $error_code{$fname} = XSD_ERROR;
    $error_msg{$fname} = $@;
    return 1;
  };

  $error_code{$fname} = NO_ERROR_CODE;
  $error_msg{$fname} = NO_ERROR_MSG;

  return 0;
}



=head2 validate

Will check the XML message against the XSD loaded using BGPmon::Validate::init

Input:  A BGPmon message in XML format

Output: 0 if the message validated
        1 if an error has occured

=cut
sub validate{
  my $xmlMsg = shift;
  my $fname = 'validate';
  $validationError = undef;

  if(!defined($xmlMsg) or $xmlMsg eq ""){
    $error_code{$fname} = NO_MSG_GIVEN;
    $error_msg{$fname} = NO_MSG_GIVEN_MSG;
    return 1;
  }


  my $doc;
  
  eval{
    $doc = $parser->parse_string($xmlMsg);
  } or do {
    $error_code{$fname} = PARSE_MSG_FAILED;
    $error_msg{$fname} = $@;
    return 1;
  };

  eval {$schema->validate($doc)};
  if($@){
    $error_code{$fname} = INVALID_MSG_GIVEN;
    $error_msg{$fname} = INVALID_MSG_GIVEN_MSG;
    $validationError = $@->{'message'};
    return 1;
  }
  else{
    $error_code{$fname} = NO_ERROR_CODE;
    $error_msg{$fname} = NO_ERROR_MSG;
    return 0;
  }
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
  my $name = shift;
  my $fname = 'get_error_code';
  my $toReturn = $error_code{$name};
  return $toReturn;
}

=head2 get_valid_error

Will return the schema validation error if one occurred.

Input:  

Output: The error code form schema validation or undef is there was no error.

=cut
sub get_valid_error{
  my $name = shift;
  my $fname = 'get_valid_error';
  return $validationError;
}

1;

__END__


=head1 ERROR CODES AND MESSAGES

The following error codes and messages are defined:
  0:    There isn't an error.
        'No Error. Relax with some tea.';
  690:  The message given to validate was invalid.
        'Invalid XML message was given.'
  691:  The XML message given to validate did not validate against the XSD.
        'XML message did not validate.'
  692:  Either the XSD file did not exist or there was a problem 
        loading the XSD.  The error message will be dynamic.
  693:  The message passed to validate was not a proper XML message
        and could not be parsed.  The error message will be dynamic.

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

	perldoc BGPmon::Validate

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

File: Validate.pm

Authors: M. Lawrence Weikum

Date: 13 August 2013
=cut






