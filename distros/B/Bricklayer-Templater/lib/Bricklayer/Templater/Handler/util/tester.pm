#------------------------------------------------------------------------------- 
# 
# File: tester.pm
# Version: 0.1
# Author: Jeremy Wall
# Definition: This is the handler for plain text blocks in a template.
#             It basically just returns the text unchanged. I made it a
#             handler just in case we needed to do something to plain text
#             later on. 
#
#--------------------------------------------------------------------------
package Bricklayer::Templater::Handler::util::tester;
use Bricklayer::Templater::Handler;
use base qw(Bricklayer::Templater::Handler);

sub run {
    
    return "tester was here :-)";   
}


return 1;