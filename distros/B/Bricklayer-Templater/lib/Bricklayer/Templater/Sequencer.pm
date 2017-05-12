#------------------------------------------------------------------------------- 
# 
# File: sequencer.pm
# Version: 0.2
# Author: Jeremy Wall
# Definition: This is the templating engine for template files. It uses the
#             parser engine to parse a file or string into tokens and then
#             uses object methods to look at the tokens or return a parsed file
#             file using the handlers in the handle library and based on the
#             current environment the object is running in.
#
#-------------------------------------------------------------------------------
package Bricklayer::Templater::Sequencer;

use strict;
use Carp;

use Bricklayer::Templater::Parser;

=head1 NAME

Bricklayer::Templater::Sequencer - Internal Module used by L<Bricklayer::Templater>;

=head1 Description

Handles parsing the template and replacing the tags with returned text for Bricklayer::Templater

=head1 METHODS

=head2 new_sequencer

Creates a new sequencer object. 

=cut

my %handlerCache;

sub new_sequencer {
    my $Proto = shift;
    my $TemplateText = shift or confess("No template specified");
    my $tagID = shift;
    my $start = shift;
    my $end   =shift;
    
    my $Class = ref($Proto) || $Proto;
    my @TokenList = Bricklayer::Templater::Parser::parse_text($TemplateText, $tagID, $start, $end);
    #die "this many tokens found ".scalar(@TokenList);
    return bless(\@TokenList, $Class); 
    
}

=head2 return_parsed

returns a string with the replacement text for a parsed token

=cut


# returns a string with the replacement text for the parsed token
sub return_parsed($$$$) {
    my $Self = shift;
    my $Env = shift;
    my $Parameters = shift;
    my $handler_loc = shift;
    
    parse_tokens($Self, $Env, $Parameters, $handler_loc);
    return; 
}

=head2 parse_tokens

actually runs through the list of tokens and loades the handler or retrieves it from the handler cache to run.

=cut

sub parse_tokens($$$$) {
    my $TokenList = shift;
    my $App = shift;
    my $Parameters = shift;
    my $handler_loc = shift;
    my $ParsedText;
    my $tokenCount = scalar(@$TokenList);
    my $loopCount = 0;
    foreach my $Token (@$TokenList) {
        # we are dynamically loading our handlers here
        # using symbolic references and a little perl magic
        # Seperate handlers with :: to denote directories
        # in the handler directory.
        my $handler;
        my $tagname = 'Bricklayer::Templater::Handler::'.$Token->{tagname};
        my $Seperator = "/";
        my $SymbolicRef = $tagname;
#        $tagname =~ s/::/$Seperator/g;
        if (exists($handlerCache{$Token->{tagname}})) {
        	$handler = $handlerCache{$Token->{tagname}}->load($Token, $App);
            $handler->run_handler($Parameters);
            
        } else {
            eval "use $tagname";
        	if (!$@) {	            
	            $handler = $SymbolicRef->load($Token, $App);
	        } else {
	            carp("grrr no such handler: $Token->{tagname} at $tagname.pm");
	            next;
	        }
	        $handlerCache{$Token->{tagname}} = $SymbolicRef;
	        $handler->run_handler($Parameters);      	
        }
    }
    return;
}

=head1 SEE ALSO

L<Bricklayer::Templater>

=cut

return 1;
