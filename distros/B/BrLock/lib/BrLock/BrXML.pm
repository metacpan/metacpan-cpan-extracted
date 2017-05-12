package BrLock::BrXML;

use strict; 
use base 'Exporter'; 
our @EXPORT = qw(xmlmessage_brpack xmlparse_brmsg brxml_debug);

our $brxml_debug = 0; 

#TODO: now that we've separated these functions in this package, we
# should update the comments. 


# xmlmessage_brpack(type, site_id, site_seq, random_data):
#  this function returns a string containing a XML message as
#  specified in the file mutex.txt. 

#TODO: verify the return values (I don't know if it's good
# to return undefined because, if  the main/superfunction wants this
# value to pass to another function, it'll need a variable to receive
# this value. However, I don't know if there is a good solution for
# him (if he wants to test, he'll need another variable anyway)). 

#TODO: change the name of this function. Maybe xmlpack_brmessage().
sub xmlmessage_brpack {
	my ($type, $site_id, $site_seq, $random) = @_;
	if ($type ne "REQ" and $type ne "REP"){ 
		print "xmlmessage_brpack(): Message must be either \"REQ\"".
			   " or \"REP\".\n" if  $brxml_debug;
		return undef; 
	}
	my $xml_msg = "\$xml_msg = \"
<msg>
 <type>\$type</type>
 <site_id>\$site_id</site_id>
 <site_seq>\$site_seq</site_seq>
 <body>\$random</body>
</msg>
\";"; 
eval $xml_msg; 
return $xml_msg; 
}


###
# XML parsing variables and functions (We all will go to hell for
# using globals). You're probably only interested in the sub
# xmlparse_brmsg (xml_msg).
###

my $xmlparse_tagtofill; 
my %xmlparse_data = (
	type => '',
	site_id => '',
	site_seq => '',
	body => '',
); 

# xmlhandler_tagstart():
#   handler for the parsing process (see the function xmlparse_brmsg).  
#   it sets which tag in the hash  %xmlparse_data must be filled by
#   the handler xmlhandler_tagchar. 
sub xmlhandler_tagstart {
	my ($p, $element, %attrs) = @_ ;
	$xmlparse_tagtofill = $element;

}

# xmlhandler_tagchar(): 
#   handler for the parsing process (see the function xmlparse_brmsg).  
#   it fills the tag in the hash %xmlparse_data which
#   xmlhandler_tagstart has set to be filled. 
sub xmlhandler_tagchar {
	my ($p, $data) = @_ ;
	$xmlparse_data{$xmlparse_tagtofill} = $data; 
	$xmlparse_tagtofill = '';
}

# xmlparse_brmsg (xml_msg):
#   parses the XML message xml_msg as specified (see the file
#   mutex.txt) and returns the existing data for the tags as a list:
#   ($type, $site_id, $site_sequence, $random).
#
#   the xml_msg data may either be a string containing the
#   whole XML document, or it may be an open IO::Handle.
sub xmlparse_brmsg { 
	my ($xml_msg) = $_[0]; 
	my ($type, $site_id, $site_sequence, $random) = 0; 
	my $xp = new XML::Parser(); 
	$xp->setHandlers ( 
		Start => \&xmlhandler_tagstart, 
		Char  => \&xmlhandler_tagchar, 
	);
	# $xp->parsestring($xml_msg);
	# it doesn't need to be a string:  
	$xp->parse($xml_msg);
	return ($xmlparse_data{'type'}, $xmlparse_data{'site_id'}, 
	        $xmlparse_data{'site_seq'}, $xmlparse_data{'body'});
}



BEGIN{
}
return 1; 
